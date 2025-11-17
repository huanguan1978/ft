import 'package:filetools/ft.dart';
import 'package:test/test.dart';

import 'package:path/path.dart' as p;

/// A group, Platform-Specific Methods
void main() {
  /// other
  group('A group of file type tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('isTextMimeType test', () {
      var items = [
        (1, 'a.txt', true),
        (2, 'a.pdf', false),
        (3, 'a.js', true),
        (4, '.dev', false),
        (5, 'a.tml', true),
        (6, 'a.toml', true),
      ];

      doTextMimeInit();
      doTextMimeAdd('tml', 'text/toml');
      doTextMimeAdd('toml', 'text/toml');
      for (var item in items) {
        var id = item.$1;
        var aTest = isTextMimeType(item.$2);
        // print(id);
        expect(aTest, item.$3 ? isTrue : isFalse, reason: 'dbg, aType, $id');
      }
    });

    test('isAllowArchiveType test', () {
      var items = [
        (2, 'a', false),
        (3, 'a.tar', true),
        (4, 'a.tgz', true),
        (5, 'a.tar.gz', true),
        (6, 'a.tbz', false),
        (7, 'a/b/a.tgz', true),
        (8, 'a/b/c/c.tar', true),
      ];

      for (var item in items) {
        var id = item.$1;
        var aTest = isAllowArchiveType(item.$2);
        // print(id);
        expect(aTest, item.$3 ? isTrue : isFalse, reason: 'dbg, aType, $id');
      }
    });

    test('archiveName test', () {
      var items = [
        (1, 'a', null, 'a.tgz', ArchiveType.tgz),
        (2, 'a', ArchiveType.tgz, 'a.tgz', ArchiveType.tgz),
        (3, 'a.tar', ArchiveType.tar, 'a.tar', ArchiveType.tar),
        (4, 'a.tar', null, 'a.tar', ArchiveType.tar),
        (5, 'a.tar', ArchiveType.tgz, 'a.tar', ArchiveType.tar),
        (6, 'a.tbz', null, 'a.tgz', ArchiveType.tgz),
        (7, 'a/b', null, p.join('a', 'b.tgz'), ArchiveType.tgz),
        (8, 'a/b/c', null, p.join('a', 'b', 'c.tgz'), ArchiveType.tgz),
      ];

      for (var item in items) {
        var id = item.$1;
        var (aName, aType) = archiveName(item.$2, item.$3 ?? ArchiveType.tgz);
        // print(id);
        expect(aName, equals(item.$4), reason: 'dbg, aName, $id');
        expect(aType, equals(item.$5), reason: 'dbg, aType, $id');
      }
    });

    // end group
  });

// end main
}
