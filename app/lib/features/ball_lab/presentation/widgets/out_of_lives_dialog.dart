import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/game_economy.dart';
import '../../domain/services/rewarded_ad_service.dart';
import '../../domain/services/time_service.dart';
import '../controllers/economy_controller.dart';

/// Modal dialog presented when the player has 0 available lives and attempts to start a game.
///
/// Displays countdown to the next midnight refresh in Asia/Ho_Chi_Minh and supports
/// watching Rewarded Ads for +1 Life (strictly bounded to max 3 lives per day in Vietnam timezone).
class OutOfLivesDialog extends ConsumerStatefulWidget {
  const OutOfLivesDialog({
    super.key,
    this.timeUntilRefill,
    this.onBackToMap,
    this.onWatchAd,
    this.onBuyLives,
    this.onLifeGranted,
  });

  /// Duration remaining until midnight rollover in Vietnam.
  final Duration? timeUntilRefill;

  /// Callback when player elects to return to the Level Map.
  final VoidCallback? onBackToMap;

  /// Optional override callback for watching Rewarded Ads.
  final VoidCallback? onWatchAd;

  /// Optional future callback for In-App Purchases.
  final VoidCallback? onBuyLives;

  /// Callback triggered after +1 life has been successfully granted via ad.
  final VoidCallback? onLifeGranted;

  @override
  ConsumerState<OutOfLivesDialog> createState() => _OutOfLivesDialogState();
}

class _OutOfLivesDialogState extends ConsumerState<OutOfLivesDialog> {
  late Duration _remaining;
  Timer? _timer;
  bool _isRequestingAd = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.timeUntilRefill ??
        const VietnamTimeService().timeUntilNextMidnight();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) return;
      setState(() {
        if (_remaining.inSeconds > 0) {
          _remaining = _remaining - const Duration(seconds: 1);
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final int hours = d.inHours;
    final int minutes = d.inMinutes.remainder(60);
    final int seconds = d.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showToast(BuildContext context, String message) {
    final ScaffoldMessengerState? messenger =
        ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E293B),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _handleWatchAd({
    required BuildContext context,
    required GameEconomy economy,
    required RewardedAdState adState,
    required AppLocalizations l10n,
  }) async {
    if (widget.onWatchAd != null) {
      widget.onWatchAd!();
      return;
    }

    if (_isRequestingAd) return;

    if (!economy.canWatchAdForLife) {
      _showToast(context, l10n.adDailyLimitReachedToast);
      return;
    }

    if (!adState.isReady) {
      if (adState.isLoading) {
        _showToast(context, l10n.adNotReadyMessage);
      } else {
        ref.read(rewardedAdServiceProvider.notifier).loadAd();
        _showToast(context, l10n.adNotReadyMessage);
      }
      return;
    }

    setState(() {
      _isRequestingAd = true;
    });

    bool rewardGranted = false;
    ref.read(rewardedAdServiceProvider.notifier).showAd(
      onUserEarnedReward: () async {
        if (rewardGranted) return;
        rewardGranted = true;
        final bool success = await ref
            .read(economyControllerProvider.notifier)
            .addRewardedLife();
        if (success && mounted) {
          _showToast(context, l10n.adRewardLifeGrantedToast);
          widget.onLifeGranted?.call();
          Navigator.of(context).pop();
        }
      },
      onAdClosed: () {
        if (mounted) {
          setState(() {
            _isRequestingAd = false;
          });
        } else {
          _isRequestingAd = false;
        }
      },
      onAdFailedToShow: (String reason) {
        if (mounted) {
          setState(() {
            _isRequestingAd = false;
          });
          _showToast(context, l10n.adNotReadyMessage);
        } else {
          _isRequestingAd = false;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final GameEconomy economy = ref.watch(economyControllerProvider);
    final RewardedAdState adState = ref.watch(rewardedAdServiceProvider);

    final bool canWatch = economy.canWatchAdForLife;
    final String adTag = canWatch
        ? '${economy.rewardedLivesToday}/${GameEconomy.maxDailyRewardedLives}'
        : l10n.adDailyLimitReachedTag;
    final bool isAdLoading =
        _isRequestingAd || (canWatch && adState.isLoading);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: const BorderRadius.all(Radius.circular(28)),
          border: Border.all(
            color: const Color(0xFFF43F5E).withValues(alpha: 0.6),
            width: 2,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x55F43F5E),
              blurRadius: 30,
              spreadRadius: 2,
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
            // Depleted Heart / Battery Badge
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[Color(0xFFFB7185), Color(0xFFE11D48)],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color(0x66F43F5E),
                    blurRadius: 18,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 38,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 18),

            // Dialog Title
            Text(
              l10n.outOfLivesTitle,
              key: const ValueKey<String>('out_of_lives_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFB7185),
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              l10n.outOfLivesMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 18),

            // Refill Countdown Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: <Widget>[
                  Text(
                    l10n.nextFreeRefillIn,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(_remaining),
                    key: const ValueKey<String>('lives_refill_countdown'),
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Rewarded Ad (+1 Life) Option
            _RewardedLifeOption(
              icon: Icons.ondemand_video_rounded,
              title: l10n.watchVideoOption,
              tag: adTag,
              isLoading: isAdLoading,
              canWatch: canWatch,
              onTap: () => _handleWatchAd(
                context: context,
                economy: economy,
                adState: adState,
                l10n: l10n,
              ),
            ),

            const SizedBox(height: 8),

            // Placeholder 2: IAP Refill - Coming Soon
            _FutureExpansionOption(
              icon: Icons.bolt_rounded,
              title: l10n.instantRefillOption,
              tag: l10n.comingSoonTag,
              onTap: widget.onBuyLives,
              isEnabled: widget.onBuyLives != null,
            ),

            const SizedBox(height: 18),

            // Back to Map Primary Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey<String>('out_of_lives_back_button'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                onPressed:
                    widget.onBackToMap ?? () => Navigator.of(context).pop(),
                child: Text(
                  l10n.buttonBackToMap,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardedLifeOption extends StatelessWidget {
  const _RewardedLifeOption({
    required this.icon,
    required this.title,
    required this.tag,
    required this.isLoading,
    required this.canWatch,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String tag;
  final bool isLoading;
  final bool canWatch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = canWatch
        ? const Color(0xFF1E293B)
        : Colors.white.withValues(alpha: 0.03);

    final Color borderColor = canWatch
        ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.08);

    final Color iconColor = canWatch
        ? const Color(0xFFFCD34D)
        : Colors.white.withValues(alpha: 0.25);

    final Color titleColor = canWatch
        ? Colors.white
        : Colors.white.withValues(alpha: 0.35);

    final Color tagBgColor = canWatch
        ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.08);

    final Color tagTextColor = canWatch
        ? const Color(0xFFFCD34D)
        : Colors.white.withValues(alpha: 0.35);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            border: Border.all(color: borderColor, width: canWatch ? 1.5 : 1.0),
          ),
          child: Row(
            children: <Widget>[
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFFCD34D)),
                  ),
                )
              else
                Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tagBgColor,
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: tagTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FutureExpansionOption extends StatelessWidget {
  const _FutureExpansionOption({
    required this.icon,
    required this.title,
    required this.tag,
    this.onTap,
    required this.isEnabled,
  });

  final IconData icon;
  final String title;
  final String tag;
  final VoidCallback? onTap;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: Colors.white38),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
