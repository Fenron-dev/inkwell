cmake_minimum_required(VERSION 3.14)
project(speech_to_text_windows_plugin CXX)

set(PLUGIN_NAME "speech_to_text_windows_plugin")

add_library(${PLUGIN_NAME} STATIC
  "speech_to_text_windows_stub.cpp"
)

apply_standard_settings(${PLUGIN_NAME})

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
)

set(speech_to_text_windows_bundled_libraries "" PARENT_SCOPE)
