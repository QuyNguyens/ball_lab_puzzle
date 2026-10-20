import 'package:meta/meta.dart';

import 'ball_color.dart';
import 'tube.dart';

/// Snapshot of an ongoing level attempt, allowing recovery if the app closes mid-game.
@immutable
class ActiveGameSession {
  const ActiveGameSession({
    required this.levelId,
    required this.tubes,
    required this.moveCount,
    required this.maxMoves,
  });

  /// Deserializes an [ActiveGameSession] from JSON.
  factory ActiveGameSession.fromJson(Map<String, dynamic> json) {
    final int id = (json['levelId'] as int?) ?? 1;
    final int moves = (json['moveCount'] as int?) ?? 0;
    final int max = (json['maxMoves'] as int?) ?? 20;

    final List<dynamic>? rawTubes = json['tubes'] as List<dynamic>?;
    final List<Tube> tubesList = <Tube>[];
    if (rawTubes != null) {
      for (final dynamic raw in rawTubes) {
        if (raw is List) {
          final List<BallColor> balls = <BallColor>[];
          for (final dynamic ballName in raw) {
            for (final BallColor color in BallColor.values) {
              if (color.name == ballName) {
                balls.add(color);
                break;
              }
            }
          }
          tubesList.add(Tube(balls: balls));
        }
      }
    }

    return ActiveGameSession(
      levelId: id,
      tubes: tubesList,
      moveCount: moves,
      maxMoves: max,
    );
  }

  final int levelId;
  final List<Tube> tubes;
  final int moveCount;
  final int maxMoves;

  /// Whether the session has exhausted its allowed moves.
  bool get isFinished => moveCount >= maxMoves;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'levelId': levelId,
      'moveCount': moveCount,
      'maxMoves': maxMoves,
      'tubes': tubes
          .map((Tube t) => t.balls.map((BallColor b) => b.name).toList())
          .toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActiveGameSession &&
        other.levelId == levelId &&
        other.moveCount == moveCount &&
        other.maxMoves == maxMoves;
  }

  @override
  int get hashCode => Object.hash(levelId, moveCount, maxMoves);
}
