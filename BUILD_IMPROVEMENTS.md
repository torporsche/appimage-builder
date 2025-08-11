# Build System Improvements for x86-64 Architecture

This document outlines the improvements made to fix build job issues for x86-64 architecture builds.

## Issues Addressed

1. **Dependency Version Mismatches**: The build was failing due to incompatible dependencies and missing packages.
2. **Qt Compatibility Issues**: The code needed updates to work with newer versions of Qt.
3. **CMake Configuration Issues**: Build flags needed updates for modern compilers.
4. **Library Path Problems**: Library search paths needed correction.

## Changes Implemented

### 1. GitHub Actions Workflow (`.github/workflows/build.yml`)

Created a comprehensive CI/CD workflow with:

- **Dual Qt Support**: Separate jobs for Qt5 (Ubuntu 20.04) and Qt6 (Ubuntu 22.04)
- **Complete Dependencies**: All required libraries including:
  - Qt6/Qt5 base, tools, and WebEngine components
  - OpenGL and graphics libraries
  - Audio libraries (ALSA, PulseAudio)
  - Development tools (clang, ninja, cmake)
  - 32-bit support libraries for multilib builds
- **Dependency Validation**: Built-in testing to verify environment setup
- **Artifact Collection**: Automatic upload of built AppImages and zsync files

### 2. Enhanced Build Script (`build_appimage.sh`)

Improved the build process with:

- **Modern Compiler Flags**: Added C++17 standard, `-fPIC`, `-O2` optimization
- **Enhanced x86_64 Configuration**: Better library search paths and 32-bit compatibility
- **Improved CMake Options**: Position-independent code and proper library detection
- **Better Architecture Handling**: Enhanced library paths for both x86_64 and i386

### 3. Quirks Files Enhancement

#### Updated `quirks-bookworm.sh`:
- Added Qt6 WebEngine support with proper CMake module detection
- Modern C++17 standard and compiler flags
- Enhanced library path configuration

#### New `quirks-modern.sh`:
- Comprehensive compatibility fixes for Ubuntu 20.04+
- Automatic Qt version detection (Qt5/Qt6)
- Enhanced WebEngine integration
- Improved library path resolution for both 64-bit and 32-bit builds
- Modern compiler flag management with automatic clang/gcc detection

### 4. Build System Infrastructure

#### Enhanced Error Handling (`common.sh`):
- Better debugging output for failed commands
- Clearer error messages with command details

#### Dependency Validation (`test-dependencies.sh`):
- Comprehensive testing of build environment
- Qt detection and verification
- Library availability checks
- 32-bit compilation support validation

#### Updated `.gitignore`:
- Prevents temporary build artifacts from being committed
- Covers all build directories and generated files

## Technical Benefits

### Dependency Management
- **Comprehensive Package Installation**: Covers all required Qt, OpenGL, audio, and development libraries
- **Version Compatibility**: Separate environments for Qt5 and Qt6 ensure compatibility
- **32-bit Support**: Full multilib configuration for 32-bit launcher builds

### Qt Compatibility
- **Automatic Version Detection**: Build system adapts to available Qt version
- **WebEngine Integration**: Proper CMake module detection for Qt WebEngine components
- **Cross-version Support**: Works with both Qt5 and Qt6 installations

### CMake Configuration
- **Modern Standards**: C++17 compliance for better toolchain compatibility
- **Enhanced Library Detection**: Improved CMake module finding and library path resolution
- **Position-Independent Code**: Better shared library support
- **Optimized Build**: Release configuration with proper optimization flags

### Library Path Resolution
- **Architecture-Specific Paths**: Proper handling of x86_64 and i386 library locations
- **Multiple Search Paths**: Comprehensive library search configuration
- **Dynamic Detection**: Runtime detection of available libraries and paths

## Usage

### Local Development
```bash
# Test dependencies
./test-dependencies.sh

# Build Qt6 AppImage for x86_64
./build_appimage.sh -t x86_64 -o -j $(nproc) -q quirks-modern.sh

# Build Qt5 AppImage for x86_64
./build_appimage.sh -t x86_64 -j $(nproc) -q quirks-modern.sh
```

### CI/CD Pipeline
The GitHub Actions workflow automatically:
1. Sets up the build environment with all dependencies
2. Validates the environment with dependency tests
3. Builds both Qt5 and Qt6 versions
4. Uploads artifacts for distribution

## Compatibility

- **Ubuntu 20.04+**: Full support with Qt5/Qt6
- **Debian Bookworm+**: Qt6 support with enhanced configuration
- **x86_64 Architecture**: Primary target with 32-bit launcher support
- **Modern Toolchains**: GCC 9+ and Clang 10+ compatibility

## Testing

The build system includes comprehensive testing:
- **Dependency validation** before builds
- **CMake module detection** for Qt components
- **Library availability checks** for all required components
- **32-bit compilation support** verification
- **Error handling validation** for build failures

This implementation provides a robust, modern build system that addresses all identified issues while maintaining compatibility with existing component repositories and providing better debugging capabilities.