// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Ball Lab Puzzle';

  @override
  String get backTooltip => 'Quay lại';

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
    return 'LƯỢT CÒN LẠI: $count';
  }

  @override
  String get actionRestart => 'Chơi lại';

  @override
  String actionUndo(int count) {
    return 'Hoàn tác ($count)';
  }

  @override
  String get actionUndoSimple => 'Hoàn tác';

  @override
  String actionHint(int count) {
    return 'Gợi ý ($count)';
  }

  @override
  String get outOfUndosToast => 'Bạn đã hết lượt Hoàn tác miễn phí hôm nay!';

  @override
  String get outOfHintsToast => 'Bạn đã hết lượt Gợi ý miễn phí hôm nay!';

  @override
  String gameInstruction(int current, int max) {
    return 'Lượt: $current / $max • Phân loại bóng theo màu';
  }

  @override
  String tubesSolvedProgress(int completed, int total) {
    return 'Đã hoàn thành $completed / $total';
  }

  @override
  String get hintAlreadyCompleted => 'Màn chơi đã hoàn thành!';

  @override
  String get hintNoMoveFound =>
      'Không tìm thấy nước đi phù hợp. Hãy thử Hoàn tác hoặc Chơi lại!';

  @override
  String get victoryTitle => 'THÍ NGHIỆM THÀNH CÔNG!';

  @override
  String get milestoneReached => 'ĐẠT CỘT MỐC ĐẶC BIỆT!';

  @override
  String levelMastered(int levelId) {
    return 'Đã chinh phục Level $levelId';
  }

  @override
  String get victoryPerfect => 'PHÂN LOẠI HOÀN HẢO!';

  @override
  String get victoryExcellent => 'KẾT QUẢ XUẤT SẮC!';

  @override
  String get victoryGood => 'HOÀN THÀNH THÍ NGHIỆM!';

  @override
  String get movesTakenLabel => 'SỐ LƯỢT ĐI';

  @override
  String get parMovesLabel => 'LƯỢT TỐI ƯU';

  @override
  String starThresholds(int threeStar, int twoStar) {
    return '3★: ≤$threeStar lượt  •  2★: ≤$twoStar lượt';
  }

  @override
  String get newBestRecord => '✨ KỶ LỤC MỚI!';

  @override
  String get buttonPlayAgain => 'Chơi lại';

  @override
  String get buttonNextLevel => 'Màn tiếp theo';

  @override
  String get buttonReturnToMap => 'Về bản đồ';

  @override
  String get defeatTitle => 'HẾT LƯỢT ĐI!';

  @override
  String levelIncomplete(int levelId) {
    return 'Chưa hoàn thành Level $levelId';
  }

  @override
  String defeatMessage(int maxMoves) {
    return 'Bạn đã sử dụng hết $maxMoves lượt cho thí nghiệm này. Hãy điều chỉnh chiến thuật và thử lại!';
  }

  @override
  String get movesUsedLabel => 'LƯỢT ĐÃ DÙNG';

  @override
  String get maxLimitLabel => 'GIỚI HẠN TỐI ĐA';

  @override
  String get outOfLivesTitle => 'HẾT MẠNG CHƠI';

  @override
  String get outOfLivesMessage =>
      'Bạn đã sử dụng hết 3 lượt chơi miễn phí hôm nay.\nSố mạng sẽ hồi phục vào nửa đêm (00:00 VN).';

  @override
  String get nextFreeRefillIn => 'HỒI PHỤC MIỄN PHÍ SAU';

  @override
  String get watchVideoOption => 'Xem video (+1 Mạng)';

  @override
  String get comingSoonTag => 'SẮP RA MẮT';

  @override
  String get instantRefillOption => 'Hồi phục năng lượng ngay';

  @override
  String get buttonBackToMap => 'VỀ BẢN ĐỒ';

  @override
  String get mapTitle => 'HÀNH TRÌNH BALL LAB';

  @override
  String get mapSubtitle => 'Chọn thí nghiệm giải đố';

  @override
  String get previousChapterTooltip => 'Chặng trước';

  @override
  String get nextChapterTooltip => 'Chặng tiếp theo';

  @override
  String chapterIndicator(int current, int total) {
    return 'CHẶNG $current / $total';
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
  String get selectChapterTitle => 'CHỌN CHẶNG THÍ NGHIỆM';

  @override
  String chapterPickerSummary(int chapters, int levels) {
    return '$chapters Chặng  •  $levels Level';
  }

  @override
  String chapterItemTitle(int number) {
    return 'Chặng $number';
  }

  @override
  String get nodePlay => 'CHƠI';

  @override
  String get bossBadge => 'BOSS';

  @override
  String get milestoneLevelDesc => 'Thử thách cột mốc đặc biệt độ khó cao';

  @override
  String get normalLevelDesc => 'Thí nghiệm phân loại màu sắc';

  @override
  String get statColors => 'SỐ MÀU';

  @override
  String get statTubes => 'SỐ ỐNG';

  @override
  String get statMaxMoves => 'GIỚI HẠN LƯỢT';

  @override
  String get statBestRun => 'KỶ LỤC';

  @override
  String get statNone => 'Chưa có';

  @override
  String movesUnit(int moves) {
    return '$moves lượt';
  }

  @override
  String starCondition(int moves) {
    return '≤ $moves lượt';
  }

  @override
  String get buttonStartExperiment => 'BẮT ĐẦU THÍ NGHIỆM';

  @override
  String levelLockedToast(int levelId) {
    return 'Hoàn thành Level $levelId để mở khóa thí nghiệm này!';
  }

  @override
  String get actionHintAd => 'Gợi ý (+1 QC)';

  @override
  String get adDailyLimitReachedTag => '3/3 ĐÃ NHẬN';

  @override
  String get adDailyLimitReachedToast =>
      'Bạn đã nhận tối đa 3 mạng thưởng hôm nay. Vui lòng quay lại vào ngày mai!';

  @override
  String get adFailedMessage =>
      'Không thể tải quảng cáo. Vui lòng kiểm tra kết nối mạng.';

  @override
  String get adNotReadyMessage =>
      'Quảng cáo đang tải. Vui lòng thử lại sau giây lát.';

  @override
  String get adRewardGrantedToast => 'Đã mở khóa 1 gợi ý từ quảng cáo!';

  @override
  String get adRewardHintDialogCancel => 'Để sau';

  @override
  String get adRewardHintDialogConfirm => 'Xem quảng cáo';

  @override
  String get adRewardHintDialogMessage =>
      'Xem một đoạn quảng cáo ngắn để nhận gợi ý nước đi tiếp theo.';

  @override
  String get adRewardHintDialogTitle => 'Nhận thêm Gợi ý?';

  @override
  String get adRewardLifeGrantedToast => 'Đã nhận thêm 1 mạng từ quảng cáo!';
}
