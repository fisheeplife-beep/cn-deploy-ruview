# RuView 国内可跟做部署配套

> 上游仓库：[ruvnet/RuView](https://github.com/ruvnet/RuView)（**MIT**，固件节点文档标注 **MIT OR Apache-2.0**）  
> 用户指南：[`docs/user-guide.md`](https://github.com/ruvnet/RuView/blob/main/docs/user-guide.md)  
> Home Assistant：[`docs/integrations/home-assistant.md`](https://github.com/ruvnet/RuView/blob/main/docs/integrations/home-assistant.md)  
> ESP32 固件：[`firmware/esp32-csi-node/README.md`](https://github.com/ruvnet/RuView/blob/main/firmware/esp32-csi-node/README.md) · Release [`v0.8.18-esp32`](https://github.com/ruvnet/RuView/releases/tag/v0.8.18-esp32)  
> Docker 镜像：`ruvnet/wifi-densepose`（本仓钉 **`sha-a175477`**）  
> 本仓性质：**独立中文部署配套**（预检 / 钉 tag 浅克隆 / Docker 模拟脚本 / ESP32 与 HA 清单 / 国内网络与和站外文差异），**不是**官方镜像或 fork，也**不会**整页搬运上游 README 或他人中文文。

RuView（WiFi DensePose）把普通 WiFi / ESP32 **CSI** 变成存在感知、动作与实验性生命体征等信号，并可接到 **Home Assistant**（MQTT 自动发现）。**无摄像头**不等于无隐私风险：CSI / 推断状态仍可能敏感，默认应本地部署并加 API token。

系列索引：[cn-deploy](https://github.com/fisheeplife-beep/cn-deploy)

---

## 验证边界（请先看）

| 路径 | 本仓作者环境验证状态（2026-11-10，Asia/Shanghai，Linux x86_64） |
|------|----------------------------------------------------------------|
| **上游身份 / 许可证** | ✅ **已确认** — `ruvnet/RuView` MIT；钉源码 **`v3628`**（`e24be921`）；镜像 **`sha-a175477`**；固件 Release **`v0.8.18-esp32`** |
| **文档 / GitHub / Docker Hub API / HF / PyPI HTTP** | ✅ **已验证** — 见 [`examples/network-probe.txt`](./examples/network-probe.txt) |
| **浅克隆钉 tag** | ✅ **已验证** — 见 [`examples/clone-upstream.txt`](./examples/clone-upstream.txt) |
| **路径 A：Docker `CSI_SOURCE=simulated` + `/health` 冒烟** | ⚠️ **未验证** — 作者机 **无 Docker Engine**。脚本已写好，待有 Docker 的机器回填日志 |
| **路径 B：ESP32 CSI 烧录 + UDP 真机** | ⚠️ **未验证** — 无 ESP32 / 串口 / 固定信道 AP |
| **路径 C：Home Assistant MQTT 实体** | ⚠️ **未验证** — 无 HA / Mosquitto |
| **传感精度 / 医疗级生命体征** | ⚠️ **未宣称** — 上游亦标注实验性与校准门槛 |

摘要：[`examples/verification-boundary.txt`](./examples/verification-boundary.txt) · 主机快照：[`examples/host-snapshot.txt`](./examples/host-snapshot.txt)

---

## 相对站外中文文，本仓多写什么？

站外已有较完整的 Docker + ESP32 部署文（例如 CSDN/AIOT「完整部署手册」、掘金原理向长文）。**请去上游与那些文章看原理/拓扑**；本仓刻意错位，补它们容易过时或省略的点：

1. **`RUVIEW_API_TOKEN`（缺则 exit 64）** 与 API Bearer；  
2. **`RUVIEW_UDP_ALLOW` / `RUVIEW_UDP_INSECURE_LAN`（ADR-296）** — 否则真机「容器在跑但无节点」；  
3. **`CSI_SOURCE=simulated` 显式模拟** — `auto` 不再静默假数据（issue #937）；  
4. **Home Assistant / MQTT**：实体数量、device id 持久化、无 LWT、vitals 校准门槛、privacy-mode；  
5. **钉 tag / digest** + 国内 Docker Hub 弱网 save/load；  
6. **诚实验证边界**（作者机无 Docker / 无板子则标未验证）。

可参考但不抄袭： [RuView Docker+ESP32 部署手册（CSDN/AIOT）](https://aiot.csdn.net/69e1b1870a2f6a37c5a08a11.html) · [掘金原理向介绍](https://juejin.cn/post/7643037374349344809)

---

## 选哪条路？

| 场景 | 推荐 |
|------|------|
| **先看 UI / API，没有 ESP32** | **路径 A：Docker 模拟**（主推） |
| **要真实 CSI 存在/呼吸实验** | **路径 B：ESP32-S3/C6 + UDP** |
| **接到家里 HA 自动化** | **路径 C：MQTT HA-DISCO**（先 B 再 C） |
| **只测网络 / 拉源码** | `./scripts/probe-network.sh` / `./scripts/clone-upstream.sh` |

**主推：路径 A。** 没有 CSI 硬件不要把模拟数据当成「已经能穿墙看人」。

---

## 环境要求（路径 A）

| 项 | 建议 |
|----|------|
| OS | Linux / macOS / Windows + Docker |
| 资源 | ≥2 CPU、**≥4 GiB RAM**、≥5 GiB 磁盘 |
| 软件 | Docker 20+（Compose 可选）、git、curl、jq、openssl |
| 出网 | GitHub、Docker Hub（见 [`docs/china-network.md`](./docs/china-network.md)） |

```bash
git clone https://github.com/fisheeplife-beep/cn-deploy-ruview.git
cd cn-deploy-ruview
./scripts/preflight.sh
```

---

## 路径 A｜Docker 模拟（本仓主推）

```bash
./scripts/clone-upstream.sh          # 默认 RUVIEW_TAG=v3628
./scripts/docker-sim-up.sh           # 钉 sha-a175477 + CSI_SOURCE=simulated
./scripts/docker-sim-smoke.sh
```

细节：[`docs/docker-sim.md`](./docs/docker-sim.md)。Lab 环境变量模板：[`local/.env.example`](./local/.env.example)（**勿提交真 token**）。

---

## 路径 B｜ESP32 真机

见 [`docs/esp32-flash.md`](./docs/esp32-flash.md)。先 `./scripts/list-esp32-firmware.sh`；不要买 **ESP32-C3**。服务器侧必须同时有 **token + UDP allowlist**。

---

## 路径 C｜Home Assistant

见 [`docs/ha-integration.md`](./docs/ha-integration.md) 与 `./scripts/ha-checklist.sh`。

---

## 国内网络 / 排障

- [`docs/china-network.md`](./docs/china-network.md) — Hub 弱网、钉 digest、和过时 `docker run` 示例对比  
- [`docs/troubleshooting.md`](./docs/troubleshooting.md)

---

## 安全注意（勿裸奔）

1. **必设 `RUVIEW_API_TOKEN`**；不要把 3000/3001 裸暴露到公网。  
2. UDP CSI **平面无认证**——`RUVIEW_UDP_INSECURE_LAN` 仅可信局域网。  
3. 生命体征 / 跌倒等是**实验性推断**，不是医疗或安防认证产品。  
4. WiFi 密码、MQTT 密码、token 用 `local/.env`，已在 `.gitignore`。  
5. 上游 MIT；本配套脚本与文档 **MIT**，不重新授权上游镜像或固件二进制。

---

## 开源边界

- 行为以 [RuView](https://github.com/ruvnet/RuView) 与其 `docs/` 为准。  
- 商标与产品名归各自权利人；本仓仅为社区跟做笔记。  
- **未向上游开 Issue / Discussion**：Issues 已 500+ 且 Discussions 偏产品讨论；空贴「又一份中文配套」易像 spam。有 Docker 真机实测日志后再考虑用 Discussion 回馈。

---

## 系列

- 索引：[cn-deploy](https://github.com/fisheeplife-beep/cn-deploy)  
- 体检：[cn-deploy-doctor](https://github.com/fisheeplife-beep/cn-deploy-doctor)  
- 选题：[trending-gap-radar](https://github.com/fisheeplife-beep/trending-gap-radar)  
- 同系列：[cn-deploy-nvke](https://github.com/fisheeplife-beep/cn-deploy-nvke) · [cn-deploy-n8n](https://github.com/fisheeplife-beep/cn-deploy-n8n) · [cn-deploy-openclaw](https://github.com/fisheeplife-beep/cn-deploy-openclaw) · [cn-deploy-firecrawl](https://github.com/fisheeplife-beep/cn-deploy-firecrawl)
