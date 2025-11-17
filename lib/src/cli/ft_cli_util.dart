part of '../../ft.dart';

/// get size input, order: define -> env -> yaml -> argResults
List<int> getSizes(Config config, ArgResults? gRes) {
  List<int> sizes = [];
  String? sizeGe = config.optionalString('size_ge');
  String? sizeLe = config.optionalString('size_le');
  sizeGe ??= gRes?.option('size_ge');
  sizeLe ??= gRes?.option('size_le');

  if (sizeLe case String sizeLe_ when sizeLe_.isNotEmpty) {
    final intSizeLe = parseHumanReadableSize(sizeLe_);
    if (intSizeLe == null) throw UsageException('err: invalid size_le', '');
    sizes = [0, intSizeLe];
  }
  if (sizeGe case String sizeGe_ when sizeGe_.isNotEmpty) {
    final intSizeGe = parseHumanReadableSize(sizeGe_);
    if (intSizeGe == null) throw UsageException('err: invalid size_ge', '');

    sizes.insert(0, intSizeGe);
  }
  if (sizes.length > 1 && sizes.first >= sizes.last) {
    throw UsageException('err: invalid size_ge and size_le', '');
  }
  return sizes;
}

/// get times input, order: define -> env -> yaml -> argResults
List<DateTime> getTimes(Config config, ArgResults? gRes) {
  List<DateTime> times = [];
  String? timeGe = config.optionalString('time_ge');
  String? timeLe = config.optionalString('time_le');
  timeGe ??= gRes?.option('time_ge');
  timeLe ??= gRes?.option('time_le');

  if (timeLe case String timeLe_ when timeLe_.isNotEmpty) {
    if (timeLe_.contains('ago')) {
      final parsedTime = TimeAgoParser.parse(timeLe_);
      if (parsedTime == null || parsedTime.unit == TimeUnit.unknown) {
        throw UsageException('err: invalid time_le (time ago)', '');
      }
      timeLe_ = parsedTime.toDateTime().toIso8601String();
    }
    final dtSizeLe = DateTime.tryParse(timeLe_);
    if (dtSizeLe == null) throw UsageException('err: invalid time_le', '');
    final epoch = DateTime(1970); // Unix Epoch (1970-01-01 00:00:00 UTC
    times = [epoch, dtSizeLe.toLocal()];
  }
  if (timeGe case String timeGe_ when timeGe_.isNotEmpty) {
    if (timeGe_.contains('ago')) {
      final parsedTime = TimeAgoParser.parse(timeGe_);
      if (parsedTime == null || parsedTime.unit == TimeUnit.unknown) {
        throw UsageException('err: invalid time_ge (time ago)', '');
      }
      timeGe_ = parsedTime.toDateTime().toIso8601String();
    }
    final dtSizeGe = DateTime.tryParse(timeGe_);
    if (dtSizeGe == null) throw UsageException('err: invalid time_ge', '');
    times.insert(0, dtSizeGe.toLocal());
  }
  if (times.length > 1 && times.first.isAfter(times.last)) {
    throw UsageException('err: invalid time_ge and time_le', '');
  }
  return times;
}

/// get source input, order: define -> env -> yaml -> argResults -> rest first
String getSource(
  Config config,
  ArgResults? gRes, {
  ArgResults? aRes,
  Map<String, String>? env,
}) {
  String? source = config.optionalString('source');
  source ??= gRes?.option('source');
  source ??= aRes?.rest.firstOrNull;

  if (source == null || source.isEmpty) {
    throw UsageException('err: required source', '');
  }

  if (source.trimLeft().startsWith('~')) {
    if (isWindows) source = source.replaceFirst('~', homePattern);
    source = expandTilde(source);
  }

  if (source.contains(varInputRegexp) && env != null) {
    source = expandVar(source, map: env);
  }

  if (source.contains(varInputRegexp)) {
    throw UsageException('err: undef.var. $source', '');
  }

  // if (source.startsWith('.')) source = expandDotPath(source);
  source = p.normalize(source);
  return source;
}

/// get target input, order: define -> env -> yaml -> argResults -> rest last
String getTarget(
  String name,
  Config config, {
  ArgResults? aRes,
  Map<String, String>? env,
  String? source,
}) {
  final orgiName = name;
  String? target = config.optionalString(name);

  if (name.contains(dotDelimiter)) name = name.split(dotDelimiter).last;
  target ??= aRes?.option(name);
  target ??= aRes?.rest.lastOrNull;
  if (target == null || target.isEmpty) {
    throw UsageException('err: required $name', '');
  }
  if ((target == '.' || target == '..') && orgiName.startsWith('archive')) {
    target = p.basename(expandDotPath(target));
  }
  if (source != null && source == target) {
    throw UsageException('err: invalid $name', '');
  }

  if (target.trimLeft().startsWith('~')) {
    if (isWindows) target = target.replaceFirst('~', homePattern);
    target = expandTilde(target);
  }

  if (target.contains(varInputRegexp) && env != null) {
    target = expandVar(target, map: env);
  }

  if (target.contains(varInputRegexp)) {
    throw UsageException('err: undef.var. $target', '');
  }

  // if (target.startsWith('.')) target = expandDotPath(target);
  target = p.normalize(target);

  return target;
}

/// get define input, order: env-> define -> yaml
Map<String, String> getDefine(Config config, ArgResults? gRes) {
  final name = 'define';
  List<String> cliValues = gRes?.multiOption(name) ?? [];
  Map<String, String> cliValue = parseAssigns(cliValues);

  // cliValue.addAll(io.Platform.environment);
  var cnfValue = config.valueOf(name); // YamlMap
  if (cnfValue != null) {
    final cnfMap = <String, String>{};
    for (var item in cnfValue.entries) {
      cnfMap[item.key.toString()] = item.value.toString();
    }

    // final cnfMap = Map<String, String>.from(cnfValue);
    cliValue.addAll(cnfMap);
  }

  return cliValue;
}

/// get commands input from yaml
Map<String, List<String>> getExecBlock(
  Config config,
  Map<String, String> env, [
  List<String> blocks = const [],
]) {
  final String os_ = config.optionalString('os') ?? '';
  if (!isOsMatched(os_)) throw UsageException('err: invalid os', '');

  final map = <String, List<String>>{}; // map blockname, cmds;
  if (blocks.isEmpty) blocks.add('commands');
  for (var blockName in blocks) {
    var cmds = config.optionalStringList(blockName);
    if (cmds == null || cmds.isEmpty) {
      throw UsageException('err: required $blockName list', '');
    }

    final subNames = PathAction.values.asNameMap().keys.toList();
    for (var cmd in cmds) {
      final undef = undefined(cmd, env);
      if (undef.isNotEmpty) {
        throw UsageException('err: undef $undef, $cmd', '');
      }
      if (!isSubCmd(cmd, subNames)) {
        throw UsageException('err: subcmd $cmd', '');
      }
    }

    map[blockName] = cmds;
  }

  return map;
}

/// get scripts input from yaml
Map<String, List<String>> getShellBlock(
  Config config,
  Map<String, String> env,
  String workdir, [
  List<String> blocks = const [],
]) {
  final String os_ = config.optionalString('os') ?? '';
  if (!isOsMatched(os_)) throw UsageException('err: invalid os', '');

  final map = <String, List<String>>{}; // map blockname, scripts;
  if (blocks.isEmpty) blocks.add('scripts');
  for (var blockName in blocks) {
    var cmds = config.optionalStringList(blockName);
    if (cmds == null || cmds.isEmpty) {
      throw UsageException('err: required $blockName list', '');
    }

    // final lpm = LocalProcessManager();
    for (var cmd in cmds) {
      final undef = undefined(cmd, env);
      if (undef.isNotEmpty) {
        throw UsageException('err: undef $undef, $cmd', '');
      }

      // final canrun = lpm.canRun(name, workingDirectory: workdir);
      // if (!canrun) throw UsageException('err: can not run, $value', '');
    }

    map[blockName] = cmds;
  }

  return map;
}

/// get scripts input from yaml
List<String> getShellScripts(
    Config config, Map<String, String> env, String workdir) {
  final String os_ = config.optionalString('os') ?? '';
  if (!isOsMatched(os_)) throw UsageException('err: invalid os', '');

  final String name = 'scripts';
  var values = config.optionalStringList(name);
  if (values == null || values.isEmpty) {
    throw UsageException('err: required $name list', '');
  }

  // final lpm = LocalProcessManager();
  for (var value in values) {
    final undef = undefined(value, env);
    if (undef.isNotEmpty) throw UsageException('err: undef $undef, $value', '');

    // final canrun = lpm.canRun(name, workingDirectory: workdir);
    // if (!canrun) throw UsageException('err: can not run, $value', '');
  }

  return values;
}

/// check [cmd] has valid [subCmdNames]
bool isSubCmd(String cmd, List<String> subCmdNames) {
  var parts = cmd.split(' ');
  if (parts.length < 2) return false;

  final [cmdName, subName, ...] = parts;
  if (cmdName != 'ft' || !subCmdNames.contains(subName.trim())) return false;

  return true;
}

/// return [input] undefined variable in [literal]
String undefined(String input, Map<String, String> literal) {
  if (input.contains(varInputRegexp)) input = expandVar(input, map: literal);
  final name = varInputRegexp.stringMatch(input);
  return name ?? '';
}

/// notDefined

/// get bool input, order: define -> env -> yaml -> globalResults -> argResults
bool getFlag(
  String name,
  Config config, {
  bool defaultTo = false,
  ArgResults? gRes,
  ArgResults? aRes,
}) {
  bool? value = config.optionalBool(name);
  if (value != null) return value;

  if (name.contains(dotDelimiter)) name = name.split(dotDelimiter).last;
  value ??= gRes?.flag(name);
  value ??= aRes?.flag(name);

  return value ?? defaultTo;
}

/// get bool input, order: define -> env -> yaml -> globalResults -> argResults
int getInt(
  String name,
  Config config, {
  int defaultTo = 0,
  int? max,
  ArgResults? gRes,
  ArgResults? aRes,
}) {
  int? value = config.optionalInt(name);
  if (value != null) return value;

  if (name.contains(dotDelimiter)) name = name.split(dotDelimiter).last;
  value ??= int.tryParse(gRes?.option(name) ?? '');
  value ??= int.tryParse(aRes?.option(name) ?? '');
  value ??= defaultTo;
  if (max != null && value >= max) {
    throw UsageException('err: invalid $name', '');
  }

  return value;
}

/// get option input, order: define -> env -> yaml -> globalResults -> argResults
String getOpiton(
  String name,
  Config config, {
  bool isNotEmpty = true,
  String defaultTo = '',
  List<String> datalist = const [],
  ArgResults? gRes,
  ArgResults? aRes,
}) {
  String? value = config.optionalString(name);
  if (value != null) return value;

  if (name.contains(dotDelimiter)) name = name.split(dotDelimiter).last;
  value ??= gRes?.option(name);
  value ??= aRes?.option(name);
  value ??= defaultTo;
  if (isNotEmpty && value.isEmpty) {
    throw UsageException('err: $name empty', '');
  }

  if (datalist.isNotEmpty && !datalist.contains(value)) {
    throw UsageException('err: $name not in datalist', '');
  }

  return value;
}

/// get options input, order: define -> env -> yaml -> globalResults -> argResults
List<String> getOpitons(
  String name,
  Config config, {
  bool isNotEmpty = false,
  List<String> defaults = const [],
  List<String> datalist = const [],
  ArgResults? gRes,
  ArgResults? aRes,
}) {
  List<String>? values = config.optionalStringList(name);
  if (values != null) return values;

  if (name.contains(dotDelimiter)) name = name.split(dotDelimiter).last;
  values ??= gRes?.multiOption(name);
  values ??= aRes?.multiOption(name);
  values ??= defaults;

  if (isNotEmpty && values.isEmpty) {
    throw UsageException('err: $name empty', '');
  }

  if (datalist.isNotEmpty && values.isNotEmpty) {
    final notfound = values.firstWhere(
      (e) => !datalist.contains(e),
      orElse: () => '',
    );
    if (notfound.isNotEmpty) {
      throw UsageException('err: $notfound not in datalist', '');
    }
  }

  return values;
}

Config configFromArgParse(
  ArgParser argParse,
  List<String> arguments, {
  Map<String, String>? environment,
  Uri? workingDirectory,
}) {
  final results = argParse.parse(arguments);

  // Load config file.
  String? fileContents;
  Uri? fileSourceUri;

  fileContents = results['config_txt'] as String?;

  final configFile = results['config'] as String?;
  if (configFile != null) {
    var configPath = configFile;
    if (configPath.startsWith(r'~')) configPath = expandTilde(configPath);

    fileContents = File(configPath).readAsStringSync();
    fileSourceUri = Uri.file(configPath);
  }

  return Config.fromConfigFileContents(
    commandLineDefines: results['define'] as List<String>,
    workingDirectory: workingDirectory ?? Directory.current.uri,
    environment: environment ?? Platform.environment,
    fileContents: fileContents,
    fileSourceUri: fileSourceUri,
  );
}
