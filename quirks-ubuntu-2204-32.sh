#!/bin/bash
# Quirks file for Ubuntu 22.04 (ubuntu-latest) - 32-bit build

git clone https://github.com/openssl/openssl.git -b openssl-3.2
pushd openssl
setarch i386 ./config -m32 --prefix=$PWD/../copenssl32 --openssldir=$PWD/../copenssl32/ssl
make install_sw
./config --prefix=$PWD/../copenssl64 --openssldir=$PWD/../copenssl64/ssl
make clean
make install_sw
export LD_LIBRARY_PATH=$PWD/../copenssl64/lib64:$PWD/../copenssl32/lib:${LD_LIBRARY_PATH}
popd
MCPELAUNCHER_CFLAGS32="-I ${PWD}/copenssl32/include -Wl,-L$PWD/copenssl32/lib $MCPELAUNCHER_CFLAGS32"
MCPELAUNCHER_CFLAGS="-stdlib=libc++ -I ${PWD}/copenssl64/include -Wl,-L$PWD/copenssl64/lib64 $MCPELAUNCHER_CFLAGS"
MCPELAUNCHER_CXXFLAGS32="-stdlib=libc++ $MCPELAUNCHER_CXXFLAGS32"
MCPELAUNCHER_CXXFLAGS="-stdlib=libc++ $MCPELAUNCHER_CXXFLAGS"
MCPELAUNCHERUI_CFLAGS="-I ${PWD}/copenssl64/include -Wl,-L$PWD/copenssl64/lib64 $MCPELAUNCHERUI_CFLAGS"

quirk_build_msa() {
  # Use system Qt5 for 32-bit
  add_cmake_options -DQT_RPATH=/usr/lib/i386-linux-gnu/
}

quirk_build_mcpelauncher() {
  # Note: 32-bit packages should already be installed in the main workflow step
  add_cmake_options -DZLIB_LIBRARY=/usr/lib/i386-linux-gnu/libz.so -DPNG_LIBRARY=/usr/lib/i386-linux-gnu/libpng.so -DPNG_PNG_INCLUDE_DIR=/usr/include/libpng -DX11_X11_LIB=/usr/lib/i386-linux-gnu/libX11.so -DCURL_LIBRARY=/usr/lib/i386-linux-gnu/libcurl.so "-DOPENSSL_SSL_LIBRARY=$PWD/copenssl32/lib/libssl.so" "-DOPENSSL_CRYPTO_LIBRARY=$PWD/copenssl32/lib/libcrypto.so" "-DOPENSSL_INCLUDE_DIR=$PWD/copenssl32/include"
}

quirk_build_mcpelauncher32() {
  add_cmake_options -DCMAKE_CXX_COMPILER_TARGET="i686-linux-gnu" -DBUILD_FAKE_JNI_TESTS=OFF -DBUILD_FAKE_JNI_EXAMPLES=OFF -DUSE_OWN_CURL=ON -DOPENSSL_ROOT_DIR=$PWD/copenssl32/ -DOPENSSL_LIBRARIES=$PWD/copenssl32/lib
}

quirk_build_mcpelauncher_ui() {
  # Use system Qt5 paths for 32-bit
  add_cmake_options -DCMAKE_INSTALL_RPATH="/usr/lib/i386-linux-gnu/:${APP_DIR}/usr/lib/" "-DOPENSSL_SSL_LIBRARY=$PWD/copenssl32/lib/libssl.so" "-DOPENSSL_CRYPTO_LIBRARY=$PWD/copenssl32/lib/libcrypto.so" "-DOPENSSL_INCLUDE_DIR=$PWD/copenssl32/include"
}