/// One turn instruction emitted by BRouter at a coordinate index.
///
/// BRouter `voicehints` rows look like:
///   [trkpt_index, cmd, exit_number, distance_to_next_m, angle]
class TurnHint {
  final int coordIndex;
  final TurnCmd cmd;
  final int exitNumber; // 0 unless roundabout
  final double distanceToNextM;
  final double angle;

  const TurnHint({
    required this.coordIndex,
    required this.cmd,
    required this.exitNumber,
    required this.distanceToNextM,
    required this.angle,
  });

  static TurnHint? fromList(List raw) {
    if (raw.length < 5) return null;
    final idx = (raw[0] as num?)?.toInt();
    final code = (raw[1] as num?)?.toInt();
    final exit = (raw[2] as num?)?.toInt() ?? 0;
    final dist = (raw[3] as num?)?.toDouble() ?? 0;
    final angle = (raw[4] as num?)?.toDouble() ?? 0;
    if (idx == null || code == null) return null;
    return TurnHint(
      coordIndex: idx,
      cmd: TurnCmd.fromCode(code),
      exitNumber: exit,
      distanceToNextM: dist,
      angle: angle,
    );
  }
}

enum TurnCmd {
  unknown,
  uTurnLeft,        // 1
  turnLeft,         // 2
  turnSlightLeft,   // 3
  keepLeft,         // 4
  straight,         // 5
  keepRight,        // 6
  turnSlightRight,  // 7
  turnRight,        // 8
  uTurnRight,       // 9
  uTurn,            // 10
  roundabout1,      // 11
  roundabout2,      // 12
  roundabout3,      // 13
  roundabout4,      // 14
  roundabout5,      // 15
  roundabout6,      // 16
  roundaboutLeft,   // 17 (counter-clockwise)
  exit;             // 18+

  static TurnCmd fromCode(int code) {
    switch (code) {
      case 1: return TurnCmd.uTurnLeft;
      case 2: return TurnCmd.turnLeft;
      case 3: return TurnCmd.turnSlightLeft;
      case 4: return TurnCmd.keepLeft;
      case 5: return TurnCmd.straight;
      case 6: return TurnCmd.keepRight;
      case 7: return TurnCmd.turnSlightRight;
      case 8: return TurnCmd.turnRight;
      case 9: return TurnCmd.uTurnRight;
      case 10: return TurnCmd.uTurn;
      case 11: return TurnCmd.roundabout1;
      case 12: return TurnCmd.roundabout2;
      case 13: return TurnCmd.roundabout3;
      case 14: return TurnCmd.roundabout4;
      case 15: return TurnCmd.roundabout5;
      case 16: return TurnCmd.roundabout6;
      case 17: return TurnCmd.roundaboutLeft;
      case 18: return TurnCmd.exit;
      default: return TurnCmd.unknown;
    }
  }
}
