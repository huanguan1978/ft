import 'dart:async';

import 'package:filetools/ft.dart';

void main() {
  actionList();
  // actionList2();

  // actionSearch();
  // actionReplace();
}

// matches all files in the current directory, excluding hidden items
void actionList() {
  // step 1: input preparation stage
  final excludes = [r'.**'];
  final source = '.';
  final action = BasicPathAction(source, excludes: excludes);
  final checkInput = action.validator();
  if (checkInput.isNotEmpty) print(checkInput);

  // step 2: core processing stage
  late Stream<Es>? aStream;
  try {
    aStream = action.list();
  } on ArgumentError catch (e) {
    print(e);
  } catch (e) {
    print(e);
  }

  // step 3: output processing stag
  if (aStream == null) return;
  late StreamSubscription subs;
  subs = aStream.listen(
    (event) {
      var (entity, stat, extra) = event.asRecord;
      print(
        'path:${entity.path}, time: ${stat.modified}, size:${stat.size}, extra: $extra.',
      );
    },
    cancelOnError: true,
    onDone: () => print('d, list, done.'),
    onError: (e, s) {
      print('e, list, $e.');
      subs.cancel();
    },
  );

  // ufn_lastline
}

// matches all files in the current directory, output log string buffer.
void actionList2() {
  // step 1: input preparation stage
  final logger = StrBufLogger();

  final excludes = [r'.**'];
  final source = '.';
  final action = BasicPathAction(source, excludes: excludes)..logger = logger;

  // step 2: core processing stage
  late Stream<Es>? aStream;
  try {
    aStream = action.list();
  } on ArgumentError catch (e) {
    logger.stderr(e.toString());
  } catch (e) {
    logger.stderr(e.toString());
  }

  // step 3: output processing stag
  if (aStream == null) return;
  late StreamSubscription subs;
  subs = aStream.listen(
    (event) {},
    cancelOnError: true,
    onDone: () {
      logger.stdout('i, list, done.');
      print(logger.toString()); // output all.
      logger.clear();
    },
    onError: (e, s) {
      logger.stderr('e, list, $e.');
      subs.cancel();
    },
  );

  // ufn_lastline
}

// matches all yaml files in the current directory, excluding hidden items
// search `version: 1.0.\d+`
void actionSearch() {
  // step 1: input preparation stage
  final pattern = r'**.yaml';
  final excludes = [r'.**'];
  final source = '.';
  final action = BasicPathAction(source, pattern: pattern, excludes: excludes);

  // step 2: core processing stage
  final regexp = r'version: 1.0.\d+';
  try {
    action.search(regexp);
  } on ArgumentError catch (e) {
    print(e);
  } catch (e) {
    print(e);
  }

  // ufn_lastline
}

// matches all yaml files in the current directory, excluding hidden items
// search `version: 1.0.\d+` replace to 'version: 1.0.1'
void actionReplace() {
  // step 1: input preparation stage
  final pattern = r'**.yaml';
  final excludes = [r'.**'];
  final source = '.';
  final action = BasicPathAction(source, pattern: pattern, excludes: excludes);

  // step 2: core processing stage
  final regexp = r'version: 1.0.\d+';
  final replace = 'version: 1.0.1';
  try {
    action.search(regexp, replace: replace);
  } on ArgumentError catch (e) {
    print(e);
  } catch (e) {
    print(e);
  }

  // ufn_lastline
}
