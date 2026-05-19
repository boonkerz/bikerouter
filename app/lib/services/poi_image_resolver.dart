import 'dart:convert';

import 'package:http/http.dart' as http;

/// Extracts a thumbnail-friendly photo URL from an OSM-tagged POI's tags.
///
/// Three sources, in priority order:
///   1. `image=` tag — usually a direct HTTPS URL to a Commons file or the
///      museum's own server. Passed through untouched.
///   2. `wikimedia_commons=File:Foo.jpg` — resolved via Commons'
///      Special:FilePath redirect, no API call.
///   3. `wikipedia=lang:Title` — resolved via the MediaWiki PageImages
///      API. Async, batched (up to 50 titles per call) by language.
class PoiImageResolver {
  /// Returns a thumbnail URL (≤ 1024 px wide) for the Commons-direct
  /// sources (`image=`, `wikimedia_commons=`), or null when neither is
  /// present. For Wikipedia-only POIs use [resolveWikipediaBatch].
  static String? resolve(Map<String, String> tags) {
    final image = tags['image'];
    if (image != null && image.isNotEmpty) {
      final lower = image.toLowerCase();
      if (lower.startsWith('https://') || lower.startsWith('http://')) {
        // Some `image` tags point at File:Foo.jpg on Commons via the wiki
        // url. Special:FilePath always works; if the tag already used it,
        // pass through untouched.
        return image;
      }
      // Bare filename in `image=` is rare but happens; route via Commons.
      return _commonsFilePathUrl(image);
    }

    final commons = tags['wikimedia_commons'];
    if (commons != null && commons.isNotEmpty) {
      final filename =
          commons.startsWith('File:') ? commons.substring(5) : commons;
      return _commonsFilePathUrl(filename);
    }

    return null;
  }

  /// Parses a `wikipedia=` tag value (`lang:Title` or just `Title`) into
  /// its components. Returns null when the value is malformed.
  static ({String lang, String title})? parseWikipedia(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return null;
    final colon = trimmed.indexOf(':');
    if (colon < 0 || colon > 6) {
      // No language prefix or implausibly long prefix — default to English.
      return (lang: 'en', title: trimmed);
    }
    return (
      lang: trimmed.substring(0, colon).toLowerCase(),
      title: trimmed.substring(colon + 1),
    );
  }

  /// Batch-resolves multiple wikipedia-page references to thumbnail URLs.
  /// Groups by language, issues one MediaWiki API call per group, returns
  /// a map keyed by the original input string (the raw OSM `wikipedia=`
  /// tag value) so callers can match results back to their POIs.
  ///
  /// Network failures and unmapped titles are reflected as a missing key
  /// in the result map — callers should treat that as "no photo".
  static Future<Map<String, String>> resolveWikipediaBatch(
    Iterable<String> wikipediaTags, {
    int thumbWidth = 1024,
  }) async {
    final out = <String, String>{};
    if (wikipediaTags.isEmpty) return out;

    // Group: lang -> { title -> originalTag } (so we can map results back
    // even when two POIs share the same title in different languages).
    final perLanguage = <String, Map<String, String>>{};
    for (final raw in wikipediaTags) {
      final parsed = parseWikipedia(raw);
      if (parsed == null) continue;
      perLanguage
          .putIfAbsent(parsed.lang, () => <String, String>{})
          .putIfAbsent(parsed.title, () => raw);
    }

    for (final entry in perLanguage.entries) {
      final lang = entry.key;
      final titles = entry.value;
      // MediaWiki query API accepts at most 50 titles per call.
      final keys = titles.keys.toList();
      for (var i = 0; i < keys.length; i += 50) {
        final batch = keys.sublist(i, i + 50 > keys.length ? keys.length : i + 50);
        final joined = batch.map(Uri.encodeComponent).join('|');
        final uri = Uri.parse(
          'https://$lang.wikipedia.org/w/api.php'
          '?action=query&format=json'
          '&prop=pageimages&piprop=thumbnail&pithumbsize=$thumbWidth'
          '&redirects=1'
          '&titles=$joined',
        );
        try {
          final r = await http.get(uri, headers: const {
            'User-Agent': 'Wegwiesel/2.1 (https://wegwiesel.app; support@thomas-peterson.de)',
          }).timeout(const Duration(seconds: 10));
          if (r.statusCode != 200) continue;
          final json = jsonDecode(r.body) as Map<String, dynamic>;
          final query = json['query'] as Map<String, dynamic>?;
          if (query == null) continue;

          // Wikipedia normalises titles (e.g. "berlin" → "Berlin"). The
          // `normalized` array maps `from` (our request) → `to` (canonical).
          // `redirects` similarly handles "Frankfurt" → "Frankfurt am Main".
          // We follow both chains so we can match the API's keyed-by-
          // canonical-title `pages` map back to the input titles.
          final canonicalFor = <String, String>{
            for (final t in batch) t: t,
          };
          for (final pair
              in [...?(query['normalized'] as List?), ...?(query['redirects'] as List?)]) {
            if (pair is Map) {
              final from = pair['from'] as String?;
              final to = pair['to'] as String?;
              if (from != null && to != null) {
                canonicalFor.updateAll(
                    (k, v) => v == from ? to : v);
              }
            }
          }

          final pages = query['pages'] as Map<String, dynamic>?;
          if (pages == null) continue;
          for (final page in pages.values) {
            if (page is! Map) continue;
            final title = page['title'] as String?;
            final thumb = page['thumbnail'] as Map?;
            final source = thumb?['source'] as String?;
            if (title == null || source == null) continue;
            // Match canonical title back to the original tag input.
            canonicalFor.forEach((requested, canonical) {
              if (canonical == title) {
                final originalTag = titles[requested];
                if (originalTag != null) out[originalTag] = source;
              }
            });
          }
        } catch (_) {
          // Network/parse failure — leave these titles unresolved.
        }
      }
    }
    return out;
  }

  /// Special:FilePath redirects to the canonical file URL. Adding ?width
  /// forces Commons to serve a server-side-resized thumbnail rather than
  /// the (often multi-megabyte) original.
  static String _commonsFilePathUrl(String filename, {int width = 1024}) {
    final encoded = Uri.encodeComponent(filename.replaceAll(' ', '_'));
    return 'https://commons.wikimedia.org/wiki/Special:FilePath/$encoded?width=$width';
  }
}
