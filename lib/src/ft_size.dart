part of '../ft.dart';

/// match a human-readable file size
RegExp regexSizeInput =
    RegExp(r'^(\d+(\.\d+)?)\s*([KMGTBP]?)B?$', caseSensitive: false);

const int sizeKB = 1024;
const int sizeMB = sizeKB * 1024;
const int sizeGB = sizeMB * 1024;
const int sizeTB = sizeGB * 1024;
const int sizePB = sizeTB * 1024;

/// Converts a file size in bytes to a human-readable format (e.g., KB, MB, GB).
///
/// ```dart
/// // 30: '30B', 5300: '5.2K', 2621440: '2.5M', 12884901888: '12.0G', 1099511627776: '1.0T', 1234567890123456: '1.1P',
/// print(humanReadableSize(30));   //  30B
/// print(humanReadableSize(5300)); // 5.2K
/// print(humanReadableSize(2621440)); // 2.5M
/// ```
String humanReadableSize(int sizeInBytes) {
  if (sizeInBytes < sizeKB) {
    return '${sizeInBytes}B';
  } else if (sizeInBytes < sizeMB) {
    return '${(sizeInBytes / sizeKB).toStringAsFixed(1)}K';
  } else if (sizeInBytes < sizeGB) {
    return '${(sizeInBytes / sizeMB).toStringAsFixed(1)}M';
  } else if (sizeInBytes < sizeTB) {
    return '${(sizeInBytes / sizeGB).toStringAsFixed(1)}G';
  } else if (sizeInBytes < sizePB) {
    return '${(sizeInBytes / sizeTB).toStringAsFixed(1)}T';
  } else {
    return '${(sizeInBytes / sizePB).toStringAsFixed(1)}P'; // or more
  }
}

/// Convert file [sizes] to human-readable format
///
/// ```dart
/// print(hrSizes([30, 5300, 2621440])); // ['30B', '5.2K', '2.5M']
/// ```
List<String> hrSizes(List<int> sizes) =>
    sizes.map((e) => humanReadableSize(e)).toList();

/// Split a human-readable file size to (value, unit)
///
/// ```dart
/// print(splitHumanReadableSize('30'));    // (30.0, 'B')
/// print(splitHumanReadableSize('30B'));   // (30.0, 'B')
/// print(splitHumanReadableSize('1m'));    // (1.0, 'M')
/// print(splitHumanReadableSize('2.5M'));  // (2.5, 'M')
/// print(splitHumanReadableSize('5.5MB')); // (5.5, 'M')
/// ```
(double, String)? splitHumanReadableSize(String humanSize) {
  // KiB->KB; ?iB->?B
  if (humanSize.contains(r'i')) {
    humanSize = humanSize.replaceFirst(r'i', r'');
  }

  final Match? match = regexSizeInput.firstMatch(humanSize.trim());
  if (match == null) return null; // Invalid format

  final double value = double.parse(match.group(1)!);
  String? unit = match.group(3)?.toUpperCase();
  if (unit == null || unit.isEmpty) unit = 'B';
  return (value, unit);
}

/// Parse a human-readable file size (e.g., KB, MB, GB) to bytes.
///
/// ```dart
/// // '10': 10, '30B': 30, '1.0K': 1024, '2.0KB': 2048, '4.0KiB': 4096, '1.5 K': 1536, '1024 KB': 1048576, '2.0M': 2097152, '3.1G': 3328599654, '4.2T': 4617948836659, '5.3P': 5967269506265907,
/// print(parseHumanReadableSize('1K')); // 1024
/// print(parseHumanReadableSize('2.0KB')); // 2048
/// print(parseHumanReadableSize('2.0M'));  // 2097152
/// ```
int? parseHumanReadableSize(String humanSize) {
  final splitSize = splitHumanReadableSize(humanSize);
  if (splitSize == null) return null; // Invalid format
  final (value, unit) = splitSize;
  return switch (unit) {
    'B' => value.toInt(),
    'K' => (value * sizeKB).toInt(),
    'M' => (value * sizeMB).toInt(),
    'G' => (value * sizeGB).toInt(),
    'T' => (value * sizeTB).toInt(),
    'P' => (value * sizePB).toInt(),
    _ => null // Invalid suffix
  };
}

/// Check a file size [value] within a specified range [min, max].
///
/// ```dart
/// print(isInSizes(5)); // false (no range defined)
/// print(isInSizes(5, min: 3, max: 7)); // true (within range)
/// print(isInSizes(2, min: 3, max: 7)); // false (not within range)
/// print(isInSizes(5, min: 3)); // true (greater than or equal to min)
/// print(isInSizes(2, min: 3)); // false (not greater than or equal to min)
/// print(isInSizes(5, max: 7)); // true (less than or equal to max)
/// print(isInSizes(8, max: 7)); // false (not less than or equal to max)
/// ```
bool isInSizes(int value, {int? min, int? max}) {
  // Condition 1: No range defined
  if (min == null && max == null) return false;
  // Condition 2: Within range
  if (min != null && max != null) return value >= min && value <= max;
  // Condition 3: Greater than or equal to min
  if (min != null) return value >= min;
  // Condition 4: Less than or equal to max
  return value <= max!; // max != null
}
