#!/bin/bash

# Qt6 Dependency Installation Script for mcpelauncher-linux AppImage Builder
# This script installs all Qt6 dependencies required for building AppImages

set -e

echo "=== Qt6 Dependency Installation for AppImage Builder ==="
echo "Installing Qt6 development packages for Ubuntu 22.04+"
echo ""

# Update package lists
echo "Updating package lists..."
sudo apt-get update

# Install Qt6 and build dependencies
echo "Installing Qt6 and related dependencies..."
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
  pkg-config \
  libc6-dev \
  libssl-dev \
  libcurl4-openssl-dev \
  zlib1g-dev \
  libpng-dev \
  libuv1-dev \
  libzip-dev \
  libglib2.0-dev \
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
  qml6-module-qtwebengine \
  qt6-wayland \
  qt6-wayland-dev \
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
  libxss1 \
  libasound2-dev \
  libpulse-dev \
  libudev-dev \
  libevdev-dev \
  libnss3-dev \
  libprotobuf-dev \
  protobuf-compiler

echo ""
echo "=== Qt6 Dependencies Installed Successfully ==="
echo ""

# Validate Qt6 installation
echo "Validating Qt6 installation..."
echo ""

# Check qmake6
if command -v qmake6 >/dev/null 2>&1; then
    echo "✅ qmake6: $(qmake6 --version | head -1)"
else
    echo "❌ qmake6: Not found"
fi

# Check Qt6 CMake modules
qt6_cmake_base="/usr/lib/x86_64-linux-gnu/cmake"
qt6_components=("Qt6" "Qt6Core" "Qt6Widgets" "Qt6WebEngine" "Qt6WaylandClient" "Qt6OpenGL")

echo ""
echo "Qt6 CMake Components:"
for component in "${qt6_components[@]}"; do
    if [ -d "$qt6_cmake_base/$component" ]; then
        echo "✅ $component: Found at $qt6_cmake_base/$component"
    else
        echo "❌ $component: Not found at $qt6_cmake_base/$component"
    fi
done

echo ""
echo "=== Installation Validation Complete ==="
echo ""
echo "You can now build Qt6 AppImages using:"
echo "  ./build_appimage.sh -t x86_64 -m -n -o -j \$(nproc) -q quirks-qt6.sh"
echo ""
echo "Or test dependencies with:"
echo "  ./test-dependencies.sh"