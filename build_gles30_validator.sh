#!/bin/bash
# OpenGL ES 3.0 Detection and Validation Script
# Creates a validator for GLES 3.0 support with software rendering fallback

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${BUILD_DIR:-/tmp/gles30_validator}"
VALIDATOR_NAME="gles30_validator"

# Colors for output
COLOR_SUCCESS="\033[32m"
COLOR_WARNING="\033[33m"
COLOR_ERROR="\033[31m"
COLOR_INFO="\033[36m"
COLOR_RESET="\033[0m"

show_status() {
    echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} $1"
}

show_success() {
    echo -e "${COLOR_SUCCESS}[SUCCESS]${COLOR_RESET} $1"
}

show_warning() {
    echo -e "${COLOR_WARNING}[WARNING]${COLOR_RESET} $1"
}

show_error() {
    echo -e "${COLOR_ERROR}[ERROR]${COLOR_RESET} $1"
}

# Create GLES 3.0 test program
create_gles30_test() {
    show_status "Creating OpenGL ES 3.0 test program"
    
    mkdir -p "$BUILD_DIR"
    
    # Create C++ test program
    cat > "$BUILD_DIR/gles30_test.cpp" << 'EOF'
#include <iostream>
#include <cstring>
#include <dlfcn.h>

#ifdef __linux__
#include <EGL/egl.h>
#include <GLES3/gl3.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#endif

class GLES30Validator {
private:
    Display* display;
    EGLDisplay egl_display;
    EGLContext egl_context;
    EGLSurface egl_surface;
    bool initialized;
    
public:
    GLES30Validator() : display(nullptr), egl_display(EGL_NO_DISPLAY), 
                        egl_context(EGL_NO_CONTEXT), egl_surface(EGL_NO_SURFACE),
                        initialized(false) {}
    
    ~GLES30Validator() {
        cleanup();
    }
    
    bool initialize() {
        // Try to open X11 display
        display = XOpenDisplay(nullptr);
        if (!display) {
            std::cerr << "Failed to open X11 display" << std::endl;
            return false;
        }
        
        // Get EGL display
        egl_display = eglGetDisplay((EGLNativeDisplayType)display);
        if (egl_display == EGL_NO_DISPLAY) {
            std::cerr << "Failed to get EGL display" << std::endl;
            return false;
        }
        
        // Initialize EGL
        EGLint major, minor;
        if (!eglInitialize(egl_display, &major, &minor)) {
            std::cerr << "Failed to initialize EGL" << std::endl;
            return false;
        }
        
        std::cout << "EGL Version: " << major << "." << minor << std::endl;
        
        // Configure EGL for OpenGL ES 3.0
        EGLint config_attribs[] = {
            EGL_SURFACE_TYPE, EGL_PBUFFER_BIT,
            EGL_BLUE_SIZE, 8,
            EGL_GREEN_SIZE, 8,
            EGL_RED_SIZE, 8,
            EGL_ALPHA_SIZE, 8,
            EGL_DEPTH_SIZE, 24,
            EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT,
            EGL_NONE
        };
        
        EGLConfig config;
        EGLint num_configs;
        if (!eglChooseConfig(egl_display, config_attribs, &config, 1, &num_configs)) {
            std::cerr << "Failed to choose EGL config" << std::endl;
            return false;
        }
        
        // Create context for OpenGL ES 3.0
        EGLint context_attribs[] = {
            EGL_CONTEXT_CLIENT_VERSION, 3,
            EGL_NONE
        };
        
        egl_context = eglCreateContext(egl_display, config, EGL_NO_CONTEXT, context_attribs);
        if (egl_context == EGL_NO_CONTEXT) {
            std::cerr << "Failed to create OpenGL ES 3.0 context" << std::endl;
            return false;
        }
        
        // Create pbuffer surface
        EGLint pbuffer_attribs[] = {
            EGL_WIDTH, 1,
            EGL_HEIGHT, 1,
            EGL_NONE
        };
        
        egl_surface = eglCreatePbufferSurface(egl_display, config, pbuffer_attribs);
        if (egl_surface == EGL_NO_SURFACE) {
            std::cerr << "Failed to create EGL surface" << std::endl;
            return false;
        }
        
        // Make context current
        if (!eglMakeCurrent(egl_display, egl_surface, egl_surface, egl_context)) {
            std::cerr << "Failed to make context current" << std::endl;
            return false;
        }
        
        initialized = true;
        return true;
    }
    
    bool validateGLES30() {
        if (!initialized) {
            std::cerr << "Validator not initialized" << std::endl;
            return false;
        }
        
        // Check OpenGL ES version
        const char* version = (const char*)glGetString(GL_VERSION);
        const char* vendor = (const char*)glGetString(GL_VENDOR);
        const char* renderer = (const char*)glGetString(GL_RENDERER);
        const char* shading_version = (const char*)glGetString(GL_SHADING_LANGUAGE_VERSION);
        
        std::cout << "OpenGL Version: " << version << std::endl;
        std::cout << "Vendor: " << vendor << std::endl;
        std::cout << "Renderer: " << renderer << std::endl;
        std::cout << "Shading Language Version: " << shading_version << std::endl;
        
        // Check if version is at least 3.0
        if (!version || strncmp(version, "OpenGL ES 3.", 12) != 0) {
            if (!version || strncmp(version, "OpenGL ES 2.", 12) == 0) {
                std::cerr << "Only OpenGL ES 2.0 available, GLES 3.0 required" << std::endl;
            } else {
                std::cerr << "OpenGL ES 3.0 not supported" << std::endl;
            }
            return false;
        }
        
        // Test basic GLES 3.0 functionality
        GLuint vao;
        glGenVertexArrays(1, &vao);
        if (glGetError() != GL_NO_ERROR) {
            std::cerr << "Vertex Array Objects not supported (GLES 3.0 feature)" << std::endl;
            return false;
        }
        glDeleteVertexArrays(1, &vao);
        
        // Check for transform feedback (GLES 3.0 feature)
        GLuint tf;
        glGenTransformFeedbacks(1, &tf);
        if (glGetError() != GL_NO_ERROR) {
            std::cerr << "Transform Feedback not supported (GLES 3.0 feature)" << std::endl;
            return false;
        }
        glDeleteTransformFeedbacks(1, &tf);
        
        std::cout << "OpenGL ES 3.0 validation successful!" << std::endl;
        return true;
    }
    
    void cleanup() {
        if (egl_context != EGL_NO_CONTEXT) {
            eglMakeCurrent(egl_display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
            eglDestroyContext(egl_display, egl_context);
            egl_context = EGL_NO_CONTEXT;
        }
        
        if (egl_surface != EGL_NO_SURFACE) {
            eglDestroySurface(egl_display, egl_surface);
            egl_surface = EGL_NO_SURFACE;
        }
        
        if (egl_display != EGL_NO_DISPLAY) {
            eglTerminate(egl_display);
            egl_display = EGL_NO_DISPLAY;
        }
        
        if (display) {
            XCloseDisplay(display);
            display = nullptr;
        }
        
        initialized = false;
    }
};

int main(int argc, char* argv[]) {
    bool software_fallback = false;
    bool verbose = false;
    
    // Parse command line arguments
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--software") == 0) {
            software_fallback = true;
        } else if (strcmp(argv[i], "--verbose") == 0) {
            verbose = true;
        } else if (strcmp(argv[i], "--help") == 0) {
            std::cout << "Usage: " << argv[0] << " [--software] [--verbose] [--help]" << std::endl;
            std::cout << "  --software: Force software rendering" << std::endl;
            std::cout << "  --verbose:  Enable verbose output" << std::endl;
            std::cout << "  --help:     Show this help message" << std::endl;
            return 0;
        }
    }
    
    if (software_fallback) {
        std::cout << "Forcing software rendering..." << std::endl;
        setenv("LIBGL_ALWAYS_SOFTWARE", "1", 1);
        setenv("MESA_GL_VERSION_OVERRIDE", "3.3", 1);
        setenv("MESA_GLES_VERSION_OVERRIDE", "3.0", 1);
    }
    
    GLES30Validator validator;
    
    std::cout << "Initializing OpenGL ES 3.0 validator..." << std::endl;
    
    if (!validator.initialize()) {
        std::cerr << "Failed to initialize GLES 3.0 validator" << std::endl;
        if (!software_fallback) {
            std::cout << "Retrying with software rendering..." << std::endl;
            setenv("LIBGL_ALWAYS_SOFTWARE", "1", 1);
            setenv("MESA_GL_VERSION_OVERRIDE", "3.3", 1);
            setenv("MESA_GLES_VERSION_OVERRIDE", "3.0", 1);
            
            GLES30Validator software_validator;
            if (!software_validator.initialize()) {
                std::cerr << "Software rendering fallback also failed" << std::endl;
                return 1;
            }
            
            if (!software_validator.validateGLES30()) {
                return 1;
            }
            
            std::cout << "OpenGL ES 3.0 validated successfully with software rendering!" << std::endl;
            return 0;
        }
        return 1;
    }
    
    if (!validator.validateGLES30()) {
        return 1;
    }
    
    return 0;
}
EOF
}

# Create CMakeLists.txt for the validator
create_cmake_config() {
    show_status "Creating CMake configuration"
    
    cat > "$BUILD_DIR/CMakeLists.txt" << 'EOF'
cmake_minimum_required(VERSION 3.16)
project(GLES30Validator)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required packages
find_package(PkgConfig REQUIRED)

# Find EGL and GLES
pkg_check_modules(EGL REQUIRED egl)
pkg_check_modules(GLES REQUIRED glesv2)

# Find X11
find_package(X11 REQUIRED)

# Create the validator executable
add_executable(gles30_validator gles30_test.cpp)

# Link libraries
target_link_libraries(gles30_validator
    ${EGL_LIBRARIES}
    ${GLES_LIBRARIES}
    ${X11_LIBRARIES}
    dl
)

# Include directories
target_include_directories(gles30_validator PRIVATE
    ${EGL_INCLUDE_DIRS}
    ${GLES_INCLUDE_DIRS}
    ${X11_INCLUDE_DIRS}
)

# Compiler flags
target_compile_options(gles30_validator PRIVATE
    ${EGL_CFLAGS_OTHER}
    ${GLES_CFLAGS_OTHER}
)
EOF
}

# Build the validator
build_validator() {
    show_status "Building OpenGL ES 3.0 validator"
    
    cd "$BUILD_DIR"
    
    # Try to build with CMake
    if command -v cmake >/dev/null 2>&1; then
        cmake -B build -S .
        if cmake --build build; then
            cp build/gles30_validator ./
            show_success "Validator built successfully with CMake"
            return 0
        else
            show_warning "CMake build failed, trying manual compilation"
        fi
    fi
    
    # Fallback to manual compilation
    show_status "Attempting manual compilation"
    
    if g++ -std=c++17 -o gles30_validator gles30_test.cpp \
        $(pkg-config --cflags --libs egl glesv2 x11) -ldl 2>/dev/null; then
        show_success "Validator built successfully with manual compilation"
        return 0
    else
        show_error "Failed to build validator"
        return 1
    fi
}

# Install the validator
install_validator() {
    local install_dir="${1:-/usr/local/bin}"
    
    show_status "Installing validator to $install_dir"
    
    if [ -f "$BUILD_DIR/gles30_validator" ]; then
        if [ -w "$install_dir" ] || [ "$EUID" -eq 0 ]; then
            cp "$BUILD_DIR/gles30_validator" "$install_dir/"
            chmod +x "$install_dir/gles30_validator"
            show_success "Validator installed to $install_dir/gles30_validator"
        else
            show_warning "No write permission to $install_dir, copying to current directory"
            cp "$BUILD_DIR/gles30_validator" ./
            show_success "Validator available as ./gles30_validator"
        fi
    else
        show_error "Validator binary not found"
        return 1
    fi
}

# Test the validator
test_validator() {
    local validator_path="$BUILD_DIR/gles30_validator"
    
    if [ ! -f "$validator_path" ]; then
        show_error "Validator not found at $validator_path"
        return 1
    fi
    
    show_status "Testing OpenGL ES 3.0 validator"
    
    # Test hardware rendering
    echo "=== Testing Hardware Rendering ==="
    if "$validator_path" --verbose; then
        show_success "Hardware OpenGL ES 3.0 support validated"
    else
        show_warning "Hardware rendering test failed"
        
        # Test software rendering
        echo "=== Testing Software Rendering Fallback ==="
        if "$validator_path" --software --verbose; then
            show_success "Software OpenGL ES 3.0 support validated"
        else
            show_error "Both hardware and software rendering failed"
            return 1
        fi
    fi
}

# Main function
main() {
    local action="${1:-build}"
    
    case "$action" in
        "build")
            create_gles30_test
            create_cmake_config
            build_validator
            ;;
        "install")
            install_validator "${2:-/usr/local/bin}"
            ;;
        "test")
            test_validator
            ;;
        "all")
            create_gles30_test
            create_cmake_config
            build_validator
            test_validator
            ;;
        "help"|"--help")
            echo "Usage: $0 [build|install|test|all|help]"
            echo ""
            echo "Actions:"
            echo "  build   - Build the GLES 3.0 validator"
            echo "  install - Install the validator to system"
            echo "  test    - Test the validator"
            echo "  all     - Build and test the validator"
            echo "  help    - Show this help message"
            echo ""
            echo "Environment variables:"
            echo "  BUILD_DIR - Directory to build in (default: /tmp/gles30_validator)"
            ;;
        *)
            show_error "Unknown action: $action"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"