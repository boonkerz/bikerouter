import Foundation
import WatchConnectivity

/// Receives navigation payloads from the iPhone via WatchConnectivity and
/// exposes them to SwiftUI as observable state. The phone sends both
/// transient `sendMessage`s (when the watch is reachable + foregrounded)
/// and durable `transferUserInfo`s (queued for later) — we route both
/// into the same applyPayload path so the UI sees the freshest snapshot.
final class WatchSessionController: NSObject, ObservableObject, WCSessionDelegate {
  @Published private(set) var direction: TurnDirection = .idle
  @Published private(set) var distanceToTurnMeters: Int = 0
  @Published private(set) var remainingKm: Double = 0
  @Published private(set) var remainingMinutes: Int = 0
  @Published private(set) var streetName: String?

  func activate() {
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    session.delegate = self
    session.activate()
  }

  // MARK: - WCSessionDelegate

  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    // No-op
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    applyPayload(message)
  }

  func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
    applyPayload(userInfo)
  }

  // MARK: - Payload routing

  private func applyPayload(_ payload: [String: Any]) {
    DispatchQueue.main.async {
      let id = (payload["direction"] as? String) ?? "idle"
      self.direction = TurnDirection(rawId: id)
      self.distanceToTurnMeters = (payload["distanceMeters"] as? Int) ?? 0
      self.remainingKm = (payload["remainingKm"] as? Double) ?? 0
      self.remainingMinutes = (payload["remainingMinutes"] as? Int) ?? 0
      self.streetName = payload["streetName"] as? String
    }
  }
}

/// Coarse direction set matching the Dart WatchTurnDirection enum.
enum TurnDirection: String, CaseIterable {
  case idle
  case straight
  case slightLeft = "slight_left"
  case left
  case sharpLeft = "sharp_left"
  case uTurn = "u_turn"
  case sharpRight = "sharp_right"
  case right
  case slightRight = "slight_right"
  case arrived

  init(rawId: String) {
    self = TurnDirection.allCases.first { $0.rawValue == rawId } ?? .idle
  }

  /// SF Symbol that visually conveys the maneuver. Watch faces render
  /// these crisp at all sizes.
  var symbolName: String {
    switch self {
    case .idle: return "location.slash"
    case .straight: return "arrow.up"
    case .slightLeft: return "arrow.up.left"
    case .left: return "arrow.turn.up.left"
    case .sharpLeft: return "arrow.uturn.left"
    case .uTurn: return "arrow.uturn.up"
    case .slightRight: return "arrow.up.right"
    case .right: return "arrow.turn.up.right"
    case .sharpRight: return "arrow.uturn.right"
    case .arrived: return "flag.checkered"
    }
  }
}
