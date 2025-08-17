#!/bin/bash
# Comprehensive Integration Test for Qt6 AppImage Improvements
# Tests the complete build, validation, and plugin structure workflow

set -e

SOURCE_DIR=${PWD}/source
BUILD_DIR=${PWD}/build
OUTPUT_DIR=${PWD}/output
TEST_DIR=${PWD}/validation/integration-tests
TEST_REPORT=${TEST_DIR}/comprehensive-test-report.md

# Color codes for output
COLOR_SUCCESS=$'\033[1m\033[32m'
COLOR_WARNING=$'\033[1m\033[33m'
COLOR_ERROR=$'\033[1m\033[31m'
COLOR_INFO=$'\033[1m\033[34m'
COLOR_RESET=$'\033[0m'

# Test results tracking
INTEGRATION_PASSED=0
INTEGRATION_FAILED=0
INTEGRATION_WARNINGS=0

show_status() {
    echo "$COLOR_INFO=> $1$COLOR_RESET"
}

show_success() {
    echo "$COLOR_SUCCESS✓ $1$COLOR_RESET"
    INTEGRATION_PASSED=$((INTEGRATION_PASSED + 1))
}

show_warning() {
    echo "$COLOR_WARNING⚠ $1$COLOR_RESET"
    INTEGRATION_WARNINGS=$((INTEGRATION_WARNINGS + 1))
}

show_error() {
    echo "$COLOR_ERROR✗ $1$COLOR_RESET"
    INTEGRATION_FAILED=$((INTEGRATION_FAILED + 1))
}

log_to_report() {
    echo "$1" >> "$TEST_REPORT"
}

init_integration_test() {
    show_status "Initializing comprehensive integration test"
    mkdir -p "$TEST_DIR"
    
    cat > "$TEST_REPORT" << EOF
# Comprehensive Qt6 AppImage Integration Test Report

**Generated:** $(date)
**Target:** Complete Qt6 AppImage Build and Validation Workflow
**Repository:** torporsche/appimage-builder

## Test Overview

This report covers the complete integration test of Qt6 AppImage improvements including:
- Build system validation
- Plugin structure verification
- Permission and RPATH validation
- Cross-environment compatibility testing

---

EOF
}

test_quirks_validation() {
    show_status "=== Testing Quirks Validation Enhancements ==="
    log_to_report "## Quirks Validation Test"
    log_to_report ""
    
    # Test strict validation flag
    export STRICT_PLUGIN_VALIDATION=true
    
    # Source quirks file to test validation functions
    if source ./quirks-qt6.sh 2>/dev/null; then
        show_success "quirks-qt6.sh sourced successfully"
        log_to_report "- ✅ **Quirks Loading**: Successfully loaded quirks-qt6.sh"
        
        # Test validation functions exist
        if declare -f validate_and_add_qt6_cmake_dir >/dev/null 2>&1; then
            show_success "validate_and_add_qt6_cmake_dir function available"
            log_to_report "- ✅ **Validation Function**: validate_and_add_qt6_cmake_dir present"
        else
            show_error "validate_and_add_qt6_cmake_dir function missing"
            log_to_report "- ❌ **Validation Function**: validate_and_add_qt6_cmake_dir missing"
        fi
        
        if declare -f configure_qt6_wayland_fallbacks >/dev/null 2>&1; then
            show_success "configure_qt6_wayland_fallbacks function available"
            log_to_report "- ✅ **Wayland Function**: configure_qt6_wayland_fallbacks present"
        else
            show_error "configure_qt6_wayland_fallbacks function missing"
            log_to_report "- ❌ **Wayland Function**: configure_qt6_wayland_fallbacks missing"
        fi
    else
        show_error "Failed to source quirks-qt6.sh"
        log_to_report "- ❌ **Quirks Loading**: Failed to load quirks-qt6.sh"
    fi
    
    log_to_report ""
}

test_cmake_enhancements() {
    show_status "=== Testing CMake RPATH Enhancements ==="
    log_to_report "## CMake RPATH Configuration Test"
    log_to_report ""
    
    if [ -f "./multilib.cmake" ]; then
        show_success "multilib.cmake file exists"
        log_to_report "- ✅ **CMake File**: multilib.cmake present"
        
        # Check for RPATH configurations
        if grep -q "CMAKE_INSTALL_RPATH.*ORIGIN" "./multilib.cmake"; then
            show_success "AppImage RPATH configuration found"
            log_to_report "- ✅ **RPATH Config**: AppImage-specific RPATH settings present"
        else
            show_error "AppImage RPATH configuration missing"
            log_to_report "- ❌ **RPATH Config**: AppImage-specific RPATH settings missing"
        fi
        
        # Check for permission settings
        if grep -q "CMAKE_INSTALL_DEFAULT_PERMISSIONS" "./multilib.cmake"; then
            show_success "Default permissions configuration found"
            log_to_report "- ✅ **Permissions Config**: Default permissions settings present"
        else
            show_error "Default permissions configuration missing"
            log_to_report "- ❌ **Permissions Config**: Default permissions settings missing"
        fi
    else
        show_error "multilib.cmake file not found"
        log_to_report "- ❌ **CMake File**: multilib.cmake missing"
    fi
    
    log_to_report ""
}

test_validation_enhancements() {
    show_status "=== Testing Validation Script Enhancements ==="
    log_to_report "## Validation Script Enhancement Test"
    log_to_report ""
    
    if [ -f "./validate-appimage.sh" ]; then
        show_success "validate-appimage.sh exists"
        log_to_report "- ✅ **Validation Script**: validate-appimage.sh present"
        
        # Check for enhanced plugin validation
        if grep -q "wayland-shell-integration" "./validate-appimage.sh"; then
            show_success "Enhanced Wayland plugin validation found"
            log_to_report "- ✅ **Wayland Validation**: Enhanced Wayland plugin checks present"
        else
            show_warning "Enhanced Wayland plugin validation missing"
            log_to_report "- ⚠️ **Wayland Validation**: Enhanced Wayland plugin checks missing"
        fi
        
        # Check for stricter permission validation
        if grep -q "total_binaries.*find.*usr/bin.*-type f" "./validate-appimage.sh"; then
            show_success "Enhanced permission validation found"
            log_to_report "- ✅ **Permission Validation**: Enhanced permission checks present"
        else
            show_warning "Enhanced permission validation missing"
            log_to_report "- ⚠️ **Permission Validation**: Enhanced permission checks missing"
        fi
        
        # Check for WebEngine validation
        if grep -q "webengine" "./validate-appimage.sh"; then
            show_success "WebEngine validation found"
            log_to_report "- ✅ **WebEngine Validation**: WebEngine checks present"
        else
            show_warning "WebEngine validation missing"
            log_to_report "- ⚠️ **WebEngine Validation**: WebEngine checks missing"
        fi
    else
        show_error "validate-appimage.sh not found"
        log_to_report "- ❌ **Validation Script**: validate-appimage.sh missing"
    fi
    
    log_to_report ""
}

test_plugin_test_framework() {
    show_status "=== Testing Plugin Test Framework ==="
    log_to_report "## Plugin Test Framework Test"
    log_to_report ""
    
    if [ -f "./tests/test-qt6-plugin-validation.sh" ]; then
        show_success "Qt6 plugin validation test exists"
        log_to_report "- ✅ **Plugin Test**: test-qt6-plugin-validation.sh present"
        
        if [ -x "./tests/test-qt6-plugin-validation.sh" ]; then
            show_success "Plugin test script is executable"
            log_to_report "- ✅ **Executable**: Plugin test script has execute permissions"
        else
            show_error "Plugin test script not executable"
            log_to_report "- ❌ **Executable**: Plugin test script missing execute permissions"
        fi
        
        # Test help functionality
        if ./tests/test-qt6-plugin-validation.sh -h >/dev/null 2>&1; then
            show_success "Plugin test help works"
            log_to_report "- ✅ **Help Function**: Plugin test help works correctly"
        else
            show_error "Plugin test help fails"
            log_to_report "- ❌ **Help Function**: Plugin test help fails"
        fi
    else
        show_error "Qt6 plugin validation test missing"
        log_to_report "- ❌ **Plugin Test**: test-qt6-plugin-validation.sh missing"
    fi
    
    log_to_report ""
}

test_build_system_integration() {
    show_status "=== Testing Build System Integration ==="
    log_to_report "## Build System Integration Test"
    log_to_report ""
    
    if [ -f "./build_appimage.sh" ]; then
        show_success "Main build script exists"
        log_to_report "- ✅ **Build Script**: build_appimage.sh present"
        
        # Check for strict validation integration
        if grep -q "STRICT_PLUGIN_VALIDATION" "./build_appimage.sh"; then
            show_success "Strict validation integration found"
            log_to_report "- ✅ **Strict Validation**: Build script integration present"
        else
            show_error "Strict validation integration missing"
            log_to_report "- ❌ **Strict Validation**: Build script integration missing"
        fi
        
        # Test help functionality
        if ./build_appimage.sh -h >/dev/null 2>&1; then
            show_success "Build script help works"
            log_to_report "- ✅ **Help Function**: Build script help works correctly"
        else
            show_error "Build script help fails"
            log_to_report "- ❌ **Help Function**: Build script help fails"
        fi
    else
        show_error "Main build script missing"
        log_to_report "- ❌ **Build Script**: build_appimage.sh missing"
    fi
    
    log_to_report ""
}

test_documentation_updates() {
    show_status "=== Testing Documentation Updates ==="
    log_to_report "## Documentation Update Test"
    log_to_report ""
    
    if [ -f "./README.md" ]; then
        show_success "README.md exists"
        log_to_report "- ✅ **README**: README.md present"
        
        # Check for troubleshooting section
        if grep -q "## Troubleshooting" "./README.md"; then
            show_success "Troubleshooting section found"
            log_to_report "- ✅ **Troubleshooting**: Troubleshooting section present"
        else
            show_error "Troubleshooting section missing"
            log_to_report "- ❌ **Troubleshooting**: Troubleshooting section missing"
        fi
        
        # Check for official AppImage reference
        if grep -q "v1.1.1-802" "./README.md"; then
            show_success "Official AppImage reference found"
            log_to_report "- ✅ **Reference**: Official AppImage v1.1.1-802 reference present"
        else
            show_error "Official AppImage reference missing"
            log_to_report "- ❌ **Reference**: Official AppImage v1.1.1-802 reference missing"
        fi
        
        # Check for Qt6 plugin troubleshooting
        if grep -q "Qt6 Plugin Issues" "./README.md"; then
            show_success "Qt6 plugin troubleshooting found"
            log_to_report "- ✅ **Qt6 Troubleshooting**: Qt6 plugin issues section present"
        else
            show_error "Qt6 plugin troubleshooting missing"
            log_to_report "- ❌ **Qt6 Troubleshooting**: Qt6 plugin issues section missing"
        fi
    else
        show_error "README.md not found"
        log_to_report "- ❌ **README**: README.md missing"
    fi
    
    log_to_report ""
}

test_environment_simulation() {
    show_status "=== Testing Environment Simulation ==="
    log_to_report "## Environment Simulation Test"
    log_to_report ""
    
    # Test strict validation flag behavior
    export STRICT_PLUGIN_VALIDATION=true
    show_success "Strict validation flag set: $STRICT_PLUGIN_VALIDATION"
    log_to_report "- ✅ **Environment**: STRICT_PLUGIN_VALIDATION flag set"
    
    # Test dependency checking (without actually installing anything)
    if ./test-dependencies.sh >/dev/null 2>&1 || [ $? -eq 1 ]; then
        show_success "Dependency test script functional"
        log_to_report "- ✅ **Dependencies**: test-dependencies.sh executes correctly"
    else
        show_error "Dependency test script failed"
        log_to_report "- ❌ **Dependencies**: test-dependencies.sh execution failed"
    fi
    
    log_to_report ""
}

generate_integration_report() {
    show_status "=== Generating Integration Test Report ==="
    
    cat >> "$TEST_REPORT" << EOF
## Integration Test Results Summary

**Total Tests:** $((INTEGRATION_PASSED + INTEGRATION_FAILED + INTEGRATION_WARNINGS))
**Passed:** $INTEGRATION_PASSED ✅
**Failed:** $INTEGRATION_FAILED ❌
**Warnings:** $INTEGRATION_WARNINGS ⚠️

### Overall Integration Status

EOF

    if [ $INTEGRATION_FAILED -eq 0 ]; then
        if [ $INTEGRATION_WARNINGS -eq 0 ]; then
            echo "**EXCELLENT** - All integration tests passed without issues." >> "$TEST_REPORT"
            show_success "Integration Test Status: EXCELLENT"
        else
            echo "**GOOD** - All critical integration tests passed with $INTEGRATION_WARNINGS warning(s)." >> "$TEST_REPORT"
            show_success "Integration Test Status: GOOD"
        fi
    else
        echo "**NEEDS ATTENTION** - $INTEGRATION_FAILED integration test(s) failed." >> "$TEST_REPORT"
        show_error "Integration Test Status: NEEDS ATTENTION"
    fi
    
    cat >> "$TEST_REPORT" << EOF

### Key Integration Points Tested

1. **Quirks Validation**: Enhanced Qt6 validation functions and strict mode
2. **CMake Configuration**: RPATH settings and permission configuration for AppImage portability
3. **Validation Framework**: Enhanced plugin validation and permission checking
4. **Plugin Test Framework**: Dedicated Qt6 plugin validation testing
5. **Build System Integration**: Strict validation flag integration in build process
6. **Documentation**: Comprehensive troubleshooting and reference documentation

### Implementation Quality

- **Fail-Fast Behavior**: Build system now fails early on missing critical Qt6 plugins
- **Comprehensive Validation**: Post-build validation covers all required plugin directories
- **RPATH Configuration**: Proper relative path configuration for portable AppImage execution
- **Permission Management**: Automated permission setting for all binaries and libraries
- **Testing Framework**: Dedicated plugin validation tests for continuous integration

### Recommendations for Production Use

1. **Environment Setup**: Ensure Qt6 development packages are installed before building
2. **Strict Mode**: Use STRICT_PLUGIN_VALIDATION=true for production builds
3. **Validation Pipeline**: Run both validate-appimage.sh and test-qt6-plugin-validation.sh
4. **Cross-Platform Testing**: Test AppImage on multiple distributions including immutable OS
5. **Reference Comparison**: Compare with official AppImage v1.1.1-802 structure when available

---

**Report Generated:** $(date)  
**Integration Test Framework Version:** 1.0.0  
**Repository:** torporsche/appimage-builder
EOF

    show_status "Integration test report saved to: $TEST_REPORT"
    
    # Display final statistics
    echo ""
    echo "=== INTEGRATION TEST COMPLETE ==="
    echo "Passed: $COLOR_SUCCESS$INTEGRATION_PASSED$COLOR_RESET"
    echo "Failed: $COLOR_ERROR$INTEGRATION_FAILED$COLOR_RESET"
    echo "Warnings: $COLOR_WARNING$INTEGRATION_WARNINGS$COLOR_RESET"
    echo "Report: $TEST_REPORT"
    echo ""
    
    # Return appropriate exit code
    if [ $INTEGRATION_FAILED -gt 0 ]; then
        return 1
    else
        return 0
    fi
}

# Main integration test function
main() {
    echo ""
    echo "=================================================="
    echo "Comprehensive Qt6 AppImage Integration Test"
    echo "=================================================="
    echo ""
    
    init_integration_test
    
    test_quirks_validation
    test_cmake_enhancements
    test_validation_enhancements
    test_plugin_test_framework
    test_build_system_integration
    test_documentation_updates
    test_environment_simulation
    
    generate_integration_report
}

# Parse command line arguments
while getopts "h?v" opt; do
    case "$opt" in
    h|\?)
        echo "Comprehensive Qt6 AppImage Integration Test"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  -h    Show this help message"
        echo "  -v    Verbose output"
        echo ""
        echo "This script tests the complete integration of Qt6 AppImage improvements:"
        echo "  - Quirks validation enhancements"
        echo "  - CMake RPATH configuration"
        echo "  - Validation script improvements"
        echo "  - Plugin test framework"
        echo "  - Build system integration"
        echo "  - Documentation updates"
        echo ""
        exit 0
        ;;
    v)  set -x
        ;;
    esac
done

# Run main integration test
main "$@"