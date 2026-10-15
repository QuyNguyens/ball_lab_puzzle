import 'package:meta/meta.dart';

import 'puzzle_move.dart';
import 'tube.dart';

/// Immutable gameplay snapshot of a Ball Lab puzzle.
@immutable
class GameState {
  GameState({
    required this.levelId,
    required List<Tube> tubes,
    required List<PuzzleMove> history,
    required this.moveCount,
    required this.isCompleted,
  }) : tubes = List<Tube>.unmodifiable(tubes),
       history = List<PuzzleMove>.unmodifiable(history) {
    if (levelId <= 0) {
      throw ArgumentError.value(
        levelId,
        'levelId',
        'levelId must be greater than zero.',
      );
    }
    if (moveCount < 0) {
      throw ArgumentError.value(
        moveCount,
        'moveCount',
        'moveCount cannot be negative.',
      );
    }
  }

  /// Identifier of the currently active level.
  final int levelId;

  /// Ordered list of tubes on the laboratory workbench.
  final List<Tube> tubes;

  /// Ordered list of past moves executed in this game session.
  final List<PuzzleMove> history;

  /// Total number of moves executed so far.
  final int moveCount;

  /// Whether the puzzle has been successfully solved.
  final bool isCompleted;

  GameState copyWith({
    int? levelId,
    List<Tube>? tubes,
    List<PuzzleMove>? history,
    int? moveCount,
    bool? isCompleted,
  }) {
    return GameState(
      levelId: levelId ?? this.levelId,
      tubes: tubes ?? this.tubes,
      history: history ?? this.history,
      moveCount: moveCount ?? this.moveCount,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GameState) return false;
    if (levelId != other.levelId ||
        moveCount != other.moveCount ||
        isCompleted != other.isCompleted ||
        tubes.length != other.tubes.length ||
        history.length != other.history.length) {
      return false;
    }
    for (int i = 0; i < tubes.length; i++) {
      if (tubes[i] != other.tubes[i]) return false;
    }
    for (int i = 0; i < history.length; i++) {
      if (history[i] != other.history[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      levelId,
      moveCount,
      isCompleted,
      Object.hashAll(tubes),
      Object.hashAll(history),
    );
  }

  @override
  String toString() =>
      'GameState(level: $levelId, moves: $moveCount, won: $isCompleted, tubes: ${tubes.length})';
}
