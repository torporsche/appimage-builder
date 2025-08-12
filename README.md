Building debian packages, if you have all dependencies installed

[TODO] Add all dependencies here
- https://mcpelauncher.readthedocs.io/en/latest/source_build/msa.html#prerequirements (only needed if MSA is enabled)
- https://mcpelauncher.readthedocs.io/en/latest/source_build/launcher.html#prerequirements
- https://mcpelauncher.readthedocs.io/en/latest/source_build/ui.html
- `libssl-dev` (openssl 1.1.0 or newer)

[TODO] Fix mcpelauncher-client do not hardcode deb to i386

`CC=clang CXX=clang++ ./build.sh`

### Building without MSA (Simplified Build)

For modern Minecraft PE versions that don't require the Microsoft Account component:

`CC=clang CXX=clang++ ./build.sh -m -q quirks-modern.sh`

or for AppImage:

`./build_appimage.sh -t x86_64 -m -q quirks-modern.sh`

This disables the MSA (Microsoft Account) component, which simplifies the build process and removes dependencies that are only needed for very old versions of Minecraft PE.

### Can I play with an APK?

No, this allowed piracy that is forbidden in this project.

Any attempt to document workarounds or make it easy to import an paid apk without a valid google play game license is undesirable.

Game licenses can be revoked at any point of time by you, microsoft/mojang or google, as it happened for all residents of Russia.

Ignoring this policy may cause suspension including termination of this project like happended between 2022-2023.

_Exception to the rule are Minecraft Trial and Edu where the latter doesn't work at this time._

For the most current version of this rule see https://minecraft-linux.github.io/faq/index.html#can-i-play-with-an-apk
