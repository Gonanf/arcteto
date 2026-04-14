#!/usr/bin/fish

set -l failed 0

echo "=== Building custom packages ==="

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

mkdir -p airootfs/local/repo

if not test -e /local/repo 
    	echo "Missing /local/repo"
	sudo mkdir -p /local/repo
end

if not test -G /local/repo
	echo "Local repo is not owned by the user, changing ownership..."
	sudo chown (whoami):(whoami) /local/repo
end

mkdir -p custom-repo/build

function build_aur_package
    set -l pkg_name $argv[1]
    set -l build_dir custom-repo/build/$pkg_name
    
    echo "Building $pkg_name from AUR..."
    
    rm -rf $build_dir
    mkdir -p $build_dir
    
    echo "  Cloning from AUR..."
    if not git clone https://aur.archlinux.org/$pkg_name.git $build_dir 2>/dev/null
        echo "  Failed to clone $pkg_name from AUR"
        return 1
    end
    
    cd $build_dir
    
    if not test -f PKGBUILD
        echo "  No PKGBUILD found for $pkg_name"
        cd -
        return 1
    end
    
    echo "  Package info:"
    makepkg --printsrcinfo | grep -E '^\s*pkgver|^\s*pkgrel|^\s*arch' | sed 's/^/    /'
    
    echo "  Checking dependencies..."
    set -l deps (makepkg --printsrcinfo | grep -E '^\s*makedepends|^\s*depends' | sed 's/.*= //' | tr '\n' ' ')
    if test -n "$deps"
        echo "  Dependencies: $deps"
        echo "  Please ensure all dependencies are installed before building"
    end
    
    echo "  Building $pkg_name (this may take a while)..."
    if not makepkg -s --noconfirm
        echo "  Failed to build $pkg_name"
        echo "  You may need to install missing dependencies:"
        echo "  sudo pacman -Sy --needed base-devel $deps"
        cd -
        return 1
    end
    
    mv *.pkg.tar.zst /local/repo/

    cd -
    echo "  Successfully built $pkg_name"
    return 0
end

# Try to build from AUR
while read -l line
	if not string length $line -q
		continue
	end

	echo ""
	echo "--- Building" $line "---"
	if not build_aur_package $line
    		echo "Failed to build" $line
    		set failed (math $failed + 1)
	end
end < airootfs/etc/aur_packages.x86_64


set -l pkg_count (ls -1 /local/repo/ 2>/dev/null | wc -l)
if test $pkg_count -gt 0
    echo ""
    echo "=== Creating custom repository ==="
    cd /local/repo
    echo "Packages in repository:"
    ls -1 *.pkg.tar.zst | sed 's/^/  /'
    
    repo-add custom.db.tar.gz *.pkg.tar.zst 2>/dev/null || true
    
    if not test -f custom.db
        ln -sf custom.db.tar.gz custom.db 2>/dev/null || true
    end
    if not test -f custom.db.sig
        ln -sf custom.db.tar.gz.sig custom.db.sig 2>/dev/null || true
    end
    
    cd -
    rm -r ./airootfs/local/repo/*
	cp /local/repo/*  ./airootfs/local/repo/
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
    rm -f /local/repo/*.pkg.tar.zst 2>/dev/null || true
    exit 0  # Don't fail the entire build, just continue without custom packages
else
    echo "All packages built successfully"
    exit 0
end
