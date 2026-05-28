import SwiftUI

/// Shows every route the phone has pushed to the watch. Tapping a
/// route opens a detail view (Phase 1 just shows stats; Phase 2 will
/// add a "Start" button that begins standalone navigation).
///
/// Empty-state explains *how* to push routes — important so the user
/// doesn't think the watch app is broken when there's nothing here.
struct RoutesListView: View {
  @EnvironmentObject var storage: RouteStorage

  var body: some View {
    NavigationStack {
      Group {
        if storage.routes.isEmpty {
          emptyState
        } else {
          list
        }
      }
      .navigationTitle("Wegwiesel")
      .navigationBarTitleDisplayMode(.inline)
    }
    .onAppear { storage.reload() }
  }

  private var emptyState: some View {
    VStack(spacing: 10) {
      Image(systemName: "iphone.and.arrow.forward")
        .font(.system(size: 36))
        .foregroundStyle(Color(red: 0.42, green: 0.29, blue: 0.16))
      Text("Keine Routen")
        .font(.headline)
      Text("Plane eine Route am Phone und tippe auf \"An Watch senden\".")
        .font(.caption2)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 8)
    }
  }

  private var list: some View {
    List(storage.routes) { route in
      NavigationLink(value: route.id) {
        VStack(alignment: .leading, spacing: 2) {
          Text(route.name)
            .font(.system(size: 15, weight: .semibold))
            .lineLimit(1)
          HStack(spacing: 4) {
            Text(String(format: "%.1f km", route.distanceKm))
            Text("·")
            Text("↑ \(route.ascentM) m")
            if route.timeMinutes > 0 {
              Text("·")
              Text(formatTime(route.timeMinutes))
            }
          }
          .font(.caption2)
          .foregroundStyle(.secondary)
        }
      }
      .swipeActions {
        Button(role: .destructive) {
          storage.delete(id: route.id)
        } label: {
          Label("Löschen", systemImage: "trash")
        }
      }
    }
    .navigationDestination(for: String.self) { id in
      if let r = storage.routes.first(where: { $0.id == id }) {
        RouteDetailView(route: r)
      }
    }
  }

  private func formatTime(_ m: Int) -> String {
    if m < 60 { return "\(m) min" }
    return String(format: "%d:%02dh", m / 60, m % 60)
  }
}

struct RouteDetailView: View {
  let route: StoredRoute

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 10) {
        // Header
        Text(route.name)
          .font(.system(size: 17, weight: .bold))
          .lineLimit(2)

        // Stats grid
        statRow(systemImage: "map", label: String(format: "%.1f km", route.distanceKm))
        statRow(systemImage: "arrow.up.right", label: "↑ \(route.ascentM) m")
        if route.timeMinutes > 0 {
          statRow(systemImage: "clock", label: formatTime(route.timeMinutes))
        }
        if !route.profile.isEmpty {
          statRow(systemImage: "bicycle.circle", label: route.profile)
        }

        Divider()

        Text("\(route.waypoints.count) Wegpunkt\(route.waypoints.count == 1 ? "" : "e")")
          .font(.caption)
          .foregroundStyle(.secondary)

        // Phase 1 placeholder — standalone start lands in Phase 2.
        Text("Standalone-Navigation kommt im nächsten Update.")
          .font(.caption2)
          .foregroundStyle(.secondary)
          .padding(.top, 6)
      }
      .padding(8)
    }
    .navigationTitle("Route")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func statRow(systemImage: String, label: String) -> some View {
    HStack(spacing: 6) {
      Image(systemName: systemImage)
        .foregroundStyle(Color(red: 0.42, green: 0.29, blue: 0.16))
      Text(label)
        .font(.system(size: 14, weight: .medium))
    }
  }

  private func formatTime(_ m: Int) -> String {
    if m < 60 { return "\(m) min" }
    return String(format: "%d:%02dh", m / 60, m % 60)
  }
}
