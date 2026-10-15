import 'package:meta/meta.dart';

import 'ball_color.dart';
import 'tube.dart';

/// Specification and initial configuration of a Ball Lab puzzle level.
@immutable
class LevelData {
  LevelData({
    required this.levelId,
    required List<Tube> initialTubes,
    this.parMoves,
  }) : initialTubes = List<Tube>.unmodifiable(initialTubes) {
    validate(this);
  }

  /// Level identifier (must be positive).
  final int levelId;

  /// Initial tube arrangement when the level starts.
  final List<Tube> initialTubes;

  /// Optional target move count for achieving a 3-star rating.
  final int? parMoves;

  /// Returns the set of distinct ball colors used in this level.
  Set<BallColor> get distinctColors {
    final Set<BallColor> colors = <BallColor>{};
    for (final Tube tube in initialTubes) {
      colors.addAll(tube.balls);
    }
    return colors;
  }

  /// Validates that a [LevelData] instance conforms to all domain rules.
  static void validate(LevelData level) {
    if (level.levelId <= 0) {
      throw ArgumentError.value(
        level.levelId,
        'levelId',
        'Level ID must be positive.',
      );
    }
    if (level.initialTubes.isEmpty) {
      throw ArgumentError('Level must contain at least one tube.');
    }
    if (level.parMoves != null && level.parMoves! <= 0) {
      throw ArgumentError.value(
        level.parMoves,
        'parMoves',
        'parMoves must be positive if supplied.',
      );
    }

    // Invariant: Consistent tube capacity across all tubes.
    final int capacity = level.initialTubes.first.capacity;
    for (int i = 0; i < level.initialTubes.length; i++) {
      final Tube tube = level.initialTubes[i];
      if (tube.capacity != capacity) {
        throw ArgumentError(
          'Tube at index $i has capacity ${tube.capacity}, expected $capacity.',
        );
      }
    }

    // Invariant: Ball count per color must equal tube capacity.
    final Map<BallColor, int> colorCounts = <BallColor, int>{};
    for (final Tube tube in level.initialTubes) {
      for (final BallColor color in tube.balls) {
        colorCounts[color] = (colorCounts[color] ?? 0) + 1;
      }
    }

    if (colorCounts.isEmpty) {
      throw ArgumentError('Level must contain at least one ball.');
    }

    for (final MapEntry<BallColor, int> entry in colorCounts.entries) {
      if (entry.value != capacity) {
        throw ArgumentError(
          'Color ${entry.key.name} has ${entry.value} balls, expected exactly $capacity.',
        );
      }
    }

    // Invariant: Level must not already be in a solved state initially.
    final bool alreadyWon = level.initialTubes.every((Tube t) => t.isComplete);
    if (alreadyWon) {
      throw ArgumentError('Initial level state cannot already be solved.');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LevelData) return false;
    if (levelId != other.levelId ||
        parMoves != other.parMoves ||
        initialTubes.length != other.initialTubes.length) {
      return false;
    }
    for (int i = 0; i < initialTubes.length; i++) {
      if (initialTubes[i] != other.initialTubes[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(levelId, parMoves, Object.hashAll(initialTubes));
  }

  @override
  String toString() =>
      'LevelData(level: $levelId, tubes: ${initialTubes.length}, par: $parMoves)';
}
