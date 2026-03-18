#!/usr/bin/fish
# Test fish functions syntax

# Get absolute path to project root
set -l script_dir (dirname (realpath (status filename)))
set -l project_root (dirname "$script_dir")
cd "$project_root"

set -l failed 0
set -l total 0

echo "=== Testing fish functions syntax ==="
echo ""

# Test all fish functions
for func in airootfs/root/.config/fish/functions/*.fish
    set total (math $total + 1)
    if fish -n "$func" 2>/dev/null
        echo "   ✓ "(basename "$func")" syntax"
    else
        echo "   ✗ "(basename "$func")" syntax error"
        fish -n "$func" 2>&1 | head -3 | sed 's/^/     /'
        set failed (math $failed + 1)
    end
end

# Test config.fish
set total (math $total + 1)
if fish -n airootfs/root/.config/fish/config.fish 2>/dev/null
    echo "   ✓ config.fish syntax"
else
    echo "   ✗ config.fish syntax error"
    fish -n airootfs/root/.config/fish/config.fish 2>&1 | head -3 | sed 's/^/     /'
    set failed (math $failed + 1)
end

echo ""
echo "=== Summary ==="
echo "Total functions: $total"
echo "Passed: "(math $total - $failed)
echo "Failed: $failed"
echo ""

if test $failed -eq 0
    echo "✅ All fish functions syntax OK"
    exit 0
else
    echo "❌ $failed fish function(s) have syntax errors"
    exit 1
end