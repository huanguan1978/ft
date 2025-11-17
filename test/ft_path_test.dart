import 'dart:io';

import 'package:filetools/ft.dart';
import 'package:test/test.dart';

import 'package:path/path.dart' as p;

/// A group, Platform-Specific Methods
void main() {
  group('A group of file path tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('pathderoot test', () {
      final windowsItems = [
        (40, r'D:\MyProjects', r'D_\MyProjects'),
        (41, r'D:\MyProjects\README.md', r'D_\MyProjects\README.md'),
      ];
      final unixlikeItems = [
        (1, r'/Users/kaguya/.zshrc', 'Users/kaguya/.zshrc'),
        (1, r'/Users/kaguya/Desktop', 'Users/kaguya/Desktop'),
      ];

      var items = isWindows ? windowsItems : unixlikeItems;
      for (var item in items) {
        expect(pathderoot(item.$2), equals(item.$3),
            reason: item.$1.toString());
      }
    });

    test('expandTilde test', () {
      final Map<String, String> env = {
        'HOME': environ['HOME'] ?? 'NoSetHome', // r'/Users/kaguya',
        'USERPROFILE':
            environ['USERPROFILE'] ?? 'NoSetHome', // r'C:\Users\TestUser',
      };

      final windowsItems = [
        (40, r'%USERPROFILE%\Documents', env["USERPROFILE"]! + r'\Documents'),
      ];
      final unixlikeItems = [
        (1, r'~/Documents', env["HOME"]! + r'/Documents'),
        (2, r'~/Downloads', env["HOME"]! + r'/Downloads'),
      ];

      var items = isWindows ? windowsItems : unixlikeItems;
      for (var item in items) {
        expect(expandTilde(item.$2), equals(item.$3),
            reason: item.$1.toString());
      }
    });

    test('compressTilde test', () {
      final Map<String, String> env = {
        'HOME': environ['HOME'] ?? 'NoSetHome', // r'/Users/kaguya',
        'USERPROFILE':
            environ['USERPROFILE'] ?? 'NoSetHome', // r'C:\Users\TestUser',
      };

      final windowsItems = [
        (40, r'%USERPROFILE%\Documents', env["USERPROFILE"]! + r'\Documents'),
      ];
      final unixlikeItems = [
        (1, r'~/Documents', env["HOME"]! + r'/Documents'),
        (2, r'~/Downloads', env["HOME"]! + r'/Downloads'),
      ];

      var items = isWindows ? windowsItems : unixlikeItems;
      for (var item in items) {
        expect(compressTilde(item.$3), equals(item.$2),
            reason: item.$1.toString());
      }
    });

    test('expandDotPath test', () {
      final currPath = p.current;
      final items = [
        (1, r'.gitignore', p.join(currPath, '.gitignore')),
        (2, r'.', currPath),
        (3, r'./README.md', p.join(currPath, 'README.md')),
        (4, r'..', p.canonicalize(p.join(currPath, '..'))),
      ];

      for (var item in items) {
        final dstPath = isWindows ? item.$3.toLowerCase : item.$3;
        expect(expandDotPath(item.$2), equals(dstPath),
            reason: item.$1.toString());
      }
    });

    test('expandVar test', () {
      final Map<String, String> env = {
        'HOME': environ['HOME'] ?? 'NoSetHome', // r'/Users/kaguya',
        'USERPROFILE':
            environ['USERPROFILE'] ?? 'NoSetHome', // r'C:\Users\TestUser',
        'DS_STORE': r'**.DS_Store',
      };

      final items = [
        (1, r'$HOME/Documents', env["HOME"]! + r'/Documents'),
        (2, r'${HOME}/Documents', env["HOME"]! + r'/Documents'),
        (3, r'$HOME/Documents/$ABC_', env["HOME"]! + r'/Documents/$ABC_'),
        (4, r'%USERPROFILE%\Documents', env["USERPROFILE"]! + r'\Documents'),
        (5, r'${DS_STORE}', env['DS_STORE']!),
      ];

      for (var item in items) {
        expect(expandVar(item.$2, map: env), equals(item.$3),
            reason: item.$1.toString());
      }
    });

    test('expandVar test timeago', () {
      Map<String, String> env = {};

      final exists = [
        (1, r'$HOME/Documents/$AGODATE1DAY', 'AGODATE', '1 DAY', true),
        (2, r'$HOME/Documents/$AGODATE1WEEK', 'AGODATE', '1 WEEK', true),
        (3, r'$HOME/Documents/$AGODATE1MONTH', 'AGODATE', '1 MONTH', true),
        (4, r'$HOME/Documents/$AGODATE1YEAR', 'AGODATE', '1 YEAR', true),
        (5, r'$HOME/$AGODATETIME5MINUTES', 'AGODATETIME', '5 MINUTES', true),
        (6, r'$HOME/$AGODATETIME2HOURS', 'AGODATETIME', '2 HOURS', true),
        (7, r'${HOME}/Documents', 'NOTHING', '0 DAY', false),
        (8, r'$HOME/$CURDATE/$CURDATETIME', 'NOTHING', '0 DAY', false),
      ];

      for (var exist in exists) {
        final path = expandVar(exist.$2, map: env);
        final agot = valueAgoInput(exist.$3, exist.$4);
        // print(path);
        if (agot.isEmpty) {
          expect(false, equals(exist.$5), reason: exist.$1.toString());
        } else {
          expect(path.contains(agot), equals(exist.$5),
              reason: exist.$1.toString());
        }
      }
    });

    // end group
  });

  /// B group, Platform-Agnostic Methods
  group('B group of path tail tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('tails test', () {
      var tails02 = tails(<String>[], 0);
      expect(tails02, isEmpty);
      var tails03 = tails(<String>[], 1);
      expect(tails03, isEmpty);

      var paths = p.split('~/Downloads/ft/README.md');
      var tails01 = tails(paths, 0);
      expect(tails01, isEmpty);

      var tails11 = tails(paths, 1);
      expect(tails11, containsAllInOrder(['README.md']));
      var tails12 = tails(paths, 2);
      expect(tails12, containsAllInOrder(['ft', 'README.md']));

      var tails20 = tails(paths, 20); // out range
      expect(tails20, containsAllInOrder(paths));
    });

    test('pathtail test', () {
      var tails02 = pathtail('', 0);
      expect(tails02, isEmpty);
      var tails03 = pathtail('', 1);
      expect(tails03, isEmpty);

      var path = '~/Downloads/ft/README.md';

      var tails01 = pathtail(path, 0);
      expect(tails01, isEmpty);

      var tail11 = pathtail(path, 1);
      expect(tail11, equals('README.md'));
      var tail12 = pathtail(path, 2);
      expect(tail12, equals(pathjoin('ft', 'README.md')));

      var tails20 = pathtail(path, 20); // out range
      expect(tails20, equals(pathjoin('~', 'Downloads', 'ft', 'README.md')));
    });

    // end group
  });

  /// other
  group('C group of glob match tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('isMatchGlob test', () {
      var src = './example/ft_example.dart';
      var pattern = r'**.dart'; // startwith r'**' is _patternCanMatchRelative
      var matched = isMatchGlob(pattern, src);
      expect(matched, isTrue);

      src = '/Users/kaguya/Downloads/ft/.gitignore';
      pattern = r'.**';
      matched = isMatchGlob(pattern, src);
      expect(matched, isTrue);

      // match absolute path with root
      if (Platform.isWindows) {
        src = r'C:\Users\14714\Desktop\git-bash.lnk';
        pattern = r'?:/**/*.lnk'; // r'C:/**/*.lnk';
        matched = isMatchGlob(pattern, src);
        expect(matched, isTrue);
      } else {
        src = '/Users/kaguya/Downloads/ft/example/ft_example.dart';
        pattern =
            r'/**/example/**'; // startwith r'/**' is _patternCanMatchAbsolute
        matched = isMatchGlob(pattern, src);
        expect(matched, isTrue);
      }
    });

    // end group
  });

// end main
}
