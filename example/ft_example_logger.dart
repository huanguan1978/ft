import 'dart:async';
import 'dart:io';

import 'package:filetools/ft.dart';

void main(List<String> args) {
  cliLogger(args);
  // fileLogger(args);
  // strbufLogger(args);
}

void cliLogger(List<String> args) {
  var verbose = args.contains('-v');
  final cliAnsi = CliAnsi(CliAnsi.isSupportAnsi);
  final logger = verbose
      ? CliVerboseLogger(ansi: cliAnsi)
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

void fileLogger(List<String> args) {
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

void strbufLogger(List<String> args) {
  var verbose = args.contains('-v');

  final strbuf = StringBuffer();
  final logger = StrBufLogger(strbuf, verbose);

  logger.stdout('Hello world!');
  logger.trace('d, message 1');

  final progress = logger.progress("doing some work");
  Future.delayed(Duration(seconds: 3)).then((value) {
    logger.trace('d, message 11');
    sleep(Duration(seconds: 1));
    logger.trace('d, message 12');
  }).whenComplete(() {
    progress.finish(message: 'progress completed');
    // strbuf cleanup
    print(strbuf.toString());
    strbuf.clear();
  });
  logger.stdout('bye.');
}
