part of '../../ft.dart';

class CliAnsi extends Ansi {
  CliAnsi(super.useAnsi);
  static bool has256color = isSupport256Colors();

  @override
  String get gray =>
      has256color ? _code('\u001b[38;5;245m') : _code('\u001b[1;30m');

  String _code(String ansiCode) => useAnsi ? ansiCode : '';

  /// Determines if the current terminal likely supports 256-color ANSI escape sequences.
  ///
  /// This method uses heuristic checks based on environment variables:
  /// - Requires `io.stdout.supportsAnsiEscapes` for basic ANSI support.
  /// - On Windows: checks `WT_SESSION` (for Windows Terminal) or `TERM` (for WSL/Git Bash).
  /// - On non-Windows: relies on `TERM` (e.g., `xterm-256color`).
  ///
  /// Note: This is a heuristic and may not be 100% accurate.
  static bool isSupport256Colors() {
    // If basic ANSI escape sequences are not supported, then 256 colors definitely aren't.
    if (!stdout.supportsAnsiEscapes) return false;

    final term = Platform.environment['TERM']?.toLowerCase();
    final has256color = term != null &&
        (term.contains('256color') || term.contains('truecolor'));

    if (Platform.isWindows) {
      // Windows Terminal sets WT_SESSION. It supports 256+ colors.
      if (Platform.environment.containsKey('WT_SESSION')) return true;

      // For other Windows environments (e.g., WSL, Git Bash), check TERM.
      return has256color;
    } else {
      // On non-Windows (Linux, macOS), TERM is the primary indicator.
      return has256color;
    }
  }

  static bool get isSupportAnsi => Ansi.terminalSupportsAnsi;
}

class CliSimpleProgress extends SimpleProgress {
  CliSimpleProgress(super.logger, super.message);

  @override
  void finish({String? message, bool showTiming = false}) {
    if (message case String _ when message.isNotEmpty) logger.stdout(message);
  }
}

class CliAnsiProgress extends Progress {
  static const List<String> kAnimationItems = ['/', '-', r'\', '|'];

  final Ansi ansi;

  late final Timer _timer;

  CliAnsiProgress(this.ansi, String message) : super(message) {
    _timer = Timer.periodic(const Duration(milliseconds: 80), (t) {
      _updateDisplay();
    });
    stdout.writeln('$message...  '.padRight(40));
    // _updateDisplay();
  }

  @override
  void cancel() {
    if (_timer.isActive) {
      _timer.cancel();
      _updateDisplay(cancelled: true);
    }
  }

  @override
  void finish({String? message, bool showTiming = false}) {
    if (_timer.isActive) {
      _timer.cancel();
      _updateDisplay(isFinal: true, message: message, showTiming: showTiming);
    }
  }

  void _updateDisplay(
      {bool isFinal = false,
      bool cancelled = false,
      String? message,
      bool showTiming = false}) {
    if (isFinal || cancelled) {
      if (message != null) {
        stdout.write(message.isEmpty ? ' ' : message);
      }
      if (showTiming) {
        final time = (elapsed.inMilliseconds / 1000.0).toStringAsFixed(1);
        stdout.write('${time}s');
      }
      stdout.writeln();
    }

    // if (message case String _ when message.isEmpty) {
    var char = kAnimationItems[_timer.tick % kAnimationItems.length];
    // if (isFinal || cancelled) char = ansi.backspace;
    stdout.write("${ansi.backspace}$char${ansi.backspace}");
    // }
  }
}

class CliVerboseLogger extends VerboseLogger {
  CliVerboseLogger({Ansi? ansi, super.logTime})
      : super(ansi: ansi ?? Ansi(Ansi.terminalSupportsAnsi));

  @override
  Progress progress(String message) => ansi.useAnsi
      ? CliAnsiProgress(ansi, message)
      : CliSimpleProgress(this, message);
}

class CliStandardLogger extends StandardLogger {
  CliStandardLogger({Ansi? ansi})
      : super(ansi: ansi ?? Ansi(Ansi.terminalSupportsAnsi));

  @override
  Progress progress(String message) => ansi.useAnsi
      ? CliAnsiProgress(ansi, message)
      : CliSimpleProgress(this, message);
}

// ---- customize logger ----

class StrBufLogger implements Logger {
  @override
  Ansi ansi;

  final StringBuffer _buffer;
  final bool _useVerbose;

  // string buffer logger, ansi disabled
  StrBufLogger([StringBuffer? buffer, bool? useVerbose])
      : ansi = Ansi(false),
        _buffer = buffer ?? StringBuffer(),
        _useVerbose = useVerbose ?? false;

  @override
  bool get isVerbose => _useVerbose;

  Progress? _currentProgress;

  @override
  void stderr(String message) {
    _cancelProgress();

    _buffer.writeln(message);
  }

  @override
  void stdout(String message) {
    _cancelProgress();

    _buffer.writeln(message);
  }

  @override
  void trace(String message) {
    if (!isVerbose) return;

    _cancelProgress();

    _buffer.writeln(message);
  }

  @override
  void write(String message) {
    _cancelProgress();

    _buffer.write(message);
  }

  @override
  void writeCharCode(int charCode) {
    _cancelProgress();

    _buffer.writeCharCode(charCode);
  }

  void _cancelProgress() {
    final progress = _currentProgress;
    if (progress != null) {
      _currentProgress = null;
      progress.cancel();
    }
  }

  @override
  Progress progress(String message) {
    _cancelProgress();

    final progress = CliSimpleProgress(this, message);
    _currentProgress = progress;
    return progress;
  }

  @override
  @Deprecated('This method will be removed in the future')
  void flush() {}

  StringBuffer get buffer => _buffer;
  String get string => _buffer.toString();
  void clear() => _buffer.clear();

  // cls_lastline
}

class IoSinkLogger implements Logger {
  @override
  Ansi ansi;

  final IOSink _sink;
  final bool _useVerbose;

  // IOSink logger, ansi disabled
  IoSinkLogger(IOSink ioSink, [bool? useVerbose])
      : ansi = Ansi(false),
        _sink = ioSink,
        _useVerbose = useVerbose ?? false;

  @override
  bool get isVerbose => _useVerbose;

  Progress? _currentProgress;

  @override
  void stderr(String message) {
    _cancelProgress();

    _sink.writeln(message);
  }

  @override
  void stdout(String message) {
    _cancelProgress();

    _sink.writeln(message);
  }

  @override
  void trace(String message) {
    if (!isVerbose) return;

    _cancelProgress();

    _sink.writeln(message);
  }

  @override
  void write(String message) {
    _cancelProgress();

    _sink.write(message);
  }

  @override
  void writeCharCode(int charCode) {
    _cancelProgress();

    _sink.writeCharCode(charCode);
  }

  void _cancelProgress() {
    final progress = _currentProgress;
    if (progress != null) {
      _currentProgress = null;
      progress.cancel();
    }
  }

  @override
  Progress progress(String message) {
    _cancelProgress();

    final progress = CliSimpleProgress(this, message);
    _currentProgress = progress;
    return progress;
  }

  @override
  @Deprecated('This method will be removed in the future')
  void flush() => _sink.flush();

  IOSink get ioSink => _sink;

  // cls_lastline
}
