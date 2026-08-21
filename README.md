# NeoXTerm

> One workbench for moving between a host and embedded Linux or Android targets.

**NeoXTerm** is a zero-dependency Rust CLI and optional native desktop workbench for lab bring-up. It gives SSH, ADB, and serial-console targets one device-profile model: discover a board, recognise it after its endpoint changes, open a shell, transfer artifacts with verification, recover connectivity, or collect hardware facts.

[中文说明](README.zh-CN.md) · [Documentation](docs/README.md) · [Operations](docs/operations.md) · [Architecture](docs/architecture.md) · [Contributing](CONTRIBUTING.md) · [Security](SECURITY.md)

## What it is for

Embedded work is often split between SSH, ADB, serial tools, copy scripts, and temporary network setup. NeoXTerm keeps the connection path, observed identity, and routine operations under one saved device name.

- **One profile across transports** — SSH, ADB, and serial operations address the same device name.
- **Identity-aware discovery** — verified endpoints and saved fingerprints help reclaim a board after DHCP, reflashing, or a USB-port change.
- **Reliable operations** — resumable and verified transfer, shell/command execution, port forwarding, connectivity sharing, and serial recovery.
- **Hardware evidence** — a read-only collector can save `hardware.json`, an optional peripheral summary, and a device-tree archive.
- **Automation and desktop UI** — `fy --json`, a local browser terminal, and an optional Tauri application use the same core.

## Install

Requires Rust stable (Rust 1.77.2+ for the desktop app) and OpenSSH. `adb` and `rsync` are optional.

```bash
git clone https://github.com/NinoC137/NeoXTerm.git
cd NeoXTerm
cargo build --release
install -m755 target/release/fy /usr/local/bin/fy

fy doctor
```

The CLI remains `fy`. Existing local profiles and facts remain compatible after the rename.

To run the desktop app (with Node.js and the normal Tauri prerequisites):

```bash
cd desktop
npm ci
npm run tauri dev       # development
npm run tauri build     # release bundle
```

The macOS bundle is written to `target/release/bundle/macos/NeoXTerm.app`.

## Quick start

Create a profile, then reuse its name for every operation. The selected transport is only the current path: a serial-only board can later be promoted to SSH.

```bash
fy add rk --ssh root@192.168.1.37
fy add phone --adb
fy add mcu --serial /dev/tty.usbserial-1420 --baud 1500000

fy scan --add                   # discover and save reachable devices
fy sh rk                         # open a shell
fy sh rk -- uname -a             # run one command
fy info rk                       # inspect saved identity facts
fy push rk ./app /tmp/           # verified, resumable upload
fy run rk ./app --help           # upload, run, return remote exit code
```

## Common tasks

| Need | Start with |
| --- | --- |
| Find or identify a board | [`fy scan`, `fy info`](docs/operations.md#discover-and-identify) |
| Shell, logs, or parallel commands | [`fy sh`, `fy log`, `fy all`](docs/operations.md#operate-targets) |
| Transfer, deploy, or debug | [`fy push`, `fy run`, `fy debug`, `fy sync`](docs/operations.md#transfer-and-deploy) |
| Forward ports or share connectivity | [`fy fwd`, `fy share`, `fy net`](docs/operations.md#connectivity-and-networking) |
| Recover a serial-only board | [`fy bb`, `fy blame`, `fy up`](docs/operations.md#serial-recovery) |
| Collect hardware facts or add a local extension | [`fy hw`, `fy plugin`](docs/operations.md#hardware-inventory) |
| Integrate with a script or agent | [`fy --json`, `fy help --json`](docs/operations.md#automation-and-json) |

Run `fy ui` for the local browser terminal. The Tauri desktop app adds fleet overview, profile editing, terminals, guarded operations, and plugins; high-impact actions show a preflight plan first.

## Safety and development

Use `fy --dry-run` before actions that can change device networking, boot configuration, host routing, firewall rules, or services. `fy share --nat`, `fy usb net --share`, USB-gadget setup, and persistent proxy settings may require elevated privileges or change network state. Scan only networks you are authorised to probe; prefer `fy keyup` over storing passwords in a device profile.

```bash
cargo test -p neoxterm --lib
cargo build --release

cd desktop && npm ci && npm run build
cd .. && cargo check -p neoxterm-desktop
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for development expectations and [SECURITY.md](SECURITY.md) for responsible disclosure. NeoXTerm is released under the [MIT License](LICENSE).
