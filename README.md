# ArcTeto

Custom Arch Linux ISO with Hyprland, Noctalia Shell, and developer tools.
This was made as a checkpoint for my own distro, it contains my scripts, configs and setup, and because of that *it is not made to be easy*.

In the future it also will have [Kateto](Pending) witch will allow the distro to be (optionally) fully agentic.

## Features

- Hyprland window manager
- Noctalia Shell desktop environment
- Fish shell with custom configuration
- Developer tools (rust, python, bun, docker, etc.)
- Custom toolings and configs
- Btrfs with snapper snapshots
- AMD and Intel GPU tooling and drivers
- **FocusLock**: isolated study environment (TTY2) with agent-custodied passkey lock and filtered DNS (see below)

## Project Status

Functional (?), only for UEFI systems

## Building

This project uses [Just](https://github.com/casey/just) as a command runner. Available commands:

### Using Just (recommended):
```bash
just build           # Build ISO only (with custom packages)
just build-no-custom # Build ISO without custom packages
just build-run       # Build and run ISO in QEMU
just run             # Run already built ISO
just build-custom    # Build custom packages only
```

### Using fish scripts directly:
```bash
./build.fish                    # Build and run ISO (with custom packages)
./build.fish --no-run           # Build (The iso) only
./build.fish --no-custom        # Build (The iso) without custom packages
./start_emu.fish                # Run already built ISO
./build-custom-packages.fish    # Build AUR packages only
```

### Custom Packages
The ISO includes a small AUR repository at `/local/repo`.
This could give problems in the future (//!Noted)

These packages are automatically built during ISO creation and included in the custom repository. The repository is configured in `pacman.conf`

## Running in QEMU

### Using Just:
```bash
just run
```

### Using fish script directly:
```bash
./start_emu.fish
```

Requires QEMU with KVM acceleration and OVMF firmware.

### Variables
You can export these variables like this, and will modify the QEMU VM:
set -U {name} {value}

| Variable             | Description                                  | Default value |
|----------------------|----------------------------------------------|---------------|
| ARCTETO_ISO_PATH     | What file will be used for the VM filesystem | ./temp.raw    |
| ARCTETO_MEMORY       | Size of RAM for the VM                       | 16G           |
| ARCTETO_SIZE         | Disk spaced used by $ARCTETO_ISO_PATH        | 50G           |
| ARCTETO_EXTRA_PARAMS | Extra parameter for QEMU                     | -accel kvm    |


## Customization

- Edit `airootfs/etc/custom_packages.x86_64` to add/remove packages from the official Arch repo.
- Edit `airootfs/etc/aur_packages.x86_64` to add/remove packages from the AUR.
- Edit `airootfs/root/.config` for user configuration (Hyprland, Noctalia, Fish).
- Adjust `profiledef.sh` for ISO metadata.


- Bring your own Wallpapers!, put them on `~/Imágenes/Wallpapers/` or copy them into `./airootfs/root/Imágenes/Wallpapers`
- Bring your own Configs!, put the paths on `configs.d` or copy them into `./airootfs/root/.config/`

## Installation

The ISO includes a guided installation script (`setup.fish`) that sets up:
- Btrfs subvolumes (@, @root, @home, @snapshots)
- Snapper snapshots
- Custom config and packages
- Custom tools and shortcuts
- Systemd‑boot as bootloader
- Automatic login to Hyprland

## Testing

### Using Just:
```bash
just test          # Run all tests
just test-simple   # Run basic file checks
just test-syntax   # Test fish functions syntax
just test-config   # Test configuration files
just test-install  # Test installation scripts
just test-deps     # Test build dependencies
```

### Using fish scripts directly:
```bash
./tests/run_all_tests.fish   # Run all tests
./tests/test_simple.fish     # Basic file checks
# ... other test files in tests/ directory
```

Tests include:
- Essential file existence checks
- Script syntax validation
- Configuration file syntax (JSON, shell)
- Package list validation (duplicates)
- Installation script structure
- Build dependency verification

## Development Commands

```bash
just               # Show all available commands
just clean         # Clean build artifacts (out/, archiso-tmp/, etc.)
just sync-configs  # Sync configs from user home to project
just install-deps  # Show dependency installation instructions
just help          # Show help
```

## Attribution
The setup script is based of [Easy Arch](https://github.com/classy-giraffe/easy-arch/tree/main).

## TODO

See [TODO.md](TODO.md) for pending tasks.

## Environment system (isolated TTYs)

Arcteto can create **any isolated environment** on its own TTY: a filtered study
box, a streaming rig, a gaming sandbox, a work profile — whatever you want. Each
environment gets its own TTY (autologin), an optional separate user, optional
filtered DNS (blocks arbitrary domains), and a set of autostart apps.

### Generic creator — `arcteto-env.fish`

Visual (zenity) automated creator. Run it and answer the prompts, or pass flags:

```fish
arcteto-env                                              # interactive (zenity)
arcteto-env --name streaming --tty 3 --user stream \
    --apps "obs affine" --wallpaper ~/Pictures/stream
arcteto-env --name study --tty 2 --user study \
    --dns "youtube.com,tiktok.com,reddit.com" --apps "zen affine"
```

Flags: `--name`, `--tty`, `--user` (isolated user; omit + `--no-user` for main
user), `--dns` (comma-separated blocklist), `--apps` (space-separated),
`--wallpaper` (dir), `--no-user` (use main user, no isolation).

It generates per-environment:
- a TTY with autologin (to the isolated user or main user)
- optional separate user (UID 10xx, input/seat groups for mouse/keyboard)
- optional filtered DNS via a per-environment dnsmasq (port `5335+TTY`) + nftables
  redirect that drops DoT/QUIC
- a Hyprland config with the requested autostart apps

### FocusLock (commitment device) — built on top

FocusLock is a specific use of the environment system plus a session lock:

- **`focuslock-setup.fish`** — wrapper that calls `arcteto-env` with the study
  params (TTY2, filtered DNS, zen + affine).
- **`arcteto-work` example** — the "work" environment (starts with your cloned
  config, blocks YouTube/social/Steam, kills games) is just a call to
  `arcteto-env` with the right flags, e.g.:
  `arcteto-env --name work --tty 4 --user work --clone-from chaos
   --dns "youtube.com,reddit.com,x.com,twitter.com,tiktok.com,steamcommunity.com,steampowered.com"
   --kill "steam,lutris,wine,gamescope"
   --share "/home/chaos/Descargas:/home/work/Descargas,/home/chaos/Documentos:/home/work/Documentos,/home/chaos/proyectos:/home/work/proyectos,/home/chaos/.config:/home/work/.config,/home/chaos/.cache:/home/work/.cache"
   --apparmor-deny "steam"`
  No separate script needed — the generic engine covers it. Shared paths use
  bindfs so work writes files that chaos still owns. `--cache` minus huggingface/uv/bun
  is a manual prune you do once after first boot of the work env.
- **`focuslock-engage.fish`** — run by the agent on TTY1 to start a study block:
  generates a random passkey, writes its SHA256 to the PAM secret, locks the
  session via hyprlock (which uses PAM service `focuslock`), and shoves you to
  TTY2. The passkey is custodied by the agent, not you — that's the commitment.
- **`/etc/pam.d/focuslock`** + `/usr/local/bin/focuslock-check` — PAM stack that
  validates the agent's passkey (not your login password).
- **`/etc/dnsmasq-focuslock.conf`** + `dnsmasq-focuslock.service` — filtered DNS
  resolver on `127.0.0.1:5335`.
- **`/etc/nftables-focuslock.conf`** — redirects `study`'s DNS to the filtered
  resolver and drops DoT/QUIC.

### Usage

```fish
arcteto-env                       # create any environment (interactive)
focuslock-setup                   # study environment (one-time)
# work environment: same engine, just flags:
arcteto-env --name work --tty 4 --user work --clone-from chaos \
    --dns "youtube.com,reddit.com,x.com,twitter.com,tiktok.com,steamcommunity.com,steampowered.com" \
    --kill "steam,lutris,wine,gamescope" \
    --share "/home/chaos/Descargas:/home/work/Descargas,/home/chaos/Documentos:/home/work/Documentos,/home/chaos/proyectos:/home/work/proyectos,/home/chaos/.config:/home/work/.config,/home/chaos/.cache:/home/work/.cache" \
    --apparmor-deny "steam"
focuslock-engage                  # agent activates a study block (TTY1 -> TTY2)
focuslock-engage --tty 4          # agent activates a work block (TTY1 -> TTY4)
```

The full design, all errors encountered, and the rationale are documented in
`../Blogs/arcteto-focuslock-kateto.md` (or the Arcteto blog).

## License

GPLv3
