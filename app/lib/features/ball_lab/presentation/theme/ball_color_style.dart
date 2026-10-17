import 'package:material_ui/material_ui.dart';

import '../../domain/models/ball_color.dart';

/// Visual style configuration for a single [BallColor].
class BallColorStyle {
  const BallColorStyle({
    required this.primaryColor,
    required this.highlightColor,
    required this.shadowColor,
    required this.glowColor,
  });

  /// Resolves the visual style for a given [BallColor].
  factory BallColorStyle.forColor(BallColor color) {
    switch (color) {
      case BallColor.crimsonRed:
        return const BallColorStyle(
          primaryColor: Color(0xFFE11D48),
          highlightColor: Color(0xFFFF6B8B),
          shadowColor: Color(0xFF880E28),
          glowColor: Color(0x66E11D48),
        );
      case BallColor.cobaltBlue:
        return const BallColorStyle(
          primaryColor: Color(0xFF2563EB),
          highlightColor: Color(0xFF70A1FF),
          shadowColor: Color(0xFF133887),
          glowColor: Color(0x662563EB),
        );
      case BallColor.emeraldGreen:
        return const BallColorStyle(
          primaryColor: Color(0xFF10B981),
          highlightColor: Color(0xFF5EEAD4),
          shadowColor: Color(0xFF065F46),
          glowColor: Color(0x6610B981),
        );
      case BallColor.amberYellow:
        return const BallColorStyle(
          primaryColor: Color(0xFFF59E0B),
          highlightColor: Color(0xFFFDE68A),
          shadowColor: Color(0xFF92400E),
          glowColor: Color(0x66F59E0B),
        );
      case BallColor.amethystPurple:
        return const BallColorStyle(
          primaryColor: Color(0xFF8B5CF6),
          highlightColor: Color(0xFFC4B5FD),
          shadowColor: Color(0xFF4C1D95),
          glowColor: Color(0x668B5CF6),
        );
      case BallColor.cyanGlow:
        return const BallColorStyle(
          primaryColor: Color(0xFF06B6D4),
          highlightColor: Color(0xFF67E8F9),
          shadowColor: Color(0xFF0E7490),
          glowColor: Color(0x6606B6D4),
        );
      case BallColor.neonOrange:
        return const BallColorStyle(
          primaryColor: Color(0xFFF97316),
          highlightColor: Color(0xFFFDBA74),
          shadowColor: Color(0xFF9A3412),
          glowColor: Color(0x66F97316),
        );
    }
  }

  /// Base body color of the sphere.
  final Color primaryColor;

  /// Specular highlight color (top-left reflection).
  final Color highlightColor;

  /// Shadow color (bottom-right ambient occlusion).
  final Color shadowColor;

  /// Soft accent glow color.
  final Color glowColor;

  /// Radial gradient that gives the sphere a glossy 3D appearance.
  RadialGradient get gradient {
    return RadialGradient(
      center: const Alignment(-0.35, -0.35),
      radius: 0.85,
      colors: <Color>[
        highlightColor,
        primaryColor,
        shadowColor,
      ],
      stops: const <double>[0, 0.55, 1],
    );
  }
}
