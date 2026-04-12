#!/usr/bin/fish

set -l no_run false
set -l no_custom false
set -l arg_idx 1

while test $arg_idx -le (count $argv)
    switch $argv[$arg_idx]
        case --no-run
            set no_run true
        case --no-custom
            set no_custom true
        case '*'
            echo "Unknown option: $argv[$arg_idx]"
            echo "Usage: $argv[0] [--no-run] [--no-custom]"
            exit 1
    end
    set arg_idx (math $arg_idx + 1)
end

# Build custom packages if not disabled
if not $no_custom
    echo "=== Building custom packages ==="
    if not ./build-custom-packages.fish
        echo "Warning: Custom package build failed, continuing anyway..."
    end
end

# Copy wallpapers to project ./wallpapers directory
echo "=== Copying wallpapers to project directory ==="
mkdir -p ./wallpapers
cp -r ~/Imágenes/Wallpapers/* ./wallpapers/ 2>/dev/null

rm packages.x86_64
cp /usr/share/archiso/configs/releng/packages.x86_64 .
cat ./airootfs/etc/custom_packages.x86_64 >>packages.x86_64
su -c "
rm -rf out
mkarchiso -w ./archiso-tmp -r -v .
rm -rf ./archiso-tmp
sudo chown $(whoami) -R out
exit
"

# Only run emulator if --no-run flag is not set
if not $no_run
    ./start_emu.fish
end
