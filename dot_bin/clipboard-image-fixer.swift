import AppKit
import Foundation
import UserNotifications

// clipboard-image-fixer
//
// "Copy image" in a Chromium browser puts two things on the clipboard: the
// picture itself (PNG) and an HTML snippet `<img src="...">`. Some web apps
// hand out images under blob: URLs (ChatGPT's generated images, for one). A
// blob: URL only exists inside the tab that created it, so an app that
// prefers the HTML flavour over the PNG pastes an <img> it cannot load.
// Microsoft Teams does exactly that: Cmd+V silently inserts nothing.
//
// This daemon drops the HTML flavour, keeps the PNG and posts a notification.
// It does not poll:
// macOS has no public "clipboard changed" event, so instead it waits for the
// one moment the fix matters, a target app becoming frontmost, and looks at
// the clipboard once. Between activations it sleeps in the run loop.
//
// The clipboard is only rewritten when the HTML is nothing but a single
// <img> with a blob: source and real image data sits next to it. Rich text,
// images with ordinary URLs and everything else are left alone.
//
// Usage: clipboard-image-fixer [--app BUNDLE_ID]... [--once] [--debug]
//   --app    bundle id to watch; repeatable (default: com.microsoft.teams2)
//   --once   check the clipboard now, whatever is frontmost, and exit
//   --debug  log every activation and every skipped clipboard
// SIGUSR1 forces a check (handy for testing).
// Notifications need the .app bundle and a start through launchd or `open`;
// started from a shell (and with --once) the daemon works without them.
// macOS also refuses them for a bundle that lives under /tmp.

func argValues(_ flag: String) -> [String] {
  let args = CommandLine.arguments
  return args.indices.filter { args[$0] == flag && $0 + 1 < args.count }.map { args[$0 + 1] }
}
let targetApps: Set<String> = {
  let given = argValues("--app")
  return given.isEmpty ? ["com.microsoft.teams2"] : Set(given)
}()
let debugMode = CommandLine.arguments.contains("--debug")
let runOnce = CommandLine.arguments.contains("--once")

func log(_ msg: String) {
  let ts = ISO8601DateFormatter().string(from: Date())
  print("\(ts) \(msg)")
  fflush(stdout)
}
func debug(_ msg: String) { if debugMode { log("debug: \(msg)") } }

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner])
  }
}
let notificationDelegate = NotificationDelegate()
var notificationsReady = false

func setupNotifications() {
  // UNUserNotificationCenter raises an exception outside an app bundle.
  guard Bundle.main.bundleIdentifier != nil else {
    log("not running from an app bundle, notifications off")
    return
  }
  let center = UNUserNotificationCenter.current()
  center.delegate = notificationDelegate
  notificationsReady = true
  center.requestAuthorization(options: [.alert]) { granted, error in
    log("notification permission: granted=\(granted)\(error.map { " error=\($0)" } ?? "")")
    if granted { notifyReady() }
  }
}

/// Posted once per start, silently: shows the daemon is up and, on the very
/// first start, follows the permission prompt.
func notifyReady() {
  let content = UNMutableNotificationContent()
  content.title = "Clipboard Image Fixer"
  content.body = "Bereit."
  let request = UNNotificationRequest(
    identifier: "clipboard-image-fixer-ready", content: content, trigger: nil)
  UNUserNotificationCenter.current().add(request) { error in
    if let error { log("notification failed: \(error)") }
  }
}

/// Silent banner; a newer one replaces the previous instead of stacking up.
func notify(_ message: String) {
  guard notificationsReady else { return }
  let content = UNMutableNotificationContent()
  content.title = "Clipboard Image Fixer"
  content.body = message
  let request = UNNotificationRequest(
    identifier: "clipboard-image-fixer", content: content, trigger: nil)
  UNUserNotificationCenter.current().add(request) { error in
    if let error { log("notification failed: \(error)") }
  }
}

/// True when the HTML consists of exactly one <img> whose source is a blob: URL.
func isLoneBlobImage(_ html: String) -> Bool {
  var body = html
  // Wrappers the browser and the pasteboard add around the fragment.
  for pattern in [
    "(?is)<!--.*?-->",
    "(?is)<head\\b.*?</head\\s*>",
    "(?i)</?(?:html|body|meta)\\b[^>]*>",
  ] {
    body = body.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
  }
  body = body.trimmingCharacters(in: .whitespacesAndNewlines)
  let loneBlobImg = "(?is)^<img\\b[^>]*\\ssrc\\s*=\\s*[\"']?blob:[^>]*>$"
  return body.range(of: loneBlobImg, options: .regularExpression) != nil
}

/// Looks at the clipboard once; rewrites it to image-only if it is the broken kind.
@discardableResult
func fixClipboard(reason: String, appName: String? = nil) -> Bool {
  let pb = NSPasteboard.general
  // Reading the type list is cheap and does not touch the data.
  guard let types = pb.types, types.contains(.html) else {
    debug("\(reason): no HTML on the clipboard, nothing to do")
    return false
  }
  guard let imageType = [NSPasteboard.PasteboardType.png, .tiff].first(where: types.contains)
  else {
    debug("\(reason): HTML without image data, left alone")
    return false
  }
  guard let html = pb.string(forType: .html), isLoneBlobImage(html) else {
    debug("\(reason): HTML is not a lone blob: image, left alone")
    return false
  }
  guard let image = pb.data(forType: imageType), !image.isEmpty else {
    log("\(reason): blob: image HTML found but no readable \(imageType.rawValue) data, left alone")
    return false
  }
  pb.clearContents()
  guard pb.setData(image, forType: imageType) else {
    log("\(reason): failed to write the image back to the clipboard")
    return false
  }
  log("\(reason): dropped blob: HTML, kept \(imageType.rawValue) (\(image.count) bytes)")
  if let appName {
    notify("Bild in der Zwischenablage bereinigt, lässt sich jetzt in \(appName) einfügen.")
  } else {
    notify("Bild in der Zwischenablage bereinigt.")
  }
  return true
}

if runOnce {
  exit(fixClipboard(reason: "once") ? 0 : 1)
}

let app = NSApplication.shared
setupNotifications()

NSWorkspace.shared.notificationCenter.addObserver(
  forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
) { note in
  let activated = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
  let bundleID = activated?.bundleIdentifier ?? "?"
  guard targetApps.contains(bundleID) else {
    debug("activated \(bundleID), not a target")
    return
  }
  fixClipboard(reason: "activated \(bundleID)", appName: activated?.localizedName)
}

// Manual trigger for testing: kill -USR1 <pid>
let usr1 = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: .main)
signal(SIGUSR1, SIG_IGN)
usr1.setEventHandler { fixClipboard(reason: "SIGUSR1") }
usr1.resume()

signal(SIGTERM) { _ in exit(0) }
signal(SIGINT) { _ in exit(0) }

log("started: fixing blob: image clipboards for \(targetApps.sorted().joined(separator: ", "))")
// A target may already be frontmost when the agent starts.
if let front = NSWorkspace.shared.frontmostApplication, let bundleID = front.bundleIdentifier,
  targetApps.contains(bundleID)
{
  fixClipboard(reason: "startup, \(bundleID) frontmost", appName: front.localizedName)
}
app.run()  // AppKit run loop: pumps WindowServer notifications, unlike RunLoop.main.run()
