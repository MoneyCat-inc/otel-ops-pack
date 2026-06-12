# PR #942 Migration - CMake Build Configuration
# ECRR: BossCat OEM | Executor: Cursor{Implementer}

cmake_minimum_required(VERSION 3.15)
project(viz-engine-projectm VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required packages
find_package(PkgConfig REQUIRED)

# Find X11 (for GLX)
find_package(X11 REQUIRED)
if(NOT X11_FOUND)
    message(FATAL_ERROR "X11 not found - required for GLX context creation")
endif()

# Find OpenGL
find_package(OpenGL REQUIRED)
if(NOT OpenGL_FOUND)
    message(FATAL_ERROR "OpenGL not found")
endif()

# Find projectM (after PR #942)
# NOTE: Adjust find path based on actual projectM installation
# After PR #942, projectM should be built with GLAD vendored
find_path(PROJECTM_INCLUDE_DIR
    NAMES projectM-4/projectM.h
    PATHS
        /usr/local/include
        /usr/include
        ${CMAKE_SOURCE_DIR}/../projectm/include
)

find_library(PROJECTM_LIBRARY
    NAMES projectM libprojectM
    PATHS
        /usr/local/lib
        /usr/lib
        ${CMAKE_SOURCE_DIR}/../projectm/build/src/libprojectM
)

if(NOT PROJECTM_INCLUDE_DIR OR NOT PROJECTM_LIBRARY)
    message(WARNING "projectM not found - some targets will not build")
    message(STATUS "PROJECTM_INCLUDE_DIR: ${PROJECTM_INCLUDE_DIR}")
    message(STATUS "PROJECTM_LIBRARY: ${PROJECTM_LIBRARY}")
endif()

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${X11_INCLUDE_DIR}
    ${OPENGL_INCLUDE_DIR}
    ${PROJECTM_INCLUDE_DIR}
)

# GL Proc Resolver library
add_library(gl_proc_resolver STATIC
    gl_proc_resolver.cpp
    gl_proc_resolver.hpp
)

target_link_libraries(gl_proc_resolver
    PUBLIC
        ${X11_LIBRARIES}
        ${OPENGL_LIBRARIES}
)

# Optional: SDL2 support
find_package(SDL2 QUIET)
if(SDL2_FOUND)
    target_compile_definitions(gl_proc_resolver PRIVATE HAVE_SDL2)
    target_link_libraries(gl_proc_resolver PRIVATE SDL2::SDL2)
    message(STATUS "SDL2 found - SDL resolver available")
endif()

# Optional: EGL support
pkg_check_modules(EGL QUIET egl)
if(EGL_FOUND)
    target_compile_definitions(gl_proc_resolver PRIVATE HAVE_EGL)
    target_link_libraries(gl_proc_resolver PRIVATE ${EGL_LIBRARIES})
    target_include_directories(gl_proc_resolver PRIVATE ${EGL_INCLUDE_DIRS})
    message(STATUS "EGL found - EGL resolver available")
endif()

# projectM Renderer library
add_library(projectm_renderer STATIC
    projectm_renderer.cpp
    projectm_renderer.hpp
)

target_link_libraries(projectm_renderer
    PRIVATE
        gl_proc_resolver
        ${X11_LIBRARIES}
        ${OPENGL_LIBRARIES}
)

if(PROJECTM_INCLUDE_DIR AND PROJECTM_LIBRARY)
    target_link_libraries(projectm_renderer
        PRIVATE
            ${PROJECTM_LIBRARY}
    )
    message(STATUS "projectM library linked")
else()
    message(WARNING "projectM not found - projectm_renderer will not link")
endif()

# GL Diagnostics utility
add_executable(gl-diagnostics
    gl_diagnostics.cpp
)

target_link_libraries(gl-diagnostics
    PRIVATE
        gl_proc_resolver
        ${X11_LIBRARIES}
        ${OPENGL_LIBRARIES}
)

# Smoke test executable
add_executable(projectm-smoke-test
    projectm-smoke-test.cpp
)

target_link_libraries(projectm-smoke-test
    PRIVATE
        projectm_renderer
        gl_proc_resolver
        ${X11_LIBRARIES}
        ${OPENGL_LIBRARIES}
)

if(PROJECTM_INCLUDE_DIR AND PROJECTM_LIBRARY)
    target_link_libraries(projectm-smoke-test
        PRIVATE
            ${PROJECTM_LIBRARY}
    )
endif()

# Install targets
install(TARGETS projectm-smoke-test gl-diagnostics
    RUNTIME DESTINATION bin
)

# Print configuration summary
message(STATUS "")
message(STATUS "=== Configuration Summary ===")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C++ standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "X11: ${X11_FOUND}")
message(STATUS "OpenGL: ${OpenGL_FOUND}")
message(STATUS "projectM include: ${PROJECTM_INCLUDE_DIR}")
message(STATUS "projectM library: ${PROJECTM_LIBRARY}")
message(STATUS "SDL2: ${SDL2_FOUND}")
message(STATUS "EGL: ${EGL_FOUND}")
message(STATUS "=============================")
