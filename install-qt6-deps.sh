#!/bin/bash

# Qt6 Dependency Installation Script for Local Development
# This script installs all Qt6 dependencies needed to build the AppImage locally

set -e

show_status() {
    echo "[INFO] $1"
}

show_error() {
    echo "[ERROR] $1" >&2
}

show_warning() {
    echo "[WARNING] $1" >&2
}

# Check if running on Ubuntu/Debian
if ! command -v apt-get >/dev/null 2>&1; then
    show_error "This script requires apt-get (Ubuntu/Debian). For other distributions, install equivalent Qt6 packages manually."
    exit 1
fi

# Check Ubuntu version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" = "ubuntu" ]; then
        case "$VERSION_ID" in
            "22.04"|"23.04"|"23.10"|"24.04")
                show_status "Detected supported Ubuntu version: $VERSION_ID"
                ;;
            *)
                show_warning "Ubuntu version $VERSION_ID may not have all Qt6 packages. Proceeding anyway..."
                ;;
        esac
    elif [ "$ID" = "debian" ]; then
        show_status "Detected Debian. Qt6 packages should be available in recent versions."
    else
        show_warning "Non-Ubuntu/Debian system detected. Package names may differ."
    fi
fi

show_status "Installing Qt6 dependencies for AppImage development..."

# Update package index
show_status "Updating package index..."
sudo apt-get update

# Install build essentials and tools
show_status "Installing build tools..."
sudo apt-get install -y \
    build-essential \
    cmake \
    git \
    curl \
    wget \
    file \
    ninja-build \
    clang \
    lld \
    pkg-config

# Install core libraries
show_status "Installing core development libraries..."
sudo apt-get install -y \
    libc6-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    zlib1g-dev \
    libpng-dev \
    libuv1-dev \
    libzip-dev \
    libglib2.0-dev \
    libprotobuf-dev \
    protobuf-compiler

# Install Qt6 core packages
show_status "Installing Qt6 core packages..."
sudo apt-get install -y \
    qt6-base-dev \
    qt6-base-dev-tools \
    qt6-tools-dev \
    qt6-tools-dev-tools \
    qmake6 \
    libqt6svg6-dev \
    libqt6opengl6-dev

# Install Qt6 WebEngine
show_status "Installing Qt6 WebEngine..."
sudo apt-get install -y \
    qt6-webengine-dev \
    qt6-webengine-dev-tools \
    libqt6webenginecore6 \
    libqt6webenginewidgets6

# Install Qt6 QML/Quick components
show_status "Installing Qt6 QML/Quick components..."
sudo apt-get install -y \
    qt6-declarative-dev \
    qml6-module-qtquick-controls \
    qml6-module-qtquick-layouts \
    qml6-module-qtquick-window \
    qml6-module-qtquick-dialogs \
    qml6-module-qtwebengine

# Install Qt6 Wayland support (critical for immutable OS compatibility)
show_status "Installing Qt6 Wayland support..."
sudo apt-get install -y \
    qt6-wayland \
    qt6-wayland-dev

# Install graphics libraries
show_status "Installing graphics libraries..."
sudo apt-get install -y \
    libgl1-mesa-dev \
    libegl1-mesa-dev \
    libgles2-mesa-dev

# Install X11 libraries
show_status "Installing X11 libraries..."
sudo apt-get install -y \
    libx11-dev \
    libxext-dev \
    libxcursor-dev \
    libxinerama-dev \
    libxi-dev \
    libxrandr-dev \
    libxtst6 \
    libxss1

# Install audio libraries
show_status "Installing audio libraries..."
sudo apt-get install -y \
    libasound2-dev \
    libpulse-dev

# Install additional libraries
show_status "Installing additional libraries..."
sudo apt-get install -y \
    libudev-dev \
    libevdev-dev \
    libnss3-dev

show_status "Qt6 dependencies installation completed successfully!"

# Verify installation
show_status "Verifying Qt6 installation..."
if command -v qmake6 >/dev/null 2>&1; then
    echo "Qt6 qmake version: $(qmake6 --version)"
else
    show_warning "qmake6 not found in PATH"
fi

# Test Qt6 CMake detection
show_status "Testing Qt6 CMake detection..."
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.16)
project(TestQt6)
find_package(Qt6 COMPONENTS Core Widgets WebEngine WaylandClient QUIET)
if(Qt6_FOUND)
    message(STATUS "Qt6 found: ${Qt6_VERSION}")
    message(STATUS "Qt6 Core: ${Qt6Core_FOUND}")
    message(STATUS "Qt6 Widgets: ${Qt6Widgets_FOUND}")
    message(STATUS "Qt6 WebEngine: ${Qt6WebEngine_FOUND}")
    message(STATUS "Qt6 WaylandClient: ${Qt6WaylandClient_FOUND}")
else()
    message(STATUS "Qt6 not found")
endif()
EOF

if cmake -S . -B build >/dev/null 2>&1; then
    show_status "Qt6 CMake detection: SUCCESS"
    cmake -S . -B build 2>&1 | grep -E "(Qt6|STATUS)" || true
else
    show_warning "Qt6 CMake detection: FAILED"
fi

# Cleanup
cd /
rm -rf "$TEMP_DIR"

show_status "Installation verification completed."
show_status ""
show_status "You can now build the Qt6 AppImage using:"
show_status "  ./build_appimage.sh -t x86_64 -m -n -o -j \$(nproc) -q quirks-qt6.sh"
show_status ""
show_status "For dependency testing, run:"
show_status "  ./test-dependencies.sh"