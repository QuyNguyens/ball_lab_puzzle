import 'package:material_ui/material_ui.dart';

import '../../domain/models/ball_color.dart';
import '../../domain/models/tube.dart';
import 'ball_widget.dart';

/// Renders a transparent laboratory test tube with rounded bottom, glass reflections,
/// and stacked chemical balls.
class TestTubeWidget extends StatelessWidget {
  const TestTubeWidget({
    super.key,
    required this.tube,
    required this.index,
    required this.isSelected,
    required this.onTap,
    this.ballSize = 44.0,
    this.isHoveredTarget = false,
    this.isInvalidHover = false,
    this.hideTopBall = false,
    this.isHintSource = false,
    this.isHintTarget = false,
    this.hintBobOffset = 0.0,
    this.previewBallColor,
    this.previewBallOpacity = 0.50,
  });

  /// The domain tube model to display.
  final Tube tube;

  /// Index of this tube on the board.
  final int index;

  /// Whether this tube is currently selected as the move source.
  final bool isSelected;

  /// Callback when the player taps this tube.
  final VoidCallback onTap;

  /// Diameter of each ball inside the tube.
  final double ballSize;

  /// Whether this tube is currently hovered as a valid drop destination.
  final bool isHoveredTarget;

  /// Whether this tube is currently hovered as an invalid drop destination.
  final bool isInvalidHover;

  /// Whether to temporarily hide the top ball during an active drag.
  final bool hideTopBall;

  /// Whether this tube is the source of an active visual hint recommendation.
  final bool isHintSource;

  /// Whether this tube is the destination target of an active visual hint recommendation.
  final bool isHintTarget;

  /// Vertical pixel offset to bob the top ball upwards during an active hint.
  final double hintBobOffset;

  /// Preview / ghost ball color to display in the next available slot at the destination.
  final BallColor? previewBallColor;

  /// Opacity for the preview / ghost ball.
  final double previewBallOpacity;

  @override
  Widget build(BuildContext context) {
    final double tubeWidth = ballSize + 14.0;
    const double spacing = 3;
    const double topClearance = 10;
    const double bottomClearance = 6;
    final double contentHeight =
        (tube.capacity * ballSize) + ((tube.capacity - 1) * spacing);
    final double tubeHeight =
        contentHeight + topClearance + bottomClearance + 8.0;
    final double borderRadius = tubeWidth / 2.0;

    final Color rimColor;
    final List<BoxShadow>? rimShadow;
    final Color bodyColor;
    final Color borderColor;
    final double borderWidth;
    final List<BoxShadow> bodyShadow;
    final Offset slideOffset;

    if (isHoveredTarget) {
      rimColor = const Color(0xFF22D3EE);
      rimShadow = const <BoxShadow>[
        BoxShadow(color: Color(0xCC22D3EE), blurRadius: 12, spreadRadius: 2),
      ];
      bodyColor = const Color(0xFF0E7490).withValues(alpha: 0.32);
      borderColor = const Color(0xFF22D3EE);
      borderWidth = 2.5;
      bodyShadow = const <BoxShadow>[
        BoxShadow(
          color: Color(0x8822D3EE),
          blurRadius: 20,
          spreadRadius: 3,
          offset: Offset(0, 4),
        ),
      ];
      slideOffset = const Offset(0, -0.05);
    } else if (isInvalidHover) {
      rimColor = const Color(0xFFF87171);
      rimShadow = const <BoxShadow>[
        BoxShadow(color: Color(0x99F87171), blurRadius: 10, spreadRadius: 1),
      ];
      bodyColor = const Color(0xFF7F1D1D).withValues(alpha: 0.22);
      borderColor = const Color(0xFFF87171);
      borderWidth = 2.0;
      bodyShadow = const <BoxShadow>[
        BoxShadow(
          color: Color(0x55F87171),
          blurRadius: 14,
          offset: Offset(0, 4),
        ),
      ];
      slideOffset = Offset.zero;
    } else if (isSelected) {
      rimColor = const Color(0xFF22D3EE);
      rimShadow = const <BoxShadow>[
        BoxShadow(color: Color(0x9922D3EE), blurRadius: 8, spreadRadius: 1),
      ];
      bodyColor = const Color(0xFF0E7490).withValues(alpha: 0.22);
      borderColor = const Color(0xFF22D3EE);
      borderWidth = 2.5;
      bodyShadow = const <BoxShadow>[
        BoxShadow(
          color: Color(0x6622D3EE),
          blurRadius: 16,
          spreadRadius: 2,
          offset: Offset(0, 4),
        ),
      ];
      slideOffset = const Offset(0, -0.10);
    } else if (isHintSource) {
      // Warm amber halo for hint source tube
      rimColor = const Color(0xFFFBBF24);
      rimShadow = const <BoxShadow>[
        BoxShadow(color: Color(0xAAFBBF24), blurRadius: 10, spreadRadius: 1),
      ];
      bodyColor = const Color(0xFFD97706).withValues(alpha: 0.18);
      borderColor = const Color(0xFFFBBF24);
      borderWidth = 2.0;
      bodyShadow = const <BoxShadow>[
        BoxShadow(
          color: Color(0x66FBBF24),
          blurRadius: 14,
          spreadRadius: 1,
          offset: Offset(0, 3),
        ),
      ];
      slideOffset = const Offset(0, -0.04);
    } else if (isHintTarget) {
      // Cool cyan neon glow for hint target tube
      rimColor = const Color(0xFF22D3EE);
      rimShadow = const <BoxShadow>[
        BoxShadow(color: Color(0xCC22D3EE), blurRadius: 12, spreadRadius: 2),
      ];
      bodyColor = const Color(0xFF0E7490).withValues(alpha: 0.20);
      borderColor = const Color(0xFF22D3EE);
      borderWidth = 2.0;
      bodyShadow = const <BoxShadow>[
        BoxShadow(
          color: Color(0x6622D3EE),
          blurRadius: 16,
          spreadRadius: 2,
          offset: Offset(0, 3),
        ),
      ];
      slideOffset = Offset.zero;
    } else {
      rimColor = Colors.white.withValues(alpha: 0.45);
      rimShadow = null;
      bodyColor = Colors.white.withValues(alpha: 0.08);
      borderColor = Colors.white.withValues(alpha: 0.35);
      borderWidth = 1.5;
      bodyShadow = <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.30),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
      slideOffset = Offset.zero;
    }

    return Semantics(
      button: true,
      label:
          'Test tube ${index + 1}, contains ${tube.balls.length} balls, capacity ${tube.capacity}',
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedSlide(
          offset: slideOffset,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Top lip / rim of the test tube
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: tubeWidth + 8.0,
                height: 6,
                decoration: BoxDecoration(
                  color: rimColor,
                  borderRadius: const BorderRadius.all(Radius.circular(3)),
                  boxShadow: rimShadow,
                ),
              ),

              // Glass tube body
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: tubeWidth,
                height: tubeHeight,
                padding: const EdgeInsets.only(
                  top: topClearance,
                  bottom: bottomClearance,
                  left: 2,
                  right: 2,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(borderRadius),
                    top: const Radius.circular(3),
                  ),
                  color: bodyColor,
                  border: Border.all(
                    color: borderColor,
                    width: borderWidth,
                  ),
                  boxShadow: bodyShadow,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: <Widget>[
                    // Left specular vertical glass reflection highlight
                    Positioned(
                      top: 2,
                      bottom: borderRadius + 2.0,
                      left: 3,
                      child: Container(
                        width: 2.5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.30),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(2)),
                        ),
                      ),
                    ),

                    // Stack of balls ordered from bottom (index 0) to top
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          // Ghost preview ball for hint destination tube
                          if (previewBallColor != null)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: tube.balls.isNotEmpty ? spacing : 0.0,
                              ),
                              child: Opacity(
                                opacity: previewBallOpacity.clamp(0.0, 1.0),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: Colors.white
                                            .withValues(alpha: 0.50),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: BallWidget(
                                    color: previewBallColor!,
                                    size: ballSize,
                                  ),
                                ),
                              ),
                            ),
                          for (int i = tube.balls.length - 1; i >= 0; i--)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: i > 0 ? spacing : 0.0,
                              ),
                              child: Opacity(
                                opacity:
                                    (i == tube.balls.length - 1 && hideTopBall)
                                        ? 0.0
                                        : 1.0,
                                child: (i == tube.balls.length - 1 &&
                                        isHintSource &&
                                        hintBobOffset > 0)
                                    ? Transform.translate(
                                        offset: Offset(0, -hintBobOffset),
                                        child: BallWidget(
                                          color: tube.balls[i],
                                          size: ballSize,
                                        ),
                                      )
                                    : BallWidget(
                                        color: tube.balls[i],
                                        size: ballSize,
                                      ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
