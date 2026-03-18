# ArcTeto

Custom Arch Linux ISO with Hyprland, Noctalia Shell, and developer tools.

## Features

- Hyprland window manager
- Noctalia Shell desktop environment
- Fish shell with custom configuration
- Developer tools (rust, python, bun, docker, etc.)
- Btrfs with snapper snapshots
- Systemd-timesyncd with NTP servers
- AMD ROCM-SMI, Vulkan drivers, Intel GPU tools
- Flameshot, hyprpicker, cliphist, and other utilities

## Building

Run the build script:

```bash
./build.fish
```

This will:
1. Copy the base packages list from Arch ISO config
2. Append custom packages from `airootfs/etc/custom_packages.x86_64`
3. Build the ISO using `mkarchiso`
4. Start the emulator with `start_emu.fish`

## Running in QEMU

To run the built ISO directly (without rebuilding):

```bash
./start_emu.fish
```

Requires QEMU with KVM acceleration and OVMF firmware.

## Customization

- Edit `airootfs/etc/custom_packages.x86_64` to add/remove packages.
- Edit `airootfs/root/.config` for user configuration (Hyprland, Noctalia, Fish).
- Modify `airootfs/root/customize_airootfs.sh` for post‑installation steps.
- Adjust `profiledef.sh` for ISO metadata.

## Installation

The ISO includes a guided installation script (`setup.fish`) that sets up:
- Btrfs subvolumes (@, @root, @home, @snapshots)
- Snapper snapshots
- Custom config and packages (Teto themed)
- Custom tools and shortcuts
- Systemd‑boot as bootloader
- Automatic login to Hyprland

## Testing

Run the test suite to validate the configuration:

```bash
./tests/run_all_tests.fish
```

Tests include:
- Essential file existence checks
- Script syntax validation
- Configuration file syntax (JSON, shell)
- Package list validation (duplicates)
- Installation script structure

## TODO

See [TODO.md](TODO.md) for pending tasks.

## License

GPLv3
