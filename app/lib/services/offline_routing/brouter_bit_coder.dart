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

class TagValueTree {
  final TagValueTree? child1;
  final TagValueTree? child2;
  final bool hasData;

  const TagValueTree.leaf(this.hasData)
      : child1 = null,
        child2 = null;

  const TagValueTree.node(this.child1, this.child2) : hasData = false;

  static TagValueTree read(BrouterBitCoder coder) {
    final isNode = coder.decodeBit();
    if (isNode) {
      return TagValueTree.node(read(coder), read(coder));
    }

    var hasData = false;
    for (;;) {
      final delta = coder.decodeVarBits();
      if (!hasData && delta == 0) {
        return const TagValueTree.leaf(false);
      }
      if (delta == 0) {
        return TagValueTree.leaf(hasData);
      }
      hasData = true;
      coder.decodeVarBits();
    }
  }

  bool decode(BrouterBitCoder coder) {
    var node = this;
    while (node.child1 != null && node.child2 != null) {
      node = coder.decodeBit() ? node.child2! : node.child1!;
    }
    return node.hasData;
  }
}
