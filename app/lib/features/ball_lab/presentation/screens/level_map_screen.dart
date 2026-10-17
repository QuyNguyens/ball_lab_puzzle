import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/models/game_economy.dart';
import '../../domain/models/game_progression.dart';
import '../../domain/models/level_data.dart';
import '../../domain/models/level_record.dart';
import '../../domain/services/level_provider_service.dart';
import '../controllers/economy_controller.dart';
import '../controllers/game_controller.dart';
import '../controllers/progression_controller.dart';
import '../widgets/out_of_lives_dialog.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/audio_controller.dart';
import 'ball_lab_screen.dart';

/// Interactive Level Journey Map screen for Ball Lab Puzzle.
/// Displays a winding laboratory map with level nodes, milestone checkpoints,
/// star achievements, and persistent progression tracking.
class LevelMapScreen extends ConsumerStatefulWidget {
  const LevelMapScreen({
    super.key,
    this.onBack,
  });

  /// Optional back callback (e.g. when opened from Home menu).
  final VoidCallback? onBack;

  @override
  ConsumerState<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends ConsumerState<LevelMapScreen> {
  final ScrollController _scrollController = ScrollController();
  final double _nodeSpacing = 110;
  static const int _pageSize = 20;
  int _selectedChapterIndex = 0;

  @override
  void initState() {
    super.initState();
    final GameProgression progression = ref.read(progressionControllerProvider);
    final int unlocked = progression.unlockedLevelMax;
    _selectedChapterIndex = ((unlocked - 1) ~/ _pageSize).clamp(0, 49);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentLevel();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentLevel() {
    if (!_scrollController.hasClients) return;
    final GameProgression progression = ref.read(progressionControllerProvider);
    final int unlocked = progression.unlockedLevelMax;
    final int activeChapter = (unlocked - 1) ~/ _pageSize;

    if (_selectedChapterIndex == activeChapter) {
      final int localIndex = (unlocked - 1) % _pageSize;
      final double targetOffset = (localIndex * _nodeSpacing) - 160.0;
      final double clamped = targetOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _changeChapter(int newIndex) {
    final LevelProviderService levelService =
        ref.read(levelProviderServiceProvider);
    final int totalChapters =
        levelService.getTotalChapters();
    if (newIndex < 0 || newIndex >= totalChapters) return;
    setState(() {
      _selectedChapterIndex = newIndex;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentLevel();
    });
  }

  void _jumpToCurrentChapter() {
    final GameProgression progression = ref.read(progressionControllerProvider);
    final int activeChapter = (progression.unlockedLevelMax - 1) ~/ _pageSize;
    _changeChapter(activeChapter);
  }

  Future<void> _showChapterPickerModal(
    BuildContext context,
    int totalChapters,
    int activeChapter,
    GameProgression progression,
  ) async {
    final LevelProviderService levelService =
        ref.read(levelProviderServiceProvider);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetCtx) {
        return _ChapterPickerSheet(
          totalChapters: totalChapters,
          selectedChapter: _selectedChapterIndex,
          activeChapter: activeChapter,
          pageSize: _pageSize,
          totalLevels: levelService.totalLevels,
          progression: progression,
          onChapterSelected: (int index) {
            Navigator.of(sheetCtx).pop();
            _changeChapter(index);
          },
        );
      },
    );
  }

  void _onLevelTap(BuildContext context, LevelData level, bool isUnlocked) {
    if (!isUnlocked) {
      final AppLocalizations l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: <Widget>[
              const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFFFB7185),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.levelLockedToast(level.levelId - 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            side: BorderSide(color: Color(0xFFE11D48), width: 1.5),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    _showLevelPreview(context, level);
  }

  Future<void> _showLevelPreview(BuildContext context, LevelData level) async {
    final GameProgression progression = ref.read(progressionControllerProvider);
    final LevelRecord record = progression.getRecord(level.levelId);
    final GameEconomy economy = ref.read(economyControllerProvider);

    bool shouldStart = false;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return _LevelPreviewSheet(
          level: level,
          record: record,
          onStart: () {
            Navigator.of(sheetContext).pop();
            if (!economy.canPlay) {
              showDialog<void>(
                context: context,
                builder: (_) => const OutOfLivesDialog(),
              );
              return;
            }
            shouldStart = true;
          },
        );
      },
    );

    if (shouldStart && context.mounted) {
      _startLevel(level.levelId);
    }
  }

  void _startLevel(int levelId) {
    final GameEconomy economy = ref.read(economyControllerProvider);
    if (!economy.canPlay) {
      showDialog<void>(
        context: context,
        builder: (_) => const OutOfLivesDialog(),
      );
      return;
    }
    ref.read(gameControllerProvider.notifier).loadLevel(levelId);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext ctx) => BallLabScreen(
          initialLevelId: levelId,
          onBack: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LevelProviderService levelService =
        ref.watch(levelProviderServiceProvider);
    final GameProgression progression =
        ref.watch(progressionControllerProvider);
    final GameEconomy economy = ref.watch(economyControllerProvider);

    final int totalChapters =
        levelService.getTotalChapters();
    final List<LevelData> levels = levelService.getLevelsForChapter(
      _selectedChapterIndex,
    );

    final int totalStars = progression.totalStars;
    final int maxPossibleStars = levelService.totalLevels * 3;

    final int activeChapter =
        (progression.unlockedLevelMax - 1) ~/ _pageSize;
    final bool isViewingActiveChapter = _selectedChapterIndex == activeChapter;

    // Calculate stars in currently viewed chapter
    int chapterStars = 0;
    for (final LevelData lvl in levels) {
      final LevelRecord rec = progression.getRecord(lvl.levelId);
      if (rec.isCompleted) {
        chapterStars += rec.stars.clamp(0, 3);
      }
    }
    final int maxChapterStars = levels.length * 3;

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
              // Header with Total Stars, Lives, and Title
              _MapHeader(
                totalStars: totalStars,
                maxPossibleStars: maxPossibleStars,
                lives: economy.totalLives,
                onBack: widget.onBack ??
                    (Navigator.of(context).canPop()
                        ? () => Navigator.of(context).pop()
                        : null),
              ),

              // Chapter Selector Bar with Quick Navigation
              _ChapterSelectorBar(
                chapterIndex: _selectedChapterIndex,
                totalChapters: totalChapters,
                startLevel: levels.isNotEmpty ? levels.first.levelId : 1,
                endLevel: levels.isNotEmpty ? levels.last.levelId : 20,
                chapterStars: chapterStars,
                maxChapterStars: maxChapterStars,
                isViewingActiveChapter: isViewingActiveChapter,
                activeLevelId: progression.unlockedLevelMax,
                onPreviousChapter: _selectedChapterIndex > 0
                    ? () => _changeChapter(_selectedChapterIndex - 1)
                    : null,
                onNextChapter: _selectedChapterIndex < totalChapters - 1
                    ? () => _changeChapter(_selectedChapterIndex + 1)
                    : null,
                onOpenChapterPicker: () => _showChapterPickerModal(
                  context,
                  totalChapters,
                  activeChapter,
                  progression,
                ),
                onJumpToCurrent: _jumpToCurrentChapter,
              ),

              // Scrollable Laboratory Winding Map (Smooth 20 nodes only!)
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext ctx, BoxConstraints constraints) {
                    final double mapWidth = constraints.maxWidth;
                    final double totalHeight =
                        (levels.length * _nodeSpacing) + 120.0;

                    return SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: SizedBox(
                        width: mapWidth,
                        height: totalHeight,
                        child: Stack(
                          children: <Widget>[
                            // Background Glowing Pipe Path (Cached in RepaintBoundary)
                            RepaintBoundary(
                              child: CustomPaint(
                                size: Size(mapWidth, totalHeight),
                                painter: _MapPathPainter(
                                  levels: levels,
                                  spacing: _nodeSpacing,
                                  width: mapWidth,
                                  unlockedMax: progression.unlockedLevelMax,
                                ),
                              ),
                            ),

                            // Level Nodes
                            ...List<Widget>.generate(levels.length, (int i) {
                              final LevelData level = levels[i];
                              final bool isUnlocked =
                                  progression.isLevelUnlocked(level.levelId);
                              final bool isCurrent =
                                  level.levelId == progression.unlockedLevelMax;
                              final LevelRecord record =
                                  progression.getRecord(level.levelId);

                              // Serpentine X position: oscillating around center
                              final double progress = i / 2.0;
                              final double xCenter = mapWidth / 2.0 +
                                  (math.sin(progress * math.pi) *
                                      (mapWidth * 0.28));
                              final double yCenter = 60.0 + (i * _nodeSpacing);

                              return Positioned(
                                left: xCenter - 42.0,
                                top: yCenter - 42.0,
                                child: _LevelNodeWidget(
                                  level: level,
                                  isUnlocked: isUnlocked,
                                  isCurrent: isCurrent,
                                  record: record,
                                  onTap: () =>
                                      _onLevelTap(context, level, isUnlocked),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom header displaying back button, laboratory title, total star progress, and daily lives.
class _MapHeader extends StatelessWidget {
  const _MapHeader({
    required this.totalStars,
    required this.maxPossibleStars,
    required this.lives,
    this.onBack,
  });

  final int totalStars;
  final int maxPossibleStars;
  final int lives;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.9),
        border: const Border(
          bottom: BorderSide(
            color: Color(0x3306B6D4),
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white70, size: 20),
              onPressed: onBack,
              tooltip: l10n.backTooltip,
            )
          else
            const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  l10n.mapTitle,
                  style: const TextStyle(
                    color: Color(0xFF22D3EE),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  l10n.mapSubtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Sound Effects Quick Toggle Button
          Consumer(
            builder: (BuildContext ctx, WidgetRef ref, _) {
              final bool isSoundEnabled =
                  ref.watch(audioSettingsControllerProvider);
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  key: const ValueKey<String>('map_sound_toggle_button'),
                  icon: Icon(
                    isSoundEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: isSoundEnabled
                        ? const Color(0xFF22D3EE)
                        : Colors.white38,
                    size: 20,
                  ),
                  tooltip: isSoundEnabled ? 'Tắt âm thanh' : 'Bật âm thanh',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  onPressed: () => ref
                      .read(audioSettingsControllerProvider.notifier)
                      .toggleSound(),
                ),
              );
            },
          ),

          // Daily Lives Pill Badge
          GestureDetector(
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (_) => const OutOfLivesDialog(),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF3B151E), Color(0xFF1E1418)],
                ),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                border: Border.all(
                  color: const Color(0xFFF43F5E).withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x44F43F5E),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.favorite_rounded,
                    size: 18,
                    color: Color(0xFFF43F5E),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$lives',
                    key: const ValueKey<String>('total_lives_counter'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Total Stars Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF332A15), Color(0xFF1E1B18)],
              ),
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x44F59E0B),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.star_rounded,
                  size: 20,
                  color: Color(0xFFFBBF24),
                ),
                const SizedBox(width: 6),
                Text(
                  '$totalStars / $maxPossibleStars',
                  key: const ValueKey<String>('total_stars_counter'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter rendering a glowing neon conduit connecting sequential level nodes.
class _MapPathPainter extends CustomPainter {
  const _MapPathPainter({
    required this.levels,
    required this.spacing,
    required this.width,
    required this.unlockedMax,
  });

  final List<LevelData> levels;
  final double spacing;
  final double width;
  final int unlockedMax;

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.length < 2) return;

    final Path activePath = Path();
    final Path lockedPath = Path();

    Offset getPoint(int i) {
      final double progress = i / 2.0;
      final double x =
          width / 2.0 + (math.sin(progress * math.pi) * (width * 0.28));
      final double y = 60.0 + (i * spacing);
      return Offset(x, y);
    }

    // Connect node points with smooth cubic bezier segments
    for (int i = 0; i < levels.length - 1; i++) {
      final Offset p1 = getPoint(i);
      final Offset p2 = getPoint(i + 1);

      final Path segment = Path()
        ..moveTo(p1.dx, p1.dy)
        ..cubicTo(
          p1.dx,
          (p1.dy + p2.dy) / 2.0,
          p2.dx,
          (p1.dy + p2.dy) / 2.0,
          p2.dx,
          p2.dy,
        );

      // Distinguish unlocked segments from locked segments
      final bool isSegmentActive = levels[i + 1].levelId <= unlockedMax;
      if (isSegmentActive) {
        activePath.addPath(segment, Offset.zero);
      } else {
        lockedPath.addPath(segment, Offset.zero);
      }
    }

    // Draw background locked pipeline
    final Paint lockedPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(lockedPath, lockedPaint);

    // Draw active conduit with high-performance multi-layer neon glow (zero CPU blur)
    final Paint activeGlow = Paint()
      ..color = const Color(0xFF06B6D4).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(activePath, activeGlow);

    final Paint activeMid = Paint()
      ..color = const Color(0xFF06B6D4).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(activePath, activeMid);

    final Paint activeCore = Paint()
      ..color = const Color(0xFF22D3EE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(activePath, activeCore);
  }

  @override
  bool shouldRepaint(covariant _MapPathPainter oldDelegate) {
    return oldDelegate.levels != levels ||
        oldDelegate.spacing != spacing ||
        oldDelegate.width != width ||
        oldDelegate.unlockedMax != unlockedMax;
  }
}

/// Laboratory-themed Chapter Navigation bar.
class _ChapterSelectorBar extends StatelessWidget {
  const _ChapterSelectorBar({
    required this.chapterIndex,
    required this.totalChapters,
    required this.startLevel,
    required this.endLevel,
    required this.chapterStars,
    required this.maxChapterStars,
    required this.isViewingActiveChapter,
    required this.activeLevelId,
    required this.onPreviousChapter,
    required this.onNextChapter,
    required this.onOpenChapterPicker,
    required this.onJumpToCurrent,
  });

  final int chapterIndex;
  final int totalChapters;
  final int startLevel;
  final int endLevel;
  final int chapterStars;
  final int maxChapterStars;
  final bool isViewingActiveChapter;
  final int activeLevelId;
  final VoidCallback? onPreviousChapter;
  final VoidCallback? onNextChapter;
  final VoidCallback onOpenChapterPicker;
  final VoidCallback onJumpToCurrent;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.95),
        border: const Border(
          bottom: BorderSide(
            color: Color(0x2206B6D4),
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          // Previous Chapter Arrow
          IconButton(
            icon: Icon(
              Icons.chevron_left_rounded,
              color: onPreviousChapter != null
                  ? const Color(0xFF22D3EE)
                  : Colors.white24,
              size: 26,
            ),
            onPressed: onPreviousChapter,
            tooltip: l10n.previousChapterTooltip,
          ),

          // Chapter Title & Quick Selector Button
          Expanded(
            child: InkWell(
              onTap: onOpenChapterPicker,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  border: Border.all(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.science_rounded,
                      color: Color(0xFF22D3EE),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          l10n.chapterIndicator(chapterIndex + 1, totalChapters),
                          style: const TextStyle(
                            color: Color(0xFF22D3EE),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          l10n.chapterProgress(
                            startLevel,
                            endLevel,
                            chapterStars,
                            maxChapterStars,
                          ),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: Color(0xFF22D3EE),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Next Chapter Arrow
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color: onNextChapter != null
                  ? const Color(0xFF22D3EE)
                  : Colors.white24,
              size: 26,
            ),
            onPressed: onNextChapter,
            tooltip: l10n.nextChapterTooltip,
          ),

          // Jump to Current Active Level button (if viewing other chapter)
          if (!isViewingActiveChapter)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: InkWell(
                onTap: onJumpToCurrent,
                borderRadius: const BorderRadius.all(Radius.circular(14)),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[Color(0xFF0284C7), Color(0xFF06B6D4)],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Color(0x5506B6D4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.my_location_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.activeLevelShort(activeLevelId),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Modal bottom sheet allowing instantaneous jumping to any chapter across 999 levels.
class _ChapterPickerSheet extends StatelessWidget {
  const _ChapterPickerSheet({
    required this.totalChapters,
    required this.selectedChapter,
    required this.activeChapter,
    required this.pageSize,
    required this.totalLevels,
    required this.progression,
    required this.onChapterSelected,
  });

  final int totalChapters;
  final int selectedChapter;
  final int activeChapter;
  final int pageSize;
  final int totalLevels;
  final GameProgression progression;
  final ValueChanged<int> onChapterSelected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF06B6D4), width: 1.5),
        ),
      ),
      child: Column(
        children: <Widget>[
          // Pill handle
          Container(
            width: 44,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                l10n.selectChapterTitle,
                style: const TextStyle(
                  color: Color(0xFF22D3EE),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                l10n.chapterPickerSummary(totalChapters, totalLevels),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.25,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: totalChapters,
              itemBuilder: (BuildContext ctx, int index) {
                final int startLevel = index * pageSize + 1;
                final int endLevel =
                    math.min((index + 1) * pageSize, totalLevels);
                final bool isUnlocked =
                    startLevel <= progression.unlockedLevelMax;
                final bool isSelected = index == selectedChapter;
                final bool isCurrentActive = index == activeChapter;

                // Count stars in this chapter
                int chapterStars = 0;
                for (int lvl = startLevel; lvl <= endLevel; lvl++) {
                  final LevelRecord rec = progression.getRecord(lvl);
                  if (rec.isCompleted) {
                    chapterStars += rec.stars.clamp(0, 3);
                  }
                }
                final int maxStars = (endLevel - startLevel + 1) * 3;

                return InkWell(
                  onTap: () => onChapterSelected(index),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0E7490)
                          : (isUnlocked
                              ? const Color(0xFF1E293B)
                              : const Color(0xFF141A29)),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(12)),
                      border: Border.all(
                        color: isCurrentActive
                            ? const Color(0xFF22D3EE)
                            : (isSelected
                                ? Colors.cyanAccent
                                : (isUnlocked
                                    ? Colors.white12
                                    : Colors.white.withValues(alpha: 0.05))),
                        width: isCurrentActive || isSelected ? 2.0 : 1.0,
                      ),
                      boxShadow: isCurrentActive
                          ? const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x4422D3EE),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          l10n.chapterItemTitle(index + 1),
                          style: TextStyle(
                            color: isUnlocked ? Colors.white : Colors.white38,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$startLevel – $endLevel',
                          style: TextStyle(
                            color: isUnlocked
                                ? const Color(0xFF22D3EE)
                                : Colors.white24,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (isUnlocked)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: Color(0xFFFBBF24),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '$chapterStars/$maxStars',
                                style: const TextStyle(
                                  color: Color(0xFFFDE68A),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          )
                        else
                          const Icon(
                            Icons.lock_rounded,
                            size: 14,
                            color: Colors.white24,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Visual representation of an individual level node on the journey map.
class _LevelNodeWidget extends StatelessWidget {
  const _LevelNodeWidget({
    required this.level,
    required this.isUnlocked,
    required this.isCurrent,
    required this.record,
    required this.onTap,
  });

  final LevelData level;
  final bool isUnlocked;
  final bool isCurrent;
  final LevelRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isMilestone = level.isMilestone;
    final bool isCompleted = record.isCompleted;
    final double nodeSize = isMilestone ? 76.0 : 68.0;

    // Theme color palette
    final Color primaryColor = isMilestone
        ? const Color(0xFFF59E0B)
        : (isCurrent
            ? const Color(0xFF06B6D4)
            : (isCompleted
                ? const Color(0xFF10B981)
                : const Color(0xFF475569)));

    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(40)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Circular / Hexagonal Node Container
          Container(
            width: nodeSize,
            height: nodeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
              border: Border.all(
                color: isUnlocked
                    ? primaryColor
                    : Colors.white.withValues(alpha: 0.15),
                width: isCurrent || isMilestone ? 3.0 : 2.0,
              ),
              boxShadow: isUnlocked
                  ? <BoxShadow>[
                      BoxShadow(
                        color: primaryColor.withValues(alpha: isCurrent ? 0.6 : 0.35),
                        blurRadius: isCurrent ? 20 : 12,
                        spreadRadius: isCurrent ? 3 : 1,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isUnlocked
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        if (isMilestone)
                          const Icon(
                            Icons.emoji_events_rounded,
                            size: 16,
                            color: Color(0xFFFDE68A),
                          ),
                        Text(
                          '${level.levelId}',
                          key: ValueKey<String>('level_node_${level.levelId}'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMilestone ? 20 : 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    )
                  : const Icon(
                      Icons.lock_rounded,
                      color: Colors.white30,
                      size: 24,
                    ),
            ),
          ),

          const SizedBox(height: 4),

          // Star Ratings under the node
          if (isCompleted)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List<Widget>.generate(3, (int starIdx) {
                final bool earned = starIdx < record.stars;
                return Icon(
                  earned ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 14,
                  color: earned ? const Color(0xFFFBBF24) : Colors.white24,
                );
              }),
            )
          else if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: Color(0xFF06B6D4),
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
              child: Text(
                AppLocalizations.of(context).nodePlay,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}

/// Bottom sheet displaying level briefing, requirements, star thresholds, and Start button.
class _LevelPreviewSheet extends StatelessWidget {
  const _LevelPreviewSheet({
    required this.level,
    required this.record,
    required this.onStart,
  });

  final LevelData level;
  final LevelRecord record;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool isMilestone = level.isMilestone;
    final Color accent =
        isMilestone ? const Color(0xFFF59E0B) : const Color(0xFF06B6D4);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: accent.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Colors.black87,
            blurRadius: 30,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Top pill indicator
          Container(
            width: 44,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),

          const SizedBox(height: 16),

          // Title & Milestone indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (isMilestone) ...<Widget>[
                const Icon(Icons.emoji_events_rounded,
                    color: Color(0xFFF59E0B), size: 24),
                const SizedBox(width: 8),
              ],
              Text(
                l10n.levelBadge(level.levelId),
                style: TextStyle(
                  color: accent,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              if (isMilestone)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                  child: Text(
                    l10n.bossBadge,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            isMilestone
                ? l10n.milestoneLevelDesc
                : l10n.normalLevelDesc,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),

          const SizedBox(height: 20),

          // Specifications Table
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _StatItem(
                  label: l10n.statColors,
                  value: '${level.distinctColors.length}',
                ),
                _StatItem(
                  label: l10n.statTubes,
                  value: '${level.initialTubes.length}',
                ),
                _StatItem(
                  label: l10n.statMaxMoves,
                  value: '${level.maxMoves}',
                ),
                _StatItem(
                  label: l10n.statBestRun,
                  value: record.isCompleted
                      ? l10n.movesUnit(record.bestMoves!)
                      : l10n.statNone,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Star Goals
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _StarGoalItem(
                  stars: 3,
                  condition: l10n.starCondition(level.threeStarMoves),
                ),
                _StarGoalItem(
                  stars: 2,
                  condition: l10n.starCondition(level.twoStarMoves),
                ),
                _StarGoalItem(
                  stars: 1,
                  condition: l10n.starCondition(level.maxMoves),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Start Experiment Action Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey<String>('level_preview_start_button'),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              onPressed: onStart,
              child: Text(
                l10n.buttonStartExperiment,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StarGoalItem extends StatelessWidget {
  const _StarGoalItem({required this.stars, required this.condition});

  final int stars;
  final String condition;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '⭐' * stars,
          style: const TextStyle(fontSize: 11),
        ),
        const SizedBox(width: 4),
        Text(
          condition,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}
