# Simplified Ubuntu 22.04 quirks for x86_64 only builds with Qt5
# Focuses on single architecture builds without multilib complexity

quirk_init() {
  # Set up modern compiler environment for x86_64 only
  export CXXFLAGS="-std=c++17 -fPIC $CXXFLAGS"
  export CFLAGS="-fPIC $CFLAGS"
  
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
  # Modern launcher build configuration for x86_64 only
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
  
  # Qt5 configuration (no Qt6 support in clean restart)
  add_cmake_options "-DQt5_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt5"
  add_cmake_options "-DQt5Widgets_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt5Widgets"
}

quirk_build_mcpelauncher_ui() {
  # UI build configuration with Qt5 WebEngine support for x86_64 only
  add_cmake_options "-DCURL_LIBRARY=/usr/lib/x86_64-linux-gnu/libcurl.so"
  add_cmake_options "-DCMAKE_CXX_STANDARD=17" "-DCMAKE_C_STANDARD=11"
  add_cmake_options "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
  add_cmake_options "-DCMAKE_BUILD_TYPE=Release"
  
  # Qt5 configuration for x86_64
  add_cmake_options "-DQt5_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt5"
  add_cmake_options "-DQt5Widgets_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt5Widgets"
  add_cmake_options "-DQt5WebEngine_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt5WebEngine"
  add_cmake_options "-DQt5WebEngineWidgets_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt5WebEngineWidgets"
  add_cmake_options "-DQt5Qml_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt5Qml"
  add_cmake_options "-DQt5Quick_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt5Quick"
  
  # OpenGL configuration for x86_64
  add_cmake_options "-DOPENGL_opengl_LIBRARY=/usr/lib/x86_64-linux-gnu/libOpenGL.so"
  add_cmake_options "-DOPENGL_gl_LIBRARY=/usr/lib/x86_64-linux-gnu/libGL.so"
  add_cmake_options "-DOPENGL_glx_LIBRARY=/usr/lib/x86_64-linux-gnu/libGLX.so"
  
  # x86_64 library search paths
  add_cmake_options "-DCMAKE_PREFIX_PATH=/usr/lib/x86_64-linux-gnu/cmake"
  add_cmake_options "-DCMAKE_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/lib64:/lib64"
}

quirk_build_start() {
  # Setup simplified build environment for x86_64 only
  show_status "Setting up simplified x86_64 build environment"
  
  # Use clang as preferred compiler
  if command -v clang++ >/dev/null 2>&1; then
    export CXX=clang++
    export CC=clang
    show_status "Using clang++ compiler for x86_64 build"
  else
    export CXX=g++
    export CC=gcc
    show_status "Using g++ compiler for x86_64 build"
  fi
  
  # Use Ninja for faster builds
  export CMAKE_GENERATOR="Ninja"
  
  # Set parallel build jobs
  if [ -z "$MAKE_JOBS" ]; then
    export MAKE_JOBS=$(nproc)
  fi
  
  show_status "Build environment ready for x86_64 (single architecture)"
}