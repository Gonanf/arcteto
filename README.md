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

## License

GPLv3
