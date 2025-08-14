# Qt5 Legacy compatibility quirks for older system support
# Focuses on Qt5 builds for broader compatibility with older distributions

# Helper function to validate Qt5 CMake paths before using them
validate_and_add_qt5_cmake_dir() {
  local component_name="$1"
  local cmake_dir="$2"
  
  if [ -d "$cmake_dir" ]; then
    add_cmake_options "-D${component_name}_DIR=$cmake_dir"
    show_status "Qt5 $component_name: Found at $cmake_dir"
  else
    show_status "Qt5 $component_name: Not found at $cmake_dir - skipping"
  fi
}

quirk_init() {
  # Set up legacy compiler environment for broader compatibility
  export CXXFLAGS="-std=c++17 -fPIC $CXXFLAGS"
  export CFLAGS="-fPIC $CFLAGS"
  
  # Set up x86_64 library paths for Qt5
  export PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig:/usr/lib/pkgconfig"
  export DEBIANTARGET="x86_64-linux-gnu"
  
  # Qt5 specific environment variables
  export QT_VERSION=5
  export CMAKE_QT_VERSION=Qt5
  
  show_status "Qt5 legacy build environment ready for broader compatibility"
}

quirk_build_msa() {
  # MSA is disabled by default in clean restart strategy
  # This function exists for compatibility but does nothing
  show_status "MSA component disabled in clean restart strategy"
  return 0
}

quirk_build_mcpelauncher() {
  # Legacy launcher build configuration for Qt5 compatibility
  add_cmake_options "-DCMAKE_CXX_STANDARD=17" "-DCMAKE_C_STANDARD=11"
  add_cmake_options "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
  add_cmake_options "-DCMAKE_BUILD_TYPE=Release"
  
  # Use system dependencies instead of downloading from external sources
  add_cmake_options "-DUSE_OWN_CURL=OFF"
  add_cmake_options "-DUSE_GAMECONTROLLERDB=OFF"
  
  # x86_64 library paths for Qt5
  add_cmake_options "-DCMAKE_PREFIX_PATH=/usr/lib/x86_64-linux-gnu/cmake"
  add_cmake_options "-DCMAKE_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/lib64:/lib64"
}

quirk_build_mcpelauncher_ui() {
  # Qt5 UI build configuration for legacy compatibility
  show_status "Building mcpelauncher-ui with Qt5 legacy compatibility..."
  
  # Qt5 specific paths and configuration
  validate_and_add_qt5_cmake_dir "Qt5" "/usr/lib/x86_64-linux-gnu/cmake/Qt5"
  validate_and_add_qt5_cmake_dir "Qt5Core" "/usr/lib/x86_64-linux-gnu/cmake/Qt5Core"
  validate_and_add_qt5_cmake_dir "Qt5Widgets" "/usr/lib/x86_64-linux-gnu/cmake/Qt5Widgets"
  validate_and_add_qt5_cmake_dir "Qt5Gui" "/usr/lib/x86_64-linux-gnu/cmake/Qt5Gui"
  validate_and_add_qt5_cmake_dir "Qt5WebEngine" "/usr/lib/x86_64-linux-gnu/cmake/Qt5WebEngine"
  validate_and_add_qt5_cmake_dir "Qt5WebEngineCore" "/usr/lib/x86_64-linux-gnu/cmake/Qt5WebEngineCore"
  validate_and_add_qt5_cmake_dir "Qt5WebEngineWidgets" "/usr/lib/x86_64-linux-gnu/cmake/Qt5WebEngineWidgets"
  
  # OpenGL libraries for Qt5
  add_cmake_options "-DOPENGL_gl_LIBRARY=/usr/lib/x86_64-linux-gnu/libGL.so"
  add_cmake_options "-DOPENGL_glu_LIBRARY=/usr/lib/x86_64-linux-gnu/libGLU.so"
  add_cmake_options "-DOPENGL_glx_LIBRARY=/usr/lib/x86_64-linux-gnu/libGLX.so"
  
  # x86_64 library search paths for Qt5
  add_cmake_options "-DCMAKE_PREFIX_PATH=/usr/lib/x86_64-linux-gnu/cmake"
  add_cmake_options "-DCMAKE_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/lib64:/lib64"
  
  # Compiler configuration for Qt5 compatibility
  add_cmake_options "-DCMAKE_CXX_STANDARD=17" "-DCMAKE_C_STANDARD=11"
  add_cmake_options "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
  add_cmake_options "-DCMAKE_BUILD_TYPE=Release"
  
  show_status "Qt5 UI build configuration complete"
}

quirk_build_start() {
  # Setup Qt5 build environment
  show_status "Setting up Qt5 legacy build environment"
  
  # Use GCC as preferred compiler for better Qt5 compatibility
  export CXX=g++
  export CC=gcc
  show_status "Using g++ compiler for Qt5 legacy build"
  
  # Use Make for traditional builds (more stable than Ninja for Qt5)
  export CMAKE_GENERATOR="Unix Makefiles"
  
  # Set parallel build jobs
  if [ -z "$MAKE_JOBS" ]; then
    export MAKE_JOBS=$(nproc)
  fi
  
  show_status "Qt5 legacy build environment ready (broader compatibility)"
}