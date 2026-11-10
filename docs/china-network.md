# 国内网络说明（RuView）

RuView 主推 Docker 镜像在 **Docker Hub**（`ruvnet/wifi-densepose`），源码与固件在 **GitHub**，可选模型在 **Hugging Face**，Python 轮子在 **PyPI**。国内常见卡点如下。

## 你会碰到什么

| 依赖 | 用途 | 国内常见问题 |
|------|------|--------------|
| `github.com/ruvnet/RuView` | 源码 / CI snapshot tag / ESP32 Release 资产 | clone 慢或中断 |
| `ruvnet/wifi-densepose`（Docker Hub） | 路径 A/B/C 感知服务镜像 | pull 超时、限流、TLS 拦截 |
| `registry-1.docker.io` | 镜像层下载 | 与 Hub API 通但层拉不动 |
| `huggingface.co/ruvnet/wifi-densepose-pretrained` | 预训练权重（可选） | 直连慢；可换镜像或事先下载 |
| `pypi.org`（`ruview` / `wifi-densepose`） | Python 客户端 | 可换清华 / 阿里云等索引 |
| `docs.espressif.com` / `espressif/idf` 镜像 | 自编译固件 | ESP-IDF / Docker 构建拉基础镜像失败 |
| `cognitum.one` | 商业 Seed / 文档外链 | 可选，跟做不依赖 |

## 建议做法（择一）

1. **给 Docker / shell 配可出网代理**，保证 `docker pull ruvnet/wifi-densepose:sha-a175477` 成功。  
2. **镜像 save/load：** 在可出网机器 `docker pull` + `docker save -o wifi-densepose-sha-a175477.tar`，内网 `docker load`。优先钉 **tag `sha-a175477`**（或 `@sha256:20ee390719515014c1dd57dd4838ea4f28ef4af7852868cd5f73dc3d76408eff`），少用浮动的 `latest`。  
3. **Git：** `./scripts/clone-upstream.sh` 已用 `--depth 1 --branch <tag>`；弱网可重试或走你们的 Git 代理。  
4. **固件：** 用 `./scripts/list-esp32-firmware.sh --download` 拉 `v0.8.18-esp32` Release 资产，避免在弱网下现场编 IDF。  
5. **PyPI：** `pip install -i https://pypi.tuna.tsinghua.edu.cn/simple "ruview[client]"`（索引按单位策略替换）。  
6. **HF：** 能拉再装模型；路径 A 模拟演示**不依赖** HF。

## 探针

```bash
./scripts/probe-network.sh
./scripts/preflight.sh
```

Docker Hub `/v2/` 返回 **401** 通常表示**可达但要鉴权换票**，不要当成「挂了」。

## 与站外中文文的差异提醒

不少站外 Docker 示例仍写：

```bash
docker run -p 3000:3000 -p 5005:5005/udp -e CSI_SOURCE=esp32 ruvnet/wifi-densepose:latest
```

在当前入口脚本下这会踩坑：

1. **缺 `RUVIEW_API_TOKEN`** → 容器 **exit 64**（issue #864）。  
2. **缺 `RUVIEW_UDP_ALLOW` / `RUVIEW_UDP_INSECURE_LAN`** → 进程能起，但 **收不到 ESP32 UDP**（ADR-296）。  
3. **`CSI_SOURCE=auto` 不再静默回落模拟数据**（issue #937，exit 78）——演示请显式 `CSI_SOURCE=simulated`。  
4. 绑定只开 `127.0.0.1:3000` 时，局域网浏览器会打不开；跨机还要 `SENSING_ALLOWED_HOSTS`。

本仓路径 A 脚本把 token + `simulated` 写进默认流程，避免跟过时教程一起翻车。

## 不要做的事

- 不要把 `RUVIEW_API_TOKEN`、MQTT 密码、WiFi 密码提交进 Git。  
- 不要在不可信网络上设 `RUVIEW_UDP_INSECURE_LAN=true` 或把 `5005/udp` 映射到公网。  
- 不要把模拟 CSI / 未校准生命体征当成安防或医疗结论。
