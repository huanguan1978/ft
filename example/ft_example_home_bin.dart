import 'dart:io';
import 'package:filetools/ft.dart';

// add home bin (~/bin|~/.local/bin) to $PATH
void main(List<String> args) async {
  var verbose = args.contains('-v');
  final cliAnsi = CliAnsi(CliAnsi.isSupportAnsi);
  final logger = verbose
      ? CliVerboseLogger(ansi: cliAnsi)
      : CliStandardLogger(ansi: cliAnsi);

  logger.stdout("d, set PATH for $ftOs...");
  final homeDir = homePath;
  if (homeDir.isEmpty) {
    logger.stderr("e, HOME not set. HOME not found.");
    exit(1);
  }

  final homeBin = HomeBin(logger, homeDir);

  // 1. Check if target directory is already in the current PATH environment
  final (existPath, userBinPath) = homeBin.inPath();
  if (existPath) {
    logger.stdout('i, exist path $userBinPath, exit.');
    exit(0);
  }

  // 2. Get shell information (Windows returns special values)
  final shellInfo = homeBin.profile();
  if (shellInfo == null) {
    logger.stderr("e, failed to get shell info.");
    exit(1);
  }
  final (shellName, profilePath) = shellInfo;

  // e. Add PATH to system (using setx or modifying profile)
  bool added = false;
  try {
    added = homeBin.addPathToSystem(
      profile: profilePath,
      path: userBinPath,
      shell: shellName,
    );
  } catch (e, s) {
    logger.stderr('e, addPathToSystem\n, $e, $s');
  }

  if (!added) exit(1);
  logger.stdout("i, complete. Successfully added `$userBinPath` to PATH.");
  if (Platform.isWindows) {
    logger.stdout("w, restart your terminal or relogin take effect.");
  } else {
    logger.stdout(
      "w, restart your terminal or run `source $profilePath` for changes to take effect.",
    );
  }

  exit(0);
}
