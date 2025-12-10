#!/bin/bash
# Valgrind Package Script
# Run this script to create distribution package

set -e  # Exit on any error

echo "=== Valgrind Package Script ==="
echo "Starting packaging at $(date)"

# Check if build exists
if [ ! -f "valgrind-3.26.0/Makefile" ]; then
    echo "Error: Build not found. Run ./build.sh first"
    exit 1
fi

# Clean any previous staging
rm -rf package-staging
mkdir -p package-staging

cd valgrind-3.26.0
echo "Packaging from: $(pwd)"

# Install to staging directory
echo "Installing to staging directory..."
make DESTDIR=../package-staging install

# Go back to package root
cd ..

# Create runner script
echo "Creating valgrind-runner script..."
cat > package-staging/valgrind-runner << 'EOF'
#!/bin/bash
# Valgrind Runner Script
# Automatically sets VALGRIND_LIB and executes valgrind from any location

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set Valgrind library path
export VALGRIND_LIB="$SCRIPT_DIR/usr/local/valgrind/libexec/valgrind"

# Execute valgrind with all arguments passed to this script
exec "$SCRIPT_DIR/usr/local/valgrind/bin/valgrind" "$@"
EOF

chmod +x package-staging/valgrind-runner

# Create README
echo "Creating README..."
cat > package-staging/README.txt << 'EOF'
# Valgrind Portable Distribution

## Quick Start
1. Extract this package anywhere
2. Use ./valgrind-runner instead of valgrind

## Examples
./valgrind-runner --version
./valgrind-runner --leak-check=full ./your-program
./valgrind-runner --tool=callgrind ./your-program

## Contents
- Valgrind 3.26.0 (latest as of Dec 2024)
- All tools: memcheck, cachegrind, callgrind, helgrind, drd, massif, dhat
- Self-contained runner script (no installation required)

## System Requirements
- Linux x86_64
- glibc 2.28+ (RHEL8/CentOS8/Ubuntu 18.04+)
- No root privileges required

## License: GPL v3
EOF

# Create version info file
VALGRIND_VERSION=$(package-staging/usr/local/valgrind/bin/valgrind --version)
BUILD_DATE=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
BUILD_HOST=$(uname -a)

cat > package-staging/BUILD_INFO << EOF
Valgrind Version: $VALGRIND_VERSION
Build Date: $BUILD_DATE
Build Host: $BUILD_HOST
Target: RHEL8/AlmaLinux8 x86_64
Builder: TeamCity Build System
EOF

# Create the distribution archive
PACKAGE_NAME="valgrind-3.26.0-rhel8-x86_64-$(date +%Y%m%d)"
echo "Creating distribution package: ${PACKAGE_NAME}.tar.gz"

cd package-staging
tar -czf "../${PACKAGE_NAME}.tar.gz" .
cd ..

# Calculate package info
PACKAGE_SIZE=$(du -h "${PACKAGE_NAME}.tar.gz" | cut -f1)
UNCOMPRESSED_SIZE=$(tar -tzf "${PACKAGE_NAME}.tar.gz" | xargs -I {} stat --format="%s" package-staging/{} 2>/dev/null | awk '{sum+=$1} END {printf "%.1fMB", sum/1024/1024}' || echo "N/A")

echo "=== Package Complete ==="
echo "Package: ${PACKAGE_NAME}.tar.gz"
echo "Compressed size: $PACKAGE_SIZE"
echo "Uncompressed size: $UNCOMPRESSED_SIZE"
echo ""
echo "Package contents:"
echo "- valgrind-runner (main executable)"
echo "- usr/local/valgrind/ (installation directory)"
echo "- README.txt (usage instructions)"
echo "- BUILD_INFO (build metadata)"
echo ""
echo "Finished at $(date)"
echo "Ready for deployment to package repository"