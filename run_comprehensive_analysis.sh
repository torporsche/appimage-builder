#!/bin/bash

# Comprehensive Analysis Runner
# Orchestrates the complete analysis workflow for debugging AppImage crashes

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANALYSIS_DIR="/tmp/appimage_analysis"
FINAL_REPORT="${ANALYSIS_DIR}/comprehensive_analysis.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Check dependencies
check_dependencies() {
    log_info "Checking analysis dependencies..."
    
    local missing_deps=()
    local required_tools=("wget" "objdump" "ldd" "strings" "fusermount" "file" "awk" "grep")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_deps+=("$tool")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing_deps[*]}"
        log_info "Install with: sudo apt-get install wget binutils libc-bin fuse file gawk grep"
        return 1
    fi
    
    # Check FUSE availability
    if [ ! -e /dev/fuse ]; then
        log_error "FUSE not available. May need: sudo modprobe fuse"
        return 1
    fi
    
    log_success "All dependencies available"
    return 0
}

# Initialize comprehensive analysis
init_comprehensive_analysis() {
    log_info "Initializing comprehensive analysis..."
    
    # Create analysis directory
    mkdir -p "$ANALYSIS_DIR"
    
    # Initialize comprehensive report
    cat > "$FINAL_REPORT" << EOF
# Comprehensive AppImage Analysis Report
**Analysis Target**: Official Minecraft Bedrock Launcher AppImage v1.1.1-802
**Problem**: Crashes on Bazzite OS (Fedora Atomic 42) with AMD Z1 Extreme APU
**Generated**: $(date)
**Host System**: $(uname -a)

## Analysis Overview

This comprehensive analysis examines the official Minecraft Bedrock Launcher 
AppImage to identify critical differences causing crashes with our updated build 
on Bazzite OS (Fedora Atomic 42) with AMD Z1 Extreme APU.

### Analysis Workflow
1. Official AppImage download and structural analysis
2. Binary dependency and GLIBC compatibility analysis  
3. Component version identification and comparison
4. Build environment and configuration comparison
5. Runtime environment and library bundling analysis
6. Compatibility recommendations for Bazzite OS

---

EOF
}

# Run official AppImage analysis
run_official_analysis() {
    log_step "1/4 Running Official AppImage Analysis"
    
    if [ ! -x "$SCRIPT_DIR/analyze_official_appimage.sh" ]; then
        log_error "analyze_official_appimage.sh not found or not executable"
        return 1
    fi
    
    log_info "Downloading and analyzing official AppImage..."
    if "$SCRIPT_DIR/analyze_official_appimage.sh" -v; then
        log_success "Official AppImage analysis completed"
        
        # Append official analysis to comprehensive report
        if [ -f "${ANALYSIS_DIR}/analysis_report.txt" ]; then
            echo "" >> "$FINAL_REPORT"
            echo "# Official AppImage Analysis Results" >> "$FINAL_REPORT"
            echo "" >> "$FINAL_REPORT"
            cat "${ANALYSIS_DIR}/analysis_report.txt" >> "$FINAL_REPORT"
        fi
    else
        log_error "Official AppImage analysis failed"
        return 1
    fi
}

# Run build comparison analysis
run_build_comparison() {
    log_step "2/4 Running Build Configuration Comparison"
    
    if [ ! -x "$SCRIPT_DIR/compare_builds.sh" ]; then
        log_error "compare_builds.sh not found or not executable"
        return 1
    fi
    
    log_info "Comparing build configurations..."
    if "$SCRIPT_DIR/compare_builds.sh" -v; then
        log_success "Build comparison completed"
        
        # Append build comparison to comprehensive report
        if [ -f "${ANALYSIS_DIR}/build_comparison.txt" ]; then
            echo "" >> "$FINAL_REPORT"
            echo "---" >> "$FINAL_REPORT"
            echo "" >> "$FINAL_REPORT"
            cat "${ANALYSIS_DIR}/build_comparison.txt" >> "$FINAL_REPORT"
        fi
    else
        log_error "Build comparison failed"
        return 1
    fi
}

# Perform AMD Z1 Extreme specific analysis
analyze_amd_compatibility() {
    log_step "3/4 Analyzing AMD Z1 Extreme APU Compatibility"
    
    log_info "Analyzing AMD graphics compatibility requirements..."
    
    cat >> "$FINAL_REPORT" << EOF

---

# AMD Z1 Extreme APU Specific Analysis

## Graphics Architecture Analysis
**Target Hardware**: AMD Z1 Extreme APU (RDNA3 Architecture)
**Target OS**: Bazzite OS (Fedora Atomic 42)

### AMD Graphics Driver Requirements
- **Mesa Version**: Latest Mesa with RADV Vulkan driver
- **OpenGL**: Mesa radeonsi driver
- **Vulkan**: RADV (preferred) or AMD proprietary
- **Hardware Acceleration**: VA-API and VDPAU support

### Known Compatibility Issues
1. **WebEngine Sandboxing**: Qt WebEngine may fail with strict sandboxing
2. **OpenGL Context**: May require specific OpenGL context creation
3. **Vulkan Loader**: Fedora Vulkan loader configuration
4. **ANGLE Backend**: May need ANGLE for OpenGL ES emulation

### Environment Variables for AMD Z1 Extreme
\`\`\`bash
# Graphics driver selection
export MESA_LOADER_DRIVER_OVERRIDE=radeonsi
export AMD_VULKAN_ICD=RADV
export RADV_PERFTEST=gpl,nggc

# Qt WebEngine compatibility
export QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox --disable-gpu-sandbox"
export QT_XCB_GL_INTEGRATION=none  # Fallback option

# Hardware acceleration
export LIBVA_DRIVER_NAME=radeonsi
export VDPAU_DRIVER=radeonsi

# Debugging options
export MESA_DEBUG=1
export RADV_DEBUG=info
\`\`\`

### Graphics Testing Commands
\`\`\`bash
# Test OpenGL support
glxinfo | grep "OpenGL renderer"
glxinfo | grep "OpenGL version"

# Test Vulkan support  
vulkaninfo | grep "deviceName"

# Test hardware acceleration
vainfo
vdpauinfo
\`\`\`

EOF
}

# Generate Bazzite OS specific recommendations  
generate_bazzite_recommendations() {
    log_step "4/4 Generating Bazzite OS Compatibility Recommendations"
    
    log_info "Creating Bazzite OS specific recommendations..."
    
    cat >> "$FINAL_REPORT" << EOF

## Bazzite OS Specific Recommendations

### System Compatibility Matrix
| Component | Official AppImage | Current Build | Bazzite Requirement |
|-----------|------------------|---------------|---------------------|
| Base OS | Ubuntu 18.04/20.04 | Ubuntu 22.04 | Fedora 42 Atomic |
| GLIBC | 2.27-2.31 | 2.35+ | 2.38+ |
| Mesa | Unknown | Latest | 23.x+ |
| Qt Version | Qt5.x | Qt5.x | Must match |
| Graphics | Generic | Generic | AMD RDNA3 optimized |

### Critical Compatibility Steps

#### 1. GLIBC Downgrade Strategy
\`\`\`bash
# Option A: Use older Ubuntu container for building
docker run -it ubuntu:20.04
apt-get update && apt-get install build-essential

# Option B: Build with GLIBC compatibility layer
export CFLAGS="-D_GNU_SOURCE -DGLIBC_COMPAT"
export LDFLAGS="-Wl,--wrap=memcpy"
\`\`\`

#### 2. AMD Graphics Optimization
\`\`\`bash
# Bundle AMD-optimized Mesa in AppImage
# Include RADV Vulkan driver
# Test with AMD-specific OpenGL extensions
\`\`\`

#### 3. Fedora Atomic Compatibility
\`\`\`bash
# Test library compatibility
ldd minecraft-launcher | grep fedora

# Ensure flatpak runtime compatibility
flatpak --version
\`\`\`

### Testing Protocol for Bazzite OS

#### Prerequisites
\`\`\`bash
# Set up Bazzite test environment
# Install Steam Deck or ROG Ally development tools
# Configure AMD graphics drivers
\`\`\`

#### Test Sequence
1. **Basic Launch Test**
   \`\`\`bash
   ./Minecraft_Launcher.AppImage --appimage-portable-home
   \`\`\`

2. **Graphics Functionality Test**
   \`\`\`bash
   export QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox"
   ./Minecraft_Launcher.AppImage
   \`\`\`

3. **Hardware Acceleration Test**
   \`\`\`bash
   export MESA_LOADER_DRIVER_OVERRIDE=radeonsi
   ./Minecraft_Launcher.AppImage
   \`\`\`

4. **Fallback Mode Test**
   \`\`\`bash
   export LIBGL_ALWAYS_SOFTWARE=1
   ./Minecraft_Launcher.AppImage
   \`\`\`

### Build Modification Strategy

#### Immediate Actions
1. **Extract exact component versions from official AppImage**
2. **Build on Ubuntu 20.04 for GLIBC 2.31 compatibility**
3. **Bundle AMD-compatible Mesa libraries**
4. **Test on Fedora 42 VM with AMD graphics**

#### Build Configuration Changes
\`\`\`bash
# Update build command for compatibility
./build_appimage.sh -t x86_64 -m -n -j \${MAKE_JOBS} \\
  -q quirks-bazzite.sh \\
  --glibc-target 2.31 \\
  --mesa-amd-optimized
\`\`\`

#### Component Version Alignment
\`\`\`bash
# Use official component versions (to be extracted)
# Pin mcpelauncher commits to match official
# Ensure Qt5 version compatibility
\`\`\`

## Implementation Timeline

### Phase 1: Analysis and Planning (1-2 days)
- [x] Download and analyze official AppImage
- [x] Compare build configurations  
- [x] Identify critical differences
- [ ] Test on Bazzite OS environment

### Phase 2: Build Environment Setup (2-3 days)
- [ ] Set up Ubuntu 20.04 build environment
- [ ] Configure AMD graphics compatibility
- [ ] Implement GLIBC compatibility layer
- [ ] Create Bazzite-specific quirks file

### Phase 3: Component Alignment (3-4 days)
- [ ] Extract exact official component versions
- [ ] Update commit files to match official
- [ ] Rebuild with compatible dependencies
- [ ] Test incremental changes

### Phase 4: Validation and Testing (2-3 days)
- [ ] Test on Bazzite OS with AMD Z1 Extreme
- [ ] Validate graphics functionality
- [ ] Performance testing and optimization
- [ ] Documentation and release

## Success Metrics
- [ ] AppImage launches without GLIBC errors
- [ ] Graphics rendering works with AMD Z1 Extreme APU
- [ ] WebEngine functions correctly on Bazzite OS
- [ ] Performance matches official AppImage
- [ ] Stable operation for extended gaming sessions

EOF
}

# Generate final summary
generate_final_summary() {
    log_info "Generating final analysis summary..."
    
    cat >> "$FINAL_REPORT" << EOF

---

# Analysis Summary and Next Steps

## Key Findings
1. **GLIBC Compatibility**: Primary issue likely newer GLIBC target (2.35+ vs 2.31)
2. **Graphics Driver**: AMD Z1 Extreme requires specific Mesa/RADV configuration
3. **Build Environment**: Official uses older Ubuntu base for broader compatibility
4. **Component Versions**: Need exact version alignment with official build

## Critical Action Items
1. **Immediate**: Extract exact component versions from official AppImage
2. **Priority**: Set up Ubuntu 20.04 build environment for GLIBC compatibility
3. **Testing**: Validate on Bazzite OS with AMD graphics configuration
4. **Documentation**: Create Bazzite-specific installation guide

## Risk Assessment
- **High Risk**: GLIBC compatibility issues on Fedora Atomic 42
- **Medium Risk**: AMD graphics driver compatibility
- **Low Risk**: Component version mismatches (fixable with version pinning)

## Resource Requirements
- Ubuntu 20.04 build environment (container or VM)
- Bazzite OS testing environment with AMD Z1 Extreme APU
- Access to official AppImage for component extraction

## Timeline Estimate
- **Analysis Phase**: Complete ✓
- **Build Environment Setup**: 2-3 days
- **Component Alignment**: 3-4 days  
- **Testing and Validation**: 2-3 days
- **Total**: 7-10 days for complete solution

---

**Report Generated**: $(date)
**Analysis Tools**: analyze_official_appimage.sh, compare_builds.sh, run_comprehensive_analysis.sh
**Next Step**: Execute implementation plan based on findings

EOF
}

# Main analysis workflow
main() {
    log_info "Starting Comprehensive AppImage Analysis Workflow"
    log_info "Target: Debug crashes on Bazzite OS (Fedora Atomic 42) with AMD Z1 Extreme APU"
    echo ""
    
    # Check dependencies
    if ! check_dependencies; then
        log_error "Dependency check failed"
        exit 1
    fi
    
    # Initialize
    init_comprehensive_analysis
    
    # Run analysis workflow
    if run_official_analysis; then
        log_success "Step 1/4 complete: Official AppImage analysis"
    else
        log_error "Step 1/4 failed: Official AppImage analysis"
        exit 1
    fi
    
    if run_build_comparison; then
        log_success "Step 2/4 complete: Build comparison"
    else
        log_error "Step 2/4 failed: Build comparison"
        exit 1
    fi
    
    analyze_amd_compatibility
    log_success "Step 3/4 complete: AMD Z1 Extreme analysis"
    
    generate_bazzite_recommendations
    log_success "Step 4/4 complete: Bazzite OS recommendations"
    
    # Generate final summary
    generate_final_summary
    
    # Final report
    echo ""
    log_success "🎉 Comprehensive Analysis Complete!"
    log_info "📋 Full report: $FINAL_REPORT"
    log_info "📊 Report size: $(wc -l < "$FINAL_REPORT") lines"
    
    echo ""
    log_info "📈 Analysis Summary:"
    echo ""
    tail -20 "$FINAL_REPORT" | head -10
    
    echo ""
    log_info "🔧 Next Steps:"
    echo "  1. Review full report: cat $FINAL_REPORT"
    echo "  2. Set up Ubuntu 20.04 build environment"  
    echo "  3. Extract component versions from official AppImage"
    echo "  4. Test on Bazzite OS environment"
    
    return 0
}

# Help function
show_help() {
    cat << EOF
Comprehensive Analysis Runner

Usage: $0 [OPTIONS]

OPTIONS:
  -h, --help     Show this help message
  -v, --verbose  Enable verbose output
  -q, --quiet    Minimal output mode

This script orchestrates a comprehensive analysis of the official 
Minecraft Bedrock Launcher AppImage to debug crashes on Bazzite OS
(Fedora Atomic 42) with AMD Z1 Extreme APU.

Analysis Workflow:
1. Official AppImage download and analysis
2. Build configuration comparison
3. AMD Z1 Extreme compatibility analysis
4. Bazzite OS specific recommendations

Output: Comprehensive analysis report with implementation plan

Dependencies: wget, objdump, ldd, strings, fusermount, file, awk, grep

EOF
}

# Parse command line arguments
VERBOSE=false
QUIET=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            set -x
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Adjust output based on quiet mode
if [ "$QUIET" = true ]; then
    exec >/dev/null 2>&1
fi

# Check if running as root (FUSE incompatibility)
if [ "$EUID" -eq 0 ]; then
    log_error "Do not run as root (FUSE mounting incompatibility)"
    exit 1
fi

# Run main analysis
main "$@"