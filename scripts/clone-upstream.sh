#!/usr/bin/env bash
# Shallow clone ruvnet/RuView at a pinned tag.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
[[ -f "$ROOT/.env" ]] && set -a && source "$ROOT/.env" && set +a
TAG="${RUVIEW_TAG:-v3628}"
DEST="${RUVIEW_DEST:-data/upstream-ruview}"
ABS="$ROOT/$DEST"
mkdir -p "$(dirname "$ABS")"
if [[ -d "$ABS/.git" ]]; then
  echo "Already cloned: $ABS"
  git -C "$ABS" fetch --depth 1 origin "refs/tags/${TAG}:refs/tags/${TAG}" 2>/dev/null || true
  git -C "$ABS" checkout -q "tags/${TAG}" 2>/dev/null || git -C "$ABS" checkout -q "$TAG" || true
  git -C "$ABS" describe --tags --always
  git -C "$ABS" rev-parse HEAD
  exit 0
fi
git clone --depth 1 --branch "$TAG" https://github.com/ruvnet/RuView.git "$ABS"
echo "OK $TAG → $ABS"
git -C "$ABS" describe --tags --always
git -C "$ABS" rev-parse HEAD
