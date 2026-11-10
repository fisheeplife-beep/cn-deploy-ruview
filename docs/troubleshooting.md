# 排障（CN 配套摘要）

上游完整列表：[`docs/TROUBLESHOOTING.md`](https://github.com/ruvnet/RuView/blob/main/docs/TROUBLESHOOTING.md)。这里只收跟做高频项。

## 容器立刻退出，代码 64

**原因：** 未设置 `RUVIEW_API_TOKEN`，且未允许未认证、绑定也不是 loopback。  
**处理：** `export RUVIEW_API_TOKEN=$(openssl rand -hex 32)` 后再 `docker run -e RUVIEW_API_TOKEN ...`。

## 容器退出 78 / auto 找不到硬件

**原因：** `CSI_SOURCE=auto`（或默认）在探测不到 ESP32/WiFi 时**不再**静默变模拟（issue #937）。  
**处理：** 演示用 `CSI_SOURCE=simulated`；真机用 `esp32` 并配 UDP。

## UI 有动画但 `/api/v1/nodes` 为空（真机）

检查顺序：

1. 节点是否同网段、固定信道、串口是否有 CSI cb 日志；  
2. 服务器是否设置 `RUVIEW_UDP_ALLOW` 或 `RUVIEW_UDP_INSECURE_LAN`；  
3. macOS Docker 是否误用了 LAN CIDR（应允许 **bridge gateway/32**）；  
4. Windows Docker 多节点 UDP 是否被折叠（需 udp-relay）；  
5. 烧录后「已关联 WiFi 但无 UDP」→ 断电重插 / DTR 复位。

## API 401

带上：`-H "Authorization: Bearer $RUVIEW_API_TOKEN"`。

## 跨机器打开 UI 返回 421

设置 `SENSING_ALLOWED_HOSTS` 为浏览器访问用的主机名/IP，并把端口发布到非 loopback（注意暴露面）。

## HA 无设备

1. Mosquitto / MQTT 集成是否在线；  
2. `--mqtt-host` 是否是 **容器视角**可达地址（bridge 网络里 `localhost` 不是 HA）；  
3. 是否已有 CSI 帧（模拟也可测发现，但请标明）；  
4. 清理历史错误 `mqtt_client_id` 残留设备（空 retain config 或 HA 里删设备）。

## 国内 pull 失败

见 [`china-network.md`](./china-network.md)：代理或 `docker save/load` 钉版镜像。

## 生命体征乱跳 / 不准

多节点 last-write 类问题上游已做 best-node；仍需校准与单人场景。当作实验信号，不当监护仪。
