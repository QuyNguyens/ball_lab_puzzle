import 'package:meta/meta.dart';

import 'ball_color.dart';

/// Represents a single ball transfer between two tubes.
@immutable
class PuzzleMove {
  const PuzzleMove({
    required this.fromIndex,
    required this.toIndex,
    required this.movedColor,
  })  : assert(fromIndex >= 0, 'fromIndex must be non-negative'),
        assert(toIndex >= 0, 'toIndex must be non-negative'),
        assert(fromIndex != toIndex, 'fromIndex and toIndex must differ');

  /// Source tube index.
  final int fromIndex;

  /// Destination tube index.
  final int toIndex;

  /// Color of the ball transferred during this move.
  final BallColor movedColor;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PuzzleMove &&
        other.fromIndex == fromIndex &&
        other.toIndex == toIndex &&
        other.movedColor == movedColor;
  }

  @override
  int get hashCode => Object.hash(fromIndex, toIndex, movedColor);

  @override
  String toString() =>
      'PuzzleMove(from: $fromIndex, to: $toIndex, color: ${movedColor.name})';
}
