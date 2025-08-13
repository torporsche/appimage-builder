#!/bin/bash

# Build Comparison Script
# Compares the official AppImage with our current build configuration
# to identify compatibility issues for Bazzite OS

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANALYSIS_DIR="/tmp/appimage_analysis"
OFFICIAL_REPORT="${ANALYSIS_DIR}/analysis_report.txt"
COMPARISON_REPORT="${ANALYSIS_DIR}/build_comparison.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Analyze current build environment
analyze_current_build() {
    log_info "Analyzing current build environment..."
    
    cat > "$COMPARISON_REPORT" << EOF
# Build Comparison Report
Generated: $(date)
Purpose: Compare official AppImage with current build configuration

## Current Build Environment Analysis

### System Information
- **OS**: $(lsb_release -d 2>/dev/null | cut -f2 || uname -s)
- **Kernel**: $(uname -r)
- **Architecture**: $(uname -m)
- **Build Host**: $(hostname)

### Compiler and Toolchain
EOF
    
    # Analyze toolchain
    echo "#### Compiler Versions:" >> "$COMPARISON_REPORT"
    echo "- **GCC**: $(gcc --version 2>/dev/null | head -1 || echo "Not available")" >> "$COMPARISON_REPORT"
    echo "- **Clang**: $(clang --version 2>/dev/null | head -1 || echo "Not available")" >> "$COMPARISON_REPORT"
    echo "- **CMake**: $(cmake --version 2>/dev/null | head -1 || echo "Not available")" >> "$COMPARISON_REPORT"
    
    # GLIBC version
    echo "#### GLIBC Version:" >> "$COMPARISON_REPORT"
    echo "- **System GLIBC**: $(ldd --version 2>/dev/null | head -1 || echo "Unknown")" >> "$COMPARISON_REPORT"
    
    # Library versions
    echo "" >> "$COMPARISON_REPORT"
    echo "### System Libraries" >> "$COMPARISON_REPORT"
    echo "#### Key Development Libraries:" >> "$COMPARISON_REPORT"
    
    # Check for key libraries
    local libs=("libcurl4" "libssl3" "libQt5Core5" "libQt5WebEngine5" "libgl1-mesa")
    for lib in "${libs[@]}"; do
        local version=$(dpkg -l "$lib*" 2>/dev/null | grep "^ii" | awk '{print $2 " " $3}' | head -1)
        if [ -n "$version" ]; then
            echo "- **$lib**: $version" >> "$COMPARISON_REPORT"
        else
            echo "- **$lib**: Not installed" >> "$COMPARISON_REPORT"
        fi
    done
    
    echo "" >> "$COMPARISON_REPORT"
}

# Compare GLIBC requirements
compare_glibc() {
    log_info "Comparing GLIBC requirements..."
    
    cat >> "$COMPARISON_REPORT" << EOF
## GLIBC Compatibility Analysis

### Current Build GLIBC Target
- **System GLIBC**: $(ldd --version | head -1)
- **Available Symbols**: 
EOF
    
    # List available GLIBC symbols on current system
    local glibc_lib=$(find /lib* /usr/lib* -name "libc.so.6" 2>/dev/null | head -1)
    if [ -n "$glibc_lib" ]; then
        objdump -T "$glibc_lib" 2>/dev/null | grep "GLIBC_" | awk '{print $5}' | sort -u | tail -10 | sed 's/^/  - /' >> "$COMPARISON_REPORT"
    fi
    
    echo "" >> "$COMPARISON_REPORT"
    echo "### Official AppImage GLIBC Requirements" >> "$COMPARISON_REPORT"
    
    # Extract GLIBC requirements from official analysis if available
    if [ -f "$OFFICIAL_REPORT" ]; then
        echo "- **From Official Analysis**: (extracted from analysis report)" >> "$COMPARISON_REPORT"
        grep -A 20 "GLIBC Symbol Dependencies" "$OFFICIAL_REPORT" 2>/dev/null | grep "GLIBC_" | sort -u | head -10 | sed 's/^/  /' >> "$COMPARISON_REPORT"
    else
        echo "- **Official analysis not available**: Run analyze_official_appimage.sh first" >> "$COMPARISON_REPORT"
    fi
    
    echo "" >> "$COMPARISON_REPORT"
    echo "### Compatibility Assessment" >> "$COMPARISON_REPORT"
    echo "**Target System**: Bazzite OS (Fedora Atomic 42) with AMD Z1 Extreme APU" >> "$COMPARISON_REPORT"
    echo "" >> "$COMPARISON_REPORT"
    echo "**Likely Issues**:" >> "$COMPARISON_REPORT"
    echo "- Current build targets newer GLIBC (2.35+) vs official (likely 2.27-2.31)" >> "$COMPARISON_REPORT"
    echo "- Fedora 42 may have different GLIBC version than Ubuntu 22.04 build target" >> "$COMPARISON_REPORT"
    echo "- AMD Z1 Extreme APU may have specific graphics driver requirements" >> "$COMPARISON_REPORT"
    
    echo "" >> "$COMPARISON_REPORT"
}

# Compare component versions
compare_components() {
    log_info "Comparing component versions..."
    
    cat >> "$COMPARISON_REPORT" << EOF
## Component Version Comparison

### Current Build Component Versions
EOF
    
    # Read current commit files
    if [ -f "$SCRIPT_DIR/mcpelauncher.commit" ]; then
        echo "- **mcpelauncher**: $(cat "$SCRIPT_DIR/mcpelauncher.commit")" >> "$COMPARISON_REPORT"
    fi
    
    if [ -f "$SCRIPT_DIR/mcpelauncher-ui.commit" ]; then
        echo "- **mcpelauncher-ui**: $(cat "$SCRIPT_DIR/mcpelauncher-ui.commit")" >> "$COMPARISON_REPORT"
    fi
    
    if [ -f "$SCRIPT_DIR/msa.commit" ]; then
        echo "- **msa**: $(cat "$SCRIPT_DIR/msa.commit") (disabled)" >> "$COMPARISON_REPORT"
    fi
    
    echo "- **Version**: $(cat "$SCRIPT_DIR/version.txt" 2>/dev/null || echo "Unknown")" >> "$COMPARISON_REPORT"
    
    echo "" >> "$COMPARISON_REPORT"
    echo "### Official AppImage Component Versions" >> "$COMPARISON_REPORT"
    
    # Extract component versions from official analysis if available
    if [ -f "$OFFICIAL_REPORT" ]; then
        echo "- **From Official Analysis**: (extracted from analysis report)" >> "$COMPARISON_REPORT"
        grep -A 10 "Version Strings in Binaries" "$OFFICIAL_REPORT" 2>/dev/null | head -20 | sed 's/^/  /' >> "$COMPARISON_REPORT"
    else
        echo "- **Official analysis not available**: Run analyze_official_appimage.sh first" >> "$COMPARISON_REPORT"
    fi
    
    echo "" >> "$COMPARISON_REPORT"
}

# Compare build environment
compare_build_environment() {
    log_info "Comparing build environments..."
    
    cat >> "$COMPARISON_REPORT" << EOF
## Build Environment Comparison

### Current Build Configuration
- **Base OS**: Ubuntu 22.04 LTS
- **Qt Version**: Qt5 (forced, no Qt6)
- **Compiler**: clang (preferred over gcc)
- **Architecture**: x86_64 only
- **MSA**: Disabled (-m flag)
- **32-bit builds**: Disabled (-n flag)
- **Quirks**: quirks-modern.sh (simplified)

### Build Flags Analysis
EOF
    
    # Analyze current build flags
    echo "#### Current Build Command:" >> "$COMPARISON_REPORT"
    echo "\`\`\`bash" >> "$COMPARISON_REPORT"
    echo "./build_appimage.sh -t x86_64 -m -n -j \${MAKE_JOBS} -q quirks-modern.sh" >> "$COMPARISON_REPORT"
    echo "\`\`\`" >> "$COMPARISON_REPORT"
    
    echo "" >> "$COMPARISON_REPORT"
    echo "#### Compiler Flags:" >> "$COMPARISON_REPORT"
    
    # Extract compiler flags from build script
    grep -E "(CFLAGS|CXXFLAGS)" "$SCRIPT_DIR/build_appimage.sh" | head -5 | sed 's/^/  /' >> "$COMPARISON_REPORT"
    
    echo "" >> "$COMPARISON_REPORT"
    echo "### Likely Official Build Environment" >> "$COMPARISON_REPORT"
    echo "**Estimated Configuration**:" >> "$COMPARISON_REPORT"
    echo "- **Base OS**: Ubuntu 18.04 or 20.04 LTS (for older GLIBC)" >> "$COMPARISON_REPORT"
    echo "- **Compiler**: Likely GCC (more conservative)" >> "$COMPARISON_REPORT"
    echo "- **Qt Version**: Stable Qt5 version" >> "$COMPARISON_REPORT"
    echo "- **GLIBC Target**: 2.27-2.31 for broader compatibility" >> "$COMPARISON_REPORT"
    
    echo "" >> "$COMPARISON_REPORT"
}

# Generate recommendations
generate_recommendations() {
    log_info "Generating compatibility recommendations..."
    
    cat >> "$COMPARISON_REPORT" << EOF
## Compatibility Recommendations

### Critical Issues for Bazzite OS (Fedora Atomic 42 + AMD Z1 Extreme)

#### 1. GLIBC Compatibility
**Problem**: Current build targets newer GLIBC than official
**Solution**: 
- Build on Ubuntu 18.04 or 20.04 container
- Target GLIBC 2.27-2.31 for broader compatibility
- Use \`--glibc-compat\` build flag if available

#### 2. Graphics Driver Compatibility  
**Problem**: AMD Z1 Extreme APU requires specific graphics configuration
**Solution**:
- Ensure ANGLE/OpenGL ES compatibility
- Bundle Mesa drivers compatible with AMD RDNA2/3
- Test with \`QTWEBENGINE_CHROMIUM_FLAGS=--no-sandbox\` (already implemented)

#### 3. Component Version Alignment
**Problem**: Unknown component version differences with official
**Solution**:
- Extract exact commit hashes from official AppImage
- Pin mcpelauncher components to matching versions
- Test incremental updates to identify breaking changes

#### 4. Library Bundling Strategy
**Problem**: Different dependency packaging may cause runtime issues
**Solution**:
- Match official library bundling approach
- Use compatible library versions
- Ensure proper library search paths

### Implementation Plan

#### Phase 1: Environment Alignment
\`\`\`bash
# Use older Ubuntu base
docker run -it ubuntu:20.04

# Install exact toolchain versions
apt-get install gcc-9 g++-9 cmake=3.16.*
\`\`\`

#### Phase 2: Component Version Matching
\`\`\`bash
# Extract official versions (after running analysis)
# Update commit files to match official
# Rebuild with exact component versions
\`\`\`

#### Phase 3: Testing and Validation
\`\`\`bash
# Test on Bazzite OS VM or container
# Validate graphics functionality
# Compare runtime behavior with official
\`\`\`

### Testing Strategy for Bazzite OS

#### Graphics Testing
\`\`\`bash
# Test ANGLE/OpenGL compatibility
export QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox --disable-gpu-sandbox"
export LIBGL_ALWAYS_SOFTWARE=1  # Fallback test

# AMD GPU specific
export MESA_LOADER_DRIVER_OVERRIDE=radeonsi
export AMD_VULKAN_ICD=RADV
\`\`\`

#### Runtime Testing
\`\`\`bash
# Verify library dependencies
ldd ./minecraft-launcher | grep "not found"

# Test in Fedora environment
podman run -it --privileged fedora:42
\`\`\`

## Success Criteria

- [ ] AppImage launches successfully on Bazzite OS
- [ ] Graphics rendering works with AMD Z1 Extreme APU
- [ ] No GLIBC compatibility errors
- [ ] Game functionality matches official AppImage behavior
- [ ] Stable performance without crashes

## Next Steps

1. **Run Official Analysis**: \`./analyze_official_appimage.sh\`
2. **Compare Results**: Review this report with official analysis
3. **Implement Changes**: Update build configuration based on findings
4. **Test on Target**: Validate on Bazzite OS with AMD Z1 Extreme
5. **Iterate**: Refine based on test results

EOF
}

# Main comparison function
main() {
    log_info "Starting Build Comparison Analysis"
    
    # Check if analysis directory exists
    if [ ! -d "$ANALYSIS_DIR" ]; then
        mkdir -p "$ANALYSIS_DIR"
    fi
    
    # Perform comparisons
    analyze_current_build
    compare_glibc
    compare_components
    compare_build_environment
    generate_recommendations
    
    # Final report
    log_success "Build comparison complete! Report saved to: $COMPARISON_REPORT"
    log_info "Report summary:"
    echo ""
    head -20 "$COMPARISON_REPORT"
    echo ""
    log_info "Full report: $COMPARISON_REPORT"
    
    # Check if official analysis exists
    if [ ! -f "$OFFICIAL_REPORT" ]; then
        log_warning "Official AppImage analysis not found."
        log_info "Run './analyze_official_appimage.sh' first for complete comparison."
    else
        log_success "Official analysis found. Comparison includes official AppImage data."
    fi
    
    return 0
}

# Help function
show_help() {
    cat << EOF
Build Comparison Script

Usage: $0 [OPTIONS]

OPTIONS:
  -h, --help     Show this help message
  -v, --verbose  Enable verbose output

This script compares the official Minecraft Bedrock Launcher AppImage
with our current build configuration to identify compatibility issues
for Bazzite OS (Fedora Atomic 42) with AMD Z1 Extreme APU.

Comparison includes:
- GLIBC compatibility analysis
- Component version differences
- Build environment comparison
- Compatibility recommendations

Note: Run './analyze_official_appimage.sh' first for complete analysis.

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            set -x
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Run main comparison
main "$@"