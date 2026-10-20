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
    this.minMoves,
    int? maxMoves,
    int? threeStarMoves,
    int? twoStarMoves,
    this.isMilestone = false,
  })  : maxMoves = _resolveMaxMoves(maxMoves, parMoves),
        threeStarMoves = _resolveThreeStar(
          threeStarMoves,
          parMoves,
          minMoves,
          maxMoves,
        ),
        twoStarMoves = _resolveTwoStar(
          twoStarMoves,
          threeStarMoves,
          parMoves,
          minMoves,
          maxMoves,
        ),
        initialTubes = List<Tube>.unmodifiable(initialTubes) {
    validate(this);
  }

  static int _resolveMaxMoves(int? maxMoves, int? parMoves) {
    return maxMoves ?? (parMoves != null ? parMoves + 6 : 20);
  }

  static int _resolveThreeStar(
    int? three,
    int? par,
    int? min,
    int? max,
  ) {
    final int resolvedMax = _resolveMaxMoves(max, par);
    final int base = three ?? par ?? min ?? 10;
    return base.clamp(1, resolvedMax);
  }

  static int _resolveTwoStar(
    int? two,
    int? three,
    int? par,
    int? min,
    int? max,
  ) {
    final int resolvedMax = _resolveMaxMoves(max, par);
    final int resolvedThree = _resolveThreeStar(three, par, min, max);
    if (two != null) return two;
    if (resolvedMax <= resolvedThree) return resolvedThree;
    final int buffer = (resolvedMax - resolvedThree) ~/ 2;
    return (resolvedThree + (buffer > 0 ? buffer : 1)).clamp(
      resolvedThree,
      resolvedMax,
    );
  }

  /// Level identifier (must be positive).
  final int levelId;

  /// Initial tube arrangement when the level starts.
  final List<Tube> initialTubes;

  /// Optional target move count for achieving a 3-star rating.
  final int? parMoves;

  /// Mathematically verified minimum moves required to solve this level.
  final int? minMoves;

  /// Maximum allowed moves before the player runs out of moves.
  final int maxMoves;

  /// Maximum moves allowed to earn a 3-star rating (movesUsed <= threeStarMoves).
  final int threeStarMoves;

  /// Maximum moves allowed to earn a 2-star rating (movesUsed <= twoStarMoves).
  final int twoStarMoves;

  /// Whether this level represents a highlighted milestone/boss challenge.
  final bool isMilestone;

  /// Evaluates star rating (1 to 3 stars) based on moves taken upon level victory.
  /// Returns 0 if movesUsed exceeds [maxMoves].
  int calculateStars(int movesUsed) {
    if (movesUsed <= 0) return 0;
    if (movesUsed <= threeStarMoves) return 3;
    if (movesUsed <= twoStarMoves) return 2;
    if (movesUsed <= maxMoves) return 1;
    return 0;
  }

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
    if (level.minMoves != null && level.minMoves! <= 0) {
      throw ArgumentError.value(
        level.minMoves,
        'minMoves',
        'minMoves must be positive if supplied.',
      );
    }
    if (level.maxMoves <= 0) {
      throw ArgumentError.value(
        level.maxMoves,
        'maxMoves',
        'maxMoves must be positive.',
      );
    }
    if (level.minMoves != null && level.minMoves! > level.maxMoves) {
      throw ArgumentError(
        'minMoves (${level.minMoves}) cannot exceed maxMoves (${level.maxMoves}).',
      );
    }
    if (level.threeStarMoves <= 0) {
      throw ArgumentError.value(
        level.threeStarMoves,
        'threeStarMoves',
        'threeStarMoves must be positive.',
      );
    }
    if (level.twoStarMoves < level.threeStarMoves) {
      throw ArgumentError(
        'twoStarMoves (${level.twoStarMoves}) must be >= threeStarMoves (${level.threeStarMoves}).',
      );
    }
    if (level.twoStarMoves > level.maxMoves) {
      throw ArgumentError(
        'twoStarMoves (${level.twoStarMoves}) cannot exceed maxMoves (${level.maxMoves}).',
      );
    }
    if (level.minMoves != null && level.threeStarMoves < level.minMoves!) {
      throw ArgumentError(
        'threeStarMoves (${level.threeStarMoves}) cannot be less than verified minMoves (${level.minMoves}).',
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
        minMoves != other.minMoves ||
        maxMoves != other.maxMoves ||
        threeStarMoves != other.threeStarMoves ||
        twoStarMoves != other.twoStarMoves ||
        isMilestone != other.isMilestone ||
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
    return Object.hash(
      levelId,
      parMoves,
      minMoves,
      maxMoves,
      threeStarMoves,
      twoStarMoves,
      isMilestone,
      Object.hashAll(initialTubes),
    );
  }

  @override
  String toString() =>
      'LevelData(level: $levelId, tubes: ${initialTubes.length}, min: $minMoves, max: $maxMoves, 3★: <=$threeStarMoves, 2★: <=$twoStarMoves, milestone: $isMilestone)';
}
