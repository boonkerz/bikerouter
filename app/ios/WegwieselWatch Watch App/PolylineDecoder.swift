import CoreLocation
import Foundation

/// Inverse of the Dart-side WatchRouteSender encoder. Reads the
/// Google encoded-polyline format byte-by-byte and rebuilds
/// CLLocationCoordinate2D points.
///
/// See: developers.google.com/maps/documentation/utilities/polylinealgorithm
enum PolylineDecoder {
  static func decode(_ str: String) -> [CLLocationCoordinate2D] {
    var out: [CLLocationCoordinate2D] = []
    let bytes = Array(str.utf8)
    var i = 0
    var lat = 0
    var lon = 0
    while i < bytes.count {
      guard let (dLat, nextI) = consume(bytes, from: i) else { break }
      i = nextI
      guard let (dLon, nextJ) = consume(bytes, from: i) else { break }
      i = nextJ
      lat += dLat
      lon += dLon
      out.append(CLLocationCoordinate2D(
        latitude: Double(lat) / 1e5,
        longitude: Double(lon) / 1e5
      ))
    }
    return out
  }

  /// Reads one varint starting at `from`. Returns (value, nextIndex)
  /// or nil if the stream ended mid-value.
  private static func consume(_ bytes: [UInt8], from start: Int) -> (Int, Int)? {
    var shift = 0
    var result = 0
    var i = start
    while i < bytes.count {
      let b = Int(bytes[i]) - 63
      result |= (b & 0x1f) << shift
      i += 1
      if b < 0x20 { break }
      shift += 5
      if shift > 30 { return nil } // malformed, way too long
    }
    let signed = (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
    return (signed, i)
  }
}
