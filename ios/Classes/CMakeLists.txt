# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(native_minilzo_library VERSION 0.0.1 LANGUAGES C)

include_directories(include)

#target_include_directories(native_minilzo_library PUBLIC
#  ${PROJECT_SOURCE_DIR}/include
#)

add_library(native_minilzo SHARED
  "native_minilzo.c"
  "minilzo.c"
)

set_target_properties(native_minilzo PROPERTIES
  PUBLIC_HEADER native_minilzo.h
  OUTPUT_NAME "native_minilzo"
)

target_compile_definitions(native_minilzo PUBLIC DART_SHARED_LIB)
