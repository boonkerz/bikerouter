import 'dart:io' show Platform;

// On native platforms there is no URL to read a share param from. The only
// exception is screenshot generation, which seeds a route so the map opens on a
// known route. The capture script (scripts/ios-screenshots.sh) passes the route
// per launch via the WW_SHARE process environment — read at runtime so a single
// build can produce several different shots. A compile-time define is kept as a
// fallback. In normal builds neither is set, so this stays null and behaviour
// is unchanged.
const String _compiledShare = String.fromEnvironment('WW_SHARE');

String? readShareParam() {
  final env = Platform.environment['WW_SHARE'];
  if (env != null && env.isNotEmpty) return env;
  return _compiledShare.isEmpty ? null : _compiledShare;
}

void updateShareParam(String? encoded) {}

String currentBaseUrl() => 'https://wegwiesel.app/';
