import 'package:web/web.dart' as web;

String? readShareParam() {
  final search = web.window.location.search;
  if (search.isEmpty) return null;
  final q = search.startsWith('?') ? search.substring(1) : search;
  for (final pair in q.split('&')) {
    final eq = pair.indexOf('=');
    if (eq <= 0) continue;
    final key = pair.substring(0, eq);
    if (key == 'r') {
      return Uri.decodeComponent(pair.substring(eq + 1));
    }
  }
  return null;
}

void updateShareParam(String? encoded) {
  final loc = web.window.location;
  final base = '${loc.origin}${loc.pathname}';
  final newUrl = encoded == null ? base : '$base?r=$encoded';
  web.window.history.replaceState(null, '', newUrl);
}

String currentBaseUrl() {
  final loc = web.window.location;
  return '${loc.origin}${loc.pathname}';
}
