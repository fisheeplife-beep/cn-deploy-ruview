# 路径 C｜Home Assistant 对接

RuView 通过 **MQTT 自动发现（HA-DISCO）** 把感知实体推到 Home Assistant；另有 Matter Bridge 路径（Apple Home / Google Home / Alexa 等）。设计见上游 ADR-115；操作原文：[`docs/integrations/home-assistant.md`](https://github.com/ruvnet/RuView/blob/main/docs/integrations/home-assistant.md)。

本页只补：**跟做顺序、token/UDP/MQTT 坑、和站外中文文差异**。不整页翻译上游。

## 前置

| 项 | 要求 |
|----|------|
| Home Assistant | Core **≥ 2025.5**（上游测试矩阵） |
| MQTT | Mosquitto add-on 最省事；EMQX / VerneMQ 也可 |
| RuView | sensing-server **≥ 0.7.0**；本仓钉 Docker `sha-a175477` |
| 数据 | 真机 CSI（路径 B）才有现场意义；模拟仅可测「实体是否出现」 |

快速自检：

```bash
./scripts/ha-checklist.sh
```

## 推荐跟做顺序

1. 先跑通路径 A，确认你理解 `RUVIEW_API_TOKEN` 与 UI。  
2. 再跑通路径 B，确认 `/api/v1/nodes` 能看到节点（记得 Bearer token）。  
3. 在 HA 装 Mosquitto → 启用 MQTT 集成。  
4. 用 **host 网络**（Linux）或确保容器能路由到 broker，启动带 `--mqtt` 的 sensing-server。  
5. 约 5 秒内应出现 `RuView node …` 设备；原始信号 + 语义实体见上游实体表（约 15 个；privacy-mode 更少）。

## Docker 示例（Linux）

```bash
export RUVIEW_API_TOKEN=$(openssl rand -hex 32)
export MQTT_PASSWORD='你的broker密码'

docker run --rm --net=host \
  -e RUVIEW_API_TOKEN -e MQTT_PASSWORD \
  -e CSI_SOURCE=esp32 \
  -e RUVIEW_UDP_ALLOW=192.168.1.0/24 \
  ruvnet/wifi-densepose:sha-a175477 \
  --source esp32 \
  --mqtt --mqtt-host 192.168.1.10 \
  --mqtt-username homeassistant \
  --mqtt-password-env MQTT_PASSWORD
```

注意：

- **entrypoint 仍要 token**（或显式允许未认证且绑定可信地址）——只加 `--mqtt` 不够。  
- **UDP allowlist 与 MQTT 是两件事**：漏 UDP 时 HA 可能一直空或只有假状态。  
- 给 data 目录做 **volume**，保留 `mqtt_client_id`，避免每次重启冒出一堆新设备。  
- Ctrl-C **不会**先发 offline，也 **没有** MQTT LWT；可用性可能显示陈旧。  
- 心率/呼吸：要校准 + 单人 + 质量门；`--privacy-mode` 会直接不宣布生物特征实体。  
- 若干 ADR 里点名的语义实体（如 bathroom / bed-exit / pose）**当前广播带不上**，不会发现——不是你没配好。

## 与站外中文文差异

站外「Docker + ESP32 完整部署」类文章通常：

- 停在 Web UI，**几乎不写 HA/MQTT**；  
- 不提 device id 持久化与残留设备清理；  
- 不提 vitals unavailable / privacy-mode / 无 LWT。

本仓路径 C 专门补这些，避免「镜像起来了但 HA 里没有可用实体 / 实体乱增」。

## 作者机状态

作者环境 **无 Home Assistant、无 MQTT broker、无 ESP32** → 路径 C **未验证**。
