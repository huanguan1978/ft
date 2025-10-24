/// Support for doing something awesome.
///
/// More dartdocs go here.

library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

// ignore: implementation_imports
import 'package:glob/src/utils.dart';
import 'package:glob/list_local_fs.dart';
import 'package:glob/glob.dart';

import 'package:mime/mime.dart' show lookupMimeType, MimeTypeResolver;
import 'package:path/path.dart' as p;
import 'package:cli_util/cli_logging.dart';
import 'package:tar/tar.dart';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_config/cli_config.dart';

part 'src/ft_constant.dart';
part 'src/ft_textmime.dart';
part 'src/ft_exception.dart';
part 'src/ft_transformer.dart';
part 'src/cli/ft_cli_logger.dart';
part 'src/ft_crc64.dart';

part 'src/ft_util.dart';
part 'src/ft_size.dart';
part 'src/ft_time_ago.dart';
part 'src/ft_time.dart';
part 'src/ft_path.dart';
part 'src/ft_base.dart';
part 'src/ft_formatter.dart';
part 'src/ft_archive.dart';
part 'src/ft_action.dart';

part 'src/cli/ft_cli_home_bin.dart';
part 'src/cli/ft_cli_util.dart';
part 'src/cli/ft_cli_code.dart';
part 'src/cli/ft_cli_run.dart';

// export 'src/ft_base.dart';

// TODO: Export any libraries intended for clients of this package.
