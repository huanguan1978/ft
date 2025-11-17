import 'package:filetools/ft.dart';
import 'package:test/test.dart';

void main() {
  group('A group of human readable time tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('humanReadableTime test', () {
      var result = {
        '2037-05-20 10:30:50': 'May 20 10:30',
        '2000-05-20 10:30:50': 'May 20 2000',
      };
      result.forEach((key, value) {
        var mtime = DateTime.parse(key);
        expect(humanReadableTime(mtime).trim(), equals(value));
      });
    });

    test('parseHumanReadableTime test', () {
      // ignore: unused_local_variable
      var year = DateTime.now().year;
      var result = {
        // '$year-05-20T10:30:00': 'May 20 10:30', // i test time: 2025-04-12
        '2000-05-20T00:00:00': 'May 20 2000',
      };
      result.forEach((key, value) {
        var mtime = parseHumanReadableTime(value)!;
        var iso8601 = mtime.toIso8601String().split('.').first;

        expect(key, equals(iso8601));
      });
    });

    test('isInTimes test', () {
      DateTime now = DateTime.now();
      DateTime yesterday = now.subtract(Duration(days: 1));
      DateTime tomorrow = now.add(Duration(days: 1));

      expect(isInTimes(now), isFalse);
      expect(isInTimes(now, min: yesterday, max: tomorrow), isTrue);
      expect(isInTimes(yesterday, min: yesterday, max: tomorrow), isTrue);
      expect(isInTimes(tomorrow, min: yesterday, max: tomorrow), isTrue);
      expect(isInTimes(yesterday, min: now, max: tomorrow), isFalse);
      expect(isInTimes(now, min: yesterday), isTrue);
      expect(isInTimes(yesterday, min: now), isFalse);
      expect(isInTimes(now, max: tomorrow), isTrue);
      expect(isInTimes(tomorrow, max: tomorrow), isTrue);
      expect(isInTimes(tomorrow, max: yesterday), isFalse);
    });
    // end group
  });

// end main
}
