import 'dart:typed_data';

class BrouterBitCoder {
  final Uint8List bytes;
  int _idx = -1;
  int _bits = 0;
  int _buffer = 0;

  BrouterBitCoder(this.bytes);

  int get readingBitPosition => (_idx << 3) + 8 - _bits;

  bool decodeBit() {
    if (_bits == 0) {
      _bits = 8;
      _buffer = bytes[++_idx] & 0xff;
    }
    final value = (_buffer & 1) != 0;
    _buffer >>= 1;
    _bits--;
    return value;
  }

  int decodeBits(int count) {
    _fillBuffer();
    final mask = count == 32 ? 0xffffffff : (1 << count) - 1;
    final value = _buffer & mask;
    _buffer >>= count;
    _bits -= count;
    return value;
  }

  int decodeBitsReverse(int count) {
    _fillBuffer();
    var value = 0;
    while (count > 0) {
      value = (value << 1) | (decodeBit() ? 1 : 0);
      count--;
    }
    return value;
  }

  int decodeBounded(int max) {
    var value = 0;
    var im = 1;
    while ((value | im) <= max) {
      if (decodeBit()) value |= im;
      im <<= 1;
    }
    return value;
  }

  int decodeVarBits() {
    var range = 0;
    while (!decodeBit()) {
      range = 2 * range + 1;
    }
    return range + decodeBounded(range);
  }

  int decodeNoisyNumber(int noisyBits) {
    final value = noisyBits == 0 ? 0 : decodeBits(noisyBits);
    return value | (decodeVarBits() << noisyBits);
  }

  int decodeNoisyDiff(int noisyBits) {
    var value = 0;
    if (noisyBits > 0) {
      value = decodeBits(noisyBits) - (1 << (noisyBits - 1));
    }
    var val2 = decodeVarBits() << noisyBits;
    if (val2 != 0 && decodeBit()) {
      val2 = -val2;
    }
    return value + val2;
  }

  int decodePredictedValue(int predictor) {
    var p = predictor < 0 ? -predictor : predictor;
    var noisyBits = 0;
    while (p > 1023) {
      noisyBits++;
      p >>= 1;
    }
    while (p > 2) {
      noisyBits++;
      p >>= 1;
    }
    return predictor + decodeNoisyDiff(noisyBits);
  }

  void decodeSortedArray(
    List<int> values,
    int offset,
    int subsize,
    int nextBitPos,
    int value,
  ) {
    if (subsize == 1) {
      if (nextBitPos >= 0) {
        value |= decodeBitsReverse(nextBitPos + 1);
      }
      values[offset] = value;
      return;
    }
    if (nextBitPos < 0) {
      while (subsize-- > 0) {
        values[offset++] = value;
      }
      return;
    }

    final size1 = decodeBounded(subsize);
    final size2 = subsize - size1;
    if (size1 > 0) {
      decodeSortedArray(values, offset, size1, nextBitPos - 1, value);
    }
    if (size2 > 0) {
      decodeSortedArray(
        values,
        offset + size1,
        size2,
        nextBitPos - 1,
        value | (1 << nextBitPos),
      );
    }
  }

  void _fillBuffer() {
    while (_bits < 24) {
      _idx++;
      if (_idx < bytes.length) {
        _buffer |= (bytes[_idx] & 0xff) << _bits;
      }
      _bits += 8;
    }
  }
}

class NoisyDiffDecoder {
  final BrouterBitCoder _coder;
  final int noisyBits;

  NoisyDiffDecoder(this._coder) : noisyBits = _coder.decodeVarBits();

  int decodeSignedValue() => _coder.decodeNoisyDiff(noisyBits);
}

/// One entry from a way-/node-description: the BRouter tag-index (0-based
/// against lookups.dat's positional table, where index 0 is the implicit
/// "reversedirection" / "nodeaccessgranted") and the value-index (0=empty,
/// 1=unknown, 2+ = the values from lookups.dat in declaration order).
class TagValueEntry {
  final int tagIdx;
  final int valueIdx;
  const TagValueEntry(this.tagIdx, this.valueIdx);
}

/// Huffman tree that maps a per-edge bit prefix to a tag-value set. Leaves
/// either hold a [payload] of [TagValueEntry]s (the edge's tag list) or are
/// "empty" (the edge has no tags, [payload] is null).
///
/// Mirrors BRouter's `TagValueCoder` (brouter-codec/.../TagValueCoder.java).
class TagValueTree {
  final TagValueTree? child1;
  final TagValueTree? child2;
  final List<TagValueEntry>? payload;

  const TagValueTree._({this.child1, this.child2, this.payload});

  bool get isNode => child1 != null && child2 != null;
  bool get hasData => payload != null;

  static TagValueTree read(BrouterBitCoder coder) {
    final isNode = coder.decodeBit();
    if (isNode) {
      return TagValueTree._(child1: read(coder), child2: read(coder));
    }

    // Leaf — decode tag-value pairs until delta=0 closes the list.
    // BRouter encoding: inum starts at 0, then `inum += delta` per pair,
    // `data = decodeVarBits()`. Pair (inum, data) is one tag entry.
    final pairs = <TagValueEntry>[];
    var inum = 0;
    var hasData = false;
    for (;;) {
      final delta = coder.decodeVarBits();
      if (delta == 0) {
        // First delta=0 with no data so far is BRouter's "empty leaf"
        // marker (= edge has no tags).
        return TagValueTree._(payload: hasData ? pairs : null);
      }
      inum += delta;
      final data = coder.decodeVarBits();
      pairs.add(TagValueEntry(inum, data));
      hasData = true;
    }
  }

  /// Reads one edge's prefix bits and returns the leaf's tag list, or null
  /// when the edge has no tags.
  List<TagValueEntry>? decodePayload(BrouterBitCoder coder) {
    var node = this;
    while (node.isNode) {
      node = coder.decodeBit() ? node.child2! : node.child1!;
    }
    return node.payload;
  }

  /// Legacy boolean variant kept for callers that only need "does this
  /// edge carry any tags". New code should prefer [decodePayload].
  bool decode(BrouterBitCoder coder) => decodePayload(coder) != null;
}
