/// Extracts a thumbnail-friendly photo URL from an OSM-tagged POI's tags.
///
/// Wikimedia Commons is the primary source because it exposes a stable
/// "Special:FilePath" redirect that turns a filename directly into the
/// underlying image — no Wikipedia API call, no auth, no rate limits to
/// worry about. The `image=` tag is preferred when it's already an https
/// URL (often points straight at Commons or the museum's own server);
/// `wikimedia_commons=File:...` is the fallback for everything else.
class PoiImageResolver {
  /// Returns a thumbnail URL (≤ 1024 px wide) or null when no photo
  /// reference is available. The result is safe to drop into a
  /// [NetworkImage] / `Image.network`.
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

  /// Special:FilePath redirects to the canonical file URL. Adding ?width
  /// forces Commons to serve a server-side-resized thumbnail rather than
  /// the (often multi-megabyte) original.
  static String _commonsFilePathUrl(String filename, {int width = 1024}) {
    final encoded = Uri.encodeComponent(filename.replaceAll(' ', '_'));
    return 'https://commons.wikimedia.org/wiki/Special:FilePath/$encoded?width=$width';
  }
}
