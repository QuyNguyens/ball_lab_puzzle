// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ball Lab Puzzle';

  @override
  String get backTooltip => 'Back';

  @override
  String levelTitle(int levelId) {
    return 'Level $levelId';
  }

  @override
  String levelBadge(int levelId) {
    return 'LEVEL $levelId';
  }

  @override
  String movesLeftCount(int count) {
    return 'MOVES LEFT: $count';
  }

  @override
  String get actionRestart => 'Restart';

  @override
  String actionUndo(int count) {
    return 'Undo ($count)';
  }

  @override
  String get actionUndoSimple => 'Undo';

  @override
  String actionHint(int count) {
    return 'Hint ($count)';
  }

  @override
  String get outOfUndosToast => 'You have used all free Undo moves for today!';

  @override
  String get outOfHintsToast => 'You have used all free Hints for today!';

  @override
  String gameInstruction(int current, int max) {
    return 'Moves: $current / $max • Sort all balls by color';
  }

  @override
  String tubesSolvedProgress(int completed, int total) {
    return '$completed / $total Solved';
  }

  @override
  String get hintAlreadyCompleted => 'Level already completed!';

  @override
  String get hintNoMoveFound => 'No helpful moves found. Try Undo or Restart!';

  @override
  String get victoryTitle => 'EXPERIMENT COMPLETE!';

  @override
  String get milestoneReached => 'MILESTONE REACHED!';

  @override
  String levelMastered(int levelId) {
    return 'Level $levelId Mastered';
  }

  @override
  String get victoryPerfect => 'PERFECT SORTING!';

  @override
  String get victoryExcellent => 'EXCELLENT LAB WORK!';

  @override
  String get victoryGood => 'EXPERIMENT SOLVED!';

  @override
  String get movesTakenLabel => 'MOVES TAKEN';

  @override
  String get parMovesLabel => 'PAR MOVES';

  @override
  String starThresholds(int threeStar, int twoStar) {
    return '3★: ≤$threeStar moves  •  2★: ≤$twoStar moves';
  }

  @override
  String get newBestRecord => '✨ NEW BEST RECORD!';

  @override
  String get buttonPlayAgain => 'Play Again';

  @override
  String get buttonNextLevel => 'Next Level';

  @override
  String get buttonReturnToMap => 'Return to Map';

  @override
  String get defeatTitle => 'OUT OF MOVES!';

  @override
  String levelIncomplete(int levelId) {
    return 'Level $levelId Incomplete';
  }

  @override
  String defeatMessage(int maxMoves) {
    return 'You have used all $maxMoves allowed moves for this experiment. Re-calibrate your strategy and try again!';
  }

  @override
  String get movesUsedLabel => 'MOVES USED';

  @override
  String get maxLimitLabel => 'MAX LIMIT';

  @override
  String get outOfLivesTitle => 'OUT OF LIVES';

  @override
  String get outOfLivesMessage =>
      'You have used all 3 free daily experiment attempts.\nYour lives replenish every midnight (00:00 VN).';

  @override
  String get nextFreeRefillIn => 'NEXT FREE REFILL IN';

  @override
  String get watchVideoOption => 'Watch Lab Video (+1 Life)';

  @override
  String get comingSoonTag => 'COMING SOON';

  @override
  String get instantRefillOption => 'Instant Lab Energy Refill';

  @override
  String get buttonBackToMap => 'BACK TO MAP';

  @override
  String get mapTitle => 'BALL LAB JOURNEY';

  @override
  String get mapSubtitle => 'Select a puzzle experiment';

  @override
  String get previousChapterTooltip => 'Previous chapter';

  @override
  String get nextChapterTooltip => 'Next chapter';

  @override
  String chapterIndicator(int current, int total) {
    return 'CHAPTER $current / $total';
  }

  @override
  String chapterProgress(int start, int end, int stars, int maxStars) {
    return 'Level $start – $end  •  ⭐ $stars/$maxStars';
  }

  @override
  String activeLevelShort(int levelId) {
    return 'Lv $levelId';
  }

  @override
  String get selectChapterTitle => 'SELECT CHAPTER';

  @override
  String chapterPickerSummary(int chapters, int levels) {
    return '$chapters Chapters  •  $levels Levels';
  }

  @override
  String chapterItemTitle(int number) {
    return 'Chapter $number';
  }

  @override
  String get nodePlay => 'PLAY';

  @override
  String get bossBadge => 'BOSS';

  @override
  String get milestoneLevelDesc =>
      'High-difficulty Laboratory Milestone challenge';

  @override
  String get normalLevelDesc => 'Color segregation experiment';

  @override
  String get statColors => 'COLORS';

  @override
  String get statTubes => 'TUBES';

  @override
  String get statMaxMoves => 'MAX MOVES';

  @override
  String get statBestRun => 'BEST RUN';

  @override
  String get statNone => 'None';

  @override
  String movesUnit(int moves) {
    return '$moves moves';
  }

  @override
  String starCondition(int moves) {
    return '≤ $moves moves';
  }

  @override
  String get buttonStartExperiment => 'START EXPERIMENT';

  @override
  String levelLockedToast(int levelId) {
    return 'Complete Level $levelId to unlock this experiment!';
  }

  @override
  String get actionHintAd => 'Hint (+1 Ad)';

  @override
  String get adDailyLimitReachedTag => '3/3 CLAIMED';

  @override
  String get adDailyLimitReachedToast =>
      'You have reached the daily limit of 3 rewarded lives. Please return tomorrow!';

  @override
  String get adFailedMessage =>
      'Ad could not be loaded. Please check your network connection.';

  @override
  String get adNotReadyMessage =>
      'Ad is loading. Please try again in a moment.';

  @override
  String get adRewardGrantedToast => 'Hint unlocked from ad!';

  @override
  String get adRewardHintDialogCancel => 'Not Now';

  @override
  String get adRewardHintDialogConfirm => 'Watch Ad';

  @override
  String get adRewardHintDialogMessage =>
      'Watch a short video ad to reveal the next best move.';

  @override
  String get adRewardHintDialogTitle => 'Need a Hint?';

  @override
  String get adRewardLifeGrantedToast => 'Life replenished (+1 Life)!';
}
