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
  // Matches Commons wiki-page URLs like
  //   https://commons.wikimedia.org/wiki/File:Foo.jpg
  //   https://commons.wikimedia.org/wiki/Datei:Foo.jpg
  // which look image-shaped to a naive eye but actually return HTML.
  static final RegExp _commonsWikiPageUrl = RegExp(
    r'^https?://commons\.wikimedia\.org/wiki/(?:File|Datei|Bild|Fichier|Plik):(.+)$',
    caseSensitive: false,
  );

  /// Returns a thumbnail URL synchronously when possible. Recognises
  /// plain HTTPS `image=` URLs but specifically *rejects* Commons
  /// description-page URLs (`commons.wikimedia.org/wiki/File:…`) — those
  /// return HTML, not an image, and need [resolveCommonsBatch] to map
  /// them to a direct upload.wikimedia.org URL.
  static String? resolve(Map<String, String> tags) {
    final image = tags['image'];
    if (image != null && image.isNotEmpty) {
      final lower = image.toLowerCase();
      if (lower.startsWith('https://') || lower.startsWith('http://')) {
        if (_commonsWikiPageUrl.hasMatch(image)) return null; // needs async
        return image;
      }
    }
    return null;
  }

  /// Convenience: returns whatever Commons reference a POI carries that
  /// needs async resolution via [resolveCommonsBatch]. Covers:
  ///   - `wikimedia_commons=File:Foo.jpg`
  ///   - `image=File:Foo.jpg` (bare File: prefix)
  ///   - `image=https://commons.wikimedia.org/wiki/File:Foo.jpg` (page URL)
  /// Returns null if no such reference exists.
  static String? extractCommonsReference(Map<String, String> tags) {
    final commons = tags['wikimedia_commons'];
    if (commons != null && commons.isNotEmpty) return commons;
    final image = tags['image'];
    if (image == null || image.isEmpty) return null;
    if (image.startsWith('File:')) return image;
    final m = _commonsWikiPageUrl.firstMatch(image);
    if (m != null) {
      // Rebuild as File:<filename> so resolveCommonsBatch keys consistently.
      return 'File:${Uri.decodeComponent(m.group(1)!)}';
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

  /// Resolution chain for `wikipedia=` tags:
  ///   1. PageImages API — fast, but many Wikipedia articles don't have a
  ///      canonical page-image set (German Wikipedia in particular is
  ///      spotty for smaller landmarks).
  ///   2. For everything still unresolved, fall back to the article's
  ///      `prop=images` list, pick the first reasonable JPG/PNG, then
  ///      run that filename through [resolveCommonsBatch] to get the
  ///      CORS-safe direct upload URL.
  ///
  /// Result keys are the original raw `wikipedia=` tag values so callers
  /// can match back to their POIs.
  static Future<Map<String, String>> resolveWikipediaBatchWithFallback(
    Iterable<String> wikipediaTags, {
    int thumbWidth = 1024,
  }) async {
    final fromPageImages =
        await resolveWikipediaBatch(wikipediaTags, thumbWidth: thumbWidth);
    final unresolved =
        wikipediaTags.where((t) => !fromPageImages.containsKey(t)).toList();
    if (unresolved.isEmpty) return fromPageImages;

    // Per-title list of image files; pick first non-icon File.
    final pickedFileForTag =
        await _firstReasonableImagePerTag(unresolved);
    if (pickedFileForTag.isEmpty) return fromPageImages;

    final commonsBatch = await resolveCommonsBatch(
      pickedFileForTag.values,
      width: thumbWidth,
    );
    final out = Map<String, String>.from(fromPageImages);
    for (final entry in pickedFileForTag.entries) {
      final url = commonsBatch[entry.value];
      if (url != null) out[entry.key] = url;
    }
    return out;
  }

  /// For each `wikipedia=lang:Title` tag, asks the MediaWiki API for the
  /// list of images embedded in that page and picks the first one that
  /// looks like a real photo (skipping SVG icons, Commons logos, etc.).
  /// Returns a map of original-tag → File:Foo.jpg.
  static Future<Map<String, String>> _firstReasonableImagePerTag(
    Iterable<String> wikipediaTags,
  ) async {
    final out = <String, String>{};
    // Same grouping as resolveWikipediaBatch.
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
      final keys = titles.keys.toList();
      for (var i = 0; i < keys.length; i += 50) {
        final batch =
            keys.sublist(i, i + 50 > keys.length ? keys.length : i + 50);
        final joined = batch.map(Uri.encodeComponent).join('|');
        final uri = Uri.parse(
          'https://$lang.wikipedia.org/w/api.php'
          '?action=query&format=json'
          '&prop=images&imlimit=20'
          '&redirects=1&origin=*'
          '&titles=$joined',
        );
        try {
          final r = await http.get(uri, headers: const {
            'User-Agent':
                'Wegwiesel/2.1 (https://wegwiesel.app; support@thomas-peterson.de)',
          }).timeout(const Duration(seconds: 10));
          if (r.statusCode != 200) continue;
          final json = jsonDecode(r.body) as Map<String, dynamic>;
          final query = json['query'] as Map<String, dynamic>?;
          if (query == null) continue;

          final canonicalFor = <String, String>{
            for (final t in batch) t: t,
          };
          for (final pair in [
            ...?(query['normalized'] as List?),
            ...?(query['redirects'] as List?),
          ]) {
            if (pair is Map) {
              final from = pair['from'] as String?;
              final to = pair['to'] as String?;
              if (from != null && to != null) {
                canonicalFor.updateAll((k, v) => v == from ? to : v);
              }
            }
          }

          final pages = query['pages'] as Map<String, dynamic>?;
          if (pages == null) continue;
          for (final page in pages.values) {
            if (page is! Map) continue;
            final title = page['title'] as String?;
            final images = page['images'] as List?;
            if (title == null || images == null) continue;
            String? picked;
            for (final img in images) {
              if (img is! Map) continue;
              final name = img['title'] as String?;
              if (name == null) continue;
              if (_isLikelyIcon(name)) continue;
              picked = _stripFilePrefix(name);
              break;
            }
            if (picked == null) continue;
            canonicalFor.forEach((requested, canonical) {
              if (canonical == title) {
                final originalTag = titles[requested];
                if (originalTag != null) out[originalTag] = 'File:$picked';
              }
            });
          }
        } catch (_) {
          // best-effort
        }
      }
    }
    return out;
  }

  /// Heuristic: skip Wikipedia's own icons, badges and SVG logos so we
  /// land on a real photo. Works language-independently because we strip
  /// the local namespace prefix before checking (German Wikipedia uses
  /// "Datei:", French "Fichier:", etc.).
  static bool _isLikelyIcon(String fileTitle) {
    final bare = _stripFilePrefix(fileTitle).toLowerCase();
    if (bare.endsWith('.svg')) return true;
    if (bare.contains('logo')) return true;
    if (bare.contains('wiktionary')) return true;
    if (bare.contains('wikisource')) return true;
    if (bare.contains('wikiquote')) return true;
    if (bare.startsWith('wappen')) return true;
    if (bare.startsWith('flagge')) return true;
    if (bare.startsWith('coat of arms')) return true;
    if (bare.contains('disambig')) return true;
    return false;
  }

  /// Strips a file-namespace prefix ("File:", "Datei:", "Fichier:", "Bild:",
  /// "Plik:", "Soubor:", …) so the bare filename can be fed back to the
  /// Commons API which always expects "File:".
  static String _stripFilePrefix(String name) {
    final colon = name.indexOf(':');
    // Only treat short leading tokens as namespace prefixes — Commons
    // filenames themselves can contain colons further along.
    if (colon > 0 && colon <= 10) return name.substring(colon + 1);
    return name;
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
