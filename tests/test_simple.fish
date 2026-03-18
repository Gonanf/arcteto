#!/usr/bin/fish
# Simple test suite for ArcTeto

# Get absolute path to project root
set -l script_dir (dirname (realpath (status filename)))
set -l project_root (dirname "$script_dir")
cd "$project_root"

set -l failed 0
set -l total 0

echo "=== Simple ArcTeto Test Suite ==="
echo ""

# 1. Check essential files exist
echo "1. Checking essential files..."
for file in profiledef.sh pacman.conf packages.x86_64 build.fish start_emu.fish
    set total (math $total + 1)
    if test -f "$file"
        echo "   ✓ $file"
    else
        echo "   ✗ $file (missing)"
        set failed (math $failed + 1)
    end
end

# 2. Check airootfs directories
echo ""
echo "2. Checking airootfs structure..."
for dir in airootfs/etc airootfs/root airootfs/root/.config/fish airootfs/root/.config/hypr airootfs/root/.config/noctalia
    set total (math $total + 1)
    if test -d "$dir"
        echo "   ✓ $dir"
    else
        echo "   ✗ $dir (missing)"
        set failed (math $failed + 1)
    end
end

# 3. Check key config files
echo ""
echo "3. Checking configuration files..."
for file in airootfs/etc/custom_packages.x86_64 \
            airootfs/root/customize_airootfs.sh \
            airootfs/etc/systemd/timesyncd.conf \
            airootfs/root/.config/fish/config.fish \
            airootfs/root/.config/hypr/hyprland.conf
    set total (math $total + 1)
    if test -f "$file"
        echo "   ✓ $file"
    else
        echo "   ✗ $file (missing)"
        set failed (math $failed + 1)
    end
end

# 4. Check script syntax
echo ""
echo "4. Checking script syntax..."
for script in build.fish start_emu.fish
    set total (math $total + 1)
    if fish -n "$script" 2>/dev/null
        echo "   ✓ $script syntax"
    else
        echo "   ✗ $script syntax error"
        fish -n "$script" 2>&1 | head -2
        set failed (math $failed + 1)
    end
end

# 5. Check bash script syntax
set total (math $total + 1)
if bash -n profiledef.sh 2>/dev/null
    echo "   ✓ profiledef.sh syntax"
else
    echo "   ✗ profiledef.sh syntax error"
    set failed (math $failed + 1)
end

# 6. Check packages list for duplicates
echo ""
echo "5. Checking package lists..."
# Skip duplicate check for base packages.x86_64 (it's from upstream)
echo "   Note: Skipping duplicate check for base packages.x86_64 (upstream file)"

if test -f airootfs/etc/custom_packages.x86_64
    set total (math $total + 1)
    set -l dups (grep '^[^#[:space:]]' airootfs/etc/custom_packages.x86_64 | sort | uniq -d)
    if test -z "$dups"
        echo "   ✓ custom_packages.x86_64 no duplicates"
    else
        echo "   ✗ custom_packages.x86_64 has duplicates"
        echo "$dups" | sed 's/^/     /'
        set failed (math $failed + 1)
    end
end

# 7. Check build script logic
echo ""
echo "6. Checking build script logic..."
set total (math $total + 1)
if grep -q "cat ./airootfs/etc/custom_packages.x86_64 >>packages.x86_64" build.fish
    echo "   ✓ build.fish appends custom packages"
else
    echo "   ✗ build.fish doesn't append custom packages"
    set failed (math $failed + 1)
end

set total (math $total + 1)
if grep -q "mkarchiso" build.fish
    echo "   ✓ build.fish calls mkarchiso"
else
    echo "   ✗ build.fish doesn't call mkarchiso"
    set failed (math $failed + 1)
end

# Summary
echo ""
echo "=== Summary ==="
echo "Total checks: $total"
echo "Passed: "(math $total - $failed)
echo "Failed: $failed"
echo ""

if test $failed -eq 0
    echo "✅ All checks passed!"
    exit 0
else
    echo "❌ $failed check(s) failed"
    exit 1
end