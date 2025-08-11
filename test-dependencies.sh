#!/bin/bash
# Test script to validate dependencies and build environment

set -e

echo "=== Testing Build Dependencies ==="

# Test basic build tools
echo "Testing basic build tools..."
which gcc || echo "gcc not found"
which g++ || echo "g++ not found"
which clang || echo "clang not found"
which clang++ || echo "clang++ not found"
which cmake || echo "cmake not found"
which ninja || echo "ninja not found"
which make || echo "make not found"

# Test pkg-config
echo "Testing pkg-config..."
pkg-config --version || echo "pkg-config not found"

# Test Qt detection
echo "Testing Qt detection..."
if command -v qmake >/dev/null 2>&1; then
    echo "Qt5 qmake version: $(qmake --version)"
fi

if command -v qmake6 >/dev/null 2>&1; then
    echo "Qt6 qmake version: $(qmake6 --version)"
fi

# Test CMake Qt finding
echo "Testing CMake Qt module detection..."
cmake --version

# Create a temporary directory for testing
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Test Qt5 detection via CMake
echo "Testing Qt5 detection..."
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.16)
project(TestQt5)
find_package(Qt5 COMPONENTS Core Widgets QUIET)
if(Qt5_FOUND)
    message(STATUS "Qt5 found: ${Qt5_VERSION}")
    message(STATUS "Qt5 Core found: ${Qt5Core_FOUND}")
    message(STATUS "Qt5 Widgets found: ${Qt5Widgets_FOUND}")
else()
    message(STATUS "Qt5 not found")
endif()
EOF

if cmake -S . -B build_qt5 >/dev/null 2>&1; then
    echo "Qt5 CMake detection: SUCCESS"
else
    echo "Qt5 CMake detection: FAILED"
fi

# Test Qt6 detection via CMake  
echo "Testing Qt6 detection..."
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.16)
project(TestQt6)
find_package(Qt6 COMPONENTS Core Widgets QUIET)
if(Qt6_FOUND)
    message(STATUS "Qt6 found: ${Qt6_VERSION}")
    message(STATUS "Qt6 Core found: ${Qt6Core_FOUND}")
    message(STATUS "Qt6 Widgets found: ${Qt6Widgets_FOUND}")
else()
    message(STATUS "Qt6 not found")
endif()
EOF

if cmake -S . -B build_qt6 >/dev/null 2>&1; then
    echo "Qt6 CMake detection: SUCCESS"
else
    echo "Qt6 CMake detection: FAILED"
fi

# Test OpenGL libraries
echo "Testing OpenGL libraries..."
ldconfig -p | grep -i opengl || echo "OpenGL libraries not found in ldconfig"

# Test common libraries that might cause issues
echo "Testing common development libraries..."
test -f /usr/lib/x86_64-linux-gnu/libcurl.so && echo "libcurl: OK" || echo "libcurl: NOT FOUND"
test -f /usr/lib/x86_64-linux-gnu/libssl.so && echo "libssl: OK" || echo "libssl: NOT FOUND"  
test -f /usr/lib/x86_64-linux-gnu/libz.so && echo "libz: OK" || echo "libz: NOT FOUND"

# Test 32-bit support
echo "Testing 32-bit support..."
if gcc -m32 -E - </dev/null >/dev/null 2>&1; then
    echo "32-bit compilation: OK"
else
    echo "32-bit compilation: FAILED"
fi

# Cleanup
cd /
rm -rf "$TEST_DIR"

echo "=== Dependency Test Complete ==="