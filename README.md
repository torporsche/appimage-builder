# AppImage builder for mcpelauncher-linux

Clean, simplified AppImage builder focusing on x86_64 architecture with modern Qt6 framework support.

## Quick Start

This repository builds AppImages for the mcpelauncher-linux project using a simplified, single-architecture approach with Qt6 for improved compatibility and modern features.

### Build Requirements
- Ubuntu 22.04 LTS (or compatible)
- Qt6 development libraries (default) or Qt5 (legacy)
- clang compiler
- Standard build tools

### Local Build
```bash
# Test your environment
./test-dependencies.sh

# Build Qt6 AppImage (x86_64 only, MSA disabled, no 32-bit) - RECOMMENDED
./build_appimage.sh -t x86_64 -m -n -o -j $(nproc) -q quirks-qt6.sh

# Build Qt5 AppImage (legacy compatibility)
./build_appimage.sh -t x86_64 -m -n -j $(nproc) -q quirks-modern.sh

# Validate the built AppImage
./run-comprehensive-validation.sh
```

## Qt6 Migration

This repository now supports **Qt6 framework** as the primary build target, providing:

### **Benefits of Qt6 Build:**
- **Modern Graphics Support**: Enhanced OpenGL/Vulkan support for AMD graphics (Z1 Extreme, RDNA3)
- **Wayland Compatibility**: Native Wayland protocol support for immutable OS environments (Bazzite, Fedora Atomic)
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

### Demo Workflow
```bash
# See the complete build and validation workflow in action
./demo-workflow.sh
```

### Bazzite OS Compatibility Analysis
```bash
# Install Qt6 development environment (if not already installed)
./install-qt6-dependencies.sh

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
- `-q quirks-modern.sh`: Use simplified build quirks

### Dependencies Installation (Ubuntu 22.04)
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
- `validate-appimage.sh` - Primary AppImage quality validation
- `analyze-build-logs.sh` - Build performance and optimization analysis  
- `test-appimage-functionality.sh` - Runtime functionality testing
- `run-comprehensive-validation.sh` - Complete validation suite

### CI/CD Integration
The GitHub Actions workflow automatically:
1. Tests the build environment
2. Builds x86_64 AppImage with MSA and 32-bit disabled
3. Runs comprehensive validation suite
4. Uploads AppImage artifacts and validation reports

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