part of '../../ft.dart';

class HomeBin {
  final Logger logger;
  final String homeDir;

  HomeBin(this.logger, this.homeDir);

  /// Get current shell type and its configuration file path (cross-platform)
  ///
  /// Returns null if unable to determine or unsupported.
  (String, String)? profile() {
    if (isWindows) return ('windows', '');

    final shellPath = environ['SHELL'] ?? '';
    String shell = 'sh';
    String profile = p.join(homeDir, '.profile');

    if (shellPath.isEmpty) logger.trace("w, SHELL not set. use default.");

    final currShell = p.basename(shellPath);
    switch (currShell) {
      case 'zsh':
        profile = p.join(homeDir, '.zprofile');
        if (!File(profile).existsSync()) profile = p.join(homeDir, '.zshrc');
        break;
      case 'bash':
        profile = p.join(homeDir, '.bash_profile');
        if (!File(profile).existsSync()) profile = p.join(homeDir, '.profile');
        break;
      case 'fish':
        profile = p.join(homeDir, '.config', 'fish', 'config.fish');
        break;
      case 'sh':
      case 'dash':
      case 'ash':
      default:
        logger.trace("w, unsupported shell: $currShell.");
    }

    return ((shell == currShell) ? shell : currShell, profile);
  }

  /// Check  `~/bin` or `~/.local/bin` in PATH.
  /// Return a tuple (exist, path).
  (bool, String) inPath() {
    final currentPath = environ['PATH'] ?? '';
    final pathDelimiter = isWindows ? ';' : ':';
    final dirs = currentPath.split(pathDelimiter);

    final binDir = Directory(p.join(homeDir, 'bin'));
    final localBinDir = Directory(p.join(homeDir, '.local', 'bin'));

    if (!binDir.existsSync()) binDir.createSync(recursive: true);
    if (!localBinDir.existsSync()) localBinDir.createSync(recursive: true);

    final binPath = binDir.path;
    final localBinPath = localBinDir.path;
    for (final dir in dirs) {
      if (dir.isEmpty) continue; // Skip empty path entries
      if (p.equals(dir, localBinPath)) return (true, localBinPath);
      if (p.equals(dir, binPath)) return (true, binPath);
    }
    return (false, localBinPath);
  }

  // locate a program file [executable] in the user's path
  String where(String executable) {
    var output = '';
    if (isDesktop) {
      final cmd = isWindows ? 'where' : 'which';
      final args = [executable];
      final result = Process.runSync(cmd, args);
      if (result.exitCode == 0) output = result.stdout.toString().trim();
    }
    return output;
  }

  /// Attempts to add [path] to system environment.
  bool addPathToSystem({
    required String shell, // For Unix-like
    required String profile, // For Unix-like
    required String path,
  }) =>
      Platform.isWindows
          ? _addPathToWindowsEnvironment(path)
          : _addPathToUnixLikeProfile(shell, profile, path);

// Helper Method: Modify Windows PATH environment (using setx)
  bool _addPathToWindowsEnvironment(String path) {
    final pathResult = Process.runSync('cmd', ['/c', 'echo', '%PATH%']);
    final currPath = pathResult.stdout.toString().trim();

    var inPath = false;
    final dirs =
        currPath.isNotEmpty ? currPath.split(semicolonDelimiter) : <String>[];
    for (final dir in dirs) {
      if (dir.isEmpty) continue; // Skip empty path entries
      if (p.windows.equals(dir, path)) {
        inPath = true;
        break;
      }
    }

    if (inPath) return true;

    // Execute setx command to add the path
    final result =
        Process.runSync('setx', ['PATH', '%PATH%$semicolonDelimiter$path']);

    if (result.exitCode == 0) return true;

    logger.stderr("e, Failed run setx. Exit code: ${result.exitCode}");
    logger.stderr("e, StdErr: ${result.stderr}");
    return false;
  }

// Helper Method: Modify Unix-like profile file
  bool _addPathToUnixLikeProfile(String shell, String profile, String path) {
    final profileFile = File(profile);
    final line = (shell == 'fish')
        ? 'fish_add_path "$path"'
        : 'export PATH="$path:\$PATH"';

    logger.stdout("d, Adding line: $line");

    bool inProfile = false;
    if (profileFile.existsSync()) {
      final content = profileFile.readAsStringSync();
      final escapedTargetDir = RegExp.escape(path);

      // Regex matching for both export PATH and fish_add_path
      final regex = RegExp(r'(export\s+PATH="[^"]*' +
          // ignore: prefer_interpolation_to_compose_strings
          escapedTargetDir +
          r'[^"]*")|'
              r'(fish_add_path\s+"' +
          escapedTargetDir +
          r'")');

      if (regex.hasMatch(content)) inProfile = true;
    }

    if (inProfile) return true;
    if (!profileFile.existsSync()) profileFile.createSync(recursive: true);
    profileFile.writeAsStringSync('\n# HomeBin\n$line\n',
        mode: FileMode.append);

    return true;
  }

  // cls_lastline
}
