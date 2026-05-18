import 'dart:convert';
import 'dart:typed_data';

/// Parsed BRouter lookups.dat: maps tag-name → ordered list of value-names
/// per context (way/node). The RD5 binary stream encodes tags by index into
/// this table, so the same lookups file must accompany the segment files.
///
/// BRouter's behavior (mirrored faithfully here so the decoder can resolve
/// edge tags correctly):
///   - For the `way` context, an implicit `reversedirection` tag is
///     prepended at index 0 with values [empty, "unknown", "yes"].
///   - For the `node` context, the implicit prepend is `nodeaccessgranted`.
///   - Every tag — implicit or from the file — starts its value list with
///     `["", "unknown"]`. The first real value from lookups.dat lands at
///     index 2.
///
/// File format (ISO-8859 text):
///
///     ---lookupversion:10
///     ---minorversion:14
///     ---context:way
///     <tag-name>;<count> <value>
///     ;<count> <value>     # continuation line: same tag, next value
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

  /// Convenience accessor for the way context, used by the RD5 microcache
  /// decoder for per-edge tag resolution.
  LookupContext? get way => contexts['way'];

  static Lookups parse(Uint8List bytes) {
    // BRouter writes lookups.dat as Latin-1 to keep umlauts in OSM tag
    // values intact without UTF-8 overhead.
    final text = latin1.decode(bytes);
    int lookupVersion = 0;
    int minorVersion = 0;
    final contexts = <String, LookupContext>{};
    LookupContext? current;
    LookupTag? currentTag;

    void seedContextIfNeeded(LookupContext ctx) {
      // BRouter prepends a hardcoded "reversedirection"/"nodeaccessgranted"
      // tag before parsing the file, so its index is always 0.
      if (ctx.tagsByIndex.isNotEmpty) return;
      final implicit = ctx.name == 'way'
          ? 'reversedirection'
          : ctx.name == 'node'
              ? 'nodeaccessgranted'
              : null;
      if (implicit == null) return;
      final tag = LookupTag(implicit);
      tag.values.add(const LookupValue(name: '', count: 0)); // index 0
      tag.values.add(const LookupValue(name: 'unknown', count: 0)); // index 1
      tag.values.add(const LookupValue(name: 'yes', count: 0)); // index 2
      ctx.tags[implicit] = tag;
      ctx.tagsByIndex.add(tag);
    }

    for (final rawLine in const LineSplitter().convert(text)) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

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
        seedContextIfNeeded(current);
        currentTag = null;
        continue;
      }
      if (line.startsWith('---')) continue; // any other directive
      if (current == null) continue;

      // Lines look like `tag;<count> value` for tag headers, then `;<count>
      // value` for continuation lines of the same tag.
      final semi = line.indexOf(';');
      if (semi < 0) continue;
      final beforeSemi = line.substring(0, semi);
      final afterSemi = line.substring(semi + 1);
      final space = afterSemi.indexOf(' ');
      if (space < 0) continue;
      final count = int.tryParse(afterSemi.substring(0, space)) ?? 0;
      // Anything after the count is `<value> [alias1 alias2 …]`. BRouter
      // stores only the canonical value in the lookup table; aliases are
      // for the encoder's tag-matching pass. The decoder only needs the
      // canonical form.
      final rest = afterSemi.substring(space + 1);
      final aliasSpace = rest.indexOf(' ');
      final value = aliasSpace < 0 ? rest : rest.substring(0, aliasSpace);

      if (beforeSemi.isNotEmpty) {
        // New tag introduction → BRouter seeds it with [empty, unknown]
        // before adding the file value at index 2.
        currentTag = current.tags.putIfAbsent(beforeSemi, () {
          final t = LookupTag(beforeSemi);
          t.values.add(const LookupValue(name: '', count: 0));
          t.values.add(const LookupValue(name: 'unknown', count: 0));
          current!.tagsByIndex.add(t);
          return t;
        });
      }
      currentTag?.values.add(LookupValue(name: value, count: count));
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
  // Name-keyed view used by tooling / introspection.
  final Map<String, LookupTag> tags = {};
  // Position-indexed view used by the RD5 decoder. Index 0 is the implicit
  // BRouter tag (reversedirection/nodeaccessgranted), index 1+ follow the
  // declaration order in lookups.dat.
  final List<LookupTag> tagsByIndex = [];

  LookupContext(this.name);

  /// Resolves a single (inum, valueIdx) pair into an OSM-style key/value
  /// pair. Returns null when either index is out of range, or when the
  /// value is "empty"/"unknown" (those are placeholders BRouter uses for
  /// "no value present" rather than real OSM tags).
  MapEntry<String, String>? resolve(int tagIdx, int valueIdx) {
    if (tagIdx < 0 || tagIdx >= tagsByIndex.length) return null;
    final tag = tagsByIndex[tagIdx];
    if (valueIdx < 0 || valueIdx >= tag.values.length) return null;
    final value = tag.values[valueIdx].name;
    if (value.isEmpty || value == 'unknown') return null;
    return MapEntry(tag.name, value);
  }
}

class LookupTag {
  final String name;
  final List<LookupValue> values = [];
  LookupTag(this.name);

  /// Index used by BRouter to encode the given value. Returns -1 if the
  /// value isn't present in this tag's enumeration.
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
