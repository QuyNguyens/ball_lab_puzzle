import 'dart:collection';

import '../models/ball_color.dart';
import '../models/game_state.dart';
import '../models/level_data.dart';
import '../models/tube.dart';
import 'game_engine.dart';

/// Pure Dart BFS solver for Ball Lab puzzle levels.
///
/// Computes the exact shortest move sequence and minimum move count to
/// mathematically verify level solvability and calibrate move limits.
class PuzzleSolver {
  const PuzzleSolver();

  static const GameEngine _engine = GameEngine();

  /// Canonical signature of a board configuration.
  ///
  /// Sorts tubes lexicographically so that identical empty or solved tubes
  /// map to the same state hash, pruning symmetric branches.
  static String _canonicalStateKey(GameState s) {
    final List<String> tubeKeys = s.tubes.map((Tube t) {
      return t.balls.map((BallColor b) => b.id).join(',');
    }).toList()..sort();
    return tubeKeys.join('|');
  }

  /// Calculates the minimum move count required to solve [level].
  ///
  /// Uses Breadth-First Search (BFS) with canonical tube sorting to explore
  /// states layer by layer, guaranteeing the first goal reached is the exact
  /// shortest path.
  ///
  /// Returns the exact shortest path move count, or `null` if unsolvable
  /// within [maxDepth] or [maxVisitedStates].
  int? findShortestMoveCount(
    LevelData level, {
    int maxDepth = 40,
    int maxVisitedStates = 30000,
  }) {
    final GameState start = _engine.createInitialState(level);
    if (start.isCompleted) return 0;

    final Queue<GameState> queue = Queue<GameState>();
    final Set<String> visited = <String>{};

    queue.add(start);
    visited.add(_canonicalStateKey(start));

    while (queue.isNotEmpty) {
      if (visited.length >= maxVisitedStates) {
        return null;
      }

      final GameState current = queue.removeFirst();

      if (current.moveCount >= maxDepth) {
        continue;
      }

      final int tubeCount = current.tubes.length;
      for (int from = 0; from < tubeCount; from++) {
        final Tube source = current.tubes[from];
        if (source.isEmpty || source.isSolved) continue;

        bool emptyTubeTried = false;

        for (int to = 0; to < tubeCount; to++) {
          if (from == to) continue;
          final Tube dest = current.tubes[to];

          // Symmetry pruning: transferring into any empty tube produces isomorphic
          // states. Trying more than one empty tube for the same source is redundant.
          if (dest.isEmpty) {
            if (emptyTubeTried) continue;
            emptyTubeTried = true;
          }

          if (_engine.isValidMove(current, from, to)) {
            final GameState next = _engine.executeMove(current, from, to);
            if (next.isCompleted) {
              return next.moveCount;
            }

            final String key = _canonicalStateKey(next);
            if (!visited.contains(key)) {
              visited.add(key);
              queue.add(next);
            }
          }
        }
      }
    }

    return null;
  }
}
