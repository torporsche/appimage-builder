# Quirks for 32-bit (x86) builds
# This file addresses 32-bit specific build issues and library paths

quirk_init() {
  # Set up 32-bit build environment
  export CXXFLAGS="-m32 -std=c++17 -fPIC $CXXFLAGS"
  export CFLAGS="-m32 -fPIC $CFLAGS"
  
  # 32-bit specific library paths
  export PKG_CONFIG_PATH="/usr/lib/i386-linux-gnu/pkgconfig:/usr/share/pkgconfig:/usr/lib/pkgconfig"
  export CMAKE_PREFIX_PATH="/usr/lib/i386-linux-gnu/cmake"
  
  # Linker flags for atomic operations on 32-bit
  export LDFLAGS="-latomic $LDFLAGS"
}

quirk_build_msa() {
  # MSA build configuration for 32-bit
  add_cmake_options "-DCMAKE_C_FLAGS=-m32 -Wl,-latomic"
  add_cmake_options "-DCMAKE_CXX_FLAGS=-m32 -std=c++17 -Wl,-latomic"
  add_cmake_options "-DCMAKE_CXX_STANDARD=17" "-DCMAKE_C_STANDARD=11"
  add_cmake_options "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
  
  # 32-bit library paths
  add_cmake_options "-DCMAKE_FIND_ROOT_PATH=/usr/lib/i386-linux-gnu"
  add_cmake_options "-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH"
  add_cmake_options "-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH"
  add_cmake_options "-DCMAKE_LIBRARY_PATH=/usr/lib/i386-linux-gnu;/usr/lib32"
  
  # SSL configuration for 32-bit
  add_cmake_options "-DOPENSSL_ROOT_DIR=/usr/lib/i386-linux-gnu"
  add_cmake_options "-DOPENSSL_INCLUDE_DIR=/usr/include"
  add_cmake_options "-DOPENSSL_CRYPTO_LIBRARY=/usr/lib/i386-linux-gnu/libcrypto.so"
  add_cmake_options "-DOPENSSL_SSL_LIBRARY=/usr/lib/i386-linux-gnu/libssl.so"
  
  # Qt configuration based on available version
  if [ -n "$MSA_QT6_OPT" ]; then
    add_cmake_options "-DQt6_DIR=/usr/lib/i386-linux-gnu/cmake/Qt6"
    add_cmake_options "-DQt6GuiTools_DIR=/usr/lib/i386-linux-gnu/cmake/Qt6GuiTools"
    add_cmake_options "-DQt6WebEngineCore_DIR=/usr/lib/i386-linux-gnu/cmake/Qt6WebEngineCore"
    add_cmake_options "-DQt6WebEngineWidgets_DIR=/usr/lib/i386-linux-gnu/cmake/Qt6WebEngineWidgets"
  else
    add_cmake_options "-DQt5_DIR=/usr/lib/i386-linux-gnu/cmake/Qt5"
    add_cmake_options "-DQt5Widgets_DIR=/usr/lib/i386-linux-gnu/cmake/Qt5Widgets"
    add_cmake_options "-DQt5WebEngine_DIR=/usr/lib/i386-linux-gnu/cmake/Qt5WebEngine"
    add_cmake_options "-DQt5WebEngineWidgets_DIR=/usr/lib/i386-linux-gnu/cmake/Qt5WebEngineWidgets"
  fi
}

quirk_build_mcpelauncher() {
  # Launcher build configuration for 32-bit
  add_cmake_options "-DCMAKE_C_FLAGS=-m32 -Wl,-latomic"
  add_cmake_options "-DCMAKE_CXX_FLAGS=-m32 -std=c++17 -Wl,-latomic"
  add_cmake_options "-DCMAKE_CXX_STANDARD=17" "-DCMAKE_C_STANDARD=11"
  add_cmake_options "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
  add_cmake_options "-DCMAKE_BUILD_TYPE=Release"
  
  # 32-bit library paths
  add_cmake_options "-DCMAKE_FIND_ROOT_PATH=/usr/lib/i386-linux-gnu"
  add_cmake_options "-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH"
  add_cmake_options "-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH"
  add_cmake_options "-DCMAKE_LIBRARY_PATH=/usr/lib/i386-linux-gnu;/usr/lib32"
  add_cmake_options "-DCMAKE_INCLUDE_PATH=/usr/include/i386-linux-gnu"
  
  # SSL configuration for 32-bit
  add_cmake_options "-DOPENSSL_ROOT_DIR=/usr/lib/i386-linux-gnu"
  add_cmake_options "-DOPENSSL_INCLUDE_DIR=/usr/include"
  add_cmake_options "-DOPENSSL_CRYPTO_LIBRARY=/usr/lib/i386-linux-gnu/libcrypto.so"
  add_cmake_options "-DOPENSSL_SSL_LIBRARY=/usr/lib/i386-linux-gnu/libssl.so"
  
  # Use own curl to avoid conflicts
  add_cmake_options "-DUSE_OWN_CURL=ON"
  
  # OpenGL configuration for 32-bit
  add_cmake_options "-DOPENGL_opengl_LIBRARY=/usr/lib/i386-linux-gnu/libOpenGL.so"
  add_cmake_options "-DOPENGL_gl_LIBRARY=/usr/lib/i386-linux-gnu/libGL.so"
}

quirk_build_mcpelauncher_ui() {
  # UI build configuration for 32-bit
  add_cmake_options "-DCMAKE_C_FLAGS=-m32 -Wl,-latomic"
  add_cmake_options "-DCMAKE_CXX_FLAGS=-m32 -std=c++17 -Wl,-latomic"
  add_cmake_options "-DCMAKE_CXX_STANDARD=17" "-DCMAKE_C_STANDARD=11"
  add_cmake_options "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
  add_cmake_options "-DCMAKE_BUILD_TYPE=Release"
  
  # 32-bit library paths
  add_cmake_options "-DCMAKE_FIND_ROOT_PATH=/usr/lib/i386-linux-gnu"
  add_cmake_options "-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH"
  add_cmake_options "-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH"
  add_cmake_options "-DCMAKE_LIBRARY_PATH=/usr/lib/i386-linux-gnu;/usr/lib32"
  add_cmake_options "-DCMAKE_INCLUDE_PATH=/usr/include/i386-linux-gnu"
  
  # SSL configuration for 32-bit
  add_cmake_options "-DOPENSSL_ROOT_DIR=/usr/lib/i386-linux-gnu"
  add_cmake_options "-DOPENSSL_INCLUDE_DIR=/usr/include"
  add_cmake_options "-DOPENSSL_CRYPTO_LIBRARY=/usr/lib/i386-linux-gnu/libcrypto.so"
  add_cmake_options "-DOPENSSL_SSL_LIBRARY=/usr/lib/i386-linux-gnu/libssl.so"
  
  # Qt configuration for 32-bit
  if [ -n "$MSA_QT6_OPT" ]; then
    add_cmake_options "-DQt6_DIR=/usr/lib/i386-linux-gnu/cmake/Qt6"
    add_cmake_options "-DQt6GuiTools_DIR=/usr/lib/i386-linux-gnu/cmake/Qt6GuiTools"
    add_cmake_options "-DQt6WebEngineCore_DIR=/usr/lib/i386-linux-gnu/cmake/Qt6WebEngineCore"
    add_cmake_options "-DQt6WebEngineWidgets_DIR=/usr/lib/i386-linux-gnu/cmake/Qt6WebEngineWidgets"
    add_cmake_options "-DQt6WebEngineQuick_DIR=/usr/lib/i386-linux-gnu/cmake/Qt6WebEngineQuick"
    add_cmake_options "-DQt6Qml_DIR=/usr/lib/i386-linux-gnu/cmake/Qt6Qml"
    add_cmake_options "-DQt6Quick_DIR=/usr/lib/i386-linux-gnu/cmake/Qt6Quick"
  else
    add_cmake_options "-DQt5_DIR=/usr/lib/i386-linux-gnu/cmake/Qt5"
    add_cmake_options "-DQt5Widgets_DIR=/usr/lib/i386-linux-gnu/cmake/Qt5Widgets"
    add_cmake_options "-DQt5WebEngine_DIR=/usr/lib/i386-linux-gnu/cmake/Qt5WebEngine"
    add_cmake_options "-DQt5WebEngineWidgets_DIR=/usr/lib/i386-linux-gnu/cmake/Qt5WebEngineWidgets"
    add_cmake_options "-DQt5Qml_DIR=/usr/lib/i386-linux-gnu/cmake/Qt5Qml"
    add_cmake_options "-DQt5Quick_DIR=/usr/lib/i386-linux-gnu/cmake/Qt5Quick"
  fi
  
  # OpenGL configuration for 32-bit
  add_cmake_options "-DOPENGL_opengl_LIBRARY=/usr/lib/i386-linux-gnu/libOpenGL.so"
  add_cmake_options "-DOPENGL_gl_LIBRARY=/usr/lib/i386-linux-gnu/libGL.so"
  add_cmake_options "-DOPENGL_glx_LIBRARY=/usr/lib/i386-linux-gnu/libGLX.so"
}

quirk_build_start() {
  # Setup 32-bit build environment
  show_status "Setting up 32-bit build environment"
  
  # Ensure proper compiler selection
  if command -v clang++ >/dev/null 2>&1; then
    export CXX="clang++ -m32"
    export CC="clang -m32"
    show_status "Using clang compiler with 32-bit flags"
  else
    export CXX="g++ -m32"
    export CC="gcc -m32"
    show_status "Using gcc compiler with 32-bit flags"
  fi
  
  # Modern CMake settings
  export CMAKE_GENERATOR="Ninja"
  
  # Improve parallel build performance
  if [ -z "$MAKE_JOBS" ]; then
    export MAKE_JOBS=$(nproc)
  fi
}