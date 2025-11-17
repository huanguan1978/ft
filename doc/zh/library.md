# 常用API手册 


## T1-文件大小

- 格式化字节大小 
```dart
// Converts a file size in bytes to a human-readable format (e.g., KB, MB, GB).
// 30: '30B', 5300: '5.2K', 2621440: '2.5M', 12884901888: '12.0G', 1099511627776: '1.0T', 1234567890123456: '1.1P',
print(humanReadableSize(5300)); // 5.2K

print(hrSizes([30, 5300, 2621440])); // ['30B', '5.2K', '2.5M']
```

- 解析易读字节大小
```dart
// Parse a human-readable file size (e.g., KB, MB, GB) to bytes.
// '10': 10, '30B': 30, '1.0K': 1024, '2.0KB': 2048, '4.0KiB': 4096, '1.5 K': 1536, '1024 KB': 1048576, '2.0M': 2097152, '3.1G': 3328599654, '4.2T': 4617948836659, '5.3P': 5967269506265907,
print(parseHumanReadableSize('2.0KB')); // 2048
print(parseHumanReadableSize('2.0M')); // 2097152
```

- 判断字节大小是否在区间内
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

## T2-文件时间

- 格式化时间为易读形式 
```dart
// Format a given DateTime object into a human-readable time string.
// using **relative six-month timestamp formatting** (e.g., `MMM DD HH:MM` for recent dates, `MMM DD YYYY` for older dates)

// 6 months ago, format MMM DD YYYY
print(humanReadableTime(DateTime.parse('2000-05-20 10:30:50'))); // May 20 2000
// less than 6 months, format MMM DD HH:MM
print(humanReadableTime(DateTime.parse('2037-05-20 10:30:50'))); // May 20 10:30
```

- 解析易读时间格式
```dart
// Parse a human-readable time string.
// using **relative six-month timestamp formatting** (e.g., `MMM DD HH:MM` for recent dates, `MMM DD YYYY` for older dates)

// 6 months ago, format MMM DD YYYY
print(parseHumanReadableTime('May 20 2000')); // 2000-05-20 00:00:00
// less than 6 months, format MMM DD HH:MM; now.year is 2025
print(parseHumanReadableTime('Dec 09 16:33')); // 2025-12-09 16:33:00
```

- 判断时间是否在区间内
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

- 相对时间格式化与解析
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

## T3-路径

- 获取路径末尾N段 
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

- 移除绝对路径的根路径 
```dart
// remove the root  from an absolute [path].
print(pathderoot(r'/Users/kaguya/Downloads/ft/README.md')); // Users/kaguya/Downloads/ft/README.md
print(pathderoot(r'/Users/kaguya/Downloads/ft')); // Users/kaguya/Downloads/ft

print(pathderoot(r'D:\MyProjects\dtst\bin\dtst.dart')); // D_\MyProjects\dtst\bin\dtst.d
print(pathderoot(r'D:\MyProjects\dtst\bin')); // D_\MyProjects\dtst\bin
```

-  展开/收缩 HOME 路径

   在Unix-like系统中，HOME 路径通常以 ~ 表示；；  
   在 Windows 中，则通常以环境变量 %USERPROFILE% 表示。

   示例用户名为`kaguya`, 绝对路径如下：
   - MacOS:   /Users/kaguya/Downloads/ft/README.md; 
   - Linux:   /home/kaguya/Downloads/ft/README.md;
   - Windows: C:\Users\kaguya\Downloads\ft\README.md

   收缩路径中的HOME部份后如下：
   - MacOS:   ~/Downloads/ft/README.md; 
   - Linux:   ~/Downloads/ft/README.md;
   - Windows: %USERPROFILE%\Downloads\ft\README.md

```dart
// expand tilde with [path]
var path = '~/Downloads/ft/README.md' // unix-like
print(expandTilde(path)); 

// compress tilde with [path]
var path = '/Users/kaguya/Downloads/ft/README.md' // unix-like 
print(compressTilde(path)); 
```

- 解析相对路径
`.`表示当前路径，`..`表示当前路径的上级路径。

   示例用户名为`kaguya`, 当前所在路径如下：
   - MacOS:   /Users/kaguya/Downloads/ft/; 
   - Linux:   /home/kaguya/Downloads/ft/;
   - Windows: C:\Users\kaguya\Downloads\ft\

   展开`./README.md`得到路径如下：
   - MacOS:   /Users/kaguya/Downloads/ft/README.md; 
   - Linux:   /home/kaguya/Downloads/ft/README.md;
   - Windows: C:\Users\kaguya\Downloads\ft\README.md

   展开`../ft.tgz`得到路径如下：
   - MacOS:   /Users/kaguya/Downloads/ft.tgz; 
   - Linux:   /home/kaguya/Downloads/ft.tgz;
   - Windows: C:\Users\kaguya\Downloads\ft.tgz

```dart
var path = './README.md';
print(expandDotPath(path)); 
path = '../ft.tgz';
print(expandDotPath(path)); 
```

- 解析路径中的变量

   Variables can be:
   - **User-defined**: Enclosed in a specific format (e.g., `"$name"`, `"${name}"`, or `"%name%"`).
   - **Built-in dynamic**:
      - `CURDIR`: Current directory.
      - `CURDATE`, `CURDATETIME`: Current date/time (e.g., 20250829, 20250829090226).
      - `AGODATE<N><UNIT>`, `AGODATETIME<N><UNIT>`:  
         Relative dates/times (e.g., `AGODATE1DAY`, `AGODATETIME1WEEK`).
         - `<N>` is a number,
         - `<UNIT>` is a time unit (e.g., SECOND, MINUTE, HOUR, DAY, WEEK, MONTH, YEAR).

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

- 从文本中提取文件/目录路径

excludes: pure filenames, Windows UNC paths, and URI schemes.
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

- 路径模式匹配检查
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

## T3-实用方法
   - isDirEmpty, 目录是否为空
   - isDirWritable, 目录是否可写
   - fileMirror, 增量镜像一个文件
   - getCrc64, 计算数组的 CRC64 校验码
   - fileOverWrite, 覆写一个文件（用于安全擦除这个文件）
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
上述代码运取结果如下：
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


## T4-日志输出

**极简日志：** 通过 stdout 和 stderr 提供精简的日志与错误输出功能，支持终端、字符串缓冲区及文件。

### 终端日志
终端日志是命令行日志工具，提供进度条功能、分流输出，并具备两种显示模式：

-   分流输出：
      - `stdout()`输出到`stdout`流；
      - `stderr()`输出到`stderr`流；
      - `trace()`输出到`stdout`流。
-   显示模式：
    - 标准模式： 输出无颜色，且不显示 `trace()` 消息。
    - 详细模式： 输出带颜色（`stderr`为红色，`trace`为灰色），并显示`trace()`消息。

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

提示：若非终端环境，则无分流和着色功能。更多示例请参阅 `example/ft_example_logger.dart`。

### 文件日志
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

## T5-功能模块化集成指南

`ft` 采用**三阶段处理架构**，这种**模块化设计**通过清晰的职责划分，提供了卓越的**可维护性、可扩展性与易用性**，便于开发者快速集成与功能定制。

该架构包含：

1.  **输入准备**：环境及参数设置。
2.  **核心逻辑执行**：调用已封装模块。
3.  **输出后处理**（可选）：用于功能扩展与结果定制。

---

**代码示例：**

```dart
// 匹配当前路径下所有文件（排除隐藏目录和文件）
void actionList() {
  // 阶段一: 输入准备
  final excludes = [r'.**'];
  final source = '.';
  final action = BasicPathAction(source, excludes: excludes);

  // 阶段二: 核心逻辑执行
  late Stream<Es>? aStream;
  try {
    aStream = action.list();
  } on ArgumentError catch (e) {
    print(e);
  } catch (e) {
    print(e);
  }

  // 阶段三: 输出后处理
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

更多示例请参阅 `example/ft_example_action.dart`。