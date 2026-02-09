import AppKit
import CoreLocation
import CoreWLAN
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

/// Detect current network type and SSID from SCDynamicStore state.
func detectNetwork(store: SCDynamicStore) -> (type: String, ssid: String) {
  // 1. Read primary interface
  guard
    let globalDict = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString)
      as? [String: Any],
    let primaryInterface = globalDict["PrimaryInterface"] as? String
  else {
    return ("disconnected", "")
  }

  debug("Primary interface: \(primaryInterface)")

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
func triggerSketchybar(type: String, ssid: String) {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = [
    "sketchybar", "--trigger", "network_info_change",
    "NETWORK_TYPE=\(type)",
    "NETWORK_SSID=\(ssid)",
  ]
  process.standardOutput = FileHandle.nullDevice
  process.standardError = FileHandle.nullDevice
  do { try process.run() } catch {}
}

// MARK: - Debug

let debugMode = CommandLine.arguments.contains("--debug")

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
      debug("Result: type=\(networkType), ssid=\(ssid)")
      triggerSketchybar(type: networkType, ssid: ssid)
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

// Re-detect when location authorization changes (SSID becomes available)
locationDelegate.onAuthorized = {
  scheduleDetection(store: store)
}

// Request authorization — on first run this shows a system dialog,
// subsequent runs use the saved preference.
locationManager.requestAlwaysAuthorization()

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
debug("Initial result: type=\(initialType), ssid=\(initialSSID)")
triggerSketchybar(type: initialType, ssid: initialSSID)

// Run the event loop
CFRunLoopRun()
