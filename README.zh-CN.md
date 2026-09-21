# NeoXTerm

> 在主机与嵌入式 Linux / Android 目标机之间往返的一体化工作台。

**NeoXTerm** 是一个零第三方 Rust 依赖的命令行工具，并提供可选的原生桌面工作台。它把 SSH、ADB 和串口控制台统一为同一套设备档案：发现开发板、在地址变化后重新认领、打开终端、带校验地传输产物、恢复连通性，或采集硬件事实。

[English](README.md) · [文档索引](docs/README.md) · [操作指南](docs/operations.zh-CN.md) · [架构说明](docs/architecture.zh-CN.md) · [参与贡献](CONTRIBUTING.md) · [安全策略](SECURITY.md)

## 适用场景

嵌入式开发常被 SSH、ADB、串口工具、拷贝脚本和临时配网步骤切碎。NeoXTerm 以一个已保存的设备名关联当前连接路径、已观察到的身份信息和日常操作。

- **一份档案，多种通道**：SSH、ADB 和串口操作复用同一个设备名。
- **身份感知的发现**：验证端点并保存指纹，在 DHCP、刷机或 USB 口变化后重新认领设备。
- **可靠操作**：支持可续传、可校验的传输，命令执行、端口转发、借网和串口恢复。
- **硬件证据**：只读采集器可保存 `hardware.json`、可选外设摘要和设备树归档。
- **自动化与桌面端**：`nxt --json`、本地浏览器终端和 Tauri 桌面应用共用同一核心。

## 安装

需要 Rust stable（桌面端需要 Rust 1.77.2 或更新版本）和 OpenSSH；`adb`、`rsync` 为可选依赖。

```bash
git clone https://github.com/NinoC137/NeoXTerm.git
cd NeoXTerm
cargo build --release
install -m755 target/release/nxt /usr/local/bin/nxt

nxt doctor
```

命令行名称已由 `fy` 改为 `nxt`。改名前已有的设备档案和身份事实可继续兼容使用。

桌面端还需要 Node.js 与常规 Tauri 构建前置条件：

```bash
cd desktop
npm ci
npm run tauri dev       # 开发
npm run tauri build     # 发布 bundle
```

macOS 发布产物位于 `target/release/bundle/macos/NeoXTerm.app`。

## 快速开始

先创建档案，之后各项操作都复用设备名。通道仅代表当前连接路径：只有串口的设备之后也可升格为 SSH。

```bash
nxt add rk --ssh root@192.168.1.37
nxt add phone --adb
nxt add mcu --serial /dev/tty.usbserial-1420 --baud 1500000

nxt scan --add                   # 发现并保存可达设备
nxt sh rk                         # 打开 shell
nxt sh rk -- uname -a             # 执行一条远端命令
nxt info rk                       # 查看已保存的身份事实
nxt push rk ./app /tmp/           # 带校验、可续传地上传
nxt run rk ./app --help           # 上传、运行并返回远端退出码
```

## 常用任务

| 需求 | 从这里开始 |
| --- | --- |
| 发现或确认开发板 | [`nxt scan`、`nxt info`](docs/operations.zh-CN.md#发现与身份确认) |
| 终端、日志或并行命令 | [`nxt sh`、`nxt log`、`nxt all`](docs/operations.zh-CN.md#日常操作) |
| 传输、部署或调试 | [`nxt push`、`nxt run`、`nxt debug`、`nxt sync`](docs/operations.zh-CN.md#传输与部署) |
| 端口转发或借用网络 | [`nxt fwd`、`nxt share`、`nxt net`](docs/operations.zh-CN.md#连通性与网络) |
| 恢复只剩串口的设备 | [`nxt bb`、`nxt blame`、`nxt up`](docs/operations.zh-CN.md#串口恢复) |
| 采集硬件事实或安装本地扩展 | [`nxt hw`、`nxt plugin`](docs/operations.zh-CN.md#硬件采集) |
| 对接脚本或 Agent | [`nxt --json`、`nxt help --json`](docs/operations.zh-CN.md#自动化与-json) |

执行 `nxt ui` 可打开本地浏览器终端。Tauri 桌面应用提供设备总览、档案编辑、终端、受保护的操作和插件；高影响操作会先展示预检计划。

## 安全与开发

涉及设备网络、启动配置、主机路由、防火墙或服务的操作前，请先用 `nxt --dry-run` 查看计划。`nxt share --nat`、`nxt usb net --share`、USB gadget 设置和持久代理可能需要提权或改变网络状态。仅扫描你有权探测的网络；优先使用 `nxt keyup`，避免在设备档案中保存密码。

```bash
cargo test -p neoxterm --lib
cargo build --release

cd desktop && npm ci && npm run build
cd .. && cargo check -p neoxterm-desktop
```

开发约定见 [CONTRIBUTING.md](CONTRIBUTING.md)，安全问题见 [SECURITY.md](SECURITY.md)。NeoXTerm 以 [MIT License](LICENSE) 发布。
