#!/usr/bin/env bash
set -euo pipefail
NAME="${RUVIEW_CONTAINER_NAME:-cn-deploy-ruview-sim}"
if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found"; exit 2
fi
if docker ps -a --format '{{.Names}}' | grep -qx "$NAME"; then
  docker rm -f "$NAME"
  echo "Removed $NAME"
else
  echo "No container named $NAME"
fi
