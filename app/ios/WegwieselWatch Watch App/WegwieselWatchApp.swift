import SwiftUI
import WatchConnectivity

/// Entry point of the Wegwiesel watchOS companion. The app has two
/// modes that share the same screen real estate:
///
///   * **Live-navigation glance** (Phase 1 v2.2): if the phone is
///     actively pushing turn-by-turn state we show the glance view
///     with the current maneuver. This is the primary use case
///     today.
///   * **Routes list** (Phase 1 v2.3): when the phone is *not*
///     navigating, the watch displays the routes that have been
///     pushed to it. From here Phase 2 will let the user start a
///     standalone navigation on the watch itself.
///
/// We switch on whether the phone's navigation feed is idle — the
/// glance view only renders when there's a live maneuver, otherwise
/// the routes list takes the screen.
@main
struct WegwieselWatchApp: App {
  @StateObject private var session = WatchSessionController()
  @StateObject private var storage = RouteStorage.shared

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(session)
        .environmentObject(storage)
        .onAppear {
          session.activate()
          storage.reload()
        }
    }
  }
}

/// Picks between the live-nav glance and the routes list based on
/// whether the phone is currently broadcasting maneuver state.
private struct RootView: View {
  @EnvironmentObject var session: WatchSessionController

  var body: some View {
    if session.direction == .idle {
      RoutesListView()
    } else {
      NavigationGlanceView()
    }
  }
}
