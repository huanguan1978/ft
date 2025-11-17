import 'dart:io';

import 'package:filetools/ft.dart';
import 'package:test/test.dart';

/// A group, Platform-Specific Methods
void main() {
  group('A group of parse assign tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('parseAssigns test', () {
      List<String> environs = [
        'MEDIADIR=/media',
        'SESSDIR=/tmp/sess',
        'DEBUG=1',
        'TEST', // invalid
        'DBG=' // invalid
      ];

      final items = [
        (1, true, r'MEDIADIR', r'/media'),
        (2, true, r'SESSDIR', r'/tmp/sess'),
        (3, true, r'DEBUG', r'1'),
        (4, false, r'TEST', null),
        (5, true, r'DBG', r''),
      ];

      final envMap = parseAssigns(environs);
      // print(envMap);
      for (var item in items) {
        expect(envMap.containsKey(item.$3), item.$2 ? isTrue : isFalse,
            reason: item.$1.toString());
        if (item.$2) {
          expect(envMap[item.$3], equals(item.$4), reason: item.$1.toString());
        }
      }
    });

    test('parseCliAssigns 1 test', () {
      var items = [
        (1, 'set name=value', {'name': 'value'}),
        (
          2,
          'set name=box & set width=18 && set height=20',
          {'name': 'box', 'width': '18', 'height': '20'}
        ),
        (3, 'export name=value', {'name': 'value'}),
        (
          4,
          'export name=box;  export width=18; export height=20',
          {'name': 'box', 'width': '18', 'height': '20'}
        ),
      ];

      for (var item in items) {
        final id = item.$1;
        final cli = item.$2;
        final rst = item.$3;
        final map = parseCliAssigns(cli);
        // print(map);

        expect(map.keys, containsAll(rst.keys), reason: '$id test keys');
        expect(map.values, containsAll(rst.values), reason: '$id test values');
      }
    });

    test('parseCliAssigns 2 test', () {
      final items = [
        (
          1,
          r'export SESSDIR=/tmp/sess;DEBUG=1',
          {'SESSDIR': '/tmp/sess', 'DEBUG': '1'},
        ),
        (
          2,
          r'set SESSDIR=C:\tmp\sess&&DEBUG=1',
          {'SESSDIR': r'C:\tmp\sess', 'DEBUG': '1'},
        ),
        (
          3,
          r'ssh --port=2222 --identity-file=~/.ssh/my_priv_key user@192.168.1.100',
          {'--port': '2222', '--identity-file': '~/.ssh/my_priv_key'},
        ),
        (
          4,
          r'ssh user@192.168.1.100',
          {},
        ),
      ];

      for (var item in items) {
        final id = item.$1;
        final cli = item.$2;
        final rst = item.$3;
        final map = parseCliAssigns(cli);
        // print(map);

        expect(map.keys, containsAll(rst.keys), reason: '$id test keys');
        expect(map.values, containsAll(rst.values), reason: '$id test values');
      }
    });

    test('parseCliArgs test', () {
      final items = [
        (
          1,
          r'export SESSDIR=/tmp/sess;DEBUG=1',
          ['export', 'SESSDIR=/tmp/sess;DEBUG=1'],
        ),
        (
          2,
          r'set SESSDIR=C:\tmp\sess&&DEBUG=1',
          ['set', r'SESSDIR=C:\tmp\sess&&DEBUG=1'],
        ),
        (
          3,
          r'ssh --port=2222 --identity-file=~/.ssh/my_priv_key user@192.168.1.100',
          [
            'ssh',
            '--port=2222',
            '--identity-file=~/.ssh/my_priv_key',
            'user@192.168.1.100',
          ],
        ),
        (
          4,
          r'ssh user@192.168.1.100',
          ['ssh', 'user@192.168.1.100'],
        ),
        (
          5,
          r'ft search --pattern="**.yaml" --excludes="/**/.**" --source=~/Downloads --fields=ok,action,type,time,size --regexp="version: 1.0.\d+" -v',
          [
            'ft',
            'search',
            '--pattern=**.yaml',
            '--excludes=/**/.**',
            '--source=~/Downloads',
            '--fields=ok,action,type,time,size',
            r'--regexp=version: 1.0.\d+',
            '-v'
          ],
        ),
      ];

      for (var item in items) {
        final id = item.$1;
        final cli = item.$2;
        final rst = item.$3;
        final arr = parseCliArgs(cli);
        // print(arr);

        expect(arr, containsAll(rst), reason: '$id test elements');
      }
    });

    // end group
  });

  group('B group of util tests', () {
    late Directory tempDir;
    late File tempFile1;
    late File tempFile2;
    late bool isDirExist;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('my_test_dir_');
      isDirExist = true;

      tempFile1 = File('${tempDir.path}${Platform.pathSeparator}test_1.txt');
      tempFile1.writeAsStringSync('Hello from temporary file!');
      tempFile2 = File('${tempDir.path}${Platform.pathSeparator}test_2.txt');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('isDirEmpty Test', () {
      expect(isDirEmpty(tempDir), isFalse);
    });

    test('isDirWritable Test', () {
      expect(isDirWritable(tempDir, isDirExist: isDirExist), isTrue);
    });

    test('fileMirror Test', () {
      final newFile = fileMirror(tempFile1, tempFile2);

      final srcCrc64 = getCrc64(tempFile1.readAsBytesSync());
      final dstCrc64 = getCrc64(newFile.readAsBytesSync());

      expect(dstCrc64, equals(srcCrc64));
    });

    test('fileOverWrite Test', () {
      final ok = fileOverWrite(tempFile1, autoDelete: false);

      expect(ok, isTrue);
    });
    // end group
  });

// end main
}
