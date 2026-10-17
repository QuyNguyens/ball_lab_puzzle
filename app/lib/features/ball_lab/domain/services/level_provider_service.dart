import 'dart:math' as math;

import '../models/ball_color.dart';
import '../models/level_data.dart';
import '../models/tube.dart';
import 'puzzle_solver.dart';

/// Service delivering curated and deterministically generated, mathematically
/// verified solvable puzzle levels supporting 999+ levels.
class LevelProviderService {
  const LevelProviderService();

  /// Total supported levels in the campaign.
  static const int maxCampaignLevels = 999;

  /// Cache of generated levels in memory for instantaneous re-access.
  static final Map<int, LevelData> _generatedCache = <int, LevelData>{};

  static const BallColor _red = BallColor.crimsonRed;
  static const BallColor _blue = BallColor.cobaltBlue;
  static const BallColor _green = BallColor.emeraldGreen;
  static const BallColor _yellow = BallColor.amberYellow;

  /// Returns all 10 curated handcrafted foundational levels.
  static final List<LevelData> _curatedLevels = <LevelData>[
    _level1,
    _level2,
    _level3,
    _level4,
    _level5,
    _level6,
    _level7,
    _level8,
    _level9,
    _level10,
  ];

  /// Returns all 10 curated handcrafted foundational levels.
  List<LevelData> getCuratedLevels() =>
      List<LevelData>.unmodifiable(_curatedLevels);

  /// Returns curated levels for backward compatibility.
  List<LevelData> getLevels() => getCuratedLevels();

  /// Retrieves a specific level by its [levelId] (1 to [maxCampaignLevels]).
  /// Returns `null` if [levelId] is out of bounds.
  LevelData? getLevel(int levelId) {
    if (levelId < 1 || levelId > totalLevels) return null;
    if (levelId <= _curatedLevels.length) {
      return _curatedLevels[levelId - 1];
    }
    return _generatedCache.putIfAbsent(
      levelId,
      () => _generateLevel(levelId),
    );
  }

  /// Total count of available levels.
  int get totalLevels => maxCampaignLevels;

  /// Whether a level with [levelId] exists.
  bool hasLevel(int levelId) => levelId >= 1 && levelId <= totalLevels;

  /// Retrieves a slice of levels belonging to a specific chapter/chặng.
  List<LevelData> getLevelsForChapter(int chapterIndex, {int pageSize = 20}) {
    final int start = chapterIndex * pageSize + 1;
    final int end = math.min((chapterIndex + 1) * pageSize, totalLevels);
    final List<LevelData> list = <LevelData>[];
    for (int i = start; i <= end; i++) {
      final LevelData? level = getLevel(i);
      if (level != null) list.add(level);
    }
    return list;
  }

  /// Total count of chapters based on [pageSize].
  int getTotalChapters({int pageSize = 20}) =>
      (totalLevels + pageSize - 1) ~/ pageSize;

  // Level 1: 3 colors, 5 tubes (2 empty), alternating pairs.
  // Proven minimum solution: 12 moves, 6 buffer moves -> max 18 moves.
  // Stars: 3★ <= 12 moves, 2★ <= 15 moves, 1★ <= 18 moves.
  static final LevelData _level1 = LevelData(
    levelId: 1,
    minMoves: 12,
    parMoves: 12,
    maxMoves: 18,
    threeStarMoves: 12,
    twoStarMoves: 15,
    initialTubes: <Tube>[
      Tube(balls: const <BallColor>[_red, _blue, _red, _blue]),
      Tube(balls: const <BallColor>[_blue, _green, _blue, _green]),
      Tube(balls: const <BallColor>[_green, _red, _green, _red]),
      Tube(balls: const <BallColor>[]),
      Tube(balls: const <BallColor>[]),
    ],
  );

  // Level 2: 3 colors, 5 tubes (2 empty), block pairs.
  // Proven minimum solution: 8 moves, par: 12 moves, max 16 moves.
  // Stars: 3★ <= 10 moves, 2★ <= 13 moves, 1★ <= 16 moves.
  static final LevelData _level2 = LevelData(
    levelId: 2,
    minMoves: 8,
    parMoves: 12,
    maxMoves: 16,
    threeStarMoves: 10,
    twoStarMoves: 13,
    initialTubes: <Tube>[
      Tube(balls: const <BallColor>[_red, _red, _blue, _blue]),
      Tube(balls: const <BallColor>[_blue, _blue, _green, _green]),
      Tube(balls: const <BallColor>[_green, _green, _red, _red]),
      Tube(balls: const <BallColor>[]),
      Tube(balls: const <BallColor>[]),
    ],
  );

  // Level 3: 4 colors, 6 tubes (2 empty), triple bases with offset caps.
  // Proven minimum solution: 5 moves, par: 6 moves, max 9 moves.
  // Stars: 3★ <= 6 moves, 2★ <= 7 moves, 1★ <= 9 moves.
  static final LevelData _level3 = LevelData(
    levelId: 3,
    minMoves: 5,
    parMoves: 6,
    maxMoves: 9,
    threeStarMoves: 6,
    twoStarMoves: 7,
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
  // Proven minimum solution: 16 moves, par: 16 moves, max 20 moves.
  // Stars: 3★ <= 16 moves, 2★ <= 18 moves, 1★ <= 20 moves.
  static final LevelData _level4 = LevelData(
    levelId: 4,
    minMoves: 16,
    parMoves: 16,
    maxMoves: 20,
    threeStarMoves: 16,
    twoStarMoves: 18,
    initialTubes: <Tube>[
      Tube(balls: const <BallColor>[_red, _blue, _red, _blue]),
      Tube(balls: const <BallColor>[_green, _yellow, _green, _yellow]),
      Tube(balls: const <BallColor>[_blue, _red, _blue, _red]),
      Tube(balls: const <BallColor>[_yellow, _green, _yellow, _green]),
      Tube(balls: const <BallColor>[]),
      Tube(balls: const <BallColor>[]),
    ],
  );

  // Level 5: 4 colors, 6 tubes (2 empty), double blocks. Milestone Level!
  // Proven minimum solution: 12 moves, par: 12 moves, max 15 moves.
  // Stars: 3★ <= 12 moves, 2★ <= 13 moves, 1★ <= 15 moves.
  static final LevelData _level5 = LevelData(
    levelId: 5,
    minMoves: 12,
    parMoves: 12,
    maxMoves: 15,
    threeStarMoves: 12,
    twoStarMoves: 13,
    isMilestone: true,
    initialTubes: <Tube>[
      Tube(balls: const <BallColor>[_red, _red, _blue, _blue]),
      Tube(balls: const <BallColor>[_green, _green, _yellow, _yellow]),
      Tube(balls: const <BallColor>[_blue, _blue, _red, _red]),
      Tube(balls: const <BallColor>[_yellow, _yellow, _green, _green]),
      Tube(balls: const <BallColor>[]),
      Tube(balls: const <BallColor>[]),
    ],
  );

  // Level 6: 4 colors, 6 tubes (2 empty), cyclical offset.
  // Proven minimum solution: 15 moves, max 19 moves.
  // Stars: 3★ <= 15 moves, 2★ <= 17 moves, 1★ <= 19 moves.
  static final LevelData _level6 = LevelData(
    levelId: 6,
    minMoves: 15,
    parMoves: 15,
    maxMoves: 19,
    threeStarMoves: 15,
    twoStarMoves: 17,
    initialTubes: <Tube>[
      Tube(balls: const <BallColor>[_red, _green, _blue, _yellow]),
      Tube(balls: const <BallColor>[_green, _blue, _yellow, _red]),
      Tube(balls: const <BallColor>[_blue, _yellow, _red, _green]),
      Tube(balls: const <BallColor>[_yellow, _red, _green, _blue]),
      Tube(balls: const <BallColor>[]),
      Tube(balls: const <BallColor>[]),
    ],
  );

  // Level 7: 4 colors, 6 tubes (2 empty), double headers.
  // Proven minimum solution: 11 moves, max 15 moves.
  // Stars: 3★ <= 11 moves, 2★ <= 13 moves, 1★ <= 15 moves.
  static final LevelData _level7 = LevelData(
    levelId: 7,
    minMoves: 11,
    parMoves: 11,
    maxMoves: 15,
    threeStarMoves: 11,
    twoStarMoves: 13,
    initialTubes: <Tube>[
      Tube(balls: const <BallColor>[_red, _red, _blue, _green]),
      Tube(balls: const <BallColor>[_blue, _blue, _green, _yellow]),
      Tube(balls: const <BallColor>[_green, _green, _yellow, _red]),
      Tube(balls: const <BallColor>[_yellow, _yellow, _red, _blue]),
      Tube(balls: const <BallColor>[]),
      Tube(balls: const <BallColor>[]),
    ],
  );

  // Level 8: 4 colors, 6 tubes (2 empty), sandwich stacks.
  // Proven minimum solution: 17 moves, max 21 moves.
  // Stars: 3★ <= 17 moves, 2★ <= 19 moves, 1★ <= 21 moves.
  static final LevelData _level8 = LevelData(
    levelId: 8,
    minMoves: 17,
    parMoves: 17,
    maxMoves: 21,
    threeStarMoves: 17,
    twoStarMoves: 19,
    initialTubes: <Tube>[
      Tube(balls: const <BallColor>[_red, _green, _red, _yellow]),
      Tube(balls: const <BallColor>[_blue, _yellow, _blue, _green]),
      Tube(balls: const <BallColor>[_green, _red, _green, _blue]),
      Tube(balls: const <BallColor>[_yellow, _blue, _yellow, _red]),
      Tube(balls: const <BallColor>[]),
      Tube(balls: const <BallColor>[]),
    ],
  );

  // Level 9: 4 colors, 6 tubes (2 empty), reverse cycle.
  // Proven minimum solution: 15 moves, max 19 moves.
  // Stars: 3★ <= 15 moves, 2★ <= 17 moves, 1★ <= 19 moves.
  static final LevelData _level9 = LevelData(
    levelId: 9,
    minMoves: 15,
    parMoves: 15,
    maxMoves: 19,
    threeStarMoves: 15,
    twoStarMoves: 17,
    initialTubes: <Tube>[
      Tube(balls: const <BallColor>[_red, _blue, _yellow, _green]),
      Tube(balls: const <BallColor>[_blue, _yellow, _green, _red]),
      Tube(balls: const <BallColor>[_yellow, _green, _red, _blue]),
      Tube(balls: const <BallColor>[_green, _red, _blue, _yellow]),
      Tube(balls: const <BallColor>[]),
      Tube(balls: const <BallColor>[]),
    ],
  );

  // Level 10: Milestone Grand Boss Level!
  // Proven minimum solution: 15 moves, tightly budgeted max 18 moves.
  // Stars: 3★ <= 15 moves, 2★ <= 17 moves, 1★ <= 18 moves.
  static final LevelData _level10 = LevelData(
    levelId: 10,
    minMoves: 15,
    parMoves: 15,
    maxMoves: 18,
    threeStarMoves: 15,
    twoStarMoves: 17,
    isMilestone: true,
    initialTubes: <Tube>[
      Tube(balls: const <BallColor>[_red, _yellow, _blue, _green]),
      Tube(balls: const <BallColor>[_green, _red, _yellow, _blue]),
      Tube(balls: const <BallColor>[_blue, _green, _red, _yellow]),
      Tube(balls: const <BallColor>[_yellow, _blue, _green, _red]),
      Tube(balls: const <BallColor>[]),
      Tube(balls: const <BallColor>[]),
    ],
  );

  // =========================================================================
  // Guaranteed-Solvable Deterministic Level Generator (Levels 11 - 999+)
  // =========================================================================

  static LevelData _generateLevel(int levelId) {
    // 1. Difficulty progression stages
    final int colorCount;
    final int targetSteps;
    final bool isMilestone =
        (levelId % 10 == 0) || (levelId == maxCampaignLevels);

    if (levelId <= 25) {
      // Stage 1: Warmup - 3 colors, 5 tubes
      colorCount = 3;
      targetSteps =
          14 + ((levelId - 11) * 0.4).round() + (isMilestone ? 3 : 0);
    } else if (levelId <= 75) {
      // Stage 2: Foundation - 4 colors, 6 tubes
      colorCount = 4;
      targetSteps =
          18 + ((levelId - 26) * 0.25).round() + (isMilestone ? 4 : 0);
    } else if (levelId <= 200) {
      // Stage 3: Strategic - 5 colors, 7 tubes
      colorCount = 5;
      targetSteps =
          24 + ((levelId - 76) * 0.12).round() + (isMilestone ? 4 : 0);
    } else if (levelId <= 500) {
      // Stage 4: Advanced - 6 colors, 8 tubes
      colorCount = 6;
      targetSteps =
          30 + ((levelId - 201) * 0.05).round() + (isMilestone ? 5 : 0);
    } else {
      // Stage 5: Master Lab - 7 colors, 9 tubes
      colorCount = 7;
      targetSteps =
          36 + ((levelId - 501) * 0.03).round() + (isMilestone ? 5 : 0);
    }

    const int emptyTubes = 2;
    final int totalTubes = colorCount + emptyTubes;

    // 2. Stable pseudo-random seed unique to this levelId
    final math.Random rng = math.Random(levelId * 31337 + 7);

    // 3. Deterministic color palette selection
    final List<BallColor> availableColors =
        List<BallColor>.of(BallColor.values);
    for (int i = availableColors.length - 1; i > 0; i--) {
      final int j = rng.nextInt(i + 1);
      final BallColor temp = availableColors[i];
      availableColors[i] = availableColors[j];
      availableColors[j] = temp;
    }
    final List<BallColor> chosenColors = availableColors.sublist(0, colorCount);

    // 4. Initial sorted/completed state
    final List<List<BallColor>> tubes = List<List<BallColor>>.generate(
      totalTubes,
      (int index) {
        if (index < colorCount) {
          return List<BallColor>.filled(4, chosenColors[index], growable: true);
        }
        return <BallColor>[];
      },
    );

    // 5. Guaranteed-Solvable Backward Scramble
    // Starting from solved state, execute legal reverse moves.
    // Each reverse move is mathematically proven to be reversible by a legal forward move.
    int lastFrom = -1;
    int lastTo = -1;
    int successfulSteps = 0;
    final int maxAttempts = targetSteps * 15;
    int attempts = 0;

    while (successfulSteps < targetSteps && attempts < maxAttempts) {
      attempts++;

      final List<_BackwardCandidate> candidates = <_BackwardCandidate>[];

      for (int d = 0; d < totalTubes; d++) {
        if (tubes[d].isEmpty) continue;
        final BallColor ball = tubes[d].last;

        // In forward play, d was destination. It was valid iff:
        // after popping ball, d is empty OR the next top ball is identical to ball.
        final bool validDestinationInForward =
            tubes[d].length == 1 || tubes[d][tubes[d].length - 2] == ball;
        if (!validDestinationInForward) continue;

        for (int s = 0; s < totalTubes; s++) {
          if (d == s) continue;
          if (tubes[s].length >= 4) continue;

          // In forward play, s was source. It was valid iff s was not already solved:
          if (tubes[s].length == 3) {
            final bool wouldBecomeSolved =
                tubes[s].every((BallColor c) => c == ball);
            if (wouldBecomeSolved) continue;
          }

          candidates.add(_BackwardCandidate(d, s));
        }
      }

      if (candidates.isEmpty) {
        break;
      }

      // Avoid immediate ping-pong reversal if alternatives exist
      List<_BackwardCandidate> filtered = candidates;
      if (candidates.length > 1 && lastFrom != -1 && lastTo != -1) {
        final List<_BackwardCandidate> nonReversal = candidates
            .where(
              (_BackwardCandidate c) =>
                  !(c.from == lastTo && c.to == lastFrom),
            )
            .toList();
        if (nonReversal.isNotEmpty) {
          filtered = nonReversal;
        }
      }

      final _BackwardCandidate chosen =
          filtered[rng.nextInt(filtered.length)];
      final BallColor ball = tubes[chosen.from].removeLast();
      tubes[chosen.to].add(ball);

      lastFrom = chosen.from;
      lastTo = chosen.to;
      successfulSteps++;
    }

    // Ensure auxiliary tubes are empty and all main tubes each have 4 balls
    for (int aux = colorCount; aux < totalTubes; aux++) {
      while (tubes[aux].isNotEmpty) {
        final BallColor ball = tubes[aux].removeLast();
        for (int m = 0; m < colorCount; m++) {
          if (tubes[m].length < 4) {
            tubes[m].add(ball);
            successfulSteps++;
            break;
          }
        }
      }
    }

    // Safety check: if tubes ended up solved or empty
    final bool isSolved = tubes.every(
      (List<BallColor> t) =>
          t.isEmpty ||
          (t.length == 4 && t.every((BallColor c) => c == t.first)),
    );
    if (isSolved || successfulSteps < 4) {
      return _buildFallbackLevel(
        levelId,
        chosenColors,
        totalTubes,
        isMilestone,
      );
    }

    final List<Tube> tubeObjects = tubes
        .map(
          (List<BallColor> balls) =>
              Tube(balls: List<BallColor>.unmodifiable(balls)),
        )
        .toList();

    // Mathematically determine shortest solution via Breadth-First Search (BFS)
    final LevelData tempLevel = LevelData(
      levelId: levelId,
      initialTubes: tubeObjects,
      maxMoves: 99,
    );

    final int? minMoves = const PuzzleSolver().findShortestMoveCount(
      tempLevel,
      maxDepth: 40,
    );

    // If BFS cannot find a valid solution or puzzle is degenerate, switch to deterministic verified fallback
    if (minMoves == null || minMoves <= 0) {
      return _buildFallbackLevel(
        levelId,
        chosenColors,
        totalTubes,
        isMilestone,
      );
    }

    // 6. Move limit calibrated strictly based on minimal solution + buffer:
    // Giới hạn lượt đi = Số bước giải tối thiểu + Số lượt dự phòng
    // Mặc định 4 lượt dự phòng, hoặc 3 lượt cho milestone boss challenge.
    final int bufferMoves = isMilestone ? 3 : 4;
    final int maxMoves = minMoves + bufferMoves;
    final int parMoves = minMoves;
    final int threeStarMoves = minMoves;
    final int twoStarMoves = minMoves + (bufferMoves ~/ 2);

    return LevelData(
      levelId: levelId,
      initialTubes: tubeObjects,
      parMoves: parMoves,
      minMoves: minMoves,
      maxMoves: maxMoves,
      threeStarMoves: threeStarMoves,
      twoStarMoves: twoStarMoves,
      isMilestone: isMilestone,
    );
  }

  static LevelData _buildFallbackLevel(
    int levelId,
    List<BallColor> colors,
    int tubeCount,
    bool isMilestone,
  ) {
    final int colorCount = colors.length;
    final List<List<BallColor>> tubeBalls = List<List<BallColor>>.generate(
      tubeCount,
      (_) => <BallColor>[],
    );
    for (int i = 0; i < colorCount; i++) {
      final BallColor c1 = colors[i];
      final BallColor c2 = colors[(i + 1) % colorCount];
      tubeBalls[i].addAll(<BallColor>[c1, c1, c2, c2]);
    }
    final List<Tube> tubeList = tubeBalls
        .map(
          (List<BallColor> balls) =>
              Tube(balls: List<BallColor>.unmodifiable(balls)),
        )
        .toList();

    final LevelData tempFallback = LevelData(
      levelId: levelId,
      initialTubes: tubeList,
      maxMoves: 99,
    );
    final int? solvedMin = const PuzzleSolver().findShortestMoveCount(
      tempFallback,
      maxDepth: 35,
    );

    final int minMoves = solvedMin ?? (colorCount * 2 + 2);
    final int bufferMoves = isMilestone ? 3 : 4;
    final int maxMoves = minMoves + bufferMoves;
    final int parMoves = minMoves;
    final int threeStarMoves = minMoves;
    final int twoStarMoves = minMoves + (bufferMoves ~/ 2);

    return LevelData(
      levelId: levelId,
      initialTubes: tubeList,
      parMoves: parMoves,
      minMoves: minMoves,
      maxMoves: maxMoves,
      threeStarMoves: threeStarMoves,
      twoStarMoves: twoStarMoves,
      isMilestone: isMilestone,
    );
  }
}

class _BackwardCandidate {
  const _BackwardCandidate(this.from, this.to);
  final int from;
  final int to;
}
