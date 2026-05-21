import SwiftUI

/// The single screen of the Wegwiesel watch app. Mirrors the
/// iPhone's turn-by-turn glance: maneuver icon at top, distance to
/// the next turn front-and-centre, remaining-trip ETA at the bottom.
struct NavigationGlanceView: View {
  @EnvironmentObject var session: WatchSessionController

  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: session.direction.symbolName)
        .resizable()
        .scaledToFit()
        .frame(width: 56, height: 56)
        .foregroundStyle(Color(red: 0.42, green: 0.29, blue: 0.16))

      Text(formattedDistance)
        .font(.system(size: 32, weight: .bold, design: .rounded))
        .foregroundStyle(.primary)
        .minimumScaleFactor(0.6)
        .lineLimit(1)

      if let street = session.streetName, !street.isEmpty {
        Text(street)
          .font(.caption2)
          .foregroundStyle(.secondary)
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
      .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 6)
    .padding(.vertical, 4)
    .containerBackground(.fill.tertiary, for: .navigation)
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
