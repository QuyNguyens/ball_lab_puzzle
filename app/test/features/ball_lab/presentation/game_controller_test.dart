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
      final bool success = container
          .read(gameControllerProvider.notifier)
          .loadLevel(2);
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
      final bool success = container
          .read(gameControllerProvider.notifier)
          .loadLevel(999);
      expect(success, isFalse);

      final GamePlayState state = container.read(gameControllerProvider);
      expect(state.currentLevel.levelId, equals(1));
      expect(state.errorMessage, contains('999'));
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

    test('Tapping an invalid destination with balls switches source selection', () {
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

    test('Restart resets board to initial configuration and clears selection', () {
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
  });
}

class _SingleLevelService extends LevelProviderService {
  const _SingleLevelService();

  static final LevelData _oneMoveLevel = LevelData(
    levelId: 99,
    initialTubes: <Tube>[
      Tube(balls: const <BallColor>[BallColor.crimsonRed, BallColor.crimsonRed, BallColor.crimsonRed]),
      Tube(balls: const <BallColor>[BallColor.cobaltBlue, BallColor.cobaltBlue, BallColor.cobaltBlue, BallColor.cobaltBlue]),
      Tube(balls: const <BallColor>[BallColor.crimsonRed]),
      Tube(balls: const <BallColor>[]),
    ],
  );

  @override
  List<LevelData> getLevels() => <LevelData>[_oneMoveLevel];

  @override
  LevelData? getLevel(int id) => _oneMoveLevel;
}
