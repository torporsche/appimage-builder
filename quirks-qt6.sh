# Qt6 Ubuntu 22.04 quirks for x86_64 builds with modern Qt6 framework
# Focuses on single architecture builds with Qt6 for improved compatibility

# Helper function to validate Qt6 CMake paths before using them
validate_and_add_qt6_cmake_dir() {
  local component_name="$1"
  local cmake_dir="$2"
  
  if [ -d "$cmake_dir" ]; then
    add_cmake_options "-D${component_name}_DIR=$cmake_dir"
    show_status "Qt6 $component_name: Found at $cmake_dir"
  else
    show_status "Qt6 $component_name: Not found at $cmake_dir - skipping"
  fi
}

# Function to detect Qt6 components and configure fallbacks
configure_qt6_wayland_fallbacks() {
  local wayland_available=false
  
  # Check for Wayland support
  if [ -d "/usr/lib/x86_64-linux-gnu/cmake/Qt6WaylandClient" ] || \
     [ -f "/usr/lib/x86_64-linux-gnu/libQt6WaylandClient.so" ]; then
    wayland_available=true
    show_status "Qt6 Wayland support detected"
  else
    show_status "Qt6 Wayland support not available - using X11 fallback"
  fi
  
  # Configure Wayland environment variables
  if [ "$wayland_available" = "true" ]; then
    # Native Wayland support
    add_cmake_options "-DENABLE_WAYLAND=ON"
    export QT_QPA_PLATFORM="wayland;xcb"
    export QT_WAYLAND_FORCE_DPI=96
    export QT_AUTO_SCREEN_SCALE_FACTOR=0
  else
    # X11 fallback
    add_cmake_options "-DENABLE_WAYLAND=OFF"
    export QT_QPA_PLATFORM="xcb"
    export QT_AUTO_SCREEN_SCALE_FACTOR=0
  fi
}

# Function to configure OpenGL ES fallbacks
configure_opengl_fallbacks() {
  # Check for hardware OpenGL support
  if [ -f "/usr/lib/x86_64-linux-gnu/libGL.so" ]; then
    show_status "Hardware OpenGL support available"
    add_cmake_options "-DFORCE_SOFTWARE_RENDERING=OFF"
  else
    show_status "Hardware OpenGL not detected - enabling software fallback"
    add_cmake_options "-DFORCE_SOFTWARE_RENDERING=ON"
    export LIBGL_ALWAYS_SOFTWARE=1
    export MESA_GL_VERSION_OVERRIDE=3.3
  fi
}

quirk_init() {
  # Set up modern compiler environment for x86_64 only
  export CXXFLAGS="-std=c++17 -fPIC $CXXFLAGS"
  export CFLAGS="-fPIC $CFLAGS"
  
  # Set up x86_64 library paths
  export PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig:/usr/lib/pkgconfig"
  export DEBIANTARGET="x86_64-linux-gnu"
  
  # Set MSA_QT6_OPT flag to enable Qt6 Wayland plugin bundling
  export MSA_QT6_OPT=1
  
  # Configure Qt6 Wayland and OpenGL fallbacks
  configure_qt6_wayland_fallbacks
  configure_opengl_fallbacks
  
  # Configure environment variables for Wayland/X11 compatibility
  export QT_LOGGING_RULES="qt.qpa.wayland.debug=false"
  export QT_WAYLAND_DISABLE_WINDOWDECORATION=0
  export QT_SCALE_FACTOR_ROUNDING_POLICY=RoundPreferFloor
  
  show_status "Qt6 build environment ready for x86_64 (modern framework with Wayland support)"
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
  
  # Qt6 configuration for modern framework - validate paths before using
  validate_and_add_qt6_cmake_dir "Qt6" "/usr/lib/x86_64-linux-gnu/cmake/Qt6"
  validate_and_add_qt6_cmake_dir "Qt6Core" "/usr/lib/x86_64-linux-gnu/cmake/Qt6Core"
  validate_and_add_qt6_cmake_dir "Qt6Widgets" "/usr/lib/x86_64-linux-gnu/cmake/Qt6Widgets"
  validate_and_add_qt6_cmake_dir "Qt6GuiTools" "/usr/lib/x86_64-linux-gnu/cmake/Qt6GuiTools"
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
  
  # Qt6 configuration for x86_64 with full WebEngine and Wayland support - validate paths
  validate_and_add_qt6_cmake_dir "Qt6" "/usr/lib/x86_64-linux-gnu/cmake/Qt6"
  validate_and_add_qt6_cmake_dir "Qt6Core" "/usr/lib/x86_64-linux-gnu/cmake/Qt6Core"
  validate_and_add_qt6_cmake_dir "Qt6Widgets" "/usr/lib/x86_64-linux-gnu/cmake/Qt6Widgets"
  validate_and_add_qt6_cmake_dir "Qt6Gui" "/usr/lib/x86_64-linux-gnu/cmake/Qt6Gui"
  validate_and_add_qt6_cmake_dir "Qt6WebEngine" "/usr/lib/x86_64-linux-gnu/cmake/Qt6WebEngine"
  validate_and_add_qt6_cmake_dir "Qt6WebEngineCore" "/usr/lib/x86_64-linux-gnu/cmake/Qt6WebEngineCore"
  validate_and_add_qt6_cmake_dir "Qt6WebEngineWidgets" "/usr/lib/x86_64-linux-gnu/cmake/Qt6WebEngineWidgets"
  validate_and_add_qt6_cmake_dir "Qt6Qml" "/usr/lib/x86_64-linux-gnu/cmake/Qt6Qml"
  validate_and_add_qt6_cmake_dir "Qt6Quick" "/usr/lib/x86_64-linux-gnu/cmake/Qt6Quick"
  validate_and_add_qt6_cmake_dir "Qt6GuiTools" "/usr/lib/x86_64-linux-gnu/cmake/Qt6GuiTools"
  
  # Qt6 Wayland support for immutable OS environments like Bazzite
  validate_and_add_qt6_cmake_dir "Qt6WaylandClient" "/usr/lib/x86_64-linux-gnu/cmake/Qt6WaylandClient"
  validate_and_add_qt6_cmake_dir "Qt6WaylandCompositor" "/usr/lib/x86_64-linux-gnu/cmake/Qt6WaylandCompositor"
  
  # Additional Wayland integration components (optional)
  if [ -d "/usr/lib/x86_64-linux-gnu/cmake/Qt6WaylandGlobalPrivate" ]; then
    validate_and_add_qt6_cmake_dir "Qt6WaylandGlobalPrivate" "/usr/lib/x86_64-linux-gnu/cmake/Qt6WaylandGlobalPrivate"
  fi
  
  # OpenGL configuration for x86_64 with improved AMD graphics support
  add_cmake_options "-DOPENGL_opengl_LIBRARY=/usr/lib/x86_64-linux-gnu/libOpenGL.so"
  add_cmake_options "-DOPENGL_gl_LIBRARY=/usr/lib/x86_64-linux-gnu/libGL.so"
  add_cmake_options "-DOPENGL_glx_LIBRARY=/usr/lib/x86_64-linux-gnu/libGLX.so"
  validate_and_add_qt6_cmake_dir "Qt6OpenGL" "/usr/lib/x86_64-linux-gnu/cmake/Qt6OpenGL"
  validate_and_add_qt6_cmake_dir "Qt6OpenGLWidgets" "/usr/lib/x86_64-linux-gnu/cmake/Qt6OpenGLWidgets"
  
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