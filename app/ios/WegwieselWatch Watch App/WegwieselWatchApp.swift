import SwiftUI
import WatchConnectivity

/// Entry point of the Wegwiesel watchOS companion. Owns a single shared
/// session controller so SwiftUI reads observable navigation state and
/// re-renders whenever the phone pushes a new turn-hint.
@main
struct WegwieselWatchApp: App {
  @StateObject private var session = WatchSessionController()

  var body: some Scene {
    WindowGroup {
      NavigationGlanceView()
        .environmentObject(session)
        .onAppear { session.activate() }
    }
  }
}
