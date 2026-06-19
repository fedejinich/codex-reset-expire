#!/usr/bin/env bash
set -euo pipefail

APP_NAME="CodexResetsExpire"
DISPLAY_NAME="Codex Resets"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_APP="$ROOT_DIR/dist/$APP_NAME.app"
TARGET_APP="/Applications/$DISPLAY_NAME.app"

cd "$ROOT_DIR"
./script/build_and_run.sh --verify

pkill -x "$APP_NAME" >/dev/null 2>&1 || true
rm -rf "$TARGET_APP"
/usr/bin/ditto "$SOURCE_APP" "$TARGET_APP"
/usr/bin/open "$TARGET_APP"

echo "Installed $DISPLAY_NAME to $TARGET_APP"
