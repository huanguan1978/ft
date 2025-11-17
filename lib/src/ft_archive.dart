part of '../ft.dart';

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

enum ArchiveType { tgz, tar, zip, tbz, txz }

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
