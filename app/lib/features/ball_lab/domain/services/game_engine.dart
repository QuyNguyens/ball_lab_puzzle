import '../models/ball_color.dart';
import '../models/game_state.dart';
import '../models/level_data.dart';
import '../models/puzzle_move.dart';
import '../models/tube.dart';

/// Validation status for a proposed ball transfer.
enum MoveValidationResult {
  valid,
  gameCompleted,
  invalidIndex,
  sameTube,
  sourceEmpty,
  sourceCompleted,
  destinationFull,
  destinationCompleted,
  colorMismatch;

  /// Whether the proposed move is valid and can be executed.
  bool get isValid => this == MoveValidationResult.valid;
}

/// Pure Dart puzzle rules engine for Ball Lab.
///
/// Contains no Flutter, Riverpod, or UI dependencies.
class GameEngine {
  const GameEngine();

  /// Validates a proposed move from [fromIndex] to [toIndex] against the given [state].
  MoveValidationResult validateMove(
    GameState state,
    int fromIndex,
    int toIndex,
  ) {
    if (state.isCompleted) {
      return MoveValidationResult.gameCompleted;
    }

    final int tubeCount = state.tubes.length;
    if (fromIndex < 0 ||
        fromIndex >= tubeCount ||
        toIndex < 0 ||
        toIndex >= tubeCount) {
      return MoveValidationResult.invalidIndex;
    }

    if (fromIndex == toIndex) {
      return MoveValidationResult.sameTube;
    }

    final Tube source = state.tubes[fromIndex];
    if (source.isEmpty) {
      return MoveValidationResult.sourceEmpty;
    }

    if (source.isSolved) {
      return MoveValidationResult.sourceCompleted;
    }

    final Tube destination = state.tubes[toIndex];
    if (destination.isFull) {
      return MoveValidationResult.destinationFull;
    }

    if (destination.isSolved) {
      return MoveValidationResult.destinationCompleted;
    }

    if (!destination.isEmpty && destination.topBall != source.topBall) {
      return MoveValidationResult.colorMismatch;
    }

    return MoveValidationResult.valid;
  }

  /// Convenience helper returning true if the proposed move is valid.
  bool isValidMove(GameState state, int fromIndex, int toIndex) {
    return validateMove(state, fromIndex, toIndex).isValid;
  }

  /// Executes a single ball transfer from [fromIndex] to [toIndex].
  ///
  /// Throws a [StateError] or [ArgumentError] if the move is invalid.
  GameState executeMove(GameState state, int fromIndex, int toIndex) {
    final MoveValidationResult result = validateMove(state, fromIndex, toIndex);
    if (!result.isValid) {
      throw StateError('Cannot execute invalid move: $result');
    }

    final Tube source = state.tubes[fromIndex];
    final Tube destination = state.tubes[toIndex];
    final BallColor ball = source.topBall!;

    final Tube newSource = source.copyWith(
      balls: source.balls.sublist(0, source.balls.length - 1),
    );
    final Tube newDestination = destination.copyWith(
      balls: <BallColor>[...destination.balls, ball],
    );

    final List<Tube> newTubes = List<Tube>.of(state.tubes);
    newTubes[fromIndex] = newSource;
    newTubes[toIndex] = newDestination;

    final PuzzleMove move = PuzzleMove(
      fromIndex: fromIndex,
      toIndex: toIndex,
      movedColor: ball,
    );

    final List<PuzzleMove> newHistory = <PuzzleMove>[...state.history, move];
    final int newMoveCount = state.moveCount + 1;
    final bool isWon = checkWinCondition(newTubes);

    return GameState(
      levelId: state.levelId,
      tubes: newTubes,
      history: newHistory,
      moveCount: newMoveCount,
      isCompleted: isWon,
    );
  }

  /// Undoes the most recent move in [state].
  ///
  /// Returns the unchanged [state] if the state history is empty.
  GameState undoLastMove(GameState state) {
    if (state.history.isEmpty) {
      return state;
    }

    final PuzzleMove lastMove = state.history.last;
    final Tube currentDest = state.tubes[lastMove.toIndex];
    final Tube currentSource = state.tubes[lastMove.fromIndex];

    if (currentDest.isEmpty || currentDest.topBall != lastMove.movedColor) {
      throw StateError(
        'Cannot undo: destination tube does not contain the expected ball.',
      );
    }

    final Tube restoredDest = currentDest.copyWith(
      balls: currentDest.balls.sublist(0, currentDest.balls.length - 1),
    );
    final Tube restoredSource = currentSource.copyWith(
      balls: <BallColor>[...currentSource.balls, lastMove.movedColor],
    );

    final List<Tube> newTubes = List<Tube>.of(state.tubes);
    newTubes[lastMove.toIndex] = restoredDest;
    newTubes[lastMove.fromIndex] = restoredSource;

    final List<PuzzleMove> newHistory = state.history.sublist(
      0,
      state.history.length - 1,
    );
    final int newMoveCount = state.moveCount > 0 ? state.moveCount - 1 : 0;
    final bool isWon = checkWinCondition(newTubes);

    return GameState(
      levelId: state.levelId,
      tubes: newTubes,
      history: newHistory,
      moveCount: newMoveCount,
      isCompleted: isWon,
    );
  }

  /// Evaluates whether the game is won.
  ///
  /// A board is won when every tube is complete (either empty, or filled to capacity
  /// with balls of identical color). At least one non-empty tube must exist.
  bool checkWinCondition(List<Tube> tubes) {
    if (tubes.isEmpty) return false;
    final bool hasBalls = tubes.any((Tube t) => !t.isEmpty);
    if (!hasBalls) return false;
    return tubes.every((Tube t) => t.isComplete);
  }

  /// Creates a fresh [GameState] initialized from the given [level].
  GameState createInitialState(LevelData level) {
    LevelData.validate(level);
    return GameState(
      levelId: level.levelId,
      tubes: level.initialTubes,
      history: const <PuzzleMove>[],
      moveCount: 0,
      isCompleted: checkWinCondition(level.initialTubes),
    );
  }

  /// Validates that a [LevelData] instance conforms to all game invariants.
  void validateLevel(LevelData level) {
    LevelData.validate(level);
  }
}
