#!/usr/bin/fish
# Test build dependencies

# Get absolute path to project root
set -l script_dir (dirname (realpath (status filename)))
set -l project_root (dirname "$script_dir")
cd "$project_root"

set -l failed 0
set -l total 0
set -l warnings 0

echo "=== Testing build dependencies ==="
echo ""

echo "1. Required commands (for scripts to run):"
set -l required_cmds fish bash mkdir rm cp cat
for cmd in $required_cmds
    set total (math $total + 1)
    if command -q "$cmd"
        echo "   ✓ $cmd"
    else
        echo "   ✗ $cmd not found"
        set failed (math $failed + 1)
    end
end

echo ""
echo "2. Build commands (needed for building ISO):"
# sudo and chown are needed for build.fish
set -l build_cmds sudo chown
for cmd in $build_cmds
    set total (math $total + 1)
    if command -q "$cmd"
        echo "   ✓ $cmd"
    else
        echo "   ⚠ $cmd not found (build may fail)"
        set warnings (math $warnings + 1)
    end
end

# mkarchiso is critical for building
set total (math $total + 1)
if command -q mkarchiso
    echo "   ✓ mkarchiso (archiso package)"
else
    echo "   ⚠ mkarchiso not found - CANNOT BUILD ISO without 'archiso' package"
    set warnings (math $warnings + 1)
end

echo ""
echo "3. Emulation commands (optional, for testing ISO):"
set total (math $total + 1)
if command -q qemu-system-x86_64
    echo "   ✓ qemu-system-x86_64"
else
    echo "   ⚠ qemu-system-x86_64 not found - cannot run emulation tests"
    set warnings (math $warnings + 1)
end

set total (math $total + 1)
if test -f /usr/share/OVMF/x64/OVMF_CODE.4m.fd
    echo "   ✓ OVMF firmware"
else
    echo "   ⚠ OVMF firmware not found - Systemd-boot will not create a UEFI entry"
    set warnings (math $warnings + 1)
end

echo ""
echo "4. Script permissions:"
set total (math $total + 1)
if test -x build.fish
    echo "   ✓ build.fish is executable"
else
    echo "   ✗ build.fish is not executable"
    set failed (math $failed + 1)
end

echo ""
echo "=== Summary ==="
echo "Total checks: $total"
echo "Passed: "(math $total - $failed - $warnings)
echo "Failed: $failed"
echo "Warnings: $warnings"
echo ""

if test $failed -eq 0
    if test $warnings -eq 0
        echo "✅ All dependencies available"
        echo "   Ready to build and test!"
        exit 0
    else
        echo "⚠ Some optional dependencies missing"
        echo "   Core functionality OK, but some features may not work"
        exit 0  # Warnings are not failures
    end
else
    echo "❌ $failed required dependency check(s) failed"
    echo "   The project may not function correctly"
    exit 1
end
