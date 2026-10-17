import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/game_state.dart';
import '../../domain/models/level_data.dart';
import '../../domain/models/puzzle_move.dart';
import '../../domain/models/tube.dart';
import '../../domain/services/game_engine.dart';
import '../../domain/services/level_provider_service.dart';
import 'audio_controller.dart';

part 'game_controller.g.dart';

/// Presentation state for the Ball Lab gameplay board.
@immutable
class GamePlayState {
  const GamePlayState({
    required this.gameState,
    required this.currentLevel,
    this.selectedTubeIndex,
    this.errorMessage,
  });

  /// Current game board state.
  final GameState gameState;

  /// Level definition currently in play (retained for restart).
  final LevelData currentLevel;

  /// Index of the currently selected source tube, or `null` if none.
  final int? selectedTubeIndex;

  /// Optional error message from a failed operation (e.g. unknown level ID).
  final String? errorMessage;

  GamePlayState copyWith({
    GameState? gameState,
    LevelData? currentLevel,
    int? selectedTubeIndex,
    bool clearSelection = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GamePlayState(
      gameState: gameState ?? this.gameState,
      currentLevel: currentLevel ?? this.currentLevel,
      selectedTubeIndex:
          clearSelection ? null : (selectedTubeIndex ?? this.selectedTubeIndex),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GamePlayState &&
        other.gameState == gameState &&
        other.currentLevel == currentLevel &&
        other.selectedTubeIndex == selectedTubeIndex &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(
      gameState,
      currentLevel,
      selectedTubeIndex,
      errorMessage,
    );
  }

  @override
  String toString() =>
      'GamePlayState(level: ${currentLevel.levelId}, selected: $selectedTubeIndex, won: ${gameState.isCompleted})';
}

/// Provider for the pure Dart [GameEngine].
@riverpod
GameEngine gameEngine(Ref ref) => const GameEngine();

/// Provider for the [LevelProviderService].
@riverpod
LevelProviderService levelProviderService(Ref ref) =>
    const LevelProviderService();

/// Gameplay controller managing the active Ball Lab puzzle board.
///
/// Implements the two-tap interaction model:
/// 1. Tapping a valid source selects it.
/// 2. Tapping the same source deselects it.
/// 3. Tapping a valid destination executes the ball transfer.
/// 4. Tapping another valid source switches the selection.
/// 5. Tapping an invalid destination retains the source selection for retry.
@riverpod
class GameController extends _$GameController {
  @override
  GamePlayState build() {
    final LevelProviderService levelService = ref.watch(
      levelProviderServiceProvider,
    );
    final GameEngine engine = ref.watch(gameEngineProvider);
    final LevelData level =
        levelService.getLevel(1) ?? levelService.getLevels().first;

    return GamePlayState(
      gameState: engine.createInitialState(level),
      currentLevel: level,
    );
  }

  /// Loads a level by its [levelId]. Returns `true` if loaded, `false` if not found.
  bool loadLevel(int levelId) {
    final LevelProviderService levelService = ref.read(
      levelProviderServiceProvider,
    );
    final LevelData? level = levelService.getLevel(levelId);
    if (level == null) {
      state = state.copyWith(
        errorMessage: 'Level $levelId not found.',
        clearSelection: true,
      );
      return false;
    }

    final GameEngine engine = ref.read(gameEngineProvider);
    state = GamePlayState(
      gameState: engine.createInitialState(level),
      currentLevel: level,
    );
    return true;
  }

  /// Handles user interaction when tapping the tube at [index].
  void selectTube(int index) {
    // If the game is won or out of moves, ignore further input.
    if (state.gameState.isCompleted || state.gameState.isOutOfMoves) {
      return;
    }

    final int tubeCount = state.gameState.tubes.length;
    if (index < 0 || index >= tubeCount) {
      return;
    }

    final int? selected = state.selectedTubeIndex;

    // Tap 1: No tube currently selected.
    if (selected == null) {
      final Tube candidate = state.gameState.tubes[index];
      // A tube cannot be a source if it is empty or already solved.
      if (candidate.isEmpty || candidate.isSolved) {
        return;
      }
      state = state.copyWith(selectedTubeIndex: index, clearError: true);
      return;
    }

    // Tap 2: A tube is already selected.
    // Case A: Tapping the same tube deselects it.
    if (selected == index) {
      state = state.copyWith(clearSelection: true, clearError: true);
      return;
    }

    // Case B: Tapping a different tube.
    final GameEngine engine = ref.read(gameEngineProvider);
    final bool canMove = engine.isValidMove(state.gameState, selected, index);

    if (canMove) {
      // Execute the valid transfer and reset selection.
      final GameState newState = engine.executeMove(
        state.gameState,
        selected,
        index,
      );
      state = state.copyWith(
        gameState: newState,
        clearSelection: true,
        clearError: true,
      );
      ref.read(gameAudioServiceProvider).playBallMove();
    } else {
      // Transfer is invalid. Check if the tapped tube is another valid source.
      final Tube candidate = state.gameState.tubes[index];
      if (!candidate.isEmpty && !candidate.isSolved) {
        // Switch selection to the new source.
        state = state.copyWith(selectedTubeIndex: index, clearError: true);
      }
      // Otherwise: preserve current selection for retry.
    }
  }

  /// Restores a previously saved active game session.
  ///
  /// Synchronizes maxMoves with the authoritative level definition to prevent
  /// legacy inflated budgets from persisting across sessions.
  bool restoreSession(int levelId, List<Tube> tubes, int moveCount, int maxMoves) {
    final LevelProviderService levelService = ref.read(
      levelProviderServiceProvider,
    );
    final LevelData? level = levelService.getLevel(levelId);
    if (level == null) {
      return false;
    }

    final int effectiveMaxMoves = math.max(level.maxMoves, moveCount);

    state = GamePlayState(
      gameState: GameState(
        levelId: levelId,
        tubes: tubes,
        history: const <PuzzleMove>[],
        moveCount: moveCount,
        isCompleted: false,
        maxMoves: effectiveMaxMoves,
      ),
      currentLevel: level,
    );
    return true;
  }

  /// Undoes the previous move.
  /// Returns `true` if a move was successfully undone, `false` if history was empty
  /// or game is already completed/lost.
  bool undo() {
    if (state.gameState.isCompleted ||
        state.gameState.isOutOfMoves ||
        state.gameState.history.isEmpty) {
      return false;
    }
    final GameEngine engine = ref.read(gameEngineProvider);
    final GameState newState = engine.undoLastMove(state.gameState);
    state = state.copyWith(
      gameState: newState,
      clearSelection: true,
      clearError: true,
    );
    return true;
  }

  /// Restarts the current level from its initial configuration.
  void restart() {
    final GameEngine engine = ref.read(gameEngineProvider);
    final GameState newState = engine.createInitialState(state.currentLevel);
    state = state.copyWith(
      gameState: newState,
      clearSelection: true,
      clearError: true,
    );
  }

  /// Directly executes a ball transfer from [fromIndex] to [toIndex].
  ///
  /// Returns `true` if the move was valid and executed, `false` otherwise.
  /// Designed for drag-and-drop interactions where both source and destination
  /// are determined upon drop.
  bool moveBall(int fromIndex, int toIndex) {
    if (state.gameState.isCompleted || state.gameState.isOutOfMoves) {
      return false;
    }

    final int tubeCount = state.gameState.tubes.length;
    if (fromIndex < 0 ||
        fromIndex >= tubeCount ||
        toIndex < 0 ||
        toIndex >= tubeCount ||
        fromIndex == toIndex) {
      return false;
    }

    final GameEngine engine = ref.read(gameEngineProvider);
    if (!engine.isValidMove(state.gameState, fromIndex, toIndex)) {
      return false;
    }

    final GameState newState = engine.executeMove(
      state.gameState,
      fromIndex,
      toIndex,
    );
    state = state.copyWith(
      gameState: newState,
      clearSelection: true,
      clearError: true,
    );
    ref.read(gameAudioServiceProvider).playBallMove();
    return true;
  }

  /// Clears any active tube selection.
  void clearSelection() {
    state = state.copyWith(clearSelection: true);
  }
}
