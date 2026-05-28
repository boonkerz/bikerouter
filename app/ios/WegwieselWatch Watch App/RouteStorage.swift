import Foundation

/// Lightweight model + on-disk store for routes the phone has pushed
/// to the watch. Each route lives as a JSON file under
/// Documents/routes/<id>.json so we can read/write atomically without
/// loading everything into memory.
struct StoredRoute: Identifiable, Codable {
  let id: String
  let name: String
  let profile: String
  let distanceKm: Double
  let ascentM: Int
  let timeMinutes: Int
  /// Polyline in Google-encoded format. Decoded on demand for the
  /// upcoming map / navigation views.
  let polyline: String
  let waypoints: [Waypoint]
  let turnHints: [TurnHint]
  let createdAt: String

  struct Waypoint: Codable {
    let lat: Double
    let lon: Double
    let name: String?
  }

  struct TurnHint: Codable {
    let idx: Int
    let cmd: String
  }

  /// Best-effort parse from the phone's payload. Returns nil for
  /// missing required fields — the phone may someday send a v2 schema
  /// we don't fully understand yet, and we'd rather skip than crash.
  static func decode(_ json: [String: Any]) -> StoredRoute? {
    guard
      let id = json["id"] as? String,
      let name = json["name"] as? String,
      let polyline = json["polyline"] as? String
    else { return nil }
    let waypoints = (json["waypoints"] as? [[String: Any]] ?? []).compactMap { w -> Waypoint? in
      guard let lat = w["lat"] as? Double, let lon = w["lon"] as? Double else { return nil }
      return Waypoint(lat: lat, lon: lon, name: w["name"] as? String)
    }
    let hints = (json["turnHints"] as? [[String: Any]] ?? []).compactMap { h -> TurnHint? in
      guard let idx = h["idx"] as? Int, let cmd = h["cmd"] as? String else { return nil }
      return TurnHint(idx: idx, cmd: cmd)
    }
    return StoredRoute(
      id: id,
      name: name,
      profile: (json["profile"] as? String) ?? "",
      distanceKm: (json["distanceKm"] as? Double) ?? 0,
      ascentM: (json["ascentM"] as? Int) ?? 0,
      timeMinutes: (json["timeMinutes"] as? Int) ?? 0,
      polyline: polyline,
      waypoints: waypoints,
      turnHints: hints,
      createdAt: (json["createdAt"] as? String) ?? ""
    )
  }
}

final class RouteStorage: ObservableObject {
  static let shared = RouteStorage()

  @Published private(set) var routes: [StoredRoute] = []

  private let fm = FileManager.default
  private var dir: URL? {
    guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
      return nil
    }
    let d = docs.appendingPathComponent("routes", isDirectory: true)
    if !fm.fileExists(atPath: d.path) {
      try? fm.createDirectory(at: d, withIntermediateDirectories: true)
    }
    return d
  }

  /// Reads every JSON file in the routes dir and refreshes the
  /// published list. Sorted newest-first by createdAt — falling back
  /// to filesystem mtime when the field is missing.
  func reload() {
    guard let d = dir else { return }
    let urls = (try? fm.contentsOfDirectory(at: d, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
    var loaded: [StoredRoute] = []
    let dec = JSONDecoder()
    for url in urls where url.pathExtension == "json" {
      guard let data = try? Data(contentsOf: url) else { continue }
      if let r = try? dec.decode(StoredRoute.self, from: data) {
        loaded.append(r)
      }
    }
    loaded.sort { $0.createdAt > $1.createdAt }
    DispatchQueue.main.async {
      self.routes = loaded
    }
  }

  /// Stores (or overwrites) a route. The phone reuses the same id for
  /// the same route, so re-sending after an edit overwrites the old
  /// copy on the watch.
  func save(_ route: StoredRoute) {
    guard let d = dir else { return }
    let url = d.appendingPathComponent("\(route.id).json")
    let enc = JSONEncoder()
    if let data = try? enc.encode(route) {
      try? data.write(to: url, options: .atomic)
      reload()
    }
  }

  /// Saves directly from the raw JSON dict the phone sent — used when
  /// WatchConnectivity hands us a file containing the unparsed JSON
  /// (we decode through [StoredRoute.decode] which is more lenient
  /// than [JSONDecoder] for forward-compat).
  func saveFromPhonePayload(_ json: [String: Any]) {
    guard let r = StoredRoute.decode(json) else { return }
    save(r)
  }

  func delete(id: String) {
    guard let d = dir else { return }
    let url = d.appendingPathComponent("\(id).json")
    try? fm.removeItem(at: url)
    reload()
  }
}
