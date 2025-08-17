#!/bin/bash

source common.sh

QUIRKS_FILE=
APP_DIR=${BUILD_DIR}/AppDir
UPDATE_CMAKE_OPTIONS=""
BUILD_NUM="0"
TARGETARCH="x86_64"
TAGNAME=""
EXTRA_CMAKE_FLAGS=()
GLIBC_COMPAT=""

# Read a commit pin (Qt6 only)
get_commit_pin() {
    local base="$1"
    local plain="${base}.commit"
    if [[ -f "${plain}" ]]; then
        tr -d '\n\r' < "${plain}"
        return 0
    fi
    echo "ERROR: Missing commit pin file: ${plain}" >&2
    exit 2
}

while getopts "h?q:j:u:i:k:s?r:l:g?" opt; do
    case "$opt" in
    h|\?)
        echo "build.sh - Qt6 x86_64 AppImage Builder"
        echo "-j  Specify the number of jobs (the -j arg to make)"
        echo "-q  Specify the quirks file (default: quirks-qt6.sh)"
        echo "-u  Specify the update check URL"
        echo "-i  Specify the build id for update checking"
        echo "-k  Specify appimageupdate information"
        echo "-s  Skip sync sources"
        echo "-r  TAGNAME of the release"
        echo "-l  extracmakeflags for launcher"
        echo "-g  Enable GLIBC compatibility mode (_GLIBCXX_USE_CXX11_ABI=0)"
        exit 0
        ;;
    j)  MAKE_JOBS=$OPTARG
        ;;
    q)  QUIRKS_FILE=$OPTARG
        ;;
    u)  UPDATE_CMAKE_OPTIONS="$UPDATE_CMAKE_OPTIONS -DENABLE_UPDATE_CHECK=ON -DUPDATE_CHECK_URL=$OPTARG"
        ;;
    i)  UPDATE_CMAKE_OPTIONS="$UPDATE_CMAKE_OPTIONS -DUPDATE_CHECK_BUILD_ID=$OPTARG"
        BUILD_NUM="${OPTARG}"
        ;;
    k)  UPDATE_CMAKE_OPTIONS="$UPDATE_CMAKE_OPTIONS -DENABLE_APPIMAGE_UPDATE_CHECK=1"
        export UPDATE_INFORMATION="$OPTARG"
        ;;
    s)  SKIP_SOURCES="1"
        ;;
    r)  TAGNAME="$OPTARG"
        ;;
    l)  EXTRA_CMAKE_FLAGS+=("$OPTARG")
        ;;
    g)  GLIBC_COMPAT="1"
        ;;
    esac
done

if [ -z "${TAGNAME}" ]
then
    TAGNAME="$(cat version.txt)-${BUILD_NUM}"
fi

DEFAULT_CMAKE_OPTIONS=()
add_default_cmake_options() {
  DEFAULT_CMAKE_OPTIONS=("${DEFAULT_CMAKE_OPTIONS[@]}" "$@")
}

# Qt6 x86_64 compiler flags
CFLAGS="-DNDEBUG -fPIC -O2 $CFLAGS"
CXXFLAGS="-I ${PWD}/curlappimageca -std=c++17 -fPIC -O2 $CXXFLAGS"

# Add GLIBC compatibility mode if requested
if [ -n "$GLIBC_COMPAT" ]; then
    show_status "Enabling GLIBC compatibility mode (_GLIBCXX_USE_CXX11_ABI=0)"
    CXXFLAGS="-D_GLIBCXX_USE_CXX11_ABI=0 $CXXFLAGS"
    export _GLIBCXX_USE_CXX11_ABI=0
fi

MCPELAUNCHERUI_CXXFLAGS="-DLAUNCHER_INIT_PATCH=\"if(!getenv(\\\"QTWEBENGINE_CHROMIUM_FLAGS\\\")) putenv(\\\"QTWEBENGINE_CHROMIUM_FLAGS=--no-sandbox\\\");\""
# Set x86_64 target architecture (Qt6 only)
DEBIANTARGET="x86_64-linux-gnu" 
APPIMAGE_ARCH="x86_64"
APPIMAGE_RUNTIME_FILE="runtime-x86_64"
LINUXDEPLOY_ARCH="x86_64"
add_default_cmake_options -DCMAKE_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu;/usr/lib64;/lib64" -DCMAKE_INCLUDE_PATH="/usr/include/x86_64-linux-gnu"
# Ensure PKG_CONFIG_PATH includes multiarch paths
export PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig:/usr/lib/pkgconfig:$PKG_CONFIG_PATH"

# Skip tool downloads in DRY_RUN_CONFIGURE mode for CI reliability
if [ -n "${DRY_RUN_CONFIGURE:-}" ]; then
  show_status "DRY_RUN_CONFIGURE: Skipping AppImage tool downloads"
else
  show_status "Downloading AppImage tools"
  mkdir -p tools
  pushd tools
  # download linuxdeploy and make it executable with retry logic
  download_with_retry() {
    local url="$1"
    local filename="$(basename "$url")"
    for i in {1..3}; do
      if wget -N "$url"; then
        return 0
      fi
      echo "Download attempt $i failed for $filename, retrying in 10 seconds..."
      sleep 10
    done
    echo "Failed to download $filename after 3 attempts"
    return 1
  }

  check_run download_with_retry "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-$LINUXDEPLOY_ARCH.AppImage"
  # also download Qt plugin, which is needed for the Qt UI
  check_run download_with_retry "https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-$LINUXDEPLOY_ARCH.AppImage"
  # Needed to cross compile AppImages for ARM and ARM64
  check_run download_with_retry "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
  # Custom Runtime File for AppImage creation
  check_run download_with_retry "https://github.com/AppImage/AppImageKit/releases/download/continuous/$APPIMAGE_RUNTIME_FILE"
  popd
fi

# Set default quirks file to Qt6
if [ -z "$QUIRKS_FILE" ]; then
    QUIRKS_FILE="quirks-qt6.sh"
fi

load_quirks "$QUIRKS_FILE"

create_build_directories
check_system_resources
rm -rf ${APP_DIR}
mkdir -p ${APP_DIR}

# Enable strict plugin validation for Qt6 builds to fail fast on missing plugins
export STRICT_PLUGIN_VALIDATION=true
show_status "Enabling strict plugin validation for Qt6 build"

call_quirk init

if [ -z "$SKIP_SOURCES" ]
then
    show_status "Downloading sources"
    download_repo mcpelauncher https://github.com/minecraft-linux/mcpelauncher-manifest.git "$(get_commit_pin mcpelauncher)"
    download_repo mcpelauncher-ui https://github.com/minecraft-linux/mcpelauncher-ui-manifest.git "$(get_commit_pin mcpelauncher-ui)"
fi
download_repo versionsdb https://github.com/minecraft-linux/mcpelauncher-versiondb.git $(cat versionsdb.txt)
if [ -n "$UPDATE_INFORMATION" ]
then
    # Checkout lib outside of the source tree, to avoid redownloading the repository after mcpelauncher-ui source update
    download_repo "AppImageUpdate" https://github.com/AppImage/AppImageUpdate 1b97acc55c89f742d51c3849eb62eb58464d8669
    mkdir -p "$SOURCE_DIR/mcpelauncher-ui/lib"
    rm "$SOURCE_DIR/mcpelauncher-ui/lib/AppImageUpdate"
    ln -s "$SOURCE_DIR/AppImageUpdate" "$SOURCE_DIR/mcpelauncher-ui/lib/AppImageUpdate"
fi
call_quirk build_start

install_component() {
  # No-op for dry-run configuration mode
  if [ -n "${DRY_RUN_CONFIGURE:-}" ]; then
    show_status "DRY_RUN_CONFIGURE: Skipping installation for $1"
    return 0
  fi
  
  pushd "$BUILD_DIR/$1"
  # Use appropriate build tool based on generator
  if [ -f "build.ninja" ]; then
    # For ninja, DESTDIR is set as environment variable
    DESTDIR="${APP_DIR}" check_run ninja install
  else
    check_run make install DESTDIR="${APP_DIR}"
  fi
  popd
}



build_component64() {
  show_status "Building $1 (64-bit)"
  mkdir -p $BUILD_DIR/$1
  pushd $BUILD_DIR/$1
  
  # Check available memory before building
  available_mem=$(free | grep "Mem:" | awk '{print $7}')
  if [ "$available_mem" -lt 1048576 ]; then # Less than 1GB
    show_status "Warning: Low memory detected ($available_mem KB), reducing parallel jobs"
    local jobs=$((MAKE_JOBS / 2))
    [ "$jobs" -lt 1 ] && jobs=1
  else
    local jobs=$MAKE_JOBS
  fi
  
  echo "cmake" "${CMAKE_OPTIONS[@]}" "$SOURCE_DIR/$1"
  
  # CMake configuration with timeout
  timeout 600 cmake "${CMAKE_OPTIONS[@]}" "$SOURCE_DIR/$1" || {
    echo "CMake configuration timed out or failed for $1"
    popd
    return 1
  }
  
  # Early return for dry-run configuration mode
  if [ -n "${DRY_RUN_CONFIGURE:-}" ]; then
    show_status "DRY_RUN_CONFIGURE: CMake configuration completed for $1 (64-bit), skipping build"
    popd
    return 0
  fi
  
  # Fix library paths
  sed -i "s/\/usr\/lib\/x86_64-linux-gnu/\/usr\/lib\/$DEBIANTARGET/g" CMakeCache.txt
  sed -i "s/\/usr\/include\/x86_64-linux-gnu/\/usr\/include\/$DEBIANTARGET/g" CMakeCache.txt
  
  # Build with timeout and memory monitoring
  if [ -f "build.ninja" ]; then
    timeout 1800 ninja -j${jobs} || {
      echo "Build timed out or failed for $1, trying with single job"
      timeout 3600 ninja -j1 || {
        echo "Build failed for $1 even with single job"
        popd
        return 1
      }
    }
  else
    timeout 1800 make -j${jobs} || {
      echo "Build timed out or failed for $1, trying with single job"
      timeout 3600 make -j1 || {
        echo "Build failed for $1 even with single job"
        popd
        return 1
      }
    }
  fi
  
  popd
}


reset_cmake_options
add_cmake_options "${DEFAULT_CMAKE_OPTIONS[@]}" -DCMAKE_ASM_FLAGS="$MCPELAUNCHER_CFLAGS $CFLAGS" -DCMAKE_C_FLAGS="$MCPELAUNCHER_CFLAGS $CFLAGS" -DCMAKE_CXX_FLAGS="$MCPELAUNCHER_CXXFLAGS $MCPELAUNCHER_CFLAGS $CXXFLAGS $CFLAGS"
add_cmake_options -DCMAKE_INSTALL_PREFIX=/usr -DENABLE_QT_ERROR_UI=OFF
# Add modern build flags for better compatibility
add_cmake_options -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_BUILD_TYPE=Release
add_cmake_options -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH
add_cmake_options "${EXTRA_CMAKE_FLAGS[@]}"
call_quirk build_mcpelauncher
build_component64 mcpelauncher
install_component mcpelauncher
reset_cmake_options
add_cmake_options "${DEFAULT_CMAKE_OPTIONS[@]}" -DCMAKE_ASM_FLAGS="$MCPELAUNCHERUI_CFLAGS $CFLAGS" -DCMAKE_C_FLAGS="$MCPELAUNCHERUI_CFLAGS $CFLAGS" -DCMAKE_CXX_FLAGS="$MCPELAUNCHERUI_CXXFLAGS $MCPELAUNCHERUI_CFLAGS $CXXFLAGS $CFLAGS"
add_cmake_options -DCMAKE_INSTALL_PREFIX=/usr -DGAME_LAUNCHER_PATH=. -DLAUNCHER_VERSION_NAME="$(cat version.txt).${BUILD_NUM}-AppImage-$TARGETARCH" -DLAUNCHER_VERSION_CODE="${BUILD_NUM}" -DLAUNCHER_CHANGE_LOG="Launcher $(cat version.txt)<br/>$(cat changelog.txt)" -DQt5QuickCompiler_FOUND:BOOL=OFF -DLAUNCHER_ENABLE_GOOGLE_PLAY_LICENCE_CHECK=ON -DLAUNCHER_DISABLE_DEV_MODE=ON -DLAUNCHER_VERSIONDB_URL=https://raw.githubusercontent.com/minecraft-linux/mcpelauncher-versiondb/$(cat versionsdbremote.txt) -DLAUNCHER_VERSIONDB_PATH="$SOURCE_DIR/versionsdb" $UPDATE_CMAKE_OPTIONS
# Add modern build flags for UI component
add_cmake_options -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_BUILD_TYPE=Release
add_cmake_options -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH
call_quirk build_mcpelauncher_ui

build_component64 mcpelauncher-ui
install_component mcpelauncher-ui

# Copy Qt6 plugins to AppImage after UI installation
call_quirk copy_qt6_plugins

# Early exit for dry-run configuration mode
if [ -n "${DRY_RUN_CONFIGURE:-}" ]; then
  show_status "DRY_RUN_CONFIGURE: CMake configuration completed for all components, skipping packaging"
  exit 0
fi

show_status "Packaging"

cp "$SOURCE_DIR/mcpelauncher-ui/mcpelauncher-ui-qt/Resources/mcpelauncher-icon.svg" "$BUILD_DIR/mcpelauncher-ui-qt.svg"
cp "$SOURCE_DIR/mcpelauncher-ui/mcpelauncher-ui-qt/mcpelauncher-ui-qt.desktop" "$BUILD_DIR/mcpelauncher-ui-qt.desktop"

chmod +x tools/linuxdeploy-*.AppImage
chmod +x tools/appimagetool-*.AppImage


export ARCH=$APPIMAGE_ARCH

fixarm() {
    if [ "$TARGETARCH" = "armhf" ] || [ "$TARGETARCH" = "arm64" ]
    then
        # fix arm
        rm -rf squashfs-root/usr/bin/strip squashfs-root/usr/bin/patchelf
        echo '#!/bin/bash' > squashfs-root/usr/bin/patchelf
        chmod +x squashfs-root/usr/bin/patchelf
        echo '#!/bin/bash' > squashfs-root/usr/bin/strip
        chmod +x squashfs-root/usr/bin/strip
    fi
}

mkdir linuxdeploy-$LINUXDEPLOY_ARCH
cd linuxdeploy-$LINUXDEPLOY_ARCH
../tools/linuxdeploy-$LINUXDEPLOY_ARCH.AppImage --appimage-extract
fixarm
cd ..
mkdir linuxdeploy-plugin-qt-$LINUXDEPLOY_ARCH
cd linuxdeploy-plugin-qt-$LINUXDEPLOY_ARCH
../tools/linuxdeploy-plugin-qt-$LINUXDEPLOY_ARCH.AppImage --appimage-extract
fixarm
cd ..
mkdir appimagetool
cd appimagetool
../tools/appimagetool-x86_64.AppImage --appimage-extract
cd ..
LINUXDEPLOY_BIN="linuxdeploy-$LINUXDEPLOY_ARCH/squashfs-root/AppRun"
LINUXDEPLOY_PLUGIN_QT_BIN="linuxdeploy-plugin-qt-$LINUXDEPLOY_ARCH/squashfs-root/AppRun"
APPIMAGETOOL_BIN="appimagetool/squashfs-root/AppRun"

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH+"${LD_LIBRARY_PATH}:"}"$APP_DIR/usr/lib"
check_run "$LINUXDEPLOY_BIN" --appdir "$APP_DIR" -i "$BUILD_DIR/mcpelauncher-ui-qt.svg" -d "$BUILD_DIR/mcpelauncher-ui-qt.desktop"

export QML_SOURCES_PATHS="$SOURCE_DIR/mcpelauncher-ui/mcpelauncher-ui-qt/qml/:$SOURCE_DIR/mcpelauncher/mcpelauncher-webview"
# Qt6 plugins are now comprehensively copied by quirk_copy_qt6_plugins function
show_status "Qt6 plugins already copied by quirks system - proceeding with linuxdeploy"
export EXTRA_PLATFORM_PLUGINS="libqwayland-egl.so;libqwayland-generic.so"
export EXTRA_QT_PLUGINS="wayland-decoration-client;wayland-graphics-integration-client;wayland-shell-integration"
check_run "$LINUXDEPLOY_PLUGIN_QT_BIN" --appdir "$APP_DIR"

# libnss needs to be included for google login support
# Ubuntu 24.04 doesn't have the nss subdirectory, so copy individual files
if [ -d "/usr/lib/$DEBIANTARGET/nss" ]; then
    # Old path: libnss needs it's subdirectory to load the google login view
    check_run cp -r "/usr/lib/$DEBIANTARGET/nss" "$APP_DIR/usr/lib/"
else
    # Modern path: libnss needs to be fully cloned for google login (Ubuntu 24.04+)
    check_run cp "/usr/lib/$DEBIANTARGET/libfreebl3.chk" "/usr/lib/$DEBIANTARGET/libfreebl3.so" "/usr/lib/$DEBIANTARGET/libfreeblpriv3.chk" "/usr/lib/$DEBIANTARGET/libfreeblpriv3.so" "/usr/lib/$DEBIANTARGET/libnss3.so" "/usr/lib/$DEBIANTARGET/libnssckbi.so" "/usr/lib/$DEBIANTARGET/libnssdbm3.chk" "/usr/lib/$DEBIANTARGET/libnssdbm3.so" "/usr/lib/$DEBIANTARGET/libnssutil3.so" "/usr/lib/$DEBIANTARGET/libsmime3.so" "/usr/lib/$DEBIANTARGET/libsoftokn3.chk" "/usr/lib/$DEBIANTARGET/libsoftokn3.so" "/usr/lib/$DEBIANTARGET/libssl3.so" "$APP_DIR/usr/lib/"
fi
# glib is excluded by appimagekit, but gmodule isn't which causes issues
check_run rm -rf "$APP_DIR/usr/lib/libgmodule-2.0.so.0"
# these files where removed from the exclude list
check_run rm -rf "$APP_DIR/usr/lib/libgio-2.0.so.0"
check_run rm -rf "$APP_DIR/usr/lib/libglib-2.0.so.0"
check_run rm -rf "$APP_DIR/usr/lib/libgobject-2.0.so.0"

# Download CA certificates with retry logic
download_cacert() {
  local output_file="$APP_DIR/usr/share/mcpelauncher/cacert.pem"
  mkdir -p "$(dirname "$output_file")"
  
  for i in {1..3}; do
    if curl -L -k --connect-timeout 30 --max-time 120 https://curl.se/ca/cacert.pem --output "$output_file"; then
      echo "Successfully downloaded CA certificates"
      return 0
    fi
    echo "Attempt $i failed to download CA certificates, retrying in 10 seconds..."
    sleep 10
  done
  
  echo "Failed to download CA certificates after 3 attempts, trying alternative source..."
  # Try alternative source
  if curl -L -k --connect-timeout 30 --max-time 120 https://raw.githubusercontent.com/bagder/ca-bundle/master/ca-bundle.crt --output "$output_file"; then
    echo "Successfully downloaded CA certificates from alternative source"
    return 0
  fi
  
  echo "ERROR: Failed to download CA certificates from all sources"
  return 1
}

check_run download_cacert

if [ "$TARGETARCH" = "armhf" ] || [ "$TARGETARCH" = "arm64" ]
then
   check_run rm $APP_DIR/AppRun
   check_run cp ./AppRun $APP_DIR/AppRun
   check_run chmod +x $APP_DIR/AppRun
fi

export OUTPUT="Minecraft_Bedrock_Launcher${OUTPUT_SUFFIX}-${TARGETARCH}-$(cat version.txt).${BUILD_NUM}.AppImage"
export ARCH="$APPIMAGE_ARCH"
if [ -n "$UPDATE_INFORMATION" ]
then
    UPDATE_INFORMATION_ARGS=("-u" "${UPDATE_INFORMATION}")
fi
check_run "$APPIMAGETOOL_BIN" --comp xz --runtime-file "tools/$APPIMAGE_RUNTIME_FILE" "${UPDATE_INFORMATION_ARGS[@]:-}" "$APP_DIR" "$OUTPUT"

# Move AppImage and zsync files to output directory (created by create_build_directories)
check_run mv Minecraft*.AppImage "$OUTPUT_DIR"/

# Verify that AppImages were successfully created and moved
if [ -z "$(find "$OUTPUT_DIR" -name "*.AppImage" 2>/dev/null)" ]; then
    echo "ERROR: No AppImage files found in output directory after build"
    echo "Build appears to have completed, but no AppImage was produced"
    echo "Check build logs for errors in AppImage creation process"
    echo "Output directory contents:"
    ls -la "$OUTPUT_DIR" || echo "Output directory is empty or doesn't exist"
    exit 1
fi

echo "SUCCESS: AppImage(s) created and moved to output directory:"
ls -la "$OUTPUT_DIR"/*.AppImage
if [ "${TAGNAME}" = "-" ]
then
    cat *.zsync > "$OUTPUT_DIR/version${OUTPUT_SUFFIX}.${ARCH}.zsync"
    cat *.zsync > "$OUTPUT_DIR/version${OUTPUT_SUFFIX}.${TARGETARCH}.zsync"
else
    cat *.zsync | sed -e "s/\(URL: \)\(.*\)/\1..\/${TAGNAME}\/\2/g" > "$OUTPUT_DIR/version${OUTPUT_SUFFIX}.${ARCH}.zsync"
    cat *.zsync | sed -e "s/\(URL: \)\(.*\)/\1..\/${TAGNAME}\/\2/g" > "$OUTPUT_DIR/version${OUTPUT_SUFFIX}.${TARGETARCH}.zsync"
fi
rm *.zsync

cleanup_build
