## Why `ft`? Beyond Shell Scripts and Standard Toolchains

In Unix-like environments, we rely on `find` for discovery, `grep` for pattern matching, and `make` for orchestration. However, when workflows span across Windows, or into "distroless" and minimalist Docker containers (like Alpine or BusyBox), these familiar tools often fail due to missing binaries, inconsistent flags, or incompatible path syntax.

`ft` (FileTools) was engineered to solve this **cross-platform fragmentation** by providing a unified interface for file manipulation and automation.

### 1. True "Write Once, Run Anywhere" (Cross-Platform Consistency)
*   **Path Normalization:** The friction between Windows backslashes `\` and Unix forward slashes `/` is a persistent bottleneck in DevOps. `ft` is **POSIX-compliant** internally; you can use `/` and `~` even on Windows, allowing your scripts to be portable without modification.
*   **Zero-Dependency Binaries:** Unlike Python or Node.js scripts that require a runtime, `ft` is distributed as **self-contained native binaries** for Windows, Linux (including ARM/RISC-V), and macOS. It is the perfect fit for "scratch" containers and restricted environments.

### 2. Unified Task Orchestration (YAML vs. Makefile)
*   **Declarative Pipelines:** `ft` utilizes human-readable **YAML** configurations. You can orchestrate complex workflows using the built-in `execute` subcommand or integrate native system tools via the `shell` runner. It provides the power of a CI/CD pipeline in a local environment, replacing the cryptic syntax of Makefiles.
*   **Dynamic Variable Injection:** Beyond standard Environment Variables, `ft` introduces **First-Class Dynamic Variables** (e.g., `$CURDATE`, `$AGODATE1WEEK`). Tasks like "implementing a 7-day rolling backup (auto-purging logs older than 1 week)" become trivial, eliminating the need for complex shell arithmetic and date-parsing logic.

### 3. Intelligent Metadata Filtering
*   **Multi-Dimensional Selection:** Standard tools often make filtering by file attributes cumbersome. `ft` promotes `size` (with unit support: KB/MB/GB), `time` (with human-readable relative syntax: "1 month ago"), and `MIME Type` to **global flags**, making precise file selection effortless.
*   **Deep MIME Integration:** Instead of manual magic-number checks, use `--mime_includes='image/'` to target all visual assets, or define custom overrides for proprietary file extensions.

### 4. High-Level "Quick Apps" (Built-in Superpowers)
`ft` consolidates specialized operations that usually require piping multiple complex tools:
*   **`mirror`:** High-performance incremental synchronization—ideal for efficient data replication.
*   **`erase`:** Secure data sanitization using multi-pass overwriting, ensuring data remanence is eliminated.
*   **`fdups`:** Rapid identification and deduplication of redundant files across massive datasets.
*   **`search`:** A cross-platform **Regex engine** that remains consistent regardless of local `grep` versions. It specifically supports **Capture Group output**, allowing you to extract and pipe specific data patterns to downstream applications.

### 5. High-Value Skill Acquisition
Using `ft` and its accompanying **[Quick Start Manual](started.md)** helps users master core computing concepts that translate to any development environment:
*   **Glob Patterns:** Master the standard for modern file path matching.
*   **Regex (Regular Expressions):** Harness the "nuclear option" of text processing.
*   **MIME & Stat:** Gain a deep understanding of **File Type identification** and **Filesystem Metadata** structures.

### 6. Full-Stack Ecosystem: From CLI to GUI
`ft` serves as the core engine for **FileShows**, a professional cross-platform GUI file manager. This means the YAML automations you develop on the command line can eventually be integrated into a visual workflow on Windows, macOS, Android, or iOS, providing 360-degree coverage of your productivity needs.

---

**Conclusion:**
If you are tired of refactoring scripts for different OS environments, or managing a bloated toolchain in your containers, **`ft` (FileTools)** is your ultimate solution. It brings modern, consistent, and human-centric file management to the terminal.

**Get Started:** [GitHub - huanguan1978/ft](https://github.com/huanguan1978/ft)  
**GUI Documentation:** [FileShows Official Manual](https://webpath.iche2.com/fssdoc/en/)

