import AppKit
import ColorSync
import Foundation
import UserNotifications

// display-profile-fixer
//
// Dell Display and Peripheral Manager (DDPM) assigns its own ICC files from
// ~/Applications/DDPM/Profiles/ to Dell monitors whenever it starts. Those
// files are malformed: the primaries do not add up to the declared D50 white
// point. ColorSync silently normalises that, but Chromium, Firefox and
// Electron apps take the numbers literally. Result: those apps draw white as
// roughly rgb(242,255,255) on the display, and screenshots (which embed the
// display profile) turn pink once such an app decodes them.
//
// This daemon listens for colour profile changes, display reconfiguration and
// wake. If a display's profile is one of DDPM's files, it replaces it and
// posts a notification:
//   - DDPM's sRGB file -> the built-in "sRGB IEC61966-2.1" profile
//   - any other DDPM file -> the display's default macOS profile (from EDID)
// Profiles chosen by hand in System Settings are left alone.
//
// Usage: display-profile-fixer [--match /DDPM/Profiles/] [--debug]
// SIGUSR1 forces a check (handy for testing).

func argValue(_ flag: String, default def: String) -> String {
  let args = CommandLine.arguments
  if let i = args.firstIndex(of: flag), i + 1 < args.count { return args[i + 1] }
  return def
}
/// A display profile whose file path contains this string counts as unwanted.
let unwantedMarker = argValue("--match", default: "/DDPM/Profiles/")
let debugMode = CommandLine.arguments.contains("--debug")
let srgbProfile = URL(fileURLWithPath: "/System/Library/ColorSync/Profiles/sRGB Profile.icc")

func log(_ msg: String) {
  let ts = ISO8601DateFormatter().string(from: Date())
  print("\(ts) \(msg)")
  fflush(stdout)
}
func debug(_ msg: String) { if debugMode { log("[debug] \(msg)") } }

// MARK: - ColorSync

let displayClass = kColorSyncDisplayDeviceClass.takeUnretainedValue()

/// The custom profile assigned to a display, or nil if it uses its default profile.
func customProfile(of uuid: CFUUID) -> URL? {
  guard
    let info = ColorSyncDeviceCopyDeviceInfo(displayClass, uuid)?.takeRetainedValue()
      as? [String: Any],
    let custom = info[kColorSyncCustomProfiles.takeUnretainedValue() as String] as? [String: Any]
  else { return nil }
  let factory = info[kColorSyncFactoryProfiles.takeUnretainedValue() as String] as? [String: Any]
  let defaultID = factory?[kColorSyncDeviceDefaultProfileID.takeUnretainedValue() as String]
  let key = defaultID.map { "\($0)" } ?? "1"
  return custom[key] as? URL
}

/// Assigns `url` as the display's profile; nil restores the default macOS profile.
func setCustomProfile(of uuid: CFUUID, to url: URL?) -> Bool {
  let profile: Any = url.map { $0 as CFURL } ?? kCFNull as Any
  let request: [String: Any] = [
    kColorSyncDeviceDefaultProfileID.takeUnretainedValue() as String: profile,
    kColorSyncProfileUserScope.takeUnretainedValue() as String: kCFPreferencesCurrentUser,
  ]
  return ColorSyncDeviceSetCustomProfiles(displayClass, uuid, request as CFDictionary)
}

func profileName(_ url: URL) -> String {
  if let profile = ColorSyncProfileCreateWithURL(url as CFURL, nil)?.takeRetainedValue(),
    let name = ColorSyncProfileCopyDescriptionString(profile)?.takeRetainedValue()
  {
    return name as String
  }
  return url.lastPathComponent
}

/// What to use instead of an unwanted profile; nil means the default macOS profile.
func replacement(for unwanted: URL) -> URL? {
  unwanted.lastPathComponent.lowercased().contains("srgb") ? srgbProfile : nil
}

// MARK: - Notifications

// Native notifications. Requires running from an .app bundle (built by dot-services);
// the user approves the permission prompt once.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound])
  }
}
let notificationDelegate = NotificationDelegate()

func setupNotifications() {
  let center = UNUserNotificationCenter.current()
  center.delegate = notificationDelegate
  center.requestAuthorization(options: [.alert, .sound]) { granted, error in
    log("notification permission: granted=\(granted)\(error.map { " error=\($0)" } ?? "")")
  }
}

func notify(display: String, _ message: String, ok: Bool) {
  let content = UNMutableNotificationContent()
  content.title = "Display Profile Fixer"
  content.subtitle = ok ? display : "\(display): Fehler"
  content.body = message
  content.sound = .default
  let request = UNNotificationRequest(
    identifier: "display-profile-fixer-\(display)", content: content, trigger: nil)
  UNUserNotificationCenter.current().add(request) { error in
    if let error { log("notification failed: \(error)") }
  }
}

// MARK: - Fix

// If something keeps putting the unwanted profile back, stop fighting it
// instead of flipping the display profile (and notifying) in a loop.
let maxFixes = 3
let fixWindow: TimeInterval = 60
var recentFixes: [Date] = []
var backoffNotified = false

func fix(reason: String) {
  for screen in NSScreen.screens {
    let name = screen.localizedName
    guard
      let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
      let uuid = CGDisplayCreateUUIDFromDisplayID(number.uint32Value)?.takeRetainedValue()
    else { continue }
    guard let current = customProfile(of: uuid), current.path.contains(unwantedMarker) else {
      debug("[\(reason)] \(name): profile ok (\(screen.colorSpace?.localizedName ?? "unknown"))")
      continue
    }

    recentFixes.removeAll { $0.timeIntervalSinceNow < -fixWindow }
    if recentFixes.count >= maxFixes {
      log("[\(reason)] \(name): unwanted profile came back \(maxFixes)x within \(Int(fixWindow))s; backing off")
      if !backoffNotified {
        backoffNotified = true
        notify(
          display: name,
          "Farbprofil wird immer wieder zurückgesetzt. Pausiere, bis es sich beruhigt.", ok: false)
      }
      schedule(reason: "backoff-retry", delay: fixWindow)
      continue
    }

    let target = replacement(for: current)
    let before = profileName(current)
    let wanted = target.map(profileName) ?? "Standardprofil"
    log("[\(reason)] \(name): '\(before)' (\(current.path)) -> '\(wanted)'")
    let accepted = setCustomProfile(of: uuid, to: target)
    recentFixes.append(Date())
    let after = customProfile(of: uuid)
    if accepted && after == target {
      backoffNotified = false
      log("[\(reason)] \(name): ok")
      notify(display: name, "Farbprofil war „\(before)“, jetzt „\(wanted)“.", ok: true)
    } else {
      log("[\(reason)] \(name): FAILED (accepted=\(accepted), now \(after?.path ?? "default"))")
      notify(display: name, "Konnte „\(wanted)“ nicht setzen, Profil ist weiter „\(before)“.", ok: false)
    }
  }
}

// MARK: - Debounced scheduling

// Everything runs on the main queue: NSScreen is main-thread only and the
// ColorSync calls return quickly.
var pending: DispatchSourceTimer?

/// Wait `delay` seconds after the last event before acting, so a burst of
/// notifications leads to one check.
func schedule(reason: String, delay: TimeInterval = 2) {
  DispatchQueue.main.async {
    pending?.cancel()
    let t = DispatchSource.makeTimerSource(queue: .main)
    t.schedule(deadline: .now() + delay)
    t.setEventHandler { fix(reason: reason) }
    t.resume()
    pending = t
  }
}

// MARK: - Event sources

// Connect to the window server; screen notifications are only delivered to
// processes with a WindowServer connection (same trick as display-refresh-fixer).
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)  // no Dock icon, no menu bar
setupNotifications()

// A display's colour profile changed. This is what fires when DDPM (or
// System Settings) assigns a profile.
NotificationCenter.default.addObserver(
  forName: NSScreen.colorSpaceDidChangeNotification, object: nil, queue: nil
) { _ in
  debug("screen colour space changed")
  schedule(reason: "colorspace")
}

// Display connected, removed or rearranged.
NotificationCenter.default.addObserver(
  forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: nil
) { _ in
  debug("screen parameters changed")
  schedule(reason: "screen-params")
}

let nc = NSWorkspace.shared.notificationCenter
nc.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: nil) { _ in
  debug("system did wake")
  schedule(reason: "wake", delay: 8)
}

// Manual trigger for testing: kill -USR1 <pid>
let usr1 = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: .main)
signal(SIGUSR1, SIG_IGN)
usr1.setEventHandler { schedule(reason: "SIGUSR1", delay: 0) }
usr1.resume()

signal(SIGTERM) { _ in exit(0) }
signal(SIGINT) { _ in exit(0) }

log("started: replacing display profiles matching '\(unwantedMarker)'")
schedule(reason: "startup", delay: 3)
app.run()  // AppKit run loop: pumps WindowServer notifications, unlike RunLoop.main.run()
