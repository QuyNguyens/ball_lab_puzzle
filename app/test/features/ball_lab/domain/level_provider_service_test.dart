import 'package:flutter_riverpod_template/features/ball_lab/domain/models/game_state.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/models/level_data.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/models/tube.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/services/game_engine.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/services/level_provider_service.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/services/puzzle_solver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const LevelProviderService service = LevelProviderService();
  const GameEngine engine = GameEngine();

  group('LevelProviderService - Catalog Structure', () {
    test('Contains at least 5 curated levels', () {
      expect(service.getLevels().length, equals(10));
      expect(service.totalLevels, equals(999));
    });

    test('Retrieves level by ID and returns null for unknown ID', () {
      expect(service.getLevel(1), isNotNull);
      expect(service.getLevel(5), isNotNull);
      expect(service.getLevel(999), isNotNull);
      expect(service.getLevel(1000), isNull);
      expect(service.hasLevel(1), isTrue);
      expect(service.hasLevel(999), isTrue);
      expect(service.hasLevel(1000), isFalse);
    });

    test('All curated levels satisfy domain constraints', () {
      for (final LevelData level in service.getLevels()) {
        expect(level.levelId, greaterThan(0));
        expect(level.initialTubes.length, greaterThanOrEqualTo(5));

        // Tube capacity 4
        for (final Tube tube in level.initialTubes) {
          expect(tube.capacity, equals(4));
        }

        // Two empty tubes
        final int emptyTubes =
            level.initialTubes.where((Tube t) => t.isEmpty).length;
        expect(emptyTubes, equals(2));

        // Initial state is not won
        expect(engine.checkWinCondition(level.initialTubes), isFalse);
      }
    });
  });

  group('LevelProviderService - Solvability Verification', () {
    test('Level 1 can be solved with its exact 12-move solution', () {
      final LevelData level1 = service.getLevel(1)!;
      GameState state = engine.createInitialState(level1);
      expect(state.isCompleted, isFalse);

      // Proven 12-move sequence:
      // T0: [R, B, R, B], T1: [B, G, B, G], T2: [G, R, G, R], T3: [], T4: []
      final List<List<int>> moves = <List<int>>[
        <int>[0, 3], // B to T3
        <int>[2, 4], // R to T4
        <int>[0, 4], // R to T4
        <int>[0, 3], // B to T3
        <int>[0, 4], // R to T4
        <int>[1, 0], // G to T0
        <int>[1, 3], // B to T3
        <int>[1, 0], // G to T0
        <int>[1, 3], // B to T3 (T3 solved with 4 Blues)
        <int>[2, 0], // G to T0
        <int>[2, 4], // R to T4 (T4 solved with 4 Reds)
        <int>[2, 0], // G to T0 (T0 solved with 4 Greens)
      ];

      for (final List<int> move in moves) {
        expect(
          engine.isValidMove(state, move[0], move[1]),
          isTrue,
          reason: 'Move from ${move[0]} to ${move[1]} must be valid',
        );
        state = engine.executeMove(state, move[0], move[1]);
      }

      expect(state.moveCount, equals(12));
      expect(state.isCompleted, isTrue);
    });

    test('Level 2 can be solved with its exact 12-move solution', () {
      final LevelData level2 = service.getLevel(2)!;
      GameState state = engine.createInitialState(level2);
      expect(state.isCompleted, isFalse);

      // Proven 12-move sequence:
      // T0: [R, R, B, B], T1: [B, B, G, G], T2: [G, G, R, R], T3: [], T4: []
      final List<List<int>> moves = <List<int>>[
        <int>[0, 3],
        <int>[0, 3],
        <int>[2, 4],
        <int>[2, 4],
        <int>[0, 4],
        <int>[0, 4],
        <int>[1, 0],
        <int>[1, 0],
        <int>[2, 0],
        <int>[2, 0],
        <int>[1, 3],
        <int>[1, 3],
      ];

      for (final List<int> move in moves) {
        expect(
          engine.isValidMove(state, move[0], move[1]),
          isTrue,
          reason: 'Move from ${move[0]} to ${move[1]} must be valid',
        );
        state = engine.executeMove(state, move[0], move[1]);
      }

      expect(state.moveCount, equals(12));
      expect(state.isCompleted, isTrue);
      expect(state.movesLeft, equals(level2.maxMoves - 12));
      expect(state.isOutOfMoves, isFalse);
    });

    test('All curated levels have verified minMoves and solvable within maxMoves', () {
      const PuzzleSolver solver = PuzzleSolver();
      for (final LevelData level in service.getLevels()) {
        expect(level.minMoves, isNotNull);
        expect(level.maxMoves, greaterThan(level.minMoves!));

        final int? shortestPath = solver.findShortestMoveCount(level);
        expect(shortestPath, isNotNull, reason: 'Level ${level.levelId} must be solvable');
        expect(shortestPath, equals(level.minMoves), reason: 'Level ${level.levelId} shortest path must match minMoves');
        expect(shortestPath, lessThanOrEqualTo(level.maxMoves));
      }
    });
  });
}
