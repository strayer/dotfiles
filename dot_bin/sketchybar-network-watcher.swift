// sketchybar-network-watcher: watches SCDynamicStore for network changes and
// triggers `sketchybar --trigger network_info_change` with these env vars:
//   NETWORK_TYPE       wifi | hotspot | ethernet | disconnected
//   NETWORK_SSID       current WiFi SSID (empty if unknown)
//   NETWORK_SSID_HASH  lowercase hex HMAC-SHA256 of the SSID's UTF-8 bytes, keyed
//                      with the salt (empty if no SSID or no salt); equals
//                      `printf '%s' "$SSID" | openssl dgst -sha256 -hmac "$SALT" | awk '{print $NF}'`
//   NETWORK_SIGNAL     WiFi signal level 0-4 from the RSSI (empty unless type is wifi)
//
// Besides SCDynamicStore changes, CoreWLAN link quality events re-trigger the
// event, but only when the signal level changes (with hysteresis), since the
// RSSI itself changes every few seconds.
//
// Detail mode (for the SketchyBar popup): SIGUSR1 enables it, SIGUSR2 disables
// it; it also expires on its own after detailModeTimeout. While enabled, the
// daemon additionally triggers `network_details_change` right away, on every
// network change and on every link quality event, with:
//   NETWORK_TYPE, NETWORK_SSID, NETWORK_SIGNAL   as above
//   NETWORK_INTERFACE  physical interface (en0, en7, ...)
//   NETWORK_IP         IPv4 address of the physical interface
//   NETWORK_ROUTER     IPv4 router of the physical interface
//   NETWORK_VPN        comma-separated names of connected VPN services
//   and, on wifi/hotspot only (empty otherwise):
//   NETWORK_RSSI, NETWORK_NOISE  dBm
//   NETWORK_TX_RATE    Mbit/s
//   NETWORK_CHANNEL    e.g. "36 · 5 GHz · 80 MHz"
//   NETWORK_PHY        e.g. "Wi-Fi 6 (802.11ax)"
//   NETWORK_SECURITY   e.g. "WPA3 Personal"
// Outside detail mode none of this is gathered or sent.
//
// Salt: read once at startup from ~/.config/dotfiles/hash-salt (deployed by chezmoi from
// an encrypted secret), UTF-8, leading/trailing whitespace+newlines trimmed. If the file
// is missing or empty, a warning is printed to stderr and every hash is empty.
//
// Flags:
//   --debug  log detection details to stderr
//   --once   detect once, print `<type>\t<ssid>\t<hash>` to stdout and exit
//            without triggering sketchybar or entering the run loop

import AppKit
import CoreLocation
import CoreWLAN
import CryptoKit
import Foundation
import SystemConfiguration

// MARK: - Location Authorization

/// Handles CoreLocation authorization so CWInterface.ssid() returns real values
/// on macOS Sequoia+ (which redacts SSID without Location Services permission).
class LocationDelegate: NSObject, CLLocationManagerDelegate {
  var onAuthorized: (() -> Void)?

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let status = manager.authorizationStatus
    if status == .authorizedAlways || status == .authorized {
      onAuthorized?()
    }
  }
}

// MARK: - Network Detection

/// On all modern Macs (Apple Silicon and Intel), the built-in WiFi is always en0.
/// This is a macOS-only tool (SketchyBar requirement), so we use this constant
/// instead of shelling out to `networksetup -listallhardwareports`.
let wifiInterface = "en0"

/// Get current WiFi SSID. Tries CoreWLAN first (requires Location Services +
/// NSApplication context), falls back to SSID_STR from SCDynamicStore AirPort state.
func getCurrentSSID(airportDict: [String: Any]?) -> String {
  if let iface = CWWiFiClient.shared().interface() {
    let cwSSID = iface.ssid()
    debug("CWInterface.ssid(): \(cwSSID ?? "nil")")
    if let ssid = cwSSID, !ssid.isEmpty {
      return ssid
    }
  }
  let fallback = airportDict?["SSID_STR"] as? String ?? ""
  debug("SSID_STR fallback: '\(fallback)'")
  return fallback
}

/// VPN/tunnel interfaces (Tailscale exit nodes, IKEv2, PPP) can become the
/// primary interface by installing a default route, masking the physical link.
func isVirtualInterface(_ name: String) -> Bool {
  ["utun", "ipsec", "ppp", "tun", "tap"].contains { name.hasPrefix($0) }
}

/// Resolve the underlying physical interface by walking the user's service
/// order and returning the first non-virtual service with active IPv4 state.
func resolvePhysicalInterface(store: SCDynamicStore) -> String? {
  guard
    let setupDict = SCDynamicStoreCopyValue(store, "Setup:/Network/Global/IPv4" as CFString)
      as? [String: Any],
    let serviceOrder = setupDict["ServiceOrder"] as? [String]
  else {
    return nil
  }
  for serviceID in serviceOrder {
    guard
      let serviceDict = SCDynamicStoreCopyValue(
        store, "State:/Network/Service/\(serviceID)/IPv4" as CFString) as? [String: Any],
      let iface = serviceDict["InterfaceName"] as? String,
      !isVirtualInterface(iface)
    else { continue }
    return iface
  }
  return nil
}

/// The primary interface, or the physical interface underneath it when the
/// primary is a tunnel. nil when there is no (physical) connection.
func primaryPhysicalInterface(store: SCDynamicStore) -> String? {
  guard
    let globalDict = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString)
      as? [String: Any],
    let primaryInterface = globalDict["PrimaryInterface"] as? String
  else {
    return nil
  }

  debug("Primary interface: \(primaryInterface)")

  guard isVirtualInterface(primaryInterface) else { return primaryInterface }
  if let physical = resolvePhysicalInterface(store: store) {
    debug("Primary is a tunnel; underlying physical interface: \(physical)")
    return physical
  }
  debug("Primary is a tunnel; no underlying physical interface found")
  return nil
}

/// Detect current network type and SSID from SCDynamicStore state.
func detectNetwork(store: SCDynamicStore) -> (type: String, ssid: String) {
  // 1. Read primary interface
  guard let primaryInterface = primaryPhysicalInterface(store: store) else {
    return ("disconnected", "")
  }

  // 2. Read AirPort state for hotspot detection and SSID fallback
  let airportDict = SCDynamicStoreCopyValue(
    store, "State:/Network/Interface/\(wifiInterface)/AirPort" as CFString) as? [String: Any]

  // 3. Get SSID (CoreWLAN with Location Services, or SCDynamicStore fallback)
  let ssid = getCurrentSSID(airportDict: airportDict)

  // 4. Determine connection type
  if primaryInterface == wifiInterface {
    // Check for hotspot via LastTetherDevice in AirPort state
    if airportDict?["LastTetherDevice"] != nil {
      debug("Detected: hotspot")
      return ("hotspot", ssid)
    }
    debug("Detected: wifi")
    return ("wifi", ssid)
  }

  debug("Detected: ethernet (interface: \(primaryInterface))")
  return ("ethernet", ssid)
}

// MARK: - Signal Quality

/// RSSI lower bounds (dBm) of signal levels 1...4; anything weaker is level 0.
let signalThresholds = [-80, -72, -65, -55]
/// dB the RSSI must move past a threshold before the level changes, so a
/// signal hovering around a threshold does not flicker between two levels.
let signalHysteresis = 3

/// Map an RSSI to a signal level 0-4, sticking to the previous level until
/// the RSSI clears the neighbouring threshold by the hysteresis margin.
func signalLevel(rssi: Int, previous: Int?) -> Int {
  guard let previous else { return signalThresholds.filter { rssi >= $0 }.count }
  return signalThresholds.enumerated().filter { index, threshold in
    rssi >= (index < previous ? threshold - signalHysteresis : threshold + signalHysteresis)
  }.count
}

/// Current RSSI of the WiFi interface, or nil when it is not associated.
func currentRSSI() -> Int? {
  guard let rssi = CWWiFiClient.shared().interface()?.rssiValue(), rssi != 0 else { return nil }
  return rssi
}

// MARK: - Details

/// IPv4 state of the first service in the user's service order that is bound
/// to the given interface (holds Addresses and Router).
func serviceIPv4(store: SCDynamicStore, interface: String) -> [String: Any]? {
  guard
    let setupDict = SCDynamicStoreCopyValue(store, "Setup:/Network/Global/IPv4" as CFString)
      as? [String: Any],
    let serviceOrder = setupDict["ServiceOrder"] as? [String]
  else {
    return nil
  }
  for serviceID in serviceOrder {
    if let serviceDict = SCDynamicStoreCopyValue(
      store, "State:/Network/Service/\(serviceID)/IPv4" as CFString) as? [String: Any],
      serviceDict["InterfaceName"] as? String == interface
    {
      return serviceDict
    }
  }
  return nil
}

/// Names of all services with active IPv4 state on a tunnel interface.
func connectedVPNNames(store: SCDynamicStore) -> [String] {
  guard
    let keys = SCDynamicStoreCopyKeyList(store, "State:/Network/Service/[^/]+/IPv4" as CFString)
      as? [String]
  else {
    return []
  }
  return keys.compactMap { key -> String? in
    guard
      let dict = SCDynamicStoreCopyValue(store, key as CFString) as? [String: Any],
      let iface = dict["InterfaceName"] as? String,
      isVirtualInterface(iface)
    else { return nil }
    let serviceID = key.split(separator: "/")[3]
    let setup = SCDynamicStoreCopyValue(store, "Setup:/Network/Service/\(serviceID)" as CFString)
      as? [String: Any]
    return setup?["UserDefinedName"] as? String ?? iface
  }.sorted()
}

func bandName(_ band: CWChannelBand) -> String {
  switch band {
  case .band2GHz: return "2.4 GHz"
  case .band5GHz: return "5 GHz"
  case .band6GHz: return "6 GHz"
  default: return ""
  }
}

func widthName(_ width: CWChannelWidth) -> String {
  switch width {
  case .width20MHz: return "20 MHz"
  case .width40MHz: return "40 MHz"
  case .width80MHz: return "80 MHz"
  case .width160MHz: return "160 MHz"
  default: return ""
  }
}

func phyName(_ mode: CWPHYMode, band: CWChannelBand?) -> String {
  switch mode {
  case .mode11be: return "Wi-Fi 7 (802.11be)"
  case .mode11ax: return band == .band6GHz ? "Wi-Fi 6E (802.11ax)" : "Wi-Fi 6 (802.11ax)"
  case .mode11ac: return "Wi-Fi 5 (802.11ac)"
  case .mode11n: return "Wi-Fi 4 (802.11n)"
  case .mode11a: return "802.11a"
  case .mode11b: return "802.11b"
  case .mode11g: return "802.11g"
  default: return ""
  }
}

func securityName(_ security: CWSecurity) -> String {
  switch security {
  case .none: return "Open"
  case .WEP, .dynamicWEP: return "WEP"
  case .wpaPersonal, .wpaPersonalMixed: return "WPA Personal"
  case .wpa2Personal, .personal: return "WPA2 Personal"
  case .wpa3Personal: return "WPA3 Personal"
  case .wpa3Transition: return "WPA2/WPA3 Personal"
  case .wpaEnterprise, .wpaEnterpriseMixed: return "WPA Enterprise"
  case .wpa2Enterprise, .enterprise: return "WPA2 Enterprise"
  case .wpa3Enterprise: return "WPA3 Enterprise"
  case .OWE, .oweTransition: return "Enhanced Open (OWE)"
  default: return ""
  }
}

/// Gather the popup details for the current network as env var assignments.
func networkDetails(store: SCDynamicStore) -> [String] {
  let interface = lastType == "disconnected" ? nil : primaryPhysicalInterface(store: store)
  let ipv4 = interface.flatMap { serviceIPv4(store: store, interface: $0) }
  var vars = [
    "NETWORK_TYPE=\(lastType)",
    "NETWORK_SSID=\(lastSSID)",
    "NETWORK_SIGNAL=\(lastSignal.map(String.init) ?? "")",
    "NETWORK_INTERFACE=\(interface ?? "")",
    "NETWORK_IP=\((ipv4?["Addresses"] as? [String])?.first ?? "")",
    "NETWORK_ROUTER=\(ipv4?["Router"] as? String ?? "")",
    "NETWORK_VPN=\(connectedVPNNames(store: store).joined(separator: ", "))",
  ]

  let wifi = interface == wifiInterface ? CWWiFiClient.shared().interface() : nil
  let channel = wifi?.wlanChannel()
  let channelParts =
    channel.map { [String($0.channelNumber), bandName($0.channelBand), widthName($0.channelWidth)] }
    ?? []
  vars += [
    "NETWORK_RSSI=\(wifi.map { String($0.rssiValue()) } ?? "")",
    "NETWORK_NOISE=\(wifi.map { String($0.noiseMeasurement()) } ?? "")",
    "NETWORK_TX_RATE=\(wifi.map { String(Int($0.transmitRate().rounded())) } ?? "")",
    "NETWORK_CHANNEL=\(channelParts.filter { !$0.isEmpty }.joined(separator: " · "))",
    "NETWORK_PHY=\(wifi.map { phyName($0.activePHYMode(), band: channel?.channelBand) } ?? "")",
    "NETWORK_SECURITY=\(wifi.map { securityName($0.security()) } ?? "")",
  ]
  return vars
}

/// Trigger a sketchybar custom event with the given env var assignments.
func triggerSketchybar(event: String, vars: [String]) {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = ["sketchybar", "--trigger", event] + vars
  process.standardOutput = FileHandle.nullDevice
  process.standardError = FileHandle.nullDevice
  do { try process.run() } catch {}
}

// MARK: - SSID Hash

/// Honours $HOME (like the sketchybar-ssid-hash helper), falling back to the
/// account home directory when it is unset or empty.
let homeDir: String = {
  if let home = ProcessInfo.processInfo.environment["HOME"], !home.isEmpty { return home }
  return FileManager.default.homeDirectoryForCurrentUser.path
}()
let saltPath = (homeDir as NSString).appendingPathComponent(".config/dotfiles/hash-salt")

/// Read the HMAC salt from ~/.config/dotfiles/hash-salt, trimming surrounding whitespace and
/// newlines. Returns "" (and warns once on stderr) if missing or empty.
func loadSalt() -> String {
  let raw = (try? String(contentsOfFile: saltPath, encoding: .utf8)) ?? ""
  let salt = raw.trimmingCharacters(in: .whitespacesAndNewlines)
  if salt.isEmpty {
    fputs(
      "sketchybar-network-watcher: salt file ~/.config/dotfiles/hash-salt missing or empty; "
        + "SSID hashes disabled (run chezmoi apply)\n", stderr)
  }
  return salt
}

let hashSalt: String = loadSalt()

/// Lowercase hex HMAC-SHA256 of the SSID's UTF-8 bytes keyed with the salt, or
/// "" for an empty SSID or missing salt. Must match
/// `printf '%s' "$SSID" | openssl dgst -sha256 -hmac "$SALT" | awk '{print $NF}'`.
func ssidHash(_ ssid: String) -> String {
  guard !ssid.isEmpty, !hashSalt.isEmpty else { return "" }
  let mac = HMAC<SHA256>.authenticationCode(
    for: Data(ssid.utf8), using: SymmetricKey(data: Data(hashSalt.utf8)))
  return mac.map { String(format: "%02x", $0) }.joined()
}

// MARK: - Debug

let debugMode = CommandLine.arguments.contains("--debug")
let onceMode = CommandLine.arguments.contains("--once")

func debug(_ msg: String) {
  if debugMode {
    fputs("[DEBUG] \(msg)\n", stderr)
  }
}

// MARK: - Main

// Initialize NSApplication so CoreWLAN recognizes us as an app context
// (required for CWInterface.ssid() to return non-nil with Location Services)
let _ = NSApplication.shared

// Request Location Services authorization (needed for CWInterface.ssid() on Sequoia+)
let locationManager = CLLocationManager()
let locationDelegate = LocationDelegate()
locationManager.delegate = locationDelegate

// Create SCDynamicStore with callback
var context = SCDynamicStoreContext(
  version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)

// Debounce state
var debounceTimer: DispatchSourceTimer?
let debounceQueue = DispatchQueue(label: "network-watcher.debounce")

// Last sent network state; only accessed on debounceQueue
var lastType = "disconnected"
var lastSSID = ""
var lastHash = ""
var lastSignal: Int?

// Detail mode end; only accessed on debounceQueue
let detailModeTimeout: TimeInterval = 300
var detailModeUntil: Date?
var detailModeActive: Bool { detailModeUntil.map { $0 > Date() } ?? false }

func triggerLastState() {
  triggerSketchybar(
    event: "network_info_change",
    vars: [
      "NETWORK_TYPE=\(lastType)",
      "NETWORK_SSID=\(lastSSID)",
      "NETWORK_SSID_HASH=\(lastHash)",
      "NETWORK_SIGNAL=\(lastSignal.map(String.init) ?? "")",
    ])
}

/// Send the popup details if detail mode is on. Must run on debounceQueue.
func triggerDetailsIfActive(store: SCDynamicStore) {
  guard detailModeActive else { return }
  triggerSketchybar(event: "network_details_change", vars: networkDetails(store: store))
}

/// Detect the network and send it to sketchybar. Must run on debounceQueue.
func detectAndTrigger(store: SCDynamicStore) {
  (lastType, lastSSID) = detectNetwork(store: store)
  lastHash = ssidHash(lastSSID)
  if lastType == "wifi", let rssi = currentRSSI() {
    lastSignal = signalLevel(rssi: rssi, previous: lastSignal)
    debug("RSSI: \(rssi) dBm, signal level \(lastSignal!)")
  } else {
    lastSignal = nil
  }
  debug("Result: type=\(lastType), ssid=\(lastSSID)")
  debug("SSID hash: \(lastHash)")
  triggerLastState()
  triggerDetailsIfActive(store: store)
}

func scheduleDetection(store: SCDynamicStore) {
  debounceQueue.async {
    debounceTimer?.cancel()
    let timer = DispatchSource.makeTimerSource(queue: debounceQueue)
    timer.schedule(deadline: .now() + 1.0)
    timer.setEventHandler {
      detectAndTrigger(store: store)
    }
    timer.resume()
    debounceTimer = timer
  }
}

/// Receives CoreWLAN link quality events (every few seconds while associated)
/// and re-triggers sketchybar only when the signal level changes, plus the
/// details on every event while detail mode is on.
class LinkQualityDelegate: NSObject, CWEventDelegate {
  let store: SCDynamicStore

  init(store: SCDynamicStore) {
    self.store = store
  }

  func linkQualityDidChangeForWiFiInterface(
    withName interfaceName: String, rssi: Int, transmitRate: Double
  ) {
    debounceQueue.async { [store] in
      if lastType == "wifi", rssi != 0 {
        let level = signalLevel(rssi: rssi, previous: lastSignal)
        if level != lastSignal {
          debug("RSSI: \(rssi) dBm, signal level \(lastSignal.map(String.init) ?? "-") -> \(level)")
          lastSignal = level
          triggerLastState()
        }
      }
      triggerDetailsIfActive(store: store)
    }
  }
}

let callback: SCDynamicStoreCallBack = { store, changedKeys, info in
  scheduleDetection(store: store)
}

guard
  let store = SCDynamicStoreCreate(
    nil, "sketchybar-network-watcher" as CFString, callback, &context)
else {
  fputs("Failed to create SCDynamicStore\n", stderr)
  exit(1)
}

// Re-detect when location authorization changes (SSID becomes available).
// In --once mode the one-shot block below handles this itself.
if !onceMode {
  locationDelegate.onAuthorized = {
    scheduleDetection(store: store)
  }
}

// Request authorization — on first run this shows a system dialog,
// subsequent runs use the saved preference.
locationManager.requestAlwaysAuthorization()

// MARK: - One-shot Mode

// --once: detect a single time, print `<type>\t<ssid>\t<hash>` and exit.
// No sketchybar trigger, no notification keys, no run loop.
if onceMode {
  debug("WiFi interface: \(wifiInterface)")
  debug("Location auth: \(locationManager.authorizationStatus.rawValue)")
  var (onceType, onceSSID) = detectNetwork(store: store)

  // Location authorization may still be resolving; give it a short grace
  // period (pumping the run loop so the delegate can fire) and retry once.
  if onceSSID.isEmpty && locationManager.authorizationStatus == .notDetermined {
    debug("SSID empty and location auth not determined; waiting briefly")
    let deadline = Date().addingTimeInterval(1.5)
    while locationManager.authorizationStatus == .notDetermined && Date() < deadline {
      _ = RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.1))
    }
    debug("Location auth after wait: \(locationManager.authorizationStatus.rawValue)")
    (onceType, onceSSID) = detectNetwork(store: store)
  }

  let onceHash = ssidHash(onceSSID)
  debug("Once result: type=\(onceType), ssid=\(onceSSID)")
  debug("SSID hash: \(onceHash)")
  print("\(onceType)\t\(onceSSID)\t\(onceHash)")
  fflush(stdout)
  exit(0)
}

// MARK: - Watch Loop

// Watch for primary interface and WiFi/AirPort state changes
let watchedKeys: [CFString] = [
  "State:/Network/Global/IPv4" as CFString,
  "State:/Network/Interface/en0/AirPort" as CFString,
]

guard SCDynamicStoreSetNotificationKeys(store, watchedKeys as CFArray, nil) else {
  fputs("Failed to set notification keys\n", stderr)
  exit(1)
}

guard let runLoopSource = SCDynamicStoreCreateRunLoopSource(nil, store, 0) else {
  fputs("Failed to create run loop source\n", stderr)
  exit(1)
}

CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)

// Watch WiFi signal strength; CWWiFiClient holds its delegate weakly
let linkQualityDelegate = LinkQualityDelegate(store: store)
CWWiFiClient.shared().delegate = linkQualityDelegate
do {
  try CWWiFiClient.shared().startMonitoringEvent(with: .linkQualityDidChange)
} catch {
  fputs("Failed to monitor WiFi link quality: \(error)\n", stderr)
}

// Handle SIGTERM for clean exit
signal(SIGTERM) { _ in
  exit(0)
}
signal(SIGINT) { _ in
  exit(0)
}

// Detail mode toggles from the SketchyBar popup (USR1 on open, USR2 on close)
signal(SIGUSR1, SIG_IGN)
signal(SIGUSR2, SIG_IGN)
let detailOnSource = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: debounceQueue)
detailOnSource.setEventHandler {
  debug("Detail mode on")
  detailModeUntil = Date().addingTimeInterval(detailModeTimeout)
  triggerDetailsIfActive(store: store)
}
detailOnSource.resume()
let detailOffSource = DispatchSource.makeSignalSource(signal: SIGUSR2, queue: debounceQueue)
detailOffSource.setEventHandler {
  debug("Detail mode off")
  detailModeUntil = nil
}
detailOffSource.resume()

// Initial detection and trigger
debug("WiFi interface: \(wifiInterface)")
debug("Location auth: \(locationManager.authorizationStatus.rawValue)")
debounceQueue.sync {
  detectAndTrigger(store: store)
}

// Re-send the state once more after 2 s. network_type.lua starts this daemon
// from inside SbarLua's config transaction, and SbarLua buffers item creation
// and event subscriptions until its event loop starts, so the first trigger
// above can race the item's subscription and be lost (leaving the item on
// "disconnected" until the next network change).
DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
  scheduleDetection(store: store)
}

// Run the event loop
CFRunLoopRun()
