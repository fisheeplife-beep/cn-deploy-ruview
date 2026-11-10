#!/usr/bin/env bash
# RuView CN preflight — Docker simulated path readiness (+ hints for ESP32 / HA).
set -euo pipefail

ok=0; warn=0; bad=0
say() { printf '%s\n' "$*"; }
pass() { say "✅ $*"; ok=$((ok+1)); }
warn_() { say "⚠️  $*"; warn=$((warn+1)); }
fail() { say "❌ $*"; bad=$((bad+1)); }

say "=== RuView CN preflight (Docker simulated / ESP32 / HA) ==="
say ""
say "Host: $(uname -s) $(uname -m)"
say "Time: $(date '+%Y-%m-%d %H:%M %Z')"
say ""

arch=$(uname -m)
case "$arch" in
  x86_64|amd64|aarch64|arm64) pass "CPU arch $arch" ;;
  *) fail "Unsupported arch $arch (need amd64 or arm64 for official Docker image)" ;;
esac

cpus=$(nproc 2>/dev/null || echo 0)
if [[ "$cpus" -ge 2 ]]; then pass "CPUs $cpus"; else warn_ "CPUs $cpus — Docker sim is light, but ESP32 flash hosts prefer ≥2"; fi

if [[ -r /proc/meminfo ]]; then
  avail_kb=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
  avail_gib=$((avail_kb / 1024 / 1024))
  total_kb=$(awk '/MemTotal/{print $2}' /proc/meminfo)
  total_gib=$((total_kb / 1024 / 1024))
  if [[ "$avail_gib" -ge 2 ]]; then
    pass "RAM available ~${avail_gib} GiB (total ~${total_gib} GiB) — Docker sim asks ≥4 GiB total"
  else
    warn_ "RAM available ~${avail_gib} GiB / total ~${total_gib} GiB — upstream recommends ≥4 GiB"
  fi
fi

if df -Pk . >/dev/null 2>&1; then
  avail_kb=$(df -Pk . | awk 'NR==2{print $4}')
  avail_gb=$((avail_kb / 1024 / 1024))
  if [[ "$avail_gb" -ge 5 ]]; then pass "Disk free ~${avail_gb} GB (≥5 recommended)"; else warn_ "Disk free ~${avail_gb} GB — image ~45 MiB compressed but leave headroom"; fi
fi

for t in git curl jq openssl; do
  if command -v "$t" >/dev/null 2>&1; then pass "$t present"; else fail "$t missing"; fi
done

if command -v python3 >/dev/null 2>&1; then
  pass "python3: $(python3 --version 2>&1)"
else
  warn_ "python3 missing — needed for provision.py / esptool on path B"
fi

if command -v docker >/dev/null 2>&1; then
  pass "docker: $(docker --version 2>/dev/null | head -1)"
  if docker info >/dev/null 2>&1; then pass "docker daemon reachable"; else fail "docker daemon not reachable"; fi
  if docker compose version >/dev/null 2>&1; then
    pass "docker compose: $(docker compose version 2>/dev/null | head -1)"
  else
    warn_ "docker compose plugin missing — path A can still use docker run"
  fi
else
  fail "Docker Engine missing — path A (simulated) needs Docker 20+"
fi

# Path B / C soft checks
if command -v esptool.py >/dev/null 2>&1 || command -v esptool >/dev/null 2>&1 || python3 -c 'import esptool' 2>/dev/null; then
  pass "esptool available (path B flash helper)"
else
  warn_ "esptool not installed — path B: pip install 'esptool>=5.3' (C5 needs ≥5.3; measured 5.6.0)"
fi
if command -v idf.py >/dev/null 2>&1; then
  pass "ESP-IDF idf.py present"
else
  warn_ "ESP-IDF not on PATH — path B can use prebuilt release bundles or espressif/idf Docker build"
fi
if ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | head -1 >/dev/null; then
  pass "serial device visible: $(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | tr '\n' ' ')"
else
  warn_ "no /dev/ttyUSB* or /dev/ttyACM* — expected when flashing ESP32 on this host"
fi

# ports
ports=(3000 3001 5005)
busy=()
if command -v ss >/dev/null 2>&1; then
  for p in "${ports[@]}"; do
    if ss -lntu 2>/dev/null | grep -qE ":${p}\\s"; then busy+=("$p"); fi
  done
fi
if [[ ${#busy[@]} -eq 0 ]]; then pass "ports 3000/tcp 3001/tcp 5005/udp look free (best-effort)"; else warn_ "ports possibly busy: ${busy[*]}"; fi

say ""
say "--- network (best-effort) ---"
probe() {
  local name="$1" url="$2"
  local code
  code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 12 -L "$url" 2>/dev/null || true)
  [[ "$code" =~ ^[0-9]{3}$ ]] || code="000"
  if [[ "$code" =~ ^(200|301|302|401|403)$ ]]; then pass "Reachable: $name (HTTP $code)"; else warn_ "Unreachable/slow: $name ($url → HTTP $code)"; fi
}
probe "GitHub RuView" "https://github.com/ruvnet/RuView"
probe "Docker Hub tag sha-a175477" "https://hub.docker.com/v2/repositories/ruvnet/wifi-densepose/tags/sha-a175477"
probe "Hugging Face pretrained" "https://huggingface.co/ruvnet/wifi-densepose-pretrained"
probe "PyPI ruview" "https://pypi.org/pypi/ruview/json"

say ""
say "=== summary: ${ok} ok / ${warn} warn / ${bad} bad ==="
say "Path A needs Docker + RUVIEW_API_TOKEN + CSI_SOURCE=simulated."
say "Path B needs ESP32-S3/C6 (+ CSI) and UDP allowlist. Path C needs MQTT broker + HA 2025.5+."
[[ "$bad" -gt 0 ]] && exit 1
exit 0
