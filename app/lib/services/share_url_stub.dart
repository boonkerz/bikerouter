// On native platforms there is no URL to read a share param from. The only
// exception is the screenshot integration test, which seeds a route via a
// compile-time define so the map opens on a known route. In normal release
// builds WW_SHARE is empty, so this stays null and behaviour is unchanged.
const String _screenshotShare = String.fromEnvironment('WW_SHARE');

String? readShareParam() => _screenshotShare.isEmpty ? null : _screenshotShare;

void updateShareParam(String? encoded) {}

String currentBaseUrl() => 'https://wegwiesel.app/';
