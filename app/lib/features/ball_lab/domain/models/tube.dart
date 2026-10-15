import 'package:meta/meta.dart';

import 'ball_color.dart';

/// Immutable laboratory tube containing chemical balls.
///
/// Order conventions:
/// - The first element in [balls] is the bottommost ball.
/// - The final element in [balls] is the topmost ball.
@immutable
class Tube {
  Tube({required List<BallColor> balls, this.capacity = 4})
    : balls = List<BallColor>.unmodifiable(balls) {
    if (capacity <= 0) {
      throw ArgumentError.value(
        capacity,
        'capacity',
        'Tube capacity must be greater than zero.',
      );
    }
    if (balls.length > capacity) {
      throw ArgumentError(
        'Balls count (${balls.length}) exceeds tube capacity ($capacity).',
      );
    }
  }

  /// Ordered collection of balls in this tube, from bottom to top.
  final List<BallColor> balls;

  /// Maximum number of balls this tube can accommodate.
  final int capacity;

  /// Whether the tube contains no balls.
  bool get isEmpty => balls.isEmpty;

  /// Whether the tube has reached its maximum ball capacity.
  bool get isFull => balls.length == capacity;

  /// The topmost ball in the tube, or `null` if the tube is empty.
  BallColor? get topBall => balls.isEmpty ? null : balls.last;

  /// A tube is complete if it is empty, or it contains exactly [capacity]
  /// balls of the same color. Partially filled tubes are never complete.
  bool get isComplete {
    if (balls.isEmpty) return true;
    if (balls.length != capacity) return false;
    final BallColor firstColor = balls.first;
    for (int i = 1; i < balls.length; i++) {
      if (balls[i] != firstColor) return false;
    }
    return true;
  }

  /// A tube is solved if it is full and contains only balls of the same color.
  bool get isSolved => isFull && isComplete;

  Tube copyWith({List<BallColor>? balls, int? capacity}) {
    return Tube(
      balls: balls ?? this.balls,
      capacity: capacity ?? this.capacity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Tube) return false;
    if (capacity != other.capacity || balls.length != other.balls.length) {
      return false;
    }
    for (int i = 0; i < balls.length; i++) {
      if (balls[i] != other.balls[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(capacity, Object.hashAll(balls));
  }

  @override
  String toString() => 'Tube(capacity: $capacity, balls: $balls)';
}
