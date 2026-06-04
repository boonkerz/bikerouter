import SwiftUI

/// Screenshot-generation support for the watch app. Entirely inert in normal
/// use: nothing here runs unless the app is launched with the environment
/// variable `WW_WATCH_SHOTS=1` (set by scripts/watch-screenshots.sh via
/// `SIMCTL_CHILD_WW_WATCH_SHOTS`). In that mode the app seeds deterministic
/// demo data and shows exactly one screen as its root, so an external
/// `xcrun simctl io <udid> screenshot` captures a clean, real render of it.
///
/// We capture via simctl rather than SwiftUI `ImageRenderer` because the
/// routes screen is built on `List` (UIKit-backed), which `ImageRenderer`
/// cannot rasterise reliably — a live simulator screenshot renders it exactly
/// as the user sees it.
enum WatchScreenshotMode {
  static var isEnabled: Bool {
    ProcessInfo.processInfo.environment["WW_WATCH_SHOTS"] == "1"
  }

  /// Which screen to show as root. Selected per-launch by the capture script.
  static var screen: String {
    ProcessInfo.processInfo.environment["WW_WATCH_SHOT"] ?? "routes"
  }

  /// Seeds demo routes (persisted so RoutesListView's onAppear reload keeps
  /// them) and a demo live-navigation snapshot.
  @MainActor
  static func seed(session: WatchSessionController, storage: RouteStorage) {
    for route in demoRoutes {
      storage.save(route)
    }
    session.seedForScreenshots(
      direction: .right,
      distanceMeters: 240,
      remainingKm: 12.4,
      remainingMinutes: 47,
      streetName: "Maximilianstraße"
    )
  }

  static let demoRoutes: [StoredRoute] = [
    StoredRoute(
      id: "demo-isar",
      name: "Isar-Radweg München",
      profile: "trekking",
      distanceKm: 24.6,
      ascentM: 120,
      timeMinutes: 94,
      polyline: "",
      waypoints: [
        .init(lat: 48.137, lon: 11.575, name: "München"),
        .init(lat: 48.165, lon: 11.520, name: "Schwabing"),
      ],
      turnHints: [],
      createdAt: "2026-06-01T09:00:00Z"
    ),
    StoredRoute(
      id: "demo-ammersee",
      name: "Ammersee-Runde",
      profile: "gravel",
      distanceKm: 51.2,
      ascentM: 310,
      timeMinutes: 188,
      polyline: "",
      waypoints: [
        .init(lat: 47.973, lon: 11.110, name: "Herrsching"),
      ],
      turnHints: [],
      createdAt: "2026-05-30T14:20:00Z"
    ),
    StoredRoute(
      id: "demo-alpen",
      name: "Tegernsee Gipfeltour",
      profile: "mtb",
      distanceKm: 18.9,
      ascentM: 940,
      timeMinutes: 152,
      polyline: "",
      waypoints: [
        .init(lat: 47.711, lon: 11.757, name: "Tegernsee"),
      ],
      turnHints: [],
      createdAt: "2026-05-28T08:00:00Z"
    ),
  ]
}

/// Root shown when the app runs in screenshot mode — a single screen chosen by
/// `WatchScreenshotMode.screen`, with no navigation chrome to interfere.
struct ScreenshotRootView: View {
  @EnvironmentObject var storage: RouteStorage

  var body: some View {
    switch WatchScreenshotMode.screen {
    case "glance":
      NavigationGlanceView()
    case "navigation":
      if let route = storage.routes.first ?? WatchScreenshotMode.demoRoutes.first {
        NavigationStack { StandaloneNavigationView(route: route) }
      } else {
        RoutesListView()
      }
    default:
      RoutesListView()
    }
  }
}
