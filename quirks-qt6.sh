# Qt6 Ubuntu 22.04 quirks for x86_64 builds with modern Qt6 framework
# Focuses on single architecture builds with Qt6 for improved compatibility

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
  
  # Qt6 configuration for modern framework
  add_cmake_options "-DQt6_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6"
  add_cmake_options "-DQt6Core_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6Core"
  add_cmake_options "-DQt6Widgets_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6Widgets"
  add_cmake_options "-DQt6GuiTools_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6GuiTools"
}

quirk_build_mcpelauncher_ui() {
  # UI build configuration with Qt6 WebEngine support for x86_64
  add_cmake_options "-DCURL_LIBRARY=/usr/lib/x86_64-linux-gnu/libcurl.so"
  add_cmake_options "-DCMAKE_CXX_STANDARD=17" "-DCMAKE_C_STANDARD=11"
  add_cmake_options "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
  add_cmake_options "-DCMAKE_BUILD_TYPE=Release"
  
  # Qt6 configuration for x86_64 with full WebEngine and Wayland support
  add_cmake_options "-DQt6_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6"
  add_cmake_options "-DQt6Core_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6Core"
  add_cmake_options "-DQt6Widgets_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6Widgets"
  add_cmake_options "-DQt6Gui_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6Gui"
  add_cmake_options "-DQt6WebEngine_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6WebEngine"
  add_cmake_options "-DQt6WebEngineCore_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6WebEngineCore"
  add_cmake_options "-DQt6WebEngineWidgets_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6WebEngineWidgets"
  add_cmake_options "-DQt6Qml_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6Qml"
  add_cmake_options "-DQt6Quick_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6Quick"
  add_cmake_options "-DQt6GuiTools_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6GuiTools"
  
  # Qt6 Wayland support for immutable OS environments like Bazzite
  add_cmake_options "-DQt6WaylandClient_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6WaylandClient"
  
  # OpenGL configuration for x86_64 with improved AMD graphics support
  add_cmake_options "-DOPENGL_opengl_LIBRARY=/usr/lib/x86_64-linux-gnu/libOpenGL.so"
  add_cmake_options "-DOPENGL_gl_LIBRARY=/usr/lib/x86_64-linux-gnu/libGL.so"
  add_cmake_options "-DOPENGL_glx_LIBRARY=/usr/lib/x86_64-linux-gnu/libGLX.so"
  add_cmake_options "-DQt6OpenGL_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6OpenGL"
  
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