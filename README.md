# cn-deploy-ruview

Chinese, follow-along **deployment companion** for [ruvnet/RuView](https://github.com/ruvnet/RuView) (WiFi DensePose / CSI sensing) — not an official fork, and not a verbatim copy of upstream docs.

**Start here (ZH):** [README.zh-CN.md](./README.zh-CN.md)

### What you get

- Preflight for the official **Docker simulated** path (plus ESP32 / Home Assistant checklists)
- Pin-tag shallow clone + Docker sim up/smoke helpers (`RUVIEW_API_TOKEN`, explicit `CSI_SOURCE=simulated`)
- ESP32 firmware release lister + HA/MQTT operator notes (UDP allowlist, device id persistence)
- China network notes differentiating from third-party ZH guides that omit token / UDP guards

### Verification snapshot (author box, 2026-11-10, Asia/Shanghai, Linux x86_64)

| Path | Status |
|------|--------|
| Upstream MIT identity + pin `v3628` / Docker `sha-a175477` | **Confirmed** |
| Network probes (GitHub / Docker Hub API / HF / PyPI) | **Verified** |
| Shallow clone `v3628` | **Verified** |
| Docker simulated stack + `/health` smoke | **Not verified** (no Docker Engine on author box) |
| ESP32 CSI flash + live UDP ingest | **Not verified** (no hardware) |
| Home Assistant MQTT entities | **Not verified** (no HA / broker) |

Pinned baseline: source **`v3628`**, image **`ruvnet/wifi-densepose:sha-a175477`**, firmware release **`v0.8.18-esp32`**. Details in `examples/`.

### Quick start (path A intent)

```bash
./scripts/preflight.sh
./scripts/clone-upstream.sh
./scripts/docker-sim-up.sh      # needs Docker
./scripts/docker-sim-smoke.sh
```

### License

Companion scripts/docs: **MIT**. Upstream RuView: **MIT** (firmware node: MIT OR Apache-2.0 per upstream).
