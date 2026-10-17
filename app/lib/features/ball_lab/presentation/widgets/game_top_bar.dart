import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';
import '../controllers/audio_controller.dart';

/// Top bar displaying the level title, remaining moves, and primary navigation actions.
class GameTopBar extends StatelessWidget {
  const GameTopBar({
    super.key,
    required this.levelId,
    required this.moveCount,
    this.movesLeft,
    this.maxMoves,
    required this.canUndo,
    required this.onUndo,
    required this.onRestart,
    this.onBack,
  });

  /// The active level number.
  final int levelId;

  /// The current move count.
  final int moveCount;

  /// Number of remaining moves allowed before defeat.
  final int? movesLeft;

  /// Total maximum allowed moves for this level.
  final int? maxMoves;

  /// Whether undo is currently available.
  final bool canUndo;

  /// Callback when undo is pressed.
  final VoidCallback onUndo;

  /// Callback when restart is pressed.
  final VoidCallback onRestart;

  /// Optional custom callback for back navigation.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final int effectiveLeft = movesLeft ?? ((maxMoves ?? 20) - moveCount);
    final bool isUrgent = effectiveLeft <= 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: <Widget>[
          // Back button
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              key: const ValueKey<String>('top_bar_back_button'),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              color: Colors.white,
              tooltip: l10n.backTooltip,
              padding: EdgeInsets.zero,
              onPressed: () {
                if (onBack != null) {
                  onBack!();
                } else if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),

          // Level badge in center
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  border: Border.all(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x3306B6D4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  l10n.levelBadge(levelId),
                  style: const TextStyle(
                    color: Color(0xFF22D3EE),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),

          // Move counter badge with dynamic stress warning
          AnimatedContainer(
            key: const ValueKey<String>('move_counter_badge'),
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: isUrgent
                  ? const Color(0x33EF4444)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              border: Border.all(
                color: isUrgent
                    ? const Color(0xFFEF4444)
                    : Colors.white.withValues(alpha: 0.2),
                width: isUrgent ? 1.5 : 1.0,
              ),
              boxShadow: isUrgent
                  ? const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x55EF4444),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  isUrgent
                       ? Icons.warning_amber_rounded
                      : Icons.hourglass_top_rounded,
                  size: 15,
                  color: isUrgent ? const Color(0xFFFCA5A5) : Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.movesLeftCount(effectiveLeft),
                  key: const ValueKey<String>('moves_left_text'),
                  style: TextStyle(
                    color: isUrgent ? const Color(0xFFFCA5A5) : Colors.white,
                    fontSize: 12,
                    fontWeight: isUrgent ? FontWeight.bold : FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Sound toggle button in GameTopBar
          const SizedBox(width: 6),
          Consumer(
            builder: (BuildContext ctx, WidgetRef ref, _) {
              final bool isSoundEnabled =
                  ref.watch(audioSettingsControllerProvider);
              return SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  key: const ValueKey<String>('top_bar_sound_toggle_button'),
                  icon: Icon(
                    isSoundEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    size: 18,
                    color: isSoundEnabled ? Colors.white70 : Colors.white24,
                  ),
                  tooltip: isSoundEnabled ? 'Tắt âm thanh' : 'Bật âm thanh',
                  padding: EdgeInsets.zero,
                  onPressed: () => ref
                      .read(audioSettingsControllerProvider.notifier)
                      .toggleSound(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
