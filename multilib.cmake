# Multilib CMake configuration for 32-bit build toolchain
# Enables cross-compilation of 32-bit components on 64-bit systems

# Set basic toolchain information
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR i686)

# Set cross-compilation toolchain
set(CMAKE_C_COMPILER gcc)
set(CMAKE_CXX_COMPILER g++)

# Add 32-bit compilation flags
set(CMAKE_C_FLAGS "-m32 ${CMAKE_C_FLAGS}")
set(CMAKE_CXX_FLAGS "-m32 ${CMAKE_CXX_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS "-m32 ${CMAKE_EXE_LINKER_FLAGS}")
set(CMAKE_SHARED_LINKER_FLAGS "-m32 ${CMAKE_SHARED_LINKER_FLAGS}")

# Set 32-bit library search paths
set(CMAKE_FIND_ROOT_PATH 
    /usr/lib/i386-linux-gnu
    /usr/lib32
    /lib32
    /usr/lib/gcc/x86_64-linux-gnu/*/32
)

# Configure find modes for cross-compilation
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# Set PKG_CONFIG environment for 32-bit libraries
set(ENV{PKG_CONFIG_PATH} "/usr/lib/i386-linux-gnu/pkgconfig:/usr/lib32/pkgconfig")

# Configure library directories
set(CMAKE_LIBRARY_ARCHITECTURE "i386-linux-gnu")

# Set 32-bit specific install paths
set(CMAKE_INSTALL_LIBDIR "lib32")

# OpenGL library paths for 32-bit
set(OPENGL_gl_LIBRARY "/usr/lib/i386-linux-gnu/libGL.so")
set(OPENGL_glu_LIBRARY "/usr/lib/i386-linux-gnu/libGLU.so")

# Common 32-bit libraries
set(CURL_LIBRARY "/usr/lib/i386-linux-gnu/libcurl.so")
set(ZLIB_LIBRARY "/usr/lib/i386-linux-gnu/libz.so")
set(OPENSSL_SSL_LIBRARY "/usr/lib/i386-linux-gnu/libssl.so")
set(OPENSSL_CRYPTO_LIBRARY "/usr/lib/i386-linux-gnu/libcrypto.so")

# Qt5 32-bit support (if available)
set(Qt5_DIR "/usr/lib/i386-linux-gnu/cmake/Qt5")
set(Qt5Core_DIR "/usr/lib/i386-linux-gnu/cmake/Qt5Core")
set(Qt5Widgets_DIR "/usr/lib/i386-linux-gnu/cmake/Qt5Widgets")
set(Qt5Gui_DIR "/usr/lib/i386-linux-gnu/cmake/Qt5Gui")

# Additional multilib configuration
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Ensure proper linking for 32-bit builds with AppImage portability
set(CMAKE_SKIP_BUILD_RPATH FALSE)
set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

# AppImage-specific RPATH configuration for portable execution
set(CMAKE_INSTALL_RPATH "\$ORIGIN/../lib:\$ORIGIN/lib:\$ORIGIN")
set(CMAKE_BUILD_RPATH "\$ORIGIN/../lib:\$ORIGIN/lib:\$ORIGIN")

# Ensure all binaries have executable permissions for AppImage
set(CMAKE_INSTALL_DEFAULT_PERMISSIONS
    OWNER_READ OWNER_WRITE OWNER_EXECUTE
    GROUP_READ GROUP_EXECUTE
    WORLD_READ WORLD_EXECUTE
)

message(STATUS "Multilib CMake toolchain configured for 32-bit builds")