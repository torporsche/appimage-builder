# AppImage Builder Analysis

## Repository Structure

This repository builds AppImages for the Minecraft PE Launcher components using shell scripts and CMake.

### Key Components
- **MSA (Microsoft Services Authentication)**: Authentication service for Xbox Live
- **MCPELauncher**: Core launcher for Minecraft Pocket Edition
- **MCPELauncher-UI**: Qt-based user interface

### Build Scripts
- `build.sh`: Main script for building debian packages
- `build_appimage.sh`: Script for creating AppImages with various options
- `common.sh`: Shared functions for build management
- `quirks-*.sh`: Platform-specific build configurations

### Architecture Support
- x86_64 (64-bit Intel/AMD)
- i386 (32-bit Intel/AMD) 
- ARM64 (64-bit ARM)
- ARMHF (32-bit ARM)

### Quirks Files
Different platforms require specific build configurations:
- `quirks-32.sh`: General 32-bit builds
- `quirks-ubuntu-1604.sh`: Ubuntu 16.04 64-bit
- `quirks-ubuntu-1604-32.sh`: Ubuntu 16.04 32-bit
- `quirks-bookworm.sh`: Debian Bookworm
- `quirks-buster.sh`: Debian Buster

## Build Process

### Dependencies
- CMake 3.0+
- C++11 compatible compiler (clang recommended)
- Qt5 development libraries
- OpenSSL development libraries
- protobuf compiler
- Various system libraries

### Building Manually

#### 64-bit build:
```bash
CC=clang CXX=clang++ ./build.sh
```

#### 32-bit build:
```bash
CC=clang CXX=clang++ ./build.sh -q quirks-32.sh
```

#### AppImage creation:
```bash
./build_appimage.sh -j $(nproc)
```

## GitHub Actions Status

### Previous Issue
The repository had GitHub Actions workflows that were intentionally deleted in commit `f08e37b` to stop nightly syncs. This caused "build" and "build32" job failures since no workflows existed.

### Solution
A new GitHub Actions workflow has been created at `.github/workflows/build.yml` that provides:
- **build**: x86_64 AppImage builds
- **build32**: i386 AppImage builds
- Timeout handling for long builds
- Artifact uploads for debugging
- Dependency installation for Ubuntu 20.04

## Known Issues
1. Builds may require specific Ubuntu/Debian versions for compatibility
2. 32-bit builds need multilib support and i386 packages
3. Qt5 WebEngine dependencies can be complex
4. OpenSSL version compatibility varies between platforms

## Commit References
- `msa.commit`: MSA component version
- `mcpelauncher.commit`: Core launcher version
- `mcpelauncher-ui.commit`: UI component version
- `mcpelauncher-qt6.commit`: Qt6 UI version
- `mcpelauncher-ui-qt6.commit`: Qt6 UI manifest version