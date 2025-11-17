# Common API Reference

## T1 - File Size Utilities

-   **Format Byte Sizes**
    ```dart
    // Converts a file size in bytes to a human-readable format (e.g., KB, MB, GB).
    // 30: '30B', 5300: '5.2K', 2621440: '2.5M', 12884901888: '12.0G', 1099511627776: '1.0T', 1234567890123456: '1.1P',
    print(humanReadableSize(5300)); // 5.2K

    print(hrSizes([30, 5300, 2621440])); // ['30B', '5.2K', '2.5M']
    ```

-   **Parse Human-Readable Byte Sizes**
    ```dart
    // Parse a human-readable file size (e.g., KB, MB, GB) to bytes.
    // '10': 10, '30B': 30, '1.0K': 1024, '2.0KB': 2048, '4.0KiB': 4096, '1.5 K': 1536, '1024 KB': 1048576, '2.0M': 2097152, '3.1G': 3328599654, '4.2T': 4617948836659, '5.3P': 5967269506265907,
    print(parseHumanReadableSize('2.0KB')); // 2048
    print(parseHumanReadableSize('2.0M')); // 2097152
    ```

-   **Check if Byte Size is Within Range**
    ```dart
    // Check a file size [value] within a specified range [min, max].
    print(isInSizes(5)); // false (no range defined)
    print(isInSizes(5, min: 3, max: 7)); // true (within range)
    print(isInSizes(2, min: 3, max: 7)); // false (not within range)
    print(isInSizes(5, min: 3)); // true (greater than or equal to min)
    print(isInSizes(2, min: 3)); // false (not greater than or equal to min)
    print(isInSizes(5, max: 7)); // true (less than or equal to max)
    print(isInSizes(8, max: 7)); // false (not less than or equal to max)
    ```

## T2 - File Time Utilities

-   **Format Time to Human-Readable Form**
    ```dart
    // Format a given DateTime object into a human-readable time string.
    // using **relative six-month timestamp formatting** (e.g., `MMM DD HH:MM` for recent dates, `MMM DD YYYY` for older dates)

    // 6 months ago, format MMM DD YYYY
    print(humanReadableTime(DateTime.parse('2000-05-20 10:30:50'))); // May 20 2000
    // less than 6 months, format MMM DD HH:MM
    print(humanReadableTime(DateTime.parse('2037-05-20 10:30:50'))); // May 20 10:30
    ```

-   **Parse Human-Readable Time Format**
    ```dart
    // Parse a human-readable time string.
    // using **relative six-month timestamp formatting** (e.g., `MMM DD HH:MM` for recent dates, `MMM DD YYYY` for older dates)

    // 6 months ago, format MMM DD YYYY
    print(parseHumanReadableTime('May 20 2000')); // 2000-05-20 00:00:00
    // less than 6 months, format MMM DD HH:MM; now.year is 2025
    print(parseHumanReadableTime('Dec 09 16:33')); // 2025-12-09 16:33:00
    ```

-   **Check if Time is Within Range**
    ```dart
    // Check a file time [value] within a specified range [min, max].
    DateTime now = DateTime.now();
    DateTime yesterday = now.subtract(Duration(days: 1));
    DateTime tomorrow = now.add(Duration(days: 1));

    print(isInTimes(now)); // false (no range defined)
    print(isInTimes(now, min: yesterday, max: tomorrow)); // true (within range)
    print(isInTimes(yesterday, min: yesterday, max: tomorrow)); // true
    print(isInTimes(tomorrow, min: yesterday, max: tomorrow)); // true
    print(isInTimes(yesterday, min: now, max: tomorrow)); // false
    print(isInTimes(now, min: yesterday)); // true (after or equal to min)
    print(isInTimes(yesterday, min: now)); // false
    print(isInTimes(now, max: tomorrow)); // true (before or equal to max)
    print(isInTimes(tomorrow, max: tomorrow)); // true
    print(isInTimes(tomorrow, max: yesterday)); // false
    ```

-   **Relative Time Formatting and Parsing**
    ```dart
    final now = DateTime.now();
    print('now:$now'); // now:2025-10-12 16:57:20.016680

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
    print(rst5minutes); // 2025-10-12 16:52:20.034874

    final rst2hours = TimeAgoParser.parse(str2hours)?.toDateTime();
    print(rst2hours); // 2025-10-12 14:57:20.035164

    final rst1days = TimeAgoParser.parse(str1days)?.toDateTime();
    print(rst1days);  // 2025-10-11 16:57:20.035328
    ```

## T3 - Path Utilities

-   **Get Last N Segments of a Path**
    ```dart
    // Get the last [n] segment of a [path].
    var path = '~/Downloads/ft/README.md';
    print(pathtail(path, 0)); // ''; empty string
    print(pathtail(path, 1)); // 'README.md'; last
    print(pathtail(path, 2)); // 'ft/README.md'
    print(pathtail(path, 3)); // 'Downloads/ft/README.md'
    print(pathtail(path, 4)); // '~/Downloads/ft/README.md'
    print(pathtail(path, 5)); // '~/Downloads/ft/README.md'
    ```

-   **Remove Root from Absolute Path**
    ```dart
    // Removes the root directory from an absolute [path].
    print(pathderoot(r'/Users/kaguya/Downloads/ft/README.md')); // Users/kaguya/Downloads/ft/README.md
    print(pathderoot(r'/Users/kaguya/Downloads/ft')); // Users/kaguya/Downloads/ft

    print(pathderoot(r'D:\MyProjects\dtst\bin\dtst.dart')); // D_\MyProjects\dtst\bin\dtst.d
    print(pathderoot(r'D:\MyProjects\dtst\bin')); // D_\MyProjects\dtst\bin
    ```

-   **Expand/Compress HOME Path (Tilde Expansion)**

    In Unix-like systems, the HOME path is typically represented by `~`.
    In Windows, it's usually represented by the `%USERPROFILE%` environment variable.

    Example for username `kaguya`, absolute paths are as follows:
    -   MacOS: `/Users/kaguya/Downloads/ft/README.md`;
    -   Linux: `/home/kaguya/Downloads/ft/README.md`;
    -   Windows: `C:\Users\kaguya\Downloads\ft\README.md`

    After compressing the HOME part of the path, it appears as:
    -   MacOS: `~/Downloads/ft/README.md`;
    -   Linux: `~/Downloads/ft/README.md`;
    -   Windows: `%USERPROFILE%\Downloads\ft\README.md`

    ```dart
    // expand tilde with [path]
    var path = '~/Downloads/ft/README.md' // unix-like
    print(expandTilde(path));

    // compress tilde with [path]
    var path = '/Users/kaguya/Downloads/ft/README.md' // unix-like
    print(compressTilde(path));
    ```

-   **Resolve Relative Paths**
    `.` denotes the current directory, and `..` denotes the parent directory.

    Example for username `kaguya`, current working directory is as follows:
    -   MacOS: `/Users/kaguya/Downloads/ft/`;
    -   Linux: `/home/kaguya/Downloads/ft/`;
    -   Windows: `C:\Users\kaguya\Downloads\ft\`

    Expanding `./README.md` results in the path:
    -   MacOS: `/Users/kaguya/Downloads/ft/README.md`;
    -   Linux: `/home/kaguya/Downloads/ft/README.md`;
    -   Windows: `C:\Users\kaguya\Downloads\ft\README.md`

    Expanding `../ft.tgz` results in the path:
    -   MacOS: `/Users/kaguya/Downloads/ft.tgz`;
    -   Linux: `/home/kaguya/Downloads/ft.tgz`;
    -   Windows: `C:\Users\kaguya\Downloads\ft.tgz`

    ```dart
    var path = './README.md';
    print(expandDotPath(path));
    path = '../ft.tgz';
    print(expandDotPath(path));
    ```

-   **Resolve Path Variables**

    Variables can be:
    -   **User-defined**: Enclosed in a specific format (e.g., `"$name"`, `"${name}"`, or `"%name%"`).
    -   **Built-in dynamic**:
        -   `CURDIR`: Current directory.
        -   `CURDATE`, `CURDATETIME`: Current date/time (e.g., 20250829, 20250829090226).
        -   `AGODATE<N><UNIT>`, `AGODATETIME<N><UNIT>`:
            Relative dates/times (e.g., `AGODATE1DAY`, `AGODATETIME1WEEK`).
            -   `<N>` is a number,
            -   `<UNIT>` is a time unit (e.g., SECOND, MINUTE, HOUR, DAY, WEEK, MONTH, YEAR).

    ```dart
    // assume the current user is 'kaguya'
    print(expandVar(r'$HOME')); // macos: /Users/kaguya, linux: /home/kaguya
    print(expandVar(r'%USERPROFILE%')); // windows: C:\Users\kaguya
    // assume the current time is 2025-10-11 16:31:50
    print(expandVar(r'$CURDATE'));      // 20251011
    print(expandVar(r'$AGODATE1DAY'));  // 20251010
    print(expandVar(r'$CURDATETIME'));  // 20251011163150
    print(expandVar(r'$AGODATETIME1HOUR')); // 20251011153150
    ```

-   **Extract File/Directory Paths from Text**

    Excludes: pure filenames, Windows UNC paths, and URI schemes.
    ```dart
    // Extract all possible local file and directory from the provided [text]
    final text = r'''
    This example text contains various paths:
    /home/user/documents/report.pdf        // File with separator, KEEP
    /home/user/documents/                  // Directory with separator, KEEP
    C:\Users\Public\Downloads\image.jpg    // File with separator, KEEP
    C:\Users\Public\Downloads\             // Directory with separator, KEEP
    ../assets/icon.png                     // File with separator, KEEP
    ../assets/                             // Directory with separator, KEEP
    file.txt                               // Pure file, NO SEPARATOR, EXCLUDE
    \\Server\Share\folder\data.xlsx        // UNC Path, EXCLUDE
    ftp://some.server/path/file.tar.gz     // URI, EXCLUDE
    https://example.com/downloads/software.zip // URI, EXCLUDE
    ''';
    print(pathextract(text));
    /*
    [
    '/home/user/documents/report.pdf', '/home/user/documents/',
    'C:\Users\Public\Downloads\image.jpg', 'C:\Users\Public\Downloads\',
    '../assets/icon.png','../assets/',
    ]
    */
    ```

-   **Path Pattern Matching (Glob)**
    ```dart
    // Checks if a [path] matches a glob [pattern].
    var matched = isMatchGlob('*.txt', 'file.txt'); // true

    matched = isMatchGlob(r'/**/example/**', expandTilde('~/Downloads/ft/example/ft_example.dart'));
    print(matched); // true, startwith r'/**' is _patternCanMatchAbsolute

    matched = isMatchGlob(r'?:/**/*.lnk', r'C:\Users\kaguya\Desktop\git-bash.lnk');
    print(matched); //true

    matched = isMatchGlob(r'**.dart', './example/ft_example.dart');
    print(matched); // true, startwith r'**' is _patternCanMatchRelative
    ```

## T3 - Utility Methods
-   `isDirEmpty`: Checks if a directory is empty.
-   `isDirWritable`: Checks if a directory is writable.
-   `fileMirror`: Incrementally mirrors a file.
-   `getCrc64`: Computes the CRC64 checksum of a byte array.
-   `fileOverWrite`: Overwrites a file (for secure erasure).

```dart
  final tempDir = Directory(expandVar(r'~/Documents/temp/$CURDATE'))
    ..createSync(recursive: true);
  print('create a directory, ${tempDir.path}.');

  var hasDirEmpty = isDirEmpty(tempDir); // true
  print('is empty directory? $hasDirEmpty.');

  var hasDirWritable = isDirWritable(tempDir); // true
  print('is writable directory? $hasDirWritable.');

  final srcFile = File(pathjoin(tempDir.path, expandVar(r'$AGODATETIME1HOUR')))
    ..writeAsStringSync('Hello World');
  print('create a file, ${srcFile.path}.');
  hasDirEmpty = isDirEmpty(tempDir); // false
  print('directory is empty? $hasDirEmpty.');

  var dstFile = File(pathjoin(tempDir.path, expandVar(r'$CURDATETIME')));
  dstFile = fileMirror(srcFile, dstFile);
  print('srcFile to dstFile, incremental mirror.');

   // get the CRC-64 checksum of the file.
  final srcCrc = getCrc64(srcFile.readAsBytesSync());
  final dstCrc = getCrc64(dstFile.readAsBytesSync());
  print('srcFile same dstFile? ${srcCrc == dstCrc}.');

   // security, file overwrite after delete
  final deleted = fileOverWrite(dstFile, autoDelete: true);
  print('dstFile secure wipe? $deleted.');

   // cleanup
  if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
```
The output of the above code is as follows:
```
create a directory, ~/Documents/temp/20251014.
is empty directory? true.
is writable directory? true.
create a file, ~/Documents/temp/20251014/20251014143131.
directory is empty? false.
srcFile to dstFile, incremental mirror.
srcFile same dstFile? true.
dstFile secure wipe? true.
```

## T4 - Logging

**Minimalist Logging:** Provides streamlined logging and error output functionalities via stdout and stderr, supporting terminals, string buffers, and files.

### Terminal Logging

A command-line logging tool that offers progress bar functionality and stream-diverted output, featuring two display modes:

-   **Stream Diversion:**
    *   `stdout()` outputs to the `stdout` stream.
    *   `stderr()` outputs to the `stderr` stream.
    *   `trace()` outputs to the `stdout` stream.
-   **Display Modes:**
    *   **Standard Mode:** Output is without color, and `trace()` messages are not displayed.
    *   **Verbose Mode:** Output includes color (`stderr` red, `trace` gray), and `trace()` messages are displayed.

```dart
void main(List<String> args) {
  var verbose = args.contains('-v');
  final cliAnsi = CliAnsi(CliAnsi.terminalSupportsAnsi);
  final logger = verbose
      ? CliVerboseLogger (ansi: cliAnsi)
      : CliStandardLogger(ansi: cliAnsi);

  logger.stdout('Hello world!');
  logger.trace('d, message 1');

  final progress = logger.progress("doing some work");
  Future.delayed(Duration(seconds: 3)).then((value) {
    logger.trace('d, message 11');
    sleep(Duration(seconds: 1));
    logger.trace('d, message 12');
  }).whenComplete(
    () => progress.finish(showTiming: true, message: 'progress completed'),
  );
  logger.stdout('bye.');
}
```

**Note:** Stream diversion and coloring functionalities are unavailable in non-terminal environments. For more examples, refer to `example/ft_example_logger.dart`.

### File Logging
```dart
void main(List<String> args) {
  var verbose = args.contains('-v');

  final filename = '${expandVar(r'$CURDATE')}.log';
  final ioSink = File(filename).openWrite(mode: FileMode.writeOnlyAppend);
  final logger = IoSinkLogger(ioSink, verbose);

  logger.stdout('Hello world!');
  logger.trace('d, message 1');

  final progress = logger.progress("doing some work");
  Future.delayed(Duration(seconds: 3)).then((value) {
    logger.trace('d, message 11');
    sleep(Duration(seconds: 1));
    logger.trace('d, message 12');
  }).whenComplete(() {
    progress.finish(message: 'progress completed');
    // ioSink cleanup
    ioSink.flush().whenComplete(() => unawaited(ioSink.close()));
  });
  logger.stdout('bye.');
}
```

## T5 - Modular Integration Guide

`ft` adopts a **three-stage processing architecture**. This **modular design**, through clear separation of concerns, offers excellent **maintainability, extensibility, and ease of use**, facilitating quick integration and customization for developers.

The architecture comprises:

1.  **Input Preparation**: Environment and parameter setup.
2.  **Core Logic Execution**: Invocation of encapsulated modules.
3.  **Output Post-processing** (Optional): For feature extension and result customization.

---

**Code Example:**

```dart
// matches all files in the current directory, excluding hidden items.
void actionList() {
  // Stage 1: Input Preparation
  final excludes = [r'.**'];
  final source = '.';
  final action = BasicPathAction(source, excludes: excludes);

  // Stage 2: Core Logic Execution
  late Stream<Es>? aStream;
  try {
    aStream = action.list();
  } on ArgumentError catch (e) {
    print(e);
  } catch (e) {
    print(e);
  }

  // Stage 3: Output Post-processing
  if (aStream == null) return;
  late StreamSubscription subs;
  subs = aStream.listen(
    (event) {
      var (entity, stat, extra) = event.asRecord;
      print(
        'path:${entity.path}, time: ${stat.modified}, size:${stat.size}, extra: $extra.',
      );
    },
    cancelOnError: true,
    onDone: () => print('d, list, done.'),
    onError: (e, s) {
      print('e, list, $e.');
      subs.cancel();
    },
  );

  // ufn_lastline
}
```

See `example\ft_example_action.dart` for more examples.
