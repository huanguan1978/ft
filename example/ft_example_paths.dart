import 'dart:io';

import 'package:filetools/ft.dart';

void main() {
  fileUtils();
  // pathExtract();
}

/// example for isDirEmpty, isDirWritable, fileMirror, fileOverWrite, getCrc64
void fileUtils() {
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
  print('dstFile delete? $deleted.');

  // cleanup
  if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
}

/// example for pathextract from text
void pathExtract() {
  final String text = r"""
This example text contains various paths:
/home/user/documents/report.pdf       // File with separator, KEEP
/home/user/documents/                  // Directory with separator, KEEP
C:\Users\Public\Downloads\image.jpg    // File with separator, KEEP
C:\Users\Public\Downloads\             // Directory with separator, KEEP
D:/data/project/settings.json          // File with separator, KEEP
D:/data/project/                       // Directory with separator, KEEP
../assets/icon.png                     // File with separator, KEEP
../assets/                             // Directory with separator, KEEP
file.txt                               // Pure file, NO SEPARATOR, EXCLUDE
C:\Program Files (x86)\App\subfolder\config.ini // File with separator, KEEP
C:\Program Files (x86)\App\subfolder\    // Directory with separator, KEEP
\\Server\Share\folder\data.xlsx        // UNC Path, EXCLUDE
ftp://some.server/path/file.tar.gz     // URI, EXCLUDE
https://example.com/downloads/software.zip // URI, EXCLUDE
another_file_without_extension.dat     // Pure file, NO SEPARATOR, EXCLUDE
config.yml                             // Pure file, NO SEPARATOR, EXCLUDE
index.html                             // Pure file, NO SEPARATOR, EXCLUDE
/var/log                               // Directory with separator, KEEP
/etc/                                  // Directory with separator, KEEP
C:\Temp                                // Directory with separator, KEEP
./my_dir                               // Directory with separator, KEEP
.                                      // Path indicator, KEEP
..                                     // Path indicator, KEEP
This is not a path: some.thing.else
Visit our website at example.com or mail us at info@domain.org // Domain, EXCLUDE
  """;

  final List<String> paths = pathextract(text);

  print(
      'Detected Local Paths (containing separators, excluding pure files, UNC, URI):');
  paths.forEach(print);
}
