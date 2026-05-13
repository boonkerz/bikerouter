import 'package:bikerouter/services/offline_routing/rd5_segment_downloader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps DACH bounds to BRouter rd5 segment names', () {
    final names = Rd5SegmentDownloader.segmentFilenamesForBounds(
      minLat: 47.0,
      minLon: 5.5,
      maxLat: 55.0,
      maxLon: 16.0,
    );

    expect(
      names,
      [
        'E10_N45.rd5',
        'E10_N50.rd5',
        'E15_N45.rd5',
        'E15_N50.rd5',
        'E5_N45.rd5',
        'E5_N50.rd5',
      ],
    );
  });

  test('does not include the next tile when max bound sits on a boundary', () {
    final names = Rd5SegmentDownloader.segmentFilenamesForBounds(
      minLat: 50.0,
      minLon: 5.0,
      maxLat: 55.0,
      maxLon: 10.0,
    );

    expect(names, ['E5_N50.rd5']);
  });

  test('formats western and southern hemisphere filenames', () {
    final names = Rd5SegmentDownloader.segmentFilenamesForBounds(
      minLat: -7.0,
      minLon: -8.0,
      maxLat: -2.0,
      maxLon: -1.0,
    );

    expect(names, ['W10_S10.rd5', 'W10_S5.rd5', 'W5_S10.rd5', 'W5_S5.rd5']);
  });
}
