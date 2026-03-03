`ft` (FileTools) employs a three-stage processing architecture. This modular design, through a clear separation of concerns, provides excellent maintainability, extensibility, and ease of use, facilitating rapid developer integration and feature customization.

This architecture includes:

1. Input Preparation: Environment and parameter setup.
2. Core Logic Execution: Invoking encapsulated modules.
3. Output Post-processing (Optional): For feature extension and result customization.

See the [Common API Manual](https://github.com/huanguan1978/ft/blob/main/doc/en/library.md) for a full list of available APIs.

```dart
// ft_example.dart

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

```