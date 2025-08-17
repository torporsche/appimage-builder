# AppImage builder for mcpelauncher-linux

Clean, simplified AppImage builder focusing on x86_64 architecture with modern Qt6 framework support.

## Quick Start

This repository builds AppImages for the mcpelauncher-linux project using a simplified, single-architecture approach with Qt6 for improved compatibility and modern features.

### Build Requirements
- Ubuntu 22.04 LTS (or compatible)
- Qt6 development libraries (default) or Qt5 (legacy)
- clang compiler
- Standard build tools

### Local Build with Enhanced Validation
```bash
# 1. Test your environment with strict dependency validation
./test-dependencies.sh

# 2. Build Qt6 AppImage (x86_64 only, MSA disabled, no 32-bit) - RECOMMENDED
./build_appimage.sh -t x86_64 -m -n -o -j $(nproc) -q quirks-qt6.sh

# 3. Validate the built AppImage with comprehensive checks
./validate-appimage.sh

# 4. Run complete validation suite including functionality tests
./run-comprehensive-validation.sh

# 5. Check AppImage compatibility across distributions (NEW)
./ensure-appimage-compatibility.sh output/mcpelauncher-ui-qt.AppImage

# 6. Test OpenGL ES 3.0 support (NEW)
./build_gles30_validator.sh all
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

## Qt6 Migration

This repository now supports **Qt6 framework** as the primary build target, providing:

### **Benefits of Qt6 Build:**
- **Modern Graphics Support**: Enhanced OpenGL/Vulkan support for AMD graphics (Z1 Extreme, RDNA3)
- **Wayland Compatibility**: Native Wayland protocol support for immutable OS environments (Bazzite, Fedora Atomic)
- **OpenGL ES 3.0 Support**: Improved graphics compatibility with hardware acceleration and software fallbacks
- **Enhanced Validation**: Comprehensive compatibility checking and dependency validation
- **Performance Improvements**: Qt6's optimized rendering pipeline and memory management
- **Security Updates**: Current security patches and vulnerability fixes
- **Future Compatibility**: Alignment with upstream mcpelauncher development direction

### **Build Variants:**
- **Qt6 (Default)**: `./build_appimage.sh -t x86_64 -m -n -o -q quirks-qt6.sh`
- **Qt5 (Legacy)**: `./build_appimage.sh -t x86_64 -m -n -q quirks-modern.sh`

### **Target Environment Compatibility:**
- **Bazzite OS** (Fedora Atomic 42 + AMD Z1 Extreme): Qt6 with Wayland support
- **Ubuntu 22.04+**: Both Qt6 and Qt5 supported
- **Immutable OS**: Qt6 provides better compatibility with read-only filesystems

### Validation Framework

This repository includes a comprehensive **AppImage Validation Framework** that ensures production readiness:

- **Build Success Verification**: Confirms all build phases completed without errors
- **AppImage Quality Assessment**: Binary integrity, dependency bundling, size optimization  
- **Component Integration Testing**: mcpelauncher components, Qt6/Qt5 GUI, OpenGL validation
- **Cross-Platform Compatibility**: GLIBC version checks, library compatibility testing
- **Security Assessment**: Basic security validation and vulnerability checks
- **Performance Benchmarks**: Startup time, file size, extraction performance

See [VALIDATION.md](VALIDATION.md) for complete documentation.

## Troubleshooting

### Qt6 Plugin Issues

**Problem**: AppImage fails to start with Qt6 plugin errors
```bash
# Verify Qt6 plugins are properly packaged
./tests/test-qt6-plugin-validation.sh

# Check for missing Wayland plugins (common on immutable OS)
./validate-appimage.sh | grep -i wayland

# Install missing Qt6 dependencies
sudo apt-get install qt6-base-dev qt6-tools-dev qt6-wayland qt6-wayland-dev
```

**Problem**: Missing WebEngine functionality
```bash
# Install WebEngine dependencies
sudo apt-get install qt6-webengine-dev qt6-webengine-data

# Rebuild with WebEngine support
./build_appimage.sh -t x86_64 -m -n -o -j $(nproc) -q quirks-qt6.sh
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

# Build with Qt6 for Bazzite OS compatibility (recommended)
./build_appimage.sh -t x86_64 -m -n -o -j $(nproc) -q quirks-qt6.sh

# Build with legacy Qt5 for older environments
./build_appimage.sh -t x86_64 -m -n -j $(nproc) -q quirks-modern.sh
```

## Clean Restart Strategy

This repository implements a **clean restart strategy** that removes accumulated complexity from multiple LLM agent revisions:

- **Single Architecture**: x86_64 only, no multilib complexity
- **Single Workflow**: One GitHub Actions job instead of three  
- **Modern Base**: Ubuntu 22.04 LTS with Qt6 framework (Qt5 legacy support available)
- **Components Disabled**: MSA and 32-bit builds disabled by default
- **Files Removed**: 10 architecture/platform-specific files cleaned up

## Build Configuration

### Default Build Flags
- `-t x86_64`: Target x86_64 architecture only
- `-m`: Disable MSA component builds  
- `-n`: Disable 32-bit mcpelauncher-client builds
- `-q quirks-qt6.sh`: Use Qt6-optimized build quirks

### Dependencies Installation (Ubuntu 22.04)

For Qt6 builds (recommended):
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

For Qt5 builds (legacy):
```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential cmake git curl wget file ninja-build clang lld pkg-config \
  libc6-dev libssl-dev libcurl4-openssl-dev zlib1g-dev libpng-dev \
  libuv1-dev libzip-dev libglib2.0-dev \
  qtbase5-dev qtbase5-dev-tools qttools5-dev qttools5-dev-tools qt5-qmake \
  libqt5svg5-dev qtwebengine5-dev qtwebengine5-dev-tools \
  libqt5webenginecore5 libqt5webenginewidgets5 qtdeclarative5-dev \
  qml-module-qtquick-controls2 qml-module-qtquick-layouts \
  qml-module-qtquick-window2 qml-module-qtquick-dialogs qml-module-qtwebengine \
  libgl1-mesa-dev libegl1-mesa-dev libgles2-mesa-dev \
  libx11-dev libxcursor-dev libxinerama-dev libxi-dev libxrandr-dev \
  libxtst6 libxss1 libasound2-dev libpulse-dev libudev-dev libevdev-dev libnss3-dev
```

## Quality Assurance

### Validation Scripts
- `integration-validation.sh` - **NEW** Pre/post-build validation ensuring reproducibility and deterministic output
- `validate-appimage.sh` - Primary AppImage quality validation
- `ensure-appimage-compatibility.sh` - **NEW** AppImage compatibility checker with system validation
- `build_gles30_validator.sh` - **NEW** OpenGL ES 3.0 detection and validation tool
- `analyze-build-logs.sh` - Build performance and optimization analysis  
- `test-appimage-functionality.sh` - Runtime functionality testing
- `run-comprehensive-validation.sh` - Complete validation suite

### CI/CD Integration
The GitHub Actions workflow automatically:
1. Tests the build environment
2. Builds x86_64 AppImage with MSA and 32-bit disabled
3. Runs comprehensive validation suite
4. Uploads AppImage artifacts and validation reports

#### CI Matrix Testing
The repository includes a CI matrix workflow that tests critical build configurations:
- **Qt Versions**: Qt5 (legacy) and Qt6 (modern)
- **MSA Options**: Enabled and disabled
- **Fast Configuration Testing**: Uses `DRY_RUN_CONFIGURE=1` mode to test CMake configuration without full compilation

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
- [MSA Requirements](https://mcpelauncher.readthedocs.io/en/latest/source_build/msa.html#prerequirements) (disabled by default)
- [Launcher Requirements](https://mcpelauncher.readthedocs.io/en/latest/source_build/launcher.html#prerequirements)
- [UI Requirements](https://mcpelauncher.readthedocs.io/en/latest/source_build/ui.html)
- **[Compatibility Guide](COMPATIBILITY.md)** - **NEW** System requirements and troubleshooting
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