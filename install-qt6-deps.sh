#!/bin/bash
# Qt6 Dependency Installation Script for Local Development
# Installs complete Qt6 development stack with Wayland support

set -e

# Color output functions
show_status() {
    echo -e "\033[1;34m[STATUS]\033[0m $1"
}

show_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

show_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

show_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

# Check if running on Ubuntu/Debian
check_system() {
    if ! command -v apt-get &> /dev/null; then
        show_error "This script requires Ubuntu/Debian with apt-get package manager"
        exit 1
    fi
    
    # Check Ubuntu version
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        show_status "Detected: $NAME $VERSION"
        
        # Recommend Ubuntu 22.04 or newer for Qt6
        if [[ "$VERSION_ID" < "22.04" ]]; then
            show_warning "Ubuntu 22.04 or newer recommended for Qt6 support"
            show_warning "Current version: $VERSION_ID"
        fi
    fi
}

# Install Qt6 dependencies
install_qt6_deps() {
    show_status "Installing Qt6 development dependencies..."
    
    # Update package list
    sudo apt-get update
    
    # Install base build tools
    show_status "Installing base build tools..."
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
        qt6-svg-dev \
        libqt6opengl6-dev
    
    # Install Qt6 WebEngine
    show_status "Installing Qt6 WebEngine..."
    sudo apt-get install -y \
        qt6-webengine-dev \
        qt6-webengine-dev-tools \
        libqt6webenginecore6 \
        libqt6webenginewidgets6
    
    # Install Qt6 Declarative (QML)
    show_status "Installing Qt6 QML components..."
    sudo apt-get install -y \
        qt6-declarative-dev \
        qml6-module-qtquick-controls \
        qml6-module-qtquick-layouts \
        qml6-module-qtquick-window \
        qml6-module-qtquick-dialogs \
        qml6-module-qtwebengine
    
    # Install Qt6 Wayland support (critical for Bazzite OS compatibility)
    show_status "Installing Qt6 Wayland support..."
    sudo apt-get install -y \
        qt6-wayland \
        qt6-wayland-dev
    
    # Install graphics libraries
    show_status "Installing OpenGL/graphics libraries..."
    sudo apt-get install -y \
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
    
    # Install audio/input libraries
    show_status "Installing audio and input libraries..."
    sudo apt-get install -y \
        libasound2-dev \
        libpulse-dev \
        libudev-dev \
        libevdev-dev \
        libnss3-dev
    
    show_success "Qt6 dependencies installed successfully!"
}

# Validate Qt6 installation
validate_qt6_installation() {
    show_status "Validating Qt6 installation..."
    
    local validation_failed=false
    
    # Check qmake6
    if command -v qmake6 &> /dev/null; then
        local qt_version=$(qmake6 -version | grep "Qt version" | awk '{print $4}')
        show_success "Qt6 qmake found: $qt_version"
    else
        show_error "qmake6 not found"
        validation_failed=true
    fi
    
    # Check key Qt6 CMake directories
    local qt6_dirs=(
        "/usr/lib/x86_64-linux-gnu/cmake/Qt6"
        "/usr/lib/x86_64-linux-gnu/cmake/Qt6Core"
        "/usr/lib/x86_64-linux-gnu/cmake/Qt6Widgets"
        "/usr/lib/x86_64-linux-gnu/cmake/Qt6WebEngine"
        "/usr/lib/x86_64-linux-gnu/cmake/Qt6WaylandClient"
    )
    
    for dir in "${qt6_dirs[@]}"; do
        if [ -d "$dir" ]; then
            show_success "Found: $dir"
        else
            show_warning "Missing: $dir"
        fi
    done
    
    # Check Qt6 Wayland plugins
    local wayland_plugins_base="/usr/lib/x86_64-linux-gnu/qt6/plugins"
    local wayland_plugin_dirs=(
        "$wayland_plugins_base/wayland-decoration-client"
        "$wayland_plugins_base/wayland-graphics-integration-client"
        "$wayland_plugins_base/wayland-shell-integration"
    )
    
    for dir in "${wayland_plugin_dirs[@]}"; do
        if [ -d "$dir" ]; then
            show_success "Found Wayland plugin: $dir"
        else
            show_warning "Missing Wayland plugin: $dir"
        fi
    done
    
    if [ "$validation_failed" = true ]; then
        show_error "Qt6 installation validation failed"
        return 1
    else
        show_success "Qt6 installation validation passed"
        return 0
    fi
}

# Set up Qt6 environment
setup_qt6_environment() {
    show_status "Setting up Qt6 environment variables..."
    
    # Create environment setup script
    cat > /tmp/qt6-env.sh << 'EOF'
# Qt6 Environment Variables
export QT_VERSION=6
export CMAKE_QT_VERSION=Qt6
export PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig:/usr/lib/pkgconfig"

# Optional: Set Qt6 as default if multiple Qt versions are installed
export QMAKE=/usr/bin/qmake6
export QT_SELECT=qt6
EOF
    
    show_success "Qt6 environment script created at /tmp/qt6-env.sh"
    show_status "To use Qt6 environment in your shell session, run:"
    echo "    source /tmp/qt6-env.sh"
}

# Main installation function
main() {
    echo ""
    echo "=================================================="
    echo "Qt6 Development Dependencies Installation"
    echo "=================================================="
    echo ""
    
    check_system
    install_qt6_deps
    validate_qt6_installation
    setup_qt6_environment
    
    echo ""
    echo "=================================================="
    echo "Qt6 Installation Complete!"
    echo "=================================================="
    echo ""
    echo "Next steps:"
    echo "1. Source the Qt6 environment: source /tmp/qt6-env.sh"
    echo "2. Test dependencies: ./test-dependencies.sh"
    echo "3. Build Qt6 AppImage: ./build_appimage.sh -t x86_64 -m -n -o -q quirks-qt6.sh"
    echo ""
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        echo "Qt6 Dependency Installation Script"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  -h, --help     Show this help message"
        echo "  --validate     Only run validation (no installation)"
        echo ""
        echo "This script installs complete Qt6 development stack including:"
        echo "  - Qt6 core libraries and development tools"
        echo "  - Qt6 WebEngine for web components"
        echo "  - Qt6 Wayland support for immutable OS compatibility"
        echo "  - Required graphics and audio libraries"
        echo ""
        exit 0
        ;;
    --validate)
        validate_qt6_installation
        exit $?
        ;;
    *)
        main "$@"
        ;;
esac