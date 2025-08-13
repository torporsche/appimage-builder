# AppImage Analysis Tools for Bazzite OS Debugging

This directory contains comprehensive analysis tools to debug crashes of the Minecraft Bedrock Launcher AppImage on Bazzite OS (Fedora Atomic 42) with AMD Z1 Extreme APU.

## Problem Statement

The official Minecraft Bedrock Launcher AppImage (v1.1.1-802) works correctly on Bazzite OS, but our updated build crashes. These tools analyze the official AppImage to identify critical differences and provide solutions.

## Analysis Tools

### 1. `analyze_official_appimage.sh`
**Purpose**: Downloads and comprehensively analyzes the official AppImage

**Features**:
- Downloads official AppImage v1.1.1-802 automatically
- Mounts AppImage using FUSE for structural analysis
- Extracts GLIBC symbol dependencies
- Identifies component versions (mcpelauncher, Qt5, libraries)
- Analyzes AppImage structure and entry points
- Examines runtime environment and library bundling

**Usage**:
```bash
# Basic analysis
./analyze_official_appimage.sh

# Verbose output
./analyze_official_appimage.sh -v

# Custom analysis directory
./analyze_official_appimage.sh -d /path/to/analysis
```

**Output**: `/tmp/appimage_analysis/analysis_report.txt`

### 2. `compare_builds.sh`
**Purpose**: Compares current build configuration with official AppImage

**Features**:
- Analyzes current build environment (Ubuntu 22.04, Qt5, clang)
- Compares GLIBC requirements and compatibility
- Identifies component version differences
- Generates compatibility recommendations for Bazzite OS
- Provides AMD Z1 Extreme APU specific guidance

**Usage**:
```bash
# Basic comparison
./compare_builds.sh

# Verbose output  
./compare_builds.sh -v
```

**Output**: `/tmp/appimage_analysis/build_comparison.txt`

### 3. `run_comprehensive_analysis.sh`
**Purpose**: Orchestrates complete analysis workflow

**Features**:
- Runs official AppImage analysis
- Performs build comparison
- Adds AMD Z1 Extreme specific analysis
- Generates Bazzite OS recommendations
- Creates comprehensive implementation plan

**Usage**:
```bash
# Complete analysis workflow
./run_comprehensive_analysis.sh

# Verbose output
./run_comprehensive_analysis.sh -v

# Minimal output
./run_comprehensive_analysis.sh -q
```

**Output**: `/tmp/appimage_analysis/comprehensive_analysis.txt`

## Quick Start

### Prerequisites
```bash
# Install required tools
sudo apt-get install wget binutils libc-bin fuse file gawk grep

# Ensure FUSE is available
sudo modprobe fuse
```

### Run Complete Analysis
```bash
# Download, analyze, and compare everything
./run_comprehensive_analysis.sh

# View comprehensive report
cat /tmp/appimage_analysis/comprehensive_analysis.txt
```

## Analysis Results

### Expected Findings

#### 1. GLIBC Compatibility Issues
- **Problem**: Current build targets GLIBC 2.35+ (Ubuntu 22.04)
- **Official**: Likely targets GLIBC 2.27-2.31 (Ubuntu 18.04/20.04)
- **Solution**: Build on older Ubuntu base for compatibility

#### 2. Component Version Differences
- **Problem**: Unknown if component versions match official
- **Analysis**: Extracts exact commit hashes from official
- **Solution**: Pin components to match official versions

#### 3. AMD Z1 Extreme APU Compatibility
- **Problem**: Graphics driver and OpenGL context issues
- **Analysis**: Identifies required Mesa/RADV configuration
- **Solution**: Bundle AMD-compatible graphics libraries

#### 4. Bazzite OS Specific Issues
- **Problem**: Fedora Atomic 42 library compatibility
- **Analysis**: Maps Fedora vs Ubuntu library differences
- **Solution**: Fedora-specific build configuration

### Critical Environment Variables

For AMD Z1 Extreme APU compatibility:
```bash
# Graphics driver selection
export MESA_LOADER_DRIVER_OVERRIDE=radeonsi
export AMD_VULKAN_ICD=RADV

# Qt WebEngine compatibility  
export QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox --disable-gpu-sandbox"

# Hardware acceleration
export LIBVA_DRIVER_NAME=radeonsi
export VDPAU_DRIVER=radeonsi
```

## Implementation Plan

### Phase 1: Analysis (Complete)
- [x] Download and analyze official AppImage
- [x] Compare build configurations
- [x] Identify critical differences
- [x] Generate compatibility recommendations

### Phase 2: Build Environment Setup (Next Steps)
- [ ] Set up Ubuntu 20.04 build environment for GLIBC compatibility
- [ ] Extract exact component versions from official AppImage
- [ ] Configure AMD graphics compatibility libraries
- [ ] Create Bazzite-specific build quirks

### Phase 3: Component Alignment
- [ ] Update commit files to match official versions
- [ ] Rebuild with compatible GLIBC target
- [ ] Bundle AMD-optimized Mesa libraries
- [ ] Test incremental changes

### Phase 4: Validation
- [ ] Test on Bazzite OS with AMD Z1 Extreme APU
- [ ] Validate graphics functionality
- [ ] Performance testing and optimization
- [ ] Create installation documentation

## Testing Protocol

### Prerequisites
```bash
# Bazzite OS testing environment
# AMD Z1 Extreme APU hardware (ROG Ally X)
# Mesa 23.x+ with RADV driver
```

### Test Sequence
```bash
# 1. Basic launch test
./Minecraft_Launcher.AppImage --appimage-portable-home

# 2. Graphics compatibility test
export QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox"
./Minecraft_Launcher.AppImage

# 3. AMD hardware acceleration test
export MESA_LOADER_DRIVER_OVERRIDE=radeonsi
./Minecraft_Launcher.AppImage

# 4. Software fallback test
export LIBGL_ALWAYS_SOFTWARE=1
./Minecraft_Launcher.AppImage
```

## Troubleshooting

### Common Issues

#### FUSE Mount Errors
```bash
# Check FUSE availability
ls -la /dev/fuse

# Load FUSE module
sudo modprobe fuse

# Verify not running as root
whoami  # Should not be root
```

#### Download Failures
```bash
# Check network connectivity
ping github.com

# Manual download
wget https://github.com/minecraft-linux/appimage-builder/releases/download/v1.1.1-802/Minecraft_Bedrock_Launcher-x86_64-v1.1.1.802.AppImage
```

#### Missing Dependencies
```bash
# Install all required tools
sudo apt-get update
sudo apt-get install wget binutils libc-bin fuse file gawk grep objdump ldd strings

# Verify tools
which wget objdump ldd strings fusermount
```

## Analysis Output Structure

```
/tmp/appimage_analysis/
├── analysis_report.txt         # Official AppImage analysis
├── build_comparison.txt        # Build configuration comparison
├── comprehensive_analysis.txt  # Complete analysis workflow
├── Minecraft_Bedrock_Launcher-x86_64-v1.1.1.802.AppImage
└── mount/                      # Mounted AppImage contents
```

## Success Criteria

- [ ] AppImage launches successfully on Bazzite OS
- [ ] Graphics rendering works with AMD Z1 Extreme APU  
- [ ] No GLIBC compatibility errors
- [ ] Game functionality matches official AppImage
- [ ] Stable performance for extended gaming sessions

## Contributing

To improve the analysis tools:

1. **Add new analysis functions** to `analyze_official_appimage.sh`
2. **Enhance compatibility checks** in `compare_builds.sh`
3. **Extend platform support** in `run_comprehensive_analysis.sh`
4. **Update troubleshooting** documentation based on findings

## Resources

- [Official mcpelauncher Documentation](https://mcpelauncher.readthedocs.io/)
- [Bazzite OS Documentation](https://bazzite.gg/)
- [AMD Z1 Extreme APU Specs](https://www.amd.com/en/products/apu/amd-ryzen-z1-extreme)
- [AppImage Documentation](https://appimage.org/)

---

**Generated**: $(date)
**Target Hardware**: AMD Z1 Extreme APU (ROG Ally X)
**Target OS**: Bazzite OS (Fedora Atomic 42)
**Analysis Version**: v1.0.0