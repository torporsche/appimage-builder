quirk_build_msa() {
  # Only configure MSA if not disabled
  if [ -z "$DISABLE_MSA" ]; then
    add_cmake_options "-DCURL_LIBRARY=/usr/lib/${DEBIANTARGET}/libcurl.so" "-DQt6_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt6" "-DQt6GuiTools_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt6GuiTools" "-DOPENGL_opengl_LIBRARY=/usr/lib/${DEBIANTARGET}/libOpenGL.so"
    # Add modern compiler flags for better compatibility
    add_cmake_options "-DCMAKE_CXX_STANDARD=17" "-DCMAKE_C_STANDARD=11"
    # Ensure proper Qt6 WebEngine support
    add_cmake_options "-DQt6WebEngineCore_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt6WebEngineCore" "-DQt6WebEngineWidgets_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt6WebEngineWidgets"
  else
    show_status "MSA disabled, skipping MSA build configuration"
  fi
}
quirk_build_mcpelauncher() {
  add_cmake_options "-DQt6_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt6" "-DQt6GuiTools_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt6GuiTools" "-DOPENGL_opengl_LIBRARY=/usr/lib/${DEBIANTARGET}/libOpenGL.so"
  # Add modern compiler flags
  add_cmake_options "-DCMAKE_CXX_STANDARD=17" "-DCMAKE_C_STANDARD=11"
  # Improve library detection
  add_cmake_options "-DCMAKE_PREFIX_PATH=/usr/lib/${DEBIANTARGET}/cmake"
}
quirk_build_mcpelauncher_ui() {
  add_cmake_options "-DCURL_LIBRARY=/usr/lib/${DEBIANTARGET}/libcurl.so" "-DQt6_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt6" "-DQt6GuiTools_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt6GuiTools" "-DOPENGL_opengl_LIBRARY=/usr/lib/${DEBIANTARGET}/libOpenGL.so" "-DOPENGL_glx_LIBRARY="
  # Add modern compiler flags and WebEngine support
  add_cmake_options "-DCMAKE_CXX_STANDARD=17" "-DCMAKE_C_STANDARD=11"
  add_cmake_options "-DQt6WebEngineCore_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt6WebEngineCore" "-DQt6WebEngineWidgets_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt6WebEngineWidgets"
  add_cmake_options "-DQt6WebEngineQuick_DIR=/usr/lib/${DEBIANTARGET}/cmake/Qt6WebEngineQuick"
  # Ensure proper library paths
  add_cmake_options "-DCMAKE_PREFIX_PATH=/usr/lib/${DEBIANTARGET}/cmake"
}

