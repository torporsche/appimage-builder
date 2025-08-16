#!/bin/bash
# AppImage Compatibility Checker for mcpelauncher-linux
# Validates dependencies and required components for proper AppImage functionality

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
COLOR_SUCCESS="\033[32m"
COLOR_WARNING="\033[33m"
COLOR_ERROR="\033[31m"
COLOR_INFO="\033[36m"
COLOR_RESET="\033[0m"

# Counters
VALIDATION_PASSED=0
VALIDATION_WARNINGS=0
VALIDATION_FAILED=0

show_status() {
    echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} $1"
}

show_success() {
    echo -e "${COLOR_SUCCESS}[SUCCESS]${COLOR_RESET} $1"
    VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
}

show_warning() {
    echo -e "${COLOR_WARNING}[WARNING]${COLOR_RESET} $1"
    VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
}

show_error() {
    echo -e "${COLOR_ERROR}[ERROR]${COLOR_RESET} $1"
    VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
}

# Check if AppImage exists and is executable
check_appimage_exists() {
    local appimage_path="$1"
    
    show_status "Checking AppImage existence and permissions"
    
    if [ ! -f "$appimage_path" ]; then
        show_error "AppImage not found: $appimage_path"
        return 1
    fi
    
    if [ ! -x "$appimage_path" ]; then
        show_error "AppImage is not executable: $appimage_path"
        return 1
    fi
    
    show_success "AppImage found and executable: $appimage_path"
    return 0
}

# Check AppImage internal structure
check_appimage_structure() {
    local appimage_path="$1"
    local temp_dir="/tmp/appimage_check_$$"
    
    show_status "Checking AppImage internal structure"
    
    # Extract AppImage
    if ! "$appimage_path" --appimage-extract >/dev/null 2>&1; then
        show_error "Failed to extract AppImage"
        return 1
    fi
    
    local squashfs_root="squashfs-root"
    
    # Check for essential files
    local essential_files=(
        "AppRun"
        "mcpelauncher-ui-qt.desktop"
        "usr/bin/mcpelauncher-ui-qt"
    )
    
    for file in "${essential_files[@]}"; do
        if [ -f "$squashfs_root/$file" ]; then
            show_success "Essential file found: $file"
        else
            show_error "Missing essential file: $file"
        fi
    done
    
    # Check for Qt plugins
    show_status "Checking Qt plugin availability"
    
    local qt_plugin_dirs=(
        "usr/lib/qt6/plugins"
        "usr/lib/qt5/plugins"
        "usr/plugins"
    )
    
    local plugins_found=false
    for plugin_dir in "${qt_plugin_dirs[@]}"; do
        if [ -d "$squashfs_root/$plugin_dir" ]; then
            show_success "Qt plugins directory found: $plugin_dir"
            plugins_found=true
            
            # Check specific plugin types
            local plugin_types=(
                "platforms"
                "imageformats"
                "iconengines"
            )
            
            for plugin_type in "${plugin_types[@]}"; do
                if [ -d "$squashfs_root/$plugin_dir/$plugin_type" ]; then
                    local plugin_count=$(find "$squashfs_root/$plugin_dir/$plugin_type" -name "*.so" 2>/dev/null | wc -l)
                    if [ "$plugin_count" -gt 0 ]; then
                        show_success "Qt $plugin_type plugins: $plugin_count found"
                    else
                        show_warning "Qt $plugin_type plugins: directory exists but no .so files"
                    fi
                else
                    show_warning "Qt $plugin_type plugins: directory not found"
                fi
            done
        fi
    done
    
    if [ "$plugins_found" = false ]; then
        show_error "No Qt plugin directories found"
    fi
    
    # Check for Wayland support
    show_status "Checking Wayland support"
    
    local wayland_plugins=(
        "usr/lib/qt6/plugins/platforms/libqwayland-egl.so"
        "usr/lib/qt6/plugins/platforms/libqwayland-generic.so"
        "usr/lib/qt5/plugins/platforms/libqwayland-egl.so"
        "usr/lib/qt5/plugins/platforms/libqwayland-generic.so"
    )
    
    local wayland_found=false
    for plugin in "${wayland_plugins[@]}"; do
        if [ -f "$squashfs_root/$plugin" ]; then
            show_success "Wayland plugin found: $plugin"
            wayland_found=true
        fi
    done
    
    if [ "$wayland_found" = false ]; then
        show_warning "No Wayland plugins found - X11 only support"
    fi
    
    # Check for OpenGL libraries
    show_status "Checking OpenGL libraries"
    
    local opengl_libs=(
        "usr/lib/libGL.so.1"
        "usr/lib/libEGL.so.1"
        "usr/lib/libGLESv2.so.2"
        "usr/lib/x86_64-linux-gnu/libGL.so.1"
        "usr/lib/x86_64-linux-gnu/libEGL.so.1"
        "usr/lib/x86_64-linux-gnu/libGLESv2.so.2"
    )
    
    local opengl_found=false
    for lib in "${opengl_libs[@]}"; do
        if [ -f "$squashfs_root/$lib" ]; then
            show_success "OpenGL library found: $lib"
            opengl_found=true
        fi
    done
    
    if [ "$opengl_found" = false ]; then
        show_warning "No OpenGL libraries found in AppImage - relying on system libraries"
    fi
    
    # Cleanup
    rm -rf "$squashfs_root"
    
    return 0
}

# Check system dependencies
check_system_dependencies() {
    show_status "Checking system dependencies"
    
    # Check GLIBC version
    local glibc_version
    if glibc_version=$(ldd --version 2>&1 | head -n1 | grep -o '[0-9]\+\.[0-9]\+'); then
        show_success "GLIBC version: $glibc_version"
        
        # Check if GLIBC is recent enough (2.31+ recommended for modern AppImages)
        if printf '%s\n2.31\n' "$glibc_version" | sort -V | head -n1 | grep -q "2.31"; then
            show_success "GLIBC version is compatible (>= 2.31)"
        else
            show_warning "GLIBC version may be too old (< 2.31) for some AppImages"
        fi
    else
        show_error "Failed to detect GLIBC version"
    fi
    
    # Check for FUSE
    if command -v fusermount >/dev/null 2>&1 || command -v fusermount3 >/dev/null 2>&1; then
        show_success "FUSE available for AppImage mounting"
    else
        show_warning "FUSE not found - may affect AppImage execution"
    fi
    
    # Check for X11/Wayland
    if [ -n "${DISPLAY:-}" ]; then
        show_success "X11 display available: $DISPLAY"
    else
        show_warning "No X11 display detected"
    fi
    
    if [ -n "${WAYLAND_DISPLAY:-}" ]; then
        show_success "Wayland display available: $WAYLAND_DISPLAY"
    else
        show_warning "No Wayland display detected"
    fi
    
    # Check for audio systems
    if command -v pulseaudio >/dev/null 2>&1 || command -v pipewire >/dev/null 2>&1; then
        show_success "Audio system available"
    else
        show_warning "No audio system detected"
    fi
    
    # Check OpenGL support
    if command -v glxinfo >/dev/null 2>&1; then
        local gl_version
        if gl_version=$(glxinfo | grep "OpenGL version" 2>/dev/null); then
            show_success "OpenGL support: $gl_version"
        else
            show_warning "OpenGL information not available"
        fi
    else
        show_warning "glxinfo not found - cannot check OpenGL support"
    fi
}

# Check mcpelauncher-specific requirements
check_mcpelauncher_requirements() {
    show_status "Checking mcpelauncher-specific requirements"
    
    # Check for curl (needed for MSA authentication)
    if command -v curl >/dev/null 2>&1; then
        show_success "curl available for network operations"
    else
        show_warning "curl not found - may affect online features"
    fi
    
    # Check for SSL/TLS support
    if [ -f "/etc/ssl/certs/ca-certificates.crt" ] || [ -d "/etc/ssl/certs" ]; then
        show_success "SSL certificates available"
    else
        show_warning "SSL certificates not found - may affect HTTPS connections"
    fi
    
    # Check for required architecture
    local arch
    arch=$(uname -m)
    if [ "$arch" = "x86_64" ]; then
        show_success "Architecture supported: $arch"
    else
        show_error "Unsupported architecture: $arch (only x86_64 supported)"
    fi
    
    # Check available memory
    local mem_total
    if mem_total=$(free -m | awk 'NR==2{print $2}'); then
        if [ "$mem_total" -ge 2048 ]; then
            show_success "Sufficient memory: ${mem_total}MB"
        else
            show_warning "Low memory: ${mem_total}MB (2GB+ recommended)"
        fi
    else
        show_warning "Unable to check memory availability"
    fi
    
    # Check disk space
    local disk_free
    if disk_free=$(df . | tail -1 | awk '{print $4}'); then
        local disk_free_mb=$((disk_free / 1024))
        if [ "$disk_free_mb" -ge 1024 ]; then
            show_success "Sufficient disk space: ${disk_free_mb}MB"
        else
            show_warning "Low disk space: ${disk_free_mb}MB (1GB+ recommended)"
        fi
    else
        show_warning "Unable to check disk space"
    fi
}

# Test basic AppImage functionality
test_appimage_basic() {
    local appimage_path="$1"
    
    show_status "Testing basic AppImage functionality"
    
    # Test AppImage version info
    if "$appimage_path" --appimage-version >/dev/null 2>&1; then
        show_success "AppImage version command works"
    else
        show_warning "AppImage version command failed"
    fi
    
    # Test AppImage help
    if timeout 10s "$appimage_path" --help >/dev/null 2>&1; then
        show_success "AppImage help command works"
    else
        show_warning "AppImage help command failed or timed out"
    fi
    
    # Test AppImage extraction (already done in structure check)
    show_success "AppImage extraction functionality confirmed"
}

# Generate compatibility report
generate_report() {
    local appimage_path="$1"
    local report_file="${2:-appimage_compatibility_report.txt}"
    
    show_status "Generating compatibility report"
    
    cat > "$report_file" << EOF
# AppImage Compatibility Report

**Generated:** $(date)
**AppImage:** $appimage_path
**System:** $(uname -a)

## Summary

- **Passed:** $VALIDATION_PASSED checks
- **Warnings:** $VALIDATION_WARNINGS issues
- **Failed:** $VALIDATION_FAILED critical issues

EOF

    if [ "$VALIDATION_FAILED" -eq 0 ]; then
        echo "## Overall Status: ✅ COMPATIBLE" >> "$report_file"
        echo "" >> "$report_file"
        echo "The AppImage should work correctly on this system." >> "$report_file"
    elif [ "$VALIDATION_FAILED" -le 2 ] && [ "$VALIDATION_WARNINGS" -le 5 ]; then
        echo "## Overall Status: ⚠️ MOSTLY COMPATIBLE" >> "$report_file"
        echo "" >> "$report_file"
        echo "The AppImage should work with minor issues or reduced functionality." >> "$report_file"
    else
        echo "## Overall Status: ❌ COMPATIBILITY ISSUES" >> "$report_file"
        echo "" >> "$report_file"
        echo "The AppImage may not work correctly due to missing dependencies or system incompatibilities." >> "$report_file"
    fi
    
    echo "" >> "$report_file"
    echo "## Recommendations" >> "$report_file"
    echo "" >> "$report_file"
    
    if [ "$VALIDATION_WARNINGS" -gt 0 ] || [ "$VALIDATION_FAILED" -gt 0 ]; then
        echo "### To improve compatibility:" >> "$report_file"
        echo "- Install missing system dependencies" >> "$report_file"
        echo "- Update graphics drivers" >> "$report_file"
        echo "- Ensure X11 or Wayland is properly configured" >> "$report_file"
        echo "- Install FUSE if not available" >> "$report_file"
        echo "- Verify OpenGL/GLES support" >> "$report_file"
    else
        echo "No specific recommendations - system appears fully compatible." >> "$report_file"
    fi
    
    show_success "Report generated: $report_file"
}

# Print usage information
usage() {
    echo "Usage: $0 <appimage_path> [report_file]"
    echo ""
    echo "Validates AppImage compatibility and dependencies"
    echo ""
    echo "Arguments:"
    echo "  appimage_path  Path to the AppImage file to check"
    echo "  report_file    Optional output file for the report (default: appimage_compatibility_report.txt)"
    echo ""
    echo "Example:"
    echo "  $0 ./mcpelauncher-ui-qt.AppImage"
    echo "  $0 ./mcpelauncher-ui-qt.AppImage my_report.txt"
}

# Main function
main() {
    if [ $# -lt 1 ]; then
        echo "Error: AppImage path required"
        echo ""
        usage
        exit 1
    fi
    
    local appimage_path="$1"
    local report_file="${2:-appimage_compatibility_report.txt}"
    
    if [ "$appimage_path" = "--help" ] || [ "$appimage_path" = "-h" ]; then
        usage
        exit 0
    fi
    
    echo "AppImage Compatibility Checker for mcpelauncher-linux"
    echo "====================================================="
    echo ""
    
    # Run all checks
    check_appimage_exists "$appimage_path"
    echo ""
    
    check_appimage_structure "$appimage_path"
    echo ""
    
    check_system_dependencies
    echo ""
    
    check_mcpelauncher_requirements
    echo ""
    
    test_appimage_basic "$appimage_path"
    echo ""
    
    # Generate report
    generate_report "$appimage_path" "$report_file"
    echo ""
    
    # Final summary
    echo "Compatibility Check Summary:"
    echo "- Passed: $VALIDATION_PASSED"
    echo "- Warnings: $VALIDATION_WARNINGS"
    echo "- Failed: $VALIDATION_FAILED"
    echo ""
    
    if [ "$VALIDATION_FAILED" -eq 0 ]; then
        show_success "AppImage compatibility check PASSED"
        exit 0
    elif [ "$VALIDATION_FAILED" -le 2 ]; then
        show_warning "AppImage compatibility check completed with minor issues"
        exit 0
    else
        show_error "AppImage compatibility check FAILED"
        exit 1
    fi
}

# Run main function
main "$@"