#!/usr/bin/fish
# Build custom packages and create local repository

set -l failed 0

echo "=== Building custom packages ==="

# Check for required commands
set -l required_cmds git makepkg repo-add
set -l missing_cmds
for cmd in $required_cmds
    if not command -q $cmd
        set missing_cmds $missing_cmds $cmd
    end
end

if test -n "$missing_cmds"
    echo "Missing required commands: $missing_cmds"
    echo "Please install: sudo pacman -Sy --needed base-devel pacman-contrib git"
    echo "Skipping custom package build"
    exit 0
end

# Create directories
mkdir -p airootfs/local/repo
mkdir -p custom-repo/build

# Function to build a package from AUR
function build_aur_package
    set -l pkg_name $argv[1]
    set -l build_dir custom-repo/build/$pkg_name
    
    echo "Building $pkg_name from AUR..."
    
    # Clean previous build
    rm -rf $build_dir
    mkdir -p $build_dir
    
    # Clone from AUR
    echo "  Cloning from AUR..."
    if not git clone https://aur.archlinux.org/$pkg_name.git $build_dir 2>/dev/null
        echo "  Failed to clone $pkg_name from AUR"
        return 1
    end
    
    cd $build_dir
    
    # Check for PKGBUILD
    if not test -f PKGBUILD
        echo "  No PKGBUILD found for $pkg_name"
        cd -
        return 1
    end
    
    # Show package info
    echo "  Package info:"
    makepkg --printsrcinfo | grep -E '^\s*pkgver|^\s*pkgrel|^\s*arch' | sed 's/^/    /'
    
    # Check for dependencies
    echo "  Checking dependencies..."
    set -l deps (makepkg --printsrcinfo | grep -E '^\s*makedepends|^\s*depends' | sed 's/.*= //' | tr '\n' ' ')
    if test -n "$deps"
        echo "  Dependencies: $deps"
        echo "  Please ensure all dependencies are installed before building"
    end
    
    # Build package
    echo "  Building $pkg_name (this may take a while)..."
    if not makepkg -s --noconfirm --needed
        echo "  Failed to build $pkg_name"
        echo "  You may need to install missing dependencies:"
        echo "  sudo pacman -Sy --needed base-devel $deps"
        cd -
        return 1
    end
    
    # Move package to repo
    mv *.pkg.tar.zst ./airootfs/local/repo/
    
    cd -
    echo "  Successfully built $pkg_name"
    return 0
end

# Try to build zen-browser from AUR
echo ""
echo "--- Building zen-browser ---"
if not build_aur_package zen-browser
    echo "Failed to build zen-browser"
    set failed (math $failed + 1)
end

# Try to build noctalia-shell from AUR
echo ""
echo "--- Building noctalia-shell ---"
if not build_aur_package noctalia-shell
    echo "Failed to build noctalia-shell"
    set failed (math $failed + 1)
end

# Create repository database if we have packages
set -l pkg_count (ls -1 airootfs/local/repo/*.pkg.tar.zst 2>/dev/null | wc -l)
if test $pkg_count -gt 0
    echo ""
    echo "=== Creating custom repository ==="
    cd airootfs/local/repo
    echo "Packages in repository:"
    ls -1 *.pkg.tar.zst | sed 's/^/  /'
    
    # Create or update repository database
    repo-add custom.db.tar.gz *.pkg.tar.zst 2>/dev/null || true
    
    # Create symlink for compatibility
    if not test -f custom.db
        ln -sf custom.db.tar.gz custom.db 2>/dev/null || true
    end
    if not test -f custom.db.sig
        ln -sf custom.db.tar.gz.sig custom.db.sig 2>/dev/null || true
    end
    
    cd -
    echo "Custom repository created with $pkg_count packages"
else
    echo ""
    echo "No packages were built, skipping repository creation"
    echo "You may need to install build dependencies:"
    echo "  sudo pacman -Sy --needed base-devel git"
end

echo ""
echo "=== Custom packages build completed ==="
if test $failed -gt 0
    echo "Failed to build $failed package(s)"
    echo "The ISO will be built without custom packages"
    # Remove any partial packages
    rm -f airootfs/local/repo/*.pkg.tar.zst 2>/dev/null || true
    exit 0  # Don't fail the entire build, just continue without custom packages
else
    echo "All packages built successfully"
    exit 0
end
