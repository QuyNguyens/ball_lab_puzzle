import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/active_game_session.dart';
import '../../domain/models/game_economy.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/level_record.dart';
import '../../domain/models/puzzle_move.dart';
import '../../domain/models/tube.dart';
import '../../domain/services/level_provider_service.dart';
import '../../domain/services/rewarded_ad_service.dart';
import '../controllers/audio_controller.dart';
import '../controllers/economy_controller.dart';
import '../controllers/game_controller.dart';
import '../controllers/progression_controller.dart';
import '../widgets/game_action_bar.dart';
import '../widgets/game_top_bar.dart';
import '../widgets/level_completed_dialog.dart';
import '../widgets/level_failed_dialog.dart';
import '../widgets/out_of_lives_dialog.dart';
import '../widgets/tube_board.dart';

/// Primary screen for playing Ball Lab Puzzle.
class BallLabScreen extends ConsumerStatefulWidget {
  const BallLabScreen({
    super.key,
    this.initialLevelId,
    this.onBack,
  });

  /// Optional level ID to start playing with.
  final int? initialLevelId;

  /// Optional custom callback for back navigation.
  final VoidCallback? onBack;

  @override
  ConsumerState<BallLabScreen> createState() => _BallLabScreenState();
}

class _BallLabScreenState extends ConsumerState<BallLabScreen>
    with WidgetsBindingObserver {
  bool _dialogActive = false;
  bool _hasDeductedLifeForDefeat = false;

  bool _hasPlayedLowMovesWarning = false;
  bool _hasPlayedCriticalMovesWarning = false;
  bool _isRequestingAd = false;

  PuzzleMove? _activeHint;
  Timer? _hintAutoDismissTimer;

  void _clearHint() {
    _hintAutoDismissTimer?.cancel();
    _hintAutoDismissTimer = null;
    if (_activeHint != null) {
      setState(() {
        _activeHint = null;
      });
    }
  }

  void _triggerHint(PuzzleMove hint) {
    _hintAutoDismissTimer?.cancel();
    setState(() {
      _activeHint = hint;
    });
    _hintAutoDismissTimer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() {
          _activeHint = null;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hintAutoDismissTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ref.read(gameAudioServiceProvider).stopAll();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final int targetLevel = widget.initialLevelId ?? 1;
      final ActiveGameSession? savedSession =
          ref.read(economyControllerProvider.notifier).activeSession;

      // Restore ongoing session if matching level, otherwise load fresh
      if (savedSession != null &&
          savedSession.levelId == targetLevel &&
          !savedSession.isFinished) {
        ref.read(gameControllerProvider.notifier).restoreSession(
              savedSession.levelId,
              savedSession.tubes,
              savedSession.moveCount,
              savedSession.maxMoves,
            );
      } else {
        ref.read(gameControllerProvider.notifier).loadLevel(targetLevel);
      }
    });
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
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            side: BorderSide(color: Color(0xFFF43F5E), width: 1.2),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _showVictoryDialog(BuildContext context, GamePlayState state) {
    if (_dialogActive) return;
    _dialogActive = true;

    final LevelProviderService levelService = ref.read(
      levelProviderServiceProvider,
    );
    final int nextLevelId = state.currentLevel.levelId + 1;
    final bool hasNext = levelService.hasLevel(nextLevelId);

    // Calculate stars and update progression
    final int stars =
        state.currentLevel.calculateStars(state.gameState.moveCount);
    final LevelRecord prevRecord = ref
        .read(progressionControllerProvider.notifier)
        .getRecord(state.currentLevel.levelId);
    final bool isNewBest = !prevRecord.isCompleted ||
        stars > prevRecord.stars ||
        (stars == prevRecord.stars &&
            (prevRecord.bestMoves == null ||
                state.gameState.moveCount < prevRecord.bestMoves!));

    // Persist victory in progression controller
    ref.read(progressionControllerProvider.notifier).recordVictory(
          levelId: state.currentLevel.levelId,
          stars: stars,
          movesUsed: state.gameState.moveCount,
        );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return LevelCompletedDialog(
          levelId: state.currentLevel.levelId,
          moveCount: state.gameState.moveCount,
          parMoves: state.currentLevel.parMoves,
          stars: stars,
          threeStarMoves: state.currentLevel.threeStarMoves,
          twoStarMoves: state.currentLevel.twoStarMoves,
          isMilestone: state.currentLevel.isMilestone,
          isNewBest: isNewBest,
          hasNextLevel: hasNext,
          onPlayAgain: () {
            Navigator.of(dialogContext).pop();
            _dialogActive = false;
            final GameEconomy economy = ref.read(economyControllerProvider);
            if (!economy.canPlay) {
              showDialog<void>(
                context: context,
                builder: (_) => OutOfLivesDialog(
                  onLifeGranted: () {
                    _hasDeductedLifeForDefeat = false;
                    ref.read(gameControllerProvider.notifier).restart();
                  },
                ),
              );
              return;
            }
            _hasDeductedLifeForDefeat = false;
            ref.read(gameControllerProvider.notifier).restart();
          },
          onNextLevel: () {
            Navigator.of(dialogContext).pop();
            _dialogActive = false;
            final GameEconomy economy = ref.read(economyControllerProvider);
            if (!economy.canPlay) {
              showDialog<void>(
                context: context,
                builder: (_) => OutOfLivesDialog(
                  onLifeGranted: () {
                    _hasDeductedLifeForDefeat = false;
                    ref
                        .read(gameControllerProvider.notifier)
                        .loadLevel(nextLevelId);
                  },
                ),
              );
              return;
            }
            _hasDeductedLifeForDefeat = false;
            ref.read(gameControllerProvider.notifier).loadLevel(nextLevelId);
          },
          onLevelMap: () {
            Navigator.of(dialogContext).pop();
            _dialogActive = false;
            if (widget.onBack != null) {
              widget.onBack!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        );
      },
    ).then((_) {
      _dialogActive = false;
    }).catchError((dynamic _) {
      _dialogActive = false;
    });
  }

  void _showDefeatDialog(BuildContext context, GamePlayState state) {
    if (_dialogActive) return;
    _dialogActive = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return LevelFailedDialog(
          levelId: state.currentLevel.levelId,
          moveCount: state.gameState.moveCount,
          maxMoves: state.gameState.maxMoves,
          onPlayAgain: () {
            Navigator.of(dialogContext).pop();
            _dialogActive = false;
            final GameEconomy economy = ref.read(economyControllerProvider);
            if (!economy.canPlay) {
              showDialog<void>(
                context: context,
                builder: (_) => OutOfLivesDialog(
                  onLifeGranted: () {
                    _hasDeductedLifeForDefeat = false;
                    ref.read(gameControllerProvider.notifier).restart();
                  },
                ),
              );
              return;
            }
            _hasDeductedLifeForDefeat = false;
            ref.read(gameControllerProvider.notifier).restart();
          },
          onExit: () {
            Navigator.of(dialogContext).pop();
            _dialogActive = false;
            if (widget.onBack != null) {
              widget.onBack!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        );
      },
    ).then((_) {
      _dialogActive = false;
    }).catchError((dynamic _) {
      _dialogActive = false;
    });
  }

  /// Handles showing rewarded ad to earn an extra hint when daily quota is depleted.
  Future<void> _handleRewardedAdHint({
    required GameState gameState,
    required GameController controller,
    required AppLocalizations l10n,
  }) async {
    if (_isRequestingAd) return;
    if (gameState.isCompleted || gameState.isOutOfMoves) return;

    final RewardedAdState adState = ref.read(rewardedAdServiceProvider);

    // If ad is not ready, show friendly message and request preload
    if (!adState.isReady) {
      if (adState.isLoading) {
        _showToast(context, l10n.adNotReadyMessage);
      } else {
        ref.read(rewardedAdServiceProvider.notifier).loadAd();
        _showToast(context, l10n.adNotReadyMessage);
      }
      return;
    }

    // Explicit confirmation dialog before displaying fullscreen rewarded ad
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        title: Row(
          children: <Widget>[
            const Icon(Icons.lightbulb_rounded, color: Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l10n.adRewardHintDialogTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.adRewardHintDialogMessage,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.adRewardHintDialogCancel,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.black,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.ondemand_video_rounded, size: 18),
            label: Text(
              l10n.adRewardHintDialogConfirm,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isRequestingAd = true;
    });

    bool rewardGranted = false;
    ref.read(rewardedAdServiceProvider.notifier).showAd(
      onUserEarnedReward: () async {
        if (rewardGranted) return;
        rewardGranted = true;
        await ref.read(economyControllerProvider.notifier).addRewardedHint(1);
        if (mounted) {
          _showToast(context, l10n.adRewardGrantedToast);
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
    final GamePlayState state = ref.watch(gameControllerProvider);
    final GameController controller = ref.read(gameControllerProvider.notifier);
    final GameEconomy economy = ref.watch(economyControllerProvider);
    final RewardedAdState adState = ref.watch(rewardedAdServiceProvider);

    // Listen for level completion and out-of-moves events
    ref.listen<GamePlayState>(
      gameControllerProvider,
      (GamePlayState? previous, GamePlayState next) {
        // Clear active visual hint when game state changes
        if (next.gameState != previous?.gameState) {
          _hintAutoDismissTimer?.cancel();
          _hintAutoDismissTimer = null;
          _activeHint = null;
        }

        // Reset warning flags when restarting or switching levels
        if (previous == null ||
            next.currentLevel.levelId != previous.currentLevel.levelId ||
            next.gameState.moveCount == 0) {
          _hasPlayedLowMovesWarning = false;
          _hasPlayedCriticalMovesWarning = false;
        }

        // Move warnings: low moves (<=3) and critical (1)
        final int movesLeft = next.gameState.movesLeft;
        if (!next.gameState.isCompleted && !next.gameState.isOutOfMoves) {
          if (movesLeft == 1 && !_hasPlayedCriticalMovesWarning) {
            _hasPlayedCriticalMovesWarning = true;
            _hasPlayedLowMovesWarning = true;
            ref.read(gameAudioServiceProvider).playCriticalMovesWarning();
          } else if (movesLeft <= 3 &&
              movesLeft > 1 &&
              !_hasPlayedLowMovesWarning) {
            _hasPlayedLowMovesWarning = true;
            ref.read(gameAudioServiceProvider).playLowMovesWarning();
          } else if (movesLeft > 3) {
            _hasPlayedLowMovesWarning = false;
            _hasPlayedCriticalMovesWarning = false;
          } else if (movesLeft > 1) {
            _hasPlayedCriticalMovesWarning = false;
          }
        }

        // Auto-save active session if in progress and not completed or out of moves
        if (!next.gameState.isCompleted &&
            !next.gameState.isOutOfMoves &&
            next.gameState.moveCount > 0) {
          ref.read(economyControllerProvider.notifier).saveSession(
                ActiveGameSession(
                  levelId: next.currentLevel.levelId,
                  tubes: next.gameState.tubes,
                  moveCount: next.gameState.moveCount,
                  maxMoves: next.gameState.maxMoves,
                ),
              );
        }

        // Critical: Check victory FIRST so that a win on the final move triggers victory, not defeat.
        if (next.gameState.isCompleted &&
            !(previous?.gameState.isCompleted ?? false)) {
          ref.read(economyControllerProvider.notifier).clearSession();
          _showVictoryDialog(context, next);
        } else if (next.gameState.isOutOfMoves &&
            !(previous?.gameState.isOutOfMoves ?? false)) {
          // Defeat: deduct 1 life idempotently
          if (!_hasDeductedLifeForDefeat) {
            _hasDeductedLifeForDefeat = true;
            ref.read(economyControllerProvider.notifier).consumeLifeOnDefeat();
            ref.read(economyControllerProvider.notifier).clearSession();
          }
          _showDefeatDialog(context, next);
        }
      },
    );

    // Calculate completed tubes count for the progress indicator
    final int completedTubes =
        state.gameState.tubes.where((Tube t) => t.isSolved).length;
    final int totalTargetTubes = state.currentLevel.distinctColors.length;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF090D16),
              Color(0xFF0F172A),
              Color(0xFF1E293B),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              // Top Bar
              GameTopBar(
                levelId: state.currentLevel.levelId,
                moveCount: state.gameState.moveCount,
                movesLeft: state.gameState.movesLeft,
                maxMoves: state.gameState.maxMoves,
                canUndo: state.gameState.history.isNotEmpty &&
                    !state.gameState.isCompleted &&
                    !state.gameState.isOutOfMoves &&
                    economy.canUndo,
                onUndo: () {
                  _clearHint();
                  if (state.gameState.isCompleted ||
                      state.gameState.isOutOfMoves) {
                    return;
                  }
                  if (!economy.canUndo) {
                    _showToast(
                      context,
                      l10n.outOfUndosToast,
                    );
                    return;
                  }
                  final bool undone = controller.undo();
                  if (undone) {
                    ref.read(economyControllerProvider.notifier).consumeUndo();
                    ref.read(gameAudioServiceProvider).playUndo();
                    if (state.gameState.moveCount > 0) {
                      ref.read(economyControllerProvider.notifier).saveSession(
                            ActiveGameSession(
                              levelId: state.currentLevel.levelId,
                              tubes: state.gameState.tubes,
                              moveCount: state.gameState.moveCount,
                              maxMoves: state.gameState.maxMoves,
                            ),
                          );
                    }
                  }
                },
                onRestart: () {
                  _clearHint();
                  _hasPlayedLowMovesWarning = false;
                  _hasPlayedCriticalMovesWarning = false;
                  if (!economy.canPlay) {
                    showDialog<void>(
                      context: context,
                      builder: (_) => OutOfLivesDialog(
                        onLifeGranted: () {
                          _hasDeductedLifeForDefeat = false;
                          ref
                              .read(economyControllerProvider.notifier)
                              .clearSession();
                          controller.restart();
                        },
                      ),
                    );
                    return;
                  }
                  _hasDeductedLifeForDefeat = false;
                  ref.read(economyControllerProvider.notifier).clearSession();
                  controller.restart();
                },
                onBack: widget.onBack,
              ),

              // Progress & Instruction banner
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        l10n.gameInstruction(
                          state.gameState.moveCount,
                          state.gameState.maxMoves,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                      ),
                      child: Text(
                        l10n.tubesSolvedProgress(
                          completedTubes,
                          totalTargetTubes,
                        ),
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white10, height: 16),

              // Main Tube Board (Visually dominant area)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TubeBoard(
                    tubes: state.gameState.tubes,
                    selectedTubeIndex: state.selectedTubeIndex,
                    activeHint: _activeHint,
                    onHintDismissed: _clearHint,
                    onTubeTapped: (int index) {
                      _clearHint();
                      controller.selectTube(index);
                    },
                    onMoveBall: (int from, int to) {
                      _clearHint();
                      return controller.moveBall(from, to);
                    },
                    canMove: (int from, int to) => ref
                        .read(gameEngineProvider)
                        .isValidMove(state.gameState, from, to),
                    isCompleted: state.gameState.isCompleted,
                  ),
                ),
              ),

              const Divider(color: Colors.white10, height: 16),

              // Bottom Actions with Quotas
              GameActionBar(
                undoCount: economy.undoCount,
                hintCount: economy.hintCount,
                canUndo: state.gameState.history.isNotEmpty &&
                    !state.gameState.isCompleted &&
                    !state.gameState.isOutOfMoves &&
                    economy.canUndo,
                onUndo: () {
                  _clearHint();
                  if (state.gameState.isCompleted ||
                      state.gameState.isOutOfMoves) {
                    return;
                  }
                  if (!economy.canUndo) {
                    _showToast(
                      context,
                      l10n.outOfUndosToast,
                    );
                    return;
                  }
                  final bool undone = controller.undo();
                  if (undone) {
                    ref.read(economyControllerProvider.notifier).consumeUndo();
                    ref.read(gameAudioServiceProvider).playUndo();
                    if (state.gameState.moveCount > 0) {
                      ref.read(economyControllerProvider.notifier).saveSession(
                            ActiveGameSession(
                              levelId: state.currentLevel.levelId,
                              tubes: state.gameState.tubes,
                              moveCount: state.gameState.moveCount,
                              maxMoves: state.gameState.maxMoves,
                            ),
                          );
                    }
                  }
                },
                onOutOfUndos: () => _showToast(
                  context,
                  l10n.outOfUndosToast,
                ),
                onRestart: () {
                  _clearHint();
                  _hasPlayedLowMovesWarning = false;
                  _hasPlayedCriticalMovesWarning = false;
                  if (!economy.canPlay) {
                    showDialog<void>(
                      context: context,
                      builder: (_) => OutOfLivesDialog(
                        onLifeGranted: () {
                          _hasDeductedLifeForDefeat = false;
                          ref
                              .read(economyControllerProvider.notifier)
                              .clearSession();
                          controller.restart();
                        },
                      ),
                    );
                    return;
                  }
                  _hasDeductedLifeForDefeat = false;
                  ref.read(economyControllerProvider.notifier).clearSession();
                  controller.restart();
                },
                isAdLoading: _isRequestingAd ||
                    (economy.hintCount == 0 && adState.isLoading),
                onHint: () {
                  if (state.gameState.isCompleted ||
                      state.gameState.isOutOfMoves) {
                    return;
                  }
                  if (!economy.canHint) {
                    _handleRewardedAdHint(
                      gameState: state.gameState,
                      controller: controller,
                      l10n: l10n,
                    );
                    return;
                  }
                  final PuzzleMove? hint = ref
                      .read(gameEngineProvider)
                      .findHintMove(state.gameState);
                  final ScaffoldMessengerState? messenger =
                      ScaffoldMessenger.maybeOf(context);

                  if (hint != null) {
                    ref.read(economyControllerProvider.notifier).consumeHint();
                    controller.clearSelection();
                    _triggerHint(hint);
                    ref.read(gameAudioServiceProvider).playHint();
                  } else {
                    _clearHint();
                    if (messenger != null) {
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF1E293B),
                            content: Text(
                              state.gameState.isCompleted
                                  ? l10n.hintAlreadyCompleted
                                  : l10n.hintNoMoveFound,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                    }
                  }
                },
                onOutOfHints: () => _handleRewardedAdHint(
                  gameState: state.gameState,
                  controller: controller,
                  l10n: l10n,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
