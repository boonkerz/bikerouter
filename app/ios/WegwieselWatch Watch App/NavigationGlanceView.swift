import SwiftUI

/// The single screen of the Wegwiesel watch app. Mirrors the
/// iPhone's turn-by-turn glance: maneuver icon at top, distance to
/// the next turn front-and-centre, remaining-trip ETA at the bottom.
///
/// Intentionally uses the older `foregroundColor` / `.system(size:)`
/// APIs (watchOS 6+) instead of `foregroundStyle` (watchOS 10+) so
/// the app remains installable on older watches and the target's
/// deployment-target setting doesn't have to be raised.
struct NavigationGlanceView: View {
  @EnvironmentObject var session: WatchSessionController

  private static let brand = Color(red: 0.42, green: 0.29, blue: 0.16)
  private static let muted = Color(red: 0.66, green: 0.66, blue: 0.66)

  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: session.direction.symbolName)
        .resizable()
        .scaledToFit()
        .frame(width: 56, height: 56)
        .foregroundColor(NavigationGlanceView.brand)

      Text(formattedDistance)
        .font(.system(size: 32, weight: .bold, design: .rounded))
        .foregroundColor(.primary)
        .minimumScaleFactor(0.6)
        .lineLimit(1)

      if let street = session.streetName, !street.isEmpty {
        Text(street)
          .font(.system(size: 11))
          .foregroundColor(NavigationGlanceView.muted)
          .lineLimit(1)
          .truncationMode(.tail)
      }

      Spacer(minLength: 4)

      HStack(spacing: 6) {
        Text(formattedRemainingKm)
        Text("·")
        Text(formattedEta)
      }
      .font(.system(size: 12, weight: .medium))
      .foregroundColor(NavigationGlanceView.muted)
    }
    .padding(.horizontal, 6)
    .padding(.vertical, 4)
  }

  // MARK: - Formatting

  /// "120 m" / "1.2 km" / "—" depending on state. Switches to the
  /// finish flag once the phone signals `arrived`.
  private var formattedDistance: String {
    if session.direction == .arrived {
      return "Ziel"
    }
    if session.direction == .idle {
      return "—"
    }
    let m = session.distanceToTurnMeters
    if m < 1000 { return "\(m) m" }
    return String(format: "%.1f km", Double(m) / 1000.0)
  }

  private var formattedRemainingKm: String {
    if session.remainingKm <= 0 { return "" }
    return String(format: "%.1f km", session.remainingKm)
  }

  /// Renders the ETA either as minutes (under an hour) or h:mm — fits
  /// without truncation on a 41 mm watch face.
  private var formattedEta: String {
    let m = session.remainingMinutes
    if m <= 0 { return "" }
    if m < 60 { return "\(m) min" }
    return String(format: "%d:%02d h", m / 60, m % 60)
  }
}
