#!/usr/bin/env bash
# Best-effort HTTP probes for GitHub / Docker Hub / Hugging Face / PyPI (no Docker needed).
set -euo pipefail
say() { printf '%s\n' "$*"; }
probe() {
  local name="$1" url="$2"
  local code
  code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 -L "$url" 2>/dev/null || true)
  [[ "$code" =~ ^[0-9]{3}$ ]] || code="000"
  say "$name	HTTP $code	$url"
}
say "=== RuView network probe $(date '+%Y-%m-%d %H:%M %Z') ==="
probe "GitHub RuView" "https://github.com/ruvnet/RuView"
probe "GitHub raw user-guide" "https://raw.githubusercontent.com/ruvnet/RuView/main/docs/user-guide.md"
probe "Docker Hub wifi-densepose" "https://hub.docker.com/v2/repositories/ruvnet/wifi-densepose/tags/sha-a175477"
probe "Docker Hub registry v2" "https://registry-1.docker.io/v2/"
probe "Hugging Face pretrained" "https://huggingface.co/ruvnet/wifi-densepose-pretrained"
probe "PyPI ruview" "https://pypi.org/pypi/ruview/json"
probe "espressif idf docs" "https://docs.espressif.com/projects/esp-idf/en/v5.4/"
probe "cognitum.one" "https://cognitum.one"
say "(Docker Hub /v2 often returns 401 — reachable but needs auth token exchange)"
