import Flutter
import Foundation
import WatchConnectivity

/// Bridges Flutter's `wegwiesel/watch` method channel to the paired Apple
/// Watch via WatchConnectivity.
///
/// Outgoing data uses `transferUserInfo`, which queues the payload when
/// the watch is asleep or out of range — so the watch sees the latest
/// state whenever it next wakes up. We additionally call `sendMessage`
/// when the watch is reachable for sub-second updates.
final class WatchBridge: NSObject, WCSessionDelegate, FlutterPlugin {
  static let channelName = "wegwiesel/watch"
  private weak var channel: FlutterMethodChannel?
  private var session: WCSession?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    let bridge = WatchBridge(channel: channel)
    registrar.addMethodCallDelegate(bridge, channel: channel)
  }

  init(channel: FlutterMethodChannel) {
    self.channel = channel
    super.init()
    if WCSession.isSupported() {
      let s = WCSession.default
      s.delegate = self
      s.activate()
      self.session = s
    }
  }

  // MARK: - FlutterMethodCallDelegate

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isReachable":
      result(session?.isReachable ?? false)

    case "updateNavigation":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "bad_args", message: "expected map", details: nil))
        return
      }
      sendNavigation(payload: args)
      result(nil)

    case "stopNavigation":
      sendNavigation(payload: ["direction": "idle"])
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Outbound

  private func sendNavigation(payload: [String: Any]) {
    guard let session = session, session.activationState == .activated else { return }

    // transferUserInfo is queued + delivered next time the watch is awake.
    // It's the right primitive for "current navigation state — replace
    // whatever's queued so we don't process stale instructions".
    session.transferUserInfo(payload)

    // When the watch is reachable (e.g. user is glancing at it right
    // now), also push via sendMessage so the UI updates in real time.
    if session.isReachable {
      session.sendMessage(payload, replyHandler: nil) { _ in
        // ignore — the userInfo transfer above will deliver eventually
      }
    }
  }

  // MARK: - WCSessionDelegate

  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    // No-op — we only push from phone to watch in v2.2 phase 1.
  }

  // Required on iOS even if we don't do anything useful with them yet.
  func sessionDidBecomeInactive(_ session: WCSession) {}
  func sessionDidDeactivate(_ session: WCSession) {
    // Re-activate for the next paired watch.
    WCSession.default.activate()
  }
}
