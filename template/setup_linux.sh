#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$OSTYPE" in
    linux*) ;;
    *)
        echo "setup_linux.sh is intended for Linux or Ubuntu (including WSL)."
        echo "Use setup.sh on macOS, or setup_windows.sh from Git Bash on Windows."
        exit 1
        ;;
esac

exec env SETUP_PLATFORM=linux bash "$SCRIPT_DIR/setup.sh" "$@"
