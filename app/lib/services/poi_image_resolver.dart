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
  /// Returns a thumbnail URL synchronously when possible — that means a
  /// plain HTTPS `image=` URL. `wikimedia_commons=File:…` and bare
  /// filenames now go through [resolveCommonsBatch] instead, because the
  /// Special:FilePath redirect we previously used here doesn't carry
  /// CORS headers and Flutter's CanvasKit blocks the load on web.
  static String? resolve(Map<String, String> tags) {
    final image = tags['image'];
    if (image != null && image.isNotEmpty) {
      final lower = image.toLowerCase();
      if (lower.startsWith('https://') || lower.startsWith('http://')) {
        // A direct image= URL works as-is. (commons.wikimedia.org/wiki/File:…
        // URLs would also hit a CORS-blocked redirect; we leave that to
        // resolveCommonsBatch via the dedicated `wikimedia_commons` path.)
        return image;
      }
    }
    return null;
  }

  /// Convenience: returns the raw `wikimedia_commons=` tag value (or an
  /// `image=File:…` bare filename) that needs async resolution via
  /// [resolveCommonsBatch], or null if no such reference exists.
  static String? extractCommonsReference(Map<String, String> tags) {
    final commons = tags['wikimedia_commons'];
    if (commons != null && commons.isNotEmpty) return commons;
    final image = tags['image'];
    if (image != null && image.startsWith('File:')) return image;
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

  /// Batch-resolves OSM `wikimedia_commons=File:…` tag values to direct
  /// upload.wikimedia.org thumbnail URLs via MediaWiki's imageinfo API.
  ///
  /// The naive Special:FilePath redirect we used before doesn't send
  /// `Access-Control-Allow-Origin: *` on the initial hop, so Flutter's
  /// CanvasKit renderer can't draw the image (it loads images via
  /// crossOrigin=anonymous fetch). The direct upload.wikimedia.org URLs
  /// returned by imageinfo do carry CORS headers.
  ///
  /// Keys in the returned map are the original tag values (including the
  /// `File:` prefix, exactly as the OSM tag carried them) — callers can
  /// look up by their input string.
  static Future<Map<String, String>> resolveCommonsBatch(
    Iterable<String> commonsTagValues, {
    int width = 1024,
  }) async {
    final out = <String, String>{};
    if (commonsTagValues.isEmpty) return out;

    // Normalize: ensure the title has the "File:" prefix the API expects,
    // remember the original tag value so we can key the result back.
    final byCanonical = <String, String>{};
    for (final raw in commonsTagValues) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      final canonical =
          trimmed.startsWith('File:') ? trimmed : 'File:$trimmed';
      byCanonical.putIfAbsent(canonical, () => raw);
    }
    if (byCanonical.isEmpty) return out;

    final keys = byCanonical.keys.toList();
    for (var i = 0; i < keys.length; i += 50) {
      final batch = keys.sublist(i, i + 50 > keys.length ? keys.length : i + 50);
      final joined = batch.map(Uri.encodeComponent).join('|');
      final uri = Uri.parse(
        'https://commons.wikimedia.org/w/api.php'
        '?action=query&format=json'
        '&prop=imageinfo&iiprop=url&iiurlwidth=$width'
        '&origin=*'
        '&titles=$joined',
      );
      try {
        final r = await http.get(uri, headers: const {
          'User-Agent':
              'Wegwiesel/2.1 (https://wegwiesel.app; support@thomas-peterson.de)',
        }).timeout(const Duration(seconds: 10));
        if (r.statusCode != 200) continue;
        final json = jsonDecode(r.body) as Map<String, dynamic>;
        final pages =
            (json['query'] as Map<String, dynamic>?)?['pages'] as Map?;
        if (pages == null) continue;
        for (final page in pages.values) {
          if (page is! Map) continue;
          final title = page['title'] as String?;
          final infos = page['imageinfo'] as List?;
          if (title == null || infos == null || infos.isEmpty) continue;
          final thumb = (infos.first as Map)['thumburl'] as String?;
          if (thumb == null) continue;
          final original = byCanonical[title];
          if (original != null) out[original] = thumb;
        }
      } catch (_) {
        // network/parse failure — leave these unresolved
      }
    }
    return out;
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
          // origin=* enables anonymous CORS access from the web build;
          // without it Chromium silently drops the response. Native
          // iOS/Android don't care either way.
          '&origin=*'
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

}
