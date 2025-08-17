# Qt6 Ubuntu 22.04 quirks for x86_64 builds with modern Qt6 framework
# Focuses on single architecture builds with Qt6 for improved compatibility

# Helper function to validate Qt6 CMake paths before using them with strict checking
validate_and_add_qt6_cmake_dir() {
  local component_name="$1"
  local cmake_dir="$2"
  local required="${3:-false}"
  
  if [ -d "$cmake_dir" ]; then
    # Verify CMake config file exists
    if [ -f "$cmake_dir/${component_name}Config.cmake" ] || [ -f "$cmake_dir/${component_name}.cmake" ]; then
      add_cmake_options "-D${component_name}_DIR=$cmake_dir"
      show_status "Qt6 $component_name: Found at $cmake_dir"
      return 0
    else
      show_status "Qt6 $component_name: Directory exists but CMake config missing at $cmake_dir"
      if [ "$required" = "true" ]; then
        echo "ERROR: Required Qt6 component $component_name missing CMake configuration" >&2
        exit 1
      fi
      return 1
    fi
  else
    show_status "Qt6 $component_name: Not found at $cmake_dir"
    if [ "$required" = "true" ]; then
      echo "ERROR: Required Qt6 component $component_name not found at $cmake_dir" >&2
      echo "Install with: sudo apt-get install qt6-base-dev qt6-tools-dev" >&2
      exit 1
    fi
    return 1
  fi
}

# Function to detect Qt6 components and configure fallbacks with strict validation
configure_qt6_wayland_fallbacks() {
  local wayland_available=false
  local required_wayland_components=0
  local found_wayland_components=0
  local strict_validation="${STRICT_PLUGIN_VALIDATION:-true}"
  
  # Check for Wayland support with comprehensive validation
  local wayland_paths=(
    "/usr/lib/x86_64-linux-gnu/cmake/Qt6WaylandClient"
    "/usr/lib/x86_64-linux-gnu/libQt6WaylandClient.so"
    "/usr/lib/x86_64-linux-gnu/qt6/plugins/platforms"
  )
  
  for path in "${wayland_paths[@]}"; do
    required_wayland_components=$((required_wayland_components + 1))
    if [ -e "$path" ]; then
      found_wayland_components=$((found_wayland_components + 1))
      show_status "Qt6 Wayland component found: $path"
    else
      show_status "Qt6 Wayland component missing: $path"
      if [ "$strict_validation" = "true" ]; then
        echo "ERROR: Required Qt6 Wayland component missing: $path" >&2
        echo "Install with: sudo apt-get install qt6-wayland qt6-wayland-dev" >&2
        exit 1
      fi
    fi
  done
  
  # Validate plugin directories exist and contain plugins with fail-fast
  local plugin_dirs=(
    "/usr/lib/x86_64-linux-gnu/qt6/plugins/platforms"
    "/usr/lib/x86_64-linux-gnu/qt6/plugins/wayland-decoration-client"
    "/usr/lib/x86_64-linux-gnu/qt6/plugins/wayland-graphics-integration-client"
    "/usr/lib/x86_64-linux-gnu/qt6/plugins/wayland-shell-integration"
  )
  
  local plugins_validated=true
  local critical_plugins_missing=0
  
  for plugin_dir in "${plugin_dirs[@]}"; do
    if [ -d "$plugin_dir" ]; then
      local plugin_count=$(find "$plugin_dir" -name "*.so" 2>/dev/null | wc -l)
      if [ "$plugin_count" -gt 0 ]; then
        show_status "Qt6 plugin directory validated: $plugin_dir ($plugin_count plugins)"
      else
        show_status "Qt6 plugin directory empty: $plugin_dir"
        plugins_validated=false
        critical_plugins_missing=$((critical_plugins_missing + 1))
        if [ "$strict_validation" = "true" ]; then
          echo "ERROR: Critical Qt6 plugin directory is empty: $plugin_dir" >&2
          exit 1
        fi
      fi
    else
      show_status "Qt6 plugin directory missing: $plugin_dir"
      plugins_validated=false
      critical_plugins_missing=$((critical_plugins_missing + 1))
      if [ "$strict_validation" = "true" ]; then
        echo "ERROR: Critical Qt6 plugin directory missing: $plugin_dir" >&2
        echo "Install with: sudo apt-get install qt6-wayland qt6-wayland-dev" >&2
        exit 1
      fi
    fi
  done
  
  # Strict validation for WebEngine plugins if enabled
  local webengine_plugin_dirs=(
    "/usr/lib/x86_64-linux-gnu/qt6/plugins/webengine"
  )
  
  for plugin_dir in "${webengine_plugin_dirs[@]}"; do
    if [ -d "$plugin_dir" ]; then
      local plugin_count=$(find "$plugin_dir" -name "*.so" 2>/dev/null | wc -l)
      if [ "$plugin_count" -gt 0 ]; then
        show_status "Qt6 WebEngine plugin directory validated: $plugin_dir ($plugin_count plugins)"
      else
        show_status "Qt6 WebEngine plugin directory empty: $plugin_dir"
        if [ "$strict_validation" = "true" ]; then
          echo "WARNING: Qt6 WebEngine plugin directory is empty: $plugin_dir" >&2
        fi
      fi
    else
      show_status "Qt6 WebEngine plugin directory missing: $plugin_dir (optional)"
    fi
  done
  
  # Determine Wayland availability based on comprehensive checks
  if [ "$found_wayland_components" -gt 0 ] && [ "$plugins_validated" = "true" ]; then
    wayland_available=true
    show_status "Qt6 Wayland support detected and validated"
  else
    if [ "$strict_validation" = "true" ] && [ "$critical_plugins_missing" -gt 0 ]; then
      echo "ERROR: $critical_plugins_missing critical Qt6 plugin directories missing or empty" >&2
      echo "This will result in AppImage build failure. Stopping early." >&2
      exit 1
    fi
    show_status "Qt6 Wayland support not available or incomplete - using X11 fallback"
    if [ "$found_wayland_components" -eq 0 ]; then
      show_status "No Wayland components found. Install with: sudo apt-get install qt6-wayland qt6-wayland-dev"
    fi
  fi
  
  # Configure Wayland environment variables with validation
  if [ "$wayland_available" = "true" ]; then
    # Native Wayland support
    add_cmake_options "-DENABLE_WAYLAND=ON"
    export QT_QPA_PLATFORM="wayland;xcb"
    export QT_WAYLAND_FORCE_DPI=96
    export QT_AUTO_SCREEN_SCALE_FACTOR=0
    
    # Validate Wayland libraries are actually loadable
    if ldconfig -p | grep -q "libQt6WaylandClient"; then
      show_status "Qt6 Wayland libraries validated in ldconfig"
    else
      show_status "WARNING: Qt6 Wayland libraries not found in ldconfig cache"
    fi
  else
    # X11 fallback with validation
    add_cmake_options "-DENABLE_WAYLAND=OFF"
    export QT_QPA_PLATFORM="xcb"
    export QT_AUTO_SCREEN_SCALE_FACTOR=0
    
    # Validate X11 libraries are available
    if ldconfig -p | grep -q "libX11"; then
      show_status "X11 libraries validated for fallback"
    else
      echo "ERROR: Neither Wayland nor X11 libraries found. Install X11 dev packages." >&2
      exit 1
    fi
  fi
}

# Function to configure OpenGL ES fallbacks with comprehensive validation
configure_opengl_fallbacks() {
  local opengl_validated=false
  local opengl_libs_found=0
  
  # Check for hardware OpenGL support with multiple library paths
  local opengl_paths=(
    "/usr/lib/x86_64-linux-gnu/libGL.so"
    "/usr/lib/x86_64-linux-gnu/libOpenGL.so"
    "/usr/lib/x86_64-linux-gnu/libEGL.so"
    "/usr/lib/x86_64-linux-gnu/libGLESv2.so"
  )
  
  show_status "Validating OpenGL/EGL libraries..."
  for lib_path in "${opengl_paths[@]}"; do
    if [ -f "$lib_path" ]; then
      show_status "OpenGL library found: $lib_path"
      opengl_libs_found=$((opengl_libs_found + 1))
    else
      show_status "OpenGL library missing: $lib_path"
    fi
  done
  
  # Validate OpenGL using ldconfig
  if ldconfig -p | grep -E "(libGL\.so|libOpenGL\.so)" >/dev/null; then
    show_status "OpenGL libraries found in ldconfig cache"
    opengl_validated=true
  fi
  
  # Check for Mesa software fallback
  if ldconfig -p | grep -q "libmesa"; then
    show_status "Mesa software rendering available"
  fi
  
  if [ "$opengl_libs_found" -gt 2 ] && [ "$opengl_validated" = "true" ]; then
    show_status "Hardware OpenGL support validated ($opengl_libs_found libraries found)"
    add_cmake_options "-DFORCE_SOFTWARE_RENDERING=OFF"
    add_cmake_options "-DENABLE_HARDWARE_ACCELERATION=ON"
  else
    show_status "Hardware OpenGL not available or incomplete - enabling software fallback"
    add_cmake_options "-DFORCE_SOFTWARE_RENDERING=ON"
    add_cmake_options "-DENABLE_HARDWARE_ACCELERATION=OFF"
    export LIBGL_ALWAYS_SOFTWARE=1
    export MESA_GL_VERSION_OVERRIDE=3.3
    export MESA_GLSL_VERSION_OVERRIDE=330
    
    # Warn if no software fallback available
    if ! ldconfig -p | grep -q "libmesa"; then
      show_status "WARNING: No Mesa software rendering found. Install mesa-utils mesa-common-dev"
    fi
  fi
  
  # Validate GPU vendor support
  if lspci 2>/dev/null | grep -i vga | grep -i amd >/dev/null; then
    show_status "AMD GPU detected - configuring RADV/Mesa optimizations"
    export RADV_PERFTEST=gpl
    export AMD_VULKAN_ICD=RADV
  elif lspci 2>/dev/null | grep -i vga | grep -i nvidia >/dev/null; then
    show_status "NVIDIA GPU detected"
  elif lspci 2>/dev/null | grep -i vga | grep -i intel >/dev/null; then
    show_status "Intel GPU detected"
  fi
}

quirk_init() {
  # Validate build environment before starting
  show_status "Validating Qt6 build environment for x86_64..."
  
  # Check essential build tools with fail-fast
  local required_tools=("cmake" "ninja" "pkg-config" "git")
  for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      echo "ERROR: Required build tool '$tool' not found" >&2
      echo "Install with: sudo apt-get install $tool" >&2
      exit 1
    fi
  done
  show_status "Build tools validated: ${required_tools[*]}"
  
  # Validate compiler availability
  if ! command -v gcc >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1; then
    echo "ERROR: No C++ compiler found (gcc or clang required)" >&2
    exit 1
  fi
  
  # Set up modern compiler environment for x86_64 only
  export CXXFLAGS="-std=c++17 -fPIC $CXXFLAGS"
  export CFLAGS="-fPIC $CFLAGS"
  
  # Set up x86_64 library paths with validation
  export PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig:/usr/lib/pkgconfig"
  export DEBIANTARGET="x86_64-linux-gnu"
  
  # Validate pkg-config can find basic libraries
  if ! pkg-config --exists openssl 2>/dev/null; then
    show_status "WARNING: OpenSSL development packages not found via pkg-config"
  fi
  
  # Set MSA_QT6_OPT flag to enable Qt6 Wayland plugin bundling
  export MSA_QT6_OPT=1
  
  # Validate Qt6 installation before proceeding
  if ! command -v qmake6 >/dev/null 2>&1; then
    echo "ERROR: Qt6 qmake not found. Install Qt6 development packages." >&2
    echo "Run: ./install-qt6-deps.sh" >&2
    exit 1
  fi
  
  # Configure Qt6 Wayland and OpenGL fallbacks with validation
  configure_qt6_wayland_fallbacks
  configure_opengl_fallbacks
  
  # Configure environment variables for Wayland/X11 compatibility
  export QT_LOGGING_RULES="qt.qpa.wayland.debug=false"
  export QT_WAYLAND_DISABLE_WINDOWDECORATION=0
  export QT_SCALE_FACTOR_ROUNDING_POLICY=RoundPreferFloor
  
  # Validate critical directories exist
  local critical_dirs=(
    "/usr/lib/x86_64-linux-gnu"
    "/usr/include"
    "/usr/lib/x86_64-linux-gnu/pkgconfig"
  )
  
  for dir in "${critical_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
      echo "ERROR: Critical directory missing: $dir" >&2
      exit 1
    fi
  done
  
  show_status "Qt6 build environment validated and ready for x86_64 (modern framework with Wayland support)"
}

quirk_build_msa() {
  # MSA is disabled by default in clean restart strategy
  # This function exists for compatibility but does nothing
  show_status "MSA component disabled in clean restart strategy"
  return 0
}

quirk_build_mcpelauncher() {
  # Modern launcher build configuration for x86_64 with Qt6
  add_cmake_options "-DCMAKE_CXX_STANDARD=17" "-DCMAKE_C_STANDARD=11"
  add_cmake_options "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
  add_cmake_options "-DCMAKE_BUILD_TYPE=Release"
  
  # Use system dependencies instead of downloading from external sources
  add_cmake_options "-DUSE_OWN_CURL=OFF"
  add_cmake_options "-DUSE_GAMECONTROLLERDB=OFF"
  
  # Force Qt6 usage for components that default to Qt5
  add_cmake_options "-DQT_VERSION_MAJOR=6"
  add_cmake_options "-DCMAKE_PREFIX_PATH=/usr/lib/x86_64-linux-gnu/cmake;/usr/lib/x86_64-linux-gnu"
  
  # Set Qt6 tool paths explicitly
  add_cmake_options "-DQt6_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6"
  add_cmake_options "-DQT_MOC_EXECUTABLE=/usr/lib/qt6/libexec/moc"
  add_cmake_options "-DQT_UIC_EXECUTABLE=/usr/lib/qt6/libexec/uic"
  add_cmake_options "-DQT_RCC_EXECUTABLE=/usr/lib/qt6/libexec/rcc"
  
  # Disable webview component to avoid Qt5 dependency issues - webview uses Qt5 hardcoded
  add_cmake_options "-DENABLE_WEBVIEW=OFF"
  add_cmake_options "-DBUILD_WEBVIEW=OFF"
  
  # Set Qt6 environment variables to override Qt5 detection
  export QT_VERSION=6
  export CMAKE_QT_VERSION=Qt6
  
  # x86_64 library paths
  add_cmake_options "-DCMAKE_PREFIX_PATH=/usr/lib/x86_64-linux-gnu/cmake"
  add_cmake_options "-DCMAKE_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/lib64:/lib64"
  
  # OpenGL libraries for x86_64
  add_cmake_options "-DOPENGL_opengl_LIBRARY=/usr/lib/x86_64-linux-gnu/libOpenGL.so"
  add_cmake_options "-DOPENGL_gl_LIBRARY=/usr/lib/x86_64-linux-gnu/libGL.so"
  
  # Qt6 configuration for modern framework - validate paths before using with strict checks
  validate_and_add_qt6_cmake_dir "Qt6" "/usr/lib/x86_64-linux-gnu/cmake/Qt6" "true"
  validate_and_add_qt6_cmake_dir "Qt6Core" "/usr/lib/x86_64-linux-gnu/cmake/Qt6Core" "true"
  validate_and_add_qt6_cmake_dir "Qt6Widgets" "/usr/lib/x86_64-linux-gnu/cmake/Qt6Widgets" "true"
  validate_and_add_qt6_cmake_dir "Qt6GuiTools" "/usr/lib/x86_64-linux-gnu/cmake/Qt6GuiTools" "false"
}

quirk_build_mcpelauncher_ui() {
  # UI build configuration with Qt6 WebEngine support for x86_64
  add_cmake_options "-DCURL_LIBRARY=/usr/lib/x86_64-linux-gnu/libcurl.so"
  add_cmake_options "-DCMAKE_CXX_STANDARD=17" "-DCMAKE_C_STANDARD=11"
  add_cmake_options "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
  add_cmake_options "-DCMAKE_BUILD_TYPE=Release"
  
  # Force Qt6 usage for all components
  add_cmake_options "-DQT_VERSION_MAJOR=6"
  add_cmake_options "-DUSE_QT6=ON"
  
  # Set Qt6 tool paths explicitly
  add_cmake_options "-DQt6_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6"
  add_cmake_options "-DQT_MOC_EXECUTABLE=/usr/lib/qt6/libexec/moc"
  add_cmake_options "-DQT_UIC_EXECUTABLE=/usr/lib/qt6/libexec/uic"
  add_cmake_options "-DQT_RCC_EXECUTABLE=/usr/lib/qt6/libexec/rcc"
  
  # Qt6 configuration for x86_64 with full WebEngine and Wayland support - validate paths with strict checking
  validate_and_add_qt6_cmake_dir "Qt6" "/usr/lib/x86_64-linux-gnu/cmake/Qt6" "true"
  validate_and_add_qt6_cmake_dir "Qt6Core" "/usr/lib/x86_64-linux-gnu/cmake/Qt6Core" "true"
  validate_and_add_qt6_cmake_dir "Qt6Widgets" "/usr/lib/x86_64-linux-gnu/cmake/Qt6Widgets" "true"
  validate_and_add_qt6_cmake_dir "Qt6Gui" "/usr/lib/x86_64-linux-gnu/cmake/Qt6Gui" "true"
  validate_and_add_qt6_cmake_dir "Qt6WebEngine" "/usr/lib/x86_64-linux-gnu/cmake/Qt6WebEngine" "false"
  validate_and_add_qt6_cmake_dir "Qt6WebEngineCore" "/usr/lib/x86_64-linux-gnu/cmake/Qt6WebEngineCore" "false"
  validate_and_add_qt6_cmake_dir "Qt6WebEngineWidgets" "/usr/lib/x86_64-linux-gnu/cmake/Qt6WebEngineWidgets" "false"
  validate_and_add_qt6_cmake_dir "Qt6Qml" "/usr/lib/x86_64-linux-gnu/cmake/Qt6Qml" "false"
  validate_and_add_qt6_cmake_dir "Qt6Quick" "/usr/lib/x86_64-linux-gnu/cmake/Qt6Quick" "false"
  validate_and_add_qt6_cmake_dir "Qt6GuiTools" "/usr/lib/x86_64-linux-gnu/cmake/Qt6GuiTools" "false"
  
  # Qt6 Wayland support for immutable OS environments like Bazzite - with validation
  validate_and_add_qt6_cmake_dir "Qt6WaylandClient" "/usr/lib/x86_64-linux-gnu/cmake/Qt6WaylandClient" "false"
  validate_and_add_qt6_cmake_dir "Qt6WaylandCompositor" "/usr/lib/x86_64-linux-gnu/cmake/Qt6WaylandCompositor" "false"
  
  # Additional Wayland integration components (optional) - with validation
  if [ -d "/usr/lib/x86_64-linux-gnu/cmake/Qt6WaylandGlobalPrivate" ]; then
    validate_and_add_qt6_cmake_dir "Qt6WaylandGlobalPrivate" "/usr/lib/x86_64-linux-gnu/cmake/Qt6WaylandGlobalPrivate" "false"
  fi
  
  # OpenGL configuration for x86_64 with improved AMD graphics support
  add_cmake_options "-DOPENGL_opengl_LIBRARY=/usr/lib/x86_64-linux-gnu/libOpenGL.so"
  add_cmake_options "-DOPENGL_gl_LIBRARY=/usr/lib/x86_64-linux-gnu/libGL.so"
  add_cmake_options "-DOPENGL_glx_LIBRARY=/usr/lib/x86_64-linux-gnu/libGLX.so"
  validate_and_add_qt6_cmake_dir "Qt6OpenGL" "/usr/lib/x86_64-linux-gnu/cmake/Qt6OpenGL" "true"
  validate_and_add_qt6_cmake_dir "Qt6OpenGLWidgets" "/usr/lib/x86_64-linux-gnu/cmake/Qt6OpenGLWidgets" "false"
  
  # x86_64 library search paths
  add_cmake_options "-DCMAKE_PREFIX_PATH=/usr/lib/x86_64-linux-gnu/cmake"
  add_cmake_options "-DCMAKE_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/lib64:/lib64"
}

quirk_build_start() {
  # Setup Qt6 build environment for x86_64 only
  show_status "Setting up Qt6 x86_64 build environment"
  
  # Use clang as preferred compiler
  if command -v clang++ >/dev/null 2>&1; then
    export CXX=clang++
    export CC=clang
    show_status "Using clang++ compiler for Qt6 x86_64 build"
  else
    export CXX=g++
    export CC=gcc
    show_status "Using g++ compiler for Qt6 x86_64 build"
  fi
  
  # Use Ninja for faster builds
  export CMAKE_GENERATOR="Ninja"
  
  # Set parallel build jobs
  if [ -z "$MAKE_JOBS" ]; then
    export MAKE_JOBS=$(nproc)
  fi
  
  # Qt6 specific environment variables and paths
  export QT_VERSION=6
  export CMAKE_QT_VERSION=Qt6
  export PATH="/usr/lib/qt6/bin:/usr/lib/qt6/libexec:$PATH"
  
  show_status "Qt6 UI build environment ready for x86_64 (WebEngine and Wayland support)"
}