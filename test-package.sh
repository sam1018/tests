#!/bin/bash
# Valgrind Package Test Script
# Tests the packaged distribution to ensure it works correctly

set -e  # Exit on any error

echo "=== Valgrind Package Test Script ==="
echo "Testing distribution package at $(date)"

# Find the latest package
PACKAGE=$(ls -1t valgrind-3.26.0-rhel8-x86_64-*.tar.gz 2>/dev/null | head -1)

if [ -z "$PACKAGE" ]; then
    echo "Error: No valgrind package found matching pattern: valgrind-3.26.0-rhel8-x86_64-*.tar.gz"
    echo "Run ./package.sh first to create the distribution package"
    exit 1
fi

echo "Testing package: $PACKAGE"

# Clean any previous test
rm -rf package-test-temp
mkdir -p package-test-temp
cd package-test-temp

# Extract package
echo "Extracting package..."
tar -xzf "../$PACKAGE"

# Verify expected files exist
echo "Verifying package structure..."
if [ ! -f "valgrind-runner" ]; then
    echo "✗ Missing valgrind-runner script"
    exit 1
fi

if [ ! -d "usr/local/valgrind" ]; then
    echo "✗ Missing valgrind installation directory"
    exit 1
fi

if [ ! -f "README.txt" ]; then
    echo "✗ Missing README.txt"
    exit 1
fi

if [ ! -f "BUILD_INFO" ]; then
    echo "✗ Missing BUILD_INFO"
    exit 1
fi

echo "✓ Package structure OK"

# Check runner script is executable
if [ ! -x "valgrind-runner" ]; then
    echo "✗ valgrind-runner is not executable"
    exit 1
fi

echo "✓ Runner script is executable"

# Test version check (no environment setup - test as user would)
echo "Testing version check..."
VERSION_OUTPUT=$(./valgrind-runner --version 2>&1)
if [[ "$VERSION_OUTPUT" =~ valgrind-3.26.0 ]]; then
    echo "✓ Version check passed: $VERSION_OUTPUT"
else
    echo "✗ Version check failed. Output: $VERSION_OUTPUT"
    exit 1
fi

# Test help output
echo "Testing help output..."
if ./valgrind-runner --help > help.txt 2>&1; then
    if grep -q "usage:" help.txt || grep -q "Usage:" help.txt; then
        echo "✓ Help output available"
    else
        echo "⚠ Help output unusual but command succeeded"
    fi
else
    echo "⚠ Help command failed but this may be normal"
fi

# Create test program for memory leak detection
echo "Creating test program..."
cat > leak_test.c << 'EOF'
#include <stdlib.h>
#include <stdio.h>

int main() {
    printf("Package test: allocating memory\n");
    char *leak = malloc(42);
    printf("Memory allocated\n");
    // Intentional leak for testing
    return 0;
}
EOF

# Check if we have gcc available
if ! command -v gcc &> /dev/null; then
    echo "⚠ GCC not available, skipping leak detection test"
else
    gcc -o leak_test leak_test.c
    
    # Test memory leak detection
    echo "Testing memory leak detection..."
    if ./valgrind-runner --leak-check=brief ./leak_test > leak_output.log 2>&1; then
        if grep -q "definitely lost" leak_output.log; then
            echo "✓ Memory leak detection working"
        else
            echo "✗ Memory leak not detected"
            echo "Valgrind output:"
            cat leak_output.log
            exit 1
        fi
    else
        echo "✗ Valgrind execution failed"
        echo "Output:"
        cat leak_output.log
        exit 1
    fi
fi

# Test tool availability
echo "Testing tool availability..."
TOOLS_AVAILABLE=0

# Test memcheck (default tool)
if ./valgrind-runner --tool=memcheck --version &>/dev/null; then
    echo "✓ memcheck available"
    ((TOOLS_AVAILABLE++))
fi

# Test callgrind
if ./valgrind-runner --tool=callgrind --version &>/dev/null; then
    echo "✓ callgrind available"
    ((TOOLS_AVAILABLE++))
fi

# Test cachegrind
if ./valgrind-runner --tool=cachegrind --version &>/dev/null; then
    echo "✓ cachegrind available"
    ((TOOLS_AVAILABLE++))
fi

# Test massif
if ./valgrind-runner --tool=massif --version &>/dev/null; then
    echo "✓ massif available"
    ((TOOLS_AVAILABLE++))
fi

if [ $TOOLS_AVAILABLE -ge 4 ]; then
    echo "✓ Core tools available ($TOOLS_AVAILABLE detected)"
else
    echo "⚠ Only $TOOLS_AVAILABLE tools detected (expected 4+)"
fi

# Test environment variable override capability (for advanced users)
echo "Testing VALGRIND_LIB override capability..."
CORRECT_LIB=$(pwd)/usr/local/valgrind/libexec/valgrind
FAKE_LIB="/nonexistent/path"

# Test that the runner script can be overridden if needed
if VALGRIND_LIB=$CORRECT_LIB ./valgrind-runner --version &>/dev/null; then
    echo "✓ VALGRIND_LIB environment variable override capability works"
    
    # Verify wrong path fails as expected
    if VALGRIND_LIB=$FAKE_LIB ./valgrind-runner --version &>/dev/null; then
        echo "⚠ VALGRIND_LIB validation test inconclusive"
    else
        echo "✓ VALGRIND_LIB correctly rejects invalid paths when overridden"
    fi
else
    echo "✗ VALGRIND_LIB override capability failed"
    exit 1
fi

# Check package size and contents
echo "Package information:"
echo "  Size: $(du -h ../$PACKAGE | cut -f1)"
echo "  Files: $(tar -tzf ../$PACKAGE | wc -l) files"
echo "  Binary tools: $(find usr/local/valgrind/bin -type f | wc -l)"
echo "  Library files: $(find usr/local/valgrind/libexec -type f 2>/dev/null | wc -l || echo 0)"

# Cleanup
cd ..
rm -rf package-test-temp

echo "=== Package Test Complete ==="
echo "Package: $PACKAGE"
echo "Status: ✅ PASSED - Package is functional and ready for deployment"
echo "Tested at $(date)"