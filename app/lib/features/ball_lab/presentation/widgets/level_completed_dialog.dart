import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';

/// Victory dialog presented when the player successfully sorts all balls.
/// Features animated star ratings, milestone badges, and navigation options.
class LevelCompletedDialog extends StatefulWidget {
  const LevelCompletedDialog({
    super.key,
    required this.levelId,
    required this.moveCount,
    this.parMoves,
    this.stars = 3,
    this.threeStarMoves,
    this.twoStarMoves,
    this.isMilestone = false,
    this.isNewBest = false,
    required this.hasNextLevel,
    required this.onPlayAgain,
    required this.onNextLevel,
    this.onLevelMap,
  });

  /// The level number completed.
  final int levelId;

  /// Total moves taken by the player.
  final int moveCount;

  /// Optional par move target for 3 stars.
  final int? parMoves;

  /// Number of stars earned (1 to 3).
  final int stars;

  /// Move limit for 3 stars.
  final int? threeStarMoves;

  /// Move limit for 2 stars.
  final int? twoStarMoves;

  /// Whether this level is a special milestone / boss challenge.
  final bool isMilestone;

  /// Whether this run improved upon the player's previous record.
  final bool isNewBest;

  /// Whether a subsequent curated level exists.
  final bool hasNextLevel;

  /// Callback when "Play Again" is tapped.
  final VoidCallback onPlayAgain;

  /// Callback when "Next Level" is tapped.
  final VoidCallback onNextLevel;

  /// Callback when returning to the Level Map.
  final VoidCallback? onLevelMap;

  @override
  State<LevelCompletedDialog> createState() => _LevelCompletedDialogState();
}

class _LevelCompletedDialogState extends State<LevelCompletedDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getStarFeedback(AppLocalizations l10n) {
    switch (widget.stars.clamp(1, 3)) {
      case 3:
        return l10n.victoryPerfect;
      case 2:
        return l10n.victoryExcellent;
      case 1:
      default:
        return l10n.victoryGood;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool isMilestone = widget.isMilestone;
    final Color accentColor =
        isMilestone ? const Color(0xFFF59E0B) : const Color(0xFF06B6D4);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: const BorderRadius.all(Radius.circular(28)),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.6),
              width: 2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: accentColor.withValues(alpha: 0.35),
                blurRadius: 32,
                spreadRadius: 4,
              ),
              const BoxShadow(
                color: Colors.black87,
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Milestone Celebration Banner
              if (isMilestone) ...<Widget>[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Color(0x66F59E0B),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.emoji_events_rounded,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        l10n.milestoneReached,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Glowing Celebratory Icon (Science Flask or Milestone Trophy)
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isMilestone
                        ? const <Color>[Color(0xFFFDE68A), Color(0xFFD97706)]
                        : const <Color>[Color(0xFF22D3EE), Color(0xFF0891B2)],
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.45),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Icon(
                  isMilestone ? Icons.military_tech_rounded : Icons.science_rounded,
                  size: 42,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // Victory Title
              Text(
                l10n.victoryTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                l10n.levelMastered(widget.levelId),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 16),

              // Animated Star Rating Row (1 to 3 Stars)
              _AnimatedStarsRow(starsEarned: widget.stars),

              const SizedBox(height: 6),

              Text(
                _getStarFeedback(l10n),
                style: const TextStyle(
                  color: Color(0xFFFDE68A),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(height: 16),

              // Move statistics card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            Text(
                              l10n.movesTakenLabel,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.moveCount}',
                              key: const ValueKey<String>('victory_move_count'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (widget.parMoves != null) ...<Widget>[
                          Container(
                            width: 1,
                            height: 32,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          Column(
                            children: <Widget>[
                              Text(
                                l10n.parMovesLabel,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.parMoves}',
                                style: const TextStyle(
                                  color: Color(0xFFFDE68A),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    if (widget.threeStarMoves != null &&
                        widget.twoStarMoves != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: const BoxDecoration(
                          color: Colors.black26,
                          borderRadius:
                              BorderRadius.all(Radius.circular(8)),
                        ),
                        child: Text(
                          l10n.starThresholds(
                            widget.threeStarMoves!,
                            widget.twoStarMoves!,
                          ),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (widget.isNewBest) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  l10n.newBestRecord,
                  style: const TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],

              const SizedBox(height: 22),

              // Action buttons
              Row(
                children: <Widget>[
                  // Play Again
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey<String>('victory_play_again_button'),
                      onPressed: widget.onPlayAgain,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                      ),
                      child: Text(
                        l10n.buttonPlayAgain,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  if (widget.hasNextLevel) ...<Widget>[
                    const SizedBox(width: 10),
                    // Next Level button
                    Expanded(
                      child: FilledButton(
                        key: const ValueKey<String>('victory_next_level_button'),
                        onPressed: widget.onNextLevel,
                        style: FilledButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          ),
                        ),
                        child: Text(
                          l10n.buttonNextLevel,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              if (widget.onLevelMap != null) ...<Widget>[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    key: const ValueKey<String>('victory_map_button'),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: Text(
                      l10n.buttonReturnToMap,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: widget.onLevelMap,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper widget animating the 3 earned stars sequentially.
class _AnimatedStarsRow extends StatelessWidget {
  const _AnimatedStarsRow({required this.starsEarned});

  final int starsEarned;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(3, (int index) {
        final bool isEarned = index < starsEarned;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 300 + (index * 180)),
            curve: Curves.elasticOut,
            builder: (BuildContext context, double value, Widget? child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isEarned
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: isEarned
                          ? const Color(0xFFFBBF24)
                          : Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: isEarned
                        ? const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x66F59E0B),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isEarned ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 28,
                    color: isEarned
                        ? const Color(0xFFFBBF24)
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
