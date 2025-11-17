import 'package:filetools/ft.dart';

void main() {
  // print('os:$ftOs');

  actionList();
  // actionSearch();
}

// matches all files in the current directory, excluding hidden items
void actionList() {
  // step 1: input preparation stage
  final action = BasicPathAction(r'.', excludes: [r'.**']);

  // step 2: core processing stage
  action.list();
}

// matches yaml files in the current directory, excluding hidden items
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
