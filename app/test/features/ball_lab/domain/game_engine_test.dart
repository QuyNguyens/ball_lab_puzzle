import 'package:flutter_riverpod_template/features/ball_lab/domain/models/ball_color.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/models/game_state.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/models/level_data.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/models/puzzle_move.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/models/tube.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/services/game_engine.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/services/level_provider_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const GameEngine engine = GameEngine();

  const BallColor red = BallColor.crimsonRed;
  const BallColor blue = BallColor.cobaltBlue;
  const BallColor green = BallColor.emeraldGreen;

  GameState createTestState({
    required List<Tube> tubes,
    int levelId = 1,
    int moveCount = 0,
    List<PuzzleMove> history = const <PuzzleMove>[],
    bool isCompleted = false,
  }) {
    return GameState(
      levelId: levelId,
      tubes: tubes,
      history: history,
      moveCount: moveCount,
      isCompleted: isCompleted,
    );
  }

  group('GameEngine - Move Validation & Execution', () {
    test('1. Move one ball to an empty tube', () {
      final GameState state = createTestState(
        tubes: <Tube>[
          Tube(balls: const <BallColor>[red, blue]),
          Tube(balls: const <BallColor>[]),
        ],
      );

      expect(engine.isValidMove(state, 0, 1), isTrue);

      final GameState newState = engine.executeMove(state, 0, 1);
      expect(newState.tubes[0].balls, equals(<BallColor>[red]));
      expect(newState.tubes[1].balls, equals(<BallColor>[blue]));
    });

    test('2. Move one ball onto a tube with the same top color', () {
      final GameState state = createTestState(
        tubes: <Tube>[
          Tube(balls: const <BallColor>[red, blue]),
          Tube(balls: const <BallColor>[green, blue]),
        ],
      );

      expect(engine.isValidMove(state, 0, 1), isTrue);

      final GameState newState = engine.executeMove(state, 0, 1);
      expect(newState.tubes[0].balls, equals(<BallColor>[red]));
      expect(newState.tubes[1].balls, equals(<BallColor>[green, blue, blue]));
    });

    test('3. Reject a different-color destination', () {
      final GameState state = createTestState(
        tubes: <Tube>[
          Tube(balls: const <BallColor>[red, blue]),
          Tube(balls: const <BallColor>[blue, green]),
        ],
      );

      final MoveValidationResult result = engine.validateMove(state, 0, 1);
      expect(result, equals(MoveValidationResult.colorMismatch));
      expect(engine.isValidMove(state, 0, 1), isFalse);
      expect(() => engine.executeMove(state, 0, 1), throwsStateError);
    });

    test('4. Reject a full destination', () {
      final GameState state = createTestState(
        tubes: <Tube>[
          Tube(balls: const <BallColor>[red, blue]),
          Tube(balls: const <BallColor>[red, green, blue, blue]),
        ],
      );

      final MoveValidationResult result = engine.validateMove(state, 0, 1);
      expect(result, equals(MoveValidationResult.destinationFull));
      expect(engine.isValidMove(state, 0, 1), isFalse);
    });

    test('5. Reject an empty source', () {
      final GameState state = createTestState(
        tubes: <Tube>[
          Tube(balls: const <BallColor>[]),
          Tube(balls: const <BallColor>[red]),
        ],
      );

      final MoveValidationResult result = engine.validateMove(state, 0, 1);
      expect(result, equals(MoveValidationResult.sourceEmpty));
      expect(engine.isValidMove(state, 0, 1), isFalse);
    });

    test('6. Reject moving a tube to itself', () {
      final GameState state = createTestState(
        tubes: <Tube>[
          Tube(balls: const <BallColor>[red, blue]),
        ],
      );

      final MoveValidationResult result = engine.validateMove(state, 0, 0);
      expect(result, equals(MoveValidationResult.sameTube));
      expect(engine.isValidMove(state, 0, 0), isFalse);
    });

    test('7. Reject invalid indices', () {
      final GameState state = createTestState(
        tubes: <Tube>[
          Tube(balls: const <BallColor>[red]),
          Tube(balls: const <BallColor>[]),
        ],
      );

      expect(
        engine.validateMove(state, -1, 1),
        equals(MoveValidationResult.invalidIndex),
      );
      expect(
        engine.validateMove(state, 0, 5),
        equals(MoveValidationResult.invalidIndex),
      );
      expect(engine.isValidMove(state, -1, 1), isFalse);
    });

    test('8. Reject moving from a completed tube', () {
      final GameState state = createTestState(
        tubes: <Tube>[
          Tube(balls: const <BallColor>[red, red, red, red]),
          Tube(balls: const <BallColor>[]),
        ],
      );

      final MoveValidationResult result = engine.validateMove(state, 0, 1);
      expect(result, equals(MoveValidationResult.sourceCompleted));
      expect(engine.isValidMove(state, 0, 1), isFalse);
    });

    test('9. Reject moving into a completed tube', () {
      final GameState state = createTestState(
        tubes: <Tube>[
          Tube(balls: const <BallColor>[red]),
          Tube(balls: const <BallColor>[red, red, red, red]),
        ],
      );

      final MoveValidationResult result = engine.validateMove(state, 0, 1);
      expect(
        result == MoveValidationResult.destinationFull ||
            result == MoveValidationResult.destinationCompleted,
        isTrue,
      );
      expect(engine.isValidMove(state, 0, 1), isFalse);
    });

    test('10. Reject moves after game completion', () {
      final GameState state = createTestState(
        tubes: <Tube>[
          Tube(balls: const <BallColor>[red, red, red, red]),
          Tube(balls: const <BallColor>[]),
        ],
        isCompleted: true,
      );

      final MoveValidationResult result = engine.validateMove(state, 0, 1);
      expect(result, equals(MoveValidationResult.gameCompleted));
      expect(engine.isValidMove(state, 0, 1), isFalse);
    });

    test('11. Increment the move count after a valid move', () {
      final GameState state = createTestState(
        tubes: <Tube>[
          Tube(balls: const <BallColor>[red]),
          Tube(balls: const <BallColor>[]),
        ],
        moveCount: 3,
      );

      final GameState newState = engine.executeMove(state, 0, 1);
      expect(newState.moveCount, equals(4));
    });

    test('12. Append history after a valid move', () {
      final GameState state = createTestState(
        tubes: <Tube>[
          Tube(balls: const <BallColor>[red, blue]),
          Tube(balls: const <BallColor>[]),
        ],
      );

      final GameState newState = engine.executeMove(state, 0, 1);
      expect(newState.history.length, equals(1));
      expect(
        newState.history.first,
        equals(
          const PuzzleMove(fromIndex: 0, toIndex: 1, movedColor: blue),
        ),
      );
    });
  });

  group('GameEngine - Undo Operations', () {
    test('13. Undo restores the exact previous board', () {
      final GameState initial = createTestState(
        tubes: <Tube>[
          Tube(balls: const <BallColor>[red, blue]),
          Tube(balls: const <BallColor>[]),
        ],
      );

      final GameState moved = engine.executeMove(initial, 0, 1);
      final GameState undone = engine.undoLastMove(moved);

      expect(undone.tubes, equals(initial.tubes));
    });

    test('14. Undo decrements the move count', () {
      final GameState initial = createTestState(
        tubes: <Tube>[
          Tube(balls: const <BallColor>[red]),
          Tube(balls: const <BallColor>[]),
        ],
        moveCount: 5,
      );

      final GameState moved = engine.executeMove(initial, 0, 1);
      expect(moved.moveCount, equals(6));

      final GameState undone = engine.undoLastMove(moved);
      expect(undone.moveCount, equals(5));
    });

    test('15. Undo removes the correct history record', () {
      final GameState initial = createTestState(
        tubes: <Tube>[
          Tube(balls: const <BallColor>[red, blue]),
          Tube(balls: const <BallColor>[]),
        ],
      );

      final GameState moved = engine.executeMove(initial, 0, 1);
      expect(moved.history.length, equals(1));

      final GameState undone = engine.undoLastMove(moved);
      expect(undone.history, isEmpty);
    });

    test('16. Undo works after multiple valid moves', () {
      final GameState stateWith2Empty = createTestState(
        tubes: <Tube>[
          Tube(balls: const <BallColor>[red, blue]),
          Tube(balls: const <BallColor>[]),
          Tube(balls: const <BallColor>[]),
        ],
      );

      final GameState step1 = engine.executeMove(stateWith2Empty, 0, 1);
      final GameState step2 = engine.executeMove(step1, 0, 2);

      expect(step2.tubes[0].balls, isEmpty);
      expect(step2.tubes[1].balls, equals(<BallColor>[blue]));
      expect(step2.tubes[2].balls, equals(<BallColor>[red]));
      expect(step2.history.length, equals(2));

      final GameState undone1 = engine.undoLastMove(step2);
      expect(undone1.tubes, equals(step1.tubes));
      expect(undone1.history.length, equals(1));

      final GameState undone2 = engine.undoLastMove(undone1);
      expect(undone2.tubes, equals(stateWith2Empty.tubes));
      expect(undone2.history, isEmpty);
    });

    test('Undo when history is empty is a safe no-op', () {
      final GameState initial = createTestState(
        tubes: <Tube>[
          Tube(balls: const <BallColor>[red]),
          Tube(balls: const <BallColor>[]),
        ],
      );

      final GameState undone = engine.undoLastMove(initial);
      expect(undone, equals(initial));
    });
  });

  group('GameEngine - Win Condition & Level Operations', () {
    test('17. Restart can reconstruct the original level state', () {
      final LevelData level = LevelData(
        levelId: 10,
        initialTubes: <Tube>[
          Tube(balls: const <BallColor>[red, blue, red, blue]),
          Tube(balls: const <BallColor>[blue, red, blue, red]),
          Tube(balls: const <BallColor>[]),
          Tube(balls: const <BallColor>[]),
        ],
      );

      final GameState initial = engine.createInitialState(level);
      final GameState moved = engine.executeMove(initial, 0, 2);
      expect(moved.moveCount, equals(1));

      final GameState restarted = engine.createInitialState(level);
      expect(restarted.moveCount, equals(0));
      expect(restarted.history, isEmpty);
      expect(restarted.tubes, equals(level.initialTubes));
    });

    test('18. Correctly detect a won board', () {
      final List<Tube> wonTubes = <Tube>[
        Tube(balls: const <BallColor>[red, red, red, red]),
        Tube(balls: const <BallColor>[blue, blue, blue, blue]),
        Tube(balls: const <BallColor>[]),
        Tube(balls: const <BallColor>[]),
      ];

      expect(engine.checkWinCondition(wonTubes), isTrue);
    });

    test('19. Reject partially filled monochromatic tubes as a win', () {
      final List<Tube> incompleteTubes = <Tube>[
        Tube(balls: const <BallColor>[red, red]),
        Tube(balls: const <BallColor>[red, red]),
        Tube(balls: const <BallColor>[blue, blue, blue, blue]),
        Tube(balls: const <BallColor>[]),
      ];

      expect(engine.checkWinCondition(incompleteTubes), isFalse);
    });

    test('20. Ensure invalid moves do not alter the original state', () {
      final GameState original = createTestState(
        tubes: <Tube>[
          Tube(balls: const <BallColor>[red, blue]),
          Tube(balls: const <BallColor>[green, red]),
        ],
        moveCount: 2,
      );

      final int originalHashCode = original.hashCode;
      expect(() => engine.executeMove(original, 0, 1), throwsStateError);

      expect(original.hashCode, equals(originalHashCode));
      expect(original.moveCount, equals(2));
      expect(original.tubes[0].balls, equals(<BallColor>[red, blue]));
    });

    test('21. Validate tube capacity and ball-count invariants', () {
      expect(
        () => Tube(balls: const <BallColor>[], capacity: 0),
        throwsArgumentError,
      );
      expect(
        () => Tube(balls: const <BallColor>[red, red, red, red, red]),
        throwsArgumentError,
      );

      expect(
        () => LevelData(
          levelId: -1,
          initialTubes: <Tube>[Tube(balls: const <BallColor>[red])],
        ),
        throwsArgumentError,
      );

      // Inconsistent tube capacity
      expect(
        () => LevelData(
          levelId: 1,
          initialTubes: <Tube>[
            Tube(balls: const <BallColor>[red, red, red, red]),
            Tube(balls: const <BallColor>[blue, blue], capacity: 2),
          ],
        ),
        throwsArgumentError,
      );

      // Unequal ball counts per color
      expect(
        () => LevelData(
          levelId: 1,
          initialTubes: <Tube>[
            Tube(balls: const <BallColor>[red, red, red]),
            Tube(balls: const <BallColor>[]),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('22. Validate every curated level', () {
      const LevelProviderService service = LevelProviderService();
      final List<LevelData> levels = service.getLevels();

      expect(levels.length, greaterThanOrEqualTo(5));
      for (final LevelData level in levels) {
        expect(() => engine.validateLevel(level), returnsNormally);
        expect(level.levelId, greaterThan(0));
        expect(level.initialTubes.length, greaterThanOrEqualTo(5));
      }
    });
  });
}
