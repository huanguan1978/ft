# 极速入门教程


## T1-通配符

快速匹配文件系统路径（包含目录和文件名）。

- 语法要点 
    - Posix路径规范：始终使用 `/` 作为目录分隔符；
    - 大小写敏感：除Windows系统外都区分大小写；
- 核心符号
    - `*` (星号)： 匹配**文件名**中零个或多个除 `/` 以外的任意字符；  
    例如：`lib/*.dart` 匹配 `lib/ft.dart`，不匹配 `lib/src/ft_base.dart`。

    - `**` (双星号)： 匹配**跨目录**的零个或多个任意字符，包括 `/`，用于递归匹配；  
    例如：`lib/**.dart` 匹配 `lib/ft.dart` 和 `lib/src/ft_base.dart`。  
    **注意：** 以`**`开头，不匹配绝对路径或 `../` 开头的路径，如`**.md`不匹配`/README.md`但`/**.md`匹配。

    -  `?` (问号)： 匹配文件名中**单个**除 `/` 以外的任意字符。  
    例如：`test?.dart` 匹配 `test1.dart`，不匹配 `test10.dart` 或 `test.dart`。

    - `[...]` (方括号)： 匹配**单个**方括号内列举的字符（不包括 `/`）；  
    （如 `[abc]`）或范围内的字符（如 `[a-zA-Z]`）  
    `[^...]` OR `[!...]`：匹配**单个**不在方括号内列举的字符。

    - `{...,...}` (花括号)： 匹配逗号分隔的**多个 glob 模式之一**；  
    例如：`lib/{*.dart,src/*}` 匹配 `lib/ft.dart` 和 `lib/src/ft_base.txt`。
    
    - `\` (反斜杠)： 用于**转义**通配符字符，使其作为普通字符匹配；  
    例如：`\*.dart` 匹配字面量 `*.dart`。

## T2-路径

**路径**是文件系统中定位文件或目录的地址，它既能指向一个文件（如 *README.md*），也能指向一个目录（如 *example/*）；路径是文件系统组织和管理文件的基本方式。

-   **绝对路径**：从**文件系统的根目录**出发，完整描述目标文件或目录的精确位置。
    *   **示例：**
        *   **Windows:** `C:\Users\Username\Downloads\ft\README.md`
        *   **Linux/macOS:** `/home/username/Downloads/ft\README.md`
        *   **URL (Web):** `https://webpath.iche2.com/app/fileshows/download_en.html`

-   **相对路径**：从**当前位置**出发，描述目标文件或目录的走向。
    *   **常用符号：**
        *   `.` (单点): 表示当前目录。
        *   `..` (双点): 表示上一级目录。
    *   **示例：** (假设当前工作目录是 `C:\Users\Username\Downloads\ft` 或 `/home/username/Downloads/ft`)
        *   `README.md` (指当前目录下的 `README.md`)
        *   `docs/started.md` (指当前目录下的 `docs` 文件夹中的 `started.md`)
        *   `../ft.exe` (指当前目录`ft`的**上级目录**中的 `Downloads` 文件夹中的 `ft.exe`)
        *   **URL (Web):** `app/fileshows/download_en.html` (如果当前页面是 `https://webpath.iche2.com/` 则为 `https://webpath.iche2.com/app/fileshows/download_en.html`)

-   **路径变量**：是一种**占位符**，在被系统解析时会替换成预设的实际路径值。

    * 路径变量主要来源于环境变量，或`ft`的参数`--define`声明的一到多个变量。

    *   **示例：**
        *   `~` （Unix-like）或`%USERPROFILE%`（Windows）变量存储了当前用户主目录的绝对路径。
        *   `$PATH` (Unix-like) 或`%PATH%` (Windows) 变量存储了一系列可执行文件的目录列表。

    * `ft`也提供一些内置路径变量，如下：

        * dynamic variable, `CURDIR`, `CURDATE`, `CURDATETIME`.
        * relative variable, prefix: AGODATE, AGODATETIME; format: prefix+ num+ unit.        
        
        * EXAMPLE NOW: 2025-08-29T09:02:26.441496;  
        CURDATE: 20250829; CURDATETIME: 20250829090226  
        AGODATE1DAY: 20250828; AGODATETIME1DAY: 20250828090226  
        AGODATE1WEEK: 20250822; AGODATETIME1WEEK: 20250822090226    


## T3-路径匹配工作流

`ft` is the open-source CLI version developed for the GUI application **FileShows**. Using the `ft list` command, users can specify the `source` directory, match with a `pattern` (default to `**`), optionally exclude paths using `excludes`, and retrieve matching paths.

`ft` 是为GUI应用 **FileShows** 所开发的开源CLI版本。
通过 `ft list` 命令，用户可以指定 `source` 目录，通过 `pattern` (默认为`**`) 匹配，并可选地利用 `excludes` 排除，以获取通配符匹配路径。


**CLI示例：** 
```sh 
# Unix-like，列出`~/Desktop`目录下所有文件：   
ft list --source=~/Desktop  
# Unix-like，列出`~/Desktop`目录下所有 Markdown文件：   
ft list --source=~/Desktop --pattern="**.md"
# Unix-like，列出`~/Desktop`目录下所有Markdown文件，排除sketch目录：  
ft list --source=~/Desktop --pattern="**.md" --excludes="/**/sketch/**"
```

```powershell
# Windows，列出`%USERPROFILE%\Desktop`目录下所有文件：   
ft list --source=~/Desktop
# Windows，列出`%USERPROFILE%\Desktop`目录下所有TEXT文件：   
ft list --source=~/Desktop --pattern="**.txt"
# Windows，列出`%USERPROFILE%\Desktop`目录下所有TEXT文件，排除sketch目录：  
ft list --source=~/Desktop --pattern="**.txt" --excludes="?:/**/sketch/**"
# Windows，列出`%USERPROFILE%\Desktop`目录下所有文件，排除`*.lnk`类型文件：  
# same excludes, "C:/**/*.lnk", "?:/**/*.lnk", "??/**/*.lnk", "*/**/*.lnk"
ft list --source=~/Desktop --excludes="*/**/*.lnk"
```
注意：为了更好的跨平台使用，路径处理内部倾向于用POSIX标准(斜杠`/`作为路径分隔符)，环境变量`HOME`或`USERPROFILE`均可用`~`代替。


## T4-文件属性筛选
在通过路径匹配（如Glob模式）得到匹配文件清单后，还可以进一步根据文件的**属性**对清单进行二次筛选。

**可筛选属性及其值格式：**
*   `size`：文件大小。值支持单位后缀：`B` (字节，默认), `K` (千字节), `M` (兆字节), `G` (吉字节), `T` (太字节), `P` (拍字节)。
*   `time`：文件修改时间。值支持格式：`YYYYMMDD` (年-月-日) 或 `YYYYMMDDTHHMMSS` (年-月-日T时分秒)。

Note：`time` support  **Human-Readable Relative Time** as: **[Quantity] [Time Unit] ago**. It quantifies the duration passed since an event. e.g. `1 hour ago`, `2 days ago` ...

**筛选参数定义：**
*   `size_ge` (Size Greater Equal): 文件大小大于或等于指定值。
*   `size_le` (Size Less Equal): 文件大小小于或等于指定值。
*   `time_ge` (Time Greater Equal): 文件修改时间大于或等于指定日期/时间。
*   `time_le` (Time Less Equal): 文件修改时间小于或等于指定日期/时间。

---
> 为了更好地查看**筛选后**的文件清单及其属性，您可以利用 **全局输出选项**`--fields`进行美化输出，通过定制输出字段，可以更直观地验证筛选结果，示例如下。
>-   输出状态：  
    `--fields=ok,action,type`
>-   输出状态和文件属性信息：  
    `--fields=ok,action,type,size,time`
>-   输出状态、文件属性信息和附加信息：  
    `--fields=ok,action,type,size,time,perm,mime,extra`
    
---

**筛选参数示例 (结合`ft list`命令)：**
*   列出`~/Downloads`目录下所有空文件：  
    `ft list --source=~/Downloads --size_le=1`  
    `ft list --source=~/Downloads --size_le=1 --fields=ok,action,type,size,time`
*   列出`~/Downloads`目录下所有大于100M的文件：  
    `ft list --source=~/Downloads --size_ge=100M`  
    `ft list --source=~/Downloads --size_ge=100M --fields=ok,action,type,size,time`
*   列出`~/Downloads`目录下所有2020年之前修改的文件：  
    `ft list --source=~/Downloads --time_le=20200101`
*   列出`~/Downloads`目录下所有在2025年8月4日09点至17点之间修改的文件：  
    `ft list --source=~/Downloads --time_le=20250804T170000 --time_ge=20250804T090000`
*   列出`~/Downloads`目录下所有2025年之前修改且大小大于100M的文件：  
    `ft list --source=~/Downloads --time_le=20250101 --size_ge=100M`
*   列出`~/Desktop`目录下所有1月之前的文件：  
    `ft list --source=~/Desktop --time_le='1 month ago'


## T5-路径匹配-示例

```sh
# ft list --help
# Usage: ft list <source> [arguments]
ft list ～/Downloads --pattern='**.zip' --size_ge=1M --fileds=ok,action,type,size,time
```

| Ok  | Action  | Type   | Size   | Modified  | Path  |
|---|---|---|---|---|---|
| 1  |  list   | f    | 4.6M | Aug 01 16:33  | ~/Downloads/FileShows-icons-5.zip     |
| 1  |  list   | f    | 1.6M | Dec 11 2024 | ~/Downloads/BOC202411/BOC-2024-11-0.pdf.zip     |


## T6-文本搜索
在匹配路径后获得的文本类型文件内容中，用正则表达式进行搜索。

```sh
# ft search --help
# Usage: ft search <source> --regexp=<pattern> [arguments]
ft search ~/Downloads --pattern="**.yaml" --excludes="/**/.**" --regexp="version: 1.\d+.\d+"  --fields=ok,action,type,time,size,extra
```

| Level | LineNo | LineText | Path |
|---|---|---|---|
|i | L:3 | I:version: 1.0.1 | F:~/Downloads/xft/pubspec.yaml |
|i | L:3 | I:version: 1.0.0 | F:~/Downloads/ft/pubspec.yaml  |


## T7-正则表达式基础语法
-   字符:
    -   `.`: 匹配除换行符以外的任何单个字符 (启用 `dotAll` 标志，则匹配任何字符)。
    -   `\d`: 匹配任何数字 (0-9)。
    -   `\D`: 匹配任何非数字字符。
    -   `\w`: 匹配任何字母、数字或下划线 (word character)。
    -   `\W`: 匹配任何非单词字符。
    -   `\s`: 匹配任何空白字符 (空格、制表符、换行符等)。
    -   `\S`: 匹配任何非空白字符。
    -   `[abc]`: 匹配字符 'a'、'b' 或 'c' 中的任意一个。
    -   `[^abc]`: 匹配除了 'a'、'b' 或 'c' 之外的任何字符。
    -   `[a-z]`: 匹配任何小写字母。
    -   `[A-Z]`: 匹配任何大写字母。
    -   `[0-9]`: 匹配任何数字。

-   量词:
    -   `*`: 匹配前一个元素零次或多次。
    -   `+`: 匹配前一个元素一次或多次。
    -   `?`: 匹配前一个元素零次或一次。
    -   `{n}`: 匹配前一个元素恰好 n 次。
    -   `{n,}`: 匹配前一个元素至少 n 次。
    -   `{n,m}`: 匹配前一个元素 n 到 m 次。

-   定位符:
    -   `^`: 匹配字符串的开头 (启用 `multiLine` 标志，则匹配行的开头)。
    -   `$`: 匹配字符串的结尾 (启用 `multiLine` 标志，则匹配行的结尾)。
    -   `\b`: 匹配单词边界。
    -   `\B`: 匹配非单词边界。

-   分组与捕获:
    -   `(pattern)`: 创建一个捕获组。
    -   `(?:pattern)`: 创建一个非捕获组。

-   特殊字符转义:  
    如果你想匹配正则表达式中的特殊字符（如 `.`, `*`, `+`, `?`, `(`, `)`, `[`, `]`, `{`, `}`, `|`, `^`, `$`, `\`），你需要用反斜杠 `\` 进行转义。  
    例如：`\.` 匹配一个点，`\?` 匹配一个问号。

深入学习正则表达式，可参考 [MDN Web Docs](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_expressions "javascript regular expressions"), [Step-by-Step Learning](https://regexlearn.com "Learn Regex step by step, from zero to advanced").


## T8-参数值和环境变量：何时加引号？

核心原则：当值或变量展开后有`空格`或`特殊字符`时，必须加引号。  
特殊字符：* ? [] < > | & ; $ # \ ( )

如何选择引号？

1.  单引号 (`'...'`)：
    *   提供**字面值**：引号内内容**不被Shell解释**（无变量、无命令、无转义）。
    *   用途：需内容原封不动时。

2.  双引号 (`"..."`)：
    *   提供**部分解释**：**展开变量**、**命令替换**，但保护空格。
    *   用途：最常用，需变量/命令输出且保护空格时。

注意：`cmd.exe` (Windows)，不支持单引号。

速记：有空格/特殊字符？ -> 加引号，默认双引号；需纯文本时用单引号。