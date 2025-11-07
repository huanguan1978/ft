part of '../ft.dart';

class EntityStreamTransformer
    extends StreamTransformerBase<FileSystemEntity, FileSystemEntity> {
  final StreamController<Es> _scFilted;
  final StreamController<Es> _scEntity;

  final bool cancelOnError;
  final List<String>? excludes;
  final List<int>? sizes;
  final List<DateTime>? times;
  final StatTimeType statTimeType;

  EntityStreamTransformer(
    this._scEntity,
    this._scFilted, {
    this.cancelOnError = false,
    this.excludes,
    this.sizes,
    this.times,
    this.statTimeType = StatTimeType.modified,
  });

  @override
  Stream<FileSystemEntity> bind(stream) {
    late StreamSubscription<FileSystemEntity> subs;
    subs = stream.listen(
      (data) {
        // print(data);
        _transform(data);
      },
      onError: (e, s) {
        // print('---error---, $e');
        _scEntity.addError(e, s);
        _scFilted.addError(e, s);
        if (cancelOnError) {
          // print('---error---,cancelOnError:$cancelOnError, cleanup.');
          _scEntity.close();
          _scFilted.close();
          subs.cancel();
        }
      },
      onDone: () {
        // print('---done---');
        _scEntity.close();
        _scFilted.close();
      },
      cancelOnError: cancelOnError,
    );

    if ((exitCode == ExitCodeExt.interrupt.code) ||
        (exitCode == ExitCodeExt.error.code)) {
      print('----exitCode:$exitCode---');
      unawaited(_scEntity.close());
      unawaited(_scFilted.close());
      unawaited(subs.cancel());
    }
    return stream;
  }

  (FileSystemEntity, FileStat) _transform(FileSystemEntity entity) {
    final isInExcludes_ = _isInExcludes(entity.path);
    final isExclude = isInExcludes_.$1;
    final stat = entity.statSync();
    final isInSizes_ = _isInSizes(stat.size);

    final statTime = switch (statTimeType) {
      StatTimeType.changed => stat.changed,
      StatTimeType.accessed => stat.accessed,
      _ => stat.modified,
    };

    final isInTimes_ = _isInTimes(statTime);

    String extra = '';
    bool isFilted = false;
    if (!isFilted && !isInTimes_) {
      extra = '_isNotInTimes_, $times, ${statTimeType.name}:$statTime';
      isFilted = true;
    }
    if (!isFilted && !isInSizes_) {
      extra = '_isNotInSizes_, $sizes, size:${stat.size}';
      isFilted = true;
    }
    if (!isFilted && isExclude) {
      extra = '_isInExcludes_, ${isInExcludes_.$2}';
      isFilted = true;
    }

    final es = Es((entity, stat, extra));
    if (isFilted) {
      _scFilted.add(es);
    } else {
      _scEntity.add(es);
    }

    return (entity, stat);
  }

  (bool, String) _isInExcludes(String path) {
    if (excludes case List<String> patterns when patterns.isNotEmpty) {
      for (var pattern in patterns) {
        if (isMatchGlob(pattern, path)) return (true, pattern);
      }
    }
    return (false, '');
  }

  bool _isInSizes(int size) {
    if (sizes case List<int> sizes_ when sizes_.isNotEmpty) {
      final min = sizes_.first;
      final int? max = (sizes_.length > 1) ? sizes_.last : null;
      return isInSizes(size, min: min, max: max);
    }
    return true;
  }

  bool _isInTimes(DateTime datetime) {
    if (times case List<DateTime> times_ when times_.isNotEmpty) {
      final min = times_.first;
      final DateTime? max = (times_.length > 1) ? times_.last : null;
      return isInTimes(datetime, min: min, max: max);
    }
    return true;
  }
  // cls_lastline
}
