import 'dart:convert';
import 'dart:typed_data';

/// Parsed BRouter lookups.dat: maps tag-name → ordered list of value-name
/// per context (way/node). The RD5 binary stream encodes tags by index into
/// this table, so the same lookups file must accompany the segment files.
///
/// File format (ISO-8859 text, BRouter conventions):
///
///     ---lookupversion:10
///     ---minorversion:14
///     ---context:way
///     <tag-name>;<count> <value>
///     <tag-name>;<count> <value>
///     ---context:node
///     <tag-name>;<count> <value>
///
/// Counts are corpus frequencies BRouter uses for Huffman tables. We keep
/// them so future commits can rebuild the Huffman trees identically.
class Lookups {
  final int lookupVersion;
  final int minorVersion;
  final Map<String, LookupContext> contexts;

  const Lookups({
    required this.lookupVersion,
    required this.minorVersion,
    required this.contexts,
  });

  LookupContext? operator [](String contextName) => contexts[contextName];

  static Lookups parse(Uint8List bytes) {
    // BRouter writes lookups.dat as Latin-1 to keep umlauts in OSM tag
    // values intact without UTF-8 overhead.
    final text = latin1.decode(bytes);
    int lookupVersion = 0;
    int minorVersion = 0;
    final contexts = <String, LookupContext>{};
    LookupContext? current;
    LookupTag? currentTag;

    for (final rawLine in const LineSplitter().convert(text)) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('---lookupversion:')) {
        lookupVersion = int.parse(line.split(':')[1].trim());
        continue;
      }
      if (line.startsWith('---minorversion:')) {
        minorVersion = int.parse(line.split(':')[1].trim());
        continue;
      }
      if (line.startsWith('---context:')) {
        final name = line.split(':')[1].trim();
        current = contexts.putIfAbsent(name, () => LookupContext(name));
        currentTag = null;
        continue;
      }
      if (current == null) continue;

      // Lines come as `tag;<count> value` for tag headers, then `;<count> value`
      // for additional values of the same tag.
      final semi = line.indexOf(';');
      if (semi < 0) continue;
      final beforeSemi = line.substring(0, semi);
      final afterSemi = line.substring(semi + 1);
      final space = afterSemi.indexOf(' ');
      if (space < 0) continue;
      final count = int.tryParse(afterSemi.substring(0, space)) ?? 0;
      final value = afterSemi.substring(space + 1);

      if (beforeSemi.isNotEmpty) {
        currentTag = current.tags.putIfAbsent(
            beforeSemi, () => LookupTag(beforeSemi));
      }
      if (currentTag != null) {
        currentTag.values.add(LookupValue(name: value, count: count));
      }
    }

    return Lookups(
      lookupVersion: lookupVersion,
      minorVersion: minorVersion,
      contexts: contexts,
    );
  }
}

class LookupContext {
  final String name;
  final Map<String, LookupTag> tags = {};
  LookupContext(this.name);
}

class LookupTag {
  final String name;
  final List<LookupValue> values = [];
  LookupTag(this.name);

  /// Index used by BRouter to encode the given value. Returns -1 if the
  /// value isn't present in this tag's enumeration (caller decides how to
  /// handle e.g. unknown surfaces).
  int indexOf(String value) {
    for (int i = 0; i < values.length; i++) {
      if (values[i].name == value) return i;
    }
    return -1;
  }
}

class LookupValue {
  final String name;
  final int count;
  const LookupValue({required this.name, required this.count});
}
