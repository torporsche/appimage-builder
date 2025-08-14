#!/bin/bash

# Qt6 Dependency Installation Script for Ubuntu 22.04+
# Installs complete Qt6 development stack with Wayland support

set -e

# Source common utilities
if [ -f "common.sh" ]; then
    source common.sh
fi

# Define status functions (fallback or override)
show_status() { echo "=> $1"; }
show_success() { echo "✅ $1"; }
show_error() { echo "❌ $1"; }
show_warning() { echo "⚠️ $1"; }

# Detect OS and version
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID="$ID"
        OS_VERSION="$VERSION_ID"
        show_status "Detected OS: $PRETTY_NAME"
    else
        show_error "Cannot detect OS. This script requires Ubuntu 22.04+ or compatible."
        exit 1
    fi
}

# Validate OS compatibility
validate_os() {
    case "$OS_ID" in
        ubuntu)
            if [ "${OS_VERSION%%.*}" -ge 22 ]; then
                show_success "Ubuntu $OS_VERSION is supported"
            else
                show_error "Ubuntu $OS_VERSION is not supported. Requires Ubuntu 22.04+"
                exit 1
            fi
            ;;
        debian)
            if [ "${OS_VERSION%%.*}" -ge 12 ]; then
                show_success "Debian $OS_VERSION is supported"
            else
                show_warning "Debian $OS_VERSION may not have all Qt6 packages available"
            fi
            ;;
        *)
            show_warning "OS $OS_ID is not officially supported but proceeding anyway"
            ;;
    esac
}

# Update package manager
update_packages() {
    show_status "Updating package manager..."
    sudo apt-get update -qq
    show_success "Package lists updated"
}

# Install Qt6 core development packages
install_qt6_core() {
    show_status "Installing Qt6 core development packages..."
    
    sudo apt-get install -y \
        qt6-base-dev \
        qt6-base-dev-tools \
        qt6-tools-dev \
        qt6-tools-dev-tools \
        qmake6 \
        libqt6core6 \
        libqt6gui6 \
        libqt6widgets6 \
        libqt6svg6-dev \
        libqt6opengl6-dev
        
    show_success "Qt6 core packages installed"
}

# Install Qt6 WebEngine for web components
install_qt6_webengine() {
    show_status "Installing Qt6 WebEngine packages..."
    
    sudo apt-get install -y \
        qt6-webengine-dev \
        qt6-webengine-dev-tools \
        libqt6webenginecore6 \
        libqt6webenginewidgets6 \
        libqt6webengine6-data
        
    show_success "Qt6 WebEngine packages installed"
}

# Install Qt6 Wayland support for immutable OS environments
install_qt6_wayland() {
    show_status "Installing Qt6 Wayland support..."
    
    sudo apt-get install -y \
        qt6-wayland \
        qt6-wayland-dev \
        libqt6waylandclient6 \
        libqt6waylandcompositor6
        
    show_success "Qt6 Wayland packages installed"
}

# Install Qt6 QML and Quick modules
install_qt6_qml() {
    show_status "Installing Qt6 QML and Quick modules..."
    
    sudo apt-get install -y \
        qt6-declarative-dev \
        qml6-module-qtquick \
        qml6-module-qtquick-controls \
        qml6-module-qtquick-layouts \
        qml6-module-qtquick-window \
        qml6-module-qtquick-dialogs \
        qml6-module-qtwebengine
        
    show_success "Qt6 QML packages installed"
}

# Install build tools and libraries
install_build_tools() {
    show_status "Installing build tools and system libraries..."
    
    sudo apt-get install -y \
        build-essential \
        cmake \
        ninja-build \
        clang \
        lld \
        pkg-config \
        git \
        curl \
        wget \
        file
        
    show_success "Build tools installed"
}

# Install system libraries
install_system_libraries() {
    show_status "Installing system libraries..."
    
    sudo apt-get install -y \
        libc6-dev \
        libssl-dev \
        libcurl4-openssl-dev \
        zlib1g-dev \
        libpng-dev \
        libuv1-dev \
        libzip-dev \
        libglib2.0-dev \
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
        
    show_success "System libraries installed"
}

# Validate Qt6 installation
validate_qt6_installation() {
    show_status "Validating Qt6 installation..."
    
    # Check Qt6 version
    if command -v qmake6 >/dev/null 2>&1; then
        QT6_VERSION=$(qmake6 -query QT_VERSION 2>/dev/null || echo "Unknown")
        show_success "Qt6 version: $QT6_VERSION"
    else
        show_error "qmake6 not found"
        return 1
    fi
    
    # Check key Qt6 directories
    local qt6_dirs=(
        "/usr/lib/x86_64-linux-gnu/cmake/Qt6"
        "/usr/lib/x86_64-linux-gnu/cmake/Qt6Core"
        "/usr/lib/x86_64-linux-gnu/cmake/Qt6Widgets"
        "/usr/lib/x86_64-linux-gnu/cmake/Qt6WebEngineCore"
        "/usr/lib/x86_64-linux-gnu/cmake/Qt6WebEngineWidgets"
        "/usr/lib/x86_64-linux-gnu/cmake/Qt6WaylandClient"
        "/usr/lib/x86_64-linux-gnu/qt6/plugins"
    )
    
    local missing_dirs=()
    for dir in "${qt6_dirs[@]}"; do
        if [ -d "$dir" ]; then
            show_success "Found: $dir"
        else
            show_warning "Missing: $dir"
            missing_dirs+=("$dir")
        fi
    done
    
    # Check Wayland platform plugins
    local wayland_plugins_base="/usr/lib/x86_64-linux-gnu/qt6/plugins"
    if [ -d "$wayland_plugins_base" ]; then
        local wayland_dirs=(
            "platforms"
            "wayland-decoration-client"
            "wayland-graphics-integration-client"
            "wayland-shell-integration"
        )
        
        for plugin_dir in "${wayland_dirs[@]}"; do
            if [ -d "$wayland_plugins_base/$plugin_dir" ]; then
                show_success "Found Qt6 plugin: $plugin_dir"
            else
                show_warning "Missing Qt6 plugin: $plugin_dir"
            fi
        done
    fi
    
    if [ ${#missing_dirs[@]} -eq 0 ]; then
        show_success "Qt6 installation validation passed"
        return 0
    else
        show_warning "Qt6 installation has ${#missing_dirs[@]} missing directories"
        return 1
    fi
}

# Generate installation summary
generate_summary() {
    show_status "Installation Summary"
    echo ""
    echo "Qt6 development environment is now ready for:"
    echo "  - mcpelauncher-linux Qt6 builds"
    echo "  - Native Wayland support for immutable OS environments"
    echo "  - WebEngine components for web-based UI elements"
    echo "  - Modern C++17 compilation with clang/gcc"
    echo ""
    echo "Next steps:"
    echo "  1. Run './test-dependencies.sh' to verify the installation"
    echo "  2. Build Qt6 AppImage: './build_appimage.sh -t x86_64 -m -n -o -q quirks-qt6.sh'"
    echo "  3. Validate the result: './validate-appimage.sh'"
    echo ""
}

# Main installation function
main() {
    echo ""
    echo "==================================================="
    echo "Qt6 Development Environment Installation"
    echo "==================================================="
    echo ""
    
    detect_os
    validate_os
    update_packages
    
    install_build_tools
    install_system_libraries
    install_qt6_core
    install_qt6_webengine
    install_qt6_wayland
    install_qt6_qml
    
    echo ""
    echo "==================================================="
    echo "Installation Complete - Running Validation"
    echo "==================================================="
    echo ""
    
    if validate_qt6_installation; then
        generate_summary
        show_success "Qt6 development environment installation completed successfully!"
        exit 0
    else
        show_error "Qt6 installation validation failed. Please check the warnings above."
        exit 1
    fi
}

# Parse command line arguments
while getopts "h?v" opt; do
    case "$opt" in
    h|\?)
        echo "Qt6 Development Environment Installation Script"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  -h  Show this help message"
        echo "  -v  Verbose mode (currently no effect)"
        echo ""
        echo "This script installs a complete Qt6 development environment"
        echo "suitable for building mcpelauncher-linux with native Wayland support."
        echo ""
        exit 0
        ;;
    v)
        # Verbose mode - currently no effect
        ;;
    esac
done

# Run main installation
main