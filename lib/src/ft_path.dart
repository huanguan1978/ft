part of '../ft.dart';

/// match input variable, e.g. ${VAR}, $VAR, %VAR%.
final RegExp varInputRegexp = RegExp(r'(\$\{([\w]+)\}|\$([\w]+)|%([\w]+)%)');

/// match dynmaic variable, time ago.
final RegExp varTimeAgoRegexp =
    RegExp(r'^(agodatetime|agodate)(\d+)(.+)$', caseSensitive: false);

/// determine the user's home directory.
// final String homePath = environ['HOME'] ?? environ['USERPROFILE'] ?? '';
String get homePath => environ['HOME'] ?? environ['USERPROFILE'] ?? '';

/// define the platform-specific home directory pattern
final String homePattern = isWindows ? r'%USERPROFILE%' : r'~';

/// define the path to the user's Documents folder.
final String homePathDocuments = p.join(homePath, 'Documents');

/// define the path to the user's Downloads folder.
final String homePathDownloads = p.join(homePath, 'Downloads');

/// Get the last [n] elements from [lists].
///
/// ```dart
/// var paths = ['Downloads', 'ft', 'README.md'];
/// print(tail(paths, 0)); // []; empty list
/// print(tail(paths, 1)); // ['README.md']
/// print(tail(paths, 2)); // ['ft', 'README.md']
/// print(tail(paths, 3)); // ['Downloads', 'ft', 'README.md']
/// print(tail(paths, 4)); // ['Downloads', 'ft', 'README.md']
/// ```
List<T> tails<T>(List<T> lists, int n) {
  if (n < 0) throw ArgumentError('tail n must be non-negative');
  if (n == 0) return [];
  if (lists.isEmpty) return [];

  // Using max(0, ...) ensures that sublist start index is not negative
  // in case n is larger than lists.length, effectively returning the whole list.
  return lists.sublist(max(0, lists.length - n));
}

/// Get the last [n] segment of a [path].
///
/// ```dart
/// var path = '~/Downloads/ft/README.md';
/// print(pathtail(path, 0)); // ''; empty string
/// print(pathtail(path, 1)); // 'README.md'; last
/// print(pathtail(path, 2)); // 'ft/README.md'
/// print(pathtail(path, 3)); // 'Downloads/ft/README.md'
/// print(pathtail(path, 4)); // '~/Downloads/ft/README.md'
/// print(pathtail(path, 5)); // '~/Downloads/ft/README.md'
/// ```
String pathtail(String path, int n) =>
    (n <= 0 || path.isEmpty) ? '' : p.joinAll(tails(p.split(path), n));

/// DeRoot an absolute [path]
///
/// ```text
/// D:\MyProjects\dtst\bin -> D_\MyProjects\dtst\bin
/// D:\MyProjects\dtst\bin\dtst.dart -> D_\MyProjects\dtst\bin\dtst.d
/// /Users/kaguya/Downloads/ft -> Users/kaguya/Downloads/ft
/// /Users/kaguya/Downloads/ft/README.md -> Users/kaguya/Downloads/ft/README.md
/// ```
String pathderoot(String path) {
  if (p.isAbsolute(path)) {
    final root = p.rootPrefix(path);
    if (isWindows) {
      if (root.isNotEmpty) {
        final newRoot = root.replaceFirst(r':', r'_');
        path = path.replaceFirst(root, newRoot);
      }
    } else {
      path = path.replaceFirst(root, r'');
    }
  }
  return path;
}

/// expand tilde with [path]
///
///  assume the current user is 'kaguya'
/// - Windows
///   - %USERPROFILE%\Downloads\ft\README.md -> C:\Users\kaguya\Downloads\ft\README.md
/// - MacOS:
///   - ~/Downloads/ft/README.md -> /Users/kaguya/Downloads/ft/README.md;
/// - Linux:
///   - ~/Downloads/ft/README.md -> /home/kaguya/Downloads/ft/README.md;
/// ```
String expandTilde(String path) {
  if (homePath.isNotEmpty && path.startsWith(homePattern)) {
    if (path == homePattern) return homePath;
    final reslovePath =
        p.join(homePath, path.substring(homePattern.length + 1));
    return reslovePath;
  }
  return path;
}

/// compress tilde with [path]
///
///  assume the current user is 'kaguya'
/// - Windows
///   - C:\Users\kaguya\Downloads\ft\README.md -> %USERPROFILE%\Downloads\ft\README.md
/// - MacOS:
///   - /Users/kaguya/Downloads/ft/README.md -> ~/Downloads/ft/README.md
/// - Linux:
///   - /home/kaguya/Downloads/ft/README.md -> ~/Downloads/ft/README.md
/// ```
String compressTilde(String path) {
  if (homePath.isNotEmpty && p.isAbsolute(path) && path.startsWith(homePath)) {
    if (path == homePath) return homePattern;

    final reslovePath =
        p.join(homePattern, path.substring(homePath.length + 1));
    return reslovePath;
  }
  return path;
}

/// Expands a [path] that starts with '.' or '..' to an absolute path.
///
/// assume the current user is 'kaguya' and the current working directory is:
/// - Windows: `C:\Users\kaguya\Downloads\ft\`
/// - MacOS:   `/Users/kaguya/Downloads/ft/`
/// - Linux:   `/home/kaguya/Downloads/ft/`
///
/// expand `./README.md` is
/// - Windows: `C:\Users\kaguya\Downloads\ft\README.md`
/// - MacOS:   `/Users/kaguya/Downloads/ft/README.md`
/// - Linux:   `/home/kaguya/Downloads/ft/README.md`
///
/// expand `../ft.tgz` is
/// - Windows: `C:\Users\kaguya\Downloads\ft.tgz`
/// - MacOS:   `/Users/kaguya/Downloads/ft.tgz`
/// - Linux:   `/home/kaguya/Downloads/ft.tgz`
/// ```
String expandDotPath(String path) {
  if (!path.startsWith('.')) return path;

  String currPath = Directory.current.path;
  String absPath = p.canonicalize(p.join(currPath, path));

  return absPath;
}

/// expand variables in a string [path] using provided [map] collections and and built-in dynamic variable
///
/// Variables can be:
/// - **User-defined**: Enclosed in a specific format (e.g., "$name", "${name}", or "%name%"),
///   resolved from the [map].
/// - **Built-in dynamic**:
///   - `CURDIR`: Current directory.
///   - `CURDATE`, `CURDATETIME`: Current date/time (e.g., `20250829`, `20250829090226`).
///   - `AGODATE<N><UNIT>`, `AGODATETIME<N><UNIT>`:  \n
///      Relative dates/times (e.g., `AGODATE1DAY`, `AGODATETIME1WEEK`).
///      - `<N>` is a number,
///      - `<UNIT>` is a time unit (e.g., SECOND, MINUTE, HOUR, DAY, WEEK, MONTH, YEAR).
///
/// ```dart
/// // assume the current user is 'kaguya',
/// final env = Platform.environment;
/// print(expandVar(r'$HOME', map:env)); // macos: /Users/kaguya, linux: /home/kaguya
/// print(expandVar(r'%USERPROFILE%', map:env)); // windows: C:\Users\kaguya
/// // assume the current time is 2025-10-11 16:31:50
/// print(expandVar(r'$CURDATE'));      // 20251011
/// print(expandVar(r'$AGODATE1DAY'));  // 20251010
/// print(expandVar(r'$CURDATETIME'));  // 20251011163150
/// print(expandVar(r'$AGODATE1HOUR')); // 20251011153150
/// ```
String expandVar(String path, {Map<String, String> map = const {}}) {
  // if (map.isEmpty) map = environ;
  map = Map<String, String>.from(map);
  if (path.contains('CURDATE') || path.contains('CURDATETIME')) {
    final iso8601 = DateTime.now().toLocal().toIso8601String().split('.').first;
    var [date, time] = iso8601.split('T');
    date = date.replaceAll('-', '');
    time = time.replaceAll(':', '');
    map['CURDATE'] = date;
    map['CURDATETIME'] = '$date$time';
  }
  if (path.contains('CURDIR')) {
    map['CURDIR'] = Directory.current.path;
  }
  if (path.contains('AGODATE') || path.contains('AGODATETIME')) {
    final Map<String, String> mapping = {};
    final matches = varInputRegexp.allMatches(path);
    for (var match in matches) {
      String name = match[2] ?? match[3] ?? match[4] ?? '';
      if (name.isNotEmpty) {
        final m = varTimeAgoRegexp.firstMatch(name);
        if (m != null) {
          final [agoType, agoValue, agoUnit] = m.groups([1, 2, 3]);
          final value = valueAgoInput('$agoType', '$agoValue $agoUnit');
          mapping[name] = value.isEmpty ? name : value;
        }
      }
    }
    map.addAll(mapping);
  }

  return path.replaceAllMapped(
    varInputRegexp, // match ${VAR} OR $VAR
    (match) {
      String? name = match[2] ?? match[3] ?? match[4];
      if (name case String _ when map.containsKey(name)) return map[name]!;

      return match.group(0) ?? '';
    },
  );
}

/// value of dynamic variable time ago
/// sucess return YYYYMMDD|YYYYMMDDHHMMSS
/// ```dart
/// // now: 2025-08-26T13:15:56
/// print(valueAgoInput('AGODATE', '1 DAY')); // 20250825
/// print(valueAgoInput('AGODATE', '1 WEEK')); // 20250819
/// print(valueAgoInput('AGODATE', '1 MONTH')); // 20250726
/// print(valueAgoInput('AGODATE', '1 YEAR')); // 20240826
/// print(valueAgoInput('AGODATETIME', '5 MINUTES')); // 20250826151056
/// print(valueAgoInput('AGODATETIME', '2 HOURS')); // 20250826131556
/// ```
String valueAgoInput(String agoType, String agoInput) {
  final allowAgoTypes = ['agodate', 'agodatetime'];
  agoType = agoType.toLowerCase();
  if (!allowAgoTypes.contains(agoType)) return '';

  final parsedTime = TimeAgoParser.parse(agoInput);
  if (parsedTime == null || (parsedTime.unit == TimeUnit.unknown)) return '';
  final pastDateTime = parsedTime.toDateTime();
  final iso8601 = pastDateTime.toLocal().toIso8601String().split('.').first;
  var [date, time] = iso8601.split('T');
  date = date.replaceAll('-', '');
  time = time.replaceAll(':', '');

  return switch (agoType) {
    'agodate' => date,
    'agodatetime' => '$date$time',
    _ => '',
  };
}

/// Extract all possible local file and directory from the provided [text]
///
/// Excludes:
/// - Pure filenames (without separators, e.g., "file.txt")
/// - Windows UNC paths (e.g., "\\Server\Share\folder")
/// - URI schemes (e.g., "http://", "ftp://", "file://")
///
/// [text] The input string to search for paths.
/// Returns a [List<String>] of found local paths.
/// ```dart
/// final text = r'''
/// This example text contains various paths:
/// /home/user/documents/report.pdf        // File with separator, KEEP
/// /home/user/documents/                  // Directory with separator, KEEP
/// C:\Users\Public\Downloads\image.jpg    // File with separator, KEEP
/// C:\Users\Public\Downloads\             // Directory with separator, KEEP
/// ../assets/icon.png                     // File with separator, KEEP
/// ../assets/                             // Directory with separator, KEEP
/// file.txt                               // Pure file, NO SEPARATOR, EXCLUDE
/// \\Server\Share\folder\data.xlsx        // UNC Path, EXCLUDE
/// ftp://some.server/path/file.tar.gz     // URI, EXCLUDE
/// https://example.com/downloads/software.zip // URI, EXCLUDE
/// ''';
/// print(pathextract(text));
/// /*
/// [
/// '/home/user/documents/report.pdf', '/home/user/documents/',
/// 'C:\Users\Public\Downloads\image.jpg', 'C:\Users\Public\Downloads\',
/// '../assets/icon.png','../assets/',
/// ]
/// */
/// ```
List<String> pathextract(String text) {
  final Set<String> foundPaths = {}; // Use a Set to store unique paths

  final isWindows = Platform.isWindows;
  // --- Path Separator Definitions ---
  final String osSep = p.separator; // e.g., '\' on Windows, '/' on Unix
  final String winSep = pathSep; // isWindows ? '/' : '\\';
  // --- Helper: Check for Local Path Separator ---
  bool existLocalSeparator(String s) => s.contains(osSep) || s.contains(winSep);

  // Splits the input text into "words" based on whitespace and common punctuation.
  final List<String> words = text
      .split(RegExp(r'''\s+|[()\[\]{}<>"\',;!?]+'''))
      .where((s) => s.isNotEmpty) // Filter out empty strings from splitting
      .toList();

  final schemes = ['//', 'mailto:', 'tel:', 'urn:', 'data:'];
  bool startsWithScheme(String text) =>
      schemes.any((scheme) => text.startsWith(scheme));

  // --- Main Path Detection Loop ---
  for (final String word in words) {
    // --- 1. Exclude common URI schemes or contain '://'.
    final String lcWord = word.toLowerCase();
    if (lcWord.contains('://')) continue;
    if (startsWithScheme(lcWord)) continue;

    // Exclude Windows UNC paths (e.g., \\Server\Share).
    if (isWindows && word.startsWith(r'\\')) continue;
    // --- 2. Core Path Characteristic: Must Contain a Separator ---
    if (!existLocalSeparator(word)) continue;

    // --- 3. Identify Likely Local Path Patterns ---
    bool isLikelyLocalPath = false;
    // Relative paths (e.g., "./", "../")
    if (word.startsWith('./') ||
        word.startsWith('../') ||
        (isWindows && (word.startsWith('.\\') || word.startsWith('..\\')))) {
      isLikelyLocalPath = true;
    } else if (word.startsWith('~/')) {
      // Unix-like home directory paths (e.g., "~/")
      isLikelyLocalPath = true;
    } else if (isWindows) {
      if (word.length >= 3 &&
          word[1] == ':' &&
          (word[2] == osSep || word[2] == '/')) {
        // Windows absolute paths: C:\..., D:/...
        isLikelyLocalPath = true;
      }
    } else {
      if (word.startsWith('/')) {
        // Unix-like absolute paths: /home/user
        isLikelyLocalPath = true;
      }
    }

    // --- 4. Final Validation and Addition ---
    if (isLikelyLocalPath) {
      if (word.trim() == osSep || word.trim() == winSep) continue;
      if (word == '.' || word == '..') continue;
      foundPaths.add(word);
    }
  }

  return foundPaths.toList();
}
