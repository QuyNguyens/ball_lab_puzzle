import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../domain/models/ball_color.dart';
import '../../domain/models/puzzle_move.dart';
import '../../domain/models/tube.dart';
import 'ball_widget.dart';
import 'test_tube_widget.dart';

/// Responsive board rendering the laboratory test tubes with smooth Drag & Drop
/// ball mechanics and flight animations.
class TubeBoard extends StatefulWidget {
  const TubeBoard({
    super.key,
    required this.tubes,
    required this.selectedTubeIndex,
    required this.onTubeTapped,
    this.onMoveBall,
    this.canMove,
    this.isCompleted = false,
    this.activeHint,
    this.onHintDismissed,
  });

  /// The list of tubes to render on the workbench.
  final List<Tube> tubes;

  /// Currently selected tube index (for tap selection), or `null`.
  final int? selectedTubeIndex;

  /// Callback when a tube at the given index is tapped.
  final ValueChanged<int> onTubeTapped;

  /// Callback when a drag-and-drop move is completed from source to target tube index.
  final bool Function(int fromIndex, int toIndex)? onMoveBall;

  /// Optional validator checking if moving from source to target tube index is legal.
  final bool Function(int fromIndex, int toIndex)? canMove;

  /// Whether the game level is currently completed.
  final bool isCompleted;

  /// Active hint recommended move, if any.
  final PuzzleMove? activeHint;

  /// Callback when user touches the board or starts an interaction that dismisses the hint.
  final VoidCallback? onHintDismissed;

  @override
  State<TubeBoard> createState() => _TubeBoardState();
}

class _TubeBoardState extends State<TubeBoard> with TickerProviderStateMixin {
  late final AnimationController _flightController;
  late final AnimationController _hintController;
  late final Animation<double> _hintBobAnimation;
  late final Animation<double> _hintPulseAnimation;

  final List<GlobalKey> _tubeKeys = <GlobalKey>[];

  // Drag tracking state
  int? _dragCandidateIndex;
  Offset? _pointerDownPos;
  bool _isDragging = false;
  int? _sourceTubeIndex;
  BallColor? _draggedBall;
  Offset? _currentDragPos;
  int? _hoveredTubeIndex;
  bool _hoveredIsValid = false;

  // Flight animation state
  bool _isFlightAnimating = false;
  int? _flightSourceIndex;
  int? _flightTargetIndex;
  BallColor? _flightBall;
  Offset _flightP0 = Offset.zero;
  Offset _flightP1 = Offset.zero;
  Offset _flightP2 = Offset.zero;
  Offset _flightP3 = Offset.zero;
  bool _isReturningFlight = false;
  double _lastComputedBallSize = 44;

  @override
  void initState() {
    super.initState();
    _syncTubeKeys();
    _flightController = AnimationController(vsync: this);
    _flightController.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        if (!_isReturningFlight &&
            _flightSourceIndex != null &&
            _flightTargetIndex != null) {
          final int from = _flightSourceIndex!;
          final int to = _flightTargetIndex!;
          widget.onMoveBall?.call(from, to);
        }
        setState(() {
          _isFlightAnimating = false;
          _flightSourceIndex = null;
          _flightTargetIndex = null;
          _flightBall = null;
          _sourceTubeIndex = null;
          _draggedBall = null;
        });
      }
    });

    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _hintBobAnimation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(
        parent: _hintController,
        curve: Curves.easeInOutSine,
      ),
    );
    _hintPulseAnimation = Tween<double>(begin: 0.35, end: 0.70).animate(
      CurvedAnimation(
        parent: _hintController,
        curve: Curves.easeInOutSine,
      ),
    );

    if (widget.activeHint != null) {
      _hintController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(TubeBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTubeKeys();
    if (widget.tubes != oldWidget.tubes && _isFlightAnimating) {
      _flightController.stop();
      _isFlightAnimating = false;
      _isDragging = false;
      _sourceTubeIndex = null;
      _flightSourceIndex = null;
      _draggedBall = null;
      _flightBall = null;
    }
    if (widget.activeHint != oldWidget.activeHint) {
      if (widget.activeHint != null) {
        if (!_hintController.isAnimating) {
          _hintController.repeat(reverse: true);
        }
      } else {
        _hintController
          ..stop()
          ..reset();
      }
    }
  }

  @override
  void dispose() {
    _hintController.dispose();
    _flightController.dispose();
    super.dispose();
  }

  void _syncTubeKeys() {
    while (_tubeKeys.length < widget.tubes.length) {
      _tubeKeys.add(GlobalKey());
    }
    while (_tubeKeys.length > widget.tubes.length) {
      _tubeKeys.removeLast();
    }
  }

  Rect? _getTubeRect(int index) {
    if (index < 0 || index >= _tubeKeys.length) return null;
    final RenderBox? box =
        _tubeKeys[index].currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final RenderBox? boardBox = context.findRenderObject() as RenderBox?;
    if (boardBox == null || !boardBox.hasSize) return null;
    final Offset localPos =
        boardBox.globalToLocal(box.localToGlobal(Offset.zero));
    return localPos & box.size;
  }

  Offset? _getBallSlotCenter(int tubeIndex, int slotIndex, double ballSize) {
    final Rect? rect = _getTubeRect(tubeIndex);
    if (rect == null) return null;
    const double bottomClearance = 6;
    const double spacing = 3;
    final double centerY = rect.bottom -
        bottomClearance -
        (slotIndex * (ballSize + spacing)) -
        (ballSize / 2);
    return Offset(rect.center.dx, centerY);
  }

  double? _getTubeLipY(int tubeIndex) {
    final Rect? rect = _getTubeRect(tubeIndex);
    if (rect == null) return null;
    return rect.top;
  }

  int? _findTubeAt(Offset localPos) {
    for (int i = 0; i < widget.tubes.length; i++) {
      final Rect? rect = _getTubeRect(i);
      if (rect != null) {
        final Rect hitRect = rect.inflate(14);
        if (hitRect.contains(localPos)) {
          return i;
        }
      }
    }
    return null;
  }

  Offset _evaluateCubicBezier(
    Offset p0,
    Offset p1,
    Offset p2,
    Offset p3,
    double t,
  ) {
    final double u = 1.0 - t;
    final double tt = t * t;
    final double uu = u * u;
    final double uuu = uu * u;
    final double ttt = tt * t;

    return p0 * uuu + p1 * (3.0 * uu * t) + p2 * (3.0 * u * tt) + p3 * ttt;
  }

  void _onPointerDown(PointerDownEvent event) {
    if (widget.activeHint != null) {
      widget.onHintDismissed?.call();
    }
    if (_isFlightAnimating || widget.isCompleted) return;

    final RenderBox? boardBox = context.findRenderObject() as RenderBox?;
    if (boardBox == null || !boardBox.hasSize) return;
    final Offset localPos = boardBox.globalToLocal(event.position);

    final int? hitIndex = _findTubeAt(localPos);
    if (hitIndex == null) {
      _dragCandidateIndex = null;
      _pointerDownPos = null;
      return;
    }

    final Tube tube = widget.tubes[hitIndex];
    if (tube.isEmpty || tube.isSolved) {
      _dragCandidateIndex = null;
      _pointerDownPos = null;
      return;
    }

    _dragCandidateIndex = hitIndex;
    _pointerDownPos = localPos;
    _isDragging = false;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_isFlightAnimating ||
        _dragCandidateIndex == null ||
        _pointerDownPos == null) {
      return;
    }

    final RenderBox? boardBox = context.findRenderObject() as RenderBox?;
    if (boardBox == null || !boardBox.hasSize) return;
    final Offset localPos = boardBox.globalToLocal(event.position);

    if (!_isDragging) {
      final double distance = (localPos - _pointerDownPos!).distance;
      if (distance >= 6.0) {
        final int sourceIdx = _dragCandidateIndex!;
        final Tube sourceTube = widget.tubes[sourceIdx];
        if (sourceTube.isEmpty || sourceTube.isSolved) {
          _dragCandidateIndex = null;
          _pointerDownPos = null;
          return;
        }
        setState(() {
          _isDragging = true;
          _sourceTubeIndex = sourceIdx;
          _draggedBall = sourceTube.topBall;
          _currentDragPos = localPos;
        });
      }
    }

    if (_isDragging) {
      final Offset targetInspectPos = localPos + const Offset(0, -18);
      final int? hovered =
          _findTubeAt(targetInspectPos) ?? _findTubeAt(localPos);

      int? newHovered;
      bool newHoveredIsValid = false;

      if (hovered != null && hovered != _sourceTubeIndex) {
        newHovered = hovered;
        final bool canMove =
            widget.canMove?.call(_sourceTubeIndex!, hovered) ?? true;
        newHoveredIsValid = canMove;
      }

      setState(() {
        _currentDragPos = localPos;
        _hoveredTubeIndex = newHovered;
        _hoveredIsValid = newHoveredIsValid;
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_isDragging) {
      _dragCandidateIndex = null;
      _pointerDownPos = null;
      return;
    }

    final int sourceIdx = _sourceTubeIndex!;
    final int? targetIdx = _hoveredTubeIndex;
    final bool isValid = targetIdx != null && _hoveredIsValid;

    final RenderBox? boardBox = context.findRenderObject() as RenderBox?;
    final Offset localPos = (boardBox != null && boardBox.hasSize)
        ? boardBox.globalToLocal(event.position)
        : (_currentDragPos ?? Offset.zero);

    final Offset releaseCenter = localPos + const Offset(0, -18);

    if (isValid) {
      _startDropFlight(sourceIdx, targetIdx, releaseCenter);
    } else {
      _startReturnFlight(sourceIdx, releaseCenter);
    }

    setState(() {
      _isDragging = false;
      _dragCandidateIndex = null;
      _pointerDownPos = null;
      _hoveredTubeIndex = null;
      _hoveredIsValid = false;
    });
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_isDragging && _sourceTubeIndex != null) {
      final Offset releaseCenter =
          (_currentDragPos ?? Offset.zero) + const Offset(0, -18);
      _startReturnFlight(_sourceTubeIndex!, releaseCenter);
      setState(() {
        _isDragging = false;
        _dragCandidateIndex = null;
        _pointerDownPos = null;
        _hoveredTubeIndex = null;
        _hoveredIsValid = false;
      });
    } else {
      _dragCandidateIndex = null;
      _pointerDownPos = null;
    }
  }

  void _startDropFlight(int sourceIdx, int targetIdx, Offset releaseCenter) {
    final Tube targetTube = widget.tubes[targetIdx];
    final Offset destSlot = _getBallSlotCenter(
          targetIdx,
          targetTube.balls.length,
          _lastComputedBallSize,
        ) ??
        releaseCenter;
    final double lipY = _getTubeLipY(targetIdx) ?? destSlot.dy;

    _flightP0 = releaseCenter;
    _flightP3 = destSlot;
    _flightP2 = Offset(destSlot.dx, lipY - (_lastComputedBallSize / 2) - 8);
    _flightP1 = Offset(
      releaseCenter.dx + (destSlot.dx - releaseCenter.dx) * 0.4,
      math.min(releaseCenter.dy, _flightP2.dy) - 24,
    );

    _flightSourceIndex = sourceIdx;
    _flightTargetIndex = targetIdx;
    _flightBall = _draggedBall;
    _isReturningFlight = false;
    _isFlightAnimating = true;

    _flightController.duration = const Duration(milliseconds: 240);
    _flightController.forward(from: 0);
  }

  void _startReturnFlight(int sourceIdx, Offset releaseCenter) {
    final Tube sourceTube = widget.tubes[sourceIdx];
    final int topSlot = math.max(0, sourceTube.balls.length - 1);
    final Offset sourceSlot = _getBallSlotCenter(
          sourceIdx,
          topSlot,
          _lastComputedBallSize,
        ) ??
        releaseCenter;
    final double lipY = _getTubeLipY(sourceIdx) ?? sourceSlot.dy;

    _flightP0 = releaseCenter;
    _flightP3 = sourceSlot;
    _flightP2 = Offset(sourceSlot.dx, lipY - (_lastComputedBallSize / 2) - 8);
    _flightP1 = Offset(
      releaseCenter.dx + (sourceSlot.dx - releaseCenter.dx) * 0.4,
      math.min(releaseCenter.dy, _flightP2.dy) - 24,
    );

    _flightSourceIndex = sourceIdx;
    _flightTargetIndex = null;
    _flightBall = _draggedBall;
    _isReturningFlight = true;
    _isFlightAnimating = true;

    _flightController.duration = const Duration(milliseconds: 200);
    _flightController.forward(from: 0);
  }

  Widget _buildTubeItem(int index, double ballSize, double clampedGap) {
    final bool isHintSource = widget.activeHint?.fromIndex == index;
    final bool isHintTarget = widget.activeHint?.toIndex == index;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: clampedGap / 2),
      child: Container(
        key: _tubeKeys[index],
        child: AnimatedBuilder(
          animation: _hintController,
          builder: (BuildContext context, Widget? child) {
            return TestTubeWidget(
              key: ValueKey<String>('tube_$index'),
              tube: widget.tubes[index],
              index: index,
              isSelected: widget.selectedTubeIndex == index && !_isDragging,
              isHoveredTarget:
                  _isDragging && _hoveredTubeIndex == index && _hoveredIsValid,
              isInvalidHover:
                  _isDragging && _hoveredTubeIndex == index && !_hoveredIsValid,
              hideTopBall: (_isDragging && _sourceTubeIndex == index) ||
                  (_isFlightAnimating && _flightSourceIndex == index),
              isHintSource: isHintSource,
              isHintTarget: isHintTarget,
              hintBobOffset: isHintSource ? _hintBobAnimation.value : 0.0,
              previewBallColor:
                  isHintTarget ? widget.activeHint?.movedColor : null,
              previewBallOpacity:
                  isHintTarget ? _hintPulseAnimation.value : 0.50,
              onTap: () {
                if (widget.activeHint != null) {
                  widget.onHintDismissed?.call();
                }
                widget.onTubeTapped(index);
              },
              ballSize: ballSize,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tubes.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableWidth = constraints.maxWidth;
        final double availableHeight = constraints.maxHeight;

        final bool useTwoRows =
            widget.tubes.length > 4 || availableWidth < 520.0;

        final int firstRowCount =
            useTwoRows ? ((widget.tubes.length + 1) ~/ 2) : widget.tubes.length;
        final int secondRowCount =
            useTwoRows ? (widget.tubes.length - firstRowCount) : 0;

        final int maxTubesInRow = math.max(firstRowCount, secondRowCount);

        final double maxAllowedByWidth =
            (availableWidth / (maxTubesInRow + 0.6)) - 16.0;
        final double maxAllowedByHeight =
            useTwoRows ? (availableHeight / 11.5) : (availableHeight / 5.8);

        final double ballSize = math
            .min(
              maxAllowedByWidth,
              maxAllowedByHeight,
            )
            .clamp(28.0, 48.0);

        _lastComputedBallSize = ballSize;

        final double horizontalGap =
            (availableWidth - (maxTubesInRow * (ballSize + 14.0))) /
                (maxTubesInRow + 1);
        final double clampedGap = horizontalGap.clamp(8.0, 24.0);

        Widget tubesLayout;

        if (!useTwoRows) {
          tubesLayout = Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (int i = 0; i < widget.tubes.length; i++)
                    _buildTubeItem(i, ballSize, clampedGap),
                ],
              ),
            ),
          );
        } else {
          final double rowVerticalSpacing =
              math.min(availableHeight * 0.04, 20);

          tubesLayout = Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Top Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (int i = 0; i < firstRowCount; i++)
                        _buildTubeItem(i, ballSize, clampedGap),
                    ],
                  ),

                  SizedBox(height: rowVerticalSpacing),

                  // Bottom Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (int i = firstRowCount; i < widget.tubes.length; i++)
                        _buildTubeItem(i, ballSize, clampedGap),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return Listener(
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: <Widget>[
              tubesLayout,

              // Active Dragged Ball Overlay
              if (_isDragging &&
                  _draggedBall != null &&
                  _currentDragPos != null)
                Positioned(
                  left: _currentDragPos!.dx - (ballSize / 2.0),
                  top: (_currentDragPos!.dy - 18.0) - (ballSize / 2.0),
                  child: IgnorePointer(
                    child: Transform.scale(
                      scale: 1.12,
                      child: BallWidget(
                        color: _draggedBall!,
                        size: ballSize,
                      ),
                    ),
                  ),
                ),

              // Active Flying Ball Animation Overlay
              if (_isFlightAnimating && _flightBall != null)
                AnimatedBuilder(
                  animation: _flightController,
                  builder: (BuildContext context, Widget? child) {
                    final double t = CurvedAnimation(
                      parent: _flightController,
                      curve: Curves.easeOutCubic,
                    ).value;
                    final Offset currentPos = _evaluateCubicBezier(
                      _flightP0,
                      _flightP1,
                      _flightP2,
                      _flightP3,
                      t,
                    );
                    final double scale = 1.12 - (0.12 * t);

                    return Positioned(
                      left: currentPos.dx - (ballSize / 2.0),
                      top: currentPos.dy - (ballSize / 2.0),
                      child: IgnorePointer(
                        child: Transform.scale(
                          scale: scale,
                          child: BallWidget(
                            color: _flightBall!,
                            size: ballSize,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
