part of '../ft.dart';

/// enum available path action
enum PathAction {
  list(label: 'list'),
  search(label: 'search'),
  fdups(label: 'fdups'),
  unarchive(label: 'unarchive'),
  archive(label: 'archive'),
  mirror(label: 'mirror'),
  rmdir(label: 'rmdir'),
  clean(label: 'clean'),
  wipe(label: 'wipe'),
  ;

  final String label;
  const PathAction({
    required this.label,
  });
}

class BasicPathAction extends PathMeta with BasicAction {
  BasicPathAction(
    super.location, {
    super.pattern,
    super.excludes,
    super.sizes,
    super.times,
    super.env,
    super.verbose,
    super.cancelOnError,
    super.os,
    super.statTimeType,
  });
}

mixin BasicAction on PathMeta {
  /// list source path.
  ///
  /// - [matched]: Show all matches if enabled, otherwise, show non-matches.
  /// - [fseType]: match type (file, directory, link).
  ///
  /// ```dart
  /// final excludes = [r'.**'];
  /// final source = '.';
  /// final action = BasicPathAction(source, excludes: excludes);
  ///
  /// action.list();
  /// ```
  Stream<Es> list({
    // String renAction = 'list',
    bool matched = true,
    FileSystemEntityType fseType = FileSystemEntityType.file,
  }) {
    final action = PathAction.list.name, chk = 'validator';
    argErr ??= validator();
    if (argErr!.isNotEmpty) throw ArgumentError.value(argErr, action, chk);

    final fields = fieldsFromOptions(
      matched ? fmtFields : [FormatField.extra.toString(), ...fmtFields],
    );

    final stream = matched ? scEntity.stream : scFilted.stream;
    final fStream =
        stream.where((event) => event.fs.type == fseType).asBroadcastStream();

    late StreamSubscription subs;
    subs = fStream.listen(
      (event) {
        final (entity, stat, extra) = event.asRecord;
        final ok = stat.type == FileSystemEntityType.notFound ? false : true;
        final line =
            Formatter(entity, stat, extra, action, shows: fields, ok: ok);
        logger.stdout(line.toString());
      },
      cancelOnError: cancelOnError,
      onDone: () => logger.trace('d, $action, done.'),
      onError: (e, s) {
        if (cancelOnError) {
          exitCode = ExitCodeExt.error.code;
          subs.cancel();
        }

        logger
          ..trace('d, $action, cancelOnError:$cancelOnError')
          ..stderr('e, $action, error. $e')
          ..stderr(kIsDebug ? '$s' : '');
      },
    );
    return fStream;
  }

  /// search source path, text files, with regexp or replace
  ///
  /// - [regexp]: regex pattern.
  /// - [replace]: regexp has match to replace if replace.isNoEmpty.
  /// - [extMime]: addon text file type, use mimetype, e.g. {'tml':'text/toml', 'yml':'application/yaml'}.
  /// - [lineByLine]: use line by line file processing?

  ///
  /// ```dart
  /// final pattern = r'**.yaml';
  /// final excludes = [r'.**'];
  /// final source = '.';
  /// final action = BasicPathAction(source, pattern:pattern, excludes: excludes);
  ///
  /// final regexp = r'version: 1.0.\d+';
  /// action.search(regexp);
  /// ```
  Stream<Es> search(
    String regexp, {
    String replace = '',
    Map<String, String> extMime = const {},
    bool reI = false, // Case-insensitive
    bool reU = false,
    bool reS = false,
    bool reM = false,
    bool lineByLine = true, // is LineSplitter
  }) {
    final action = PathAction.search.name, chk = 'validator';
    argErr ??= validator();
    if (argErr!.isNotEmpty) throw ArgumentError.value(argErr, action, chk);

    final fields = fieldsFromOptions(
      [FormatField.extra.toString(), ...fmtFields],
    );
    final fseType = FileSystemEntityType.file;
    final stream = scEntity.stream;
    final fStream =
        stream.where((event) => event.fs.type == fseType).asBroadcastStream();

    doTextMimeInit(); // use for isTextMimeType
    if (extMime.isNotEmpty) extMime.forEach((k, v) => doTextMimeAdd(k, v));

    // logger.stdout('d, regexp:$regexp, utf8.encode:${utf8.encode(regexp)}');
    final regex = RegExp(
      regexp,
      caseSensitive: !reI,
      unicode: reU,
      dotAll: reS,
      multiLine: reM,
    );

    late StreamSubscription subs;
    subs = fStream.listen(
      (event) {
        var (entity, stat, extra) = event.asRecord;
        final ok = stat.type == FileSystemEntityType.notFound ? false : true;
        final isText = ok ? isTextMimeType(entity.path) : false;
        extra += ' isTextFile:${isText ? 1 : 0}';
        final line =
            Formatter(entity, stat, extra, action, shows: fields, ok: isText);
        logger.stdout(line.toString());

        if (ok && isText) {
          final buf = StringBuffer();

          var replaced = false;
          var no = 0; // lineNumber
          final location = compressTilde(entity.path);
          final file = File.fromUri(entity.uri);
          var tStream = file.openRead().transform(utf8.decoder);
          if (lineByLine) tStream = tStream.transform(const LineSplitter());

          late StreamSubscription tSubs;
          tSubs = tStream.listen(
            (line) {
              no++;
              if (regex.hasMatch(line)) {
                // line.contains(regex)
                if (replace.isNotEmpty) {
                  replaced = true;
                  line = line.replaceAll(regex, replace);
                  logger.stdout('i, L:$no, O:$line, F:$location');
                } else {
                  logger.stdout(
                      'i, L:$no, I:${lineByLine ? line : '......'}, F:$location');
                }
              }
              if (replace.isNotEmpty) buf.writeln(line);
            },
            cancelOnError: cancelOnError,
            onDone: () {
              if (replace.isNotEmpty && replaced) {
                try {
                  file.writeAsStringSync(buf.toString());
                } on FileSystemException catch (e, s) {
                  logger
                    ..trace('d, $action, file replace:$location')
                    ..stderr('e, $action, error. $e')
                    ..stderr(kIsDebug ? '$s' : '');
                } finally {
                  buf.clear();
                }
              }
              buf.clear();
              // logger.trace('d, $action, done.');
            },
            onError: (e, s) {
              buf.clear();
              tSubs.cancel();

              logger
                ..trace('d, $action, file listen:$location')
                ..stderr('e, $action, error. $e')
                ..stderr(kIsDebug ? '$s' : '');
            },
          );
        }
      },
      cancelOnError: cancelOnError,
      onDone: () => logger.trace('d, $action, done.'),
      onError: (e, s) {
        if (cancelOnError) {
          exitCode = ExitCodeExt.error.code;
          subs.cancel();
        }

        logger
          ..trace('d, $action, cancelOnError:$cancelOnError')
          ..stderr('e, $action, error. $e')
          ..stderr(kIsDebug ? '$s' : '');
      },
    );
    return fStream;
  }

  /// incrementally mirror source path to target directory.
  ///
  /// - [toDir]: target directory.
  /// - [useRelPath]: use relative path If true else use deroot absolute path.
  ///
  /// Example: <br/>
  ///   source: `~/tmp.txt`, target: `~/Downloads/temp/`; <br/>
  /// Result: <br />
  ///   `~/Downloads/temp/tmp.txt` if true
  ///   else `~/Downloads/temp/Users/kaguya/tmp.txt`
  ///
  /// ```dart
  /// final excludes = [r'.**'];
  /// final source = '.';
  /// final action = BasicPathAction(source, excludes: excludes);
  ///
  /// final toDir = Direcotry(expandTilde('~/Downloads/ft/'))..createSync(recursive: true);
  /// action.mirror(toDir);
  /// ```
  Stream<Es> mirror(Directory toDir, [bool useRelPath = true]) {
    final action = PathAction.mirror.name, chk = 'validator';
    argErr ??= validator();
    if (argErr!.isNotEmpty) throw ArgumentError.value(argErr, action, chk);
    final srcPath = (type == FileSystemEntityType.directory)
        ? Directory(path).absolute.path
        : path;

    final fields = fieldsFromOptions(fmtFields);
    final fseType = FileSystemEntityType.file;
    final stream = scEntity.stream;
    final fStream =
        stream.where((event) => event.fs.type == fseType).asBroadcastStream();

    final dst = toDir.path;
    late StreamSubscription subs;
    subs = fStream.listen(
      (event) {
        final (entity, stat, extra) = event.asRecord;
        final oldPath = entity.isAbsolute ? entity.path : entity.absolute.path;
        // keep the original, useRelPath
        var newPath = p.join(dst, pathderoot(oldPath)); // default false
        if (useRelPath) {
          if (type == FileSystemEntityType.directory) {
            newPath = p.join(dst, oldPath.substring(srcPath.length + 1));
          } else {
            newPath = p.join(dst, p.basename(oldPath));
          }
        }
        var ok = false;
        var file = File(entity.path);
        var newFile = File(newPath);
        try {
          file = fileMirror(file, newFile);
          ok = true;
        } catch (e, s) {
          logger.stderr('e, $action, data, filesync, $oldPath -> $newPath');
          scEntity.addError(e, s);
        }

        final line = Formatter(file, ok ? file.statSync() : stat, extra, action,
            shows: fields, ok: ok);
        logger.stdout(line.toString());
      },
      cancelOnError: cancelOnError,
      onDone: () => logger.trace('d, $action, done.'),
      onError: (e, s) {
        if (cancelOnError) {
          exitCode = ExitCodeExt.error.code;
          subs.cancel();
        }

        logger
          ..trace('d, $action, cancelOnError:$cancelOnError')
          ..stderr('e, $action, error. $e')
          ..stderr(kIsDebug ? '$s' : '');
      }, // onError
    );

    return fStream;
  }

  /// remove directory if empty
  ///
  /// - [force]: force remove directory if not empty.
  /// - [keeptop]: keep top (source) directory.
  ///
  /// ```dart
  /// final source = '~/Downloads/temp/ft/';
  /// final action = BasicPathAction(source);
  ///
  /// action.rmdir();
  /// // action.rmdir(force:true, keeptop:true); // no remove ~/Downloads/temp/ft/
  /// ```
  Stream<Es> rmdir({bool force = false, bool keeptop = false}) {
    final action = PathAction.rmdir.name, chk = 'validator';
    argErr ??= validator();
    if (argErr!.isNotEmpty) throw ArgumentError.value(argErr, action, chk);

    final fields = fieldsFromOptions(fmtFields);
    final fseType = FileSystemEntityType.directory;

    final stream = scEntity.stream;
    final dStream =
        stream.where((event) => event.fs.type == fseType).asBroadcastStream();
    dStream.toList().then(
      (events) {
        if (type == FileSystemEntityType.directory) {
          final source = Directory(path);
          final es = Es((source, source.statSync(), 'source'));
          events.add(es);
        }
        events.sort((a, b) => b.fse.path.length.compareTo(a.fse.path.length));
        if (events.isNotEmpty && keeptop) events.removeLast(); // keep top?
        bool errexit = false;
        for (var event in events) {
          if (errexit) break;
          final (entity, stat, extra) = event.asRecord;
          // print('---${entity.path}');
          final dir = Directory(entity.path);
          final exist = dir.existsSync();
          if (exist) {
            var ok = false;

            try {
              if (force) {
                dir.deleteSync(recursive: true);
              } else {
                if (isDirEmpty(dir, isDirExist: exist)) dir.deleteSync();
              }
              ok = true;
            } on FileSystemException catch (e, s) {
              exitCode = ExitCodeExt.error.code;
              if (cancelOnError) errexit = true;
              logger
                ..stderr('e, $action, delete, $e')
                ..stderr((kIsDebug ? '' : s.toString()));
            }
            final line =
                Formatter(entity, stat, extra, action, shows: fields, ok: ok);
            logger.stdout(line.toString());
          }
        } // end_for
      },
    );

    return dStream;
  }

  /// find duplicate files
  Stream<Es> fdups() {
    final action = PathAction.fdups.name, chk = 'validator';
    argErr ??= validator();
    if (argErr!.isNotEmpty) throw ArgumentError.value(argErr, action, chk);

    final fields = fieldsFromOptions(fmtFields);
    final fseType = FileSystemEntityType.file;

    final crcMap = <int, List<Es>>{};
    // if (!fileds.contains(FormatField.extra)) fileds.add(FormatField.extra);

    final stream = scEntity.stream;
    final fStream =
        stream.where((event) => event.fs.type == fseType).asBroadcastStream();
    late StreamSubscription subs;
    subs = fStream.listen(
      (event) {
        var (entity, stat, extra) = event.asRecord;
        try {
          final crc64 = getCrc64(File(entity.path).readAsBytesSync());
          extra = 'hash:$crc64';
          crcMap.putIfAbsent(crc64, () => []);
          crcMap[crc64]?.add(event.copyWith(extra: extra));
        } catch (e, s) {
          logger.stderr('e, $action, data, delete ${entity.path}');
          scEntity.addError(e, s);
        }
      },
      cancelOnError: cancelOnError,
      onDone: () {
        logger.trace('d, $action, done.');
        for (var item in crcMap.entries) {
          final key = item.key;
          final dups = item.value;
          if (dups.length > 1) {
            logger.stdout('i, $action, hash:$key');
            final ok = true;
            for (var dup in dups) {
              // final (entity, stat, extra) = dup;
              final line = Formatter(dup.fse, dup.fs, dup.extra, action,
                  shows: fields, ok: ok);
              logger.stdout(line.toString());
            }
          }
        }
      },
      onError: (e, s) {
        if (cancelOnError) {
          exitCode = ExitCodeExt.error.code;
          subs.cancel();
        }

        logger
          ..trace('d, $action, cancelOnError:$cancelOnError')
          ..stderr('e, $action, error. $e')
          ..stderr(kIsDebug ? '$s' : '');
      }, // onError
    );

    return fStream;
  }

  /// clean files
  Stream<Es> clean() {
    final action = PathAction.clean.name, chk = 'validator';
    argErr ??= validator();
    if (argErr!.isNotEmpty) throw ArgumentError.value(argErr, action, chk);

    final fields = fieldsFromOptions(fmtFields);
    final fseType = FileSystemEntityType.file;

    final stream = scEntity.stream;
    final fStream =
        stream.where((event) => event.fs.type == fseType).asBroadcastStream();
    late StreamSubscription subs;
    subs = fStream.listen(
      (event) {
        final (entity, stat, extra) = event.asRecord;
        var ok = false;
        try {
          entity.deleteSync();
          ok = true;
        } catch (e, s) {
          logger.stderr('e, $action, data, delete ${entity.path}');
          scEntity.addError(e, s);
        }

        final line =
            Formatter(entity, stat, extra, action, shows: fields, ok: ok);
        logger.stdout(line.toString());
      },
      cancelOnError: cancelOnError,
      onDone: () => logger.trace('d, $action, done.'),
      onError: (e, s) {
        if (cancelOnError) {
          exitCode = ExitCodeExt.error.code;
          subs.cancel();
        }

        logger
          ..trace('d, $action, cancelOnError:$cancelOnError')
          ..stderr('e, $action, error. $e')
          ..stderr(kIsDebug ? '$s' : '');
      }, // onError
    );
    return fStream;
  }

  /// secure wipe files
  ///
  /// - [levels]: security levels for file overwrite.
  ///
  /// available levels:
  ///        [low]                 file overwritten with zeros (0);
  ///        [medium] (default)    file overwritten with random bits (0|1);
  ///        [high]                file overwritten with random bytes (0-255).
  ///
  /// ```dart
  /// final source = '~/Downloads/temp/ft.tgz';
  /// final action = BasicPathAction(source);
  ///
  /// action.wipe();
  /// ```
  Stream<Es> wipe([List<String> levels = const []]) {
    final action = PathAction.wipe.name, chk = 'validator';
    argErr ??= validator();
    if (argErr!.isNotEmpty) throw ArgumentError.value(argErr, action, chk);

    final fields = fieldsFromOptions(fmtFields);
    final fseType = FileSystemEntityType.file;

    final stream = scEntity.stream;
    final fStream =
        stream.where((event) => event.fs.type == fseType).asBroadcastStream();
    late StreamSubscription subs;
    subs = fStream.listen(
      (event) {
        final (entity, stat, extra) = event.asRecord;
        var ok = false;
        var autoDelete = levels.length == 1 ? true : false;
        var file = File(entity.path);
        try {
          for (var level in levels) {
            logger.trace('d, $action, level:$level, ${entity.path}');
            ok = fileOverWrite(
              file,
              isFileExist: true,
              autoDelete: autoDelete,
              level: FileWriteLevel.values.byName(level),
            );
          }
          if (!autoDelete) file.deleteSync();
        } catch (e, s) {
          logger.stderr('e, $action, data, secure ${entity.path}');
          scEntity.addError(e, s);
        }

        final line =
            Formatter(entity, stat, extra, action, shows: fields, ok: ok);
        logger.stdout(line.toString());
      },
      cancelOnError: cancelOnError,
      onDone: () => logger.trace('d, $action, done.'),
      onError: (e, s) {
        if (cancelOnError) {
          exitCode = ExitCodeExt.error.code;
          subs.cancel();
        }

        logger
          ..trace('d, $action, cancelOnError:$cancelOnError')
          ..stderr('e, $action, error. $e')
          ..stderr(kIsDebug ? '$s' : '');
      }, // onError
    );
    return fStream;
  }

  /// archive source path
  ///
  /// - [archiveFile]: to archive file.
  /// - [archiveType]: to archive type.
  /// - [useRelPath]: use relative path If true else use deroot absolute path.
  ///
  /// ```dart
  /// final excludes = [r'.**'];
  /// final source = '.';
  /// final action = BasicPathAction(source, excludes:excludes);
  ///
  /// final toArchive = File(expandTilde('~/Downloads/ft.tgz'));
  /// action.archive(toArchive, ArchiveType.tgz);
  /// ```
  Stream<Es> archive(File archiveFile, ArchiveType archiveType,
      [bool useRelPath = true]) {
    final action = PathAction.archive.name, chk = 'validator';
    argErr ??= validator();
    if (argErr!.isNotEmpty) throw ArgumentError.value(argErr, action, chk);
    final srcPath = (type == FileSystemEntityType.directory)
        ? Directory(path).absolute.path
        : path;

    final fields = fieldsFromOptions(fmtFields);
    final fseType = FileSystemEntityType.file;
    final stream = scEntity.stream;
    final fStream =
        stream.where((event) => event.fs.type == fseType).asBroadcastStream();
    final tarEntryController = StreamController<TarEntry>(sync: true);

    late StreamSubscription subs;
    subs = fStream.listen(
      (event) {
        final (entity, stat, extra) = event.asRecord;
        final oldPath = entity.isAbsolute ? entity.path : entity.absolute.path;
        // keep the original,  use useRelPath
        var newPath = oldPath;
        if (useRelPath) {
          if (type == FileSystemEntityType.directory) {
            newPath = oldPath.substring(srcPath.length + 1);
          } else {
            newPath = p.basename(path);
          }
        }
        if (newPath == archiveFile.path) return; // same continue and for...in
        var ok = false;
        newPath = separatorToForwardSlash(newPath);
        try {
          tarEntryController.add(
            TarEntry(
              TarHeader(
                  name: newPath,
                  modified: stat.modified,
                  mode: stat.mode,
                  size: stat.size),
              File(entity.path).openRead(),
            ),
          );
          ok = true;
        } catch (e, s) {
          logger.stderr('e, $action, data, secure ${entity.path}');
          scEntity.addError(e, s);
        }

        final line =
            Formatter(entity, stat, extra, action, shows: fields, ok: ok);
        logger.stdout(line.toString());
      },
      cancelOnError: cancelOnError,
      onDone: () {
        logger.trace('d, $action, done.');

        final outputStream = archiveFile.openWrite();
        final tStream = (archiveType == ArchiveType.tgz)
            ? tarEntryController.stream
                .transform(tarWriter)
                .transform(gzip.encoder)
            : tarEntryController.stream;
        final pipe = (archiveType == ArchiveType.tgz)
            ? tStream.pipe(outputStream)
            : tStream.pipe(tarWritingSink(outputStream));

        pipe.then(
          (_) => unawaited(outputStream.close()),
          onError: (e, s) =>
              logger.stderr('e, $action, done, pipe tarwrite, $e\n$s'),
        );
        tarEntryController.close();
      },
      onError: (e, s) {
        if (cancelOnError) {
          tarEntryController.close();

          exitCode = ExitCodeExt.error.code;
          subs.cancel();
        }

        logger
          ..trace('d, $action, cancelOnError:$cancelOnError')
          ..stderr('e, $action, error. $e')
          ..stderr(kIsDebug ? '$s' : '');
      }, // onError
    );
    return fStream;
  }

  /// find archive in source unarchive to target directory.
  ///
  /// - [toDir]: unarchive to target directory.
  /// - [useRelPath]: use relative path If true else use deroot absolute path.
  ///
  /// ```dart
  /// final source = '~/Downloads/ft.tgz';
  /// final action = BasicPathAction(source);
  ///
  /// final toDir = Direcotry(expandTilde('~/Downloads/temp/ft/'))..createSync(recursive: true);
  /// action.unarchive(toDir);
  /// ```
  Stream<Es> unarchive(Directory toDir,
      [bool useRelPath = true, bool? isDirWritable]) {
    final action = PathAction.unarchive.name, chk = 'validator';
    argErr ??= validator();
    if (argErr!.isNotEmpty) throw ArgumentError.value(argErr, action, chk);
    final srcPath = (type == FileSystemEntityType.directory)
        ? Directory(path).absolute.path
        : path;

    final fields = fieldsFromOptions(fmtFields);
    final fseType = FileSystemEntityType.file;
    final stream = scEntity.stream;
    final fStream =
        stream.where((event) => event.fs.type == fseType).asBroadcastStream();
    // final fStream = stream.where((event) => isAllowArchiveType(event.$1.path));

    final dst = toDir.path;
    late StreamSubscription subs;
    subs = fStream.listen(
      (event) {
        if (!isAllowArchiveType(event.fse.path)) return; // same continue

        final (entity, stat, extra) = event.asRecord;
        final oldPath = entity.isAbsolute ? entity.path : entity.absolute.path;
        // print(srcFile);
        // keep the original, useRelPath
        var newPath = p.join(dst, pathderoot(oldPath)); // default false
        if (useRelPath) {
          if (type == FileSystemEntityType.directory) {
            newPath = p.join(dst, oldPath.substring(srcPath.length + 1));
          } else {
            newPath = p.join(dst, p.basename(oldPath));
          }
        }
        var ok = false;
        var file = File(entity.path);
        try {
          unArchive(file, toDir, fields,
              useRelPath: useRelPath,
              logger: logger,
              isDirWritable: isDirWritable);
          ok = true;
        } catch (e, s) {
          logger.stderr('e, $action, data, unArchive, $oldPath -> $newPath');
          scEntity.addError(e, s);
        }

        final line =
            Formatter(file, stat, extra, action, shows: fields, ok: ok);
        logger.stdout(line.toString());
      },
      cancelOnError: cancelOnError,
      onDone: () => logger.trace('d, $action, done.'),
      onError: (e, s) {
        if (cancelOnError) {
          exitCode = ExitCodeExt.error.code;
          subs.cancel();
        }

        logger
          ..trace('d, $action, cancelOnError:$cancelOnError')
          ..stderr('e, $action, error. $e')
          ..stderr(kIsDebug ? '$s' : '');
      }, // onError
    );

    return fStream;
  }

  // cls_lastline
}
