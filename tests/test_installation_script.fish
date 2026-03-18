#!/usr/bin/fish
# Test installation script

# Get absolute path to project root
set -l script_dir (dirname (realpath (status filename)))
set -l project_root (dirname "$script_dir")
cd "$project_root"

set -l failed 0
set -l total 0

echo "=== Testing installation script (setup.fish) ==="
echo ""

# Check file exists
set total (math $total + 1)
if test -f airootfs/root/.config/fish/functions/setup.fish
    echo "   ✓ setup.fish exists"
    
    # Check syntax
    set total (math $total + 1)
    if fish -n airootfs/root/.config/fish/functions/setup.fish 2>/dev/null
        echo "   ✓ setup.fish syntax OK"
    else
        echo "   ✗ setup.fish syntax error"
        fish -n airootfs/root/.config/fish/functions/setup.fish 2>&1 | head -3 | sed 's/^/     /'
        set failed (math $failed + 1)
    end
    
    # Check for required functions
    set total (math $total + 1)
    set -l required_funcs prepare_disk mount_partitions install_arcteto
    set -l missing_funcs
    for func in $required_funcs
        if not grep -q "function $func" airootfs/root/.config/fish/functions/setup.fish
            set missing_funcs $missing_funcs $func
        end
    end
    
    if test -z "$missing_funcs"
        echo "   ✓ setup.fish has required functions"
    else
        echo "   ✗ setup.fish missing functions: $missing_funcs"
        set failed (math $failed + 1)
    end
    
    # Check for log function usage
    set total (math $total + 1)
    if grep -q "log " airootfs/root/.config/fish/functions/setup.fish
        echo "   ✓ setup.fish uses log function"
    else
        echo "   ✗ setup.fish doesn't use log function"
        set failed (math $failed + 1)
    end
    
    # Check for dangerous commands (warn only)
    echo ""
    echo "   Checking for potential issues (warnings only):"
    if grep -q "rm -rf" airootfs/root/.config/fish/functions/setup.fish
        echo "     ⚠ Contains 'rm -rf'"
    end
    if grep -q "wipefs" airootfs/root/.config/fish/functions/setup.fish
        echo "     ⚠ Contains 'wipefs' (disk wiping)"
    end
    if grep -q "mkfs" airootfs/root/.config/fish/functions/setup.fish
        echo "     ⚠ Contains 'mkfs' (filesystem creation)"
    end
    
else
    echo "   ✗ setup.fish missing"
    set failed (math $failed + 1)
end

# Test customize_airootfs.sh
echo ""
echo "   Testing customize_airootfs.sh..."
set total (math $total + 1)
if test -f airootfs/root/customize_airootfs.sh
    # Check syntax
    if bash -n airootfs/root/customize_airootfs.sh 2>/dev/null
        echo "   ✓ customize_airootfs.sh syntax OK"
    else
        echo "   ✗ customize_airootfs.sh syntax error"
        bash -n airootfs/root/customize_airootfs.sh 2>&1 | head -3 | sed 's/^/     /'
        set failed (math $failed + 1)
    end
else
    echo "   ✗ customize_airootfs.sh missing"
    set failed (math $failed + 1)
end

echo ""
echo "=== Summary ==="
echo "Total checks: $total"
echo "Passed: "(math $total - $failed)
echo "Failed: $failed"
echo ""

if test $failed -eq 0
    echo "✅ Installation script tests passed"
    exit 0
else
    echo "❌ $failed installation script check(s) failed"
    exit 1
end