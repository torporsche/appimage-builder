# Quirks for x86 (32-bit) builds
# This quirks file addresses specific issues when building for 32-bit x86 architecture

quirk_init() {
  # Set up 32-bit compiler environment
  export CXXFLAGS="-std=c++17 -m32 -fPIC $CXXFLAGS"
  export CFLAGS="-m32 -fPIC $CFLAGS"
  
  # Set up 32-bit library paths
  if [ -d "/usr/lib/i386-linux-gnu" ]; then
    export PKG_CONFIG_PATH="/usr/lib/i386-linux-gnu/pkgconfig:$PKG_CONFIG_PATH"
    export LD_LIBRARY_PATH="/usr/lib/i386-linux-gnu:/usr/lib32:/lib32:$LD_LIBRARY_PATH"
  fi
  
  # Force 32-bit architecture for all builds
  export CPPFLAGS="-m32 $CPPFLAGS"
  export LDFLAGS="-m32 $LDFLAGS"
}

quirk_build_msa() {
  # 32-bit MSA build configuration
  add_cmake_options "-DCMAKE_CXX_COMPILER_TARGET=i686-linux-gnu"
  add_cmake_options "-DCMAKE_C_COMPILER_TARGET=i686-linux-gnu"
  add_cmake_options "-DCMAKE_CXX_STANDARD=17" "-DCMAKE_C_STANDARD=11"
  add_cmake_options "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
  
  # 32-bit specific library paths
  add_cmake_options "-DCMAKE_LIBRARY_PATH=/usr/lib/i386-linux-gnu;/usr/lib32;/lib32"
  add_cmake_options "-DCMAKE_INCLUDE_PATH=/usr/include/i386-linux-gnu"
  
  # Qt configuration for 32-bit
  if [ -n "$MSA_QT6_OPT" ]; then
    add_cmake_options "-DQt6_DIR=/usr/lib/i386-linux-gnu/cmake/Qt6"
  else
    add_cmake_options "-DQt5_DIR=/usr/lib/i386-linux-gnu/cmake/Qt5"
  fi
}

quirk_build_mcpelauncher() {
  # 32-bit launcher build configuration
  add_cmake_options "-DCMAKE_CXX_COMPILER_TARGET=i686-linux-gnu"
  add_cmake_options "-DCMAKE_C_COMPILER_TARGET=i686-linux-gnu"
  add_cmake_options "-DCMAKE_CXX_STANDARD=17" "-DCMAKE_C_STANDARD=11"
  add_cmake_options "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
  add_cmake_options "-DCMAKE_BUILD_TYPE=Release"
  
  # Use own curl for 32-bit to avoid conflicts
  add_cmake_options "-DUSE_OWN_CURL=ON"
  
  # 32-bit library paths
  add_cmake_options "-DCMAKE_LIBRARY_PATH=/usr/lib/i386-linux-gnu;/usr/lib32;/lib32"
  add_cmake_options "-DCMAKE_INCLUDE_PATH=/usr/include/i386-linux-gnu"
  
  # OpenSSL for 32-bit
  add_cmake_options "-DOPENSSL_ROOT_DIR=/usr"
  add_cmake_options "-DOPENSSL_INCLUDE_DIR=/usr/include"
  add_cmake_options "-DOPENSSL_CRYPTO_LIBRARY=/usr/lib/i386-linux-gnu/libcrypto.so"
  add_cmake_options "-DOPENSSL_SSL_LIBRARY=/usr/lib/i386-linux-gnu/libssl.so"
}

quirk_build_mcpelauncher32() {
  # This is the same as regular mcpelauncher for x86 builds
  quirk_build_mcpelauncher
}

quirk_build_mcpelauncher_ui() {
  # 32-bit UI build configuration
  add_cmake_options "-DCMAKE_CXX_COMPILER_TARGET=i686-linux-gnu"
  add_cmake_options "-DCMAKE_C_COMPILER_TARGET=i686-linux-gnu"
  add_cmake_options "-DCMAKE_CXX_STANDARD=17" "-DCMAKE_C_STANDARD=11"
  add_cmake_options "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
  add_cmake_options "-DCMAKE_BUILD_TYPE=Release"
  
  # Use own curl for 32-bit
  add_cmake_options "-DUSE_OWN_CURL=ON"
  
  # 32-bit library paths
  add_cmake_options "-DCMAKE_LIBRARY_PATH=/usr/lib/i386-linux-gnu;/usr/lib32;/lib32"
  add_cmake_options "-DCMAKE_INCLUDE_PATH=/usr/include/i386-linux-gnu"
  
  # Qt configuration for 32-bit
  if [ -n "$MSA_QT6_OPT" ]; then
    add_cmake_options "-DQt6_DIR=/usr/lib/i386-linux-gnu/cmake/Qt6"
  else
    add_cmake_options "-DQt5_DIR=/usr/lib/i386-linux-gnu/cmake/Qt5"
  fi
  
  # OpenGL for 32-bit
  add_cmake_options "-DOPENGL_opengl_LIBRARY=/usr/lib/i386-linux-gnu/libOpenGL.so"
  add_cmake_options "-DOPENGL_gl_LIBRARY=/usr/lib/i386-linux-gnu/libGL.so"
  
  # OpenSSL for 32-bit
  add_cmake_options "-DOPENSSL_ROOT_DIR=/usr"
  add_cmake_options "-DOPENSSL_INCLUDE_DIR=/usr/include"
  add_cmake_options "-DOPENSSL_CRYPTO_LIBRARY=/usr/lib/i386-linux-gnu/libcrypto.so"
  add_cmake_options "-DOPENSSL_SSL_LIBRARY=/usr/lib/i386-linux-gnu/libssl.so"
}

quirk_build_start() {
  # Setup 32-bit build environment
  show_status "Setting up 32-bit build environment"
  
  # Ensure proper compiler selection for 32-bit
  if command -v clang++ >/dev/null 2>&1; then
    export CXX="clang++ -m32"
    export CC="clang -m32"
    show_status "Using clang compiler with 32-bit flags"
  else
    export CXX="g++ -m32"
    export CC="gcc -m32"
    show_status "Using gcc compiler with 32-bit flags"
  fi
  
  # Force CMake to use Ninja for better 32-bit support
  export CMAKE_GENERATOR="Ninja"
  
  # Improve parallel build performance
  if [ -z "$MAKE_JOBS" ]; then
    export MAKE_JOBS=$(nproc)
  fi
}