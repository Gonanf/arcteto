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

## Project Status

✅ **Ready for building** – All TODO items completed, comprehensive test suite passes, custom packages built, Just integration implemented.

## Building

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
./build.fish --no-run           # Build only
./build.fish --no-custom        # Build without custom packages
./start_emu.fish                # Run already built ISO
./build-custom-packages.fish    # Build custom packages only
```

The build process will:
1. Build custom packages (zen-browser, noctalia-shell) from AUR and add to local repository
2. Copy the base packages list from Arch ISO config
3. Append custom packages from `airootfs/etc/custom_packages.x86_64`
4. Build the ISO using `mkarchiso`
5. (Optional) Start the emulator with `start_emu.fish`

### Custom Packages
The ISO includes a custom package repository at `/local/repo` containing:
- **zen-browser**: Built from AUR with all dependencies
- **noctalia-shell**: Built from AUR with all dependencies

These packages are automatically built during ISO creation and included in the custom repository. The repository is configured in `pacman.conf` with signature checking disabled for local packages.

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

This project uses [Just](https://github.com/casey/just) as a command runner. Available commands:

```bash
just               # Show all available commands
just build         # Build the ISO only (with custom packages)
just build-no-custom # Build ISO without custom packages
just build-run     # Build and run the ISO
just run           # Run already built ISO in QEMU
just build-custom  # Build custom packages only
just test          # Run all tests
just test-*        # Run specific test suite (see above)
just clean         # Clean build artifacts (out/, archiso-tmp/, etc.)
just sync-configs  # Sync configs from user home to project
just install-deps  # Show dependency installation instructions
just help          # Show help
```

## TODO

See [TODO.md](TODO.md) for pending tasks.

## License

GPLv3
