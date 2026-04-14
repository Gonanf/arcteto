default:
    @just --list

build:
    #!/usr/bin/env fish
    
    echo "Building ArcTeto ISO (without running)..."
    ./build.fish --no-run

build-no-custom:
    #!/usr/bin/env fish
    
    echo "Building ArcTeto ISO without custom packages..."
    ./build.fish --no-run --no-custom

build-run:
    #!/usr/bin/env fish
    
    echo "Building and running ArcTeto ISO..."
    ./build.fish

build-custom:
    #!/usr/bin/env fish
    
    echo "Building custom packages only..."
    ./build-custom-packages.fish

run:
    #!/usr/bin/env fish
    
    echo "Starting ArcTeto ISO in QEMU..."
    ./start_emu.fish

test-disk:
    #!/usr/bin/env fish
    
    echo "Testing QEMU disk..."
    ./test_disk.fish

test:
    #!/usr/bin/env fish
    
    echo "Running ArcTeto test suite..."
    cd tests && fish run_all_tests.fish

test-simple:
    #!/usr/bin/env fish
    
    echo "Running simple tests..."
    cd tests && fish test_simple.fish

test-syntax:
    #!/usr/bin/env fish
    
    echo "Testing syntax..."
    cd tests && fish test_fish_functions_syntax.fish

test-config:
    #!/usr/bin/env fish
    
    echo "Testing config syntax..."
    cd tests && fish test_config_syntax.fish

test-install:
    #!/usr/bin/env fish
    
    echo "Testing installation scripts..."
    cd tests && fish test_installation_script.fish

test-deps:
    #!/usr/bin/env fish
    
    echo "Testing build dependencies..."
    cd tests && fish test_build_deps.fish

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

sync-configs:
	#!/usr/bin/env fish
    
	echo "Syncing configurations from user home to project..."
	set failed 0

	while read -l line
		set target airootfs/root/(string replace -r "^~/" "" -- $line)
		set line (string replace -r '^~' $HOME -- $line)
		if not string length $line -q
			continue
		end

		echo ""
		echo "--- Copying" $line "into" $target "---"

		rm -rf $target
		if not cp -r (realpath $line) $target
			echo "Failed to copy" $line "into" $target
			set failed (math $failed + 1)
		end
	end < configs.d
       
	if test $failed -gt 0
		echo "Configuration sync completed with errors (" $failed ")" 
	else 
		echo "Configuration sync complete!" 
	end

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

help:
    @just --list
