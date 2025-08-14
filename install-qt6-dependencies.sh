#!/bin/bash

# Qt6 Dependency Installation Script for AppImage Builder
# Installs complete Qt6 development stack for Ubuntu 22.04+

set -e

echo "=== Installing Qt6 Dependencies for AppImage Builder ==="

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges. Please run with sudo."
    exit 1
fi

# Update package lists
echo "Updating package lists..."
apt-get update

# Install Qt6 core development packages
echo "Installing Qt6 core development packages..."
apt-get install -y \
    build-essential \
    cmake \
    git \
    curl \
    wget \
    file \
    ninja-build \
    clang \
    lld \
    pkg-config \
    libc6-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    zlib1g-dev \
    libpng-dev \
    libuv1-dev \
    libzip-dev \
    libglib2.0-dev

# Install Qt6 framework packages
echo "Installing Qt6 framework packages..."
apt-get install -y \
    qt6-base-dev \
    qt6-base-dev-tools \
    qt6-tools-dev \
    qt6-tools-dev-tools \
    qmake6 \
    libqt6svg6-dev \
    qt6-webengine-dev \
    qt6-webengine-dev-tools \
    libqt6webenginecore6 \
    libqt6webenginewidgets6 \
    qt6-declarative-dev \
    qml6-module-qtquick-controls \
    qml6-module-qtquick-layouts \
    qml6-module-qtquick-window \
    qml6-module-qtquick-dialogs \
    qml6-module-qtwebengine

# Install Qt6 Wayland support (critical for Bazzite OS compatibility)
echo "Installing Qt6 Wayland support..."
apt-get install -y \
    qt6-wayland \
    qt6-wayland-dev \
    libqt6waylandclient6 \
    libqt6waylandcompositor6

# Install Qt6 OpenGL and graphics support
echo "Installing Qt6 OpenGL and graphics support..."
apt-get install -y \
    libqt6opengl6-dev \
    libgl1-mesa-dev \
    libegl1-mesa-dev \
    libgles2-mesa-dev \
    libx11-dev \
    libxext-dev \
    libxcursor-dev \
    libxinerama-dev \
    libxi-dev \
    libxrandr-dev \
    libxtst6 \
    libxss1

# Install audio and device support
echo "Installing audio and device support..."
apt-get install -y \
    libasound2-dev \
    libpulse-dev \
    libudev-dev \
    libevdev-dev \
    libnss3-dev

# Install additional development tools
echo "Installing additional development tools..."
apt-get install -y \
    libprotobuf-dev \
    protobuf-compiler

echo "=== Qt6 Dependencies Installation Complete ==="

# Verify Qt6 installation
echo "Verifying Qt6 installation..."

if command -v qmake6 >/dev/null 2>&1; then
    echo "✓ Qt6 qmake found: $(qmake6 --version)"
else
    echo "✗ Qt6 qmake not found"
fi

if [ -d "/usr/lib/x86_64-linux-gnu/cmake/Qt6" ]; then
    echo "✓ Qt6 CMake modules found"
    ls /usr/lib/x86_64-linux-gnu/cmake/Qt6* | head -5
else
    echo "✗ Qt6 CMake modules not found"
fi

if [ -d "/usr/lib/x86_64-linux-gnu/qt6/plugins/platforms" ]; then
    echo "✓ Qt6 platform plugins found"
    ls /usr/lib/x86_64-linux-gnu/qt6/plugins/platforms/ | grep wayland || echo "  Warning: Wayland platform plugins not found"
else
    echo "✗ Qt6 platform plugins directory not found"
fi

echo ""
echo "Qt6 development environment is ready for AppImage building!"
echo "You can now run: ./build_appimage.sh -t x86_64 -m -n -o -j \$(nproc) -q quirks-qt6.sh"