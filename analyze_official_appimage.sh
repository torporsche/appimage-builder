#!/bin/bash

# Official AppImage Analysis Script
# Analyzes the official Minecraft Bedrock Launcher AppImage v1.1.1-802
# to identify critical differences with our build that's crashing on Bazzite OS

set -e

# Configuration
OFFICIAL_VERSION="v1.1.1.802"
OFFICIAL_URL="https://github.com/minecraft-linux/appimage-builder/releases/download/v1.1.1-802/Minecraft_Bedrock_Launcher-x86_64-v1.1.1.802.AppImage"
OFFICIAL_FILENAME="Minecraft_Bedrock_Launcher-x86_64-v1.1.1.802.AppImage"
ANALYSIS_DIR="/tmp/appimage_analysis"
MOUNT_POINT=""
REPORT_FILE="${ANALYSIS_DIR}/analysis_report.txt"

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

# Cleanup function
cleanup() {
    if [ -n "$MOUNT_POINT" ] && mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        log_info "Unmounting AppImage..."
        fusermount -u "$MOUNT_POINT" 2>/dev/null || true
    fi
    
    # Kill any running AppImage processes
    pkill -f "$OFFICIAL_FILENAME" 2>/dev/null || true
}

trap cleanup EXIT

# Setup analysis directory
setup_analysis_dir() {
    log_info "Setting up analysis directory..."
    rm -rf "$ANALYSIS_DIR"
    mkdir -p "$ANALYSIS_DIR"
    cd "$ANALYSIS_DIR"
}

# Download official AppImage
download_official_appimage() {
    log_info "Downloading official AppImage $OFFICIAL_VERSION..."
    
    if [ -f "$OFFICIAL_FILENAME" ]; then
        log_info "Official AppImage already exists, skipping download"
        return 0
    fi
    
    # Download with progress and retry logic
    for attempt in 1 2 3; do
        log_info "Download attempt $attempt/3..."
        if wget --progress=bar:force:noscroll -O "$OFFICIAL_FILENAME" "$OFFICIAL_URL"; then
            log_success "Download completed successfully"
            break
        else
            log_warning "Download attempt $attempt failed"
            if [ $attempt -eq 3 ]; then
                log_error "Failed to download after 3 attempts"
                return 1
            fi
            sleep 10
        fi
    done
    
    # Make executable
    chmod +x "$OFFICIAL_FILENAME"
    
    # Verify download
    if [ ! -f "$OFFICIAL_FILENAME" ] || [ ! -s "$OFFICIAL_FILENAME" ]; then
        log_error "Downloaded file is missing or empty"
        return 1
    fi
    
    log_success "Official AppImage downloaded: $(ls -lh "$OFFICIAL_FILENAME" | awk '{print $5}')"
}

# Mount AppImage for analysis
mount_appimage() {
    log_info "Mounting AppImage for analysis..."
    
    # Create mount point
    MOUNT_POINT="$ANALYSIS_DIR/mount"
    mkdir -p "$MOUNT_POINT"
    
    # Mount AppImage using --appimage-mount
    log_info "Starting AppImage mount process..."
    "./$OFFICIAL_FILENAME" --appimage-mount &
    local mount_pid=$!
    
    # Wait for mount to be ready (max 30 seconds)
    local timeout=30
    local count=0
    while [ $count -lt $timeout ]; do
        # Check for mount points
        local actual_mount=$(mount | grep -E "(squashfs|fuse)" | grep -E "\.mount_[^/]+$" | tail -1 | awk '{print $3}')
        if [ -n "$actual_mount" ] && [ -d "$actual_mount" ]; then
            MOUNT_POINT="$actual_mount"
            log_success "AppImage mounted at: $MOUNT_POINT"
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done
    
    log_error "Failed to mount AppImage within timeout"
    kill $mount_pid 2>/dev/null || true
    return 1
}

# Initialize analysis report
init_report() {
    log_info "Initializing analysis report..."
    
    cat > "$REPORT_FILE" << EOF
# Official AppImage Analysis Report
Generated: $(date)
AppImage: $OFFICIAL_FILENAME
Version: $OFFICIAL_VERSION
Analysis Host: $(uname -a)

## Executive Summary
This report analyzes the official Minecraft Bedrock Launcher AppImage (v1.1.1-802)
to identify critical differences with our updated build that's crashing on Bazzite OS
(Fedora Atomic 42) with AMD Z1 Extreme APU.

EOF
}

# Analyze binary dependencies and GLIBC requirements
analyze_binary_dependencies() {
    log_info "Analyzing binary dependencies and GLIBC requirements..."
    
    cat >> "$REPORT_FILE" << EOF
## 1. Binary Comparison Analysis

### GLIBC Version Requirements
EOF
    
    # Find all executable binaries and shared libraries
    log_info "Finding executable files and libraries..."
    local executables=$(find "$MOUNT_POINT" -type f \( -perm -111 -o -name "*.so*" \) 2>/dev/null | head -50)
    
    # Analyze GLIBC requirements
    echo "#### GLIBC Symbol Dependencies:" >> "$REPORT_FILE"
    for binary in $executables; do
        if [ -x "$binary" ] || [[ "$binary" == *.so* ]]; then
            local filename=$(basename "$binary")
            echo "**$filename:**" >> "$REPORT_FILE"
            
            # Extract GLIBC requirements
            if objdump -T "$binary" 2>/dev/null | grep -E "GLIBC_[0-9]" | awk '{print $5}' | sort -u; then
                objdump -T "$binary" 2>/dev/null | grep -E "GLIBC_[0-9]" | awk '{print $5}' | sort -u | sed 's/^/  - /' >> "$REPORT_FILE"
            else
                echo "  - No GLIBC symbols found" >> "$REPORT_FILE"
            fi
            echo "" >> "$REPORT_FILE"
        fi
    done
    
    # Analyze library dependencies
    echo "### Library Dependencies" >> "$REPORT_FILE"
    echo "#### Main Executable Dependencies:" >> "$REPORT_FILE"
    
    # Find main launcher executable
    local main_exe=$(find "$MOUNT_POINT" -name "*mcpelauncher*" -type f -perm -111 | head -1)
    if [ -n "$main_exe" ]; then
        echo "**Main executable: $(basename "$main_exe")**" >> "$REPORT_FILE"
        ldd "$main_exe" 2>/dev/null | sed 's/^/  /' >> "$REPORT_FILE" || echo "  No dynamic dependencies" >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
}

# Detect component versions
analyze_component_versions() {
    log_info "Analyzing component versions..."
    
    cat >> "$REPORT_FILE" << EOF
## 2. Component Version Analysis

### mcpelauncher Components
EOF
    
    # Check for version information in binaries
    echo "#### Binary Version Information:" >> "$REPORT_FILE"
    
    # Look for version strings in executables
    local version_files=$(find "$MOUNT_POINT" -type f \( -name "*version*" -o -name "*VERSION*" \) 2>/dev/null)
    for file in $version_files; do
        echo "**$(basename "$file"):**" >> "$REPORT_FILE"
        cat "$file" 2>/dev/null | head -10 | sed 's/^/  /' >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    done
    
    # Check embedded version strings in binaries
    echo "#### Version Strings in Binaries:" >> "$REPORT_FILE"
    local executables=$(find "$MOUNT_POINT" -name "*mcpelauncher*" -type f -perm -111)
    for exe in $executables; do
        echo "**$(basename "$exe"):**" >> "$REPORT_FILE"
        
        # Extract readable strings that might contain version info
        strings "$exe" 2>/dev/null | grep -iE "(version|v[0-9]+\.[0-9]+|commit|hash)" | head -5 | sed 's/^/  /' >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    done
    
    # Qt5 version detection
    echo "### Qt5 Framework Version" >> "$REPORT_FILE"
    
    # Look for Qt libraries
    local qt_libs=$(find "$MOUNT_POINT" -name "*Qt5*" -type f | head -10)
    if [ -n "$qt_libs" ]; then
        echo "#### Qt5 Libraries Found:" >> "$REPORT_FILE"
        for lib in $qt_libs; do
            echo "  - $(basename "$lib")" >> "$REPORT_FILE"
            # Try to extract Qt version from library
            strings "$lib" 2>/dev/null | grep -E "Qt [0-9]+\.[0-9]+" | head -1 | sed 's/^/    Version: /' >> "$REPORT_FILE"
        done
    else
        echo "  - No Qt5 libraries found" >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
}

# Analyze AppImage structure
analyze_appimage_structure() {
    log_info "Analyzing AppImage structure..."
    
    cat >> "$REPORT_FILE" << EOF
## 3. AppImage Structure Comparison

### File Structure
#### Directory Layout:
EOF
    
    # Generate directory tree
    if command -v tree >/dev/null 2>&1; then
        tree -L 3 "$MOUNT_POINT" | head -50 >> "$REPORT_FILE"
    else
        find "$MOUNT_POINT" -type d | head -20 | sed 's/^/  /' >> "$REPORT_FILE"
    fi
    
    # Analyze desktop integration
    echo "" >> "$REPORT_FILE"
    echo "### Desktop Integration" >> "$REPORT_FILE"
    
    # Check for .desktop files
    local desktop_files=$(find "$MOUNT_POINT" -name "*.desktop" -type f)
    for desktop_file in $desktop_files; do
        echo "#### $(basename "$desktop_file"):" >> "$REPORT_FILE"
        cat "$desktop_file" | sed 's/^/  /' >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    done
    
    # Check AppRun script
    echo "### Entry Point Analysis" >> "$REPORT_FILE"
    if [ -f "$MOUNT_POINT/AppRun" ]; then
        echo "#### AppRun Script:" >> "$REPORT_FILE"
        cat "$MOUNT_POINT/AppRun" | head -20 | sed 's/^/  /' >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
}

# Analyze runtime environment
analyze_runtime_environment() {
    log_info "Analyzing runtime environment requirements..."
    
    cat >> "$REPORT_FILE" << EOF
## 4. Runtime Environment Analysis

### Library Bundling Strategy
#### Bundled Libraries:
EOF
    
    # Find bundled libraries
    local lib_dirs=$(find "$MOUNT_POINT" -type d -name "*lib*" 2>/dev/null)
    for lib_dir in $lib_dirs; do
        if [ -d "$lib_dir" ]; then
            echo "**$lib_dir:**" >> "$REPORT_FILE"
            ls -la "$lib_dir" | head -10 | sed 's/^/  /' >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
        fi
    done
    
    # Check for environment setup scripts
    echo "### Environment Variables" >> "$REPORT_FILE"
    
    # Look for environment setup in AppRun or other scripts
    local scripts=$(find "$MOUNT_POINT" -type f \( -name "AppRun" -o -name "*.sh" \) 2>/dev/null)
    for script in $scripts; do
        echo "#### $(basename "$script") environment setup:" >> "$REPORT_FILE"
        grep -E "(export|PATH|LD_LIBRARY_PATH)" "$script" 2>/dev/null | head -5 | sed 's/^/  /' >> "$REPORT_FILE" || echo "  No environment variables set" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    done
    
    echo "" >> "$REPORT_FILE"
}

# Generate comparison with current build
generate_comparison() {
    log_info "Generating comparison with current build..."
    
    cat >> "$REPORT_FILE" << EOF
## 5. Critical Differences Analysis

### Current Build Configuration
- **Base System**: Ubuntu 22.04 LTS
- **Architecture**: x86_64 only
- **Qt Version**: Qt5 (WebEngine enabled)
- **Compiler**: clang 18.1.3
- **CMake**: 3.31.6
- **Component Versions**:
  - mcpelauncher: $(cat /home/runner/work/appimage-builder/appimage-builder/mcpelauncher.commit)
  - mcpelauncher-ui: $(cat /home/runner/work/appimage-builder/appimage-builder/mcpelauncher-ui.commit)
  - msa: $(cat /home/runner/work/appimage-builder/appimage-builder/msa.commit) (disabled)

### Build Environment Differences
**Likely Issues:**
1. **GLIBC Compatibility**: Official build likely targets older GLIBC (2.27-2.31) vs our 2.35+
2. **Library Bundling**: Different dependency packaging strategy
3. **Base Distribution**: Official may use older Ubuntu base (18.04/20.04)
4. **Component Versions**: Official uses different mcpelauncher component versions

### Recommended Actions
1. **Pin GLIBC Version**: Build on older Ubuntu base (18.04/20.04)
2. **Match Component Versions**: Use exact commits from official build
3. **Library Strategy**: Match official dependency bundling approach
4. **Configuration**: Replicate CMake and build tool versions

EOF
}

# Main analysis function
main() {
    log_info "Starting Official AppImage Analysis for Debugging Crash Issues"
    log_info "Target: Minecraft Bedrock Launcher AppImage v1.1.1-802"
    
    # Setup
    setup_analysis_dir
    init_report
    
    # Download and mount
    if ! download_official_appimage; then
        log_error "Failed to download official AppImage"
        exit 1
    fi
    
    if ! mount_appimage; then
        log_error "Failed to mount AppImage"
        exit 1
    fi
    
    # Perform analysis
    analyze_binary_dependencies
    analyze_component_versions
    analyze_appimage_structure
    analyze_runtime_environment
    generate_comparison
    
    # Final report
    log_success "Analysis complete! Report saved to: $REPORT_FILE"
    log_info "Report summary:"
    echo ""
    cat "$REPORT_FILE" | head -20
    echo ""
    log_info "Full report: $REPORT_FILE"
    
    return 0
}

# Help function
show_help() {
    cat << EOF
Official AppImage Analysis Script

Usage: $0 [OPTIONS]

OPTIONS:
  -h, --help     Show this help message
  -v, --verbose  Enable verbose output
  -d, --dir DIR  Use custom analysis directory (default: $ANALYSIS_DIR)

This script downloads and analyzes the official Minecraft Bedrock Launcher
AppImage v1.1.1-802 to identify critical differences with our build that's
crashing on Bazzite OS (Fedora Atomic 42) with AMD Z1 Extreme APU.

Analysis includes:
- Binary dependencies and GLIBC requirements
- Component version detection
- AppImage structure comparison
- Runtime environment analysis
- Comparison with current build configuration

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
        -d|--dir)
            ANALYSIS_DIR="$2"
            shift 2
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    for cmd in wget objdump ldd strings fusermount; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Please install: sudo apt-get install wget binutils libc-bin fuse"
        exit 1
    fi
}

# Verify we're not root (for FUSE mounting)
if [ "$EUID" -eq 0 ]; then
    log_error "Do not run this script as root (FUSE mounting may not work)"
    exit 1
fi

# Check dependencies and run main
check_dependencies
main "$@"