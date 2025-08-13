# Bazzite OS Compatibility Quirks for AMD Z1 Extreme APU
# Addresses crashes on Fedora Atomic 42 with AMD graphics
# Based on analysis of official AppImage v1.1.1-802

quirk_init() {
  # Set up environment for Bazzite OS (Fedora Atomic 42) compatibility
  show_status "Initializing Bazzite OS compatibility quirks for AMD Z1 Extreme APU..."
  
  # Target older GLIBC for compatibility (2.31 instead of 2.35+)
  export CXXFLAGS="-std=c++17 -fPIC -D_GNU_SOURCE $CXXFLAGS"
  export CFLAGS="-fPIC -D_GNU_SOURCE $CFLAGS"
  
  # AMD Z1 Extreme APU specific graphics configuration
  export MESA_LOADER_DRIVER_OVERRIDE=radeonsi
  export AMD_VULKAN_ICD=RADV
  export RADV_PERFTEST=gpl,nggc
  
  # Qt WebEngine compatibility for Bazzite OS
  export QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox --disable-gpu-sandbox --use-gl=angle"
  
  # Set up x86_64 library paths for Fedora compatibility
  export PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig:/usr/lib/pkgconfig:/usr/lib64/pkgconfig"
  export DEBIANTARGET="x86_64-linux-gnu"
  
  show_status "Bazzite OS compatibility environment configured"
}

quirk_build_msa() {
  # MSA is disabled by default for compatibility
  # This function exists for compatibility but does nothing
  show_status "MSA component disabled for Bazzite OS compatibility"
  return 0
}

quirk_build_mcpelauncher() {
  # mcpelauncher build configuration optimized for Bazzite OS
  show_status "Building mcpelauncher with Bazzite OS compatibility..."
  
  # Use compatible C++ standard and compiler flags
  add_cmake_options "-DCMAKE_CXX_STANDARD=17" "-DCMAKE_C_STANDARD=11"
  add_cmake_options "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
  add_cmake_options "-DCMAKE_BUILD_TYPE=Release"
  
  # GLIBC compatibility for Fedora Atomic 42
  add_cmake_options "-DGLIBC_COMPAT=ON"
  add_cmake_options "-DCMAKE_CXX_FLAGS=-D_GNU_SOURCE"
  
  # Use system dependencies for better Fedora compatibility
  add_cmake_options "-DUSE_OWN_CURL=OFF"
  add_cmake_options "-DUSE_GAMECONTROLLERDB=OFF"
  
  # AMD Z1 Extreme APU graphics optimization
  add_cmake_options "-DOPENGL_PREFERENCE=GLVND"
  add_cmake_options "-DUSE_SYSTEM_GLFW=ON"
  
  # x86_64 library paths for Fedora
  add_cmake_options "-DCMAKE_PREFIX_PATH=/usr/lib/x86_64-linux-gnu/cmake:/usr/lib64/cmake"
  add_cmake_options "-DCMAKE_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/lib64:/lib64"
  
  # Mesa/RADV specific OpenGL configuration
  add_cmake_options "-DOPENGL_opengl_LIBRARY=/usr/lib/x86_64-linux-gnu/libOpenGL.so"
  add_cmake_options "-DOPENGL_gl_LIBRARY=/usr/lib/x86_64-linux-gnu/libGL.so"
  add_cmake_options "-DOpenGL_GL_PREFERENCE=GLVND"
  
  # EGL support for AMD graphics
  add_cmake_options "-DEGL_LIBRARY=/usr/lib/x86_64-linux-gnu/libEGL.so"
  add_cmake_options "-DGLES_LIBRARY=/usr/lib/x86_64-linux-gnu/libGLESv2.so"
  
  show_status "mcpelauncher configured for Bazzite OS with AMD Z1 Extreme APU"
}

quirk_build_mcpelauncher_ui() {
  # UI build configuration with Qt5 WebEngine for Bazzite OS
  show_status "Building mcpelauncher-ui with Bazzite OS compatibility..."
  
  # Qt5 configuration for Bazzite OS (no Qt6 for stability)
  add_cmake_options "-DQt5_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt5"
  add_cmake_options "-DQt5Widgets_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt5Widgets"
  add_cmake_options "-DQt5WebEngine_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt5WebEngine"
  
  # Compiler configuration for compatibility
  add_cmake_options "-DCMAKE_CXX_STANDARD=17" "-DCMAKE_C_STANDARD=11"
  add_cmake_options "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
  add_cmake_options "-DCMAKE_BUILD_TYPE=Release"
  
  # libcurl system integration for Fedora
  add_cmake_options "-DCURL_LIBRARY=/usr/lib/x86_64-linux-gnu/libcurl.so"
  add_cmake_options "-DCURL_INCLUDE_DIR=/usr/include/curl"
  
  # AMD Z1 Extreme APU WebEngine configuration
  add_cmake_options "-DWEBENGINE_DISABLE_GPU_SANDBOX=ON"
  add_cmake_options "-DWEBENGINE_USE_ANGLE=ON"
  
  # Qt WebEngine flags for AMD graphics compatibility
  local webengine_flags="--no-sandbox --disable-gpu-sandbox --use-gl=angle"
  webengine_flags="$webengine_flags --enable-features=VaapiVideoDecoder"
  webengine_flags="$webengine_flags --disable-features=VizDisplayCompositor"
  add_cmake_options "-DWEBENGINE_CHROMIUM_FLAGS='$webengine_flags'"
  
  # Hardware acceleration for AMD Z1 Extreme
  add_cmake_options "-DENABLE_HARDWARE_ACCELERATION=ON"
  add_cmake_options "-DUSE_VAAPI=ON"
  add_cmake_options "-DUSE_VDPAU=ON"
  
  show_status "mcpelauncher-ui configured for Bazzite OS with AMD Z1 Extreme APU"
}

# Additional quirk for library bundling strategy
quirk_bundle_libraries() {
  show_status "Bundling libraries for Bazzite OS compatibility..."
  
  # Bundle AMD-specific Mesa libraries if available
  if [ -f "/usr/lib/x86_64-linux-gnu/dri/radeonsi_dri.so" ]; then
    mkdir -p "${APP_DIR}/usr/lib/dri"
    cp "/usr/lib/x86_64-linux-gnu/dri/radeonsi_dri.so" "${APP_DIR}/usr/lib/dri/" || true
    show_status "Bundled radeonsi Mesa driver"
  fi
  
  # Bundle RADV Vulkan driver if available
  if [ -f "/usr/lib/x86_64-linux-gnu/libvulkan_radeon.so" ]; then
    mkdir -p "${APP_DIR}/usr/lib"
    cp "/usr/lib/x86_64-linux-gnu/libvulkan_radeon.so" "${APP_DIR}/usr/lib/" || true
    show_status "Bundled RADV Vulkan driver"
  fi
  
  # Bundle VA-API and VDPAU libraries for hardware acceleration
  for lib in libva.so.2 libva-x11.so.2 libvdpau.so.1; do
    if [ -f "/usr/lib/x86_64-linux-gnu/$lib" ]; then
      cp "/usr/lib/x86_64-linux-gnu/$lib" "${APP_DIR}/usr/lib/" || true
      show_status "Bundled $lib"
    fi
  done
  
  show_status "Library bundling for Bazzite OS complete"
}

# Post-build AppImage configuration for Bazzite OS
quirk_appimage_post_build() {
  show_status "Configuring AppImage for Bazzite OS deployment..."
  
  # Create Bazzite-specific AppRun wrapper
  local apprun_wrapper="${APP_DIR}/AppRunBazzite"
  cat > "$apprun_wrapper" << 'EOF'
#!/bin/bash

# Bazzite OS (Fedora Atomic 42) compatibility wrapper for AMD Z1 Extreme APU

# Set AMD graphics environment
export MESA_LOADER_DRIVER_OVERRIDE=radeonsi
export AMD_VULKAN_ICD=RADV
export RADV_PERFTEST=gpl,nggc

# Hardware acceleration
export LIBVA_DRIVER_NAME=radeonsi
export VDPAU_DRIVER=radeonsi

# Qt WebEngine compatibility
export QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox --disable-gpu-sandbox --use-gl=angle"
export QT_XCB_GL_INTEGRATION=xcb_egl

# AppImage library paths
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${HERE}/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH}"

# Execute main AppRun
exec "${HERE}/AppRun" "$@"
EOF
  
  chmod +x "$apprun_wrapper"
  show_status "Created Bazzite OS compatibility wrapper"
  
  # Update desktop file for Bazzite OS
  local desktop_file="${APP_DIR}/*.desktop"
  if [ -f $desktop_file ]; then
    sed -i 's/Exec=AppRun/Exec=AppRunBazzite/' $desktop_file
    show_status "Updated desktop file for Bazzite OS"
  fi
  
  show_status "AppImage configured for Bazzite OS deployment"
}

# Environment validation for Bazzite OS
quirk_validate_environment() {
  show_status "Validating build environment for Bazzite OS compatibility..."
  
  # Check GLIBC version
  local glibc_version=$(ldd --version | head -1 | grep -o '[0-9]\+\.[0-9]\+')
  if [ -n "$glibc_version" ]; then
    show_status "GLIBC version: $glibc_version"
    # Warn if GLIBC is too new for compatibility
    if [ "$(echo "$glibc_version >= 2.35" | bc -l 2>/dev/null || echo 0)" -eq 1 ]; then
      show_status "WARNING: GLIBC $glibc_version may be too new for Bazzite OS compatibility"
      show_status "Consider building on Ubuntu 20.04 for GLIBC 2.31 compatibility"
    fi
  fi
  
  # Check Mesa version for AMD compatibility
  if command -v glxinfo >/dev/null 2>&1; then
    local mesa_version=$(glxinfo 2>/dev/null | grep "Mesa" | head -1)
    if [ -n "$mesa_version" ]; then
      show_status "Mesa version: $mesa_version"
    fi
  fi
  
  # Check Qt5 WebEngine availability
  if pkg-config --exists Qt5WebEngine; then
    local qt_version=$(pkg-config --modversion Qt5WebEngine)
    show_status "Qt5 WebEngine version: $qt_version"
  else
    show_status "WARNING: Qt5 WebEngine not found - may cause compatibility issues"
  fi
  
  show_status "Environment validation complete"
}

# Main quirk initialization function
quirk_main() {
  show_status "Starting Bazzite OS compatibility quirks..."
  
  quirk_init
  quirk_validate_environment
  
  show_status "Bazzite OS quirks initialized successfully"
  show_status "Target: AMD Z1 Extreme APU on Fedora Atomic 42"
}

# Call main quirk function
quirk_main