# AppImage Compatibility Guide

This document provides comprehensive system requirements, compatibility information, and troubleshooting guidance for the mcpelauncher-linux AppImage.

## System Requirements

### Minimum Requirements

#### Operating System
- **Linux Distribution**: Any modern Linux distribution (2020+)
- **Kernel Version**: Linux 4.15+ (Ubuntu 18.04 equivalent)
- **GLIBC Version**: 2.31+ (Ubuntu 20.04 equivalent) - **Recommended**
- **Architecture**: x86_64 only

#### Hardware
- **CPU**: x86_64 processor with SSE4.1 support
- **Memory**: 2GB RAM minimum, 4GB+ recommended
- **Storage**: 1GB free disk space
- **Graphics**: OpenGL 3.3+ or OpenGL ES 3.0+ support

#### Dependencies
- **FUSE**: For AppImage mounting (usually pre-installed)
- **Display Server**: X11 or Wayland
- **Audio**: PulseAudio, ALSA, or PipeWire

### Recommended Configuration

#### For Qt6 Builds (Default)
```bash
# Ubuntu 22.04+ / Debian 12+
sudo apt-get install -y \
    fuse3 libfuse3-3 \
    qt6-wayland \
    mesa-utils \
    pulseaudio \
    ca-certificates

# Fedora 36+
sudo dnf install -y \
    fuse3 \
    qt6-qtwayland \
    mesa-utils \
    pulseaudio \
    ca-certificates

# Arch Linux
sudo pacman -S \
    fuse3 \
    qt6-wayland \
    mesa-utils \
    pulseaudio \
    ca-certificates
```

#### For Qt5 Builds (Legacy)
```bash
# Ubuntu 20.04+
sudo apt-get install -y \
    fuse libfuse2 \
    qt5-wayland \
    mesa-utils \
    pulseaudio \
    ca-certificates
```

## Hardware Compatibility

### Graphics Drivers

#### AMD Graphics (Recommended)
- **Modern Cards (RDNA/RDNA2/RDNA3)**: Full support with Mesa 22.0+
- **GCN Cards**: Good support with Mesa 21.0+
- **Environment Variables** for optimal performance:
  ```bash
  export MESA_LOADER_DRIVER_OVERRIDE=radeonsi
  export AMD_VULKAN_ICD=RADV
  export RADV_PERFTEST=gpl,nggc
  ```

#### NVIDIA Graphics
- **Proprietary Driver**: Version 470+ recommended
- **Nouveau**: Basic support, may require software rendering
- **Environment Variables**:
  ```bash
  export __GL_SYNC_TO_VBLANK=1
  export __GL_THREADED_OPTIMIZATIONS=1
  ```

#### Intel Graphics
- **Modern iGPUs (Gen8+)**: Full support with Mesa 20.0+
- **Older iGPUs**: May require software rendering fallback

### Display Compatibility

#### Wayland (Preferred)
- **Supported Compositors**: 
  - GNOME Shell 40+
  - KDE Plasma 5.24+
  - Sway 1.7+
  - Hyprland
  - wlroots-based compositors

- **Environment Setup**:
  ```bash
  export QT_QPA_PLATFORM="wayland;xcb"
  export QT_WAYLAND_FORCE_DPI=96
  export QT_AUTO_SCREEN_SCALE_FACTOR=0
  ```

#### X11 (Fallback)
- **Window Managers**: Any X11-compatible WM
- **Environment Setup**:
  ```bash
  export QT_QPA_PLATFORM="xcb"
  export QT_AUTO_SCREEN_SCALE_FACTOR=0
  ```

## Distribution-Specific Notes

### Ubuntu/Debian
- **18.04/20.04**: Use Qt5 build for better compatibility
- **22.04+**: Qt6 build recommended
- **Missing dependencies**: Install with `apt-get`

### Fedora/RHEL
- **Fedora 36+**: Full Qt6 support
- **CentOS/RHEL 8+**: May need EPEL repository
- **Immutable Variants** (Silverblue, Kinoite, Bazzite): 
  - Use Flatpak runtime dependencies
  - Prefer Qt6 builds
  - May require `--disable-sandboxing` for WebEngine

### Arch Linux
- **Rolling Release**: Latest Qt6 recommended
- **Missing dependencies**: Install with `pacman`

### openSUSE
- **Tumbleweed**: Qt6 support excellent
- **Leap**: Qt5 may be more stable

## Environment Configuration

### Qt6 Configuration (Default)

#### Basic Setup
```bash
# Core Qt6 environment
export QT_VERSION=6
export QT_QPA_PLATFORM="wayland;xcb"
export QT_LOGGING_RULES="qt.qpa.wayland.debug=false"

# Scaling and DPI
export QT_WAYLAND_FORCE_DPI=96
export QT_AUTO_SCREEN_SCALE_FACTOR=0
export QT_SCALE_FACTOR_ROUNDING_POLICY=RoundPreferFloor

# WebEngine compatibility
export QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox --disable-seccomp-filter-sandbox"
```

#### Hardware Acceleration
```bash
# Enable hardware acceleration
export QT_OPENGL=desktop
export QT_QUICK_BACKEND=rhi

# For problematic systems, force software rendering
export LIBGL_ALWAYS_SOFTWARE=1
export MESA_GL_VERSION_OVERRIDE=3.3
export MESA_GLES_VERSION_OVERRIDE=3.0
```

### Qt5 Configuration (Legacy)

```bash
# Core Qt5 environment
export QT_VERSION=5
export QT_QPA_PLATFORM="wayland-egl;wayland;xcb"

# Scaling
export QT_AUTO_SCREEN_SCALE_FACTOR=0
export QT_SCALE_FACTOR=1

# WebEngine (if available)
export QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox"
```

## Troubleshooting

### Common Issues and Solutions

#### 1. AppImage Won't Start

**Symptoms**: Double-click does nothing, or permission denied

**Solutions**:
```bash
# Make executable
chmod +x mcpelauncher-ui-qt.AppImage

# Check FUSE
sudo apt-get install fuse3 libfuse3-3

# Manual extraction if FUSE fails
./mcpelauncher-ui-qt.AppImage --appimage-extract
./squashfs-root/AppRun
```

#### 2. Graphics/Rendering Issues

**Symptoms**: Black screen, UI corruption, crashes on startup

**Solutions**:
```bash
# Try software rendering
export LIBGL_ALWAYS_SOFTWARE=1
./mcpelauncher-ui-qt.AppImage

# AMD graphics optimization
export MESA_LOADER_DRIVER_OVERRIDE=radeonsi
export AMD_VULKAN_ICD=RADV

# Intel graphics workaround
export INTEL_DEBUG=norbc

# NVIDIA proprietary driver
export __GL_SYNC_TO_VBLANK=1
```

#### 3. Wayland Issues

**Symptoms**: Window decoration missing, input problems, crashes

**Solutions**:
```bash
# Force X11 mode
export QT_QPA_PLATFORM=xcb
./mcpelauncher-ui-qt.AppImage

# Fix Wayland scaling
export QT_WAYLAND_FORCE_DPI=96
export QT_SCALE_FACTOR_ROUNDING_POLICY=RoundPreferFloor

# Disable Wayland-specific features
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
```

#### 4. Audio Issues

**Symptoms**: No sound, audio crackling

**Solutions**:
```bash
# Check audio system
pulseaudio --check || pulseaudio --start

# Alternative audio systems
export PULSE_RUNTIME_PATH=/run/user/$(id -u)/pulse

# Force ALSA (fallback)
export QT_MULTIMEDIA_PREFERRED_PLUGINS=alsa
```

#### 5. Network/SSL Issues

**Symptoms**: Login failures, certificate errors

**Solutions**:
```bash
# Update certificates
sudo apt-get update && sudo apt-get install ca-certificates

# Manual certificate path
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
export SSL_CERT_DIR=/etc/ssl/certs

# Network debugging
export QT_LOGGING_RULES="qt.network.ssl.debug=true"
```

#### 6. Performance Issues

**Symptoms**: Slow startup, laggy UI, high CPU usage

**Solutions**:
```bash
# Enable hardware acceleration
export QT_OPENGL=desktop
export QT_QUICK_BACKEND=rhi

# Reduce quality for older hardware
export QT_QUICK_CONTROLS_STYLE=Basic
export QT_SCALE_FACTOR=0.8

# Disable animations
export QT_QUICK_CONTROLS_MOBILE=false
```

### Build Variant Selection

#### Choose Qt6 Build When:
- Using Ubuntu 22.04+ or equivalent
- On Wayland desktop environments
- Need modern graphics driver support
- Using AMD RDNA/RDNA2/RDNA3 graphics
- On immutable OS (Silverblue, Bazzite)

#### Choose Qt5 Build When:
- Using Ubuntu 20.04 or older
- On legacy systems
- Need maximum compatibility
- Experiencing Qt6-specific issues

### Validation Tools

#### Compatibility Checker
```bash
# Check if your system is compatible
./ensure-appimage-compatibility.sh mcpelauncher-ui-qt.AppImage

# Generate detailed report
./ensure-appimage-compatibility.sh mcpelauncher-ui-qt.AppImage my_report.txt
```

#### OpenGL ES 3.0 Validator
```bash
# Build and test GLES 3.0 support
./build_gles30_validator.sh all

# Test with software fallback
./build_gles30_validator.sh test
gles30_validator --software
```

#### Dependency Testing
```bash
# Check build dependencies
./test-dependencies.sh

# Install Qt6 dependencies
./install-qt6-deps.sh
```

## Performance Optimization

### For Gaming Handhelds (Steam Deck, ROG Ally, etc.)

```bash
# Optimize for handheld
export QT_SCALE_FACTOR=1.25
export QT_WAYLAND_FORCE_DPI=120
export QT_QUICK_CONTROLS_STYLE=Material

# Steam Deck specific
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.steam/steam"
export QT_QPA_PLATFORM="wayland;xcb"

# Performance mode
export QT_OPENGL=desktop
export QT_QUICK_BACKEND=rhi
export AMD_VULKAN_ICD=RADV
export RADV_PERFTEST=gpl,nggc
```

### For Low-End Hardware

```bash
# Reduce resource usage
export QT_QUICK_CONTROLS_STYLE=Basic
export QT_SCALE_FACTOR=0.9
export QT_AUTO_SCREEN_SCALE_FACTOR=0

# Software rendering if necessary
export LIBGL_ALWAYS_SOFTWARE=1
export MESA_GL_VERSION_OVERRIDE=3.3
```

## Security Considerations

### WebEngine Sandboxing

The AppImage may need to disable WebEngine sandboxing on some systems:

```bash
# If WebEngine fails to load
export QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox --disable-seccomp-filter-sandbox"

# For additional compatibility
export QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox --disable-seccomp-filter-sandbox --disable-dev-shm-usage"
```

**Note**: Disabling sandboxing reduces security. Only use when necessary.

### File Permissions

```bash
# Ensure proper AppImage permissions
chmod +x mcpelauncher-ui-qt.AppImage

# For extracted AppImage
chmod +x squashfs-root/AppRun
```

## Getting Help

### Validation and Debugging

1. **Run compatibility checker**:
   ```bash
   ./ensure-appimage-compatibility.sh mcpelauncher-ui-qt.AppImage
   ```

2. **Test OpenGL support**:
   ```bash
   ./build_gles30_validator.sh all
   ```

3. **Check dependencies**:
   ```bash
   ./test-dependencies.sh
   ```

4. **Generate debug logs**:
   ```bash
   export QT_LOGGING_RULES="*=true"
   ./mcpelauncher-ui-qt.AppImage --debug 2>&1 | tee debug.log
   ```

### Community Resources

- **mcpelauncher Documentation**: https://mcpelauncher.readthedocs.io/
- **GitHub Issues**: https://github.com/minecraft-linux/mcpelauncher-ui-manifest/issues
- **Discord Community**: Available through project documentation

### Reporting Issues

When reporting compatibility issues, include:

1. Output from `ensure-appimage-compatibility.sh`
2. System information (`uname -a`, distribution version)
3. Graphics driver information (`glxinfo | grep "OpenGL version"`)
4. Environment variables used
5. Complete error messages or debug logs

This comprehensive compatibility guide should help ensure your mcpelauncher-linux AppImage works correctly across a wide range of Linux systems and configurations.