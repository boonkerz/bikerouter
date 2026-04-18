export 'share_url_stub.dart'
    if (dart.library.html) 'share_url_web.dart'
    if (dart.library.io) 'share_url_stub.dart';
