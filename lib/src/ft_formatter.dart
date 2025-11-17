part of '../ft.dart';

enum FormatField { ok, action, type, mime, perm, time, size, extra }

final fieldNames = FormatField.values.asNameMap().keys.toList();

List<FormatField> fieldsFromOptions(List<String> options) {
  final List<FormatField> fields = [];
  for (var option in options) {
    if (fieldNames.contains(option)) {
      fields.add(FormatField.values.byName(option));
    }
  }
  return fields;
}

class Formatter {
  final FileSystemEntity entity;
  final FileStat stat;
  final String extra;
  final String action;
  final List<FormatField> shows;
  final String delimiter; // line output delimiter
  final StatTimeType statTimeType; // line output file stat time type

  late bool ok = false;
  late bool showOk = false; // 0 or 1
  late bool showAction = false; // action name
  late bool showType = false;
  late bool showMime = false;
  late bool showModes = false;
  late bool showTime = false;
  late bool showSize = false;
  late bool showExtra = false;

  Formatter(
    this.entity,
    this.stat,
    this.extra,
    this.action, {
    this.ok = false,
    this.shows = const [],
    this.delimiter = r' ',
    this.statTimeType = StatTimeType.modified,
  }) {
    if (shows.contains(FormatField.ok)) showOk = true;
    if (shows.contains(FormatField.action)) showAction = true;
    if (shows.contains(FormatField.type)) showType = true;
    if (shows.contains(FormatField.mime)) showMime = true;
    if (shows.contains(FormatField.perm)) showModes = true;
    if (shows.contains(FormatField.time)) showTime = true;
    if (shows.contains(FormatField.size)) showSize = true;
    if (shows.contains(FormatField.extra)) showExtra = true;
  }

  /// format type
  String get typeString => switch (stat.type) {
        FileSystemEntityType.file => 'f',
        FileSystemEntityType.directory => 'd',
        FileSystemEntityType.link => 'l',
        FileSystemEntityType.unixDomainSock => 's',
        FileSystemEntityType.pipe => 'p',
        FileSystemEntityType.notFound => 'n',
        _ => '?',
      };

  /// fromat mime
  String get mimeString => lookupMimeType(entity.path) ?? '';

  /// format mode
  String get modeString {
    var permissions = stat.mode & 0xFFF;
    var codes = const ['---', '--x', '-w-', '-wx', 'r--', 'r-x', 'rw-', 'rwx'];
    var rwx = [];
    var sgt = ['_', '_', '_']; // suid, guid, sticky bit
    if ((permissions & 0x800) != 0) sgt[0] = 's';
    if ((permissions & 0x400) != 0) sgt[1] = 'g';
    if ((permissions & 0x200) != 0) sgt[2] = 't';
    rwx
      ..add(codes[(permissions >> 6) & 0x7])
      ..add(codes[(permissions >> 3) & 0x7])
      ..add(codes[permissions & 0x7]);
    return '${sgt.join()} ${rwx.join()}'.padLeft(13);
  }

  /// format time
  String get timeString {
    final statTime = switch (statTimeType) {
      StatTimeType.changed => stat.changed,
      StatTimeType.accessed => stat.accessed,
      _ => stat.modified,
    };
    return humanReadableTime(statTime);
  }

  /// format size
  String get sizeString => humanReadableSize(stat.size).padLeft(6);

  /// format path
  String get pathString => compressTilde(entity.path);

  /// format ok
  String get okString => ok ? '1' : '0';

  /// format action
  String get actionString => action.padLeft(7);

  /// format output
  String output() {
    List<String> words = [];
    if (showOk) words.add(okString);
    if (showAction) words.add(actionString);
    if (showType) words.add(typeString);
    if (showModes) words.add(modeString);
    if (showSize) words.add(sizeString);
    if (showTime) words.add(timeString);

    words.add(pathString);
    if (showMime) words.add(mimeString);
    if (showExtra) words.add(extra);

    return words.join(delimiter);
  }

  @override
  String toString() => output();

  // cls_lastline
}
