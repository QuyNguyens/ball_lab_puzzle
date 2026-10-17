import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';

/// Defeat dialog presented when the player runs out of moves.
class LevelFailedDialog extends StatelessWidget {
  const LevelFailedDialog({
    super.key,
    required this.levelId,
    required this.moveCount,
    required this.maxMoves,
    required this.onPlayAgain,
    this.canUndo = false,
    this.onUndo,
    this.onExit,
  });

  /// The level number failed.
  final int levelId;

  /// Total moves taken by the player.
  final int moveCount;

  /// Maximum moves allowed for this level.
  final int maxMoves;

  /// Whether the player can undo their last move.
  final bool canUndo;

  /// Callback when "Play Again" is tapped.
  final VoidCallback onPlayAgain;

  /// Callback when "Undo" is tapped.
  final VoidCallback? onUndo;

  /// Callback when "Exit" is tapped.
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: const BorderRadius.all(Radius.circular(28)),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.6),
            width: 2,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x66EF4444),
              blurRadius: 32,
              spreadRadius: 4,
            ),
            BoxShadow(
              color: Colors.black87,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Glowing crimson hourglass / alert icon
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[Color(0xFFF87171), Color(0xFFDC2626)],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color(0x66F87171),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.hourglass_disabled_rounded,
                size: 42,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            // Defeat Title
            Text(
              l10n.defeatTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFF87171),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              l10n.levelIncomplete(levelId),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              l10n.defeatMessage(maxMoves),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            // Move statistics card
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Text(
                        l10n.movesUsedLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$moveCount',
                        key: const ValueKey<String>('defeat_move_count'),
                        style: const TextStyle(
                          color: Color(0xFFF87171),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  Column(
                    children: <Widget>[
                      Text(
                        l10n.maxLimitLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$maxMoves',
                        key: const ValueKey<String>('defeat_max_moves'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: <Widget>[
                // Undo button if available
                if (canUndo && onUndo != null) ...<Widget>[
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey<String>('defeat_undo_button'),
                      onPressed: onUndo,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                      ),
                      child: Text(
                        l10n.actionUndoSimple,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Play Again / Retry button
                Expanded(
                  child: FilledButton(
                    key: const ValueKey<String>('defeat_play_again_button'),
                    onPressed: onPlayAgain,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ),
                    child: Text(
                      l10n.buttonPlayAgain,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
