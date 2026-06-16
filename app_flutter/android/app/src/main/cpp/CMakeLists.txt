cmake_minimum_required(VERSION 3.22.1)
project(audioapp_native LANGUAGES CXX C)

set(AUDIOAPP_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../../")

set(AUDIOAPP_BUILD_TESTS OFF CACHE BOOL "" FORCE)
add_subdirectory("${AUDIOAPP_ROOT}/engine_juce" "${CMAKE_BINARY_DIR}/audioapp_engine")

add_library(audioapp_native SHARED
    jni_bridge.cpp
    "${AUDIOAPP_ROOT}/native_bridge/src/BridgeHost.cpp"
)

target_include_directories(audioapp_native PRIVATE
    "${AUDIOAPP_ROOT}/native_bridge/include"
    "${AUDIOAPP_ROOT}/engine_juce/include"
)

find_library(log-lib log)

target_link_libraries(audioapp_native PRIVATE
    audioapp_engine
    ${log-lib}
)
