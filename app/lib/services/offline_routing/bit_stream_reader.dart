import 'dart:typed_data';

/// MSB-first bit-level reader over a byte buffer.
///
/// BRouter's `StatCoderContext` reads bits high-to-low within each byte
/// (most-significant first), then advances to the next byte. This class
/// matches that convention so the higher-level decoders can call
/// [readBits] with the bit width they need without juggling shifts.
///
/// Bits are not buffered across reads — each [readBits] pulls fresh bits
/// from the current byte cursor and may straddle byte boundaries.
class BitStreamReader {
  final Uint8List bytes;
  int _byteOffset;
  int _bitOffset; // 0 = MSB of the current byte, 7 = LSB

  BitStreamReader(this.bytes, [int startByte = 0])
      : _byteOffset = startByte,
        _bitOffset = 0;

  /// Current absolute bit position from the start of the buffer.
  int get position => _byteOffset * 8 + _bitOffset;

  /// True when at least one more bit is available.
  bool get hasMore => _byteOffset < bytes.length;

  /// Read [count] bits and return them as an unsigned int. Count must be
  /// in [0, 32]. Out-of-range or buffer-overrun reads throw.
  int readBits(int count) {
    if (count < 0 || count > 32) {
      throw RangeError('readBits count out of range: $count');
    }
    int value = 0;
    int remaining = count;
    while (remaining > 0) {
      if (_byteOffset >= bytes.length) {
        throw StateError('BitStreamReader: read past end of buffer');
      }
      final bitsLeftInByte = 8 - _bitOffset;
      final take = remaining < bitsLeftInByte ? remaining : bitsLeftInByte;
      final shift = bitsLeftInByte - take;
      final chunk = (bytes[_byteOffset] >> shift) & ((1 << take) - 1);
      value = (value << take) | chunk;
      _bitOffset += take;
      if (_bitOffset == 8) {
        _bitOffset = 0;
        _byteOffset++;
      }
      remaining -= take;
    }
    return value;
  }

  /// Read a single bit as bool. Convenience for huffman-style trees.
  bool readBit() => readBits(1) == 1;

  /// Unary-coded length prefix: count of consecutive 1-bits before the
  /// first 0-bit. BRouter uses this pattern in several places of its
  /// variable-length encodings.
  int readUnary() {
    int count = 0;
    while (readBit()) {
      count++;
      if (count > 64) {
        throw StateError('BitStreamReader: unary length runaway');
      }
    }
    return count;
  }
}
