part of '../ft.dart';

/// A map of environment variables for the current process.
///
/// Example: `{'PATH': '/usr/bin', 'HOME': '/home/username'}`
final Map<String, String> environ =
    Map<String, String>.from(Platform.environment);

/// Delimiter: a single dot (`.`).
const String dotDelimiter = r'.';

/// Delimiter: a single space (` `).
const String spaceDelimiter = r' ';

/// Delimiter: a semicolon (`;`).
const String semicolonDelimiter = r';';

/// Delimiter: a comma (`,`).
const String commaDelimiter = r',';

/// Delimiter: an equals sign (`=`).
const String equalsignDelimiter = r'=';

/// Delimiter: an ampersand (`&`).
const String ampersandDelimiter = r'&';

/// Joins a list of `names` into a single string using the specified `delimiter`.
///
/// Defaults to [dotDelimiter] if no delimiter is provided.
///
/// Example: `joinDelimiter(['foo', 'bar'])` returns `"foo.bar"`.
///
/// Example: `joinDelimiter(['foo', 'bar'], '-')` returns `"foo-bar"`.
String joinDelimiter(List<String> names, [String delimiter = dotDelimiter]) =>
    names.join(delimiter);

/// The platform-specific line terminator string.
///
/// For example, `\r\n` on Windows, `\n` on Unix-like systems.
final String lineEnd = Platform.lineTerminator;

/// The platform-specific path separator character.
///
/// For example, `\` on Windows, `/` on Unix-like systems.
final String pathSep = Platform.pathSeparator;

/// True if the current operating system is Windows.
final bool isWindows = Platform.isWindows;

/// True if the current operating system is Linux or macOS.
bool get isUnixLike => (Platform.isLinux || Platform.isMacOS);

/// True if the current operating system is a desktop OS (Windows, Linux, or macOS).
bool get isDesktop => (isWindows || isUnixLike);

/// The version string for 'ft'.
final ftVer = '0.0.1';

/// The operating system name string for 'ft'.
final ftOs = Platform.operatingSystem;

/// Checks if the given `name` matches the current platform's operating system.
///
/// Handles "Windows" as case-insensitive for the input `name`.
///
/// Returns `true` if `name` matches the current OS, otherwise `false`.
bool isOsMatched(String name) {
  if (name.contains('Windows')) name = 'windows';
  return name == ftOs;
}

/// The default template filename for 'ft'.
final ftTmplName = 'ft.yaml';

/// The default template text for 'ft'.
final ftTmplText = '''
name: filetool config
description: a filetool config template.
version: 1.0.0

# homepage: 
# repository: https://github.com/huanguan1978/ft
# author: 
# authors: 

# required, specifies the target platform (macos, linux, windows, android, ios)
os: $ftOs
# required, readonly, ft cli version.
ver: $ftVer

# YAML overrides CLI. Lookup: CLI named -> ENV -> YAML -> CLI positional.
# source: .
# size_ge:
# size_le:
# time_ge:
# time_le:

# pretty output fields
fields: 
  - ok
  - action 
  - type
  # - mime
  # - perm 
  # - time
  # - size
  # - extra

# exit on error
errexit: true

# * (Asterisk - Alias):  References a previously defined node (using `&` for anchor).  Used for data reusability. 
# To include an asterisk literally within a string, enclose it in single or double quotes.
# pattern: '**'

excludes:
  - '**~'
  - '**.DS_Store'
  # .** excluding hiddens
  # - '.**'
  - /**/.**

# subcommand variable
# list.type file|directory|link; archive.type tar|tgz
list:
  type: file
mirror:
  target: \$ft_target_dir/mirror/\$CURDATETIME
  relative: true
  tail: 1
unarchive:
  target: \$ft_target_dir/unarchive/\$CURDATETIME
  relative: true
  tail: 1  
archive:
  target: \$ft_target_dir/archive/\$CURDATE
  relative: true
  tail: 1
  type: tgz

shell:
  vai_shell: true
  exit_on_nonzore: false

# define variables. 
# the system provides dynamic variables CURDIR, CURDATE, CURDATETIME.
# relative variable, prefix: AGODATE, AGODATETIME, format: prefix+ num+ unit.
# NOW: 2025-08-29T09:02:26.441496;
# CURDATE: 20250829; CURDATETIME: 20250829090226
# AGODATE1DAY: 20250828; AGODATETIME1DAY: 20250828090226
# AGODATE1WEEK: 20250822; AGODATETIME1WEEK: 20250822090226
define:
  # all macos desktop services store.
  ds_store: '**.DS_Store'
  # all hidden files
  hidden_files: '.**'
  # emacs|vi swap files  
  swap_files: '**.sw[p|o|n]'
  # emacs|nano backup files
  backup_files: '**~' 
  # vim undo files
  vim_undo: '**.un'
  # emacs autosave files
  emacs_autosave: '**#'
  
  downloads: "$homePattern/Downloads"
  ft_target_dir: "$homePattern/Documents/FileShows"


# stream-based commands (supports [define] & ENV). requires - or -- options.
commands:
  - ft clean --source="\$downloads" --pattern="\$backup_files" --fields=ok,action,type 

# custom blocks must end in 'commands'. 'commands' is the default.
my_commands:
  # - ft mirror ~/Desktop "\$ft_target_dir/mirror/Desktop/\$CURDATE/\$CURDATETIME" --fields=ok,action,type 
  # - ft rmdir --force --keeptop "\$ft_target_dir/mirror/Desktop" --time_le="1 week ago" --fields=ok,action,type 

# shell commands (supports [define] & ENV). 
scripts:
  - echo "hello world"

# custom blocks must end in 'scripts'. 'scripts' is the default.
my_scripts:
  - date
  - hostname


# a cron-like time-based job scheduler, run commands, and scripts.
job:
  # available actions: run | pause | stop | delete
  action: stop
  # tigger time: hourly | daily | weekly | yearly | expression
  # tigger time: midday12t | midday13t | afternoon15t | afternoon16t | every1mins | every2mins | every3mins | every5mins
  time: midday12t
  # use expression time if not empty 
  expression: 
  # runonce: true | false
  runonce: false
  # result notification via email
  emailnotify: false
  # logpath use \$ft_target_dir/joblogs if empty
  logpath: 

''';
