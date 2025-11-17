import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import 'package:filetools/ft.dart';

void main(List<String> args) {
  final verbose = args.contains('-v') || args.contains('--verbose');
  final logger = verbose ? Logger.verbose(logTime: false) : Logger.standard();

  final version = args.contains('--version');
  if (version) logger.stdout('i, version:$version');

  final gen = args.contains('--config_gen');
  if (gen) {
    var config = p.join(p.current, ftTmplName);
    final argMap = parseAssigns(args);
    if (argMap case {'--config': String config_} when config_.isNotEmpty) {
      config = p.normalize(expandTilde(config_));
    }

    final file = File(config);
    if (file.existsSync()) {
      logger.stderr('w, generate aborted: already exist $config');
      exit(ExitCodeExt.cantCreate.code);
    } else {
      try {
        file.writeAsStringSync(ftTmplText);
      } on FileSystemException catch (e, s) {
        logger
          ..stderr('e, generate aborted: $e')
          ..stderr(kIsDebug ? '$s' : '');
        exit(ExitCodeExt.cantCreate.code);
      } catch (e, s) {
        logger
          ..stderr('e, generate aborted: $e')
          ..stderr(kIsDebug ? '$s' : '');

        exit(ExitCodeExt.cantCreate.code);
      }
      logger.stdout('i, generated success, $config');
      exit(ExitCodeExt.success.code);
    }
  }

  // ignore: unused_local_variable
  // final results = parser.parse(args);
  final runner = cmdRunner(args);
  if (args.isEmpty) {
    runner.printUsage();
    exitCode = ExitCodeExt.usage.code;
    return;
  }

  runner.run(args).catchError((error) {
    if (error is! UsageException) throw error;
    logger.stderr(error.toString().split('\n\n').first);
    // runner.printUsage();
    exitCode = ExitCodeExt.usage.code;
    return;
  });

  // exitCode = ExitCodeExt.success.code;
  // end_main
}
