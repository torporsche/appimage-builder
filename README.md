# AppImage Builder for mcpelauncher-linux

Clean, simplified AppImage builder focusing on x86_64 architecture with modern Ubuntu 22.04 base.

## Quick Start

This repository builds AppImages for the mcpelauncher-linux project using a simplified, single-architecture approach.

### Build Requirements
- Ubuntu 22.04 LTS (or compatible)
- Qt5 development libraries
- clang compiler
- Standard build tools

### Local Build
```bash
# Test your environment
./test-dependencies.sh

# Build AppImage (x86_64 only, MSA disabled, no 32-bit)
./build_appimage.sh -t x86_64 -m -n -j $(nproc) -q quirks-modern.sh
```

## Clean Restart Strategy

This repository implements a **clean restart strategy** that removes accumulated complexity from multiple LLM agent revisions:

- **Single Architecture**: x86_64 only, no multilib complexity
- **Single Workflow**: One GitHub Actions job instead of three  
- **Modern Base**: Ubuntu 22.04 LTS with Qt5
- **Components Disabled**: MSA and 32-bit builds disabled by default
- **Files Removed**: 10 architecture/platform-specific files cleaned up

## Build Configuration

### Default Build Flags
- `-t x86_64`: Target x86_64 architecture only
- `-m`: Disable MSA component builds  
- `-n`: Disable 32-bit mcpelauncher-client builds
- `-q quirks-modern.sh`: Use simplified build quirks

### Dependencies Installation (Ubuntu 22.04)
```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential cmake git curl wget file ninja-build clang lld pkg-config \
  libc6-dev libssl-dev libcurl4-openssl-dev zlib1g-dev libpng-dev \
  libuv1-dev libzip-dev libglib2.0-dev \
  qtbase5-dev qtbase5-dev-tools qttools5-dev qttools5-dev-tools qt5-qmake \
  libqt5svg5-dev qtwebengine5-dev qtwebengine5-dev-tools \
  libqt5webenginecore5 libqt5webenginewidgets5 qtdeclarative5-dev \
  qml-module-qtquick-controls2 qml-module-qtquick-layouts \
  qml-module-qtquick-window2 qml-module-qtquick-dialogs qml-module-qtwebengine \
  libgl1-mesa-dev libegl1-mesa-dev libgles2-mesa-dev \
  libx11-dev libxcursor-dev libxinerama-dev libxi-dev libxrandr-dev \
  libxtst6 libxss1 libasound2-dev libpulse-dev libudev-dev libevdev-dev libnss3-dev
```

## APK Policy

**This project does not support APK importing.** 

As stated in the [official FAQ](https://minecraft-linux.github.io/faq/index.html#can-i-play-with-an-apk), any attempt to document workarounds or make it easy to import paid APKs without valid Google Play game licenses is undesirable and may cause project suspension.

Valid alternatives:
- Minecraft Trial (supported)
- Minecraft Education (limited support)

Game licenses can be revoked at any time by Microsoft/Mojang or Google.

## Project Links

- [mcpelauncher Documentation](https://mcpelauncher.readthedocs.io/)
- [MSA Requirements](https://mcpelauncher.readthedocs.io/en/latest/source_build/msa.html#prerequirements) (disabled by default)
- [Launcher Requirements](https://mcpelauncher.readthedocs.io/en/latest/source_build/launcher.html#prerequirements)
- [UI Requirements](https://mcpelauncher.readthedocs.io/en/latest/source_build/ui.html)
