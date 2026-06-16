cmake_minimum_required(VERSION 3.22)
project(audioapp_engine VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

option(AUDIOAPP_BUILD_TESTS "Build engine unit tests" ON)

include(FetchContent)
FetchContent_Declare(
  JUCE
  GIT_REPOSITORY https://github.com/juce-framework/JUCE.git
  GIT_TAG        8.0.4
  GIT_SHALLOW    TRUE
)
FetchContent_MakeAvailable(JUCE)

add_library(audioapp_engine STATIC
  src/EngineHost.cpp
  src/TestOscillator.cpp
)

target_include_directories(audioapp_engine
  PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(audioapp_engine
  PUBLIC
    juce::juce_audio_basics
    juce::juce_audio_devices
    juce::juce_audio_processors
    juce::juce_core
    juce::juce_events
)

target_compile_definitions(audioapp_engine
  PUBLIC
    JUCE_WEB_BROWSER=0
    JUCE_USE_CURL=0
    JUCE_DISPLAY_SPLASH_SCREEN=0
)

if(AUDIOAPP_BUILD_TESTS)
  enable_testing()
  add_executable(audioapp_engine_tests
    tests/engine_smoke_test.cpp
  )
  target_link_libraries(audioapp_engine_tests PRIVATE audioapp_engine)
  add_test(NAME engine_smoke COMMAND audioapp_engine_tests)
endif()
