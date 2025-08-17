#!/bin/bash
# Qt6 Plugin Validation Integration Test
# Tests for Qt6 plugin presence, structure, and permissions in AppImage builds

set -e

SOURCE_DIR=${PWD}/source
BUILD_DIR=${PWD}/build
OUTPUT_DIR=${PWD}/output
TEST_DIR=${PWD}/validation/plugin-tests
TEST_REPORT=${TEST_DIR}/qt6-plugin-test-report.md

# Color codes for output
COLOR_SUCCESS=$'\033[1m\033[32m'
COLOR_WARNING=$'\033[1m\033[33m'
COLOR_ERROR=$'\033[1m\033[31m'
COLOR_INFO=$'\033[1m\033[34m'
COLOR_RESET=$'\033[0m'

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

show_status() {
    echo "$COLOR_INFO=> $1$COLOR_RESET"
}

show_success() {
    echo "$COLOR_SUCCESS✓ $1$COLOR_RESET"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

show_warning() {
    echo "$COLOR_WARNING⚠ $1$COLOR_RESET"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
}

show_error() {
    echo "$COLOR_ERROR✗ $1$COLOR_RESET"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

log_to_report() {
    echo "$1" >> "$TEST_REPORT"
}

init_test() {
    show_status "Initializing Qt6 plugin validation tests"
    mkdir -p "$TEST_DIR"
    
    cat > "$TEST_REPORT" << EOF
# Qt6 Plugin Validation Test Report

**Generated:** $(date)
**Target:** Qt6 AppImage Plugin Structure and Permissions
**Repository:** torporsche/appimage-builder

## Test Summary

This report validates Qt6 plugin structure and permissions in the built AppImage.

---

EOF
}

test_essential_plugins() {
    show_status "=== Testing Essential Qt6 Plugins ==="
    log_to_report "## Essential Qt6 Plugins Test"
    log_to_report ""
    
    local appimage_files=($(find "$OUTPUT_DIR" -name "*.AppImage" 2>/dev/null))
    if [ ${#appimage_files[@]} -eq 0 ]; then
        show_error "No AppImage files found for plugin testing"
        log_to_report "- ❌ **Plugin Test**: No AppImage files found"
        return 1
    fi
    
    for appimage in "${appimage_files[@]}"; do
        local filename=$(basename "$appimage")
        show_status "Testing plugins in: $filename"
        log_to_report "### Testing: $filename"
        log_to_report ""
        
        # Extract AppImage
        if "$appimage" --appimage-extract >/dev/null 2>&1; then
            local extract_dir="squashfs-root"
            
            # Test essential plugin directories
            local essential_plugins=("platforms" "imageformats" "iconengines")
            local essential_missing=0
            
            for plugin_type in "${essential_plugins[@]}"; do
                local plugin_dir="$extract_dir/usr/plugins/$plugin_type"
                if [ -d "$plugin_dir" ]; then
                    local plugin_count=$(find "$plugin_dir" -name "*.so" 2>/dev/null | wc -l)
                    if [ $plugin_count -gt 0 ]; then
                        show_success "Essential plugin type '$plugin_type': $plugin_count plugins"
                        log_to_report "- ✅ **$plugin_type**: $plugin_count plugins found"
                        
                        # Test plugin permissions
                        local readable_plugins=$(find "$plugin_dir" -name "*.so" -readable 2>/dev/null | wc -l)
                        if [ $readable_plugins -eq $plugin_count ]; then
                            show_success "  All $plugin_type plugins are readable"
                            log_to_report "  - ✅ Permissions: All readable"
                        else
                            show_error "  Some $plugin_type plugins have permission issues"
                            log_to_report "  - ❌ Permissions: $readable_plugins/$plugin_count readable"
                        fi
                    else
                        show_error "Essential plugin directory '$plugin_type' is empty"
                        log_to_report "- ❌ **$plugin_type**: Directory empty"
                        essential_missing=$((essential_missing + 1))
                    fi
                else
                    show_error "Essential plugin directory '$plugin_type' missing"
                    log_to_report "- ❌ **$plugin_type**: Directory missing"
                    essential_missing=$((essential_missing + 1))
                fi
            done
            
            # Summary for essential plugins
            if [ $essential_missing -eq 0 ]; then
                show_success "All essential plugin types present and valid"
                log_to_report "- ✅ **Essential Plugins**: All required types present"
            else
                show_error "Missing $essential_missing essential plugin types"
                log_to_report "- ❌ **Essential Plugins**: $essential_missing types missing"
            fi
            
            rm -rf "$extract_dir"
        else
            show_error "Failed to extract AppImage for plugin testing"
            log_to_report "- ❌ **Extraction**: Failed to extract AppImage"
        fi
        
        log_to_report ""
    done
}

test_wayland_plugins() {
    show_status "=== Testing Qt6 Wayland Plugins ==="
    log_to_report "## Qt6 Wayland Plugins Test"
    log_to_report ""
    
    local appimage_files=($(find "$OUTPUT_DIR" -name "*.AppImage" 2>/dev/null))
    
    for appimage in "${appimage_files[@]}"; do
        local filename=$(basename "$appimage")
        show_status "Testing Wayland plugins in: $filename"
        log_to_report "### Wayland Testing: $filename"
        log_to_report ""
        
        if "$appimage" --appimage-extract >/dev/null 2>&1; then
            local extract_dir="squashfs-root"
            
            # Test Wayland-specific plugin directories
            local wayland_plugins=("wayland-decoration-client" "wayland-graphics-integration-client" "wayland-shell-integration")
            local wayland_found=0
            
            for wayland_plugin in "${wayland_plugins[@]}"; do
                local plugin_dir="$extract_dir/usr/plugins/$wayland_plugin"
                if [ -d "$plugin_dir" ]; then
                    local plugin_count=$(find "$plugin_dir" -name "*.so" 2>/dev/null | wc -l)
                    if [ $plugin_count -gt 0 ]; then
                        show_success "Wayland plugin type '$wayland_plugin': $plugin_count plugins"
                        log_to_report "- ✅ **$wayland_plugin**: $plugin_count plugins found"
                        wayland_found=$((wayland_found + 1))
                        
                        # Test specific plugin files
                        find "$plugin_dir" -name "*.so" 2>/dev/null | while read -r plugin_file; do
                            local plugin_name=$(basename "$plugin_file")
                            if [ -r "$plugin_file" ]; then
                                show_success "  Plugin readable: $plugin_name"
                            else
                                show_error "  Plugin not readable: $plugin_name"
                            fi
                        done
                    else
                        show_warning "Wayland plugin directory '$wayland_plugin' is empty"
                        log_to_report "- ⚠️ **$wayland_plugin**: Directory empty"
                    fi
                else
                    show_warning "Wayland plugin directory '$wayland_plugin' missing"
                    log_to_report "- ⚠️ **$wayland_plugin**: Directory missing"
                fi
            done
            
            # Summary for Wayland plugins
            if [ $wayland_found -gt 0 ]; then
                show_success "Wayland support present: $wayland_found plugin types found"
                log_to_report "- ✅ **Wayland Support**: $wayland_found plugin types present"
            else
                show_warning "No Wayland plugins found (may affect immutable OS compatibility)"
                log_to_report "- ⚠️ **Wayland Support**: No Wayland plugins found"
            fi
            
            rm -rf "$extract_dir"
        fi
        
        log_to_report ""
    done
}

test_webengine_plugins() {
    show_status "=== Testing Qt6 WebEngine Plugins ==="
    log_to_report "## Qt6 WebEngine Plugins Test"
    log_to_report ""
    
    local appimage_files=($(find "$OUTPUT_DIR" -name "*.AppImage" 2>/dev/null))
    
    for appimage in "${appimage_files[@]}"; do
        local filename=$(basename "$appimage")
        show_status "Testing WebEngine plugins in: $filename"
        log_to_report "### WebEngine Testing: $filename"
        log_to_report ""
        
        if "$appimage" --appimage-extract >/dev/null 2>&1; then
            local extract_dir="squashfs-root"
            
            # Test WebEngine plugin directory
            local webengine_dir="$extract_dir/usr/plugins/webengine"
            if [ -d "$webengine_dir" ]; then
                local plugin_count=$(find "$webengine_dir" -name "*.so" 2>/dev/null | wc -l)
                if [ $plugin_count -gt 0 ]; then
                    show_success "WebEngine plugins found: $plugin_count"
                    log_to_report "- ✅ **WebEngine**: $plugin_count plugins found"
                    
                    # Test WebEngine libraries
                    local webengine_libs=$(find "$extract_dir" -name "*WebEngine*" -type f 2>/dev/null | wc -l)
                    show_success "WebEngine libraries found: $webengine_libs"
                    log_to_report "- ✅ **WebEngine Libraries**: $webengine_libs files found"
                else
                    show_warning "WebEngine plugin directory is empty"
                    log_to_report "- ⚠️ **WebEngine**: Plugin directory empty"
                fi
            else
                show_warning "WebEngine plugin directory missing (optional)"
                log_to_report "- ⚠️ **WebEngine**: Plugin directory missing (optional)"
            fi
            
            rm -rf "$extract_dir"
        fi
        
        log_to_report ""
    done
}

test_plugin_structure_integrity() {
    show_status "=== Testing Plugin Structure Integrity ==="
    log_to_report "## Plugin Structure Integrity Test"
    log_to_report ""
    
    local appimage_files=($(find "$OUTPUT_DIR" -name "*.AppImage" 2>/dev/null))
    
    for appimage in "${appimage_files[@]}"; do
        local filename=$(basename "$appimage")
        show_status "Testing plugin structure in: $filename"
        log_to_report "### Structure Testing: $filename"
        log_to_report ""
        
        if "$appimage" --appimage-extract >/dev/null 2>&1; then
            local extract_dir="squashfs-root"
            local plugins_root="$extract_dir/usr/plugins"
            
            if [ -d "$plugins_root" ]; then
                # Count total plugins
                local total_plugins=$(find "$plugins_root" -name "*.so" 2>/dev/null | wc -l)
                show_success "Total plugins found: $total_plugins"
                log_to_report "- ✅ **Total Plugins**: $total_plugins plugin files"
                
                # Test plugin file integrity
                local corrupted_plugins=0
                find "$plugins_root" -name "*.so" 2>/dev/null | while read -r plugin_file; do
                    if file "$plugin_file" | grep -q "ELF.*shared object"; then
                        show_success "  Plugin valid: $(basename "$plugin_file")"
                    else
                        show_error "  Plugin corrupted: $(basename "$plugin_file")"
                        corrupted_plugins=$((corrupted_plugins + 1))
                    fi
                done
                
                # Test directory structure
                local plugin_dirs=$(find "$plugins_root" -type d -mindepth 1 | wc -l)
                show_success "Plugin directories found: $plugin_dirs"
                log_to_report "- ✅ **Plugin Directories**: $plugin_dirs directories"
                
                # Test file permissions consistency
                local all_plugins=$(find "$plugins_root" -name "*.so" 2>/dev/null | wc -l)
                local readable_plugins=$(find "$plugins_root" -name "*.so" -readable 2>/dev/null | wc -l)
                
                if [ $all_plugins -eq $readable_plugins ]; then
                    show_success "All plugins have correct permissions"
                    log_to_report "- ✅ **Plugin Permissions**: All $all_plugins plugins readable"
                else
                    show_error "Some plugins have permission issues: $readable_plugins/$all_plugins"
                    log_to_report "- ❌ **Plugin Permissions**: $readable_plugins/$all_plugins readable"
                fi
            else
                show_error "No plugins directory found"
                log_to_report "- ❌ **Plugin Structure**: No plugins directory found"
            fi
            
            rm -rf "$extract_dir"
        fi
        
        log_to_report ""
    done
}

generate_final_test_report() {
    show_status "=== Generating Final Test Report ==="
    
    cat >> "$TEST_REPORT" << EOF
## Test Results Summary

**Total Tests:** $((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))
**Passed:** $TESTS_PASSED ✅
**Failed:** $TESTS_FAILED ❌
**Skipped:** $TESTS_SKIPPED ⚠️

### Overall Plugin Validation Status

EOF

    if [ $TESTS_FAILED -eq 0 ]; then
        if [ $TESTS_SKIPPED -eq 0 ]; then
            echo "**EXCELLENT** - All Qt6 plugin tests passed without issues." >> "$TEST_REPORT"
            show_success "Plugin Validation Status: EXCELLENT"
        else
            echo "**GOOD** - All critical plugin tests passed with $TESTS_SKIPPED warning(s)." >> "$TEST_REPORT"
            show_success "Plugin Validation Status: GOOD"
        fi
    else
        echo "**NEEDS ATTENTION** - $TESTS_FAILED plugin test(s) failed." >> "$TEST_REPORT"
        show_error "Plugin Validation Status: NEEDS ATTENTION"
    fi
    
    cat >> "$TEST_REPORT" << EOF

### Key Findings

1. **Essential Plugins**: Platform, imageformats, and iconengines plugin presence and integrity
2. **Wayland Support**: Qt6 Wayland plugin availability for immutable OS compatibility
3. **WebEngine Support**: Qt6 WebEngine plugin presence for web functionality
4. **Structure Integrity**: Plugin file validity and permission consistency

### Recommendations

1. **Essential Plugins**: All platform, imageformats, and iconengines plugins must be present
2. **Wayland Plugins**: At least one Wayland plugin type should be available for modern desktop compatibility
3. **Permissions**: All plugin files must have proper read permissions
4. **File Integrity**: All plugin files should be valid ELF shared objects

---

**Report Generated:** $(date)  
**Plugin Test Framework Version:** 1.0.0  
**Repository:** torporsche/appimage-builder
EOF

    show_status "Plugin test report saved to: $TEST_REPORT"
    
    # Display final statistics
    echo ""
    echo "=== PLUGIN VALIDATION COMPLETE ==="
    echo "Passed: $COLOR_SUCCESS$TESTS_PASSED$COLOR_RESET"
    echo "Failed: $COLOR_ERROR$TESTS_FAILED$COLOR_RESET"
    echo "Skipped: $COLOR_WARNING$TESTS_SKIPPED$COLOR_RESET"
    echo "Report: $TEST_REPORT"
    echo ""
    
    # Return appropriate exit code
    if [ $TESTS_FAILED -gt 0 ]; then
        return 1
    else
        return 0
    fi
}

# Main test function
main() {
    echo ""
    echo "=================================================="
    echo "Qt6 Plugin Validation Integration Test"
    echo "=================================================="
    echo ""
    
    init_test
    
    test_essential_plugins
    test_wayland_plugins  
    test_webengine_plugins
    test_plugin_structure_integrity
    
    generate_final_test_report
}

# Parse command line arguments
while getopts "h?v" opt; do
    case "$opt" in
    h|\?)
        echo "Qt6 Plugin Validation Test Script"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  -h    Show this help message"
        echo "  -v    Verbose output"
        echo ""
        echo "This script validates Qt6 plugin structure in AppImage builds:"
        echo "  - Essential plugin presence and integrity"
        echo "  - Wayland plugin availability"
        echo "  - WebEngine plugin support"
        echo "  - Plugin file permissions and structure"
        echo ""
        exit 0
        ;;
    v)  set -x
        ;;
    esac
done

# Run main testing
main "$@"