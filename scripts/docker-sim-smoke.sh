#!/usr/bin/env bash
# Smoke the Docker simulated stack: /health + authenticated sensing endpoints.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
[[ -f "$ROOT/.env" ]] && set -a && source "$ROOT/.env" && set +a
[[ -f "$ROOT/local/.env" ]] && set -a && source "$ROOT/local/.env" && set +a

HTTP_PORT="${RUVIEW_HTTP_PORT:-3000}"
BASE="http://127.0.0.1:${HTTP_PORT}"
NAME="${RUVIEW_CONTAINER_NAME:-cn-deploy-ruview-sim}"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker not found — cannot smoke." >&2
  exit 2
fi
if ! docker ps --format '{{.Names}}' | grep -qx "$NAME"; then
  echo "ERROR: container $NAME not running. Run ./scripts/docker-sim-up.sh first." >&2
  exit 2
fi

echo "=== docker-sim-smoke $(date '+%Y-%m-%d %H:%M %Z') ==="
echo "container: $(docker inspect -f '{{.State.Status}} image={{.Config.Image}}' "$NAME")"

# wait for health
ok=0
for i in $(seq 1 30); do
  code=$(curl -sS -o /tmp/ruview-health.json -w '%{http_code}' --max-time 3 "$BASE/health" 2>/dev/null || true)
  if [[ "$code" == "200" ]]; then ok=1; break; fi
  sleep 1
done
if [[ "$ok" != "1" ]]; then
  echo "FAIL: /health not ready. Last logs:" >&2
  docker logs --tail 40 "$NAME" >&2 || true
  exit 1
fi
echo "GET /health → HTTP 200"
cat /tmp/ruview-health.json; echo

auth=()
if [[ -n "${RUVIEW_API_TOKEN:-}" ]]; then
  auth=(-H "Authorization: Bearer ${RUVIEW_API_TOKEN}")
else
  echo "WARN: RUVIEW_API_TOKEN unset — /api/v1/* may 401"
fi

for path in /api/v1/info /api/v1/sensing/latest /api/v1/vital-signs; do
  code=$(curl -sS -o "/tmp/ruview${path//\//_}.json" -w '%{http_code}' --max-time 8 "${auth[@]}" "$BASE$path" || true)
  echo "GET $path → HTTP $code"
  head -c 400 "/tmp/ruview${path//\//_}.json" 2>/dev/null || true
  echo
done

echo "OK smoke finished. Open UI at $BASE/"
