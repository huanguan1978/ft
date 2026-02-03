part of '../../ft.dart';

/// extension Command, override invocation
extension CommandExtension on Command {
  String get invocation {
    var parents = [name];
    for (var command = parent; command != null; command = command.parent) {
      parents.add(command.name);
    }
    parents.add(runner!.executableName);

    var invocation = parents.reversed.join(' ');
    return subcommands.isNotEmpty
        ? '$invocation <subcommand> [arguments]'
        : '$invocation <source> [arguments]';
  }

  // cls_lastline
}

void traceGlobalParam(Logger logger, FtRunner ftRun, String source) {
  logger.trace('i, pattern:${ftRun.ftPattern}, excludes:${ftRun.ftExcludes}');
  if (ftRun.ftFields.contains(FormatField.time.name)) {
    logger.trace('i, time_type:${ftRun.ftTimeType}');
  }
  if (ftRun.ftDefine.isNotEmpty) logger.trace('i, define:${ftRun.ftDefine}');
  if (ftRun.ftSizes.isNotEmpty) {
    logger.trace('i, sizes:${ftRun.ftSizes}, ${hrSizes(ftRun.ftSizes)}');
  }
  if (ftRun.ftTimes.isNotEmpty) {
    logger.trace('i, times:${ftRun.ftTimes}');
  }
  logger.trace('i, source:$source');
}

class ListCommand extends Command {
  @override
  final name = PathAction.list.name;
  @override
  final description = "listing all entities that match a glob \n\n"
      "e.g. list CWD, use . or \$PWD (Unix-like) or \$CURDIR (ft define) \n"
      "  ft list . \n\n"
      "e.g. list CWD, all *.md, use variable name. \n"
      r"  ft list '\$CURDIR' --pattern='$mdfiles' --define='mdfiles=**.md'"
      "\n\n"
      "e.g. list CWD, excluding hiddens, verbose, pretty output. \n"
      "  ft list . --excludes='/**/.**' --fields=ok,action,type,perm,time,size -v \n\n"
      "e.g. list CWD, only hiddens, verbose output, show extra. \n"
      "  ft list . --excludes='/**/.**' --no-matched --fileds=extra -v \n\n"
      "e.g. list ~/Downloads, file size >= 100M, show size. \n"
      "  ft list ~/Downloads --size_ge=100m --fields=size  \n\n"
      "e.g. list ~/Downloads, file time <= 20240101, show time. \n"
      "  ft list ~/Downloads --time_le=20240101 --fields=time\n\n"
      "e.g. list ~/Downloads, use relative time (quantity unit ago). \n"
      "  ft list ~/Downloads --size_ge=100m --time_le='1 month ago' --fields=size,time";

  final typeNames = ['file', 'directory', 'link', 'notFound'];
  final typeDefault = 'file';

  ListCommand() {
    argParser
      ..addFlag(
        'matched',
        negatable: true,
        defaultsTo: true,
        help: 'Show all matches if enabled, otherwise, show non-matches.',
      )
      ..addOption(
        'type',
        defaultsTo: typeDefault,
        allowed: typeNames,
        allowedHelp: {
          'file': 'is file',
          'directory': 'is directory',
          'link': 'is filesystem link',
        },
        valueHelp: 'file',
        help: 'match type (file, directory, link)',
      );
  }

  @override
  String get invocation {
    var parents = [name];
    for (var command = parent; command != null; command = command.parent) {
      parents.add(command.name);
    }
    parents.add(runner!.executableName);

    var invocation = parents.reversed.join(' ');
    return subcommands.isNotEmpty
        ? '$invocation <subcommand> [arguments]'
        : '$invocation <source> [arguments]';
  }

  @override
  void run() {
    final ftRun = runner as FtRunner;
    final v = ftRun.ftVerbose;
    final logger = ftRun.ftLogger;

    late final String source;
    late final String type;
    late final bool matched;
    try {
      final args = globalResults?.arguments ?? [];
      final config = configFromArgParse(ftRun.argParser, args);
      final define = getDefine(config, globalResults);
      final env = {...Platform.environment, ...define};

      ftRun
        ..ftConfig = config
        ..ftDefine = define
        ..ftEnv = env
        ..ftPattern = getOpiton('pattern', config, gRes: globalResults)
        ..ftExcludes = getOpitons('excludes', config, gRes: globalResults)
        ..ftFields = getOpitons('fields', config,
            gRes: globalResults, datalist: fieldNames)
        ..ftSizes = getSizes(config, globalResults)
        ..ftTimes = getTimes(config, globalResults)
        ..ftErrExit =
            getFlag('errexit', config, defaultTo: true, gRes: globalResults)
        ..ftTimeType = getOpiton('time_type', ftRun.ftConfig,
            gRes: globalResults,
            defaultTo: timeTypeDefault,
            datalist: timeTypes);

      source = getSource(ftRun.ftConfig, globalResults,
          aRes: argResults, env: ftRun.ftEnv);
      type = getOpiton('$name.type', ftRun.ftConfig,
          aRes: argResults, defaultTo: typeDefault, datalist: typeNames);
      matched = getFlag('$name.matched', ftRun.ftConfig,
          aRes: argResults, defaultTo: true);
    } on UsageException catch (e, s) {
      logger.stderr('e, $name.run, $e\n $s');
      rethrow;
    } catch (e, s) {
      logger.stderr('e, $name.run, $e\n $s');
      throw UsageException(e.toString(), '');
    }

    if (v) traceGlobalParam(logger, ftRun, source);
    final action = BasicPathAction(
      source,
      pattern: ftRun.ftPattern,
      excludes: ftRun.ftExcludes,
      sizes: ftRun.ftSizes,
      times: ftRun.ftTimes,
      env: ftRun.ftEnv,
      verbose: ftRun.ftVerbose,
      cancelOnError: ftRun.ftErrExit,
      statTimeType: StatTimeType.values.byName(ftRun.ftTimeType),
    )
      ..logger = logger
      ..fmtFields = ftRun.ftFields;

    final err = action.validator();
    if (err.isNotEmpty) throw UsageException('err: chk, $err', '');
    action.argErr = err;

    final fseType = switch (type) {
      'file' => FileSystemEntityType.file,
      'directory' => FileSystemEntityType.directory,
      'link' => FileSystemEntityType.link,
      'unixDomainSock' => FileSystemEntityType.unixDomainSock,
      'pipe' => FileSystemEntityType.pipe,
      _ => FileSystemEntityType.notFound,
    };
    if (v) logger.trace('i, type:$fseType, matched:$matched.');
    action.list(matched: matched, fseType: fseType);

    // end run
  }

  // cls_last_line
}

class SearchCommand extends Command {
  @override
  final name = PathAction.search.name;
  @override
  final description = "search with regexp or replace.  \n\n"
      "e.g. search CWD, yaml files, with vesion: 1.0.0, use literal pattern \n"
      "  ft search . --pattern='**.yaml' --regexp='version: 1.0.0' \n\n"
      "e.g. search CWD, yaml files, with vesion: 1.0.\\d+, use regex pattern, enable escape \n"
      "  ft search . --pattern='**.yaml' --regexp='version: 1.0.\\d+' --escape \n\n"
      "e.g. search CWD, toml files, with vesion: 1.0.0, use extmime. \n"
      "  ft search . --pattern='**.{tml,toml}' --regexp='version: 1.0.0' --extmime='tml=text/toml,toml=application/toml' \n\n"
      "e.g. search CWD, yaml files, vesion 1.0.0 replace to 1.0.1 \n"
      "  ft search . --pattern='**.yaml' --regexp='version: 1.0.0' --replace='version: 1.0.1' \n\n"
      "e.g. search CWD, html files, <div id=\"helloworld\">...</div> \n"
      "  ft search . --pattern='**.{htm,html}' --regexp='<div id=\"helloworld\">.*?<\\/div>' --no-linebyline --res \n\n"
      "e.g. search apache access log, output remote_addr, access_time, use onlygroups \n"
      "  ft search /var/log/httpd/ --pattern='**.log' --regexp='(.*) - - \\[(.*)\\]' --onlygroups ";

  SearchCommand() {
    argParser
      ..addOption(
        'regexp',
        valueHelp: 'pattern',
        help: 'regex pattern',
      )
      ..addMultiOption(
        'extmime',
        help: "ext mime for search (e.g. --extmime='yaml=text/yaml')",
      )
      ..addFlag(
        'linebyline',
        negatable: true,
        defaultsTo: true,
        help: 'line by line file processing',
      )
      ..addFlag(
        'linenum',
        negatable: true,
        defaultsTo: true,
        help: 'linenum output',
      )
      ..addFlag(
        'onlygroups',
        negatable: true,
        defaultsTo: false,
        help: 'only groups output',
      )
      ..addFlag(
        'esc',
        negatable: false,
        help: 'escape regexp special characters.',
      )
      ..addFlag(
        'rei',
        negatable: false,
        help: 'regex use case insensitive.',
      )
      ..addFlag(
        'reu',
        negatable: false,
        help: 'regex use unicode.',
      )
      ..addFlag(
        'res',
        negatable: false,
        help: 'regex use dot all.',
      )
      ..addFlag(
        'rem',
        negatable: false,
        help: 'regex use multiLine.',
      )
      ..addOption(
        'replace',
        help: 'regexp has match to replace',
      );
  }

  @override
  String get invocation {
    var parents = [name];
    for (var command = parent; command != null; command = command.parent) {
      parents.add(command.name);
    }
    parents.add(runner!.executableName);

    var invocation = parents.reversed.join(' ');
    return subcommands.isNotEmpty
        ? '$invocation <subcommand> [arguments]'
        : '$invocation <source> --regexp=<pattern> [arguments]';
  }

  @override
  void run() {
    final ftRun = runner as FtRunner;
    final v = ftRun.ftVerbose;
    final logger = ftRun.ftLogger;

    late final String source;

    late final String regexp;
    late final String replace;
    late final bool rei;
    late final bool reu;
    late final bool res;
    late final bool rem;
    late final bool linebyline;
    late final bool onlygroups;
    late final bool linenum;
    late final bool esc;
    late final List<String> mimeexts;
    try {
      final args = globalResults?.arguments ?? [];
      final config = configFromArgParse(ftRun.argParser, args);
      final define = getDefine(config, globalResults);
      final env = {...Platform.environment, ...define};
      ftRun
        ..ftConfig = config
        ..ftDefine = define
        ..ftEnv = env
        ..ftPattern = getOpiton('pattern', config, gRes: globalResults)
        ..ftExcludes = getOpitons('excludes', config, gRes: globalResults)
        ..ftFields = getOpitons('fields', config,
            gRes: globalResults, datalist: fieldNames)
        ..ftSizes = getSizes(config, globalResults)
        ..ftTimes = getTimes(config, globalResults)
        ..ftErrExit =
            getFlag('errexit', config, defaultTo: true, gRes: globalResults)
        ..ftTimeType = getOpiton('time_type', ftRun.ftConfig,
            gRes: globalResults,
            defaultTo: timeTypeDefault,
            datalist: timeTypes);

      source = getSource(ftRun.ftConfig, globalResults,
          aRes: argResults, env: ftRun.ftEnv);

      regexp = getOpiton('$name.regexp', ftRun.ftConfig, aRes: argResults);
      replace = getOpiton('$name.replace', ftRun.ftConfig,
          aRes: argResults, isNotEmpty: false);
      rei = getFlag('$name.rei', ftRun.ftConfig, aRes: argResults);
      reu = getFlag('$name.reu', ftRun.ftConfig, aRes: argResults);
      res = getFlag('$name.res', ftRun.ftConfig, aRes: argResults);
      rem = getFlag('$name.rem', ftRun.ftConfig, aRes: argResults);

      esc = getFlag('$name.esc', ftRun.ftConfig, aRes: argResults);
      linebyline = getFlag('$name.linebyline', ftRun.ftConfig,
          aRes: argResults, defaultTo: true);
      onlygroups = getFlag('$name.onlygroups', ftRun.ftConfig,
          aRes: argResults, defaultTo: false);
      linenum = getFlag('$name.linenum', ftRun.ftConfig,
          aRes: argResults, defaultTo: true);

      mimeexts = getOpitons('$name.extmime', ftRun.ftConfig, aRes: argResults);
    } on UsageException catch (e, s) {
      logger.stderr('e, $name.run, $e\n $s');
      rethrow;
    } catch (e, s) {
      logger.stderr('e, $name.run, $e\n $s');
      throw UsageException(e.toString(), '');
    }

    if (v) traceGlobalParam(logger, ftRun, source);
    final action = BasicPathAction(
      source,
      pattern: ftRun.ftPattern,
      excludes: ftRun.ftExcludes,
      sizes: ftRun.ftSizes,
      times: ftRun.ftTimes,
      env: ftRun.ftEnv,
      verbose: ftRun.ftVerbose,
      cancelOnError: ftRun.ftErrExit,
      statTimeType: StatTimeType.values.byName(ftRun.ftTimeType),
    )
      ..logger = logger
      ..fmtFields = ftRun.ftFields;

    final err = action.validator();
    if (err.isNotEmpty) throw UsageException('err: chk, $err', '');
    action.argErr = err;

    final escapeRegexp = esc ? RegExp.escape(regexp) : '';
    if (v) {
      logger
        ..trace(
            'i, regexp:$regexp, replace:$replace, linebyline:$linebyline, rei:$rei,reu:$reu,rem:$rem,res:$res. extmime:$mimeexts')
        ..trace('i, escape:$esc, $escapeRegexp');
    }
    final mimeext = <String, String>{};
    if (mimeexts.isNotEmpty) mimeext.addAll(parseAssigns(mimeexts));
    // print(mimeext);
    action.search(
      esc ? escapeRegexp : regexp,
      replace: replace,
      extMime: mimeext,
      lineByLine: linebyline,
      onlyGroups: onlygroups,
      lineNum: linenum,
      reI: rei,
      reU: reu,
      reM: rem,
      reS: res,
    );

    // end run
  }

  // cls_last_line
}

class MirrorCommand extends Command {
  @override
  final name = PathAction.mirror.name;
  @override
  final description = "mirror source file|diretory to target directory \n\n"
      "e.g. mirror CWD to ~/mirrors/ . \n"
      "  ft mirror . ~/mirrors \n\n"
      "e.g. mirror CWD to ~/mirrors/, use absolute directory. \n"
      "  ft mirror . ~/mirrors  --no-relative \n\n"
      "e.g. mirror ~/Documents/docs/ to ~/Downloads/docs/, excluding hiddens. \n"
      "  ft mirror ~/Documents/docs ~/Downloads/docs --excludes='/**/.**' -v ";

  MirrorCommand() {
    argParser.addOption(
      'target',
      valueHelp: 'directory',
      help: 'target directory',
    );
    argParser.addFlag(
      'relative',
      negatable: true,
      defaultsTo: true,
      help: 'mirror source use relative directory.',
    );
    argParser.addOption(
      'tail',
      defaultsTo: '0',
      help: 'tail source injection to target.',
    );
  }

  @override
  String get invocation {
    var parents = [name];
    for (var command = parent; command != null; command = command.parent) {
      parents.add(command.name);
    }
    parents.add(runner!.executableName);

    var invocation = parents.reversed.join(' ');
    return subcommands.isNotEmpty
        ? '$invocation <subcommand> [arguments]'
        : '$invocation <source> <target> [arguments]';
  }

  @override
  void run() {
    final ftRun = runner as FtRunner;
    final v = ftRun.ftVerbose;
    final logger = ftRun.ftLogger;

    late final String source;
    late final String target;
    late final bool relative;
    late final int tail;
    try {
      final args = globalResults?.arguments ?? [];
      final config = configFromArgParse(ftRun.argParser, args);
      final define = getDefine(config, globalResults);
      final env = {...Platform.environment, ...define};
      ftRun
        ..ftConfig = config
        ..ftDefine = define
        ..ftEnv = env
        ..ftPattern = getOpiton('pattern', config, gRes: globalResults)
        ..ftExcludes = getOpitons('excludes', config, gRes: globalResults)
        ..ftFields = getOpitons('fields', config,
            gRes: globalResults, datalist: fieldNames)
        ..ftSizes = getSizes(config, globalResults)
        ..ftTimes = getTimes(config, globalResults)
        ..ftErrExit =
            getFlag('errexit', config, defaultTo: true, gRes: globalResults)
        ..ftTimeType = getOpiton('time_type', ftRun.ftConfig,
            gRes: globalResults,
            defaultTo: timeTypeDefault,
            datalist: timeTypes);

      source = getSource(ftRun.ftConfig, globalResults,
          aRes: argResults, env: ftRun.ftEnv);
      target = getTarget('$name.target', ftRun.ftConfig,
          aRes: argResults, env: ftRun.ftEnv, source: source);
      tail =
          getInt('$name.tail', ftRun.ftConfig, aRes: argResults, defaultTo: 0);
      relative = getFlag('$name.relative', ftRun.ftConfig,
          aRes: argResults, defaultTo: true);
    } on UsageException catch (_, __) {
      rethrow;
    } catch (e) {
      throw UsageException(e.toString(), '');
    }

    var toDir = Directory(target);
    final isWritable = isDirWritable(toDir);
    if (!isWritable) {
      throw UsageException('err: not writable. $target', '');
    }

    if (v) traceGlobalParam(logger, ftRun, source);
    final action = BasicPathAction(
      source,
      pattern: ftRun.ftPattern,
      excludes: ftRun.ftExcludes,
      sizes: ftRun.ftSizes,
      times: ftRun.ftTimes,
      env: ftRun.ftEnv,
      verbose: ftRun.ftVerbose,
      cancelOnError: ftRun.ftErrExit,
      statTimeType: StatTimeType.values.byName(ftRun.ftTimeType),
    )
      ..logger = logger
      ..fmtFields = ftRun.ftFields;
    final err = action.validator(target: target);
    if (err.isNotEmpty) throw UsageException('err: chk, $err', '');
    action.argErr = err;

    final srcPath = action.path;
    String dstPath = target;
    if (tail > 0) dstPath = p.join(target, pathtail(srcPath, tail));
    if (v) logger.trace('i, relative:$relative, tail:$tail, target:$dstPath');

    toDir = Directory(dstPath);
    action.mirror(toDir, relative);
  }

  // cls_last_line
}

class CleanCommand extends Command {
  @override
  final name = PathAction.clean.name;
  @override
  final description = "clean source file|diretory \n\n"
      "e.g. clean one file ./logs/error.log . \n"
      "  ft clean ./logs/error.log \n\n"
      "e.g. clean all files in ./logs/ . \n"
      "  ft clean ./logs \n\n"
      "e.g. clean CWD, autosave files (*{~,#}), verbose output. \n"
      "  ft clean . --pattern='**{~,#}' -v \n\n"
      "e.g. clean ~/Downloads, all macos desktop services store. \n"
      "  ft clean ~/Downloads, --pattern='**.DS_Store' \n\n"
      "e.g. clean ~/Downloads/README.md/* \n"
      "  ft clean ~/Downloads --pattern='*README.md/**' \n\n"
      "e.g. clean ~/Downloads, empty files (file size <=1). \n"
      "  ft clean ~/Downloads --size_le=1 \n\n"
      "e.g. clean ~/Downloads, April Fools' Day Documents. \n"
      "  ft clean ~/Downloads --time_ge=20240401 --time_le=20240402";

  @override
  String get invocation {
    var parents = [name];
    for (var command = parent; command != null; command = command.parent) {
      parents.add(command.name);
    }
    parents.add(runner!.executableName);

    var invocation = parents.reversed.join(' ');
    return subcommands.isNotEmpty
        ? '$invocation <subcommand> [arguments]'
        : '$invocation <source> [arguments]';
  }

  @override
  void run() {
    final ftRun = runner as FtRunner;
    final v = ftRun.ftVerbose;
    final logger = ftRun.ftLogger;

    late final String source;
    try {
      final args = globalResults?.arguments ?? [];
      final config = configFromArgParse(ftRun.argParser, args);
      final define = getDefine(config, globalResults);
      final env = {...Platform.environment, ...define};
      ftRun
        ..ftConfig = config
        ..ftDefine = define
        ..ftEnv = env
        ..ftPattern = getOpiton('pattern', config, gRes: globalResults)
        ..ftExcludes = getOpitons('excludes', config, gRes: globalResults)
        ..ftFields = getOpitons('fields', config,
            gRes: globalResults, datalist: fieldNames)
        ..ftSizes = getSizes(config, globalResults)
        ..ftTimes = getTimes(config, globalResults)
        ..ftErrExit =
            getFlag('errexit', config, defaultTo: true, gRes: globalResults)
        ..ftTimeType = getOpiton('time_type', ftRun.ftConfig,
            gRes: globalResults,
            defaultTo: timeTypeDefault,
            datalist: timeTypes);

      source = getSource(ftRun.ftConfig, globalResults,
          aRes: argResults, env: ftRun.ftEnv);
    } on UsageException catch (_, __) {
      rethrow;
    } catch (e) {
      throw UsageException(e.toString(), '');
    }

    if (v) traceGlobalParam(logger, ftRun, source);
    final action = BasicPathAction(
      source,
      pattern: ftRun.ftPattern,
      excludes: ftRun.ftExcludes,
      sizes: ftRun.ftSizes,
      times: ftRun.ftTimes,
      env: ftRun.ftEnv,
      verbose: ftRun.ftVerbose,
      cancelOnError: ftRun.ftErrExit,
      statTimeType: StatTimeType.values.byName(ftRun.ftTimeType),
    )
      ..logger = logger
      ..fmtFields = ftRun.ftFields;
    final err = action.validator();
    if (err.isNotEmpty) throw UsageException('err: chk, $err', '');

    action.clean();
    // action.deleteEmptyDir();

    // end run
  }

  // cls_last_line
}

class WipeCommand extends Command {
  @override
  final name = PathAction.wipe.name;
  @override
  final description = "secure wipe source file|diretory \n\n"
      "e.g. secure wipe file ~/Documents/docs/15816.pdf \n"
      "  ft erase ~/Documents/docs/15816.pdf \n\n"
      "e.g. secure wipe file, overwrite multiple times use (low, medium) \n"
      "  ft erase ~/Documents/docs/15815.pdf --levels=low,medium \n\n"
      "e.g. secure wipe directory ~/Documents/mdocs. \n"
      "  ft erase ~/Documents/mdocs \n\n";

  final levelNames = FileWriteLevel.values.asNameMap().keys;
  final levelDefaults = [FileWriteLevel.medium.name];

  WipeCommand() {
    argParser.addMultiOption(
      'levels',
      defaultsTo: levelDefaults,
      allowed: levelNames,
      allowedHelp: {
        'low': 'file overwritten with zeros (0)',
        'medium': 'file overwritten with random bits (0|1)',
        'high': 'file overwritten with random bytes (0-255)',
      },
      help: 'security levels for file overwrite',
    );
  }

  @override
  String get invocation {
    var parents = [name];
    for (var command = parent; command != null; command = command.parent) {
      parents.add(command.name);
    }
    parents.add(runner!.executableName);

    var invocation = parents.reversed.join(' ');
    return subcommands.isNotEmpty
        ? '$invocation <subcommand> [arguments]'
        : '$invocation <source> [arguments]';
  }

  @override
  void run() {
    final ftRun = runner as FtRunner;
    final v = ftRun.ftVerbose;
    final logger = ftRun.ftLogger;

    late final String source;
    late final List<String> levels;
    try {
      final args = globalResults?.arguments ?? [];
      final config = configFromArgParse(ftRun.argParser, args);
      final define = getDefine(config, globalResults);
      final env = {...Platform.environment, ...define};
      ftRun
        ..ftConfig = config
        ..ftDefine = define
        ..ftEnv = env
        ..ftPattern = getOpiton('pattern', config, gRes: globalResults)
        ..ftExcludes = getOpitons('excludes', config, gRes: globalResults)
        ..ftFields = getOpitons('fields', config,
            gRes: globalResults, datalist: fieldNames)
        ..ftSizes = getSizes(config, globalResults)
        ..ftTimes = getTimes(config, globalResults)
        ..ftErrExit =
            getFlag('errexit', config, defaultTo: true, gRes: globalResults)
        ..ftTimeType = getOpiton('time_type', ftRun.ftConfig,
            gRes: globalResults,
            defaultTo: timeTypeDefault,
            datalist: timeTypes);

      source = getSource(ftRun.ftConfig, globalResults,
          aRes: argResults, env: ftRun.ftEnv);
      levels = getOpitons('levels', config, aRes: argResults);
    } on UsageException catch (_, __) {
      rethrow;
    } catch (e) {
      throw UsageException(e.toString(), '');
    }

    if (v) traceGlobalParam(logger, ftRun, source);
    final action = BasicPathAction(
      source,
      pattern: ftRun.ftPattern,
      excludes: ftRun.ftExcludes,
      sizes: ftRun.ftSizes,
      times: ftRun.ftTimes,
      env: ftRun.ftEnv,
      verbose: ftRun.ftVerbose,
      cancelOnError: ftRun.ftErrExit,
      statTimeType: StatTimeType.values.byName(ftRun.ftTimeType),
    )
      ..logger = logger
      ..fmtFields = ftRun.ftFields;
    final err = action.validator();
    if (err.isNotEmpty) throw UsageException('err: chk, $err', '');
    action.argErr = err;

    action.wipe(levels);
    // action.deleteEmptyDir();
  }

  // cls_last_line
}

class RmDirCommand extends Command {
  @override
  final name = PathAction.rmdir.name;
  @override
  final description = "remove empty source directory \n\n"
      "e.g. remove CWD any empty directory, verbose output. \n"
      "  ft rmdir . -v \n\n"
      "e.g. rmdir ~/Documents/mdocs, pretty output. \n"
      "  ft rmdir ~/Documents/mdocs --fields=ok,action,type -v \n\n"
      "e.g. rmdir ~/Documents/mdocs, force remove if not empty. \n"
      "  ft rmdir ~/Documents/mdocs --fields=ok,action,type --force -v \n\n"
      "e.g. rmdir ~/Documents/mdocs, keep top source directory. \n"
      "  ft rmdir ~/Documents/mdocs --fields=ok,action,type --force --keeptop -v";

  RmDirCommand() {
    argParser
      ..addFlag(
        'force',
        negatable: false,
        defaultsTo: false,
        help: 'force remove if not empty.',
      )
      ..addFlag(
        'keeptop',
        negatable: false,
        defaultsTo: false,
        help: 'keep top (source) directory.',
      );
  }

  @override
  String get invocation {
    var parents = [name];
    for (var command = parent; command != null; command = command.parent) {
      parents.add(command.name);
    }
    parents.add(runner!.executableName);

    var invocation = parents.reversed.join(' ');
    return subcommands.isNotEmpty
        ? '$invocation <subcommand> [arguments]'
        : '$invocation <source> [arguments]';
  }

  @override
  void run() {
    final ftRun = runner as FtRunner;
    final v = ftRun.ftVerbose;
    final logger = ftRun.ftLogger;

    late final String source;
    late final bool force;
    late final bool keeptop;
    try {
      final args = globalResults?.arguments ?? [];
      final config = configFromArgParse(ftRun.argParser, args);
      final define = getDefine(config, globalResults);
      final env = {...Platform.environment, ...define};
      ftRun
        ..ftConfig = config
        ..ftDefine = define
        ..ftEnv = env
        ..ftPattern = getOpiton('pattern', config, gRes: globalResults)
        ..ftExcludes = getOpitons('excludes', config, gRes: globalResults)
        ..ftFields = getOpitons('fields', config,
            gRes: globalResults, datalist: fieldNames)
        ..ftSizes = getSizes(config, globalResults)
        ..ftTimes = getTimes(config, globalResults)
        ..ftErrExit =
            getFlag('errexit', config, defaultTo: true, gRes: globalResults)
        ..ftTimeType = getOpiton('time_type', ftRun.ftConfig,
            gRes: globalResults,
            defaultTo: timeTypeDefault,
            datalist: timeTypes);

      source = getSource(ftRun.ftConfig, globalResults,
          aRes: argResults, env: ftRun.ftEnv);
      force = getFlag('$name.force', ftRun.ftConfig,
          aRes: argResults, defaultTo: false);
      keeptop = getFlag('$name.keeptop', ftRun.ftConfig,
          aRes: argResults, defaultTo: false);
    } on UsageException catch (_, __) {
      rethrow;
    } catch (e) {
      throw UsageException(e.toString(), '');
    }

    if (v) traceGlobalParam(logger, ftRun, source);
    final action = BasicPathAction(
      source,
      pattern: ftRun.ftPattern,
      excludes: ftRun.ftExcludes,
      sizes: ftRun.ftSizes,
      times: ftRun.ftTimes,
      env: ftRun.ftEnv,
      verbose: ftRun.ftVerbose,
      cancelOnError: ftRun.ftErrExit,
      statTimeType: StatTimeType.values.byName(ftRun.ftTimeType),
    )
      ..logger = logger
      ..fmtFields = ftRun.ftFields;
    final err = action.validator();
    if (err.isNotEmpty) throw UsageException('err: chk, $err', '');
    action.argErr = err;

    if (v) logger.trace('i, force:$force, removesource:$keeptop');
    action.rmdir(force: force, keeptop: keeptop);
  }

  // cls_last_line
}

class FdupsCommand extends Command {
  @override
  final name = PathAction.fdups.name;
  @override
  final description = "find duplicate files from source diretory \n\n"
      "e.g. fdups from ~/Documents/mdocs. \n"
      "  ft fdups ~/Documents/mdocs \n\n"
      "e.g. fdups from  ~/Documents/mdocs. pretty output. \n"
      "  ft fdups ~/Documents/mdocs --fields=ok,action,type -v";

  @override
  String get invocation {
    var parents = [name];
    for (var command = parent; command != null; command = command.parent) {
      parents.add(command.name);
    }
    parents.add(runner!.executableName);

    var invocation = parents.reversed.join(' ');
    return subcommands.isNotEmpty
        ? '$invocation <subcommand> [arguments]'
        : '$invocation <source> [arguments]';
  }

  @override
  void run() {
    final ftRun = runner as FtRunner;
    final v = ftRun.ftVerbose;
    final logger = ftRun.ftLogger;

    late final String source;
    try {
      final args = globalResults?.arguments ?? [];
      final config = configFromArgParse(ftRun.argParser, args);
      final define = getDefine(config, globalResults);
      final env = {...Platform.environment, ...define};
      ftRun
        ..ftConfig = config
        ..ftDefine = define
        ..ftEnv = env
        ..ftPattern = getOpiton('pattern', config, gRes: globalResults)
        ..ftExcludes = getOpitons('excludes', config, gRes: globalResults)
        ..ftFields = getOpitons('fields', config,
            gRes: globalResults, datalist: fieldNames)
        ..ftSizes = getSizes(config, globalResults)
        ..ftTimes = getTimes(config, globalResults)
        ..ftErrExit =
            getFlag('errexit', config, defaultTo: true, gRes: globalResults)
        ..ftTimeType = getOpiton('time_type', ftRun.ftConfig,
            gRes: globalResults,
            defaultTo: timeTypeDefault,
            datalist: timeTypes);

      source = getSource(ftRun.ftConfig, globalResults,
          aRes: argResults, env: ftRun.ftEnv);
    } on UsageException catch (_, __) {
      rethrow;
    } catch (e) {
      throw UsageException(e.toString(), '');
    }

    if (v) traceGlobalParam(logger, ftRun, source);
    final action = BasicPathAction(
      source,
      pattern: ftRun.ftPattern,
      excludes: ftRun.ftExcludes,
      sizes: ftRun.ftSizes,
      times: ftRun.ftTimes,
      env: ftRun.ftEnv,
      verbose: ftRun.ftVerbose,
      cancelOnError: ftRun.ftErrExit,
      statTimeType: StatTimeType.values.byName(ftRun.ftTimeType),
    )
      ..logger = logger
      ..fmtFields = ftRun.ftFields;
    final err = action.validator();
    if (err.isNotEmpty) throw UsageException('err: chk, $err', '');
    action.argErr = err;

    action.fdups();
  }

  // cls_last_line
}

class ArchiveCommand extends Command {
  @override
  final name = PathAction.archive.name;
  @override
  final description = "archive source file|directory to target file. \n\n"
      "e.g. archvie CWD, target file is basename(CWD).tgz \n"
      "  ft archive . \n\n"
      "e.g. archvie directory ~/Documents/mdocs to CWD. \n"
      "  ft archive ~/Documents/mdocs ./mdocs.tgz \n\n"
      "e.g. archvie direcotry ~/Documents/mdocs to ~/Downloads/mdocs2.tgz, use absolute directory. \n"
      "  ft archive ~/Documents/mdocs ~/Downloads/mdocs2.tgz --no-relative \n\n"
      "e.g. archvie directory ~/Downloads, pictures, to ~/Downloads/pics1.tar, not compresse. \n"
      "  ft archive ~/Downloads ~/Downloads/pic1.tar --type=tar --pattern='**.{jpg,jpeg,png,gif,bmp,tif,tiff,webp,svg,ico}' ";

  final typeNames = ArchiveType.values.asNameMap().keys.toList();
  final typeDefault = ArchiveType.tgz.name;

  ArchiveCommand() {
    argParser.addOption(
      'target',
      valueHelp: 'file',
      help: 'file name',
    );
    argParser.addFlag(
      'relative',
      negatable: true,
      defaultsTo: true,
      help: 'archive source use relative directory.',
    );
    argParser.addOption(
      'tail',
      defaultsTo: '0',
      help: 'tail source injection to target.',
    );
    argParser.addOption(
      'type',
      defaultsTo: typeDefault,
      allowed: typeNames,
      allowedHelp: {
        'tgz': 'tarball use gzip compressed',
        'tar': 'tarball not compressed',
      },
      help: 'file type (tgz, tar)',
    );
  }

  @override
  String get invocation {
    var parents = [name];
    for (var command = parent; command != null; command = command.parent) {
      parents.add(command.name);
    }
    parents.add(runner!.executableName);

    var invocation = parents.reversed.join(' ');
    return subcommands.isNotEmpty
        ? '$invocation <subcommand> [arguments]'
        : '$invocation <source> [target] [arguments]';
  }

  @override
  void run() {
    final ftRun = runner as FtRunner;
    final v = ftRun.ftVerbose;
    final logger = ftRun.ftLogger;

    late final String source;
    late final String target;
    late final bool relative;
    late final int tail;
    late String type;
    try {
      final args = globalResults?.arguments ?? [];
      final config = configFromArgParse(ftRun.argParser, args);
      final define = getDefine(config, globalResults);
      final env = {...Platform.environment, ...define};
      ftRun
        ..ftConfig = config
        ..ftDefine = define
        ..ftEnv = env
        ..ftPattern = getOpiton('pattern', config, gRes: globalResults)
        ..ftExcludes = getOpitons('excludes', config, gRes: globalResults)
        ..ftFields = getOpitons('fields', config,
            gRes: globalResults, datalist: fieldNames)
        ..ftSizes = getSizes(config, globalResults)
        ..ftTimes = getTimes(config, globalResults)
        ..ftErrExit =
            getFlag('errexit', config, defaultTo: true, gRes: globalResults)
        ..ftTimeType = getOpiton('time_type', ftRun.ftConfig,
            gRes: globalResults,
            defaultTo: timeTypeDefault,
            datalist: timeTypes);

      source = getSource(ftRun.ftConfig, globalResults,
          aRes: argResults, env: ftRun.ftEnv);
      target = getTarget('$name.target', ftRun.ftConfig,
          aRes: argResults, env: ftRun.ftEnv, source: source);

      type = getOpiton('$name.type', ftRun.ftConfig,
          aRes: argResults, defaultTo: typeDefault, datalist: typeNames);
      tail =
          getInt('$name.tail', ftRun.ftConfig, aRes: argResults, defaultTo: 0);
      relative = getFlag('$name.relative', ftRun.ftConfig,
          aRes: argResults, defaultTo: true);
    } on UsageException catch (_, __) {
      rethrow;
    } catch (e) {
      throw UsageException(e.toString(), '');
    }

    if (v) traceGlobalParam(logger, ftRun, source);
    final action = BasicPathAction(
      source,
      pattern: ftRun.ftPattern,
      excludes: ftRun.ftExcludes,
      sizes: ftRun.ftSizes,
      times: ftRun.ftTimes,
      env: ftRun.ftEnv,
      verbose: ftRun.ftVerbose,
      cancelOnError: ftRun.ftErrExit,
      statTimeType: StatTimeType.values.byName(ftRun.ftTimeType),
    )
      ..logger = logger
      ..fmtFields = ftRun.ftFields;
    final err = action.validator();
    if (err.isNotEmpty) throw UsageException('err: chk, $err', '');
    action.argErr = err;

    var archiveType = switch (type) {
      'tar' => ArchiveType.tar,
      _ => ArchiveType.tgz,
    };
    type = archiveType.name;
    var srcPath = action.path;
    var dstPath = target;

    if (tail > 0) dstPath = p.join(target, pathtail(srcPath, tail));
    (dstPath, archiveType) = dstPath.isEmpty
        ? archiveName(srcPath, archiveType)
        : archiveName(dstPath, archiveType);
    if (v) {
      logger.trace(
          'i, relative:$relative, tail:$tail, target:$dstPath, type:$type');
    }

    late final File archiveFile;
    try {
      archiveFile = File(dstPath)..createSync(recursive: true);
    } catch (e, s) {
      logger.stderr('e, $name, create, $e \n$s');
      return;
    }

    action.archive(archiveFile, archiveType, relative);
    // end run
  }
  // cls_last_line
}

class UnArchiveCommand extends Command {
  @override
  final name = PathAction.unarchive.name;
  @override
  final description = "unarchive tar|tgz source file to target directory \n\n"
      "e.g. unarchive tgz to CWD \n"
      "  ft unarchive ~/Downloads/mdocs2.tgz . \n\n"
      "e.g. unarchive tgz to /tmp/mdocs2/, verbose, pretty output.\n"
      "  ft unarchive ~/Downloads/mdocs2.tgz /tmp/mdocs2 -v --fields=ok,action,type,extra";

  UnArchiveCommand() {
    argParser.addOption(
      'target',
      valueHelp: 'directory',
      help: 'target directory.',
    );
    argParser.addFlag(
      'relative',
      negatable: true,
      defaultsTo: true,
      help: 'mirror source use relative directory.',
    );
    argParser.addOption(
      'tail',
      defaultsTo: '0',
      valueHelp: 'int',
      help: 'tail source injection to target.',
    );
  }

  @override
  String get invocation {
    var parents = [name];
    for (var command = parent; command != null; command = command.parent) {
      parents.add(command.name);
    }
    parents.add(runner!.executableName);

    var invocation = parents.reversed.join(' ');
    return subcommands.isNotEmpty
        ? '$invocation <subcommand> [arguments]'
        : '$invocation <source> <target> [arguments]';
  }

  @override
  void run() {
    final ftRun = runner as FtRunner;
    final v = ftRun.ftVerbose;
    final logger = ftRun.ftLogger;

    late final String source;
    late final String target;
    late final bool relative;
    late final int tail;
    try {
      final args = globalResults?.arguments ?? [];
      final config = configFromArgParse(ftRun.argParser, args);
      final define = getDefine(config, globalResults);
      final env = {...Platform.environment, ...define};
      ftRun
        ..ftConfig = config
        ..ftDefine = define
        ..ftEnv = env
        ..ftPattern = getOpiton('pattern', config, gRes: globalResults)
        ..ftExcludes = getOpitons('excludes', config, gRes: globalResults)
        ..ftFields = getOpitons('fields', config,
            gRes: globalResults, datalist: fieldNames)
        ..ftSizes = getSizes(config, globalResults)
        ..ftTimes = getTimes(config, globalResults)
        ..ftErrExit =
            getFlag('errexit', config, defaultTo: true, gRes: globalResults)
        ..ftTimeType = getOpiton('time_type', ftRun.ftConfig,
            gRes: globalResults,
            defaultTo: timeTypeDefault,
            datalist: timeTypes);

      source = getSource(ftRun.ftConfig, globalResults,
          aRes: argResults, env: ftRun.ftEnv);
      target = getTarget('$name.target', ftRun.ftConfig,
          aRes: argResults, env: ftRun.ftEnv, source: source);
      tail =
          getInt('$name.tail', ftRun.ftConfig, aRes: argResults, defaultTo: 0);
      relative = getFlag('$name.relative', ftRun.ftConfig,
          aRes: argResults, defaultTo: true);
    } on UsageException catch (_, __) {
      rethrow;
    } catch (e) {
      throw UsageException(e.toString(), '');
    }

    if (v) traceGlobalParam(logger, ftRun, source);
    final action = BasicPathAction(
      source,
      pattern: ftRun.ftPattern,
      excludes: ftRun.ftExcludes,
      sizes: ftRun.ftSizes,
      times: ftRun.ftTimes,
      env: ftRun.ftEnv,
      verbose: ftRun.ftVerbose,
      cancelOnError: ftRun.ftErrExit,
      statTimeType: StatTimeType.values.byName(ftRun.ftTimeType),
    )
      ..logger = logger
      ..fmtFields = ftRun.ftFields;
    final err = action.validator(target: target);
    if (err.isNotEmpty) throw UsageException('err: chk, $err', '');
    action.argErr = err;

    final srcPath = action.path;
    String dstPath = target;
    if (tail > 0) dstPath = p.join(target, pathtail(srcPath, tail));
    if (v) logger.trace('i, relative:$relative, tail:$tail, target:$dstPath');

    final toDir = Directory(dstPath);
    final isWritable = isDirWritable(toDir);
    if (!isWritable) {
      throw UsageException('err: not writable. $dstPath', '');
    }

    action.unarchive(toDir, relative, isWritable);
  }

  // cls_last_line
}

class ExecuteCommand extends Command {
  @override
  final name = "execute";
  @override
  final description =
      "execute command blocks defined in `--config`, using `--source` as the working directory.  \n\n"
      "e.g. generate a custom config on current directory. \n"
      "  ft --config_gen \n"
      "  ft --config=ft.yaml --config_gen \n\n"
      "e.g. run commands (default block) in current directory.  \n"
      "  ft execute . --config=ft.yaml \n\n"
      "e.g. run commands (use blocks in order) in current directory.  \n"
      "  ft execute . --config=ft.yaml --blocks=commands,my_commands";

  ExecuteCommand() {
    argParser
      ..addMultiOption(
        'blocks',
        defaultsTo: ['commands'],
        valueHelp: 'name, ...',
        help: 'execute command block in order provided.',
      )
      ..addOption(
        'delay',
        defaultsTo: '1',
        valueHelp: 'seconds',
        help: 'delay between blocks.',
      );
  }

  @override
  String get invocation {
    var parents = [name];
    for (var command = parent; command != null; command = command.parent) {
      parents.add(command.name);
    }
    parents.add(runner!.executableName);

    var invocation = parents.reversed.join(' ');
    return subcommands.isNotEmpty
        ? '$invocation <subcommand> [arguments]'
        : '$invocation <source> --config=<file> --blocks=<name,...> [arguments]';
  }

  @override
  void run() {
    final ftRun = runner as FtRunner;
    final v = ftRun.ftVerbose;
    final logger = ftRun.ftLogger;

    late final String source;
    late final List<String> blocks;
    late final Map<String, List<String>> blockMap;
    late final String delay;
    try {
      final args = globalResults?.arguments ?? [];
      final config = configFromArgParse(ftRun.argParser, args);
      final define = getDefine(config, globalResults);
      final env = {...Platform.environment, ...define};
      ftRun
        ..ftConfig = config
        ..ftDefine = define
        ..ftEnv = env
        ..ftErrExit =
            getFlag('errexit', config, defaultTo: true, gRes: globalResults);

      source = getSource(ftRun.ftConfig, globalResults,
          aRes: argResults, env: ftRun.ftEnv);

      blocks = getOpitons('blocks', config, aRes: argResults);
      blockMap = getExecBlock(ftRun.ftConfig, ftRun.ftEnv, blocks);
      delay =
          getOpiton('delay', ftRun.ftConfig, aRes: argResults, defaultTo: '1');
    } on UsageException catch (_, __) {
      rethrow;
    } catch (e) {
      throw UsageException(e.toString(), '');
    }

    if (v) logger.trace('i, source:$source');

    bool errexit = false;
    for (var block in blocks) {
      var commands = blockMap[block] ?? [];
      if (commands.isEmpty) break;

      for (var cmd in commands) {
        if (errexit) break;

        logger.trace('i, block:$block, cmd:$cmd');
        cmd = expandVar(cmd, map: ftRun.ftEnv);
        final progress = logger.progress('i, block:$block, run:$cmd');

        final parts = parseCliArgs(cmd);
        final args = parts
            .getRange(1, parts.length)
            .map((e) => e.trim())
            .toList()
          ..removeWhere((e) => e.isEmpty);

        final runner = cmdRunner(args);

        runner.run(args).catchError(
          (e, s) {
            if (ftRun.ftErrExit) errexit = true;
            if (exitCode == 0) exitCode = ExitCodeExt.error.code;
            logger.stderr(e.toString().split('\n\n').first);
          },
        ).whenComplete(
          () => progress.finish(message: 'i, block:$block, completed.'),
        );
      }

      if (block.length > 1) sleep(Duration(seconds: int.tryParse(delay) ?? 1));
    }
  }

  // cls_last_line
}

class ShellCommand extends Command {
  @override
  final name = "shell";
  @override
  final description =
      "execute script blocks defined in `--config`, using `--source` as the working directory.  \n\n"
      "e.g. generate a custom config on current directory. \n"
      "  ft --config_gen \n"
      "  ft --config=ft.yaml --config_gen \n\n"
      "e.g. run scripts (default block) in current directory.  \n"
      "  ft shell . --config=ft.yaml \n\n"
      "e.g. run scripts (use blocks in order) in current directory.  \n"
      "  ft shell . --config=ft.yaml --blocks=scripts,my_scripts";

  ShellCommand() {
    argParser
      ..addMultiOption(
        'blocks',
        defaultsTo: ['scripts'],
        valueHelp: 'name, ...',
        help: 'execute script block in order provided.',
      )
      ..addOption(
        'delay',
        defaultsTo: '1',
        valueHelp: 'seconds',
        help: 'delay between blocks.',
      )
      ..addFlag(
        'via_shell',
        defaultsTo: true,
        help: 'run script through the system shell.',
      )
      ..addFlag(
        'keep_quotes',
        defaultsTo: false,
        help: 'keep quotes in script arguments.',
      )
      ..addFlag(
        'expand_path',
        defaultsTo: true,
        help: 'expand tilde (~) and resolve relative paths (., ..) in args.',
      )
      ..addFlag(
        'exit_on_nonzore',
        defaultsTo: false,
        help: 'exit on non-zero exit code.',
      );
  }

  @override
  String get invocation {
    var parents = [name];
    for (var command = parent; command != null; command = command.parent) {
      parents.add(command.name);
    }
    parents.add(runner!.executableName);

    var invocation = parents.reversed.join(' ');
    return subcommands.isNotEmpty
        ? '$invocation <subcommand> [arguments]'
        : '$invocation <source> --config=<file> [arguments]';
  }

  Map<String, String> _getShellVar(Config config) {
    final String name = 'scripts';
    final values = config.optionalStringList(name) ?? [];

    final cmdvar = <String, String>{};
    for (var cmd in values) {
      final name = cmd.split(spaceDelimiter).first.trim().toLowerCase();
      if (name == 'set' || name == 'export') {
        cmdvar.addAll(parseCliAssigns(cmd));
      }
    }
    return cmdvar;
  }

  @override
  void run() {
    final ftRun = runner as FtRunner;
    final v = ftRun.ftVerbose;
    final logger = ftRun.ftLogger;

    late final String source;
    late final bool viaShell;
    late final bool keepQuotes;
    late final bool expandPath;
    late final bool exitOnNonzore;
    late final List<String> blocks;
    late final Map<String, List<String>> blockMap;
    late final String delay;
    try {
      final args = globalResults?.arguments ?? [];
      final config = configFromArgParse(ftRun.argParser, args);
      final define = getDefine(config, globalResults);
      final shvar = _getShellVar(config);
      define.addAll(shvar);
      final env = {...Platform.environment, ...define};
      ftRun
        ..ftConfig = config
        ..ftDefine = define
        ..ftEnv = env
        ..ftErrExit =
            getFlag('errexit', config, defaultTo: true, gRes: globalResults);

      source = getSource(ftRun.ftConfig, globalResults,
          aRes: argResults, env: ftRun.ftEnv);

      viaShell = getFlag('$name.via_shell', ftRun.ftConfig,
          aRes: argResults, defaultTo: true);
      keepQuotes = getFlag('$name.keep_quotes', ftRun.ftConfig,
          aRes: argResults, defaultTo: false);
      expandPath = getFlag('$name.expand_path', ftRun.ftConfig,
          aRes: argResults, defaultTo: true);
      exitOnNonzore = getFlag('$name.exit_on_nonzore', ftRun.ftConfig,
          aRes: argResults, defaultTo: false);

      blocks = getOpitons('blocks', config, aRes: argResults);
      blockMap = getShellBlock(ftRun.ftConfig, ftRun.ftEnv, source, blocks);
      delay =
          getOpiton('delay', ftRun.ftConfig, aRes: argResults, defaultTo: '1');
    } on UsageException catch (_, __) {
      rethrow;
    } catch (e) {
      throw UsageException(e.toString(), '');
    }

    if (v) logger.trace('i, source:$source');

    for (var block in blocks) {
      var commands = blockMap[block] ?? [];
      if (commands.isEmpty) break;

      runScriptSync(
        block,
        commands,
        ftRun,
        source, // workdir
        viaShell: viaShell,
        keepQuotes: keepQuotes,
        expandPath: expandPath,
        exitOnNonzore: exitOnNonzore,
      );

      if (block.length > 1) sleep(Duration(seconds: int.tryParse(delay) ?? 1));
    }
  }

  void runScriptSync(
    String blockName,
    List<String> commands,
    FtRunner ftRun,
    String workdir, {
    bool viaShell = true,
    bool keepQuotes = false,
    bool expandPath = true,
    bool exitOnNonzore = true,
  }) {
    var workenv = ftRun.ftEnv;
    var logger = ftRun.ftLogger;
    // final lpm = LocalProcessManager();
    for (var cmd in commands) {
      logger.trace('i, block:$blockName, cmd:$cmd');
      cmd = expandVar(cmd.trim(), map: ftRun.ftEnv);

      var parts = cmd.split(spaceDelimiter);
      var name = parts.first.trim();
      var args = parts.getRange(1, parts.length).map((e) => e.trim()).toList()
        ..removeWhere((e) => e.isEmpty);
      if (expandPath) {
        args = args.map((e) => expandTilde(e)).toList();
        // logger.trace('i, expandPath, args:$args');
      }
      if (!keepQuotes) {
        args = args.map((e) => e.replaceAll('"', '')).toList();
        args = args.map((e) => e.replaceAll("'", "")).toList();
      }

      var exec = name.toLowerCase();
      var progress = logger.progress(
          'i, block:$blockName, run:$name ${args.join(spaceDelimiter)} ');

      if (exec == 'cd') {
        if (args.isEmpty) {
          workdir = expandTilde('~');
        } else {
          var newdir = args.first.trim();
          if (newdir.startsWith('~')) newdir = expandTilde(newdir);
          workdir = p.normalize(newdir);
        }
        continue;
      }
      if (exec == 'set' || exec == 'export') {
        // workenv.addAll(parseCmdVar(cmd));
        continue;
      }

      try {
        var result = Process.runSync(
          name,
          args,
          workingDirectory: workdir,
          environment: workenv,
          runInShell: viaShell,
        );
        var code = result.exitCode;
        logger.trace('${code == 0 ? 'i' : 'e'}, exitcode:$code');
        if (code == 0) {
          logger.write(result.stdout);
        } else {
          logger.stderr(result.stderr);
          if (exitOnNonzore) {
            exitCode = ExitCodeExt.error.code;
            break;
          }
        }
      } on ProcessException catch (e, s) {
        logger
          ..stderr('$e')
          ..stderr(kIsDebug ? '$s' : '');
        if (ftRun.ftErrExit) {
          exitCode = ExitCodeExt.error.code;
          break;
        }
      } finally {
        progress.finish();
      }
    }
  }

  // cls_last_line
}

/// FileTool Runner
class FtRunner<T> extends CommandRunner<T> {
  FtRunner(super.executableName, super.description);

  @override
  String get invocation => '$executableName <command> <source> [arguments]';

  Logger ftLogger = CliStandardLogger(ansi: CliAnsi(Ansi.terminalSupportsAnsi));

  late final bool ftErrExit;
  late final bool ftVerbose;
  late final Config ftConfig;
  late final String ftSource;
  late final List<int> ftSizes;
  late final List<DateTime> ftTimes;
  late final String ftPattern;
  late final List<String> ftExcludes;
  late final List<String> ftFields;
  late final Map<String, String> ftDefine, ftEnv;
  late final String ftTimeType;
}

/// filetool run
FtRunner cmdRunner(List<String> args) {
  final verbose = args.contains('-v') || args.contains('--verbose');

  final cliAnsi = CliAnsi(Ansi.terminalSupportsAnsi);
  final logger = verbose
      ? CliVerboseLogger(ansi: cliAnsi)
      : CliStandardLogger(ansi: cliAnsi);

  final ftRun = FtRunner("ft", "FileTools: cross-platform glob & streams. \n")
    ..ftVerbose = verbose
    ..ftLogger = logger;

  // ignore: unused_local_variable
  final parser = ftRun.argParser
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show additional command output.',
    )
    ..addFlag(
      'version',
      negatable: false,
      help: 'Print the tool version.',
    )
    ..addOption(
      'source',
      valueHelp: 'path',
      help: 'Specify the source (file|directory)',
    )
    ..addOption(
      'config',
      valueHelp: 'file',
      help: 'Loads a config file for variable referencing',
    )
    ..addOption(
      'config_txt',
      valueHelp: 'yaml',
      help: 'Loads a yaml text for variable referencing',
    )
    ..addFlag(
      'config_gen',
      negatable: false,
      defaultsTo: false,
      help: 'Generate a custom config on curdir.',
    )
    ..addFlag(
      'errexit',
      negatable: true,
      defaultsTo: true,
      help: 'exit on error.',
    )
    ..addMultiOption(
      'define',
      help: 'Define or override a variable from command line',
    )
    ..addOption(
      'pattern',
      defaultsTo: '**',
      help: 'Glob pattern',
    )
    ..addMultiOption(
      'excludes',
      help: "Glob pattern after exclusion (e.g. --excludes='.**')",
    )
    ..addMultiOption(
      'fields',
      help: "show fields (ok, action, type, mime, perm, time, size, extra)",
    )
    ..addOption(
      'size_le',
      help: 'file size less than (in bytes, unit:B|K|M|G|T|P)',
    )
    ..addOption(
      'size_ge',
      help: 'file size greater than (in bytes, unit:B|K|M|G|T|P)',
    )
    ..addOption(
      'time_le',
      help: 'file time before (yyyyMMddTHHmmss | yyyyMMdd)',
    )
    ..addOption(
      'time_ge',
      help: 'file time after (yyyyMMddTHHmmss | yyyyMMdd)',
    )
    ..addOption(
      'time_type',
      defaultsTo: 'modified',
      allowed: StatTimeType.values.asNameMap().keys.toList(),
      allowedHelp: {
        'changed': 'ctime - change time',
        'modified': 'mtime - modification time',
        'accessed': 'atime - access time',
      },
      valueHelp: 'modified',
      help: 'file time type (changed | modified | accessed)',
    );

  ftRun
    ..addCommand(ListCommand())
    ..addCommand(SearchCommand())
    ..addCommand(MirrorCommand())
    ..addCommand(CleanCommand())
    ..addCommand(WipeCommand())
    ..addCommand(RmDirCommand())
    ..addCommand(FdupsCommand())
    ..addCommand(ArchiveCommand())
    ..addCommand(UnArchiveCommand())
    ..addCommand(ExecuteCommand())
    ..addCommand(ShellCommand());

  return ftRun;
}
