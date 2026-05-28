import Combine
import CoreLocation
import Foundation
import WatchKit

/// Watch-side standalone navigation: drives the same kind of glance
/// state the phone normally pushes (direction + distance-to-turn +
/// remaining km), but computes it locally from CoreLocation while the
/// phone is out of reach.
///
/// Lifecycle: [start] when the user taps "Start" on RouteDetailView,
/// [stop] when they exit the navigation view or arrive. We keep the
/// engine cheap-to-build so SwiftUI can hold it in @StateObject.
///
/// Off-route detection uses a fixed 75m threshold + 3-sample
/// hysteresis — the same logic shape the phone uses, just compiled
/// to native instead of going through Dart.
final class NavigationEngine: NSObject, ObservableObject, CLLocationManagerDelegate {
  @Published private(set) var direction: TurnDirection = .straight
  @Published private(set) var distanceToTurnMeters: Int = 0
  @Published private(set) var remainingKm: Double = 0
  @Published private(set) var offRoute: Bool = false
  @Published private(set) var arrived: Bool = false
  @Published private(set) var hasFix: Bool = false

  private let route: StoredRoute
  private let coords: [CLLocationCoordinate2D]
  private let turns: [StoredRoute.TurnHint]
  private let locationManager = CLLocationManager()

  // Index into `coords` of the closest segment we're on. Monotonic
  // forward — we only ever advance, never snap backwards onto an
  // earlier passage of the route.
  private var coordIdx: Int = 0
  private var consecutiveOffRoute: Int = 0
  // Last maneuver we vibrated for, so we don't re-buzz the same turn
  // while the user lingers inside the 80m / 30m thresholds.
  private var lastHapticHintIdx: Int = -1

  private static let offRouteThresholdM: Double = 75
  private static let offRouteConfirmSamples: Int = 3
  private static let arrivalThresholdM: Double = 30

  init(route: StoredRoute) {
    self.route = route
    self.coords = PolylineDecoder.decode(route.polyline)
    self.turns = route.turnHints
    super.init()
    locationManager.delegate = self
    // 5m filter — same as phone-side navigation. Watch GPS doesn't
    // need anything finer for turn-by-turn.
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.distanceFilter = 5
  }

  func start() {
    arrived = false
    offRoute = false
    consecutiveOffRoute = 0
    coordIdx = 0
    locationManager.requestWhenInUseAuthorization()
    locationManager.startUpdatingLocation()
  }

  func stop() {
    locationManager.stopUpdatingLocation()
  }

  // MARK: - CLLocationManagerDelegate

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let loc = locations.last else { return }
    hasFix = true
    advance(with: loc)
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    // Watch GPS sometimes drops out behind a wrist motion — that's
    // recoverable, no need to surface anything.
  }

  // MARK: - Routing core

  private func advance(with loc: CLLocation) {
    guard !coords.isEmpty, !arrived else { return }

    // Find the nearest coord index, biased forward so we don't snap
    // onto an earlier loop of the same route.
    let nearest = nearestForwardIndex(of: loc.coordinate)
    coordIdx = nearest

    // Arrival check against the last waypoint, not the last coord —
    // routes sometimes overshoot the destination by a few metres.
    if let last = route.waypoints.last {
      let endLoc = CLLocation(latitude: last.lat, longitude: last.lon)
      if loc.distance(from: endLoc) < Self.arrivalThresholdM {
        arrived = true
        direction = .arrived
        distanceToTurnMeters = 0
        remainingKm = 0
        playHaptic(.success)
        stop()
        return
      }
    }

    // Off-route detection: distance from the current track segment.
    let distOff = distanceToCurrentSegment(loc.coordinate)
    if distOff > Self.offRouteThresholdM {
      consecutiveOffRoute += 1
      if consecutiveOffRoute >= Self.offRouteConfirmSamples && !offRoute {
        offRoute = true
        playHaptic(.failure)
      }
    } else {
      if offRoute { offRoute = false }
      consecutiveOffRoute = 0
    }

    // Next maneuver: first turnHint whose coordIndex is at or after
    // the current position.
    let nextTurn = turns.first(where: { $0.idx >= coordIdx })
    if let turn = nextTurn {
      direction = TurnDirection(cmdName: turn.cmd)
      distanceToTurnMeters = distanceAlong(from: coordIdx, to: turn.idx).rounded().toInt()
      // Single haptic per turn at ~150m before we hit it.
      if distanceToTurnMeters < 150 && lastHapticHintIdx != turn.idx {
        playHaptic(.directionUp)
        lastHapticHintIdx = turn.idx
      }
    } else {
      direction = .straight
      distanceToTurnMeters = 0
    }

    // Remaining km to the end of the route.
    remainingKm = distanceAlong(from: coordIdx, to: coords.count - 1) / 1000.0
  }

  /// Iterates forward from the current index, biased to prefer
  /// staying ahead. We allow looking back ~10 indices in case GPS
  /// noise made us briefly overshoot, but no further.
  private func nearestForwardIndex(of c: CLLocationCoordinate2D) -> Int {
    let start = max(0, coordIdx - 10)
    var best = start
    var bestD = Double.greatestFiniteMagnitude
    for i in start..<coords.count {
      let p = coords[i]
      // squared planar distance is enough for nearest-point on short
      // path segments — cheaper than haversine in a tight loop.
      let dLat = p.latitude - c.latitude
      let dLon = p.longitude - c.longitude
      let d = dLat * dLat + dLon * dLon
      if d < bestD {
        bestD = d
        best = i
      }
    }
    return best
  }

  /// Perpendicular-ish distance from the user to the segment between
  /// coords[coordIdx-1] and coords[coordIdx]. Approximated as the
  /// haversine distance to coords[coordIdx] — sufficient at 5m GPS
  /// granularity, and saves a full segment-projection.
  private func distanceToCurrentSegment(_ c: CLLocationCoordinate2D) -> Double {
    guard coordIdx < coords.count else { return 0 }
    let target = coords[coordIdx]
    let a = CLLocation(latitude: c.latitude, longitude: c.longitude)
    let b = CLLocation(latitude: target.latitude, longitude: target.longitude)
    return a.distance(from: b)
  }

  /// Total along-track distance from `from` index to `to` index.
  private func distanceAlong(from: Int, to: Int) -> Double {
    let end = min(to, coords.count - 1)
    guard from < end else { return 0 }
    var sum: Double = 0
    var prev = coords[from]
    var i = from + 1
    while i <= end {
      let cur = coords[i]
      let a = CLLocation(latitude: prev.latitude, longitude: prev.longitude)
      let b = CLLocation(latitude: cur.latitude, longitude: cur.longitude)
      sum += a.distance(from: b)
      prev = cur
      i += 1
    }
    return sum
  }

  private func playHaptic(_ kind: WKHapticType) {
    DispatchQueue.main.async {
      WKInterfaceDevice.current().play(kind)
    }
  }
}

private extension Double {
  func toInt() -> Int { Int(self) }
}

extension TurnDirection {
  /// Maps the Dart TurnCmd enum *name* (e.g. "turnLeft", "straight")
  /// to the coarser watch direction. The phone serialises this via
  /// TurnCmd.name on the Dart side, so the wire string stays stable
  /// even if we reorder enum cases.
  init(cmdName: String) {
    switch cmdName {
    case "straight": self = .straight
    case "turnLeft": self = .left
    case "turnSlightLeft", "keepLeft": self = .slightLeft
    case "turnRight": self = .right
    case "turnSlightRight", "keepRight": self = .slightRight
    case "uTurn", "uTurnLeft", "uTurnRight": self = .uTurn
    case "roundabout1", "roundabout2", "roundabout3",
         "roundabout4", "roundabout5", "roundabout6",
         "roundaboutLeft":
      self = .right
    default: self = .straight
    }
  }
}
