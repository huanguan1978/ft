part of '../ft.dart';

/// Maps specific file extensions to their corresponding [ArchiveType].
const archiveTypeMapper = {
  'tar.gz': 'tgz',
  'tgz': 'tgz',
  'tar.bz2': 'tbz',
  'tbz': 'tbz',
  'tar.xz': 'txz',
  'txz': 'txz',
  'tar': 'tar',
  'zip': 'zip',
};

/// Represents the supported archive formats.
enum ArchiveType { tgz, tar, zip, tbz, txz }

/// A list of default file extensions permitted for archive operations.
const basicArchiveExtAllows = ['tar', 'tgz', 'tar.gz'];

/// create archive name from [path] and [type]
(String, ArchiveType) archiveName(
  String path, [
  ArchiveType type = ArchiveType.tgz,
  List<String> extAllows = basicArchiveExtAllows,
]) {
  var dname = p.dirname(path);
  var fname = p.basenameWithoutExtension(path);
  var ename = p.extension(path).toLowerCase();
  if (ename.isNotEmpty) {
    ename = ename.substring(1); // remove prefix .
    ename = archiveTypeMapper[ename] ?? ename;
    // if (ename == 'tar.gz') ename = 'tgz';
    final isAllowType = isAllowArchiveType(path, extAllows);
    if (!isAllowType) {
      ename = type.name;
      path = p.normalize(p.join(dname, '$fname.$ename'));
    }
  }

  if (ename.isNotEmpty && ArchiveType.values.asNameMap().containsKey(ename)) {
    type = ArchiveType.values.byName(ename);
  }

  var name = p.split(path).last.toLowerCase();
  if (name.endsWith(type.name)) return (path, type);

  name += '.${type.name}';
  path = p.normalize(p.join(path, '..', name));
  return (path, type);
}

/// Checks if [filename] has an extension present in [extAllows].
bool isAllowArchiveType(
  String filename, [
  List<String> extAllows = basicArchiveExtAllows,
]) {
  // final extAllows = ['tar', 'tgz', 'tar.gz'];
  final basename = p.basename(filename).toLowerCase();
  final extName = extAllows.firstWhere(
    (e) => basename.endsWith(e),
    orElse: () => '',
  );

  return extName.isNotEmpty;
}

/// Performs pre-extraction validation for an archive file.
///
/// Returns an empty string if valid, otherwise returns a concatenated error message.
/// Validates: existence of [file], file extension against [extAllows],
/// and write accessibility of [dir].
String unArchiveValidator(
  File file,
  Directory dir, [
  bool? isWritable, // isDirWriteable
  List<String> extAllows = basicArchiveExtAllows,
]) {
  final List<String> errors = [];

  if (!file.existsSync()) errors.add('not found. ${file.path}');
  isWritable ??= isDirWritable(dir);
  if (!isWritable) errors.add('not writable dir, ${dir.path}');

  final isAllowType = isAllowArchiveType(file.path, extAllows);
  if (!isAllowType) errors.add('not support type, ${file.path}');

  return errors.join(semicolonDelimiter);
}

/// unarchive [filename] to [pathname],
///
/// extname: tar.gz, tgz, tar.
void unArchive(
  File file,
  Directory dir,
  List<FormatField> fields, {
  bool useRelPath = true,
  Logger? logger,
  bool? isDirWritable,
}) {
  final name = 'unArchive';
  final extName = p.extension(file.path);

  final compressed = (extName.endsWith(r'gz')) ? true : false;
  final input =
      compressed ? file.openRead().transform(gzip.decoder) : file.openRead();

  final pathname = dir.path;
  TarReader.forEach(
    input,
    (tarEntry) async {
      var tarPath = tarEntry.name;
      if (p.isAbsolute(tarPath) && useRelPath) tarPath = pathderoot(tarPath);

      final location = p.normalize(p.join(pathname, tarPath));
      if (useRelPath && !p.isWithin(pathname, location)) {
        logger?.stderr('e, $name, $location, isNotWithin $pathname');
        return; // // same continue and for...in
      }

      if (tarEntry.type == TypeFlag.reg) {
        await File(location).create(recursive: true).then(
          (out) async {
            await tarEntry.contents.pipe(out.openWrite()).then(
              (_) {
                final line = Formatter(out, out.statSync(), '', name,
                    shows: fields, ok: true);
                logger?.stdout(line.toString());
              },
              onError: (e, s) {
                final line = Formatter(out, out.statSync(), e, name,
                    shows: fields, ok: false);
                logger?.stdout(line.toString());
                logger?.stderr('e, $name, $location, $e');
              },
            );
          },
          onError: (e, s) {
            logger?.stderr('e, $name, $location, $e');
          },
        );
      }
      if (tarEntry.type == TypeFlag.dir) {
        await Directory(location).create(recursive: true).then(
          (dir) {
            final line = Formatter(dir, dir.statSync(), '', name,
                shows: fields, ok: true);
            logger?.stdout(line.toString());
          },
          onError: (e, s) {
            logger?.stderr('e, $name, $location, $e');
          },
        );
      }
    }, // end action
  ).then((value) {
    logger?.trace('d, $name, TarReader.endForEach.');
    // unawaited(input.drain());
  });

  return;
}

/// Options for the archive operation.
class ArchiveOptions {
  final List<FileSystemEntity> entities;
  final String basePath;
  final File outputFile;
  final bool useGzip;
  final StringBuffer? logBuffer;
  final void Function()? onSuccess;
  final void Function(Object, StackTrace?)? onError;
  final StreamController<TarEntry>? controller;
  final bool autoFillEntities;

  ArchiveOptions({
    required this.entities,
    required this.basePath,
    required this.outputFile,
    this.useGzip = true,
    this.logBuffer,
    this.onSuccess,
    this.onError,
    this.controller,
    this.autoFillEntities = true,
  });
}

/// Options for the unarchive operation.
class UnArchiveOptions {
  final File file;
  final Directory targetDir;
  final StringBuffer? logBuffer;
  final void Function()? onSuccess;
  final void Function(Object, StackTrace?)? onError;
  final void Function(File extractedFile)? onFileExtracted;

  UnArchiveOptions({
    required this.file,
    required this.targetDir,
    this.logBuffer,
    this.onSuccess,
    this.onError,
    this.onFileExtracted,
  });
}

/// tar archive | unarchive helper
class TarHelper {
  static void _log(StringBuffer? buffer, String message) {
    buffer?.writeln(message);
  }

  /// Archives entities into a tar file with trace logging.
  ///
  /// Use [ArchiveOptions] to configure the operation.
  static void archive(ArchiveOptions options) {
    _log(options.logBuffer, '--- Archive Started at ${DateTime.now()} ---');
    _log(options.logBuffer, 'Base path: ${options.basePath}');

    final isExternalController = options.controller != null;
    final tarController =
        options.controller ?? StreamController<TarEntry>(sync: true);
    final outputSink = options.outputFile.openWrite();

    final archiveStream = options.useGzip
        ? tarController.stream.transform(tarWriter).transform(gzip.encoder)
        : tarController.stream.transform(tarWriter);

    archiveStream.pipe(outputSink).then((_) {
      _log(options.logBuffer, '--- Archive Successfully Completed ---');
      options.onSuccess?.call();
    }).catchError((e, st) {
      _log(options.logBuffer, '!!! Archive Error: $e');
      if (!isExternalController) {
        tarController.close();
      }
      outputSink.close();
      options.onError?.call(e, st);
    });

    // Only auto-fill if controller is internal and autoFillEntities is true
    if (!isExternalController && options.autoFillEntities) {
      _fillController(
          options.entities, options.basePath, tarController, options.logBuffer);
    }
  }

  static void _fillController(
    List<FileSystemEntity> entities,
    String basePath,
    StreamController<TarEntry> controller,
    StringBuffer? logBuffer,
  ) {
    try {
      for (final entity in entities) {
        if (!entity.existsSync()) {
          logBuffer?.writeln('Warning: Path not found: ${entity.path}');
          continue;
        }

        if (entity is File) {
          addFileToTarEntry(entity, basePath, controller, logBuffer);
        } else if (entity is Directory) {
          final files = entity.listSync(recursive: true, followLinks: false);
          for (final file in files) {
            if (file is File) {
              addFileToTarEntry(file, basePath, controller, logBuffer);
            }
          }
        }
      }
      controller.close();
    } catch (e, s) {
      logBuffer?.writeln('Critical error during scan: $e');
      controller.addError(e, s);
      controller.close();
    }
  }

  /// Adds a single file to the tar archive controller.
  ///
  /// This method can be called externally to dynamically add files to an archive
  /// when using an external [StreamController<TarEntry>].
  ///
  /// Parameters:
  /// - [file]: The file to add to the archive.
  /// - [basePath]: The base path for computing relative paths.
  /// - [controller]: The tar entry stream controller.
  /// - [logBuffer]: Optional buffer for logging.
  static void addFileToTarEntry(
    File file,
    String basePath,
    StreamController<TarEntry> controller,
    StringBuffer? logBuffer,
  ) {
    final relativePath = p.relative(file.path, from: basePath);
    logBuffer?.writeln('Adding: $relativePath');

    controller.add(
      TarEntry(
        TarHeader(
          name: relativePath,
          size: file.lengthSync(),
          mode: int.parse('644', radix: 8),
        ),
        file.openRead(),
      ),
    );
  }

  /// Adds all files from a directory to the tar archive controller.
  ///
  /// This method recursively adds all files from the specified directory
  /// to the archive. It can be called externally for dynamic archive building.
  ///
  /// Parameters:
  /// - [directory]: The directory to add to the archive.
  /// - [basePath]: The base path for computing relative paths.
  /// - [controller]: The tar entry stream controller.
  /// - [logBuffer]: Optional buffer for logging.
  /// - [recursive]: If true (default), recursively adds files from subdirectories.
  static void addDirectoryToTarEntry(
    Directory directory,
    String basePath,
    StreamController<TarEntry> controller,
    StringBuffer? logBuffer, {
    bool recursive = true,
  }) {
    try {
      final files =
          directory.listSync(recursive: recursive, followLinks: false);
      for (final file in files) {
        if (file is File) {
          addFileToTarEntry(file, basePath, controller, logBuffer);
        }
      }
    } catch (e) {
      logBuffer?.writeln('Error scanning directory ${directory.path}: $e');
    }
  }

  /// Unarchives [file] to [targetDir].
  /// Symmetric to [archive] method.
  static void unArchive(UnArchiveOptions options) {
    _log(options.logBuffer,
        '--- Unarchive Started: ${p.basename(options.file.path)} ---');

    final extName = p.extension(options.file.path);
    final isCompressed = extName.endsWith('.gz') || extName.endsWith('.tgz');

    final inputStream = options.file.openRead();
    final input =
        isCompressed ? inputStream.transform(gzip.decoder) : inputStream;

    TarReader.forEach(input, (tarEntry) async {
      final location =
          p.normalize(p.join(options.targetDir.path, tarEntry.name));

      if (!p.isWithin(options.targetDir.path, location)) {
        _log(options.logBuffer,
            'Warning: Skipping insecure entry: ${tarEntry.name}');
        return;
      }

      if (tarEntry.type == TypeFlag.dir) {
        _log(options.logBuffer, 'Creating dir: ${tarEntry.name}');
        Directory(location).createSync(recursive: true);
        return;
      }

      if (tarEntry.type == TypeFlag.reg) {
        final targetFile = File(location);
        targetFile.parent.createSync(recursive: true);
        _log(options.logBuffer, 'Extracting file: ${tarEntry.name}');
        try {
          await tarEntry.contents.pipe(targetFile.openWrite());
          options.onFileExtracted?.call(targetFile);
        } catch (e) {
          _log(options.logBuffer, 'Pipe failed for ${tarEntry.name}: $e');
          rethrow;
        }
      }
    }).then((_) {
      _log(options.logBuffer, '--- Unarchive Completed Successfully ---');
      options.onSuccess?.call();
    }).catchError((e, st) {
      _log(options.logBuffer, '!!! Unarchive Failed: $e');
      options.onError?.call(e, st);
    });
  }

  // cls.lastline
}
