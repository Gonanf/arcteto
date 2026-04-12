# ArcTeto - Custom Arch Linux ISO with Hyprland
#
# Available commands:
#   just build       - Build the ISO only (requires archiso package)
#   just build-run   - Build and run the ISO
#   just run         - Run the built ISO in QEMU (requires qemu)
#   just test        - Run all tests
#   just clean       - Clean build artifacts
#   just help        - Show this help

# Default target (show commands)
default:
    @just --list

# Build the ISO only (without running)
build:
    #!/usr/bin/env fish
    
    echo "Building ArcTeto ISO (without running)..."
    ./build.fish --no-run

# Build ISO without custom packages
build-no-custom:
    #!/usr/bin/env fish
    
    echo "Building ArcTeto ISO without custom packages..."
    ./build.fish --no-run --no-custom

# Build and run the ISO
build-run:
    #!/usr/bin/env fish
    
    echo "Building and running ArcTeto ISO..."
    ./build.fish

# Build custom packages only
build-custom:
    #!/usr/bin/env fish
    
    echo "Building custom packages only..."
    ./build-custom-packages.fish

# Run the built ISO in QEMU
run:
    #!/usr/bin/env fish
    
    echo "Starting ArcTeto ISO in QEMU..."
    ./start_emu.fish

# Run test disk (without ISO)
test-disk:
    #!/usr/bin/env fish
    
    echo "Testing QEMU disk..."
    ./test_disk.fish

# Run all tests
test:
    #!/usr/bin/env fish
    
    echo "Running ArcTeto test suite..."
    cd tests && fish run_all_tests.fish

# Run simple tests
test-simple:
    #!/usr/bin/env fish
    
    echo "Running simple tests..."
    cd tests && fish test_simple.fish

# Test syntax
test-syntax:
    #!/usr/bin/env fish
    
    echo "Testing syntax..."
    cd tests && fish test_fish_functions_syntax.fish

# Test config syntax
test-config:
    #!/usr/bin/env fish
    
    echo "Testing config syntax..."
    cd tests && fish test_config_syntax.fish

# Test installation scripts
test-install:
    #!/usr/bin/env fish
    
    echo "Testing installation scripts..."
    cd tests && fish test_installation_script.fish

# Test build dependencies
test-deps:
    #!/usr/bin/env fish
    
    echo "Testing build dependencies..."
    cd tests && fish test_build_deps.fish

# Clean build artifacts
clean:
    #!/usr/bin/env fish
    
    echo "Cleaning build artifacts..."
    rm -rf out archiso-tmp .temp.raw custom-repo
    
    # Clean custom repo in airootfs
    if [[ -d airootfs/local/repo ]]; then
        echo "Cleaning custom repository..."
        rm -rf airootfs/local/repo/*
    fi
    
    # Clean package file if it exists (will be regenerated on build)
    if [[ -f packages.x86_64 ]]; then
        echo "Removing packages.x86_64..."
        rm packages.x86_64
    fi

# Sync configurations from user's home to project
sync-configs:
    #!/usr/bin/env fish
    
    echo "Syncing configurations from user home to project..."
    
    # Hyprland config
    if [[ -d "$HOME/.config/hypr" ]]; then
        echo "Copying Hyprland configuration..."
        rm -rf airootfs/root/.config/hypr
        cp -r "$HOME/.config/hypr" airootfs/root/.config/
    else
        echo "Warning: $HOME/.config/hypr not found"
    fi
    
    # Noctalia config
    if [[ -d "$HOME/.config/noctalia" ]]; then
        echo "Copying Noctalia configuration..."
        rm -rf airootfs/root/.config/noctalia
        cp -r "$HOME/.config/noctalia" airootfs/root/.config/
    else
        echo "Warning: $HOME/.config/noctalia not found"
    fi
    
    echo "Configuration sync complete!"

# Show dependency installation instructions
install-deps:
    #!/usr/bin/env fish
    
    echo "Dependency installation instructions for Arch Linux:"
    echo ""
    echo "1. Required for building ISO:"
    echo "   sudo pacman -S archiso"
    echo ""
    echo "2. Optional for testing/emulation:"
    echo "   sudo pacman -S qemu-full edk2-ovmf"
    echo ""
    echo "3. For Just command runner (if not installed):"
    echo "   sudo pacman -S just"
    echo ""
    echo "Note: Adjust package names for your distribution."

# Show help
help:
    @just --list
