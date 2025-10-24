part of '../ft.dart';

const months_ = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];

/// Format a given DateTime object into a human-readable time string.
///
/// using **relative six-month timestamp formatting** (e.g., `MMM DD HH:MM` for recent dates, `MMM DD YYYY` for older dates)
/// ```dart
/// // 6 months ago, format MMM DD YYYY
/// print(humanReadableTime(DateTime.parse('2000-05-20 10:30:50'))); // May 20 2000
/// // less than 6 months, format MMM DD HH:MM
/// print(humanReadableTime(DateTime.parse('2037-05-20 10:30:50'))); // May 20 10:30
/// ```
String humanReadableTime(DateTime mtime, [List<String> months = months_]) {
  final mtimeLocal = mtime.toLocal();
  final now = DateTime.now().toLocal();

  // Approximate 6 months
  final sixMonthsAgo = now.subtract(const Duration(days: 180));
  final monthAbbr = months[mtimeLocal.month - 1];

  final fmtDay = mtimeLocal.day.toString().padLeft(2, '0');
  if (mtimeLocal.isAfter(sixMonthsAgo)) {
    final fmtHour = mtimeLocal.hour.toString().padLeft(2, '0');
    final fmtMinute = mtimeLocal.minute.toString().padLeft(2, '0');
    return '$monthAbbr $fmtDay $fmtHour:$fmtMinute';
  } else {
    final fmtYear = mtimeLocal.year.toString().padRight(5);
    return '$monthAbbr $fmtDay $fmtYear';
  }
}

/// Parse a human-readable time string
///
/// using **relative six-month timestamp formatting** (e.g., `MMM DD HH:MM` for recent dates, `MMM DD YYYY` for older dates)
/// ```dart
/// // 6 months ago, format MMM DD YYYY
/// print(parseHumanReadableTime('May 20 2000')); // 2000-05-20 00:00:00
/// // less than 6 months, format MMM DD HH:MM
/// print(parseHumanReadableTime('Dec 09 16:33')); // 2025-12-09 16:33:00 // now.year is 2025
/// ```
DateTime? parseHumanReadableTime(
  String humanTime, [
  List<String> months = months_,
]) {
  final parts = humanTime.trim().split(' ');
  if (parts.length != 3) return null; // Invalid format
  final [month_, day_, last_, ...] = parts;
  if (!months.contains(month_)) return null;
  final month = months.indexOf(month_) + 1;
  final day = int.tryParse(day_);
  if (day == null || day < 1 || day > 31) return null;

  // Format: "MMM DD YYYY" (e.g., "May 20 2000")
  if (!humanTime.contains(':')) {
    final year = int.tryParse(last_);
    if (year == null || year < 1) return null; // Invalid year
    return DateTime(year, month, day);
  }

  // Format: "MMM DD HH:MM" e.g., "May 20 10:30"
  final timeParts = last_.split(':');
  if (timeParts.length != 2) return null; // Invalid time format

  final hour = int.tryParse(timeParts.first);
  final minute = int.tryParse(timeParts.last);

  if (hour == null ||
      hour < 0 ||
      hour > 23 ||
      minute == null ||
      minute < 0 ||
      minute > 59) {
    return null; // Invalid hour or minute
  }

  final now = DateTime.now().toLocal();
  final mtime = DateTime(now.year, month, day, hour, minute);

  // Check if time is in the future
  final sixMonthsAgo = now.subtract(const Duration(days: 180));
  if (mtime.isBefore(sixMonthsAgo)) {
    return DateTime(now.year - 1, month, day, hour, minute);
  }

  return mtime;
}

/// Check a file time [value] within a specified range [min, max].
///
/// ```dart
/// DateTime now = DateTime.now();
/// DateTime yesterday = now.subtract(Duration(days: 1));
/// DateTime tomorrow = now.add(Duration(days: 1));
/// print(isInTimes(now)); // false (no range defined)
/// print(isInTimes(now, min: yesterday, max: tomorrow)); // true (within range)
/// print(isInTimes(yesterday, min: yesterday, max: tomorrow)); // true
/// print(isInTimes(tomorrow, min: yesterday, max: tomorrow)); // true
/// print(isInTimes(yesterday, min: now, max: tomorrow)); // false
/// print(isInTimes(now, min: yesterday)); // true (after or equal to min)
/// print(isInTimes(yesterday, min: now)); // false
/// print(isInTimes(now, max: tomorrow)); // true (before or equal to max)
/// print(isInTimes(tomorrow, max: tomorrow)); // true
/// print(isInTimes(tomorrow, max: yesterday)); // false
/// ```
bool isInTimes(DateTime value, {DateTime? min, DateTime? max}) {
  // Condition 1: No range defined
  if (min == null && max == null) return false;
  // Condition 2: Within range
  if (min != null && max != null) {
    return value.isAfter(min) && value.isBefore(max) ||
        value == min ||
        value == max;
  }
  // Condition 3: After or equal to min
  if (min != null) return value.isAfter(min) || value == min;
  // Condition 4: Before or equal to max
  return value.isBefore(max!) || value == max; // max != null
}
