#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$OSTYPE" in
    msys*|cygwin*|win32*|mingw*) ;;
    *)
        echo "setup_windows.sh is intended for Git Bash on Windows."
        echo "Use setup_linux.sh on Linux/Ubuntu, or setup.sh on macOS."
        exit 1
        ;;
esac

exec env SETUP_PLATFORM=windows bash "$SCRIPT_DIR/setup.sh" "$@"
