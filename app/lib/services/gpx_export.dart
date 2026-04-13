export 'gpx_export_stub.dart'
    if (dart.library.html) 'gpx_export_web.dart'
    if (dart.library.io) 'gpx_export_native.dart';
