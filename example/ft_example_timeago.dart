import 'package:filetools/ft.dart';

void main() {
  // formatAgo();
  // parseAgo();
  example1();
}

void parseAgo() {
  String timeString1 = "5 minutes ago";
  String timeString2 = "3 days ago";
  String timeString3 = "1 year ago";
  String timeString4 = "2 hours";
  String timeString5 = "invalid input";
  String timeString6 = "7 weeks";
  String timeString7 = "2 seconds ago";
  String timeString8 = "10 months ago";

  List<String> testStrings = [
    timeString1,
    timeString2,
    timeString3,
    timeString4,
    timeString5,
    timeString6,
    timeString7,
    timeString8
  ];

  for (String s in testStrings) {
    print("Parsing: '$s'");
    final parsedTime = TimeAgoParser.parse(s);

    if (parsedTime != null) {
      if (parsedTime.unit != TimeUnit.unknown) {
        print('  Value: ${parsedTime.value}');
        print('  Unit: ${parsedTime.unit.toShortString()}');
        print('  Full representation: ${parsedTime.toString()}');

        try {
          final dartDuration = parsedTime.toDuration();
          print('  As Duration (approx): $dartDuration');

          final pastDateTime = parsedTime.toDateTime();
          print('  Past DateTime: ${pastDateTime.toIso8601String()}');
        } catch (e) {
          print('  Error converting to Duration/DateTime: $e');
        }
      } else {
        print('  Parsed but unit is unknown.');
      }
    } else {
      print('  Could not parse string.');
    }
    print('---');
  }
}

void formatAgo() {
// 当前时间
  final now = DateTime.now();

  print("Time Ago Examples:");
  print("5 minutes ago: ${formatTimeAgo(now.subtract(Duration(minutes: 5)))}");
  print("3 days ago: ${formatTimeAgo(now.subtract(Duration(days: 3)))}");
  print("1 year ago: ${formatTimeAgo(now.subtract(Duration(days: 365 + 10)))}");
  print("2 hours ago: ${formatTimeAgo(now.subtract(Duration(hours: 2)))}");
  print(
      "2 seconds ago: ${formatTimeAgo(now.subtract(Duration(seconds: 2)))}"); // Expect "1 minute ago"
  print(
      "45 seconds ago: ${formatTimeAgo(now.subtract(Duration(seconds: 45)))}"); // Expect "1 minute ago"
  print("7 weeks ago: ${formatTimeAgo(now.subtract(Duration(days: 7 * 7)))}");
  print(
      "10 months ago: ${formatTimeAgo(now.subtract(Duration(days: 30 * 10 + 5)))}");
  print(
      "just now: ${formatTimeAgo(now.subtract(Duration(milliseconds: 500)))}");

  print("\nFuture Time Examples:");
  print("in 10 minutes: ${formatTimeAgo(now.add(Duration(minutes: 10)))}");
  print("in 5 days: ${formatTimeAgo(now.add(Duration(days: 5)))}");
  print(
      "in 30 seconds: ${formatTimeAgo(now.add(Duration(seconds: 30)))}"); // Expect "in 1 minute"
  print(
      "just now (future): ${formatTimeAgo(now.add(Duration(milliseconds: 500)))}"); // Expect "just now"
  print(
      "in 2 months: ${formatTimeAgo(now.add(Duration(days: 30 * 2 + 5)))}"); // Expect "in 2 months"
  print(
      "in 1 year: ${formatTimeAgo(now.add(Duration(days: 365 + 20)))}"); // Expect "in 1 year"
  print("in 3 years: ${formatTimeAgo(now.add(Duration(days: 365 * 3 + 100)))}");
}

void example1() {
  final now = DateTime.now();
  print('now:$now');
// Use [formatTimeAgo] to convert a [DateTime] to a relative string (past/future)
  final ago5minutes = now.subtract(Duration(minutes: 5));
  final str5minutes = formatTimeAgo(ago5minutes);
  print(str5minutes); // 5 minutes ago

  final ago2hours = now.subtract(Duration(hours: 2));
  final str2hours = formatTimeAgo(ago2hours);
  print(str2hours); // 2 hours ago

  final ago1days = now.subtract(Duration(days: 1));
  final str1days = formatTimeAgo(ago1days);
  print(str1days); // 1 day ago

// Use [TimeAgoParser.parse] to convert a "time ago" string to a [TimeAgoDuration] object, then use its [toDateTime] method to get the [DateTime] object.
  final rst5minutes = TimeAgoParser.parse(str5minutes)?.toDateTime();
  print(rst5minutes);

  final rst2hours = TimeAgoParser.parse(str2hours)?.toDateTime();
  print(rst2hours);

  final rst1days = TimeAgoParser.parse(str1days)?.toDateTime();
  print(rst1days);
}
