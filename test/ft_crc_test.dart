import 'package:filetools/ft.dart';
import 'package:test/test.dart';

void main() {
  group('A group of crc tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('crc64 test', () {
      final text = 'hello world';
      final crc64s = getCrc64(text.codeUnits);
      // print(crc64s); // 5981764153023615706
      expect(crc64s, equals(5981764153023615706));
    });

    test('crc32 test', () {
      final text = 'hello world';
      final crc32s = getCrc32(text.codeUnits);
      // print(crc32s); // 222957957
      expect(crc32s, equals(222957957));
    });
    // end group
  });

  // end main
}
