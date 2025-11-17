part of '../../ft.dart';

/// extension ExitCode
class ExitCodeExt {
  /// Command completed successfully.
  static const success = ExitCodeExt._(0, 'success');

  /// Command was used incorrectly.
  ///
  /// This may occur if the wrong number of arguments was used, a bad flag, or
  /// bad syntax in a parameter.
  static const usage = ExitCodeExt._(64, 'usage');

  /// Input data was used incorrectly.
  ///
  /// This should occur only for user data (not system files).
  static const data = ExitCodeExt._(65, 'data');

  /// An input file (not a system file) did not exist or was not readable.
  static const noInput = ExitCodeExt._(66, 'noInput');

  /// User specified did not exist.
  static const noUser = ExitCodeExt._(67, 'noUser');

  /// Host specified did not exist.
  static const noHost = ExitCodeExt._(68, 'noHost');

  /// A service is unavailable.
  ///
  /// This may occur if a support program or file does not exist. This may also
  /// be used as a catch-all error when something you wanted to do does not
  /// work, but you do not know why.
  static const unavailable = ExitCodeExt._(69, 'unavailable');

  /// An internal software error has been detected.
  ///
  /// This should be limited to non-operating system related errors as possible.
  static const software = ExitCodeExt._(70, 'software');

  /// An operating system error has been detected.
  ///
  /// This intended to be used for such thing as `cannot fork` or `cannot pipe`.
  static const osError = ExitCodeExt._(71, 'osError');

  /// Some system file (e.g. `/etc/passwd`) does not exist or could not be read.
  static const osFile = ExitCodeExt._(72, 'osFile');

  /// A (user specified) output file cannot be created.
  static const cantCreate = ExitCodeExt._(73, 'cantCreate');

  /// An error occurred doing I/O on some file.
  static const ioError = ExitCodeExt._(74, 'ioError');

  /// Temporary failure, indicating something is not really an error.
  ///
  /// In some cases, this can be re-attempted and will succeed later.
  static const tempFail = ExitCodeExt._(75, 'tempFail');

  /// You did not have sufficient permissions to perform the operation.
  ///
  /// This is not intended for file system problems, which should use [noInput]
  /// or [cantCreate], but rather for higher-level permissions.
  static const noPerm = ExitCodeExt._(77, 'noPerm');

  /// Something was found in an unconfigured or misconfigured state.
  static const config = ExitCodeExt._(78, 'config');

  // -------------customize -------------------------

  /// Catchall for general errors
  static const error = ExitCodeExt._(1, 'error');

  /// Misuse of shell built-ins (according to Bash documentation)
  static const badBuiltin = ExitCodeExt._(2, 'badBuiltin');

  /// Command invoked cannot execute
  static const noExec = ExitCodeExt._(126, 'noExec');

  /// Command not found
  static const notFound = ExitCodeExt._(127, 'notFound');

  /// Invalid argument to exit, same ExitCode.usage, 64
  // static const badExitArg = ExitCodeExt._(128, 'badExitArg');

  /// Fatal error signal “n”
  static const signal = ExitCodeExt._(128, 'signal');

  /// Script terminated by Control-C.
  static const interrupt = ExitCodeExt._(130, 'interrupt');

  /// Exit status out of range.
  static const outOfRange = ExitCodeExt._(255, 'outOfRange');

  /// Exit code value.
  final int code;

  /// Name of the exit code.
  final String _name;

  const ExitCodeExt._(this.code, this._name);

  @override
  String toString() => '$_name: $code';
}
