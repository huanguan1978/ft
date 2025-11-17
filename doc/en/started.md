# Quick Start Tutorial

## T1-Wildcards

Quickly match file system paths (including directories and filenames).

-   **Key Syntax Points**
    -   Posix path convention: Always use `/` as the directory separator.
    -   Case sensitivity: Case-sensitive everywhere except on Windows systems.
-   **Core Symbols**
    -   `*` (Asterisk): Matches zero or more non-`/` characters within a **filename**.
        For example: `lib/*.dart` matches `lib/ft.dart` but not `lib/src/ft_base.dart`.

    -   `**` (Double Asterisk): Matches zero or more characters **across directories**, including `/`, for recursive matching.
        For example: `lib/**.dart` matches `lib/ft.dart` and `lib/src/ft_base.dart`.
        **Note:** Paths starting with `**` do not match absolute paths or paths beginning with `../`. For instance, `**.md` will not match `/README.md`, but `/**.md` will.

    -   `?` (Question Mark): Matches a **single** non-`/` character within a filename.
        For example: `test?.dart` matches `test1.dart` but not `test10.dart` or `test.dart`.

    -   `[...]` (Brackets): Matches a **single** character listed within the brackets (excluding `/`);
        (e.g., `[abc]`) or a range of characters (e.g., `[a-zA-Z]`).
        `[^...]` OR `[!...]`: Matches a **single** character not listed within the brackets.

    -   `{...,...}` (Braces): Matches **one of the comma-separated glob patterns**.
        For example: `lib/{*.dart,src/*}` matches `lib/ft.dart` and `lib/src/ft_base.txt`.

    -   `\` (Backslash): Used to **escape** wildcard characters, treating them as literal characters for matching.
        For example: `\*.dart` matches the literal string `*.dart`.

## T2-Paths

**Paths** are addresses in the file system used to locate files or directories. They can point to a file (e.g., *README.md*) or a directory (e.g., *example/*); paths are the fundamental way the file system organizes and manages files.

-   **Absolute Paths**: Describes the precise location of a target file or directory, starting from the **file system root**.
    *   **Examples:**
        *   **Windows:** `C:\Users\Username\Downloads\ft\README.md`
        *   **Linux/macOS:** `/home/username/Downloads/ft\README.md`
        *   **URL (Web):** `https://webpath.iche2.com/app/fileshows/download_en.html`

-   **Relative Paths**: Describes the direction to a target file or directory, starting from the **current location**.
    *   **Common Notations:**
        *   `.` (Single dot): Represents the current directory.
        *   `..` (Double dot): Represents the parent directory.
    *   **Examples:** (Assuming the current working directory is `C:\Users\Username\Downloads\ft` or `/home/username/Downloads/ft`)
        *   `README.md` (refers to `README.md` in the current directory)
        *   `docs/started.md` (refers to `started.md` in the `docs` folder within the current directory)
        *   `../ft.exe` (refers to `ft.exe` in the `Downloads` folder, which is the **parent directory** of the current `ft` directory)
        *   **URL (Web):** `app/fileshows/download_en.html` (if the current page is `https://webpath.iche2.com/`, this resolves to `https://webpath.iche2.com/app/fileshows/download_en.html`)

-   **Path Variables**: Are **placeholders** that are replaced with predefined actual path values when parsed by the system.

    *   Path variables mainly originate from environment variables or one or more variables declared using `ft`'s `--define` parameter.

    *   **Examples:**
        *   `~` (Unix-like) or `%USERPROFILE%` (Windows) variables store the absolute path of the current user's home directory.
        *   `$PATH` (Unix-like) or `%PATH%` (Windows) variables store a list of directories for executable files.

    *   `ft` also provides some built-in path variables, as follows:

        *   Dynamic variables: `CURDIR`, `CURDATE`, `CURDATETIME`.
        *   Relative variables (prefix: AGODATE, AGODATETIME), format: prefix + num + unit.

        *   EXAMPLE NOW: 2025-08-29T09:02:26.441496;
            CURDATE: 20250829; CURDATETIME: 20250829090226
            AGODATE1DAY: 20250828; AGODATETIME1DAY: 20250828090226
            AGODATE1WEEK: 20250822; AGODATETIME1WEEK: 20250822090226

## T3-Path Matching Workflow

`ft` is the open-source CLI version developed for the GUI application **FileShows**.
Using the `ft list` command, users can specify the `source` directory, match with a `pattern` (defaulting to `**`), and optionally use `excludes` to filter out paths, thereby retrieving wildcard-matched paths.

**CLI Examples:**
```sh
# Unix-like, list all files in the `~/Desktop` directory:
ft list --source=~/Desktop
# Unix-like, list all Markdown files in the `~/Desktop` directory:
ft list --source=~/Desktop --pattern="**.md"
# Unix-like, list all Markdown files in the `~/Desktop` directory, excluding the sketch directory:
ft list --source=~/Desktop --pattern="**.md" --excludes="/**/sketch/**"
```

```powershell
# Windows, list all files in the `%USERPROFILE%\Desktop` directory:
ft list --source=~/Desktop
# Windows, list all TEXT files in the `%USERPROFILE%\Desktop` directory:
ft list --source=~/Desktop --pattern="**.txt"
# Windows, list all TEXT files in the `%USERPROFILE%\Desktop` directory, excluding the sketch directory:
ft list --source=~/Desktop --pattern="**.txt" --excludes="?:/**/sketch/**"
# Windows, list all files in the `%USERPROFILE%\Desktop` directory, excluding `*.lnk` type files:
# same excludes, "C:/**/*.lnk", "?:/**/*.lnk", "??/**/*.lnk", "*/**/*.lnk"
ft list --source=~/Desktop --excludes="*/**/*.lnk"
```
Note: For better cross-platform compatibility, internal path handling tends to follow the POSIX standard (using `/` as the path separator). Environment variables `HOME` or `USERPROFILE` can both be represented by `~`.

## T4-File Attribute Filtering

After obtaining a list of matched files through path matching (e.g., Glob patterns), this list can be further refined by filtering based on file **attributes**.

**Filterable Attributes and Their Value Formats:**
*   `size`: File size. Values support unit suffixes: `B` (bytes, default), `K` (kilobytes), `M` (megabytes), `G` (gigabytes), `T` (terabytes), `P` (petabytes).
*   `time`: File modification time. Values support formats: `YYYYMMDD` (YearMonthDay) or `YYYYMMDDTHHMMSS` (YearMonthDayTHourMinuteSecond).

Note: `time` supports **Human-Readable Relative Time** as: **[Quantity] [Time Unit] ago**. It quantifies the duration passed since an event. e.g. `1 hour ago`, `2 days ago` ...

**Filter Parameter Definitions:**
*   `size_ge` (Size Greater Equal): File size greater than or equal to the specified value.
*   `size_le` (Size Less Equal): File size less than or equal to the specified value.
*   `time_ge` (Time Greater Equal): File modification time greater than or equal to the specified date/time.
*   `time_le` (Time Less Equal): File modification time less than or equal to the specified date/time.

---
> To better view the **filtered** file list and its attributes, you can leverage the **global output option** `--fields` for formatted output. By customizing the output fields, you can more intuitively verify the filtering results, as shown in the examples below.
>-   Output status:
    `--fields=ok,action,type`
>-   Output status and file attribute information:
    `--fields=ok,action,type,size,time`
>-   Output status, file attribute information, and additional information:
    `--fields=ok,action,type,size,time,perm,mime,extra`
---

**Filter Parameter Examples (combined with `ft list` command):**
*   List all empty files in the `~/Downloads` directory:
    - `ft list --source=~/Downloads --size_le=1`
    - `ft list --source=~/Downloads --size_le=1 --fields=ok,action,type,size,time`
*   List all files larger than 100M in the `~/Downloads` directory:
    - `ft list --source=~/Downloads --size_ge=100M`
    - `ft list --source=~/Downloads --size_ge=100M --fields=ok,action,type,size,time`
*   List all files in the `~/Downloads` directory modified before 2020:
    `- ft list --source=~/Downloads --time_le=20200101`
*   List all files in the `~/Downloads` directory modified between 09:00 and 17:00 on August 4, 2025:
    - `ft list --source=~/Downloads --time_le=20250804T170000 --time_ge=20250804T090000`
*   List all files in the `~/Downloads` directory modified before 2025 and larger than 100M:
    - `ft list --source=~/Downloads --time_le=20250101 --size_ge=100M`
*   List all files in the `~/Desktop` directory older than 1 month:
    - `ft list --source=~/Desktop --time_le='1 month ago'`

## T5-Path Matching - Examples

```sh
# ft list --help
# Usage: ft list <source> [arguments]
ft list ～/Downloads --pattern='**.zip' --size_ge=1M --fileds=ok,action,type,size,time
```

| Ok | Action | Type | Size | Modified | Path |
|:---|:---|:---|:---|:---|:---|
| 1 | list | f | 4.6M | Aug 01 16:33 | ~/Downloads/FileShows-icons-5.zip |
| 1 | list | f | 1.6M | Dec 11 2024 | ~/Downloads/BOC202411/BOC-2024-11-0.pdf.zip |

## T6-Text Search

After matching paths, use regular expressions to search within the content of the resulting text-type files.

```sh
# ft search --help
# Usage: ft search <source> --regexp=<pattern> [arguments]
ft search ~/Downloads --pattern="**.yaml" --excludes="/**/.**" --regexp="version: 1.\d+.\d+"  --fields=ok,action,type,time,size,extra
```

| Level | LineNo | LineText | Path |
|:---|:---|:---|:---|
| i | L:3 | I:version: 1.0.1 | F:~/Downloads/xft/pubspec.yaml |
| i | L:3 | I:version: 1.0.0 | F:~/Downloads/ft/pubspec.yaml |

## T7-Regular Expression Basic Syntax

-   **Characters**:
    -   `.`: Matches any single character except newline (if `dotAll` flag is enabled, matches any character).
    -   `\d`: Matches any digit (0-9).
    -   `\D`: Matches any non-digit character.
    -   `\w`: Matches any letter, digit, or underscore (word character).
    -   `\W`: Matches any non-word character.
    -   `\s`: Matches any whitespace character (space, tab, newline, etc.).
    -   `\S`: Matches any non-whitespace character.
    -   `[abc]`: Matches any one of the characters 'a', 'b', or 'c'.
    -   `[^abc]`: Matches any character except 'a', 'b', or 'c'.
    -   `[a-z]`: Matches any lowercase letter.
    -   `[A-Z]`: Matches any uppercase letter.
    -   `[0-9]`: Matches any digit.

-   **Quantifiers**:
    -   `*`: Matches the preceding element zero or more times.
    -   `+`: Matches the preceding element one or more times.
    -   `?`: Matches the preceding element zero or one time.
    -   `{n}`: Matches the preceding element exactly n times.
    -   `{n,}`: Matches the preceding element at least n times.
    -   `{n,m}`: Matches the preceding element between n and m times.

-   **Anchors**:
    -   `^`: Matches the start of the string (if `multiLine` flag is enabled, matches the start of a line).
    -   `$`: Matches the end of the string (if `multiLine` flag is enabled, matches the end of a line).
    -   `\b`: Matches a word boundary.
    -   `\B`: Matches a non-word boundary.

-   **Grouping and Capturing**:
    -   `(pattern)`: Creates a capturing group.
    -   `(?:pattern)`: Creates a non-capturing group.

-   **Special Character Escaping**:
    If you want to match special characters in regular expressions (such as `.`, `*`, `+`, `?`, `(`, `)`, `[`, `]`, `{`, `}`, `|`, `^`, `$`, `\`), you need to escape them with a backslash `\`.
    For example: `\.` matches a literal dot, `\?` matches a literal question mark.

For in-depth learning of regular expressions, refer to [MDN Web Docs](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_expressions "javascript regular expressions") and [Step-by-Step Learning](https://regexlearn.com "Learn Regex step by step, from zero to advanced").

## T8-Parameter Values and Environment Variables: When to Quote?

**Core Principle:** Always enclose values or expanded variables in quotes when they contain `spaces` or `special characters`.
Special characters: `* ? [] < > | & ; $ # \ ( )`

**How to choose quotes?**

1.  **Single quotes (`'...'`)**:
    *   **Provide literal values**: Content within single quotes is **not interpreted by the Shell** (no variable expansion, command substitution, or escape sequences).
    *   **Usage**: When the content needs to be used exactly as written.

2.  **Double quotes (`"..."`)**:
    *   **Provide partial interpretation**: **Variables are expanded** and **command substitution occurs**, but spaces are preserved.
    *   **Usage**: Most common; when variable/command output is needed and spaces must be preserved.

Note: `cmd.exe` (Windows) does not support single quotes.

**Quick rule:** Spaces/special characters present? -> Use quotes, double quotes by default; use single quotes for literal text.
