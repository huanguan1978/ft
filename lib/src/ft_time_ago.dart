/*
This file provides utilities for converting between DateTime objects
and human-friendly "time ago" strings (e.g., "5 minutes ago", "in 3 days").

- Formatting: Use RelativeTimeFormatter.formatTimeAgo to convert a DateTime
  to a relative string (past/future).
- Parsing: Use TimeAgoParser.parse to convert a "time ago" string
  to a TimeAgoDuration object, which can then yield a Duration or a
  calendar-aware past DateTime.
*/

part of '../ft.dart';

/// Supported time unit strings for parsing and validation.
const timeUnits = [
  'millisecond',
  'milliseconds',
  'second',
  'seconds',
  'minute',
  'minutes',
  'hour',
  'hours',
  'day',
  'days',
  'week',
  'weeks',
  'month',
  'months',
  'year',
  'years',
];

/// Regex to parse "N unit [ago]" strings (e.g., "5 minutes ago").
///
/// Captures the numeric value and the unit word, is case-insensitive.
final RegExp timeAgoRegExp =
    RegExp(r'^(\d+)\s+([a-zA-Z]+)(?:\s+ago)?$', caseSensitive: false);

/// Recognized time units for parsing "time ago" strings.
enum TimeUnit {
  milliseconds,
  seconds,
  minutes,
  hours,
  days,
  weeks,
  months,
  years,
  justnow,
  unknown,
}

/// Utility extension for [TimeUnit].
extension TimeUnitExtension on TimeUnit {
  /// Returns the lowercase string name of the unit (e.g., 'minutes').
  String toShortString() {
    return toString().split('.').last; // e.g. TimeUnit.minutes -> minutes
  }
}

/// Represents a parsed 'time ago' duration (value and unit).
class TimeAgoDuration {
  /// The numeric value (e.g., '5' in "5 minutes").
  final int value;

  /// The unit of time (e.g., [TimeUnit.minutes]).
  final TimeUnit unit;

  TimeAgoDuration(this.value, this.unit);

  /// Returns a string representation (e.g., '5 minutes').
  @override
  String toString() {
    return '$value ${unit.toShortString()}';
  }

  /// Converts to a Dart [Duration].
  ///
  /// Months (30d) and years (365d) are approximations. <br/>
  /// Throws if [unit] is unknown.
  Duration toDuration() {
    switch (unit) {
      case TimeUnit.milliseconds:
        return Duration(microseconds: value * 1000);
      case TimeUnit.seconds:
        return Duration(seconds: value);
      case TimeUnit.minutes:
        return Duration(minutes: value);
      case TimeUnit.hours:
        return Duration(hours: value);
      case TimeUnit.days:
        return Duration(days: value);
      case TimeUnit.weeks:
        return Duration(days: value * 7);
      case TimeUnit.months:
        return Duration(days: value * 30);
      case TimeUnit.years:
        return Duration(days: value * 365);
      case TimeUnit.justnow:
        return Duration.zero;
      case TimeUnit.unknown:
        throw Exception("Cannot convert unknown time unit to Duration.");
    }
  }

  /// Calculate a past [DateTime] relative to [DateTime.now()]. <br/>
  /// Months/years are calendar-aware. Throws if [unit] is unknown.
  DateTime toDateTime() {
    final now = DateTime.now();
    switch (unit) {
      case TimeUnit.milliseconds:
        return now.subtract(Duration(microseconds: value * 1000));
      case TimeUnit.seconds:
        return now.subtract(Duration(seconds: value));
      case TimeUnit.minutes:
        return now.subtract(Duration(minutes: value));
      case TimeUnit.hours:
        return now.subtract(Duration(hours: value));
      case TimeUnit.days:
        return now.subtract(Duration(days: value));
      case TimeUnit.weeks:
        return now.subtract(Duration(days: value * 7));
      case TimeUnit.months:
        return DateTime(now.year, now.month - value, now.day, now.hour,
            now.minute, now.second, now.millisecond, now.microsecond);
      case TimeUnit.years:
        return DateTime(now.year - value, now.month, now.day, now.hour,
            now.minute, now.second, now.millisecond, now.microsecond);
      case TimeUnit.justnow:
        return now;
      case TimeUnit.unknown:
        throw Exception("Cannot convert unknown time unit to DateTime.");
    }
  }
}

/// Utility for parsing 'time ago' strings into [TimeAgoDuration] objects.
class TimeAgoParser {
  /// Extracts `(value, unit)` from input using regex and basic validation. <br/>
  /// Returns `null` on failure.
  static (int, String)? _prepare(String input) {
    final match = timeAgoRegExp.firstMatch(input.trim().toLowerCase());
    if (match != null) {
      final [valueInput, unitInput] = match.groups([1, 2]);
      if (valueInput == null || unitInput == null) return null;

      final value = int.tryParse(valueInput);
      if (value == null) return null;
      if (!timeUnits.contains(unitInput)) return null;

      return (value, unitInput);
    }

    return null;
  }

  /// Parses a 'time ago' string (e.g., "5 minutes ago") into [TimeAgoDuration]. <br/>
  /// Handles "justnow", is case-insensitive. Returns `null` if parsing fails.
  static TimeAgoDuration? parse(String input) {
    if (input.trim().toLowerCase() == TimeUnit.justnow.name) {
      return TimeAgoDuration(0, TimeUnit.justnow);
    }

    final prepared = _prepare(input);
    if (prepared != null) {
      final (valueInput, unitInput) = prepared;

      TimeUnit timeUnit = switch (unitInput) {
        'millisecond' || 'milliseconds' => TimeUnit.milliseconds,
        'second' || 'seconds' => TimeUnit.seconds,
        'minute' || 'minutes' => TimeUnit.minutes,
        'hour' || 'hours' => TimeUnit.hours,
        'day' || 'days' => TimeUnit.days,
        'week' || 'weeks' => TimeUnit.weeks,
        'month' || 'months' => TimeUnit.months,
        'year' || 'years' => TimeUnit.years,
        'jastnow' => TimeUnit.justnow,
        _ => TimeUnit.unknown
      };
      return TimeAgoDuration(valueInput, timeUnit);
    }
    return null;
  }
}

// Formats a [DateTime] into a human-readable, relative time string (e.g., '5 minutes ago', 'in 3 days').
///
/// This function calculates the time difference between the provided [dateTime] and the current moment ([DateTime.now()])
/// and returns a string in an approximate, user-friendly format.
///
/// **Behavior for Past Times (ago):**
/// - Less than 1 second: "just now"
/// - 1-59 seconds: "1 minute ago" (per specified requirement)
/// - 1-59 minutes: "X minutes ago"
/// - 1-23 hours: "X hours ago"
/// - 1-6 days: "X days ago"
/// - 1-4 weeks (approx): "X weeks ago"
/// - 1-11 months (approx): "X months ago"
/// - 1+ years (approx): "X years ago"
///
/// **Behavior for Future Times (from now):**
/// - Less than 1 second: "just now"
/// - 1-59 seconds: "in 1 minute"
/// - 1-59 minutes: "in X minutes"
/// - 1-23 hours: "in X hours"
/// - 1-29 days: "in X days"
/// - 1-11 months (approx): "in X months"
/// - 1+ years (approx): "in X years"
///
/// Handles singular/plural forms for all units.
/// Approximations for weeks, months, and years are based on fixed day counts (7 days/week, 30 days/month, 365 days/year).
///
/// @param dateTime The specific point in time to format.
/// @return A string representing the relative time difference.
String formatTimeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  /// chopLastCharacter
  String chopLast(String text) =>
      text.isEmpty ? '' : text.substring(0, text.length - 1);

  /// format Future Times
  String fmtFutureTimes(int n, TimeUnit unit) => switch (unit) {
        TimeUnit.justnow => TimeUnit.justnow.name,
        TimeUnit.unknown => TimeUnit.unknown.name,
        _ => 'in $n ${(n > 1) ? unit.name : chopLast(unit.name)}'
      };

  /// format Future Times
  String fmtPastTimes(int n, TimeUnit unit) => switch (unit) {
        TimeUnit.justnow => TimeUnit.justnow.name,
        TimeUnit.unknown => TimeUnit.unknown.name,
        _ => '$n ${(n > 1) ? unit.name : chopLast(unit.name)} ago'
      };

  if (diff.isNegative) {
    // Handling future times
    final fDiff = dateTime.difference(now);

    if (fDiff.inSeconds == 0) {
      return fmtFutureTimes(0, TimeUnit.justnow);
    } else if (fDiff.inMinutes == 0) {
      return fmtFutureTimes(1, TimeUnit.minutes);
    } else if (fDiff.inMinutes < 60) {
      return fmtFutureTimes(fDiff.inMinutes, TimeUnit.minutes);
    } else if (fDiff.inHours < 24) {
      return fmtFutureTimes(fDiff.inHours, TimeUnit.hours);
    } else if (diff.inDays < 7) {
      return fmtFutureTimes(diff.inDays, TimeUnit.days);
    } else if (fDiff.inDays < 30) {
      int weeks = (diff.inDays / 7).round();
      if (weeks == 0) weeks = 1;
      return fmtFutureTimes(weeks, TimeUnit.weeks);
    } else if (fDiff.inDays < 365) {
      int months = (fDiff.inDays / 30).round();
      if (months == 0) months = 1;
      return fmtFutureTimes(months, TimeUnit.months);
    } else {
      int years = (fDiff.inDays / 365).round();
      if (years == 0) years = 1;
      return fmtFutureTimes(years, TimeUnit.years);
    }
  }

  // Handling past times
  if (diff.inMinutes == 0) {
    return (diff.inSeconds == 0)
        ? fmtPastTimes(0, TimeUnit.justnow)
        : fmtPastTimes(1, TimeUnit.minutes);
  } else if (diff.inMinutes < 60) {
    return fmtPastTimes(diff.inMinutes, TimeUnit.minutes);
  } else if (diff.inHours < 24) {
    return fmtPastTimes(diff.inHours, TimeUnit.hours);
  } else if (diff.inDays < 7) {
    return fmtPastTimes(diff.inDays, TimeUnit.days);
  } else if (diff.inDays < 30) {
    int weeks = (diff.inDays / 7).round();
    if (weeks == 0) weeks = 1;
    return fmtPastTimes(weeks, TimeUnit.weeks);
  } else if (diff.inDays < 365) {
    int months = (diff.inDays / 30).round();
    if (months == 0) months = 1;
    return fmtPastTimes(months, TimeUnit.months);
  } else {
    int years = (diff.inDays / 365).round();
    if (years == 0) years = 1;
    return fmtPastTimes(years, TimeUnit.years);
  }
}
