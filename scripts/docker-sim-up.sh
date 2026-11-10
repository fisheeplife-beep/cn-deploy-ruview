#!/usr/bin/env bash
# Path A: start wifi-densepose Docker with explicit simulated CSI.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
[[ -f "$ROOT/.env" ]] && set -a && source "$ROOT/.env" && set +a
[[ -f "$ROOT/local/.env" ]] && set -a && source "$ROOT/local/.env" && set +a

IMAGE="${RUVIEW_DOCKER_IMAGE:-ruvnet/wifi-densepose:sha-a175477}"
NAME="${RUVIEW_CONTAINER_NAME:-cn-deploy-ruview-sim}"
HTTP_PORT="${RUVIEW_HTTP_PORT:-3000}"
WS_PORT="${RUVIEW_WS_PORT:-3001}"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker not found. Install Docker Engine 20+ then retry." >&2
  exit 2
fi
if ! docker info >/dev/null 2>&1; then
  echo "ERROR: docker daemon not reachable." >&2
  exit 2
fi

if [[ -z "${RUVIEW_API_TOKEN:-}" ]]; then
  if command -v openssl >/dev/null 2>&1; then
    RUVIEW_API_TOKEN="$(openssl rand -hex 32)"
    echo "Generated ephemeral RUVIEW_API_TOKEN (not saved). Export it to curl APIs."
    echo "export RUVIEW_API_TOKEN=$RUVIEW_API_TOKEN"
  else
    echo "ERROR: set RUVIEW_API_TOKEN (container exits 64 without it)." >&2
    exit 64
  fi
fi

# Explicit simulated — do NOT rely on auto fallback (issue #937: auto fails hard).
CSI_SOURCE="${CSI_SOURCE:-simulated}"
if [[ "$CSI_SOURCE" != "simulated" ]]; then
  echo "NOTE: CSI_SOURCE=$CSI_SOURCE (path A script defaults to simulated)." >&2
fi

if docker ps -a --format '{{.Names}}' | grep -qx "$NAME"; then
  echo "Removing existing container $NAME"
  docker rm -f "$NAME" >/dev/null
fi

echo "Pulling $IMAGE ..."
docker pull "$IMAGE"

echo "Starting $NAME (CSI_SOURCE=$CSI_SOURCE, ports ${HTTP_PORT}/tcp ${WS_PORT}/tcp) ..."
docker run -d --name "$NAME" --restart unless-stopped \
  -p "127.0.0.1:${HTTP_PORT}:3000" \
  -p "127.0.0.1:${WS_PORT}:3001" \
  -e RUVIEW_API_TOKEN \
  -e "CSI_SOURCE=$CSI_SOURCE" \
  "$IMAGE"

echo "OK. UI: http://127.0.0.1:${HTTP_PORT}/"
echo "Smoke: ./scripts/docker-sim-smoke.sh"
