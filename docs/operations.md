# Operations guide

This guide groups NeoXTerm commands by the job they perform. Use `nxt --help` for the exact syntax in your installed version, and use `nxt --dry-run` before an operation that can alter host or target state.

## Discover and identify

```bash
nxt scan
nxt scan --subnet 192.0.2.0/24
nxt scan --ports 2222,2200
nxt scan --no-mdns
nxt scan --add

nxt info rk
nxt forget rk
```

`nxt scan` combines mDNS, a bounded concurrent TCP scan, SSH banner verification, ARP MAC lookup, ADB enumeration, and serial-port enumeration. Network candidates are deliberately conservative: a host must present a valid SSH protocol banner, or be an already-authorised network ADB endpoint, before it is offered as a profile.

NeoXTerm saves observed facts and can use them to recognise a known target after DHCP or reflash changes its address. Use `nxt forget <device>` when the board was reflashed and the saved SSH host key should be removed. Do not scan networks you are not authorised to probe.

## Operate targets

```bash
nxt sh rk
nxt sh rk -- 'systemctl status my-service'
nxt log rk
nxt log phone
nxt top
nxt all -- uname -a
nxt all rk cam -- 'df -h /'
```

`nxt sh` opens an interactive session or runs one command. `nxt log` selects `journalctl`, syslog, `dmesg`, or `logcat` for the selected transport. `nxt top` samples compatible target health information in parallel, while `nxt all` executes a command against matching profiles.

Set up key-based SSH as soon as practical:

```bash
nxt keyup rk
```

`nxt keyup` can generate and install a public key while respecting the selected profile's compatibility settings. It is preferable to saving a password in a local profile.

## Transfer and deploy

```bash
nxt push rk ./rootfs.img /tmp/
nxt push --all ./app /opt/app --only rk
nxt pull rk /var/log/messages ./logs/

nxt cp ./firmware.bin rk:/tmp/
nxt cp rk:/var/log/messages ./logs/
nxt cp rk:/tmp/fw.bin cam:/data/local/tmp/

nxt run rk ./app --verbose
nxt debug rk ./app --port 3333
nxt sync rk ./build /opt/app --exec 'systemctl restart app'
```

`push` and `pull` validate an existing prefix before resuming, check available remote space where possible, and verify SHA-256 when the target has a compatible hash utility. `cp` supports local-to-device, device-to-local, and device-to-device transfers; board-to-board data passes through the host but is not written as an intermediate host file.

Useful transfer controls:

| Flag | Meaning |
| --- | --- |
| `--force` | retransmit even when the target looks identical |
| `--no-resume` | disable resumable transfer |
| `--no-verify` | disable post-transfer verification |
| `--scp` | use the legacy scp/tar path as an escape hatch; it has no NeoXTerm resume/verify semantics |

`nxt run` transfers, marks executable, runs, and returns the remote exit code. `nxt debug` starts a `gdbserver` workflow with the required forward and reports the connection command. `nxt sync` chooses an appropriate rsync/tar/ADB path and can execute a command after syncing.

## Connectivity and networking

```bash
nxt fwd rk 8080
nxt fwd rk 8080:80
nxt fwd rk R:9000:8000
nxt fwd rk D:1080
nxt fwd ls
nxt fwd rm f1

nxt watch start
nxt watch status

nxt net rk
nxt net rk --no-speed
```

For SSH profiles, NeoXTerm uses connection reuse and can replay forwards through `nxt watch` after a disconnect. Matching ADB forward/reverse rules use ADB's native forwarding commands.

```bash
# Default: reverse tunnel to a combined HTTP/SOCKS5 host proxy; no sudo.
nxt share rk
nxt share rk --upstream auto
nxt share rk --persist

# Explicitly request host NAT for a directly connected SSH target.
nxt share rk --nat
nxt share rk --off

# Host-side USB network setup and optional sharing.
nxt usb net --share
```

The default `share` mode exposes a host proxy through a reverse tunnel. `--nat` is deliberately separate because it can change host routing and firewall state. `nxt net` measures and reports latency, jitter, packet loss, MTU, routes, DNS, external connectivity, and optional real throughput.

## Serial recovery

```bash
nxt bb start mcu
nxt bb status
nxt blame mcu
nxt bb stop mcu

nxt up mcu
nxt up mcu --boot
```

The serial black box continuously records the console and recognises common kernel panic, Oops, lockup, and OOM signatures. When it is active, `nxt sh` attaches through the shared Unix socket instead of competing for the serial port.

`nxt up` is a best-effort promotion workflow: it attempts serial login, target and network inspection, USB gadget or DHCP setup where applicable, SSH reachability, and optional public-key setup. The original serial route remains the recovery path if promotion does not complete. `--boot` permits the workflow to proceed through a bootloader boundary; review its plan before use.

## USB gadget and local artifact service

```bash
nxt usb gadget --out neoxterm-gadget.sh --mode ncm
nxt usb install rk --autostart

nxt serve ./out --for rk
nxt serve ./out --upload ./inbox
```

`ncm` is the recommended USB gadget mode for macOS and Linux; use `rndis` only for a compatibility requirement. `nxt usb install` can place the generated gadget configuration on a target and register it for boot-time use, so it is a target-changing operation. `nxt serve` provides a local artifact service for minimal/recovery targets using `wget` or `curl`; `--upload` enables reverse file collection.

## Hardware inventory

```bash
nxt hw rk --out ./rk-hardware
nxt hw rk --out ./rk-hardware --max-dt-nodes 1024
nxt hw rk --out ./rk-hardware --no-bundle

nxt hw brief ./rk-hardware/hardware.json
nxt hw brief ./rk-hardware/hardware.json --out ./peripherals.md
```

`nxt hw` is designed as a read-only collection: it reads procfs, sysfs, and the live device tree; it does not load modules, scan I2C/SPI buses, write sysfs, or change target security policy. A report contains `hardware.json`, an optional human-readable `peripherals.md`, and, when supported by target `tar`, `device-tree.tar`.

On Android, NeoXTerm selects an appropriate writable deployment directory rather than assuming `/tmp` is available. Hardware identifiers are redacted by default; only opt in to collecting identifying data when it is appropriate for the environment in which the report will be stored.

## Local plugins

Plugins are reviewable local packages for host-side workflows that do not belong in the core binary. A package contains `plugin.toml` and the executable declared by its `entry` field. The manifest declares transport requirements, host dependencies, arguments, risk, summary, and a preview. NeoXTerm rejects entrypoint path escapes and installs packages under `~/.config/neoxterm/plugins/<id>/` (or `$NEOXTERM_HOME/plugins/<id>/`).

```bash
nxt plugin ls

nxt plugin install sysroot-sync
nxt plugin show sysroot-sync
nxt plugin run sysroot-sync rk -- --dest ~/neoxterm-sysroots/rk --no-sudo

nxt plugin install device-tree-pull
nxt plugin run device-tree-pull rk -- --out ./rk-hardware

nxt plugin install /path/to/my-neoxterm-plugin
```

The bundled **Sysroot Sync** package mirrors `/lib`, `/usr/lib`, and `/usr/include` from an SSH target while preserving NeoXTerm's profile-specific SSH options. Its `--delete` option can remove local sysroot files, so it is opt-in.

The bundled **Device Tree Pull** package uses NeoXTerm's native read-only collector to recover `device-tree.tar`, `hardware.json`, and optionally `peripherals.md`. It supports SSH and authorised ADB profiles, requires a new or empty output directory, and removes its target temporary directory after recovery. Read plugin source before installing any package, including local packages supplied by others.

The desktop plugin workbench intentionally uses SSH keys only: a saved profile password is never passed into a background plugin command. A desktop `sudo` destination must have a previously authorised `sudo -v` session, or you should select a user-writable directory.

## Automation and JSON

```bash
nxt --json ls
nxt --json sh rk -- 'uname -a'
nxt --json push rk ./firmware.bin /tmp/
nxt --json net rk
nxt help --json
```

For supported commands, JSON mode guarantees one JSON document on stdout. Progress and diagnostics go to stderr; prompts are disabled; ambiguous or unsafe actions return structured failures with hints. `NEOXTERM_JSON=1` enables JSON mode for a process environment.

The command list and stable exit-code documentation are available through `nxt help --json`. Streaming commands such as `ui`, `serve`, `log`, and `top` reject JSON mode rather than mix terminal output with machine-readable data.
