import 'package:filetools/ft.dart';
import 'package:test/test.dart';

void main() {
  group('A group of human readable size tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('splitHumanReadableSize test', () {
      var items = [
        (1, '30', 'B', 30.0),
        (2, '40B', 'B', 40.0),
        (3, '1m', 'M', 1.0),
        (4, '2M', 'M', 2.0),
        (5, '5.5M', 'M', 5.5),
      ];

      for (var item in items) {
        var id = item.$1;
        var splitSize = splitHumanReadableSize(item.$2);
        if (splitSize != null) {
          var (aVal, aUnit) = splitSize;
          expect(aUnit, equals(item.$3), reason: 'dbg, aUnit, $id');
          expect(aVal, equals(item.$4), reason: 'dbg, aVal, $id');
        }
      }
    });

    test('humanReadableSize test', () {
      var result = {
        30: '30B',
        5300: '5.2K',
        2621440: '2.5M',
        12884901888: '12.0G',
        1099511627776: '1.0T',
        1234567890123456: '1.1P',
      };
      result.forEach((key, value) {
        expect(humanReadableSize(key), equals(value));
      });
    });

    test('parseHumanReadableSize test', () {
      var result = {
        10: '10', // 10B
        30: '30B',
        1024: '1.0K',
        2048: '2.0KB',
        4096: '4.0KiB',
        1536: '1.5 K',
        1048576: '1024 KB',
        2097152: '2.0M',
        3328599654: '3.1G',
        4617948836659: '4.2T',
        5967269506265907: '5.3P',
      };
      result.forEach((key, value) {
        expect(parseHumanReadableSize(value), equals(key));
      });
    });

    test('isInSizes test', () {
      expect(isInSizes(5), isFalse);
      expect(isInSizes(5, min: 3, max: 7), isTrue);
      expect(isInSizes(2, min: 3, max: 7), isFalse);
      expect(isInSizes(5, min: 3), isTrue);
      expect(isInSizes(2, min: 3), isFalse);
      expect(isInSizes(5, max: 7), isTrue);
      expect(isInSizes(8, max: 7), isFalse);
    });

    // end group
  });

// end main
}
