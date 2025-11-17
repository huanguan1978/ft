part of '../ft.dart';

/// Parses a list of `key=value` [assigns] strings into a Map. Skips invalid entries.
///
/// ```dart
/// final assigns =['SESSDIR=/tmp/sess', 'DEBUG=1', 'TEST', 'DBG='];
/// print(parseAssigns(assigns)); // {SESSDIR:/tmp/sess, DEBUG:1}
/// ```
Map<String, String> parseAssigns(List<String> assigns) {
  final map = <String, String>{};

  if (assigns.isNotEmpty) {
    for (var value in assigns) {
      if (value.contains(equalsignDelimiter)) {
        final parts = value.split(equalsignDelimiter);
        if (parts.length == 2) {
          map[parts[0].trim()] = parts[1].trim();
        }
      }
    }
  }
  return map;
}

/// Parses [cli] command arguments into a Map of key-value assignments
///
/// It extract the command name and then processes the arguments.
///
/// - `export` command: arguments are semicolon-separated.
/// - `set` command: arguments are ampersand-separated (`&&` handled).
/// - other commands: arguments are space-separated by default.
///
/// Invalid assignment entries are skipped.
/// ```dart
/// final ssh = r'ssh --port=2222 --identity-file=~/.ssh/my_priv_key user@192.168.1.100'
/// print(parseCliAssigns(ssh)); // {--prot: 2222, --identity-file: ~/.ssh/my_priv_key}
/// print(parseCliAssigns('export SESSDIR=/tmp/sess;DEBUG=1')); // {SESSDIR: /tmp/tmp, DEBUG: 1}
/// print(parseCliAssigns('set SESSDIR=C:\tmp\sess&&DEBUG=1')); // {SESSDIR: C:\tmp\sess, DEBUG: 1}
/// ```
Map<String, String> parseCliAssigns(String cli) {
  final assigns = <String>[];

  var exec = '';
  var args = cli.split(spaceDelimiter);
  if (args.isNotEmpty) {
    exec = args.removeAt(0);
    assigns.addAll(args);
  }

  if (exec == 'export') {
    if (cli.contains(semicolonDelimiter)) {
      cli = cli
          .replaceAll(semicolonDelimiter, spaceDelimiter)
          .replaceAll('export', spaceDelimiter);
    }
    args = cli.trimLeft().split(spaceDelimiter);
    assigns
      ..clear()
      ..addAll(args);
  }

  if (exec == 'set') {
    final lineDelimiter = r'&&';
    if (cli.contains(lineDelimiter)) {
      cli = cli
          .replaceAll(lineDelimiter, spaceDelimiter)
          .replaceAll('set', spaceDelimiter);
    }
    args = cli.trimLeft().split(spaceDelimiter);
    assigns
      ..clear()
      ..addAll(args);
  }

  return parseAssigns(assigns);
}

/// Parse a CLI [command] string into a list of its full arguments, including the command name itself.
///
/// Attempts to simulate basic shell argument parsing behavior, including handling single quotes, double quotes, and escape characters.
/// ```dart
/// final cmd = '''ft search --pattern="**.yaml" --excludes="/**/.**" --source=~/Downloads --fields=ok,action,type,time,size --regexp="version: 1.0.\d+" -v''';
/// print(parseCliCommand(cmd));
/// // [ft, search, --pattern=**.yaml, --excludes=/**/.**, --source=~/Downloads, --fields=ok,action,type,time,size, --regexp=version: 1.0.\d+, -v]
/// ```
List<String> parseCliArgs(String command, {bool isRawString = true}) {
  List<String> args = [];
  StringBuffer currentArg = StringBuffer();
  bool inDoubleQuote = false;
  bool inSingleQuote = false;
  bool escaped = false;

  for (int i = 0; i < command.length; i++) {
    String char = command[i];

    if (escaped) {
      currentArg.write(char);
      escaped = false;
    } else if (char == r'\') {
      escaped = true;
      if (isRawString) {
        escaped = false;
        currentArg.write(char);
      }
    } else if (char == r'"' && !inSingleQuote) {
      inDoubleQuote = !inDoubleQuote;
    } else if (char == r"'" && !inDoubleQuote) {
      inSingleQuote = !inSingleQuote;
    } else if (char == r' ' && !inDoubleQuote && !inSingleQuote) {
      if (currentArg.isNotEmpty) {
        args.add(currentArg.toString());
        currentArg.clear();
      }
    } else {
      currentArg.write(char);
    }
  }

  if (currentArg.isNotEmpty) {
    args.add(currentArg.toString());
  }

  return args;
}

/// Checks if a [path] matches a glob [pattern].
///
/// Uses `package:glob` syntax (e.g., `*`, `?`, `**`).
/// Returns `true` on match, `false` otherwise.
///
/// Example:
/// ```dart
/// var matched = isMatchGlob('*.txt', 'file.txt'); // true
/// print(matched); // true
/// matched = isMatchGlob(r'/**/example/**', expandTilde('~/Downloads/ft/example/ft_example.dart'));
/// print(matched); // true, // startwith r'/**' is _patternCanMatchAbsolute
/// matched = isMatchGlob(r'?:/**/*.lnk', r'C:\Users\kaguya\Desktop\git-bash.lnk');
/// print(matched); //true, // windows startwith r'?:/**' is _patternCanMatchAbsolute
/// matched = isMatchGlob(r'**.dart', './example/ft_example.dart'));
/// print(matched); // true, // startwith r'**' is _patternCanMatchRelative
/// ```
bool isMatchGlob(String pattern, String path) => Glob(pattern).matches(path);

/// Joins the given path parts into a single path using the current platform's
/// [separator]. Example:
///
///     p.join('path', 'to', 'foo'); // -> 'path/to/foo'
///
/// If any part ends in a path separator, then a redundant separator will not
/// be added:
///
///     p.join('path/', 'to', 'foo'); // -> 'path/to/foo'
///
/// If a part is an absolute path, then anything before that will be ignored:
///
///     p.join('path', '/to', 'foo'); // -> '/to/foo'
var pathjoin = p.join;

/*
/// Escape all special regular expression characters in the --regexp pattern.
String escapeRegExp(String input) {
  final specialChars = RegExp(r'[\.*+?^${}()|[\]\\]');
  return input.replaceAllMapped(specialChars, (Match match) {
    return r'\' + match.group(0)!;
  });
}
*/

/// Checks if a [directory] is empty synchronously.
///
/// An empty directory contains no files or subdirectories.
bool isDirEmpty(Directory directory, {bool? isDirExist}) {
  isDirExist ??= directory.existsSync();
  return isDirExist ? directory.listSync().isEmpty : false;
}

/// Checks if a [directory] is writable by the current process.
///
/// It attempts to create and then clean up a temporary subdirectory inside [directory]. <br/>
/// If [directory] does not exist, it's first created and deleted to test write permissions on its parent.
///
/// Returns `true` if writable, `false` otherwise (e.g., permission denied, invalid path).
bool isDirWritable(Directory directory, {bool? isDirExist}) {
  isDirExist ??= directory.existsSync();
  Directory? testDir;

  try {
    if (!isDirExist) {
      directory
        ..createSync(recursive: true)
        ..deleteSync();
      return true;
    }

    bool runing = true;
    while (runing) {
      final tempDirName = '._writable_test_${Random().nextInt(1000000)}';
      testDir = Directory('${directory.path}/$tempDirName');
      if (!testDir.existsSync()) {
        runing = false;
        testDir.createSync();
      }
    }

    return true;
  } catch (e) {
    return false;
  } finally {
    if (testDir != null && testDir.existsSync()) {
      try {
        testDir.deleteSync(recursive: true);
      } catch (e) {
        // print(e);
      }
    }
  }
}

/// Efficiently mirrors [srcFile] content to [dstFile], copying only if necessary.
///
/// Compares size, modification time, and CRC64 checksums. <br/>
/// Creates [dstFile] (and its parent directories) if it doesn't exist.
File fileMirror(File srcFile, File dstFile) {
  final newPath = dstFile.path;
  if (!dstFile.existsSync()) {
    dstFile.createSync(recursive: true);
    return srcFile.copySync(newPath);
  }

  if ((srcFile.lengthSync() != dstFile.lengthSync()) ||
      (srcFile.lastModifiedSync() != dstFile.lastModifiedSync())) {
    return srcFile.copySync(newPath);
  }

  final srcCrc64 = getCrc64(srcFile.readAsBytesSync());
  final dstCrc64 = getCrc64(dstFile.readAsBytesSync());
  if (srcCrc64 != dstCrc64) return srcFile.copySync(newPath);

  return dstFile;
}

// Define security levels for file overwrite.
enum FileWriteLevel { low, medium, high }

/// Overwrite the content of a [file] based on the specified [level] pattern.
///
/// I/O exceptions during the write operation are propagated to the caller. <br />
/// [level]: Fill content: `low` for zeros, `medium` for bits, `high` for random. Defaults to `medium`.
bool fileOverWrite(
  File file, {
  bool? isFileExist,
  FileWriteLevel level = FileWriteLevel.medium,
  bool autoDelete = true, // auto delete after save
}) {
  isFileExist ??= file.existsSync();
  if (!isFileExist) return false;

  final fileSize = file.lengthSync();
  final random = Random.secure();

  // fixed-length list
  List<int> buffer = switch (level) {
    FileWriteLevel.low => List<int>.filled(fileSize, 0),
    FileWriteLevel.medium => List<int>.generate(fileSize, (i) => i % 2),
    _ => List<int>.generate(fileSize, (i) => random.nextInt(256)),
  };

  file.writeAsBytesSync(buffer, flush: true);
  buffer = []; // use dart gc

  if (autoDelete) file.deleteSync();

  return true;
}
