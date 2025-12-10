#!/bin/bash
# Valgrind Build Script
# Run this script to compile Valgrind from source

set -e  # Exit on any error

echo "=== Valgrind Build Script ==="
echo "Starting build at $(date)"

# Check if we're in the right directory
if [ ! -f "valgrind-3.26.0/configure" ]; then
    echo "Error: Valgrind source not found. Expected valgrind-3.26.0/configure"
    echo "Current directory: $(pwd)"
    exit 1
fi

# Change to source directory
cd valgrind-3.26.0
echo "Building in: $(pwd)"

# Check if already configured
if [ ! -f "Makefile" ]; then
    echo "Configuring Valgrind..."
    ./configure --prefix=/usr/local/valgrind
else
    echo "Already configured, skipping configure step"
fi

# Build Valgrind
echo "Compiling Valgrind (using $(nproc) cores)..."
make -j$(nproc)

echo "=== Build Complete ==="
echo "Finished at $(date)"
echo "Next step: Run ./test.sh (optional) or ./package.sh"