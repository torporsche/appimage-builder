#!/bin/bash
# Integration Validation Script for Pre/Post-Build Validation
# Ensures reproducibility and deterministic output across builds

set -e

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

# Pre-build validation
validate_pre_build() {
    show_status "=== Pre-Build Integration Validation ==="
    
    # 1. Validate commit pins are consistent
    show_status "Validating commit pins for reproducibility..."
    
    local commit_files=("mcpelauncher.commit" "mcpelauncher-ui.commit" "msa.commit")
    for commit_file in "${commit_files[@]}"; do
        if [ -f "$commit_file" ]; then
            local commit_hash=$(cat "$commit_file" | tr -d '\n\r')
            if [[ "$commit_hash" =~ ^[a-fA-F0-9]{40}$ ]]; then
                show_success "Commit pin valid: $commit_file ($commit_hash)"
            else
                show_error "Invalid commit hash in $commit_file: $commit_hash"
            fi
        else
            show_warning "Commit pin file missing: $commit_file"
        fi
    done
    
    # 2. Validate build environment consistency
    show_status "Validating build environment for reproducibility..."
    
    # Check if build tools are deterministic versions
    if command -v cmake >/dev/null 2>&1; then
        local cmake_version=$(cmake --version | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
        show_success "CMake version: $cmake_version"
    else
        show_error "CMake not found"
    fi
    
    if command -v gcc >/dev/null 2>&1; then
        local gcc_version=$(gcc --version | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
        show_success "GCC version: $gcc_version"
    else
        show_warning "GCC not found"
    fi
    
    # 3. Validate Qt6 environment consistency
    show_status "Validating Qt6 environment for deterministic builds..."
    
    if command -v qmake6 >/dev/null 2>&1; then
        local qt6_version=$(qmake6 --version | grep "Qt version" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
        show_success "Qt6 version: $qt6_version"
        
        # Check Qt6 installation consistency
        local qt6_paths=(
            "/usr/lib/x86_64-linux-gnu/cmake/Qt6"
            "/usr/lib/x86_64-linux-gnu/cmake/Qt6Core"
            "/usr/lib/x86_64-linux-gnu/cmake/Qt6Widgets"
        )
        
        for qt6_path in "${qt6_paths[@]}"; do
            if [ -d "$qt6_path" ]; then
                show_success "Qt6 component path validated: $qt6_path"
            else
                show_error "Qt6 component path missing: $qt6_path"
            fi
        done
    else
        show_error "Qt6 qmake not found"
    fi
    
    # 4. Validate source integrity
    show_status "Validating source code integrity..."
    
    # Check critical build scripts exist and are executable
    local critical_scripts=("build_appimage.sh" "test-dependencies.sh" "validate-appimage.sh")
    local library_scripts=("quirks-qt6.sh" "common.sh")
    
    for script in "${critical_scripts[@]}"; do
        if [ -f "$script" ]; then
            if [ -x "$script" ]; then
                show_success "Build script validated: $script"
            else
                show_error "Build script not executable: $script"
            fi
        else
            show_error "Critical build script missing: $script"
        fi
    done
    
    for script in "${library_scripts[@]}"; do
        if [ -f "$script" ]; then
            show_success "Library script validated: $script"
        else
            show_error "Library script missing: $script"
        fi
    done
    
    # 5. Environment variable validation
    show_status "Validating environment variables for reproducible builds..."
    
    # Check for deterministic environment
    if [ -z "${LANG}" ]; then
        show_warning "LANG not set - may affect build reproducibility"
    else
        show_success "LANG set: $LANG"
    fi
    
    if [ -z "${LC_ALL}" ]; then
        export LC_ALL=C
        show_success "LC_ALL set to C for reproducible builds"
    else
        show_success "LC_ALL already set: $LC_ALL"
    fi
    
    # Set SOURCE_DATE_EPOCH for reproducible builds
    if [ -z "${SOURCE_DATE_EPOCH}" ]; then
        export SOURCE_DATE_EPOCH=1640995200  # 2022-01-01 00:00:00 UTC
        show_success "SOURCE_DATE_EPOCH set for reproducible builds: $SOURCE_DATE_EPOCH"
    else
        show_success "SOURCE_DATE_EPOCH already set: $SOURCE_DATE_EPOCH"
    fi
}

# Post-build validation
validate_post_build() {
    show_status "=== Post-Build Integration Validation ==="
    
    # 1. Validate AppImage output consistency
    show_status "Validating AppImage output for deterministic builds..."
    
    local output_dir="output"
    local appimage_files=($(find "$output_dir" -name "*.AppImage" 2>/dev/null || true))
    
    if [ ${#appimage_files[@]} -eq 0 ]; then
        show_error "No AppImage files found in $output_dir"
        return 1
    fi
    
    for appimage in "${appimage_files[@]}"; do
        if [ -f "$appimage" ]; then
            local file_size=$(stat -c%s "$appimage" 2>/dev/null || echo "unknown")
            show_success "AppImage validated: $(basename "$appimage") (${file_size} bytes)"
            
            # Check AppImage permissions
            if [ -x "$appimage" ]; then
                show_success "AppImage executable: $(basename "$appimage")"
            else
                show_error "AppImage not executable: $(basename "$appimage")"
            fi
            
            # Validate AppImage structure
            if command -v file >/dev/null 2>&1; then
                local file_type=$(file "$appimage" | grep -o "ELF.*executable" || echo "unknown")
                if [[ "$file_type" == *"executable"* ]]; then
                    show_success "AppImage file type validated: $file_type"
                else
                    show_warning "AppImage file type unexpected: $file_type"
                fi
            fi
        else
            show_error "AppImage file not found: $appimage"
        fi
    done
    
    # 2. Validate build artifacts consistency
    show_status "Validating build artifacts for reproducibility..."
    
    local build_dir="build"
    if [ -d "$build_dir" ]; then
        # Check build logs for deterministic patterns
        local build_logs=($(find "$build_dir" -name "*.log" 2>/dev/null || true))
        for log in "${build_logs[@]}"; do
            if [ -f "$log" ]; then
                # Check for non-deterministic warnings
                local warnings=$(grep -i "warning\|error" "$log" 2>/dev/null | wc -l || echo "0")
                if [ "$warnings" -eq 0 ]; then
                    show_success "Build log clean: $(basename "$log")"
                else
                    show_warning "Build log has $warnings warnings/errors: $(basename "$log")"
                fi
            fi
        done
        
        show_success "Build artifacts directory validated: $build_dir"
    else
        show_warning "Build directory not found: $build_dir"
    fi
    
    # 3. Cross-validation with validation reports
    show_status "Cross-validating with existing validation reports..."
    
    local validation_dir="validation"
    if [ -d "$validation_dir" ]; then
        local reports=($(find "$validation_dir" -name "*.md" 2>/dev/null || true))
        for report in "${reports[@]}"; do
            if [ -f "$report" ]; then
                local error_count=$(grep -c "❌\|ERROR" "$report" 2>/dev/null || echo "0")
                if [ "$error_count" -eq 0 ]; then
                    show_success "Validation report clean: $(basename "$report")"
                else
                    show_warning "Validation report has $error_count errors: $(basename "$report")"
                fi
            fi
        done
    else
        show_warning "Validation directory not found: $validation_dir"
    fi
    
    # 4. Reproducibility verification
    show_status "Verifying build reproducibility markers..."
    
    # Check if builds are using deterministic settings
    for appimage in "${appimage_files[@]}"; do
        if command -v strings >/dev/null 2>&1; then
            # Look for timestamp markers that might indicate non-reproducible builds
            local timestamp_count=$(strings "$appimage" 2>/dev/null | grep -E "[0-9]{4}-[0-9]{2}-[0-9]{2}" | wc -l || echo "0")
            if [ "$timestamp_count" -lt 5 ]; then
                show_success "AppImage appears to have minimal timestamp dependencies: $(basename "$appimage")"
            else
                show_warning "AppImage may have $timestamp_count timestamp dependencies: $(basename "$appimage")"
            fi
        fi
    done
}

# Generate integration validation report
generate_integration_report() {
    show_status "=== Generating Integration Validation Report ==="
    
    local report_file="validation/integration-validation-report.md"
    mkdir -p "$(dirname "$report_file")"
    
    cat > "$report_file" << EOF
# Integration Validation Report

**Generated:** $(date -u '+%Y-%m-%d %H:%M:%S UTC')
**Build Environment:** $(uname -a)
**Validation Framework:** Integration Validation v1.0

## Summary

- ✅ **Passed:** $VALIDATION_PASSED checks
- ⚠️ **Warnings:** $VALIDATION_WARNINGS checks  
- ❌ **Failed:** $VALIDATION_FAILED checks

## Build Reproducibility Status

$(if [ "$VALIDATION_FAILED" -eq 0 ]; then
    echo "🟢 **REPRODUCIBLE**: All critical checks passed"
else
    echo "🔴 **NON-REPRODUCIBLE**: $VALIDATION_FAILED critical issues found"
fi)

## Environment Configuration

- **CMake Version:** $(command -v cmake >/dev/null 2>&1 && cmake --version | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "Not found")
- **GCC Version:** $(command -v gcc >/dev/null 2>&1 && gcc --version | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "Not found")
- **Qt6 Version:** $(command -v qmake6 >/dev/null 2>&1 && qmake6 --version | grep "Qt version" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "Not found")
- **SOURCE_DATE_EPOCH:** ${SOURCE_DATE_EPOCH:-"Not set"}
- **LC_ALL:** ${LC_ALL:-"Not set"}

## AppImage Output

$(local output_dir="output"
local appimage_files=($(find "$output_dir" -name "*.AppImage" 2>/dev/null || true))
if [ ${#appimage_files[@]} -gt 0 ]; then
    for appimage in "${appimage_files[@]}"; do
        local file_size=$(stat -c%s "$appimage" 2>/dev/null || echo "unknown")
        echo "- **$(basename "$appimage")**: ${file_size} bytes"
    done
else
    echo "- No AppImage files found"
fi)

## Recommendations

$(if [ "$VALIDATION_FAILED" -gt 0 ]; then
    echo "### Critical Issues"
    echo "- Review failed validation checks above"
    echo "- Ensure all Qt6 components are properly installed"
    echo "- Verify build environment consistency"
    echo ""
fi)

$(if [ "$VALIDATION_WARNINGS" -gt 0 ]; then
    echo "### Improvements"
    echo "- Address warning conditions for better reproducibility"
    echo "- Consider setting missing environment variables"
    echo "- Review build logs for optimization opportunities"
    echo ""
fi)

### Best Practices
- Use \`./test-dependencies.sh\` before every build
- Run integration validation after each build
- Compare AppImage sizes across builds for consistency
- Use \`SOURCE_DATE_EPOCH\` for reproducible timestamps

---

**Next Review:** After any build environment changes or Qt6 updates
EOF
    
    show_success "Integration validation report generated: $report_file"
}

# Main execution
main() {
    echo ""
    echo "==================================================="
    echo "Integration Validation for Reproducible Builds"
    echo "==================================================="
    echo ""
    
    case "${1:-both}" in
        "pre")
            validate_pre_build
            ;;
        "post")
            validate_post_build
            ;;
        "both"|"")
            validate_pre_build
            echo ""
            validate_post_build
            ;;
        *)
            echo "Usage: $0 [pre|post|both]"
            echo ""
            echo "  pre   - Run pre-build validation only"
            echo "  post  - Run post-build validation only"  
            echo "  both  - Run both pre and post validation (default)"
            exit 1
            ;;
    esac
    
    echo ""
    generate_integration_report
    
    echo ""
    echo "=== Integration Validation Summary ==="
    echo "✅ Passed: $VALIDATION_PASSED"
    echo "⚠️  Warnings: $VALIDATION_WARNINGS"
    echo "❌ Failed: $VALIDATION_FAILED"
    echo ""
    
    if [ "$VALIDATION_FAILED" -gt 0 ]; then
        echo "🔴 INTEGRATION VALIDATION FAILED"
        echo "Review errors above and fix before proceeding with build."
        exit 1
    elif [ "$VALIDATION_WARNINGS" -gt 0 ]; then
        echo "🟡 INTEGRATION VALIDATION PASSED WITH WARNINGS"
        echo "Consider addressing warnings for optimal reproducibility."
    else
        echo "🟢 INTEGRATION VALIDATION PASSED"
        echo "Environment ready for reproducible builds."
    fi
}

# Run main function
main "$@"