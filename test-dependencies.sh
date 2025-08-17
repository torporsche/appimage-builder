#!/bin/bash
# Test script to validate dependencies and build environment with strict checking
# Fails early on missing critical dependencies

set -e

echo "=== Testing Build Dependencies with Strict Validation ==="

# Detect target architecture
TARGET_ARCH="${TARGETARCH:-$(uname -m)}"
echo "Target architecture: $TARGET_ARCH"

# Test basic build tools with fail-fast behavior
echo "Testing basic build tools..."
MISSING_TOOLS=()
REQUIRED_TOOLS=("gcc" "g++" "cmake" "ninja" "make" "git" "pkg-config")

for tool in "${REQUIRED_TOOLS[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "✅ $tool: $(command -v $tool)"
    else
        echo "❌ $tool: NOT FOUND"
        MISSING_TOOLS+=("$tool")
    fi
done

# Check for at least one C++ compiler
if ! command -v clang++ >/dev/null 2>&1 && ! command -v g++ >/dev/null 2>&1; then
    echo "❌ No C++ compiler found (clang++ or g++ required)"
    MISSING_TOOLS+=("clang++ or g++")
fi

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo ""
    echo "ERROR: Missing required build tools: ${MISSING_TOOLS[*]}"
    echo "Install with: sudo apt-get install build-essential cmake ninja-build git pkg-config"
    exit 1
fi

# Test pkg-config with validation
echo ""
echo "Testing pkg-config..."
if command -v pkg-config >/dev/null 2>&1; then
    PKG_CONFIG_VERSION=$(pkg-config --version)
    echo "✅ pkg-config: $PKG_CONFIG_VERSION"
    
    # Test essential pkg-config packages
    ESSENTIAL_PACKAGES=("openssl" "zlib")
    for package in "${ESSENTIAL_PACKAGES[@]}"; do
        if pkg-config --exists "$package" 2>/dev/null; then
            echo "✅ pkg-config package: $package"
        else
            echo "❌ pkg-config package: $package (missing development package)"
        fi
    done
else
    echo "❌ pkg-config: NOT FOUND"
    exit 1
fi

# Test compiler versions with stricter validation
echo ""
echo "Testing compiler versions..."
if command -v gcc >/dev/null 2>&1; then
    GCC_VERSION=$(gcc --version | head -1)
    echo "✅ GCC: $GCC_VERSION"
    
    # Check GCC version is reasonable (7.0+)
    GCC_MAJOR=$(gcc -dumpversion | cut -d. -f1)
    if [ "$GCC_MAJOR" -lt 7 ]; then
        echo "⚠️  WARNING: GCC version may be too old for modern C++17 features"
    fi
else
    echo "❌ GCC: NOT FOUND"
fi

if command -v clang >/dev/null 2>&1; then
    CLANG_VERSION=$(clang --version | head -1)
    echo "✅ Clang: $CLANG_VERSION"
else
    echo "⚠️  Clang: NOT FOUND (recommended for Qt6 builds)"
fi

if command -v cmake >/dev/null 2>&1; then
    CMAKE_VERSION=$(cmake --version | head -1)
    echo "✅ CMake: $CMAKE_VERSION"
    
    # Check CMake version is adequate (3.16+)
    CMAKE_VERSION_NUM=$(cmake --version | head -1 | grep -o '[0-9]\+\.[0-9]\+' | head -1)
    CMAKE_MAJOR=$(echo "$CMAKE_VERSION_NUM" | cut -d. -f1)
    CMAKE_MINOR=$(echo "$CMAKE_VERSION_NUM" | cut -d. -f2)
    if [ "$CMAKE_MAJOR" -lt 3 ] || ([ "$CMAKE_MAJOR" -eq 3 ] && [ "$CMAKE_MINOR" -lt 16 ]); then
        echo "❌ ERROR: CMake version too old. Qt6 requires CMake 3.16+"
        exit 1
    fi
else
    echo "❌ CMake: NOT FOUND"
    exit 1
fi

# Test Qt detection with strict validation
echo ""
echo "Testing Qt detection with strict requirements..."
QT5_FOUND=false
QT6_FOUND=false

if command -v qmake >/dev/null 2>&1; then
    QT5_VERSION=$(qmake --version | grep "Qt version" | head -1)
    echo "✅ Qt5 qmake: $QT5_VERSION"
    QT5_FOUND=true
else
    echo "⚠️  Qt5 qmake: NOT FOUND"
fi

if command -v qmake6 >/dev/null 2>&1; then
    QT6_VERSION=$(qmake6 --version | grep "Qt version" | head -1)
    echo "✅ Qt6 qmake: $QT6_VERSION"
    QT6_FOUND=true
else
    echo "❌ Qt6 qmake: NOT FOUND"
fi

# Require at least Qt6 for modern builds
if [ "$QT6_FOUND" = "false" ]; then
    echo ""
    echo "ERROR: Qt6 is required for modern AppImage builds"
    echo "Install with: sudo apt-get install qt6-base-dev qt6-tools-dev qmake6"
    echo "Or run: ./install-qt6-deps.sh"
    exit 1
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

# Test Qt6 detection via CMake with comprehensive component validation
echo ""
echo "Testing Qt6 detection and component validation..."
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.16)
project(TestQt6)

# Test essential Qt6 components
find_package(Qt6 COMPONENTS Core Widgets Gui REQUIRED)
message(STATUS "✅ Qt6 Essential: Core=${Qt6Core_FOUND}, Widgets=${Qt6Widgets_FOUND}, Gui=${Qt6Gui_FOUND}")

# Test optional but important components
find_package(Qt6 COMPONENTS OpenGL QUIET)
if(Qt6OpenGL_FOUND)
    message(STATUS "✅ Qt6 OpenGL: Available")
else()
    message(STATUS "⚠️  Qt6 OpenGL: Missing (install libqt6opengl6-dev)")
endif()

find_package(Qt6 COMPONENTS WebEngine WebEngineWidgets QUIET)
if(Qt6WebEngine_FOUND AND Qt6WebEngineWidgets_FOUND)
    message(STATUS "✅ Qt6 WebEngine: Available")
else()
    message(STATUS "⚠️  Qt6 WebEngine: Missing (install qt6-webengine-dev)")
endif()

find_package(Qt6 COMPONENTS WaylandClient QUIET)
if(Qt6WaylandClient_FOUND)
    message(STATUS "✅ Qt6 Wayland: Available")
else()
    message(STATUS "⚠️  Qt6 Wayland: Missing (install qt6-wayland-dev)")
endif()

message(STATUS "Qt6 Version: ${Qt6_VERSION}")
message(STATUS "Qt6 Installation: ${Qt6_DIR}")
EOF

QT6_CMAKE_SUCCESS=false
if cmake -S . -B build_qt6 >/dev/null 2>&1; then
    echo "✅ Qt6 CMake detection: SUCCESS"
    QT6_CMAKE_SUCCESS=true
    # Show detailed Qt6 component status
    cmake -S . -B build_qt6 2>&1 | grep -E "(Qt6|✅|⚠️)" || true
else
    echo "❌ Qt6 CMake detection: FAILED"
    echo "   This indicates Qt6 development packages are not properly installed"
fi

if [ "$QT6_CMAKE_SUCCESS" = "false" ]; then
    echo ""
    echo "ERROR: Qt6 CMake configuration failed"
    echo "Install Qt6 development packages with:"
    echo "  sudo apt-get install qt6-base-dev qt6-tools-dev"
    echo "Or run: ./install-qt6-deps.sh"
    exit 1
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

# Qt6-specific validation for AppImage builds
echo ""
echo "=== Qt6 Validation for AppImage Builds ==="

# Check for Qt6 Wayland development packages
echo "Testing Qt6 Wayland development packages..."
qt6_wayland_libs=(
    "/usr/lib/x86_64-linux-gnu/libQt6WaylandClient.so"
    "/usr/lib/x86_64-linux-gnu/qt6/plugins/wayland-decoration-client"
    "/usr/lib/x86_64-linux-gnu/qt6/plugins/wayland-graphics-integration-client"
    "/usr/lib/x86_64-linux-gnu/qt6/plugins/wayland-shell-integration"
)

for lib in "${qt6_wayland_libs[@]}"; do
    if [ -e "$lib" ]; then
        echo "✅ Qt6 Wayland component: $lib"
    else
        echo "❌ Qt6 Wayland component: $lib (missing)"
    fi
done

# Check Qt6 plugin directories that are needed for AppImage bundling
echo ""
echo "Testing Qt6 plugin directories for AppImage bundling..."
qt6_plugin_dirs=(
    "/usr/lib/x86_64-linux-gnu/qt6/plugins/platforms"
    "/usr/lib/x86_64-linux-gnu/qt6/plugins/wayland-decoration-client"
    "/usr/lib/x86_64-linux-gnu/qt6/plugins/wayland-graphics-integration-client" 
    "/usr/lib/x86_64-linux-gnu/qt6/plugins/wayland-shell-integration"
    "/usr/lib/x86_64-linux-gnu/qt6/plugins/xcbglintegrations"
)

for dir in "${qt6_plugin_dirs[@]}"; do
    if [ -d "$dir" ]; then
        plugin_count=$(find "$dir" -name "*.so" 2>/dev/null | wc -l)
        echo "✅ Qt6 plugin directory: $dir ($plugin_count plugins)"
    else
        echo "❌ Qt6 plugin directory: $dir (missing)"
    fi
done

# Test Qt6 CMake configuration specifically for AppImage requirements
echo ""
echo "Testing Qt6 CMake configuration for AppImage builds..."
cat > /tmp/CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.16)
project(TestQt6AppImage)

# Test essential Qt6 components needed for mcpelauncher-ui AppImage
find_package(Qt6 REQUIRED COMPONENTS 
    Core 
    Widgets 
    OpenGL
)

# Optional components that may not be available on all systems
find_package(Qt6 COMPONENTS 
    WebEngine 
    WebEngineWidgets 
    WaylandClient 
    QUIET
)

message(STATUS "Qt6 AppImage build test: SUCCESS")
message(STATUS "Qt6 Version: ${Qt6_VERSION}")
message(STATUS "Qt6 Installation: ${Qt6_DIR}")
message(STATUS "Qt6 Wayland: ${Qt6WaylandClient_FOUND}")
message(STATUS "Qt6 WebEngine: ${Qt6WebEngine_FOUND}")
EOF

if cmake -S /tmp -B /tmp/build_qt6_appimage >/dev/null 2>&1; then
    echo "✅ Qt6 CMake AppImage configuration: SUCCESS"
    cmake -S /tmp -B /tmp/build_qt6_appimage 2>&1 | grep "Qt6" || true
else
    echo "❌ Qt6 CMake AppImage configuration: FAILED"
fi

echo ""
echo "=== Dependency Validation Summary ==="
echo ""

# Final validation summary
VALIDATION_ERRORS=0
VALIDATION_WARNINGS=0

echo "Performing final dependency validation..."

# Check critical requirements
if [ "$QT6_FOUND" = "false" ]; then
    echo "❌ CRITICAL: Qt6 qmake not available"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

if [ "$QT6_CMAKE_SUCCESS" = "false" ]; then
    echo "❌ CRITICAL: Qt6 CMake configuration failed"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo "❌ CRITICAL: Missing build tools: ${MISSING_TOOLS[*]}"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

# Check for common issues and provide solutions
if [ "$VALIDATION_ERRORS" -gt 0 ]; then
    echo ""
    echo "🔥 VALIDATION FAILED: $VALIDATION_ERRORS critical errors found"
    echo ""
    echo "To fix Qt6 issues, run:"
    echo "  ./install-qt6-deps.sh"
    echo ""
    echo "Or install manually:"
    echo "  sudo apt-get update"
    echo "  sudo apt-get install qt6-base-dev qt6-tools-dev qt6-webengine-dev qt6-wayland-dev"
    echo ""
    exit 1
else
    echo "✅ All critical dependencies validated successfully"
fi

if [ "$VALIDATION_WARNINGS" -gt 0 ]; then
    echo "⚠️  $VALIDATION_WARNINGS warnings found - build may succeed but some features might be limited"
fi

echo ""
echo "If Qt6 Wayland components are missing, install with:"
echo "  sudo apt-get install qt6-wayland qt6-wayland-dev"
echo ""
echo "For complete Qt6 setup, run:"
echo "  ./install-qt6-deps.sh"
echo ""

# Cleanup
cd /
rm -rf "$TEST_DIR" /tmp/CMakeLists.txt /tmp/build_qt6_appimage 2>/dev/null || true

echo "=== Dependency Test Complete ==="