#!/usr/bin/fish
# Run all ArcTeto tests

set -l test_dir (dirname (status filename))
cd "$test_dir"

set -l tests_passed 0
set -l tests_failed 0
set -l tests_skipped 0

echo "==============================="
echo "ArcTeto Comprehensive Test Suite"
echo "==============================="
echo ""

# List of test suites to run
set test_suites \
    test_simple.fish \
    test_fish_functions_syntax.fish \
    test_config_syntax.fish \
    test_installation_script.fish \
    test_build_deps.fish

# Run each test suite
for test_suite in $test_suites
    echo ""
    echo "Running $test_suite..."
    echo "------------------------"
    
    if test -f "$test_suite"
        if fish "$test_suite"
            echo "✅ $test_suite PASSED"
            set tests_passed (math $tests_passed + 1)
        else
            echo "❌ $test_suite FAILED"
            set tests_failed (math $tests_failed + 1)
        end
    else
        echo "⚠ $test_suite not found"
        set tests_skipped (math $tests_skipped + 1)
    end
end

echo ""
echo "==============================="
echo "Test Suite Summary"
echo "==============================="
echo "Tests passed: $tests_passed"
echo "Tests failed: $tests_failed"
echo "Tests skipped: $tests_skipped"
echo "Total suites: "(math $tests_passed + $tests_failed + $tests_skipped)
echo ""

if test $tests_failed -eq 0
    echo "🎉 All test suites passed!"
    exit 0
else
    echo "💥 $tests_failed test suite(s) failed!"
    exit 1
end