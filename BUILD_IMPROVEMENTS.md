# Clean Restart Strategy: Simplified x86_64 AppImage Builder

This document outlines the clean restart strategy implemented to simplify the build system while maintaining modern dependencies.

## Strategy Overview

After multiple LLM agent revisions introduced complexity and potential conflicts, this implementation provides a clean restart by:

1. **Single Architecture Focus**: x86_64 only, no multilib complexity
2. **Simplified Workflow**: One GitHub Actions job instead of three
3. **Disabled Components**: MSA disabled, 32-bit builds disabled  
4. **Modern Base**: Ubuntu 22.04 LTS with Qt6
5. **Reduced File Count**: 10 architecture/platform-specific files removed

## Key Simplifications

### GitHub Actions Workflow
- **Before**: 3 separate jobs (build-x86_64, build-x86_64-qt5, build-x86)
- **After**: 1 job (build-x86_64) on Ubuntu 22.04 with Qt5
- **Dependencies**: Consolidated into single installation step
- **No multilib**: Removed all i386 architecture setup and gcc-multilib

### Build Configuration
- **MSA Component**: Disabled by default using `-m` flag
- **32-bit Builds**: Disabled by default using `-n` flag  
- **Qt Version**: Focus on Qt5 for mcpelauncher-ui compatibility
- **Target**: x86_64 only using `-t x86_64` flag

### Simplified File Structure
Removed architecture-specific files:
- `arm64toolchain.txt`, `armhftoolchain.txt` (ARM support)
- `quirks-32.sh`, `quirks-ubuntu-1604-32.sh` (32-bit support)
- `quirks-buster.sh`, `quirks-ubuntu-1604.sh` (legacy platforms)
- `mcpelauncher-qt6.commit`, `mcpelauncher-ui-qt6.commit` (Qt6 variants)
- `sources.list.focal` (Ubuntu 20.04 specific)

### Modernized quirks-modern.sh
- **x86_64 Only**: Hardcoded x86_64 library paths, no dynamic architecture detection
- **Qt5 Focus**: Removed Qt6 version detection and configuration
- **No 32-bit**: Removed quirk_build_mcpelauncher32() function
- **MSA Disabled**: quirk_build_msa() does nothing and returns immediately

## Build Command

The simplified build command is:
```bash
./build_appimage.sh -t x86_64 -m -n -j ${MAKE_JOBS} -q quirks-modern.sh
```

Where:
- `-t x86_64`: Target x86_64 architecture only
- `-m`: Disable MSA component builds
- `-n`: Disable mcpelauncher-client32 for 64-bit targets
- `-o`: Build Qt6 AppImage with Wayland support  
- `-q quirks-qt6.sh`: Use Qt6-optimized quirks file

## Dependencies (Ubuntu 22.04)

All dependencies installed in one step:
```bash
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

## Benefits

### Reduced Complexity
- **75% fewer CI jobs** (3 → 1)
- **10 fewer platform files** removed
- **No multilib conflicts** or retry logic needed
- **Single Qt version** reduces configuration complexity

### Improved Maintainability  
- **Clear focus** on x86_64 with Qt6
- **Disabled problematic components** (MSA, 32-bit)
- **Modern base** (Ubuntu 22.04) with current packages
- **Simplified troubleshooting** with single build path

### Modern Foundation
- **Ubuntu 22.04 LTS**: Latest long-term support base
- **Qt5**: Stable, well-supported Qt version
- **clang**: Modern compiler with better diagnostics
- **Ninja**: Fast build system

## Component Versions

Using existing commit versions for stability:
- `mcpelauncher.commit`: 298806f6b404afce9d9621ae689db1a9f91dcc05
- `mcpelauncher-ui.commit`: bcf5858a63ff48414eb6d46d360787bcde6da9eb  
- `msa.commit`: cfcebaa0845df8e0eebaae5b211e38f8d812beab (disabled)

## Usage

### Local Development
```bash
# Test dependencies
./test-dependencies.sh

# Build AppImage for x86_64 only
./build_appimage.sh -t x86_64 -m -n -o -j $(nproc) -q quirks-qt6.sh
```

### CI/CD Pipeline
The GitHub Actions workflow automatically:
1. Sets up Ubuntu 22.04 with Qt5 dependencies
2. Tests the build environment
3. Builds x86_64 AppImage with MSA and 32-bit disabled
4. Uploads artifacts

This implementation provides a clean, maintainable foundation for AppImage builds while removing accumulated technical debt from multiple revision cycles.vision cycles.