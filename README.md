# AppImage builder for mcpelauncher-linux

Clean, simplified AppImage builder for x86_64 architecture with Qt6 framework support only.

## Quick Start

This repository builds AppImages for the mcpelauncher-linux project using a streamlined Qt6-only approach optimized for modern systems.

### Build Requirements
- Ubuntu 22.04 LTS (or compatible)
- Qt6 development libraries
- clang compiler
- Standard build tools

### Local Build with Enhanced Validation
```bash
# 1. Test your environment with strict dependency validation
./test-dependencies.sh

# 2. Build Qt6 AppImage (x86_64 only) - RECOMMENDED
./build_appimage.sh -j $(nproc)

# 3. Validate the built AppImage with comprehensive checks
./validate-appimage.sh

# 4. Run complete validation suite including functionality tests
./run-comprehensive-validation.sh

# 5. Check AppImage compatibility across distributions
./ensure-appimage-compatibility.sh output/mcpelauncher-ui-qt.AppImage

# 6. Test OpenGL ES 3.0 support (NEW)
./build_gles30_validator.sh all
```

### Output Directory Convention

The build system follows official AppImage packaging conventions by placing all built artifacts in the `./output` directory:

```bash
# Output directory structure after successful build:
./output/
├── Minecraft_Bedrock_Launcher-x86_64-<version>.<build>.AppImage    # Main AppImage
├── version.x86_64.zsync                                            # Update metadata
└── version.amd64.zsync                                             # Alternative arch metadata
```

#### Output Directory Behavior
- **Automatic Creation**: The `./output` directory is automatically created by `./build_appimage.sh`
- **Consistent Location**: All AppImages are reliably placed in `./output` regardless of build configuration
- **Validation Required**: Use `./validate-appimage.sh` to verify output directory exists and contains valid AppImages
- **Clean Builds**: Remove `./output` before building to ensure fresh artifacts

#### Troubleshooting Output Issues
```bash
# Missing output directory
./validate-appimage.sh
# ❌ Output directory not found: ./output
# → Run './build_appimage.sh' to create output directory and build AppImages

# Empty output directory  
./validate-appimage.sh
# ❌ Output directory is empty: ./output
# → Run './build_appimage.sh' to build AppImages
# → Ensure build completes successfully without errors

# Verify output contents
ls -la ./output/
du -h ./output/*.AppImage    # Check AppImage sizes
file ./output/*.AppImage     # Verify AppImage format
```

### Build Troubleshooting Workflow

#### Quick Dependency Check
```bash
# Check if your system is ready for Qt6 builds
./test-dependencies.sh

# Expected output: All "✅" checks, no "❌" errors
# If you see "❌" errors, follow the installation suggestions
```

#### Common Build Issues and Solutions

**1. Qt6 Not Found Error**
```bash
❌ Qt6 qmake: NOT FOUND
❌ Qt6 CMake AppImage configuration: FAILED
```
**Solution:**
```bash
# Install Qt6 development packages
./install-qt6-deps.sh

# Or manually:
sudo apt-get install qt6-base-dev qt6-tools-dev qt6-webengine-dev
```

**2. Missing Build Tools**
```bash
❌ cmake: NOT FOUND
❌ ninja: NOT FOUND
```
**Solution:**
```bash
sudo apt-get install build-essential cmake ninja-build git pkg-config
```

**3. Qt6 Wayland Components Missing**
```bash
❌ Qt6 Wayland component: /usr/lib/x86_64-linux-gnu/libQt6WaylandClient.so (missing)
```
**Solution:**
```bash
sudo apt-get install qt6-wayland qt6-wayland-dev
```

**4. OpenGL/Graphics Issues**
```bash
⚠️ Hardware OpenGL not available or incomplete - enabling software fallback
```
**Solution:**
```bash
sudo apt-get install libgl1-mesa-dev libegl1-mesa-dev mesa-utils
```

#### Validation Workflow

**Pre-Build Validation:**
```bash
# Ensure environment is ready with integration validation
./integration-validation.sh pre

# Ensure environment dependencies are met
./test-dependencies.sh
echo $? # Should be 0 for success
```

**Post-Build Validation:**
```bash
# Validate AppImage structure and functionality
./validate-appimage.sh

# Run integration validation for reproducibility
./integration-validation.sh post

# Check cross-distribution compatibility
./ensure-appimage-compatibility.sh output/*.AppImage

# Run comprehensive test suite
./run-comprehensive-validation.sh
```

**Complete Validation Workflow:**
```bash
# Complete pre/post build validation
./integration-validation.sh both

# This runs both pre-build and post-build validation
# ensuring reproducible, deterministic builds
```

**CI/CD Integration:**
```bash
# For automated builds, use fail-fast validation
set -e

# Pre-build validation
./integration-validation.sh pre
./test-dependencies.sh

# Build process
./build_appimage.sh -t x86_64 -m -n -o -j $(nproc) -q quirks-qt6.sh

# Post-build validation
./validate-appimage.sh
./integration-validation.sh post
```

## Qt6 Framework

This repository builds AppImages using the **Qt6 framework exclusively**, providing:

### **Benefits of Qt6:**
- **Modern Graphics Support**: Enhanced OpenGL/Vulkan support for AMD graphics (Z1 Extreme, RDNA3)
- **Wayland Compatibility**: Native Wayland protocol support for immutable OS environments (Bazzite, Fedora Atomic)
- **OpenGL ES 3.0 Support**: Improved graphics compatibility with hardware acceleration and software fallbacks
- **Enhanced Validation**: Comprehensive compatibility checking and dependency validation
- **Performance Improvements**: Qt6's optimized rendering pipeline and memory management
- **Security Updates**: Current security patches and vulnerability fixes
- **Future Compatibility**: Alignment with upstream mcpelauncher development direction

### **Build Command:**
```bash
./build_appimage.sh -j $(nproc)
```

### **Target Environment Compatibility:**
- **Bazzite OS** (Fedora Atomic 42 + AMD Z1 Extreme): Qt6 with Wayland support
- **Ubuntu 22.04+**: Qt6 supported
- **Immutable OS**: Qt6 provides excellent compatibility with read-only filesystems

### Validation Framework

This repository includes a comprehensive **AppImage Validation Framework** that ensures production readiness:

- **Build Success Verification**: Confirms all build phases completed without errors
- **AppImage Quality Assessment**: Binary integrity, dependency bundling, size optimization  
- **Component Integration Testing**: mcpelauncher components, Qt6 GUI, OpenGL validation
- **Cross-Platform Compatibility**: GLIBC version checks, library compatibility testing
- **Security Assessment**: Basic security validation and vulnerability checks
- **Performance Benchmarks**: Startup time, file size, extraction performance

See [VALIDATION.md](VALIDATION.md) for complete documentation.

## Troubleshooting

### Qt6 Plugin Issues and Structure

#### Required Qt6 Plugin Structure

The AppImage requires a complete Qt6 plugin directory structure in `usr/plugins/` that matches the official Minecraft Bedrock Launcher AppImage:

**Critical Plugins (Build Failure if Missing):**
```
usr/plugins/
├── platforms/          # Essential for Qt application startup
├── imageformats/       # Required for image loading (PNG, JPG, etc.)
├── iconengines/        # Required for icon rendering
├── wayland-decoration-client/       # Critical for Wayland compatibility
├── wayland-graphics-integration-client/  # Critical for Wayland graphics
└── wayland-shell-integration/       # Critical for Wayland window management
```

**Optional Plugins (Recommended):**
```
usr/plugins/
├── xcbglintegrations/  # X11 OpenGL support
├── webengine/          # Web functionality support
├── tls/               # Secure network connections
└── networkinformation/ # Network status detection
```

#### Plugin Validation and Diagnostics

**Verify Plugin Structure:**
```bash
# Run comprehensive plugin validation
./tests/test-qt6-plugin-validation.sh

# Validate built AppImage
./validate-appimage.sh

# Check specific plugin presence
./validate-appimage.sh | grep -E "(platforms|wayland|webengine)"
```

**Check Plugin Directory Contents:**
```bash
# Extract and examine AppImage plugin structure
./output/mcpelauncher-ui-qt.AppImage --appimage-extract
find squashfs-root/usr/plugins/ -name "*.so" | sort

# Compare with system Qt6 plugins
find /usr/lib/x86_64-linux-gnu/qt6/plugins/ -name "*.so" | wc -l
```

#### Common Plugin Issues and Solutions

**Problem**: AppImage fails to start with Qt6 plugin errors or "No platform plugin" errors
```bash
# Symptoms: 
# - "qt.qpa.plugin: Could not find the Qt platform plugin"
# - "This application failed to start because no Qt platform plugin could be initialized"

# Diagnosis:
./validate-appimage.sh | grep -A 10 -B 5 "Qt Plugins"

# Solution 1: Install missing Qt6 packages
sudo apt-get update
sudo apt-get install qt6-base-dev qt6-tools-dev qt6-wayland qt6-wayland-dev

# Solution 2: Rebuild with comprehensive plugin copying
export STRICT_PLUGIN_VALIDATION=true
./build_appimage.sh -j $(nproc)

# Solution 3: Verify quirk_copy_qt6_plugins function executed
./build_appimage.sh -j $(nproc) 2>&1 | grep -i "copying qt6 plugins"
```

**Problem**: AppImage crashes on Wayland systems (Bazzite, Silverblue, immutable OS)
```bash
# Symptoms:
# - Works on X11 but crashes on Wayland
# - "Could not connect to Wayland display"
# - Segmentation fault on startup

# Diagnosis:
./validate-appimage.sh | grep -i wayland

# Solution: Ensure all Wayland plugins are present
sudo apt-get install qt6-wayland qt6-wayland-dev
./build_appimage.sh -j $(nproc)

# Verify Wayland plugin presence:
./output/mcpelauncher-ui-qt.AppImage --appimage-extract
ls -la squashfs-root/usr/plugins/wayland-*/
```

**Problem**: Missing WebEngine functionality (web views don't work)
```bash
# Symptoms:
# - Login screen doesn't load
# - Web-based features non-functional
# - "QWebEngineView" related errors

# Install WebEngine dependencies
sudo apt-get install qt6-webengine-dev qt6-webengine-data

# Rebuild with WebEngine support
./build_appimage.sh -j $(nproc)

# Verify WebEngine plugins
./output/mcpelauncher-ui-qt.AppImage --appimage-extract
ls -la squashfs-root/usr/plugins/webengine/
```

#### Advanced Plugin Troubleshooting

**Enable Strict Plugin Validation:**
```bash
# Force build to fail if critical plugins are missing
export STRICT_PLUGIN_VALIDATION=true
./build_appimage.sh -j $(nproc)
```

**Manual Plugin Verification:**
```bash
# Check if plugins are loadable
ldd squashfs-root/usr/plugins/platforms/libqxcb.so

# Verify plugin permissions
find squashfs-root/usr/plugins/ -name "*.so" ! -perm 755

# Test plugin compatibility
file squashfs-root/usr/plugins/platforms/*.so
```

**Debug Plugin Loading:**
```bash
# Run AppImage with Qt debug output
QT_LOGGING_RULES="qt.qpa.*=true" ./output/mcpelauncher-ui-qt.AppImage

# Check for missing dependencies
QT_DEBUG_PLUGINS=1 ./output/mcpelauncher-ui-qt.AppImage
```

### RPATH and Library Issues

**Problem**: AppImage fails to find bundled libraries
```bash
# Check RPATH configuration
readelf -d output/mcpelauncher-ui-qt.AppImage | grep -E "(RPATH|RUNPATH)"

# Validate library bundling
./validate-appimage.sh | grep -i "bundled libraries"

# Fix with proper RPATH (automatic in multilib.cmake)
```

### Permission Issues

**Problem**: Executables lack proper permissions
```bash
# Check AppImage permissions
./validate-appimage.sh | grep -i permissions

# Fix permissions manually (last resort)
chmod +x output/*.AppImage
```

### Official AppImage Reference (v1.1.1-802)

This build system aims to match the structure and functionality of the official Minecraft Bedrock Launcher AppImage v1.1.1-802:

- **Plugin Structure**: Complete Qt6 plugin directory hierarchy
- **Wayland Support**: Native Wayland protocol plugins for immutable OS compatibility  
- **WebEngine Integration**: Full Qt6 WebEngine plugin support
- **RPATH Configuration**: Portable library loading with `$ORIGIN` relative paths
- **Permission Model**: All binaries and libraries with correct executable/readable permissions

**Reference Analysis**:
```bash
# Analyze official AppImage structure (if available)
./analyze_official_appimage.sh /path/to/official-launcher-v1.1.1-802.AppImage

# Compare with built AppImage
./compare_builds.sh output/mcpelauncher-ui-qt.AppImage /path/to/official.AppImage
```

### Environment-Specific Issues

**Ubuntu 22.04 LTS**:
```bash
# Install required dependencies
sudo apt-get update
sudo apt-get install qt6-base-dev qt6-tools-dev qt6-wayland qt6-wayland-dev

# Build with environment validation
./build_appimage.sh -t x86_64 -m -n -o -j $(nproc) -q quirks-qt6.sh
```

**Fedora/Immutable OS (Bazzite)**:
```bash
# Enable Wayland support (critical for immutable OS)
export STRICT_PLUGIN_VALIDATION=true
./build_appimage.sh -t x86_64 -m -n -o -j $(nproc) -q quirks-qt6.sh

# Validate Wayland compatibility
./tests/test-qt6-plugin-validation.sh
```

**Cross-Distribution Testing**:
```bash
# Test AppImage compatibility across distributions
./ensure-appimage-compatibility.sh output/mcpelauncher-ui-qt.AppImage

# Run comprehensive validation
./run-comprehensive-validation.sh
```

### Demo Workflow
```bash
# See the complete build and validation workflow in action
./demo-workflow.sh
```

### Bazzite OS Compatibility Analysis
```bash
# Analyze official AppImage for debugging crashes on Bazzite OS
./run_comprehensive_analysis.sh

# Build Qt6 AppImage for modern systems
./build_appimage.sh -j $(nproc)
```

## Clean Restart Strategy

This repository implements a **clean restart strategy** that removes accumulated complexity:

- **Single Architecture**: x86_64 only, no multilib complexity
- **Single Workflow**: One GitHub Actions job  
- **Modern Base**: Ubuntu 22.04 LTS with Qt6 framework
- **Simplified Components**: MSA and 32-bit builds removed
- **Streamlined Files**: Architecture/platform-specific files removed

## Build Configuration

### Default Build Command
```bash
./build_appimage.sh -j $(nproc)
```

### Dependencies Installation (Ubuntu 22.04)

For Qt6 builds:
```bash
# Install Qt6 dependencies using the provided script
./install-qt6-deps.sh
```

Or manually:
```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential cmake git curl wget file ninja-build clang lld pkg-config \
  libc6-dev libssl-dev libcurl4-openssl-dev zlib1g-dev libpng-dev \
  libuv1-dev libzip-dev libglib2.0-dev \
  qt6-base-dev qt6-base-dev-tools qt6-tools-dev qt6-tools-dev-tools qmake6 \
  libqt6svg6-dev qt6-webengine-dev qt6-webengine-dev-tools \
  libqt6webenginecore6 libqt6webenginewidgets6 qt6-declarative-dev \
  qml6-module-qtquick-controls qml6-module-qtquick-layouts \
  qml6-module-qtquick-window qml6-module-qtquick-dialogs qml6-module-qtwebengine \
  qt6-wayland qt6-wayland-dev libqt6opengl6-dev \
  libgl1-mesa-dev libegl1-mesa-dev libgles2-mesa-dev \
  libx11-dev libxcursor-dev libxinerama-dev libxi-dev libxrandr-dev \
  libxtst6 libxss1 libasound2-dev libpulse-dev libudev-dev libevdev-dev libnss3-dev
```

## Quality Assurance

### Validation Scripts
- `integration-validation.sh` - Pre/post-build validation ensuring reproducibility and deterministic output
- `validate-appimage.sh` - Primary AppImage quality validation
- `ensure-appimage-compatibility.sh` - AppImage compatibility checker with system validation
- `build_gles30_validator.sh` - OpenGL ES 3.0 detection and validation tool
- `analyze-build-logs.sh` - Build performance and optimization analysis  
- `test-appimage-functionality.sh` - Runtime functionality testing
- `run-comprehensive-validation.sh` - Complete validation suite

### CI/CD Integration
The GitHub Actions workflow automatically:
1. Tests the build environment
2. Builds x86_64 AppImage with Qt6
3. Runs comprehensive validation suite
4. Uploads AppImage artifacts and validation reports

#### Fast Configuration Testing
The repository supports `DRY_RUN_CONFIGURE=1` mode to test CMake configuration without full compilation:

**DRY_RUN_CONFIGURE Mode:**
```bash
# Test CMake configuration only (no compilation/packaging)
DRY_RUN_CONFIGURE=1 ./build_appimage.sh -t x86_64 -n -m -j $(nproc) -q quirks-qt6.sh
```
This mode performs CMake configuration for all components but skips:
- Compilation (ninja/make build)
- Installation (make install)  
- Packaging (AppImage creation)

Perfect for CI validation of build configuration changes without the overhead of full compilation.

### Success Criteria
- ✅ **Build completed without errors or warnings**
- ✅ **AppImage is properly structured and functional**
- ✅ **All mcpelauncher components are correctly integrated**
- ✅ **Runtime execution works on target Ubuntu systems**
- ✅ **Minecraft Launcher functionality is preserved**

## APK Policy

**This project does not support APK importing.** 

As stated in the [official FAQ](https://minecraft-linux.github.io/faq/index.html#can-i-play-with-an-apk), any attempt to document workarounds or make it easy to import paid APKs without valid Google Play game licenses is undesirable and may cause project suspension.

Valid alternatives:
- Minecraft Trial (supported)
- Minecraft Education (limited support)

Game licenses can be revoked at any time by Microsoft/Mojang or Google.

## Project Links

- [mcpelauncher Documentation](https://mcpelauncher.readthedocs.io/)
- [Launcher Requirements](https://mcpelauncher.readthedocs.io/en/latest/source_build/launcher.html#prerequirements)
- [UI Requirements](https://mcpelauncher.readthedocs.io/en/latest/source_build/ui.html)
- **[Compatibility Guide](COMPATIBILITY.md)** - System requirements and troubleshooting
- [Validation Framework](VALIDATION.md)

## Analysis Tools

For debugging AppImage crashes on Bazzite OS (Fedora Atomic 42) with AMD Z1 Extreme APU:

- **[Analysis Tools Documentation](ANALYSIS_TOOLS.md)** - Complete guide to debugging tools
- `analyze_official_appimage.sh` - Downloads and analyzes official AppImage v1.1.1-802
- `compare_builds.sh` - Compares current build with official configuration
- `run_comprehensive_analysis.sh` - Complete analysis workflow
- `quirks-bazzite.sh` - Bazzite OS compatibility build configuration

### Quick Analysis
```bash
# Run complete analysis to identify crash causes
./run_comprehensive_analysis.sh

# View results
cat /tmp/appimage_analysis/comprehensive_analysis.txt
```
- [Validation Framework](VALIDATION.md)