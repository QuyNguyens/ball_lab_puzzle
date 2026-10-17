import 'package:meta/meta.dart';

/// Contract providing current local time in Vietnam (`Asia/Ho_Chi_Minh`, UTC+7).
///
/// Abstracted to enable deterministic unit testing and future migration to
/// network/server time without modifying core game economy logic.
abstract interface class TimeService {
  /// Returns the current UTC DateTime.
  DateTime nowUtc();

  /// Returns current DateTime in Asia/Ho_Chi_Minh (UTC+7).
  DateTime nowVietnam();

  /// Returns the date string formatted as `YYYY-MM-DD` in Asia/Ho_Chi_Minh.
  String getVietnamDateString();

  /// Returns the next upcoming midnight (00:00:00) in Asia/Ho_Chi_Minh.
  DateTime getNextMidnightVietnam();

  /// Returns the duration remaining until the next upcoming midnight in Vietnam.
  Duration timeUntilNextMidnight();
}

/// Production implementation of [TimeService] calculating Vietnam time via UTC+7 offset.
@immutable
class VietnamTimeService implements TimeService {
  const VietnamTimeService();

  static const Duration _vietnamOffset = Duration(hours: 7);

  @override
  DateTime nowUtc() => DateTime.now().toUtc();

  @override
  DateTime nowVietnam() {
    return nowUtc().add(_vietnamOffset);
  }

  @override
  String getVietnamDateString() {
    final DateTime vn = nowVietnam();
    final String y = vn.year.toString().padLeft(4, '0');
    final String m = vn.month.toString().padLeft(2, '0');
    final String d = vn.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  DateTime getNextMidnightVietnam() {
    final DateTime vn = nowVietnam();
    final DateTime nextDay = DateTime.utc(vn.year, vn.month, vn.day + 1);
    return nextDay;
  }

  @override
  Duration timeUntilNextMidnight() {
    final DateTime vn = nowVietnam();
    final DateTime midnight = getNextMidnightVietnam();
    final Duration diff = midnight.difference(vn);
    return diff.isNegative ? Duration.zero : diff;
  }
}
