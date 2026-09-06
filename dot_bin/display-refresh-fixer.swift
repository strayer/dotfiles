import AppKit
import Foundation
import UserNotifications

// display-refresh-fixer
//
// macOS 15.1+ no longer lists "3008x1692 HiDPI @ 144 Hz" as a display mode for
// the Dell G3223Q, so it never persists it. BetterDisplay can still switch the
// link timing ("unexposed refresh rate"), but only for the running session:
// every reconnect or wake drops the link back to 120 Hz.
//
// This daemon listens for display reconfiguration and system/screen wake,
// waits for the link to settle, and if the display is not at the target
// refresh rate, asks BetterDisplay to set it and posts a notification.
// Our own mode switch also fires a reconfiguration callback; the "already at
// target" check keeps that from looping.
//
// Usage: display-refresh-fixer [--display DELL] [--refresh 143.96Hz-VRR] [--debug]
// SIGUSR1 forces a check (handy for testing).
// Background: vault note "Dell G3223Q".

let betterDisplay = "/Applications/BetterDisplay.app/Contents/MacOS/BetterDisplay"

func argValue(_ flag: String, default def: String) -> String {
  let args = CommandLine.arguments
  if let i = args.firstIndex(of: flag), i + 1 < args.count { return args[i + 1] }
  return def
}
let displayName = argValue("--display", default: "DELL")
let targetRefresh = argValue("--refresh", default: "143.96Hz-VRR")
let debugMode = CommandLine.arguments.contains("--debug")

func log(_ msg: String) {
  let ts = ISO8601DateFormatter().string(from: Date())
  print("\(ts) \(msg)")
  fflush(stdout)
}
func debug(_ msg: String) { if debugMode { log("[debug] \(msg)") } }

/// Run a process with a timeout; returns (exit code, trimmed stdout). -1 on timeout/launch failure.
func run(_ path: String, _ args: [String], timeout: TimeInterval = 20) -> (Int32, String) {
  let p = Process()
  p.executableURL = URL(fileURLWithPath: path)
  p.arguments = args
  let pipe = Pipe()
  p.standardOutput = pipe
  p.standardError = FileHandle.nullDevice
  do { try p.run() } catch {
    log("failed to launch \(path): \(error)")
    return (-1, "")
  }
  let group = DispatchGroup()
  group.enter()
  DispatchQueue.global().async { p.waitUntilExit(); group.leave() }
  if group.wait(timeout: .now() + timeout) == .timedOut {
    p.terminate()
    log("timeout running \(path) \(args.joined(separator: " "))")
    return (-1, "")
  }
  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  let out = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
  return (p.terminationStatus, out)
}

/// Current refresh rate as reported by BetterDisplay, or nil if the display
/// is absent or BetterDisplay is not running.
func currentRefresh() -> String? {
  let (code, out) = run(betterDisplay, ["get", "-nameLike=\(displayName)", "-refreshRate"])
  debug("get -refreshRate -> code \(code), out '\(out)'")
  if code != 0 || out.isEmpty || out.hasPrefix("Failed") { return nil }
  return out
}

// Native notifications. Requires running from an .app bundle (see compile script);
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

func notify(_ message: String, ok: Bool) {
  let content = UNMutableNotificationContent()
  content.title = "Display Fixer"
  content.subtitle = ok ? "\(displayName): \(targetRefresh)" : "\(displayName): Fehler"
  content.body = message
  content.sound = .default
  let request = UNNotificationRequest(
    identifier: "display-refresh-fixer", content: content, trigger: nil)
  UNUserNotificationCenter.current().add(request) { error in
    if let error { log("notification failed: \(error)") }
  }
}

func fix(reason: String) {
  guard let before = currentRefresh() else {
    log("[\(reason)] display '\(displayName)' not available or BetterDisplay not running; skipping")
    return
  }
  if before == targetRefresh {
    log("[\(reason)] already at \(targetRefresh)")
    return
  }
  log("[\(reason)] at \(before), setting \(targetRefresh)")
  _ = run(betterDisplay, ["set", "-nameLike=\(displayName)", "-refreshRate=\(targetRefresh)"])
  Thread.sleep(forTimeInterval: 2)
  let after = currentRefresh() ?? "unbekannt"
  if after == targetRefresh {
    log("[\(reason)] ok: \(before) -> \(after)")
    notify("Link war auf \(before), jetzt \(after).", ok: true)
  } else {
    log("[\(reason)] FAILED: still \(after)")
    notify("Konnte \(targetRefresh) nicht setzen, Link ist \(after).", ok: false)
  }
}

// MARK: - Debounced scheduling

let queue = DispatchQueue(label: "display-refresh-fixer")
var pending: DispatchSourceTimer?
var pendingReason = ""

/// Wait `delay` seconds after the last event before acting, so the link has settled.
func schedule(reason: String, delay: TimeInterval = 5) {
  queue.async {
    pending?.cancel()
    pendingReason = reason
    let t = DispatchSource.makeTimerSource(queue: queue)
    t.schedule(deadline: .now() + delay)
    t.setEventHandler { fix(reason: pendingReason) }
    t.resume()
    pending = t
  }
}

// MARK: - Event sources

// Connect to the window server; CGDisplay reconfiguration callbacks are only
// delivered to processes with a WindowServer connection (same trick as the
// network watcher).
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)  // no Dock icon, no menu bar
setupNotifications()

// Display added/removed/mode changed. Ignore the "begin" flag; act on completion.
let reconfigCallback: CGDisplayReconfigurationCallBack = { display, flags, _ in
  if flags.contains(.beginConfigurationFlag) { return }
  debug("display reconfiguration: display \(display) flags \(flags.rawValue)")
  schedule(reason: "reconfigure")
}
CGDisplayRegisterReconfigurationCallback(reconfigCallback, nil)

// AppKit-level screen change notification (resolution, arrangement, connect).
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
nc.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: nil) { _ in
  debug("screens did wake")
  schedule(reason: "screens-wake", delay: 8)
}

// Manual trigger for testing: kill -USR1 <pid>
let usr1 = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: queue)
signal(SIGUSR1, SIG_IGN)
usr1.setEventHandler { schedule(reason: "SIGUSR1", delay: 0) }
usr1.resume()

signal(SIGTERM) { _ in exit(0) }
signal(SIGINT) { _ in exit(0) }

log("started: display=\(displayName) target=\(targetRefresh)")
schedule(reason: "startup", delay: 3)
app.run()  // AppKit run loop: pumps WindowServer notifications, unlike RunLoop.main.run()
