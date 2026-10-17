import 'package:material_ui/material_ui.dart';

import '../../domain/models/ball_color.dart';
import '../theme/ball_color_style.dart';

/// Renders a single glossy chemical ball with 3D specular highlight and shadow.
class BallWidget extends StatelessWidget {
  const BallWidget({
    super.key,
    required this.color,
    this.size = 44.0,
  });

  /// The domain color of this ball.
  final BallColor color;

  /// The diameter of the ball in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final BallColorStyle style = BallColorStyle.forColor(color);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: style.gradient,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: style.glowColor,
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          // Top-left specular gloss highlight
          Positioned(
            top: size * 0.14,
            left: size * 0.18,
            child: Container(
              width: size * 0.28,
              height: size * 0.18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(size)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.75),
                    Colors.white.withValues(alpha: 0.15),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
