#!/bin/bash
# Comprehensive AppImage Validation and Quality Assurance Script
# Validates build success, AppImage quality, and component integration

set -e

SOURCE_DIR=${PWD}/source
BUILD_DIR=${PWD}/build
OUTPUT_DIR=${PWD}/output
VALIDATION_DIR=${PWD}/validation
VALIDATION_REPORT=${VALIDATION_DIR}/validation-report.md

# Color codes for output
COLOR_SUCCESS=$'\033[1m\033[32m'
COLOR_WARNING=$'\033[1m\033[33m'
COLOR_ERROR=$'\033[1m\033[31m'
COLOR_INFO=$'\033[1m\033[34m'
COLOR_RESET=$'\033[0m'

# Validation results tracking
VALIDATION_PASSED=0
VALIDATION_FAILED=0
VALIDATION_WARNINGS=0

show_status() {
    echo "$COLOR_INFO=> $1$COLOR_RESET"
}

show_success() {
    echo "$COLOR_SUCCESS✓ $1$COLOR_RESET"
    VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
}

show_warning() {
    echo "$COLOR_WARNING⚠ $1$COLOR_RESET"
    VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
}

show_error() {
    echo "$COLOR_ERROR✗ $1$COLOR_RESET"
    VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
}

log_to_report() {
    echo "$1" >> "$VALIDATION_REPORT"
}

init_validation() {
    show_status "Initializing AppImage validation framework"
    mkdir -p "$VALIDATION_DIR"
    
    # Create validation report header
    cat > "$VALIDATION_REPORT" << EOF
# AppImage Validation Report

**Generated:** $(date)
**Target Architecture:** x86_64
**Build System:** Ubuntu 22.04 LTS with Qt5

## Executive Summary

This report provides comprehensive validation results for the mcpelauncher-linux AppImage build.

---

EOF
}

# 1. Build Success Verification
validate_build_success() {
    show_status "=== Build Success Verification ==="
    log_to_report "## 1. Build Success Verification"
    log_to_report ""
    
    # Check if output directory exists
    if [ -d "$OUTPUT_DIR" ]; then
        show_success "Output directory exists: $OUTPUT_DIR"
        log_to_report "- ✅ **Output Directory**: Found at $OUTPUT_DIR"
    else
        show_error "Output directory not found: $OUTPUT_DIR"
        log_to_report "- ❌ **Output Directory**: Not found at $OUTPUT_DIR"
        return 1
    fi
    
    # Find AppImage files
    local appimage_files=($(find "$OUTPUT_DIR" -name "*.AppImage" 2>/dev/null))
    if [ ${#appimage_files[@]} -gt 0 ]; then
        show_success "Found ${#appimage_files[@]} AppImage file(s)"
        log_to_report "- ✅ **AppImage Files**: Found ${#appimage_files[@]} file(s)"
        for appimage in "${appimage_files[@]}"; do
            local filename=$(basename "$appimage")
            local filesize=$(du -h "$appimage" | cut -f1)
            show_success "  AppImage: $filename ($filesize)"
            log_to_report "  - $filename ($filesize)"
        done
    else
        show_error "No AppImage files found in output directory"
        log_to_report "- ❌ **AppImage Files**: None found"
        return 1
    fi
    
    # Check for zsync files
    local zsync_files=($(find "$OUTPUT_DIR" -name "*.zsync" 2>/dev/null))
    if [ ${#zsync_files[@]} -gt 0 ]; then
        show_success "Found ${#zsync_files[@]} zsync file(s) for updates"
        log_to_report "- ✅ **Update Files**: Found ${#zsync_files[@]} zsync file(s)"
    else
        show_warning "No zsync files found (update capability disabled)"
        log_to_report "- ⚠️ **Update Files**: No zsync files found"
    fi
    
    # Verify build directories exist
    if [ -d "$BUILD_DIR" ]; then
        show_success "Build directory preserved: $BUILD_DIR"
        log_to_report "- ✅ **Build Directory**: Preserved for analysis"
    else
        show_warning "Build directory not found (may have been cleaned)"
        log_to_report "- ⚠️ **Build Directory**: Not found (possibly cleaned)"
    fi
    
    # Check source directories
    if [ -d "$SOURCE_DIR" ]; then
        show_success "Source directory available: $SOURCE_DIR"
        log_to_report "- ✅ **Source Directory**: Available for inspection"
        
        # Check individual components
        for component in msa mcpelauncher mcpelauncher-ui; do
            if [ -d "$SOURCE_DIR/$component" ]; then
                show_success "  Component source: $component"
                log_to_report "  - ✅ $component source directory"
            else
                show_warning "  Component source missing: $component"
                log_to_report "  - ⚠️ $component source directory missing"
            fi
        done
    else
        show_warning "Source directory not found"
        log_to_report "- ⚠️ **Source Directory**: Not found"
    fi
    
    log_to_report ""
}

# 2. AppImage Quality Assessment
validate_appimage_quality() {
    show_status "=== AppImage Quality Assessment ==="
    log_to_report "## 2. AppImage Quality Assessment"
    log_to_report ""
    
    local appimage_files=($(find "$OUTPUT_DIR" -name "*.AppImage" 2>/dev/null))
    if [ ${#appimage_files[@]} -eq 0 ]; then
        show_error "No AppImage files found for quality assessment"
        log_to_report "- ❌ **Quality Assessment**: No AppImage files to analyze"
        return 1
    fi
    
    for appimage in "${appimage_files[@]}"; do
        local filename=$(basename "$appimage")
        show_status "Analyzing AppImage: $filename"
        log_to_report "### Analysis: $filename"
        log_to_report ""
        
        # File permissions and executable check
        if [ -x "$appimage" ]; then
            show_success "  AppImage is executable"
            log_to_report "- ✅ **Executable**: File has execute permissions"
        else
            show_error "  AppImage is not executable"
            log_to_report "- ❌ **Executable**: Missing execute permissions"
            chmod +x "$appimage" 2>/dev/null && show_success "  Fixed: Made AppImage executable"
        fi
        
        # File size analysis
        local size_bytes=$(stat --printf="%s" "$appimage")
        local size_mb=$((size_bytes / 1024 / 1024))
        if [ $size_mb -lt 50 ]; then
            show_warning "  AppImage size unusually small: ${size_mb}MB"
            log_to_report "- ⚠️ **Size**: ${size_mb}MB (unusually small)"
        elif [ $size_mb -gt 500 ]; then
            show_warning "  AppImage size quite large: ${size_mb}MB"
            log_to_report "- ⚠️ **Size**: ${size_mb}MB (quite large)"
        else
            show_success "  AppImage size reasonable: ${size_mb}MB"
            log_to_report "- ✅ **Size**: ${size_mb}MB (reasonable)"
        fi
        
        # File type verification
        local file_type=$(file "$appimage" 2>/dev/null || echo "unknown")
        if echo "$file_type" | grep -q "ELF.*executable"; then
            show_success "  File type: ELF executable"
            log_to_report "- ✅ **File Type**: ELF executable"
        else
            show_warning "  Unexpected file type: $file_type"
            log_to_report "- ⚠️ **File Type**: $file_type"
        fi
        
        # Extract and analyze AppImage contents
        local temp_dir=$(mktemp -d)
        if "$appimage" --appimage-extract >/dev/null 2>&1; then
            local extract_dir="squashfs-root"
            if [ -d "$extract_dir" ]; then
                validate_appimage_structure "$extract_dir" "$filename"
                rm -rf "$extract_dir"
            fi
        else
            show_warning "  Could not extract AppImage for detailed analysis"
            log_to_report "- ⚠️ **Extraction**: Failed to extract AppImage contents"
        fi
        rm -rf "$temp_dir"
        
        log_to_report ""
    done
}

validate_appimage_structure() {
    local extract_dir="$1"
    local filename="$2"
    
    show_status "  Analyzing AppImage structure with enhanced validation"
    
    # Check for AppRun with executable permissions
    if [ -f "$extract_dir/AppRun" ]; then
        if [ -x "$extract_dir/AppRun" ]; then
            show_success "    AppRun script present and executable"
            log_to_report "- ✅ **AppRun**: Script present and executable"
        else
            show_error "    AppRun script present but not executable"
            log_to_report "- ❌ **AppRun**: Script not executable"
        fi
    else
        show_error "    AppRun script missing"
        log_to_report "- ❌ **AppRun**: Script missing"
    fi
    
    # Check for desktop file with validation
    local desktop_files=($(find "$extract_dir" -name "*.desktop" 2>/dev/null))
    if [ ${#desktop_files[@]} -gt 0 ]; then
        show_success "    Desktop file(s) found: ${#desktop_files[@]}"
        log_to_report "- ✅ **Desktop File**: Found ${#desktop_files[@]} file(s)"
        for desktop in "${desktop_files[@]}"; do
            validate_desktop_file "$desktop"
        done
    else
        show_error "    No desktop files found"
        log_to_report "- ❌ **Desktop File**: Not found"
    fi
    
    # Check for icon files
    local icon_files=($(find "$extract_dir" -name "*.png" -o -name "*.svg" -o -name "*.ico" 2>/dev/null))
    if [ ${#icon_files[@]} -gt 0 ]; then
        show_success "    Icon file(s) found: ${#icon_files[@]}"
        log_to_report "- ✅ **Icon Files**: Found ${#icon_files[@]} file(s)"
    else
        show_warning "    No icon files found"
        log_to_report "- ⚠️ **Icon Files**: Not found"
    fi
    
    # Check for main executable with comprehensive validation
    local main_executable=""
    if [ -f "$extract_dir/usr/bin/mcpelauncher-ui-qt" ]; then
        main_executable="$extract_dir/usr/bin/mcpelauncher-ui-qt"
        show_success "    Main executable: mcpelauncher-ui-qt"
        log_to_report "- ✅ **Main Executable**: mcpelauncher-ui-qt found"
    elif [ -f "$extract_dir/usr/bin/mcpelauncher-ui" ]; then
        main_executable="$extract_dir/usr/bin/mcpelauncher-ui"
        show_success "    Main executable: mcpelauncher-ui"
        log_to_report "- ✅ **Main Executable**: mcpelauncher-ui found"
    else
        show_error "    Main executable not found"
        log_to_report "- ❌ **Main Executable**: Not found"
    fi
    
    # Validate main executable if found
    if [ -n "$main_executable" ]; then
        if [ -x "$main_executable" ]; then
            show_success "    Main executable has correct permissions"
            log_to_report "- ✅ **Permissions**: Main executable is executable"
            
            # Check executable dependencies
            if command -v ldd >/dev/null 2>&1; then
                local missing_deps=$(ldd "$main_executable" 2>/dev/null | grep "not found" | wc -l)
                if [ "$missing_deps" -eq 0 ]; then
                    show_success "    Main executable dependencies satisfied"
                    log_to_report "- ✅ **Dependencies**: All dependencies satisfied"
                else
                    show_warning "    Main executable has $missing_deps missing dependencies"
                    log_to_report "- ⚠️ **Dependencies**: $missing_deps missing dependencies"
                fi
            fi
        else
            show_error "    Main executable not executable"
            log_to_report "- ❌ **Permissions**: Main executable not executable"
        fi
    fi
    
    # Check library bundling with enhanced validation
    local lib_count=$(find "$extract_dir/usr/lib" -name "*.so*" 2>/dev/null | wc -l)
    if [ $lib_count -gt 0 ]; then
        show_success "    Bundled libraries: $lib_count"
        log_to_report "- ✅ **Bundled Libraries**: $lib_count libraries found"
        
        # Check for Qt6 libraries specifically
        local qt6_lib_count=$(find "$extract_dir/usr/lib" -name "*Qt6*" 2>/dev/null | wc -l)
        if [ $qt6_lib_count -gt 0 ]; then
            show_success "    Qt6 libraries bundled: $qt6_lib_count"
            log_to_report "- ✅ **Qt6 Libraries**: $qt6_lib_count Qt6 libraries bundled"
        else
            show_warning "    No Qt6 libraries found in bundle"
            log_to_report "- ⚠️ **Qt6 Libraries**: No Qt6 libraries found"
        fi
    else
        show_warning "    No bundled libraries found"
        log_to_report "- ⚠️ **Bundled Libraries**: None found"
    fi
    
    # Check Qt plugins with comprehensive validation and stricter requirements
    if [ -d "$extract_dir/usr/plugins" ]; then
        local plugin_count=$(find "$extract_dir/usr/plugins" -name "*.so" 2>/dev/null | wc -l)
        show_success "    Qt plugins directory with $plugin_count plugins"
        log_to_report "- ✅ **Qt Plugins**: $plugin_count plugins found"
        
        # Check for essential Qt platform plugins (stricter validation)
        local essential_plugins=("platforms" "imageformats" "iconengines")
        local missing_essential=0
        
        for plugin_type in "${essential_plugins[@]}"; do
            if [ -d "$extract_dir/usr/plugins/$plugin_type" ]; then
                local type_count=$(find "$extract_dir/usr/plugins/$plugin_type" -name "*.so" 2>/dev/null | wc -l)
                if [ $type_count -gt 0 ]; then
                    show_success "      $plugin_type plugins: $type_count"
                    log_to_report "  - ✅ $plugin_type: $type_count plugins"
                else
                    show_error "      $plugin_type directory empty (CRITICAL)"
                    log_to_report "  - ❌ $plugin_type: Directory empty (CRITICAL)"
                    missing_essential=$((missing_essential + 1))
                fi
            else
                show_error "      $plugin_type directory missing (CRITICAL)"
                log_to_report "  - ❌ $plugin_type: Directory missing (CRITICAL)"
                missing_essential=$((missing_essential + 1))
            fi
        done
        
        # Check for Wayland plugins specifically (required for Qt6 builds)
        local wayland_plugins_found=0
        local wayland_plugin_dirs=("wayland-decoration-client" "wayland-graphics-integration-client" "wayland-shell-integration")
        
        for wayland_plugin in "${wayland_plugin_dirs[@]}"; do
            if [ -d "$extract_dir/usr/plugins/$wayland_plugin" ]; then
                local wayland_count=$(find "$extract_dir/usr/plugins/$wayland_plugin" -name "*.so" 2>/dev/null | wc -l)
                if [ $wayland_count -gt 0 ]; then
                    show_success "      $wayland_plugin plugins: $wayland_count"
                    log_to_report "  - ✅ $wayland_plugin: $wayland_count plugins"
                    wayland_plugins_found=$((wayland_plugins_found + 1))
                else
                    show_warning "      $wayland_plugin directory empty"
                    log_to_report "  - ⚠️ $wayland_plugin: Directory empty"
                fi
            else
                show_warning "      $wayland_plugin directory missing"
                log_to_report "  - ⚠️ $wayland_plugin: Directory missing"
            fi
        done
        
        if [ $wayland_plugins_found -gt 0 ]; then
            show_success "    Wayland plugins detected ($wayland_plugins_found types)"
            log_to_report "- ✅ **Wayland Support**: $wayland_plugins_found Wayland plugin types found"
        else
            show_warning "    No Wayland plugins found (may affect immutable OS compatibility)"
            log_to_report "- ⚠️ **Wayland Support**: No Wayland plugins found"
        fi
        
        # Check for WebEngine plugins (optional but recommended)
        if [ -d "$extract_dir/usr/plugins/webengine" ]; then
            local webengine_count=$(find "$extract_dir/usr/plugins/webengine" -name "*.so" 2>/dev/null | wc -l)
            if [ $webengine_count -gt 0 ]; then
                show_success "    WebEngine plugins detected: $webengine_count"
                log_to_report "- ✅ **WebEngine Support**: $webengine_count WebEngine plugins found"
            else
                show_warning "    WebEngine directory empty"
                log_to_report "- ⚠️ **WebEngine Support**: Directory empty"
            fi
        else
            show_warning "    No WebEngine plugins found (optional)"
            log_to_report "- ⚠️ **WebEngine Support**: No WebEngine plugins found (optional)"
        fi
        
        # Fail validation if critical plugins are missing
        if [ $missing_essential -gt 0 ]; then
            show_error "    CRITICAL: $missing_essential essential plugin directories missing or empty"
            log_to_report "- ❌ **CRITICAL FAILURE**: $missing_essential essential plugin directories missing"
        fi
    else
        show_error "    Qt plugins directory not found (CRITICAL)"
        log_to_report "- ❌ **Qt Plugins**: Directory not found (CRITICAL)"
    fi
    
    # Validate RPATH settings for bundled libraries
    if command -v readelf >/dev/null 2>&1 && [ -n "$main_executable" ]; then
        local rpath_info=$(readelf -d "$main_executable" 2>/dev/null | grep -E "(RPATH|RUNPATH)" || true)
        if [ -n "$rpath_info" ]; then
            show_success "    RPATH/RUNPATH configured for library loading"
            log_to_report "- ✅ **RPATH**: Configured for bundled libraries"
        else
            show_warning "    No RPATH/RUNPATH found (may rely on LD_LIBRARY_PATH)"
            log_to_report "- ⚠️ **RPATH**: Not configured (fallback to LD_LIBRARY_PATH)"
        fi
    fi
    
    # Check file permissions with comprehensive validation
    local executable_count=$(find "$extract_dir/usr/bin" -type f -executable 2>/dev/null | wc -l)
    local total_binaries=$(find "$extract_dir/usr/bin" -type f 2>/dev/null | wc -l)
    
    if [ $executable_count -gt 0 ]; then
        if [ $executable_count -eq $total_binaries ]; then
            show_success "    All executable files have correct permissions: $executable_count/$total_binaries"
            log_to_report "- ✅ **Permissions**: All $total_binaries executables have correct permissions"
        else
            show_warning "    Some executables missing permissions: $executable_count/$total_binaries"
            log_to_report "- ⚠️ **Permissions**: $executable_count/$total_binaries executables have correct permissions"
            
            # List files with incorrect permissions
            local non_executable_files=$(find "$extract_dir/usr/bin" -type f ! -executable 2>/dev/null)
            if [ -n "$non_executable_files" ]; then
                show_warning "    Files with incorrect permissions:"
                log_to_report "  - Files missing execute permissions:"
                while IFS= read -r file; do
                    local filename=$(basename "$file")
                    show_warning "      $filename"
                    log_to_report "    - $filename"
                done <<< "$non_executable_files"
            fi
        fi
    else
        if [ $total_binaries -gt 0 ]; then
            show_error "    No executable permissions on $total_binaries binary files (CRITICAL)"
            log_to_report "- ❌ **Permissions**: No executables found with correct permissions ($total_binaries files need fixing)"
        else
            show_warning "    No binary files found in usr/bin"
            log_to_report "- ⚠️ **Permissions**: No binary files found in usr/bin"
        fi
    fi
    
    # Check library permissions
    local lib_dir="$extract_dir/usr/lib"
    if [ -d "$lib_dir" ]; then
        local total_libs=$(find "$lib_dir" -name "*.so*" -type f 2>/dev/null | wc -l)
        local readable_libs=$(find "$lib_dir" -name "*.so*" -type f -readable 2>/dev/null | wc -l)
        
        if [ $total_libs -eq $readable_libs ] && [ $total_libs -gt 0 ]; then
            show_success "    All library files have correct permissions: $total_libs"
            log_to_report "- ✅ **Library Permissions**: All $total_libs libraries are readable"
        elif [ $total_libs -gt 0 ]; then
            show_warning "    Some libraries have permission issues: $readable_libs/$total_libs"
            log_to_report "- ⚠️ **Library Permissions**: $readable_libs/$total_libs libraries have correct permissions"
        fi
    fi
}

validate_desktop_file() {
    local desktop_file="$1"
    
    # Check required desktop file entries
    if grep -q "^Name=" "$desktop_file"; then
        show_success "      Desktop file has Name entry"
    else
        show_warning "      Desktop file missing Name entry"
    fi
    
    if grep -q "^Exec=" "$desktop_file"; then
        show_success "      Desktop file has Exec entry"
    else
        show_error "      Desktop file missing Exec entry"
    fi
    
    if grep -q "^Icon=" "$desktop_file"; then
        show_success "      Desktop file has Icon entry"
    else
        show_warning "      Desktop file missing Icon entry"
    fi
    
    if grep -q "^Categories=" "$desktop_file"; then
        show_success "      Desktop file has Categories entry"
    else
        show_warning "      Desktop file missing Categories entry"
    fi
}

# 3. Component Integration Validation
validate_component_integration() {
    show_status "=== mcpelauncher Component Integration ==="
    log_to_report "## 3. Component Integration Validation"
    log_to_report ""
    
    # Check build artifacts for each component
    validate_msa_component
    validate_mcpelauncher_component
    validate_mcpelauncher_ui_component
    
    log_to_report ""
}

validate_msa_component() {
    show_status "Validating MSA component"
    log_to_report "### MSA Component"
    log_to_report ""
    
    # MSA is disabled in modern build, so this should reflect that
    if [ -d "$SOURCE_DIR/msa" ]; then
        show_success "MSA source available (disabled in build)"
        log_to_report "- ✅ **MSA Source**: Available but disabled in clean restart strategy"
    else
        show_success "MSA component properly disabled"
        log_to_report "- ✅ **MSA Status**: Properly disabled per clean restart strategy"
    fi
    
    # Check if MSA libraries are NOT bundled (since it's disabled)
    local appimage_files=($(find "$OUTPUT_DIR" -name "*.AppImage" 2>/dev/null))
    for appimage in "${appimage_files[@]}"; do
        if "$appimage" --appimage-extract >/dev/null 2>&1; then
            local extract_dir="squashfs-root"
            if [ -d "$extract_dir" ]; then
                local msa_libs=$(find "$extract_dir" -name "*msa*" 2>/dev/null | wc -l)
                if [ $msa_libs -eq 0 ]; then
                    show_success "MSA libraries correctly excluded from AppImage"
                    log_to_report "- ✅ **MSA Exclusion**: No MSA libraries found in AppImage (as expected)"
                else
                    show_warning "Found $msa_libs MSA-related files in AppImage"
                    log_to_report "- ⚠️ **MSA Inclusion**: Found $msa_libs MSA-related files unexpectedly"
                fi
                rm -rf "$extract_dir"
            fi
        fi
    done
}

validate_mcpelauncher_component() {
    show_status "Validating mcpelauncher component"
    log_to_report "### mcpelauncher Component"
    log_to_report ""
    
    if [ -d "$SOURCE_DIR/mcpelauncher" ]; then
        show_success "mcpelauncher source directory found"
        log_to_report "- ✅ **Source**: mcpelauncher component source available"
        
        # Check for build artifacts
        if [ -d "$BUILD_DIR/mcpelauncher" ]; then
            show_success "mcpelauncher build directory found"
            log_to_report "- ✅ **Build Directory**: mcpelauncher build artifacts available"
            
            # Check for specific libraries/executables
            local client_found=false
            local server_found=false
            
            # Look for mcpelauncher-client
            if find "$BUILD_DIR/mcpelauncher" -name "*mcpelauncher-client*" -type f 2>/dev/null | grep -q .; then
                show_success "mcpelauncher-client found in build"
                log_to_report "- ✅ **Client**: mcpelauncher-client built successfully"
                client_found=true
            fi
            
            # Look for mcpelauncher-server  
            if find "$BUILD_DIR/mcpelauncher" -name "*mcpelauncher-server*" -type f 2>/dev/null | grep -q .; then
                show_success "mcpelauncher-server found in build"
                log_to_report "- ✅ **Server**: mcpelauncher-server built successfully"
                server_found=true
            fi
            
            if [ "$client_found" = false ] && [ "$server_found" = false ]; then
                show_warning "No mcpelauncher executables found in build directory"
                log_to_report "- ⚠️ **Executables**: No mcpelauncher executables found"
            fi
        else
            show_warning "mcpelauncher build directory not found"
            log_to_report "- ⚠️ **Build Directory**: Not found"
        fi
    else
        show_error "mcpelauncher source directory not found"
        log_to_report "- ❌ **Source**: mcpelauncher component source missing"
    fi
}

validate_mcpelauncher_ui_component() {
    show_status "Validating mcpelauncher-ui component"
    log_to_report "### mcpelauncher-ui Component"
    log_to_report ""
    
    if [ -d "$SOURCE_DIR/mcpelauncher-ui" ]; then
        show_success "mcpelauncher-ui source directory found"
        log_to_report "- ✅ **Source**: mcpelauncher-ui component source available"
        
        # Check for build artifacts
        if [ -d "$BUILD_DIR/mcpelauncher-ui" ]; then
            show_success "mcpelauncher-ui build directory found"
            log_to_report "- ✅ **Build Directory**: mcpelauncher-ui build artifacts available"
            
            # Look for UI executable
            if find "$BUILD_DIR/mcpelauncher-ui" -name "*mcpelauncher-ui*" -type f -executable 2>/dev/null | grep -q .; then
                show_success "mcpelauncher-ui executable found"
                log_to_report "- ✅ **UI Executable**: Built successfully"
            else
                show_warning "mcpelauncher-ui executable not found in build directory"
                log_to_report "- ⚠️ **UI Executable**: Not found in build directory"
            fi
        else
            show_warning "mcpelauncher-ui build directory not found"
            log_to_report "- ⚠️ **Build Directory**: Not found"
        fi
        
        # Check Qt5 integration in AppImage
        local appimage_files=($(find "$OUTPUT_DIR" -name "*.AppImage" 2>/dev/null))
        for appimage in "${appimage_files[@]}"; do
            if "$appimage" --appimage-extract >/dev/null 2>&1; then
                local extract_dir="squashfs-root"
                if [ -d "$extract_dir" ]; then
                    # Check for Qt5 libraries
                    local qt5_libs=$(find "$extract_dir" -name "*Qt5*" 2>/dev/null | wc -l)
                    if [ $qt5_libs -gt 0 ]; then
                        show_success "Qt5 libraries found in AppImage: $qt5_libs"
                        log_to_report "- ✅ **Qt5 Integration**: $qt5_libs Qt5 libraries bundled"
                    else
                        show_warning "No Qt5 libraries found in AppImage"
                        log_to_report "- ⚠️ **Qt5 Integration**: No Qt5 libraries found"
                    fi
                    
                    # Check for WebEngine integration
                    local webengine_libs=$(find "$extract_dir" -name "*WebEngine*" 2>/dev/null | wc -l)
                    if [ $webengine_libs -gt 0 ]; then
                        show_success "Qt WebEngine integration found: $webengine_libs files"
                        log_to_report "- ✅ **WebEngine**: $webengine_libs WebEngine files found"
                    else
                        show_warning "Qt WebEngine integration not found"
                        log_to_report "- ⚠️ **WebEngine**: Integration not found"
                    fi
                    
                    rm -rf "$extract_dir"
                fi
            fi
        done
    else
        show_error "mcpelauncher-ui source directory not found"
        log_to_report "- ❌ **Source**: mcpelauncher-ui component source missing"
    fi
}

# 4. Cross-Platform Compatibility Validation
validate_compatibility() {
    show_status "=== Cross-Platform Compatibility ==="
    log_to_report "## 4. Cross-Platform Compatibility"
    log_to_report ""
    
    validate_architecture_compatibility
    validate_library_compatibility
    validate_glibc_compatibility
    validate_graphics_compatibility
    
    log_to_report ""
}

validate_architecture_compatibility() {
    show_status "Validating x86_64 architecture compatibility"
    log_to_report "### Architecture Compatibility"
    log_to_report ""
    
    local appimage_files=($(find "$OUTPUT_DIR" -name "*.AppImage" 2>/dev/null))
    for appimage in "${appimage_files[@]}"; do
        local filename=$(basename "$appimage")
        
        # Check file architecture
        local arch_info=$(file "$appimage" | grep -o "x86-64\|x86_64\|64-bit" || echo "unknown")
        if echo "$arch_info" | grep -q "64"; then
            show_success "AppImage architecture: x86_64"
            log_to_report "- ✅ **Architecture**: x86_64 confirmed for $filename"
        else
            show_error "AppImage architecture not x86_64: $arch_info"
            log_to_report "- ❌ **Architecture**: Not x86_64 for $filename"
        fi
        
        # Check for 32-bit components (should not be present in clean restart)
        if "$appimage" --appimage-extract >/dev/null 2>&1; then
            local extract_dir="squashfs-root"
            if [ -d "$extract_dir" ]; then
                local bit32_files=$(find "$extract_dir" -type f -executable -exec file {} \; 2>/dev/null | grep -c "32-bit" || echo "0")
                if [ "$bit32_files" -eq 0 ]; then
                    show_success "No 32-bit executables found (clean x86_64 build)"
                    log_to_report "- ✅ **32-bit Exclusion**: No 32-bit executables (as expected)"
                else
                    show_warning "Found $bit32_files 32-bit executable(s)"
                    log_to_report "- ⚠️ **32-bit Presence**: Found $bit32_files 32-bit executables"
                fi
                rm -rf "$extract_dir"
            fi
        fi
    done
}

validate_library_compatibility() {
    show_status "Validating library compatibility"
    log_to_report "### Library Compatibility"
    log_to_report ""
    
    # Check system libraries
    show_status "Checking target system compatibility (Ubuntu 22.04 LTS)"
    
    # Key system libraries that should be compatible
    local key_libs=("libc.so.6" "libssl.so" "libcrypto.so" "libz.so" "libGL.so")
    
    for lib in "${key_libs[@]}"; do
        if ldconfig -p | grep -q "$lib"; then
            show_success "System library available: $lib"
            log_to_report "- ✅ **System Library**: $lib available"
        else
            show_warning "System library not found: $lib"
            log_to_report "- ⚠️ **System Library**: $lib not found"
        fi
    done
    
    # Check bundled libraries in AppImage
    local appimage_files=($(find "$OUTPUT_DIR" -name "*.AppImage" 2>/dev/null))
    for appimage in "${appimage_files[@]}"; do
        if "$appimage" --appimage-extract >/dev/null 2>&1; then
            local extract_dir="squashfs-root"
            if [ -d "$extract_dir" ]; then
                local lib_dir="$extract_dir/usr/lib"
                if [ -d "$lib_dir" ]; then
                    local bundled_count=$(find "$lib_dir" -name "*.so*" | wc -l)
                    show_success "Bundled libraries in AppImage: $bundled_count"
                    log_to_report "- ✅ **Bundled Libraries**: $bundled_count libraries included"
                    
                    # Check for critical libraries
                    for lib in "${key_libs[@]}"; do
                        if find "$lib_dir" -name "*$lib*" | grep -q .; then
                            show_success "  Critical library bundled: $lib"
                        fi
                    done
                fi
                rm -rf "$extract_dir"
            fi
        fi
    done
}

validate_glibc_compatibility() {
    show_status "Validating GLIBC compatibility"
    log_to_report "### GLIBC Compatibility"
    log_to_report ""
    
    # Check system GLIBC version
    local glibc_version=$(ldd --version | head -1 | grep -o "[0-9]\+\.[0-9]\+" || echo "unknown")
    show_success "System GLIBC version: $glibc_version"
    log_to_report "- ✅ **System GLIBC**: Version $glibc_version"
    
    # Check AppImage GLIBC requirements
    local appimage_files=($(find "$OUTPUT_DIR" -name "*.AppImage" 2>/dev/null))
    for appimage in "${appimage_files[@]}"; do
        local filename=$(basename "$appimage")
        
        # Extract and check executables for GLIBC requirements
        if "$appimage" --appimage-extract >/dev/null 2>&1; then
            local extract_dir="squashfs-root"
            if [ -d "$extract_dir" ]; then
                # Find main executable and check its GLIBC requirements
                local main_exec=$(find "$extract_dir/usr/bin" -type f -executable | head -1)
                if [ -n "$main_exec" ]; then
                    local required_glibc=$(objdump -T "$main_exec" 2>/dev/null | grep "GLIBC_" | grep -o "GLIBC_[0-9]\+\.[0-9]\+" | sort -V | tail -1 || echo "GLIBC_unknown")
                    if [ "$required_glibc" != "GLIBC_unknown" ]; then
                        local required_version=$(echo "$required_glibc" | grep -o "[0-9]\+\.[0-9]\+")
                        show_success "AppImage requires GLIBC: $required_version"
                        log_to_report "- ✅ **Required GLIBC**: $required_version for $filename"
                        
                        # Check compatibility
                        if [ "$(printf '%s\n' "$required_version" "$glibc_version" | sort -V | head -1)" = "$required_version" ]; then
                            show_success "GLIBC compatibility: OK"
                            log_to_report "- ✅ **GLIBC Compatibility**: System version $glibc_version >= required $required_version"
                        else
                            show_error "GLIBC compatibility: FAILED"
                            log_to_report "- ❌ **GLIBC Compatibility**: System version $glibc_version < required $required_version"
                        fi
                    else
                        show_warning "Could not determine GLIBC requirements"
                        log_to_report "- ⚠️ **GLIBC Requirements**: Could not determine for $filename"
                    fi
                fi
                rm -rf "$extract_dir"
            fi
        fi
    done
}

validate_graphics_compatibility() {
    show_status "Validating graphics stack compatibility"
    log_to_report "### Graphics Stack Compatibility"
    log_to_report ""
    
    # Check OpenGL libraries
    if ldconfig -p | grep -q "libGL.so"; then
        show_success "OpenGL library available"
        log_to_report "- ✅ **OpenGL**: Core library available"
    else
        show_error "OpenGL library not found"
        log_to_report "- ❌ **OpenGL**: Core library not found"
    fi
    
    if ldconfig -p | grep -q "libEGL.so"; then
        show_success "EGL library available"
        log_to_report "- ✅ **EGL**: Library available"
    else
        show_warning "EGL library not found"
        log_to_report "- ⚠️ **EGL**: Library not found"
    fi
    
    # Check for Mesa drivers
    if ldconfig -p | grep -q "mesa"; then
        show_success "Mesa drivers available"
        log_to_report "- ✅ **Mesa**: Drivers available"
    else
        show_warning "Mesa drivers not found"
        log_to_report "- ⚠️ **Mesa**: Drivers not found"
    fi
    
    # Check X11 libraries
    if ldconfig -p | grep -q "libX11.so"; then
        show_success "X11 library available"
        log_to_report "- ✅ **X11**: Core library available"
    else
        show_warning "X11 library not found"
        log_to_report "- ⚠️ **X11**: Core library not found"
    fi
    
    # Check AppImage graphics bundling
    local appimage_files=($(find "$OUTPUT_DIR" -name "*.AppImage" 2>/dev/null))
    for appimage in "${appimage_files[@]}"; do
        if "$appimage" --appimage-extract >/dev/null 2>&1; then
            local extract_dir="squashfs-root"
            if [ -d "$extract_dir" ]; then
                local gl_libs=$(find "$extract_dir" -name "*GL*" -o -name "*EGL*" | wc -l)
                if [ $gl_libs -gt 0 ]; then
                    show_success "Graphics libraries bundled: $gl_libs"
                    log_to_report "- ✅ **Bundled Graphics**: $gl_libs graphics libraries included"
                else
                    show_warning "No graphics libraries bundled"
                    log_to_report "- ⚠️ **Bundled Graphics**: No graphics libraries found"
                fi
                rm -rf "$extract_dir"
            fi
        fi
    done
}

# Generate final validation report
generate_final_report() {
    show_status "=== Generating Final Validation Report ==="
    
    # Add summary to report
    cat >> "$VALIDATION_REPORT" << EOF
## 5. Validation Summary

**Total Checks:** $((VALIDATION_PASSED + VALIDATION_FAILED + VALIDATION_WARNINGS))
**Passed:** $VALIDATION_PASSED ✅
**Failed:** $VALIDATION_FAILED ❌
**Warnings:** $VALIDATION_WARNINGS ⚠️

### Overall Status

EOF

    if [ $VALIDATION_FAILED -eq 0 ]; then
        if [ $VALIDATION_WARNINGS -eq 0 ]; then
            echo "**EXCELLENT** - All validation checks passed without warnings." >> "$VALIDATION_REPORT"
            show_success "Validation Status: EXCELLENT - All checks passed"
        else
            echo "**GOOD** - All critical checks passed with $VALIDATION_WARNINGS warning(s)." >> "$VALIDATION_REPORT"
            show_success "Validation Status: GOOD - Critical checks passed with warnings"
        fi
    else
        echo "**NEEDS ATTENTION** - $VALIDATION_FAILED critical check(s) failed." >> "$VALIDATION_REPORT"
        show_error "Validation Status: NEEDS ATTENTION - Critical failures detected"
    fi
    
    cat >> "$VALIDATION_REPORT" << EOF

### Deployment Readiness

EOF

    if [ $VALIDATION_FAILED -eq 0 ]; then
        cat >> "$VALIDATION_REPORT" << EOF
The AppImage appears to be **ready for deployment** with the following considerations:

- ✅ **Build Success**: All build phases completed successfully
- ✅ **AppImage Quality**: Meets quality standards for distribution
- ✅ **Component Integration**: mcpelauncher components properly integrated
- ✅ **Compatibility**: Compatible with target Linux distributions

EOF
        if [ $VALIDATION_WARNINGS -gt 0 ]; then
            echo "**Note**: $VALIDATION_WARNINGS warning(s) should be reviewed but do not block deployment." >> "$VALIDATION_REPORT"
        fi
    else
        cat >> "$VALIDATION_REPORT" << EOF
The AppImage **requires fixes** before deployment:

- ❌ **Critical Issues**: $VALIDATION_FAILED issue(s) must be resolved
- ⚠️ **Warnings**: $VALIDATION_WARNINGS warning(s) should be reviewed

EOF
    fi
    
    cat >> "$VALIDATION_REPORT" << EOF

### Recommendations

1. **Performance Testing**: Conduct runtime performance testing with actual Minecraft content
2. **User Acceptance Testing**: Test on clean Ubuntu 22.04 LTS systems
3. **Security Review**: Perform security audit of bundled libraries
4. **Documentation**: Update user documentation with system requirements

---

**Report Generated:** $(date)  
**Validation Framework Version:** 1.0.0  
**Repository:** torporsche/appimage-builder
EOF

    show_status "Validation report saved to: $VALIDATION_REPORT"
    
    # Display final statistics
    echo ""
    echo "=== VALIDATION COMPLETE ==="
    echo "Passed: $COLOR_SUCCESS$VALIDATION_PASSED$COLOR_RESET"
    echo "Failed: $COLOR_ERROR$VALIDATION_FAILED$COLOR_RESET"
    echo "Warnings: $COLOR_WARNING$VALIDATION_WARNINGS$COLOR_RESET"
    echo "Report: $VALIDATION_REPORT"
    echo ""
    
    # Return appropriate exit code
    if [ $VALIDATION_FAILED -gt 0 ]; then
        return 1
    else
        return 0
    fi
}

# Main validation function
main() {
    echo ""
    echo "=================================================="
    echo "AppImage Validation and Quality Assurance"
    echo "=================================================="
    echo ""
    
    init_validation
    
    validate_build_success
    validate_appimage_quality
    validate_component_integration
    validate_compatibility
    
    generate_final_report
}

# Parse command line arguments
while getopts "h?v" opt; do
    case "$opt" in
    h|\?)
        echo "AppImage Validation Script"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  -h    Show this help message"
        echo "  -v    Verbose output"
        echo ""
        echo "This script validates the AppImage build for:"
        echo "  - Build success verification"
        echo "  - AppImage quality assessment"
        echo "  - Component integration testing"
        echo "  - Cross-platform compatibility"
        echo ""
        exit 0
        ;;
    v)  set -x
        ;;
    esac
done

# Run main validation
main "$@"