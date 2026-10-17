/// Pure Dart representation of chemical ball colors.
///
/// Domain models must not depend on `dart:ui`, `Color`, widgets, or `BuildContext`.
enum BallColor {
  crimsonRed('crimson_red'),
  cobaltBlue('cobalt_blue'),
  emeraldGreen('emerald_green'),
  amberYellow('amber_yellow'),
  amethystPurple('amethyst_purple'),
  cyanGlow('cyan_glow'),
  neonOrange('neon_orange');

  const BallColor(this.id);

  /// Stable machine-readable identifier for serialization and testing.
  final String id;

  /// Human-readable label for user-facing hints, logs, and accessibility.
  String get displayName {
    switch (this) {
      case BallColor.crimsonRed:
        return 'Red';
      case BallColor.cobaltBlue:
        return 'Blue';
      case BallColor.emeraldGreen:
        return 'Green';
      case BallColor.amberYellow:
        return 'Yellow';
      case BallColor.amethystPurple:
        return 'Purple';
      case BallColor.cyanGlow:
        return 'Cyan';
      case BallColor.neonOrange:
        return 'Orange';
    }
  }

  /// Resolves a [BallColor] from its stable [id], or `null` if unrecognised.
  static BallColor? fromId(String id) {
    for (final BallColor color in values) {
      if (color.id == id) return color;
    }
    return null;
  }
}
