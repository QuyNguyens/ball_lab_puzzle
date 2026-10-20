import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/models/ball_color.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/models/level_data.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/models/tube.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/services/level_provider_service.dart';
import 'package:flutter_riverpod_template/features/ball_lab/presentation/controllers/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const BallColor blue = BallColor.cobaltBlue;

  ProviderContainer createContainer({
    List<Override> overrides = const <Override>[],
  }) {
    final ProviderContainer container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    return container;
  }

  group('GameController - Initialization and Level Loading', () {
    test('Initializes with default level 1 and clean selection', () {
      final ProviderContainer container = createContainer();
      final GamePlayState state = container.read(gameControllerProvider);

      expect(state.currentLevel.levelId, equals(1));
      expect(state.gameState.levelId, equals(1));
      expect(state.gameState.moveCount, equals(0));
      expect(state.selectedTubeIndex, isNull);
      expect(state.errorMessage, isNull);
      expect(state.gameState.isCompleted, isFalse);
    });

    test('Loading a valid level updates state and resets selection', () {
      final ProviderContainer container = createContainer();
      final bool success =
          container.read(gameControllerProvider.notifier).loadLevel(2);
      expect(success, isTrue);

      final GamePlayState state = container.read(gameControllerProvider);
      expect(state.currentLevel.levelId, equals(2));
      expect(state.gameState.levelId, equals(2));
      expect(state.gameState.moveCount, equals(0));
      expect(state.selectedTubeIndex, isNull);
      expect(state.errorMessage, isNull);
    });

    test('Loading an unknown level sets error message and preserves board', () {
      final ProviderContainer container = createContainer();
      final bool success =
          container.read(gameControllerProvider.notifier).loadLevel(1000);
      expect(success, isFalse);

      final GamePlayState state = container.read(gameControllerProvider);
      expect(state.currentLevel.levelId, equals(1));
      expect(state.errorMessage, contains('1000'));
      expect(state.selectedTubeIndex, isNull);
    });
  });

  group('GameController - Two-Tap Interaction & Move Execution', () {
    test('Tap 1 selects a valid non-empty, non-completed source tube', () {
      final ProviderContainer container = createContainer();
      container.read(gameControllerProvider.notifier).selectTube(0);
      expect(
        container.read(gameControllerProvider).selectedTubeIndex,
        equals(0),
      );
    });

    test('Tapping an empty tube as source is ignored', () {
      final ProviderContainer container = createContainer();
      // Tube 3 is empty in Level 1
      container.read(gameControllerProvider.notifier).selectTube(3);
      expect(
        container.read(gameControllerProvider).selectedTubeIndex,
        isNull,
      );
    });

    test('Tapping the same selected tube deselects it', () {
      final ProviderContainer container = createContainer();
      container.read(gameControllerProvider.notifier)
        ..selectTube(0)
        ..selectTube(0);
      expect(
        container.read(gameControllerProvider).selectedTubeIndex,
        isNull,
      );
    });

    test('Two taps on valid source and destination executes the transfer', () {
      final ProviderContainer container = createContainer();
      // Level 1: Tube 0 has top Blue. Tube 3 is empty.
      container.read(gameControllerProvider.notifier)
        ..selectTube(0)
        ..selectTube(3);

      final GamePlayState state = container.read(gameControllerProvider);
      expect(state.selectedTubeIndex, isNull);
      expect(state.gameState.moveCount, equals(1));
      expect(state.gameState.tubes[3].balls, equals(<BallColor>[blue]));
      expect(state.gameState.history.length, equals(1));
    });

    test('Tapping an invalid destination with balls switches source selection',
        () {
      final ProviderContainer container = createContainer();
      // Level 1: Tube 0 top is Blue. Tube 1 top is Green.
      // Transfer from 0 to 1 is invalid. Tapping 1 switches source selection to 1.
      container.read(gameControllerProvider.notifier)
        ..selectTube(0)
        ..selectTube(1);
      final GamePlayState state = container.read(gameControllerProvider);
      expect(state.selectedTubeIndex, equals(1));
      expect(state.gameState.moveCount, equals(0));
    });
  });

  group('GameController - Undo, Restart and Win State', () {
    test('Undo reverses the move and clears selection', () {
      final ProviderContainer container = createContainer();
      final GameController controller =
          container.read(gameControllerProvider.notifier)
            ..selectTube(0)
            ..selectTube(3);
      expect(
        container.read(gameControllerProvider).gameState.moveCount,
        equals(1),
      );

      controller
        ..selectTube(1)
        ..undo();
      final GamePlayState state = container.read(gameControllerProvider);
      expect(state.gameState.moveCount, equals(0));
      expect(state.selectedTubeIndex, isNull);
      expect(state.gameState.tubes[3].balls, isEmpty);
    });

    test('Restart resets board to initial configuration and clears selection',
        () {
      final ProviderContainer container = createContainer();
      final GameController controller =
          container.read(gameControllerProvider.notifier)
            ..selectTube(0)
            ..selectTube(3);
      expect(
        container.read(gameControllerProvider).gameState.moveCount,
        equals(1),
      );

      controller
        ..selectTube(1)
        ..restart();

      final GamePlayState state = container.read(gameControllerProvider);
      expect(state.gameState.moveCount, equals(0));
      expect(state.selectedTubeIndex, isNull);
      expect(state.gameState.history, isEmpty);
      expect(
        state.gameState.tubes,
        equals(state.currentLevel.initialTubes),
      );
    });

    test('Completed state rejects further taps and moves', () {
      final ProviderContainer container = createContainer(
        overrides: <Override>[
          levelProviderServiceProvider.overrideWithValue(
            const _SingleLevelService(),
          ),
        ],
      );

      // Move red from Tube 2 to Tube 0 (completes Tube 0 and wins!)
      final GameController controller =
          container.read(gameControllerProvider.notifier)
            ..selectTube(2)
            ..selectTube(0);

      final GamePlayState wonState = container.read(gameControllerProvider);
      expect(wonState.gameState.isCompleted, isTrue);
      expect(wonState.selectedTubeIndex, isNull);

      // Tapping tubes on won board is ignored
      controller.selectTube(1);
      expect(
        container.read(gameControllerProvider).selectedTubeIndex,
        isNull,
      );
    });

    test('moveBall directly transfers ball and updates state for drag & drop',
        () {
      final ProviderContainer container = createContainer();
      final bool success =
          container.read(gameControllerProvider.notifier).moveBall(0, 3);
      expect(success, isTrue);

      final GamePlayState state = container.read(gameControllerProvider);
      expect(state.gameState.moveCount, equals(1));
      expect(state.gameState.tubes[3].balls.length, equals(1));
      expect(state.gameState.tubes[3].balls.last, equals(blue));
      expect(state.selectedTubeIndex, isNull);
    });

    test('moveBall rejects invalid moves safely', () {
      final ProviderContainer container = createContainer();
      expect(
        container.read(gameControllerProvider.notifier).moveBall(0, 0),
        isFalse,
      );
      expect(
        container.read(gameControllerProvider.notifier).moveBall(3, 0),
        isFalse,
      );
      expect(
        container.read(gameControllerProvider.notifier).moveBall(-1, 0),
        isFalse,
      );
      expect(
        container.read(gameControllerProvider).gameState.moveCount,
        equals(0),
      );
    });
  });

  group('GameController - Move Limits & Game Over Handling', () {
    test('1. Level initializes with exact maxMoves and movesLeft', () {
      final ProviderContainer container = createContainer();
      final GamePlayState state = container.read(gameControllerProvider);

      expect(state.currentLevel.maxMoves, equals(18));
      expect(state.gameState.maxMoves, equals(18));
      expect(state.gameState.moveCount, equals(0));
      expect(state.gameState.movesLeft, equals(18));
      expect(state.gameState.isOutOfMoves, isFalse);
    });

    test('2. Valid move decrements movesLeft by exactly one', () {
      final ProviderContainer container = createContainer();
      container.read(gameControllerProvider.notifier).moveBall(0, 3);
      final GamePlayState state = container.read(gameControllerProvider);

      expect(state.gameState.moveCount, equals(1));
      expect(state.gameState.movesLeft, equals(17));
      expect(state.gameState.isOutOfMoves, isFalse);
    });

    test('3. Invalid move does not decrement movesLeft', () {
      final ProviderContainer container = createContainer();
      container
          .read(gameControllerProvider.notifier)
          .moveBall(0, 1); // Invalid color mismatch
      final GamePlayState state = container.read(gameControllerProvider);

      expect(state.gameState.moveCount, equals(0));
      expect(state.gameState.movesLeft, equals(18));
    });

    test('4. Undo restores movesLeft correctly', () {
      final ProviderContainer container = createContainer();
      final GameController controller =
          container.read(gameControllerProvider.notifier)..moveBall(0, 3);
      expect(container.read(gameControllerProvider).gameState.movesLeft,
          equals(17));

      controller.undo();
      expect(container.read(gameControllerProvider).gameState.movesLeft,
          equals(18));
      expect(container.read(gameControllerProvider).gameState.moveCount,
          equals(0));
    });

    test(
        '5. Restart restores movesLeft and board configuration to initial state',
        () {
      final ProviderContainer container = createContainer();
      container.read(gameControllerProvider.notifier)
        ..moveBall(0, 3)
        ..restart();

      final GamePlayState state = container.read(gameControllerProvider);
      expect(state.gameState.moveCount, equals(0));
      expect(state.gameState.movesLeft, equals(18));
      expect(state.gameState.tubes[3].isEmpty, isTrue);
    });

    test(
        '6. When moves run out without winning, isOutOfMoves is true and moves are blocked',
        () {
      // Mock level with maxMoves: 1
      final LevelData oneMoveFailLevel = LevelData(
        levelId: 88,
        minMoves: 1,
        maxMoves: 1,
        initialTubes: <Tube>[
          Tube(balls: const <BallColor>[
            BallColor.crimsonRed,
            BallColor.cobaltBlue,
            BallColor.crimsonRed,
            BallColor.cobaltBlue,
          ]),
          Tube(balls: const <BallColor>[
            BallColor.cobaltBlue,
            BallColor.crimsonRed,
            BallColor.cobaltBlue,
            BallColor.crimsonRed,
          ]),
          Tube(balls: const <BallColor>[]),
          Tube(balls: const <BallColor>[]),
        ],
      );

      final _CustomLevelService mockService =
          _CustomLevelService(oneMoveFailLevel);
      final ProviderContainer container = createContainer(
        overrides: <Override>[
          levelProviderServiceProvider.overrideWithValue(mockService),
        ],
      );

      final GameController controller =
          container.read(gameControllerProvider.notifier);
      expect(container.read(gameControllerProvider).gameState.movesLeft,
          equals(1));

      // Execute 1 move (not completing the puzzle)
      final bool move1 = controller.moveBall(0, 2);
      expect(move1, isTrue);

      final GamePlayState stateAfterMove1 =
          container.read(gameControllerProvider);
      expect(stateAfterMove1.gameState.moveCount, equals(1));
      expect(stateAfterMove1.gameState.movesLeft, equals(0));
      expect(stateAfterMove1.gameState.isCompleted, isFalse);
      expect(stateAfterMove1.gameState.isOutOfMoves, isTrue);

      // Attempting any further move must be blocked
      final bool move2 = controller.moveBall(1, 3);
      expect(move2, isFalse);
      expect(container.read(gameControllerProvider).gameState.moveCount,
          equals(1));
    });

    test('7. Winning on the exact last move is counted as victory, NOT defeat',
        () {
      // Mock level with maxMoves: 1, solvable in 1 move
      final LevelData oneMoveWinLevel = LevelData(
        levelId: 77,
        maxMoves: 1,
        initialTubes: <Tube>[
          Tube(balls: const <BallColor>[
            BallColor.crimsonRed,
            BallColor.crimsonRed,
            BallColor.crimsonRed
          ]),
          Tube(balls: const <BallColor>[
            BallColor.cobaltBlue,
            BallColor.cobaltBlue,
            BallColor.cobaltBlue,
            BallColor.cobaltBlue
          ]),
          Tube(balls: const <BallColor>[BallColor.crimsonRed]),
          Tube(balls: const <BallColor>[]),
        ],
      );

      final _CustomLevelService mockService =
          _CustomLevelService(oneMoveWinLevel);
      final ProviderContainer container = createContainer(
        overrides: <Override>[
          levelProviderServiceProvider.overrideWithValue(mockService),
        ],
      );

      final GameController controller =
          container.read(gameControllerProvider.notifier);

      // Final move that completes the puzzle
      final bool winMove = controller.moveBall(2, 0);
      expect(winMove, isTrue);

      final GamePlayState finalState = container.read(gameControllerProvider);
      expect(finalState.gameState.moveCount, equals(1));
      expect(finalState.gameState.movesLeft, equals(0));
      expect(finalState.gameState.isCompleted, isTrue);
      expect(finalState.gameState.isOutOfMoves, isFalse,
          reason: 'Win on last move must not be outOfMoves');
    });

    test(
        '8. Switching levels resets state to the target level fixed configuration and maxMoves',
        () {
      final ProviderContainer container = createContainer();
      final GameController controller =
          container.read(gameControllerProvider.notifier)..moveBall(0, 3);
      expect(container.read(gameControllerProvider).gameState.movesLeft,
          equals(17));

      controller.loadLevel(2);
      final GamePlayState level2State = container.read(gameControllerProvider);

      expect(level2State.currentLevel.levelId, equals(2));
      expect(level2State.gameState.levelId, equals(2));
      expect(level2State.gameState.moveCount, equals(0));
      expect(level2State.gameState.maxMoves, equals(16));
      expect(level2State.gameState.movesLeft, equals(16));
    });
  });
}

class _SingleLevelService extends LevelProviderService {
  const _SingleLevelService();

  static final LevelData _oneMoveLevel = LevelData(
    levelId: 99,
    initialTubes: <Tube>[
      Tube(balls: const <BallColor>[
        BallColor.crimsonRed,
        BallColor.crimsonRed,
        BallColor.crimsonRed
      ]),
      Tube(balls: const <BallColor>[
        BallColor.cobaltBlue,
        BallColor.cobaltBlue,
        BallColor.cobaltBlue,
        BallColor.cobaltBlue
      ]),
      Tube(balls: const <BallColor>[BallColor.crimsonRed]),
      Tube(balls: const <BallColor>[]),
    ],
  );

  @override
  List<LevelData> getLevels() => <LevelData>[_oneMoveLevel];

  @override
  LevelData? getLevel(int id) => _oneMoveLevel;
}

class _CustomLevelService extends LevelProviderService {
  const _CustomLevelService(this.level);

  final LevelData level;

  @override
  List<LevelData> getLevels() => <LevelData>[level];

  @override
  LevelData? getLevel(int id) => level;

  @override
  bool hasLevel(int id) => id == level.levelId;
}
