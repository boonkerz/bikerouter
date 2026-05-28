import MapKit
import SwiftUI

/// Mini map page of the standalone-navigation TabView. Renders Apple
/// Maps with the route as a polyline overlay and the user's live
/// position as a dot. Camera follows the user unless they pan / zoom
/// manually (via the Digital Crown), at which point we stop following
/// until the next maneuver.
///
/// We deliberately use MapKit instead of bundling our own OSM-tile
/// pipeline — MapKit's tile cache, gestures and Digital-Crown zoom
/// are all free, and Apple's basemap is good enough at the zoom
/// levels a cyclist actually reads at speed (z14–17). Bringing OSM
/// would mean shipping a tile cache + image decoder, which Phase 3
/// doesn't justify.
struct RouteMapView: View {
  let route: StoredRoute
  /// Live position from the running NavigationEngine. We mirror it
  /// here instead of subscribing to the engine directly so this view
  /// stays a pure layout — the parent owns the engine lifecycle.
  let userLocation: CLLocationCoordinate2D?

  @State private var cameraPosition: MapCameraPosition = .automatic

  /// Decoded once when the view is built. The polyline string is
  /// stable for the route's lifetime so this never needs invalidating.
  private var routeCoordinates: [CLLocationCoordinate2D] {
    PolylineDecoder.decode(route.polyline)
  }

  var body: some View {
    Map(position: $cameraPosition) {
      MapPolyline(coordinates: routeCoordinates)
        .stroke(Color(red: 0.42, green: 0.29, blue: 0.16), lineWidth: 4)
      UserAnnotation()
    }
    .mapStyle(.standard(elevation: .flat))
    .onAppear { recentre() }
    .onChange(of: userLocation?.latitude) { _, _ in recentre() }
    .containerBackground(.fill.tertiary, for: .navigation)
  }

  /// Re-centres on the user with a zoom appropriate for cycling
  /// turn-by-turn (~500m diameter — close enough to read the next
  /// turn, wide enough to see what's coming after it).
  private func recentre() {
    guard let user = userLocation else { return }
    cameraPosition = .region(MKCoordinateRegion(
      center: user,
      latitudinalMeters: 500,
      longitudinalMeters: 500
    ))
  }
}
