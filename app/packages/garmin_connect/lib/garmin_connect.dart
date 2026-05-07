import 'package:flutter/services.dart';

/// A paired Garmin device (Edge, Fenix, etc.) discovered via Garmin Connect Mobile.
class GarminDevice {
  final String id;
  final String name;
  final String modelName;
  final String status; // "connected" | "notConnected" | "notPaired" | "unknown"

  const GarminDevice({
    required this.id,
    required this.name,
    required this.modelName,
    required this.status,
  });

  factory GarminDevice.fromMap(Map<dynamic, dynamic> m) => GarminDevice(
        id: m['id'] as String,
        name: (m['name'] as String?) ?? '',
        modelName: (m['modelName'] as String?) ?? '',
        status: (m['status'] as String?) ?? 'unknown',
      );

  bool get isConnected => status == 'connected';
}

class GarminConnectUnavailableException implements Exception {
  final String reason; // "noGcm" | "notInstalled" | "platformUnsupported"
  GarminConnectUnavailableException(this.reason);
  @override
  String toString() => 'GarminConnect unavailable: $reason';
}

class GarminConnect {
  static const _channel = MethodChannel('wegwiesel/garmin');

  /// True if Garmin Connect Mobile is installed and the SDK is reachable.
  static Future<bool> isAvailable() async {
    try {
      return (await _channel.invokeMethod<bool>('isAvailable')) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Returns the cached list of devices the user has previously authorised
  /// for this companion app. Empty until [pickDevices] runs at least once.
  static Future<List<GarminDevice>> listDevices() async {
    final raw = await _channel.invokeMethod<List<dynamic>>('listDevices');
    if (raw == null) return [];
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map(GarminDevice.fromMap)
        .toList(growable: false);
  }

  /// Launches Garmin Connect Mobile so the user can pick which paired devices
  /// to grant Wegwiesel access to. Resolves with the new device list when GCM
  /// hands control back via the registered URL scheme.
  static Future<List<GarminDevice>> pickDevices() async {
    final raw = await _channel.invokeMethod<List<dynamic>>('pickDevices');
    if (raw == null) return [];
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map(GarminDevice.fromMap)
        .toList(growable: false);
  }

  /// Sends a 6-character share code to the Wegwiesel Sync IQ app on the device.
  /// Throws PlatformException on transport errors; the future completes when
  /// the SDK confirms the message was delivered.
  static Future<void> sendCode({
    required String deviceId,
    required String code,
  }) async {
    await _channel.invokeMethod<void>('sendCode', {
      'deviceId': deviceId,
      'code': code,
    });
  }
}
