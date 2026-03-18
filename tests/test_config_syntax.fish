#!/usr/bin/fish
# Test configuration file syntax

# Get absolute path to project root
set -l script_dir (dirname (realpath (status filename)))
set -l project_root (dirname "$script_dir")
cd "$project_root"

set -l failed 0
set -l total 0

echo "=== Testing configuration file syntax ==="
echo ""

# Test JSON files (if jq is available)
if command -q jq
    # Test noctalia configs
    for json in airootfs/root/.config/noctalia/*.json
        if test -f "$json"
            set total (math $total + 1)
            if jq empty "$json" 2>/dev/null
                echo "   ✓ "(basename "$json")" JSON syntax"
            else
                echo "   ✗ "(basename "$json")" JSON syntax error"
                jq empty "$json" 2>&1 | head -2 | sed 's/^/     /'
                set failed (math $failed + 1)
            end
        end
    end
else
    echo "   Note: jq not available, skipping JSON syntax checks"
end

# Test hyprland config (basic check - file exists and non-empty)
set total (math $total + 1)
if test -f airootfs/root/.config/hypr/hyprland.conf
    set -l lines (wc -l < airootfs/root/.config/hypr/hyprland.conf)
    if test $lines -gt 10
        echo "   ✓ hyprland.conf exists and has $lines lines"
    else
        echo "   ✗ hyprland.conf too short ($lines lines)"
        set failed (math $failed + 1)
    end
else
    echo "   ✗ hyprland.conf missing"
    set failed (math $failed + 1)
end

# Test snapper template
set total (math $total + 1)
if test -f airootfs/etc/snapper/config-templates/default
    set -l lines (wc -l < airootfs/etc/snapper/config-templates/default)
    if test $lines -gt 5
        echo "   ✓ snapper template exists and has $lines lines"
    else
        echo "   ✗ snapper template too short ($lines lines)"
        set failed (math $failed + 1)
    end
else
    echo "   ✗ snapper template missing"
    set failed (math $failed + 1)
end

# Test timesyncd config syntax (basic ini check)
set total (math $total + 1)
if test -f airootfs/etc/systemd/timesyncd.conf
    if grep -q "^\[Time\]" airootfs/etc/systemd/timesyncd.conf && grep -q "^NTP=" airootfs/etc/systemd/timesyncd.conf
        echo "   ✓ timesyncd.conf has [Time] section and NTP setting"
    else
        echo "   ✗ timesyncd.conf missing [Time] or NTP"
        set failed (math $failed + 1)
    end
else
    echo "   ✗ timesyncd.conf missing"
    set failed (math $failed + 1)
end

echo ""
echo "=== Summary ==="
echo "Total configs: $total"
echo "Passed: "(math $total - $failed)
echo "Failed: $failed"
echo ""

if test $failed -eq 0
    echo "✅ All configuration files syntax OK"
    exit 0
else
    echo "❌ $failed configuration file(s) have issues"
    exit 1
end