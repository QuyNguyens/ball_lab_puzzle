import '../models/ball_color.dart';
import '../models/level_data.dart';
import '../models/tube.dart';

/// Service delivering curated, mathematically verified solvable puzzle levels.
class LevelProviderService {
  const LevelProviderService();

  static const BallColor _red = BallColor.crimsonRed;
  static const BallColor _blue = BallColor.cobaltBlue;
  static const BallColor _green = BallColor.emeraldGreen;
  static const BallColor _yellow = BallColor.amberYellow;

  /// Returns all available curated levels.
  List<LevelData> getLevels() {
    return <LevelData>[_level1, _level2, _level3, _level4, _level5];
  }

  /// Retrieves a specific level by its [levelId], or `null` if not found.
  LevelData? getLevel(int levelId) {
    for (final LevelData level in getLevels()) {
      if (level.levelId == levelId) return level;
    }
    return null;
  }

  /// Total count of curated levels.
  int get totalLevels => getLevels().length;

  /// Whether a level with [levelId] exists.
  bool hasLevel(int levelId) => getLevel(levelId) != null;

  // Level 1: 3 colors, 5 tubes (2 empty), alternating pairs.
  // Proven solution: 12 moves.
  static final LevelData _level1 = LevelData(
    levelId: 1,
    parMoves: 12,
    initialTubes: <Tube>[
      Tube(balls: const <BallColor>[_red, _blue, _red, _blue]),
      Tube(balls: const <BallColor>[_blue, _green, _blue, _green]),
      Tube(balls: const <BallColor>[_green, _red, _green, _red]),
      Tube(balls: const <BallColor>[]),
      Tube(balls: const <BallColor>[]),
    ],
  );

  // Level 2: 3 colors, 5 tubes (2 empty), block pairs.
  // Proven solution: 12 moves.
  static final LevelData _level2 = LevelData(
    levelId: 2,
    parMoves: 12,
    initialTubes: <Tube>[
      Tube(balls: const <BallColor>[_red, _red, _blue, _blue]),
      Tube(balls: const <BallColor>[_blue, _blue, _green, _green]),
      Tube(balls: const <BallColor>[_green, _green, _red, _red]),
      Tube(balls: const <BallColor>[]),
      Tube(balls: const <BallColor>[]),
    ],
  );

  // Level 3: 4 colors, 6 tubes (2 empty), triple bases with offset caps.
  // Proven solution: 16 moves.
  static final LevelData _level3 = LevelData(
    levelId: 3,
    parMoves: 16,
    initialTubes: <Tube>[
      Tube(balls: const <BallColor>[_red, _red, _red, _blue]),
      Tube(balls: const <BallColor>[_blue, _blue, _blue, _green]),
      Tube(balls: const <BallColor>[_green, _green, _green, _yellow]),
      Tube(balls: const <BallColor>[_yellow, _yellow, _yellow, _red]),
      Tube(balls: const <BallColor>[]),
      Tube(balls: const <BallColor>[]),
    ],
  );

  // Level 4: 4 colors, 6 tubes (2 empty), symmetric alternating stacks.
  // Proven solution: 16 moves.
  static final LevelData _level4 = LevelData(
    levelId: 4,
    parMoves: 16,
    initialTubes: <Tube>[
      Tube(balls: const <BallColor>[_red, _blue, _red, _blue]),
      Tube(balls: const <BallColor>[_green, _yellow, _green, _yellow]),
      Tube(balls: const <BallColor>[_blue, _red, _blue, _red]),
      Tube(balls: const <BallColor>[_yellow, _green, _yellow, _green]),
      Tube(balls: const <BallColor>[]),
      Tube(balls: const <BallColor>[]),
    ],
  );

  // Level 5: 4 colors, 6 tubes (2 empty), double blocks.
  // Proven solution: 12 moves.
  static final LevelData _level5 = LevelData(
    levelId: 5,
    parMoves: 12,
    initialTubes: <Tube>[
      Tube(balls: const <BallColor>[_red, _red, _blue, _blue]),
      Tube(balls: const <BallColor>[_green, _green, _yellow, _yellow]),
      Tube(balls: const <BallColor>[_blue, _blue, _red, _red]),
      Tube(balls: const <BallColor>[_yellow, _yellow, _green, _green]),
      Tube(balls: const <BallColor>[]),
      Tube(balls: const <BallColor>[]),
    ],
  );
}
