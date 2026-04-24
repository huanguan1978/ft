#!/bin/sh

################################################################################
# ft - Installation Script
# 
# Supported Platforms and Installation Methods:
# 
# 1. macOS (Darwin)
#    - ARM64 (Apple Silicon M1/M2/M3): downloads ft-macos-arm64-1.0.7.zip
#    - x86_64 (Intel): downloads ft-macos-x64-1.0.7.zip
#    - Install directory: $HOME/.local/bin
#    - Installation methods:
#      * Automatic: bash install.sh (this script)
#      * Package manager: sudo port install ft (MacPorts)
#      * Package manager: brew tap huanguan1978/tap && brew install huanguan1978/tap/ft (Homebrew)
#
# 2. Linux
#    - x86_64: downloads ft-linux-x64-1.0.7.zip
#    - ARM64 (aarch64): downloads ft-linux-arm64-1.0.7.zip
#    - ARM32 (armv7l): downloads ft-linux-arm-1.0.7.zip
#    - RISCV64: downloads ft-linux-riscv64-1.0.7.zip
#    - Install directory: $HOME/.local/bin
#    - Installation method: bash install.sh (this script)
#
# 3. Windows (compatible shells only)
#    - Git for Windows (MINGW64_NT)
#    - MSYS2 (MSYS_NT)
#    - Cygwin (CYGWIN)
#    - x86_64: downloads ft-windows-x64-1.0.7.zip
#    - Install directory: $HOME/AppData/Local/bin
#    - Installation methods:
#      * Automatic: bash install.sh (this script)
#      * Package manager: winget install gai.filetools
#
# Prerequisites:
#    - curl: for downloading the binary
#    - unzip: for extracting the archive
#    - sh-compatible shell (bash, zsh, dash, etc.)
#
# Troubleshooting - Manual Installation:
#    If automatic installation fails, download the binary manually:
#    1. Visit: https://github.com/huanguan1978/ft/releases
#    2. Download the appropriate zip file for your platform
#    3. Extract the zip file (executable is in build/ subdirectory)
#    4. Copy the executable to your preferred location (e.g., ~/.local/bin/ft)
#    5. Make sure the directory is in your PATH environment variable
#    6. Verify installation by running: ft --version
#
################################################################################

set -e

# Configuration
VERSION="1.0.7"
REPO="huanguan1978/ft"
RELEASE_PAGE="https://github.com/huanguan1978/ft/releases"

# Detect OS and architecture
UNAME_OS=$(uname -s)
ARCH=$(uname -m)

# Convert OS name
case "$UNAME_OS" in
    Darwin)                        OS_NAME="macos" ;;
    Linux)                         OS_NAME="linux" ;;
    MINGW64_NT* | MSYS_NT* | CYGWIN*) OS_NAME="windows" ;;
    *)                             echo "Error: Unsupported OS: $UNAME_OS"; exit 1 ;;
esac

# Set install directory based on OS
if [ "$OS_NAME" = "windows" ]; then
    INSTALL_DIR="$HOME/AppData/Local/bin"
else
    INSTALL_DIR="$HOME/.local/bin"
fi

# Convert architecture name
case "$ARCH" in
    x86_64)  ARCH_NAME="x64" ;;
    arm64)   ARCH_NAME="arm64" ;;
    aarch64) ARCH_NAME="arm64" ;;
    armv7l)  ARCH_NAME="arm" ;;
    riscv64) ARCH_NAME="riscv64" ;;
    *)       echo "Error: Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Build filename and download URL
FILE_NAME="ft-${OS_NAME}-${ARCH_NAME}-${VERSION}.zip"
URL="https://github.com/${REPO}/releases/download/v${VERSION}/${FILE_NAME}"

echo "========================================"
echo "ft Installation Script v${VERSION}"
echo "========================================"
echo "Detected: OS=$OS_NAME, Architecture=$ARCH_NAME"
echo "Install directory: $INSTALL_DIR"
echo ""
echo "Downloading: $URL"
echo ""

# Create install directory and download
mkdir -p "$INSTALL_DIR" || { echo "Error: Failed to create directory $INSTALL_DIR"; exit 1; }

TMP_DIR=$(mktemp -d) || { echo "Error: Failed to create temporary directory"; exit 1; }
cd "$TMP_DIR"

if ! curl -LO "$URL" 2>/dev/null; then
    echo "Error: Download failed. This may be due to:"
    echo "  - Network connectivity issues"
    echo "  - Incorrect platform/architecture detection"
    echo ""
    echo "Please download the binary manually from:"
    echo "$RELEASE_PAGE"
    echo ""
    echo "Then follow the manual installation steps in the script comments."
    rm -rf "$TMP_DIR"
    exit 1
fi

# Extract and install
if ! unzip -q -o "$FILE_NAME"; then
    echo "Error: Failed to extract the archive. Ensure unzip is installed."
    rm -rf "$TMP_DIR"
    exit 1
fi

# Find the executable file (in build/ subdirectory)
EXECUTABLE=""

# Try exact filename based on OS (Windows has .exe extension)
if [ "$OS_NAME" = "windows" ]; then
    if [ -f "build/ft-${VERSION}-${OS_NAME}-${ARCH_NAME}.exe" ]; then
        EXECUTABLE="build/ft-${VERSION}-${OS_NAME}-${ARCH_NAME}.exe"
    fi
else
    if [ -f "build/ft-${VERSION}-${OS_NAME}-${ARCH_NAME}" ]; then
        EXECUTABLE="build/ft-${VERSION}-${OS_NAME}-${ARCH_NAME}"
    fi
fi

# Fallback: search for any executable matching 'ft*'
if [ -z "$EXECUTABLE" ]; then
    EXECUTABLE=$(find build -name "ft*" -type f -executable 2>/dev/null | head -1)
fi

if [ -z "$EXECUTABLE" ] || [ ! -f "$EXECUTABLE" ]; then
    echo "Error: Could not find 'ft' executable in the archive."
    echo "The archive structure may have changed. Please download manually:"
    echo "$RELEASE_PAGE"
    echo ""
    echo "Manual Installation Steps:"
    echo "1. Download the zip file from: $RELEASE_PAGE"
    echo "2. Extract the archive"
    echo "3. Find the 'ft' executable (in build/ subdirectory)"
    echo "4. Copy it to: $INSTALL_DIR/ft (or $INSTALL_DIR/ft.exe on Windows)"
    echo "5. Make it executable: chmod +x $INSTALL_DIR/ft"
    rm -rf "$TMP_DIR"
    exit 1
fi

if ! mv "$EXECUTABLE" "$INSTALL_DIR/ft"; then
    echo "Error: Failed to move ft to $INSTALL_DIR"
    echo "You may need elevated permissions. Try: sudo mv $EXECUTABLE $INSTALL_DIR/ft"
    rm -rf "$TMP_DIR"
    exit 1
fi

chmod +x "$INSTALL_DIR/ft" 2>/dev/null || true

# Cleanup
rm -rf "$TMP_DIR"

# Verify installation
if ! [ -x "$INSTALL_DIR/ft" ]; then
    echo "Error: Installation verification failed. ft executable not found or not executable."
    exit 1
fi

# Prompt user to update PATH if needed
echo "========================================"
echo "✓ Installation completed!"
echo "========================================"
echo "ft has been installed to: $INSTALL_DIR/ft"
echo ""

if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    echo "⚠ Action required: Add $INSTALL_DIR to your PATH"
    echo ""
    echo "Run:"
    echo "  export PATH=\"\$PATH:$INSTALL_DIR\""
    echo ""
    if [ "$OS_NAME" = "windows" ]; then
        echo "To persist this, add the above line to your .bashrc or .profile"
    else
        echo "To persist this, add the above line to ~/.bashrc, ~/.zshrc, or ~/.profile"
    fi
    echo ""
else
    echo "✓ $INSTALL_DIR is already in your PATH"
    echo ""
fi

echo "Verify installation:"
echo "  ft --version"
echo ""
echo "For help:"
echo "  ft --help"
echo ""
if [ "$OS_NAME" = "macos" ]; then
    echo "Note: On macOS, you can also install via package manager:"
    echo "  - MacPorts: sudo port install ft"
    echo "  - Homebrew: brew tap huanguan1978/tap && brew install huanguan1978/tap/ft"
fi

if [ "$OS_NAME" = "windows" ]; then
    echo "Note: On Windows, you can also install via package manager:"
    echo "  - Winget: winget install gai.filetools"
fi