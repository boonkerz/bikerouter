import 'dart:math';
import 'dart:typed_data';

import 'brouter_bit_coder.dart';
import 'offline_routing_graph.dart';

class Rd5DecodedMicroCache {
  final List<OfflineRoutingNode> nodes;
  final List<OfflineRoutingEdge> edges;

  const Rd5DecodedMicroCache({
    required this.nodes,
    required this.edges,
  });
}

class Rd5MicroCacheDecoder {
  final Uint8List bytes;
  final int lonIdx;
  final int latIdx;
  final int divisor;

  Rd5MicroCacheDecoder({
    required this.bytes,
    required this.lonIdx,
    required this.latIdx,
    required this.divisor,
  });

  Rd5DecodedMicroCache decode() {
    final coder = BrouterBitCoder(bytes);
    final wayTags = TagValueTree.read(coder);
    TagValueTree.read(coder); // node tags, currently not needed for routing.
    final nodeIdxDiff = NoisyDiffDecoder(coder);
    final nodeEleDiff = NoisyDiffDecoder(coder);
    final extLonDiff = NoisyDiffDecoder(coder);
    final extLatDiff = NoisyDiffDecoder(coder);
    final transEleDiff = NoisyDiffDecoder(coder);

    final size = coder.decodeNoisyNumber(5);
    if (size <= 0) {
      return const Rd5DecodedMicroCache(nodes: [], edges: []);
    }

    final faid = List<int>.filled(size, 0);
    final alon = List<int>.filled(size, 0);
    final alat = List<int>.filled(size, 0);
    coder.decodeSortedArray(faid, 0, size, 29, 0);
    for (var n = 0; n < size; n++) {
      final point = _expandId(faid[n]);
      alon[n] = point.$1;
      alat[n] = point.$2;
    }

    coder.decodeNoisyNumber(10); // net data size in BRouter's internal format.
    final edges = <OfflineRoutingEdge>[];
    final nodeById = <int, OfflineRoutingNode>{};

    var elevation = 0;
    for (var n = 0; n < size; n++) {
      final ilon = alon[n];
      final ilat = alat[n];

      var featureId = coder.decodeVarBits();
      if (featureId == 13) {
        final node = _node(ilon, ilat, elevation.toDouble());
        nodeById[node.id] = node;
        continue;
      }
      while (featureId != 0) {
        final bitSize = coder.decodeNoisyNumber(5);
        if (featureId == 2) {
          coder.decodeBounded(1023);
        } else if (featureId == 1) {
          coder.decodeBit();
          coder.decodeNoisyDiff(10);
          coder.decodeNoisyDiff(10);
          coder.decodeNoisyDiff(10);
          coder.decodeNoisyDiff(10);
        } else {
          for (var i = 0; i < bitSize; i++) {
            coder.decodeBit();
          }
        }
        featureId = coder.decodeVarBits();
      }

      elevation += nodeEleDiff.decodeSignedValue();
      final node = _node(ilon, ilat, elevation.toDouble());
      nodeById[node.id] = node;

      _decodeTagValueSet(coder); // node tags payload
      final linkCount = coder.decodeNoisyNumber(1);
      for (var li = 0; li < linkCount; li++) {
        final nodeIdx = n + nodeIdxDiff.decodeSignedValue();
        int dlon;
        int dlat;
        var reverse = false;
        var internal = false;
        if (nodeIdx != n && nodeIdx >= 0 && nodeIdx < size) {
          internal = true;
          dlon = alon[nodeIdx] - ilon;
          dlat = alat[nodeIdx] - ilat;
        } else {
          reverse = coder.decodeBit();
          dlon = extLonDiff.decodeSignedValue();
          dlat = extLatDiff.decodeSignedValue();
        }

        final hasWayTags = wayTags.decode(coder);
        final targetLon = ilon + dlon;
        final targetLat = ilat + dlat;
        final targetNode = _node(targetLon, targetLat, 0);
        nodeById.putIfAbsent(targetNode.id, () => targetNode);

        if (hasWayTags || !reverse) {
          edges.add(OfflineRoutingEdge(
            fromNodeId: node.id,
            toNodeId: targetNode.id,
            distanceMeters: max(
              1,
              OfflineRoutingGraph.haversineMeters(
                node.lon,
                node.lat,
                targetNode.lon,
                targetNode.lat,
              ),
            ).toDouble(),
            tags: const {'highway': 'cycleway'},
            bidirectional: internal && !reverse,
          ));
        }

        if (!reverse) {
          var remainingLon = dlon;
          var remainingLat = dlat;
          final transCount = coder.decodeVarBits();
          var count = transCount + 1;
          for (var i = 0; i < transCount; i++) {
            final transLon = coder.decodePredictedValue(remainingLon ~/ count);
            final transLat = coder.decodePredictedValue(remainingLat ~/ count);
            remainingLon -= transLon;
            remainingLat -= transLat;
            count--;
            transEleDiff.decodeSignedValue();
          }
        }
      }
    }

    return Rd5DecodedMicroCache(nodes: nodeById.values.toList(), edges: edges);
  }

  void _decodeTagValueSet(BrouterBitCoder coder) {
    for (;;) {
      final delta = coder.decodeVarBits();
      if (delta == 0) return;
      coder.decodeVarBits();
    }
  }

  (int, int) _expandId(int id32) {
    var dlon = 0;
    var dlat = 0;
    var value = id32;
    for (var bit = 1; bit < 0x8000; bit <<= 1) {
      if ((value & 1) != 0) dlon |= bit;
      if ((value & 2) != 0) dlat |= bit;
      value >>= 2;
    }
    final cellSize = 1000000 ~/ divisor;
    return (lonIdx * cellSize + dlon, latIdx * cellSize + dlat);
  }

  OfflineRoutingNode _node(int ilon, int ilat, double elevation) {
    final lon = (ilon - 180000000) / 1000000.0;
    final lat = (ilat - 90000000) / 1000000.0;
    return OfflineRoutingNode(
      id: _nodeId(ilon, ilat),
      lon: lon,
      lat: lat,
      elevation: elevation,
    );
  }

  static int _nodeId(int ilon, int ilat) => (ilon << 32) ^ ilat;
}
