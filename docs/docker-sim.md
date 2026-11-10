# 路径 A｜Docker 模拟（本仓主推）

目标：在**没有 ESP32** 的机器上，用官方镜像跑感知服务 + Web UI，确认 API / 仪表盘链路通。数据是**合成 CSI**，不是真实存在/生命体征。

## 钉版

| 项 | 值 |
|----|-----|
| 源码 CI snapshot | `v3628`（`e24be921944ed9cb9f5eea041313982f732703d8`） |
| Docker 镜像 tag | `ruvnet/wifi-densepose:sha-a175477` |
| 多架构 index digest | `sha256:20ee390719515014c1dd57dd4838ea4f28ef4af7852868cd5f73dc3d76408eff` |

> 镜像发布节奏与 CI snapshot tag 可能差几个 commit。跟做容器时以 **Docker tag/digest** 为准；读文档/脚本以 **源码 tag** 为准。

## 一键脚本

```bash
./scripts/preflight.sh
./scripts/docker-sim-up.sh
./scripts/docker-sim-smoke.sh
# 停止：
./scripts/docker-sim-down.sh
```

`docker-sim-up.sh` 会：

1. 检查 Docker；  
2. 若未设置则生成临时 `RUVIEW_API_TOKEN`（打印 `export` 行，**默认不落盘**）；  
3. `docker pull` 钉版镜像；  
4. `CSI_SOURCE=simulated` 启动，并把 HTTP/WS **只绑到 127.0.0.1**。

## 等价手搓命令

```bash
export RUVIEW_API_TOKEN=$(openssl rand -hex 32)
docker pull ruvnet/wifi-densepose:sha-a175477
docker run -d --name cn-deploy-ruview-sim \
  -p 127.0.0.1:3000:3000 -p 127.0.0.1:3001:3001 \
  -e RUVIEW_API_TOKEN -e CSI_SOURCE=simulated \
  ruvnet/wifi-densepose:sha-a175477
```

浏览器：http://127.0.0.1:3000/

```bash
curl -s http://127.0.0.1:3000/health
curl -s -H "Authorization: Bearer $RUVIEW_API_TOKEN" \
  http://127.0.0.1:3000/api/v1/sensing/latest
```

## 和「真机」差在哪

| | 模拟（路径 A） | ESP32（路径 B） |
|--|----------------|-----------------|
| `CSI_SOURCE` | **必须** `simulated` | `esp32` |
| UDP 5005 | 可不映射 | 映射 + `RUVIEW_UDP_ALLOW` |
| `/health` 的 `source` | `simulated` | `esp32` |
| 存在/呼吸/心率 | 演示用合成值 | 需校准；非医疗设备 |
| HA 自动化 | 可联调 MQTT，但别当真 | 才有现场意义 |

## Compose

上游 `docker/docker-compose.yml` 同时起 Rust + 遗留 Python 服务。最少要导出：

```bash
export RUVIEW_API_TOKEN=$(openssl rand -hex 32)
export CSI_SOURCE=simulated   # 演示
# 真机再设 RUVIEW_UDP_ALLOW=...
cd data/upstream-ruview/docker && docker compose up
```

本仓主推仍是单容器 `docker-sim-up.sh`，减少变量。

## 作者机状态

作者 box **无 Docker** → 路径 A 容器起栈标 **未验证**；网络探针与浅克隆已验证。你本机有 Docker 时跑通后可把冒烟日志贴回 `examples/`。
