## **ft: FileTools - 跨平台高效文件管理与自动化**

**`ft` (FileTools) 是一款强大的命令行工具，专为开发者和高级用户设计，提供**高性能、跨平台**的文件管理和任务自动化解决方案。告别繁琐的Shell脚本和平台差异，`ft` 助您轻松驾驭文件流。**

<!-- Features  -->
**核心特色：**

1.  **极致性能：** 基于**异步文件流**处理，高效应对海量文件操作，实现低内存占用与卓越吞吐量。
2.  **跨平台无缝：** 为 Windows, Linux, macOS 及主流架构提供预编译版本，一次掌握，处处可用。
3.  **智能匹配与筛选：** 灵活的 Glob 通配符，结合文件时间、大小属性，精确锁定目标文件。
4.  **丰富内置命令：** 提供 `list`, `search`, `clean`, `rmdir`, `archive`, `unarchive`, `mirror` (增量镜像), `erase`（安全擦除）, `fdups`（文件查重）,  等常用文件处理子命令，开箱即用。
5.  **强大任务自动化：**
    *   **`execute`：** 通过 YAML 配置批量运行 `ft` 内置命令，实现复杂文件工作流自动化。
    *   **`shell`：** 作为通用任务协调器，整合并批量执行任何系统原生CLI应用，实现跨工具自动化。

**`ft` 是您管理日常运维、文件部署、数据处理的理想选择，让文件操作从此变得高效、简单。**


<!-- Getting started -->

## **ft: 快速开始**

**立即体验 `ft` 强大的跨平台文件管理与自动化功能。**

### **安装 `ft`**

*   **推荐（即时使用）：**
    [**下载预编译的二进制文件**](https://github.com/huanguan1978/ft/releases)，解压即可运行。
    *   **💡 探索更多：** 查阅 [**快速上手简明手册**](started.md) 了解 `ft` 的通配符、路径、正则表达式、参数值与引号，以及工作流程。

*   **Dart/Flutter 用户：**
    `dart pub global activate --executable=ft filetools`

*   **开发者（集成）：**
    [**集成 `ft` 源代码库到您的 Dart/Flutter 项目**](library.md)。

### **使用 `ft`**

*   **通用帮助：** `ft help`
*   **命令详情：** `ft help <command>` (例如: `ft help list`)

**开始您的 `ft` 之旅！**


<!-- Usage -->

## **ft: 核心功能概览**

`ft` 的每个**快捷应用**都高效利用**异步文件流**，在路径匹配与筛选后的文件清单上执行操作。

这些快捷应用通过**全局参数**和**应用参数**（特定快捷应用独有）进行配置。

### 快捷应用分类

#### 1. 只读快捷应用 (数据获取与无修改操作)

*   `list`：列出通配清单。
*   `search`：文本内容正则匹配。
*   `fdups`：查找重复文件。
*   `archive`：归档文件/目录。
*   `unarchive`：解档文件/目录。
*   `mirror`：增量同步文件/目录。

#### 2. 读写快捷应用 (修改或删除操作，即时生效)

*   `replace`: 查找并替换文本。
*   `rmdir`：移除空目录。
*   `clean`：清除文件/目录。
*   `erase`：安全擦除文件（可多重覆写）。

#### 3. 自动化与编排快捷应用

*   `execute`：批量运行 `ft` 内部快捷应用（通过 YAML 配置）。
*   `shell`：批量运行系统原生CLI应用（通过 YAML 配置）。

---

### **命令行帮助信息**

`ft` 提供了详尽的内置帮助文档，您可以通过命令行直接查询。

#### **1. 通用帮助 (`ft help`)**

运行 `ft help` 将显示所有全局选项和可用**快捷应用**的概览。

```zsh
$ ft help
FileTools: cross-platform glob & streams. 

Usage: ft <command> <source> [arguments]

Global options:
-h, --help                        Print this usage information.
-v, --verbose                     Show additional command output.
    --version                     Print the tool version.
    --source=<path>               Specify the source (file|directory)
    --config=<file>               Loads a config file for variable referencing
    --config_txt=<yaml>           Loads a yaml text for variable referencing
    --config_gen                  Generate a custom config on curdir.
    --[no-]errexit                exit on error.
                                  (defaults to on)
    --define                      Define or override a variable from command line
    --pattern                     Glob pattern
                                  (defaults to "**")
    --excludes                    Glob pattern after exclusion (e.g. --excludes='.**')
    --fields                      show fields (ok, action, type, mime, perm, time, size, extra)
    --mime_overrides              Override or add MIME types (e.g. 'tml=text/toml,toml=application/toml')
    --mime_includes               Filter by MIME types or subtypes (e.g. 'text/markdown,text,markdown')
    --mime_excludes               Exclude specific types or subtypes (e.g. 'application/zip,zip')
    --size_le                     file size less than (in bytes, unit:B|K|M|G|T|P)
    --size_ge                     file size greater than (in bytes, unit:B|K|M|G|T|P)
    --time_le                     file time before (yyyyMMddTHHmmss | yyyyMMdd)
    --time_ge                     file time after (yyyyMMddTHHmmss | yyyyMMdd)
    --time_type=<modified>        file time type (changed | modified | accessed)

          [changed]               ctime - change time
          [modified] (default)    mtime - modification time
          [accessed]              atime - access time

Available commands:
  archive     archive source file|directory to target file. 
  clean       clean source file|diretory 
  execute     execute command blocks defined in `--config`, using `--source` as the working directory.  
  fdups       find duplicate files from source diretory 
  list        listing all entities that match a glob 
  mirror      mirror source file|diretory to target directory 
  rmdir       remove empty source directory 
  search      search with regexp or replace.  
  shell       execute script blocks defined in `--config`, using `--source` as the working directory.  
  unarchive   unarchive tar|tgz source file to target directory 
  wipe        secure wipe source file|diretory 

Run "ft help <command>" for more information about a command.
```

#### **2. 特定快捷应用帮助 (`ft help <command>`)**

运行 `ft help <command>` 可查看该**快捷应用**的详细用法、特有参数及其丰富的示例。以下是 `list` 快捷应用的帮助输出，它全面展示了如何结合全局参数进行文件匹配和筛选：

```zsh
$ ft help list
listing all entities that match a glob 

e.g. list CWD, use . or $PWD (Unix-like) or $CURDIR (ft define)
  ft list . 

e.g. list CWD, all *.md, use variable name. 
  ft list '$CURDIR' --pattern='$mdfiles' --define='mdfiles=**.md'

e.g. list CWD, excluding hiddens, verbose, pretty output. 
  ft list . --excludes='/**/.**' --fields=ok,action,type,perm,time,size -v 

e.g. list CWD, only hiddens, verbose output, show extra. 
  ft list . --excludes='/**/.**' --no-matched --fileds=extra -v 

e.g. list ~/Downloads, file size >= 100M, show size. 
  ft list ~/Downloads --size_ge=100m --fields=size  

e.g. list ~/Downloads, file time <= 20240101, show time. 
  ft list ~/Downloads --time_le=20240101 --fields=time

e.g. list ~/Downloads, use relative time (quantity unit ago). 
  ft list ~/Downloads --size_ge=100m --time_le='1 month ago' --fields=size,time

Usage: ft list <source> [arguments]
-h, --help                    Print this usage information.
    --[no-]matched            Show all matches if enabled, otherwise, show non-matches.
                              (defaults to on)
    --type=<file>             match type (file, directory, link)

          [file] (default)    is file
          [directory]         is directory
          [link]              is filesystem link

Run "ft help" to see global options.
```

### 自动化与编排
`ft execute` 是 `ft` 的核心自动化功能，它让您通过简单的 YAML 配置文件，**批量、跨平台**地运行一系列 `ft` 内部快捷应用。告别复杂的平台脚本，用统一的配置管理任务。

（如果需要**集成系统原生命令**，请使用 `ft shell` 快捷应用。）

#### `execute` 快捷应用用法概览：

```zsh
$ ft help execute
execute command blocks defined in `--config`, using `--source` as the working directory.  

e.g. generate a custom config on current directory. 
  ft --config_gen 
  ft --config=ft.yaml --config_gen 

e.g. run commands (default block) in current directory.  
  ft execute . --config=ft.yaml 

e.g. run commands (use blocks in order) in current directory.  
  ft execute . --config=ft.yaml --blocks=commands,my_commands

Usage: ft execute <source> --config=<file> --blocks=<name,...> [arguments]
-h, --help                  Print this usage information.
    --blocks=<name, ...>    execute command block in order provided.
                            (defaults to "commands")
    --delay=<seconds>       delay between blocks.
                            (defaults to "1")

Run "ft help" to see global options.
```

#### 快速体验：
把用户临时桌面工作区内的文档进行增量镜像，以便回溯近几天的文档。  

1.  生成配置文件：
    ```zsh
    $ ft execute . --config=ft-mirror-desktop.yaml --config_gen
    ```

2.  编辑配置文件：
    ```yaml
    commands:
      - ft mirror ~/Desktop '~/Documents/FileShows/mirror/Desktop/$CURDATE/$CURDATETIME' --fields=ok,action,type
      - ft rmdir --force '~/Documents/FileShows/mirror/Desktop/$AGODATE1WEEK' --fields=ok,action,type
      # - ft rmdir --force --keeptop ~/Documents/FileShows/mirror/Desktop/ --time_type=changed --time_le='1 week ago' --fields=ok,action,type,time
    ```
3.  **运行任务：**
    ```zsh
    $ ft execute . --config=ft-mirror-desktop.yaml

    i, run:ft mirror ~/Desktop '~/Documents/FileShows/mirror/Desktop/20251009/20251009075522' --fields=ok,action,type  
    i, run:ft rmdir --force '~/Documents/FileShows/mirror/Desktop/20251002'  --fields=ok,action,type  
    err: chk, path: notFound, /Users/kaguya/Documents/FileShows/mirror/Desktop/20251002
    1  mirror f ~/Documents/FileShows/mirror/Desktop/20251009/20251009075522/Screenshot 2025-09-01 at 16.23.53.png
    1  mirror f ~/Documents/FileShows/mirror/Desktop/20251009/20251009075522/.DS_Store
    1  mirror f ~/Documents/FileShows/mirror/Desktop/20251009/20251009075522/memo.txt    
    ```


## 功能模块化集成指南

`ft` 采用**三阶段处理架构**，这种**模块化设计**通过清晰的职责划分，提供了卓越的**可维护性、可扩展性与易用性**，便于开发者快速集成与功能定制。

该架构包含：

1.  **输入准备**：环境及参数设置。
2.  **核心逻辑执行**：调用已封装模块。
3.  **输出后处理**（可选）：用于功能扩展与结果定制。

---

**代码示例：**

```dart
import 'package:filetools/ft.dart';
// file: example\ft_example_action.dart

// 通配当前路径下的所有文件（排除隐藏目录或文件）, 输出日志到字符串缓冲区.
void actionList2() {
  // 阶段一: 输入准备
  final logger = StrBufLogger();

  final excludes = [r'.**'];
  final source = '.';
  final action = BasicPathAction(source, excludes: excludes)..logger = logger;

  // 阶段二: 核心逻辑执行
  late Stream<Es>? aStream;
  try {
    aStream = action.list();
  } on ArgumentError catch (e) {
    logger.stderr(e.toString());
  } catch (e) {
    logger.stderr(e.toString());
  }

  // 阶段三: 输出后处理
  if (aStream == null) return;
  late StreamSubscription subs;
  subs = aStream.listen(
    (event) {
      var (entity, stat, extra) = event.asRecord;
      logger.stdout(
        'path:${entity.path}, time: ${stat.modified}, size:${stat.size}, extra: $extra.',
      );      
    },
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
```

