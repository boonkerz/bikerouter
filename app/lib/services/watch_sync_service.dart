import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/turn_hint.dart';

/// Bridges navigation state to a paired Apple Watch (and later Wear OS).
///
/// The phone owns all of the actual routing logic; the watch is a thin
/// glance-screen showing the next turn, the distance to it, and the
/// remaining-trip ETA. Updates are pushed best-effort — if the watch is
/// asleep or out of range, the next [updateNavigation] call replaces the
/// queued payload.
///
/// On Android we stub everything so the navigation screen can call us
/// unconditionally; Wear OS wiring will land in v2.2 phase 2.
class WatchSyncService {
  WatchSyncService._();
  static final WatchSyncService instance = WatchSyncService._();

  static const MethodChannel _channel = MethodChannel('wegwiesel/watch');

  bool _navigationActive = false;

  /// Whether the platform side reports a watch paired and reachable.
  /// We don't gate updates on this — `transferUserInfo` queues things
  /// while the watch is asleep — but the UI can use it to flag "Watch
  /// is currently the source of truth".
  Future<bool> get isWatchReachable async {
    if (!_isSupportedPlatform) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isReachable');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Sends a single navigation snapshot to the watch. Called from the
  /// navigation screen whenever the turn-by-turn state changes (new
  /// instruction, distance ticks down, etc.). Drops payloads silently if
  /// the platform side isn't wired up — we don't want a missing native
  /// bridge to crash navigation.
  Future<void> updateNavigation({
    required WatchTurnDirection direction,
    required int distanceToTurnMeters,
    required double remainingKm,
    required int remainingMinutes,
    String? streetName,
  }) async {
    if (!_isSupportedPlatform) return;
    _navigationActive = true;
    try {
      await _channel.invokeMethod('updateNavigation', <String, Object?>{
        'direction': direction.id,
        'distanceMeters': distanceToTurnMeters,
        'remainingKm': remainingKm,
        'remainingMinutes': remainingMinutes,
        if (streetName != null) 'streetName': streetName,
      });
    } catch (e, st) {
      // Don't blow up the navigation timer for a watch glitch.
      if (kDebugMode) debugPrint('watch updateNavigation failed: $e\n$st');
    }
  }

  /// Tells the watch to clear its navigation glance — used when the user
  /// stops navigation, finishes the route, or leaves the navigation
  /// screen. Idempotent.
  Future<void> stopNavigation() async {
    if (!_isSupportedPlatform || !_navigationActive) return;
    _navigationActive = false;
    try {
      await _channel.invokeMethod('stopNavigation');
    } catch (_) {
      // best-effort
    }
  }

  // Apple Watch via WatchConnectivity (v2.2 P1) and Wear OS via the
  // Wearable Data Layer (v2.2 P2) both speak through the same Flutter
  // method channel — each platform plugs its own bridge in on the native
  // side. Other platforms (web/desktop) have no companion to talk to.
  bool get _isSupportedPlatform => Platform.isIOS || Platform.isAndroid;
}

/// Stable string identifiers shared with the Swift side so the wire
/// format doesn't depend on enum-index order.
enum WatchTurnDirection {
  straight('straight'),
  slightLeft('slight_left'),
  left('left'),
  sharpLeft('sharp_left'),
  uTurn('u_turn'),
  sharpRight('sharp_right'),
  right('right'),
  slightRight('slight_right'),
  arrived('arrived');

  const WatchTurnDirection(this.id);
  final String id;

  /// Maps the app's [TurnCmd] enum to the watch's coarser direction
  /// set. Roundabouts collapse to the side they exit on; anything we
  /// can't classify falls through to [straight] — better to show "fahr
  /// weiter" than the wrong arrow.
  static WatchTurnDirection fromTurnCmd(TurnCmd? cmd) {
    if (cmd == null) return straight;
    switch (cmd) {
      case TurnCmd.straight:
        return straight;
      case TurnCmd.keepLeft:
      case TurnCmd.turnSlightLeft:
        return slightLeft;
      case TurnCmd.turnLeft:
        return left;
      case TurnCmd.uTurnLeft:
        return uTurn;
      case TurnCmd.keepRight:
      case TurnCmd.turnSlightRight:
        return slightRight;
      case TurnCmd.turnRight:
        return right;
      case TurnCmd.uTurnRight:
      case TurnCmd.uTurn:
        return uTurn;
      case TurnCmd.roundabout1:
      case TurnCmd.roundabout2:
      case TurnCmd.roundabout3:
      case TurnCmd.roundabout4:
      case TurnCmd.roundabout5:
      case TurnCmd.roundabout6:
      case TurnCmd.roundaboutLeft:
        return right; // most roundabouts in DE/AT/CH exit going right-ish
      case TurnCmd.unknown:
      case TurnCmd.exit:
        return straight;
    }
  }
}
