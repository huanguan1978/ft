// ignore_for_file: unused_local_variable

import 'dart:async';
import 'dart:io';

import 'package:filetools/ft.dart';
import 'package:tar/tar.dart';

void main() {
  final logBuffer = StringBuffer();
  final tarFile = File('example.tgz');
  final srcPath = 'example';
  final srcDir = Directory(srcPath);
  final dstPath = 'example2';
  final dstDir = Directory(dstPath);

  // Example of archiving with auto-fill
  archinve(srcDir, tarFile, srcPath, useGzip: true, logBuffer: logBuffer);

  // Example of archiving with external controller
  // archiveWithExternalController(tarFile, srcPath,
  //     useGzip: true, logBuffer: logBuffer);

  // unarchive(dstDir, tarFile, logBuffer: logBuffer);
}

void archinve(Directory srcDir, File tarFile, String basePath,
        {bool? useGzip, StringBuffer? logBuffer}) =>
    TarHelper.archive(
      ArchiveOptions(
        entities: [srcDir],
        basePath: basePath,
        outputFile: tarFile,
        useGzip: useGzip ?? false,
        logBuffer: logBuffer,
        onSuccess: () {
          print('archive success!');
          print('archive log:\n${logBuffer.toString()}');
        },
        onError: (error, stack) {
          print('archive failure: $error');
          print('archive log:\n${logBuffer.toString()}');
        },
      ),
    );

void unarchive(Directory outDir, File tarFile, {StringBuffer? logBuffer}) =>
    TarHelper.unArchive(
      UnArchiveOptions(
        file: tarFile,
        targetDir: outDir,
        logBuffer: logBuffer,
        onSuccess: () {
          print('unarchive success!');
          print('unarchive log:\n${logBuffer.toString()}');
        },
        onError: (error, stack) {
          print('unarchive failure: $error');
          print('unarchive log:\n${logBuffer.toString()}');
        },
      ),
    );

void archiveWithExternalController(
  File tarFile,
  String basePath, {
  bool? useGzip,
  StringBuffer? logBuffer,
}) {
  final controller = StreamController<TarEntry>(sync: true);

  // Manually add files to the controller
  final exampleFile = File('example/ft_example_tar_helper.dart');
  if (exampleFile.existsSync()) {
    TarHelper.addFileToTarEntry(exampleFile, basePath, controller, logBuffer);
  }

  // Add another file
  final readmeFile = File('README.md');
  if (readmeFile.existsSync()) {
    TarHelper.addFileToTarEntry(readmeFile, basePath, controller, logBuffer);
  }

  // Close the controller to end the stream
  controller.close();

  TarHelper.archive(
    ArchiveOptions(
      entities: [], // Empty, because we use external controller
      basePath: basePath,
      outputFile: tarFile,
      useGzip: useGzip ?? false,
      logBuffer: logBuffer,
      controller: controller, // Use external controller
      autoFillEntities: false, // Do not auto-fill entities
      onSuccess: () {
        print('archive with external controller success!');
        print('archive log:\n${logBuffer.toString()}');
      },
      onError: (error, stack) {
        print('archive failure: $error');
        print('archive log:\n${logBuffer.toString()}');
      },
    ),
  );
}
