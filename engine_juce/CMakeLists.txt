cmake_minimum_required(VERSION 3.22)
project(audioapp_engine VERSION 0.1.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

option(AUDIOAPP_BUILD_TESTS "Build engine unit tests" ON)

set(JUCE_BUILD_HELPER_TOOLS OFF CACHE BOOL "" FORCE)
set(JUCE_BUILD_EXTRAS OFF CACHE BOOL "" FORCE)
set(JUCE_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
if(ANDROID)
  # Cross-compiling Android cannot bootstrap juceaide on all host toolchains; modules-only is enough for juce_core JSON.
  set(JUCE_MODULES_ONLY ON CACHE BOOL "" FORCE)
endif()

include(FetchContent)
FetchContent_Declare(
  JUCE
  GIT_REPOSITORY https://github.com/juce-framework/JUCE.git
  GIT_TAG        8.0.4
  GIT_SHALLOW    TRUE
)
FetchContent_MakeAvailable(JUCE)

add_library(audioapp_engine STATIC
  src/TestOscillator.cpp
  src/ProjectEngine.cpp
  src/LivePerformance.cpp
  src/ProjectEngine_live.cpp
  src/ProjectJson.cpp
  src/ProjectArchive.cpp
  src/MidiClipPlayback.cpp
  src/SampleBank.cpp
  src/WavLoader.cpp
  src/SamplePlayback.cpp
  src/SamplerFilter.cpp
  src/SubtractiveSynth.cpp
  src/MasterMix.cpp
  src/DeviceChain.cpp
  src/devices/DeviceRegistry.cpp
  src/devices/OscillatorDeviceType.cpp
  src/devices/SamplerDeviceType.cpp
  src/devices/TrackGainDeviceType.cpp
  src/devices/SubtractiveSynthDeviceType.cpp
  src/model/TrackRepository.cpp
  src/model/ClipRepository.cpp
  src/transport/TransportController.cpp
  src/modulation/ModulationGraph.cpp
  src/AutomationPlayback.cpp
  src/EngineHost_commands.cpp
  src/LfoEngine.cpp
)

target_include_directories(audioapp_engine
  PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(audioapp_engine
  PUBLIC
    juce::juce_core
)

target_compile_definitions(audioapp_engine
  PUBLIC
    JUCE_WEB_BROWSER=0
    JUCE_USE_CURL=0
    JUCE_DISPLAY_SPLASH_SCREEN=0
)

if(ANDROID)
  target_sources(audioapp_engine PRIVATE src/EngineHost_android.cpp)
  find_library(aaudio-lib aaudio)
  find_library(log-lib log)
  target_link_libraries(audioapp_engine
    PUBLIC
      ${aaudio-lib}
      ${log-lib}
  )
else()
  target_sources(audioapp_engine PRIVATE src/EngineHost_juce.cpp)
  target_link_libraries(audioapp_engine
    PUBLIC
      juce::juce_audio_basics
      juce::juce_audio_devices
      juce::juce_events
  )
endif()

if(AUDIOAPP_BUILD_TESTS AND NOT ANDROID)
  enable_testing()
  add_executable(audioapp_engine_tests
    tests/engine_smoke_test.cpp
    tests/oscillator_output_test.cpp
    tests/project_engine_test.cpp
    tests/midi_clip_playback_test.cpp
    tests/midi_clip_notes_test.cpp
    tests/clip_length_test.cpp
    tests/project_archive_test.cpp
    tests/project_serialization_test.cpp
    tests/sample_bank_test.cpp
    tests/sample_clip_test.cpp
    tests/master_mix_test.cpp
    tests/track_gain_test.cpp
    tests/sampler_midi_playback_test.cpp
    tests/device_chain_test.cpp
    tests/live_performance_test.cpp
    tests/subtractive_synth_test.cpp
    tests/lfo_modulation_test.cpp
  )
  target_link_libraries(audioapp_engine_tests PRIVATE audioapp_engine)
  add_test(NAME engine_smoke COMMAND audioapp_engine_tests)

  add_executable(device_registry_test tests/device_registry_test.cpp)
  target_link_libraries(device_registry_test PRIVATE audioapp_engine)
  add_test(NAME device_registry_test COMMAND device_registry_test)

  add_executable(device_types_test tests/device_types_test.cpp)
  target_link_libraries(device_types_test PRIVATE audioapp_engine)
  add_test(NAME device_types_test COMMAND device_types_test)
endif()
