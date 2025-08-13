# Modern Ubuntu quirks for improved compatibility with newer toolchains and Qt versions
# This quirks file addresses common build issues on Ubuntu 20.04+ systems

quirk_init() {
  # Set up modern compiler environment
  export CXXFLAGS="-std=c++17 -fPIC $CXXFLAGS"
  export CFLAGS="-fPIC $CFLAGS"
  
  # Ensure we use modern OpenSSL
  if [ -d "/usr/lib/x86_64-linux-gnu" ]; then
    export PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH"
  fi
}

quirk_build_msa() {
  # Modern MSA build configuration
  add_cmake_options "-DCURL_LIBRARY=/usr/lib/${DEBIANTARGET}/libcurl.so"
  add_cmake_options "-DCMAKE_CXX_STANDARD=17" "-DCMAKE_C_STANDARD=11"
  add_cmake_options "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
  
  # Ensure PKG_CONFIG_PATH is set for dependency detection
  if [ -d "/usr/lib/${DEBIANTARGET}/pkgconfig" ]; then
    export PKG_CONFIG_PATH="/usr/lib/${DEBIANTARGET}/pkgconfig:$PKG_CONFIG_PATH"
  fi
  
  # Qt version detection and configuration
  if [ -n "$MSA_QT6_OPT" ]; then
    add_cmake_options "-DQt6_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt6"
    add_cmake_options "-DQt6GuiTools_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt6GuiTools"
    add_cmake_options "-DQt6WebEngineCore_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt6WebEngineCore"
    add_cmake_options "-DQt6WebEngineWidgets_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt6WebEngineWidgets"
  else
    add_cmake_options "-DQt5_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt5"
    add_cmake_options "-DQt5Widgets_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt5Widgets"
    add_cmake_options "-DQt5WebEngine_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt5WebEngine"
    add_cmake_options "-DQt5WebEngineWidgets_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt5WebEngineWidgets"
  fi
  
  # OpenGL configuration
  add_cmake_options "-DOPENGL_opengl_LIBRARY=/usr/lib/${DEBIANTARGET}/libOpenGL.so"
  add_cmake_options "-DOPENGL_gl_LIBRARY=/usr/lib/${DEBIANTARGET}/libGL.so"
}

quirk_build_mcpelauncher() {
  # Modern launcher build configuration
  add_cmake_options "-DCMAKE_CXX_STANDARD=17" "-DCMAKE_C_STANDARD=11"
  add_cmake_options "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
  add_cmake_options "-DCMAKE_BUILD_TYPE=Release"
  
  # Library path improvements
  add_cmake_options "-DCMAKE_PREFIX_PATH=/usr/lib/${DEBIANTARGET}/cmake"
  add_cmake_options "-DCMAKE_LIBRARY_PATH=/usr/lib/${DEBIANTARGET};/usr/lib64;/lib64"
  
  # OpenGL and graphics libraries
  add_cmake_options "-DOPENGL_opengl_LIBRARY=/usr/lib/${DEBIANTARGET}/libOpenGL.so"
  add_cmake_options "-DOPENGL_gl_LIBRARY=/usr/lib/${DEBIANTARGET}/libGL.so"
  
  # Qt configuration based on version
  if [ -n "$MSA_QT6_OPT" ]; then
    add_cmake_options "-DQt6_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt6"
    add_cmake_options "-DQt6GuiTools_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt6GuiTools"
  else
    add_cmake_options "-DQt5_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt5"
    add_cmake_options "-DQt5Widgets_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt5Widgets"
  fi
}

quirk_build_mcpelauncher32() {
  # 32-bit build configuration with improved compatibility
  add_cmake_options "-DCMAKE_CXX_COMPILER_TARGET=i686-linux-gnu"
  add_cmake_options "-DCMAKE_CXX_STANDARD=17" "-DCMAKE_C_STANDARD=11"
  add_cmake_options "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
  add_cmake_options "-DBUILD_FAKE_JNI_TESTS=OFF" "-DBUILD_FAKE_JNI_EXAMPLES=OFF"
  # Use own curl to avoid conflicts with system packages
  add_cmake_options "-DUSE_OWN_CURL=ON"
  
  # Improved library paths for 32-bit
  add_cmake_options "-DCMAKE_LIBRARY_PATH=/usr/lib/i386-linux-gnu;/usr/lib32"
  add_cmake_options "-DCMAKE_INCLUDE_PATH=/usr/include/i386-linux-gnu"
  
  # Specify 32-bit SSL libraries explicitly
  add_cmake_options "-DOPENSSL_ROOT_DIR=/usr"
  add_cmake_options "-DOPENSSL_INCLUDE_DIR=/usr/include"
  add_cmake_options "-DOPENSSL_CRYPTO_LIBRARY=/usr/lib/i386-linux-gnu/libcrypto.so"
  add_cmake_options "-DOPENSSL_SSL_LIBRARY=/usr/lib/i386-linux-gnu/libssl.so"
}

quirk_build_mcpelauncher_ui() {
  # UI build configuration with Qt WebEngine support
  add_cmake_options "-DCURL_LIBRARY=/usr/lib/${DEBIANTARGET}/libcurl.so"
  add_cmake_options "-DCMAKE_CXX_STANDARD=17" "-DCMAKE_C_STANDARD=11"
  add_cmake_options "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
  add_cmake_options "-DCMAKE_BUILD_TYPE=Release"
  
  # Enhanced Qt configuration
  if [ -n "$MSA_QT6_OPT" ]; then
    add_cmake_options "-DQt6_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt6"
    add_cmake_options "-DQt6GuiTools_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt6GuiTools"
    add_cmake_options "-DQt6WebEngineCore_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt6WebEngineCore"
    add_cmake_options "-DQt6WebEngineWidgets_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt6WebEngineWidgets"
    add_cmake_options "-DQt6WebEngineQuick_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt6WebEngineQuick"
    add_cmake_options "-DQt6Qml_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt6Qml"
    add_cmake_options "-DQt6Quick_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt6Quick"
  else
    add_cmake_options "-DQt5_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt5"
    add_cmake_options "-DQt5Widgets_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt5Widgets"
    add_cmake_options "-DQt5WebEngine_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt5WebEngine"
    add_cmake_options "-DQt5WebEngineWidgets_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt5WebEngineWidgets"
    add_cmake_options "-DQt5Qml_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt5Qml"
    add_cmake_options "-DQt5Quick_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt5Quick"
  fi
  
  # OpenGL configuration
  add_cmake_options "-DOPENGL_opengl_LIBRARY=/usr/lib/${DEBIANTARGET}/libOpenGL.so"
  add_cmake_options "-DOPENGL_gl_LIBRARY=/usr/lib/${DEBIANTARGET}/libGL.so"
  add_cmake_options "-DOPENGL_glx_LIBRARY=/usr/lib/${DEBIANTARGET}/libGLX.so"
  
  # Library search improvements
  add_cmake_options "-DCMAKE_PREFIX_PATH=/usr/lib/${DEBIANTARGET}/cmake"
  add_cmake_options "-DCMAKE_LIBRARY_PATH=/usr/lib/${DEBIANTARGET};/usr/lib64;/lib64"
}

quirk_build_start() {
  # Setup build environment
  show_status "Setting up modern build environment"
  
  # Ensure proper compiler selection
  if command -v clang++ >/dev/null 2>&1; then
    export CXX=clang++
    export CC=clang
    show_status "Using clang++ compiler"
  else
    export CXX=g++
    export CC=gcc
    show_status "Using g++ compiler"
  fi
  
  # Improve parallel build performance
  if [ -z "$MAKE_JOBS" ]; then
    export MAKE_JOBS=$(nproc)
  fi
}