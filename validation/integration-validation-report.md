# Integration Validation Report

**Generated:** 2025-08-17 12:23:15 UTC
**Build Environment:** Linux pkrvmubgrv54qmi 6.11.0-1018-azure #18~24.04.1-Ubuntu SMP Sat Jun 28 04:46:03 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux
**Validation Framework:** Integration Validation v1.0

## Summary

- ✅ **Passed:** 13 checks
- ⚠️ **Warnings:** 0 checks  
- ❌ **Failed:** 1 checks

## Build Reproducibility Status

🔴 **NON-REPRODUCIBLE**: 1 critical issues found

## Environment Configuration

- **CMake Version:** 3.31.6
- **GCC Version:** 13.3.0
13.3.0
- **Qt6 Version:** Not found
- **SOURCE_DATE_EPOCH:** 1640995200
- **LC_ALL:** C

## AppImage Output

- No AppImage files found

## Recommendations

### Critical Issues
- Review failed validation checks above
- Ensure all Qt6 components are properly installed
- Verify build environment consistency



### Best Practices
- Use `./test-dependencies.sh` before every build
- Run integration validation after each build
- Compare AppImage sizes across builds for consistency
- Use `SOURCE_DATE_EPOCH` for reproducible timestamps

---

**Next Review:** After any build environment changes or Qt6 updates
