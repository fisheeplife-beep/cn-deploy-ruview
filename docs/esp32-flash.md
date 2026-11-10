# 路径 B｜ESP32 CSI 真机（清单）

完整存在感知 / 生命体征依赖 **CSI**。消费级笔记本 WiFi 通常只有 RSSI，不够。

## 硬件选型（先看这个）

| 板子 | 建议 | 说明 |
|------|------|------|
| **ESP32-S3** | ✅ 主推 | 生产路径；8MB 带屏 / 4MB 无头包都有 |
| **ESP32-C6** | ✅ 研究 | Wi-Fi 6 / 802.15.4；见上游 ADR-110 |
| **ESP32-C5** | ⚠️ 实验 | 启动与传输有限验证；**bootloader 地址 0x2000** |
| **ESP32-C3** | ❌ | **无 CSI**，不要买来踩坑 |

路由器：2.4 GHz、**固定信道**（常与节点 `--channel` 一致，例如 6）、关 AP 隔离、ESP32 与跑 Docker 的主机同一二层网络。

## 钉版固件

优先用 GitHub Release 预编译包，而不是一上来 menuconfig：

```bash
./scripts/list-esp32-firmware.sh
./scripts/list-esp32-firmware.sh --download   # → data/firmware/（gitignore）
```

钉：**`v0.8.18-esp32`**（prerelease；含 S3 8MB/4MB、C6、C5 包 + `SHA256SUMS.txt`）。  
上游声明：CI 验证的是软件行为，**不等于**板级传感精度合格。

校验校验和后再烧录。详细地址表以包内说明 + [`firmware/esp32-csi-node/README.md`](https://github.com/ruvnet/RuView/blob/main/firmware/esp32-csi-node/README.md) 为准。

## 烧录（概念步骤）

1. 安装 `esptool`（C5 建议 ≥5.3；上游实测文档写过 5.6.0）与 `esp-idf-nvs-partition-gen`（`provision.py` 需要）。  
2. 认准 **UART 口**（很多 S3 DevKit 左侧 USB-C 才是串口桥）。  
3. 按对应 flash 布局 `write_flash`（S3/C6 与 C5 地址不同）。  
4. 用 `provision.py` 写 NVS：**SSID / 密码文件 / target-ip / target-port(5005) / node-id / channel**。密码优先 `--password-file`，避免进 shell 历史。  
5. 断电重插；串口应看到连上 WiFi 与 CSI callback。若关联成功但无 UDP，先硬复位（上游排障常见）。

自编译可用 `espressif/idf:v5.4` Docker（上游称为较稳方式）或本机 IDF；弱网优先 Release 包。

## 服务器侧（Docker）

站外教程常漏的两行：

```bash
export RUVIEW_API_TOKEN=$(openssl rand -hex 32)
export RUVIEW_UDP_ALLOW=192.168.1.0/24   # 换成你的节点网段
docker run --rm -d --name ruview \
  -p 127.0.0.1:3000:3000 -p 127.0.0.1:3001:3001 -p 5005:5005/udp \
  -e RUVIEW_API_TOKEN -e CSI_SOURCE=esp32 -e RUVIEW_UDP_ALLOW \
  ruvnet/wifi-densepose:sha-a175477
```

要点：

- UDP 默认只听 loopback；有 `RUVIEW_UDP_ALLOW` 或 `RUVIEW_UDP_INSECURE_LAN=true` 时入口脚本才绑 `0.0.0.0`。  
- **macOS Docker Desktop / OrbStack**：包源地址会被改成桥网关，allowlist 应写 **gateway/32**，不是 LAN CIDR。  
- **Windows Docker Desktop**：多节点 UDP 可能被折叠成单一源 IP（上游 #374 / #386），需 host relay。  
- 本机二进制则要 `--udp-bind 0.0.0.0 --udp-allow ...`。

## 校准

生命体征需按上游 [`docs/calibration-guide.md`](https://github.com/ruvnet/RuView/blob/main/docs/calibration-guide.md) 校准；未过质量门时 HA 里心率/呼吸会保持 unavailable。  
**非医疗设备**；跌倒等语义状态有误报可能，阈值要现场调。

## 作者机状态

作者 box **无 ESP32、无串口设备、无 Docker** → 路径 B **整路未验证**。本页是跟做清单 + 与过时中文文的差异标注。
