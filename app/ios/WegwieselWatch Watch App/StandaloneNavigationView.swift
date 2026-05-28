import SwiftUI

/// Watch's standalone navigation screen — shown when the user taps
/// "Start" on a stored route. The engine is owned here as a
/// @StateObject so the navigation lifecycle (start on appear, stop
/// on disappear) lives with the screen, and the two sub-pages
/// (turn glance + mini map) just read from the same source of truth.
///
/// Layout uses a horizontal TabView (page style) — Watch users are
/// used to swiping between pages, and it keeps the Digital Crown
/// free for in-page interactions (e.g. zooming the map).
struct StandaloneNavigationView: View {
  let route: StoredRoute
  @StateObject private var engine: NavigationEngine
  @Environment(\.dismiss) private var dismiss

  init(route: StoredRoute) {
    self.route = route
    _engine = StateObject(wrappedValue: NavigationEngine(route: route))
  }

  var body: some View {
    TabView {
      TurnGlancePage(engine: engine)
        .tag(0)
      RouteMapView(route: route, userLocation: engine.userLocation)
        .tag(1)
    }
    .tabViewStyle(.verticalPage)
    .navigationTitle(route.name)
    .navigationBarTitleDisplayMode(.inline)
    .onAppear { engine.start() }
    .onDisappear { engine.stop() }
    .onChange(of: engine.arrived) { _, arrived in
      // Auto-dismiss back to the route detail screen ~3s after the
      // arrival haptic so the user has time to see "Ziel".
      if arrived {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
          dismiss()
        }
      }
    }
  }
}

/// The "big arrow + distance" page — same shape as the phone-driven
/// glance view, just bound to the watch-local engine.
private struct TurnGlancePage: View {
  @ObservedObject var engine: NavigationEngine

  var body: some View {
    VStack(spacing: 6) {
      if engine.offRoute {
        offRouteBanner
      } else if !engine.hasFix {
        Text("GPS wird gesucht…")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }

      Image(systemName: engine.direction.symbolName)
        .resizable()
        .scaledToFit()
        .frame(width: 56, height: 56)
        .foregroundStyle(Color(red: 0.42, green: 0.29, blue: 0.16))

      Text(formattedDistance)
        .font(.system(size: 32, weight: .bold, design: .rounded))
        .foregroundStyle(.primary)
        .minimumScaleFactor(0.6)
        .lineLimit(1)

      Spacer(minLength: 4)

      Text(formattedRemainingKm)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 6)
    .padding(.vertical, 4)
    .containerBackground(.fill.tertiary, for: .navigation)
  }

  private var offRouteBanner: some View {
    HStack(spacing: 4) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.caption)
      Text("Abseits der Route")
        .font(.caption2.bold())
    }
    .padding(.horizontal, 6)
    .padding(.vertical, 3)
    .background(Color.red.opacity(0.25))
    .clipShape(RoundedRectangle(cornerRadius: 4))
    .foregroundStyle(Color.red)
  }

  private var formattedDistance: String {
    if engine.arrived { return "Ziel" }
    if !engine.hasFix { return "—" }
    let m = engine.distanceToTurnMeters
    if m <= 0 { return "—" }
    if m < 1000 { return "\(m) m" }
    return String(format: "%.1f km", Double(m) / 1000.0)
  }

  private var formattedRemainingKm: String {
    if engine.arrived { return "" }
    if engine.remainingKm <= 0 { return "" }
    return String(format: "noch %.1f km", engine.remainingKm)
  }
}
