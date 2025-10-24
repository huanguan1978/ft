part of '../ft.dart';

/// file stat time type
enum StatTimeType { changed, modified, accessed }

final timeTypes = StatTimeType.values.asNameMap().keys.toList();
final timeTypeDefault = StatTimeType.modified.name;

/// extension type (FileSystemEntity, FileStat, String)
extension type Es((FileSystemEntity, FileStat, String) _es) {
  FileSystemEntity get fse => _es.$1;
  FileStat get fs => _es.$2;
  String get extra => _es.$3;

  (FileSystemEntity, FileStat, String) get asRecord => _es;

/*
  Es.create({
    required FileSystemEntity fse,
    required FileStat fs,
    required String extra,
  }) : _es = (fse, fs, extra);
  */

  Es copyWith({
    FileSystemEntity? fse,
    FileStat? fs,
    String? extra,
  }) {
    return Es((
      fse ?? this.fse,
      fs ?? this.fs,
      extra ?? this.extra,
    ));
  }
}

/// data class, path meta data
class PathMeta {
  String path; // entity file/directory
  String os;
  String pattern;
  List<String> excludes;
  List<int> sizes; // sizeRange(begin, end)
  List<DateTime> times; // timeRange(begin, end)
  Map<String, String> env;
  bool verbose;
  bool cancelOnError;
  String? argErr;

  StatTimeType statTimeType;
  late final FileSystemEntityType type;

  Logger logger = CliStandardLogger(ansi: CliAnsi(CliAnsi.isSupportAnsi));
  List<String> fmtFields = <String>[
    FormatField.ok.toString(),
    FormatField.action.toString(),
  ];

  final scFilted = StreamController<Es>(sync: true);
  final scEntity = StreamController<Es>(sync: true);
  late final Stream<FileSystemEntity> fseStream; // return Glob(pattern).list()

  PathMeta(
    String location, {
    this.pattern = r'**',
    this.excludes = const [],
    this.sizes = const [],
    this.times = const [],
    this.env = const {},
    this.verbose = false,
    this.cancelOnError = true,
    this.os = '',
    this.statTimeType = StatTimeType.modified,
  }) : path = location {
    // env = {...Platform.environment, ...env}; // merage env
    if (verbose) {
      logger = CliVerboseLogger(ansi: CliAnsi(CliAnsi.isSupportAnsi));
    }

    if (os.isEmpty) os = Platform.operatingSystem;
    if (path.contains(varInputRegexp)) path = expandVar(path, map: env);
    if (path.contains(r'~')) path = expandTilde(path);
    if (pattern.contains(varInputRegexp)) {
      pattern = expandVar(pattern, map: env);
    }

    if (excludes.isNotEmpty) {
      var excl = excludes
          .map((e) => e.contains(varInputRegexp) ? expandVar(e, map: env) : e);
      excludes = excl.toList();
    }

    // if (path.startsWith(r'.')) path = expandDotPath(path);
    path = p.normalize(path);
    type = FileSystemEntity.typeSync(path);

    // print('location:$location, path:$path');
    Stream<FileSystemEntity>? fseStream_;
    if (type == FileSystemEntityType.directory) {
      fseStream_ = Glob(pattern).list(root: path);
    }
    if (type == FileSystemEntityType.file) {
      fseStream_ = Stream.value(File(path));
    }
    if (fseStream_ != null) {
      fseStream = fseStream_.cast<FileSystemEntity>().transform(
            EntityStreamTransformer(
              scEntity,
              scFilted,
              cancelOnError: cancelOnError,
              excludes: excludes,
              sizes: sizes,
              times: times,
            ),
          );
    }
  }

  factory PathMeta.fromJson(Map<String, dynamic> map) {
    final sizeRange = <int>[];
    if (map case {'sizes': List<int> sizes_}) {
      sizeRange.addAll(List<int>.from(sizes_));
    }
    final timeRange = <DateTime>[];
    if (map case {'times': List<String> times_}) {
      for (var e in times_) {
        var dt = DateTime.tryParse(e);
        if (dt is DateTime) timeRange.add(dt);
      }
    }

    final envMap = <String, String>{};
    if (map case {'env': Map env_}) {
      final dict_ = Map<String, String>.from(env_);
      envMap.addAll(dict_);
    }

    return PathMeta(
      map['path'] ?? '',
      pattern: map['pattern'] ?? '',
      excludes: switch (map['excludes']) {
        List value => List<String>.from(value),
        _ => [],
      },
      sizes: sizeRange,
      times: timeRange,
      env: envMap,
      os: map['os'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'os': os,
        'path': path,
        'pattern': pattern,
        'excludes': excludes,
        'sizes': sizes,
        'times': times,
        'env': env,
      };

  @override
  String toString() => toJson().toString();

  /// Check variables are replaced, return the unresolved or null.
  String validator({
    String target = '',
  }) {
    final errors = <String>[];
    if (target.contains(varInputRegexp)) {
      errors.add('target: undef.var,$target');
    }

    if (type == FileSystemEntityType.notFound) errors.add('path: $type, $path');
    if (path.contains(varInputRegexp)) errors.add('path: undef.var, $path');
    if (pattern.isEmpty) errors.add('pattern: isEmpty');
    if (pattern.contains(varInputRegexp)) {
      errors.add('pattern: undef.var, $pattern');
    }
    for (var e in excludes) {
      if (e.contains(varInputRegexp)) errors.add('excludes: undef.var, $e');
    }

    if (errors.isNotEmpty) {
      exitCode = ExitCodeExt.error.code;
      if (type == FileSystemEntityType.notFound) {
        exitCode = ExitCodeExt.notFound.code;
      }
    }

    return errors.join(semicolonDelimiter);
  }

  // cls_lastline
}
