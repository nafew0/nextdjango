#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

exec env SETUP_PLATFORM=linux bash "$SCRIPT_DIR/setup.sh" "$@"
