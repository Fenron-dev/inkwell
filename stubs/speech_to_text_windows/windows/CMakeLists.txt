cmake_minimum_required(VERSION 3.14)
project(speech_to_text_windows_plugin CXX)

set(PLUGIN_NAME "speech_to_text_windows_plugin")

# Build as SHARED (DLL) to match the standard Flutter Windows plugin pattern.
# A STATIC lib does not propagate INTERFACE include dirs correctly to the runner
# and causes __declspec(dllimport) mismatches in generated_plugin_registrant.cc.
add_library(${PLUGIN_NAME} SHARED
  "speech_to_text_windows_stub.cpp"
)

apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)

# FLUTTER_PLUGIN_IMPL switches the header to __declspec(dllexport).
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
)

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

set(speech_to_text_windows_bundled_libraries "" PARENT_SCOPE)
