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

quirk_init() {
  # Set up modern compiler environment for x86_64 only
  export CXXFLAGS="-std=c++17 -fPIC $CXXFLAGS"
  export CFLAGS="-fPIC $CFLAGS"
  
  # Set Qt6 build flag to ensure Wayland plugins are bundled
  export MSA_QT6_OPT="-DQT_VERSION=6"
  export COMMIT_FILE_SUFFIX="-qt6"
  
  # Set up x86_64 library paths
  export PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig:/usr/lib/pkgconfig"
  export DEBIANTARGET="x86_64-linux-gnu"
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
  
  # OpenGL configuration for x86_64 with improved AMD graphics support
  add_cmake_options "-DOPENGL_opengl_LIBRARY=/usr/lib/x86_64-linux-gnu/libOpenGL.so"
  add_cmake_options "-DOPENGL_gl_LIBRARY=/usr/lib/x86_64-linux-gnu/libGL.so"
  add_cmake_options "-DOPENGL_glx_LIBRARY=/usr/lib/x86_64-linux-gnu/libGLX.so"
  validate_and_add_qt6_cmake_dir "Qt6OpenGL" "/usr/lib/x86_64-linux-gnu/cmake/Qt6OpenGL"
  
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
  
  # Qt6 specific environment variables
  export QT_VERSION=6
  export CMAKE_QT_VERSION=Qt6
  
  show_status "Qt6 build environment ready for x86_64 (modern framework)"
}