// sketchybar-network-watcher: watches SCDynamicStore for network changes and
// triggers `sketchybar --trigger network_info_change` with these env vars:
//   NETWORK_TYPE       wifi | hotspot | ethernet | disconnected
//   NETWORK_SSID       current WiFi SSID (empty if unknown)
//   NETWORK_SSID_HASH  lowercase hex HMAC-SHA256 of the SSID's UTF-8 bytes, keyed
//                      with the salt (empty if no SSID or no salt); equals
//                      `printf '%s' "$SSID" | openssl dgst -sha256 -hmac "$SALT" | awk '{print $NF}'`
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

/// Detect current network type and SSID from SCDynamicStore state.
func detectNetwork(store: SCDynamicStore) -> (type: String, ssid: String) {
  // 1. Read primary interface
  guard
    let globalDict = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString)
      as? [String: Any],
    var primaryInterface = globalDict["PrimaryInterface"] as? String
  else {
    return ("disconnected", "")
  }

  debug("Primary interface: \(primaryInterface)")

  if isVirtualInterface(primaryInterface) {
    if let physical = resolvePhysicalInterface(store: store) {
      debug("Primary is a tunnel; underlying physical interface: \(physical)")
      primaryInterface = physical
    } else {
      debug("Primary is a tunnel; no underlying physical interface found")
      return ("disconnected", "")
    }
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

/// Trigger sketchybar custom event with network info as env vars.
func triggerSketchybar(type: String, ssid: String, hash: String) {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = [
    "sketchybar", "--trigger", "network_info_change",
    "NETWORK_TYPE=\(type)",
    "NETWORK_SSID=\(ssid)",
    "NETWORK_SSID_HASH=\(hash)",
  ]
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

func scheduleDetection(store: SCDynamicStore) {
  debounceQueue.async {
    debounceTimer?.cancel()
    let timer = DispatchSource.makeTimerSource(queue: debounceQueue)
    timer.schedule(deadline: .now() + 1.0)
    timer.setEventHandler {
      let (networkType, ssid) = detectNetwork(store: store)
      let hash = ssidHash(ssid)
      debug("Result: type=\(networkType), ssid=\(ssid)")
      debug("SSID hash: \(hash)")
      triggerSketchybar(type: networkType, ssid: ssid, hash: hash)
    }
    timer.resume()
    debounceTimer = timer
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

// Handle SIGTERM for clean exit
signal(SIGTERM) { _ in
  exit(0)
}
signal(SIGINT) { _ in
  exit(0)
}

// Initial detection and trigger
debug("WiFi interface: \(wifiInterface)")
debug("Location auth: \(locationManager.authorizationStatus.rawValue)")
let (initialType, initialSSID) = detectNetwork(store: store)
let initialHash = ssidHash(initialSSID)
debug("Initial result: type=\(initialType), ssid=\(initialSSID)")
debug("SSID hash: \(initialHash)")
triggerSketchybar(type: initialType, ssid: initialSSID, hash: initialHash)

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
