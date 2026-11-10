#!/usr/bin/env bash
# List / optionally download pinned ESP32 firmware release assets (path B checklist).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
[[ -f "$ROOT/.env" ]] && set -a && source "$ROOT/.env" && set +a
TAG="${ESP32_FW_TAG:-v0.8.18-esp32}"
DEST="${ESP32_FW_DEST:-data/firmware}"
DO_DOWNLOAD=0
[[ "${1:-}" == "--download" ]] && DO_DOWNLOAD=1

echo "=== ESP32 firmware release $TAG ==="
if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI missing — open https://github.com/ruvnet/RuView/releases/tag/$TAG"
  exit 0
fi
gh release view "$TAG" --repo ruvnet/RuView
echo ""
gh release view "$TAG" --repo ruvnet/RuView --json assets --jq '.assets[] | "\(.name)\t\(.size)\t\(.url)"'

if [[ "$DO_DOWNLOAD" == "1" ]]; then
  mkdir -p "$ROOT/$DEST"
  echo "Downloading into $ROOT/$DEST ..."
  gh release download "$TAG" --repo ruvnet/RuView --dir "$ROOT/$DEST"
  echo "Verify SHA256SUMS.txt before flashing. See docs/esp32-flash.md"
fi

echo ""
echo "Boards: ESP32-S3 (8MB display / 4MB headless), ESP32-C6, ESP32-C5 experimental."
echo "NOT ESP32-C3 (no CSI). Prefer release bundles over reinventing menuconfig when starting."
