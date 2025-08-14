#!/bin/bash
# Test script to validate dependencies and build environment

set -e

echo "=== Testing Build Dependencies ==="

# Detect target architecture
TARGET_ARCH="${TARGETARCH:-$(uname -m)}"
echo "Target architecture: $TARGET_ARCH"

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

# Test compiler versions
echo "Testing compiler versions..."
gcc --version | head -1 || echo "gcc version check failed"
clang --version | head -1 || echo "clang version check failed"
cmake --version | head -1 || echo "cmake version check failed"

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
    # Show Qt5 details if found
    cmake -S . -B build_qt5 2>&1 | grep -i "qt5" || true
else
    echo "Qt5 CMake detection: FAILED"
fi

# Test Qt6 detection via CMake with more comprehensive component testing
echo "Testing Qt6 detection..."
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.16)
project(TestQt6)
find_package(Qt6 COMPONENTS Core Widgets WebEngine WebEngineWidgets WaylandClient QUIET)
if(Qt6_FOUND)
    message(STATUS "Qt6 found: ${Qt6_VERSION}")
    message(STATUS "Qt6 Core found: ${Qt6Core_FOUND}")
    message(STATUS "Qt6 Widgets found: ${Qt6Widgets_FOUND}")
    message(STATUS "Qt6 WebEngine found: ${Qt6WebEngine_FOUND}")
    message(STATUS "Qt6 WebEngineWidgets found: ${Qt6WebEngineWidgets_FOUND}")
    message(STATUS "Qt6 WaylandClient found: ${Qt6WaylandClient_FOUND}")
else()
    message(STATUS "Qt6 not found")
endif()
EOF

if cmake -S . -B build_qt6 >/dev/null 2>&1; then
    echo "Qt6 CMake detection: SUCCESS"
    # Show Qt6 details if found
    cmake -S . -B build_qt6 2>&1 | grep -i "qt6" || true
else
    echo "Qt6 CMake detection: FAILED"
fi

# Test OpenGL libraries
echo "Testing OpenGL libraries..."
ldconfig -p | grep -i opengl || echo "OpenGL libraries not found in ldconfig"

# Architecture-specific library testing
if [ "$TARGET_ARCH" = "x86" ] || [ "$TARGET_ARCH" = "i386" ] || [ "$TARGET_ARCH" = "i686" ]; then
    echo "Testing 32-bit libraries..."
    LIB_PATH="/usr/lib/i386-linux-gnu"
    test -f "$LIB_PATH/libcurl.so" && echo "libcurl (32-bit): OK" || echo "libcurl (32-bit): NOT FOUND"
    test -f "$LIB_PATH/libssl.so" && echo "libssl (32-bit): OK" || echo "libssl (32-bit): NOT FOUND"  
    test -f "$LIB_PATH/libz.so" && echo "libz (32-bit): OK" || echo "libz (32-bit): NOT FOUND"
    test -f "$LIB_PATH/libGL.so" && echo "libGL (32-bit): OK" || echo "libGL (32-bit): NOT FOUND"
    
    # Test 32-bit compilation
    echo "Testing 32-bit compilation..."
    if gcc -m32 -E - </dev/null >/dev/null 2>&1; then
        echo "32-bit compilation: OK"
    else
        echo "32-bit compilation: FAILED"
    fi
    
    # Test pkg-config paths for 32-bit
    echo "Testing pkg-config paths for 32-bit..."
    export PKG_CONFIG_PATH="/usr/lib/i386-linux-gnu/pkgconfig:$PKG_CONFIG_PATH"
    if pkg-config --exists openssl 2>/dev/null; then
        echo "OpenSSL pkg-config (32-bit): OK"
    else
        echo "OpenSSL pkg-config (32-bit): NOT FOUND"
    fi
else
    echo "Testing 64-bit libraries..."
    LIB_PATH="/usr/lib/x86_64-linux-gnu"
    test -f "$LIB_PATH/libcurl.so" && echo "libcurl (64-bit): OK" || echo "libcurl (64-bit): NOT FOUND"
    test -f "$LIB_PATH/libssl.so" && echo "libssl (64-bit): OK" || echo "libssl (64-bit): NOT FOUND"  
    test -f "$LIB_PATH/libz.so" && echo "libz (64-bit): OK" || echo "libz (64-bit): NOT FOUND"
    test -f "$LIB_PATH/libGL.so" && echo "libGL (64-bit): OK" || echo "libGL (64-bit): NOT FOUND"
    
    # Test multilib support
    echo "Testing multilib support..."
    if gcc -m32 -E - </dev/null >/dev/null 2>&1; then
        echo "32-bit multilib compilation: OK"
        
        # Test 32-bit libraries for multilib
        LIB_PATH_32="/usr/lib/i386-linux-gnu"
        test -f "$LIB_PATH_32/libssl.so" && echo "libssl (32-bit multilib): OK" || echo "libssl (32-bit multilib): NOT FOUND"  
        test -f "$LIB_PATH_32/libz.so" && echo "libz (32-bit multilib): OK" || echo "libz (32-bit multilib): NOT FOUND"
    else
        echo "32-bit multilib compilation: FAILED"
    fi
fi

# Test environment variables
echo "Testing environment variables..."
echo "CC: ${CC:-not set}"
echo "CXX: ${CXX:-not set}"
echo "PKG_CONFIG_PATH: ${PKG_CONFIG_PATH:-not set}"
echo "CMAKE_PREFIX_PATH: ${CMAKE_PREFIX_PATH:-not set}"
echo "CMAKE_LIBRARY_PATH: ${CMAKE_LIBRARY_PATH:-not set}"

# Test CMake capabilities
echo "Testing CMake with current environment..."
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.16)
project(TestEnvironment)
message(STATUS "CMAKE_SYSTEM_PROCESSOR: ${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "CMAKE_C_COMPILER: ${CMAKE_C_COMPILER}")
message(STATUS "CMAKE_CXX_COMPILER: ${CMAKE_CXX_COMPILER}")
message(STATUS "CMAKE_PREFIX_PATH: ${CMAKE_PREFIX_PATH}")
message(STATUS "CMAKE_LIBRARY_PATH: ${CMAKE_LIBRARY_PATH}")
EOF

cmake -S . -B build_env 2>&1 | grep -E "(CMAKE_|found|Found)" || true

# Check for common issues
echo "Checking for common build issues..."

# Check for conflicting packages
if dpkg -l | grep -q "libssl.*dev.*i386" && dpkg -l | grep -q "libssl.*dev" | grep -v "i386"; then
    echo "WARNING: Potential SSL dev package conflict detected"
fi

# Check for Qt6 Wayland plugins (important for native Wayland support)
echo "Testing Qt6 Wayland plugin availability..."
QT6_PLUGINS_PATH="/usr/lib/x86_64-linux-gnu/qt6/plugins"
if [ -d "$QT6_PLUGINS_PATH" ]; then
    echo "Qt6 plugins directory: OK"
    
    # Check platform plugins
    if [ -f "$QT6_PLUGINS_PATH/platforms/libqwayland-egl.so" ] && \
       [ -f "$QT6_PLUGINS_PATH/platforms/libqwayland-generic.so" ]; then
        echo "Qt6 Wayland platform plugins: OK"
    else
        echo "Qt6 Wayland platform plugins: NOT FOUND"
        echo "  Install with: sudo apt-get install qt6-wayland qt6-wayland-dev"
    fi
    
    # Check Wayland-specific plugin directories
    for plugin_dir in wayland-decoration-client wayland-graphics-integration-client wayland-shell-integration; do
        if [ -d "$QT6_PLUGINS_PATH/$plugin_dir" ]; then
            echo "Qt6 $plugin_dir plugins: OK"
        else
            echo "Qt6 $plugin_dir plugins: NOT FOUND"
        fi
    done
else
    echo "Qt6 plugins directory: NOT FOUND"
    echo "  Qt6 development packages may not be installed."
    echo "  Run: sudo ./install-qt6-dependencies.sh"
fi

# Check disk space
DISK_SPACE=$(df /tmp | tail -1 | awk '{print $4}')
if [ "$DISK_SPACE" -lt 1048576 ]; then # Less than 1GB
    echo "WARNING: Low disk space in /tmp: ${DISK_SPACE}KB available"
fi

# Check available memory
MEM_AVAILABLE=$(free | grep "Mem:" | awk '{print $7}')
if [ "$MEM_AVAILABLE" -lt 1048576 ]; then # Less than 1GB
    echo "WARNING: Low available memory: ${MEM_AVAILABLE}KB available"
fi

# Cleanup
cd /
rm -rf "$TEST_DIR"

echo "=== Dependency Test Complete ==="