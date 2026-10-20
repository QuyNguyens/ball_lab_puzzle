import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';

/// Bottom action bar providing quick access to Restart, Undo (with quota), and Hint (with quota or Ad).
class GameActionBar extends StatelessWidget {
  const GameActionBar({
    super.key,
    required this.canUndo,
    required this.onUndo,
    required this.onRestart,
    required this.onHint,
    this.undoCount = 3,
    this.hintCount = 2,
    this.onOutOfUndos,
    this.onOutOfHints,
    this.isAdLoading = false,
  });

  /// Whether an undo step is currently available in the history stack.
  final bool canUndo;

  /// Callback when Undo is tapped and quota is available.
  final VoidCallback onUndo;

  /// Callback when Restart is pressed.
  final VoidCallback onRestart;

  /// Callback when Hint is pressed and quota is available.
  final VoidCallback onHint;

  /// Number of remaining Undos for today.
  final int undoCount;

  /// Number of remaining Hints for today.
  final int hintCount;

  /// Callback when user taps Undo with 0 remaining.
  final VoidCallback? onOutOfUndos;

  /// Callback when user taps Hint with 0 remaining (e.g. to watch rewarded ad).
  final VoidCallback? onOutOfHints;

  /// Whether a rewarded ad is currently loading or opening.
  final bool isAdLoading;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool undoActive = canUndo && undoCount > 0;
    final bool hintActive = hintCount > 0;
    final bool isAdHint = hintCount == 0 && onOutOfHints != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Restart button
          Flexible(
            child: _ActionButton(
              key: const ValueKey<String>('action_restart_button'),
              icon: Icons.refresh_rounded,
              label: l10n.actionRestart,
              onTap: onRestart,
              isEnabled: true,
            ),
          ),
          const SizedBox(width: 8),

          // Undo button with daily quota count
          Flexible(
            child: _ActionButton(
              key: const ValueKey<String>('action_undo_button'),
              icon: Icons.undo_rounded,
              label: l10n.actionUndo(undoCount),
              onTap:
                  undoActive ? onUndo : (undoCount == 0 ? onOutOfUndos : null),
              isEnabled: undoActive,
              isDepleted: undoCount == 0,
            ),
          ),
          const SizedBox(width: 8),

          // Hint button with daily quota count or rewarded ad prompt
          Flexible(
            child: _ActionButton(
              key: const ValueKey<String>('action_hint_button'),
              icon: isAdHint
                  ? Icons.ondemand_video_rounded
                  : Icons.lightbulb_outline_rounded,
              label: isAdHint ? l10n.actionHintAd : l10n.actionHint(hintCount),
              onTap: hintActive ? onHint : (isAdLoading ? null : onOutOfHints),
              isEnabled: hintActive || isAdHint,
              isDepleted: hintCount == 0 && !isAdHint,
              isAd: isAdHint,
              isLoading: isAdLoading,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isEnabled,
    this.isDepleted = false,
    this.isAd = false,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isEnabled;
  final bool isDepleted;
  final bool isAd;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final Color foregroundColor = isAd
        ? const Color(0xFFFCD34D)
        : (isEnabled
            ? Colors.white
            : (isDepleted
                ? const Color(0xFF94A3B8).withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.35)));

    final Color backgroundColor = isAd
        ? const Color(0xFF1E293B)
        : (isEnabled
            ? const Color(0xFF1E293B)
            : const Color(0xFF1E293B).withValues(alpha: 0.4));

    final Color borderColor = isAd
        ? const Color(0xFFF59E0B).withValues(alpha: 0.45)
        : (isEnabled
            ? Colors.white.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.08));

    return Opacity(
      opacity: isEnabled ? 1.0 : (isDepleted ? 0.75 : 0.6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              border: Border.all(color: borderColor),
              boxShadow: isEnabled
                  ? <BoxShadow>[
                      BoxShadow(
                        color: isAd
                            ? const Color(0x33F59E0B)
                            : const Color(0x22000000),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (isLoading)
                  const SizedBox(
                    key: ValueKey<String>('hint_ad_loading_indicator'),
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFCD34D),
                    ),
                  )
                else
                  Icon(
                    icon,
                    size: 18,
                    color: foregroundColor,
                  ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
