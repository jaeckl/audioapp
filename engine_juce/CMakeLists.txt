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
  src/KickGenerator.cpp
  src/SnareGenerator.cpp
  src/ClapGenerator.cpp
  src/CymbalGenerator.cpp
  src/CrashGenerator.cpp
  src/MetallicNoiseSynth.cpp
  src/DynamicsProcessor.cpp
  src/MasterMix.cpp
  src/DeviceChain.cpp
  src/devices/DeviceRegistry.cpp
  src/devices/OscillatorDeviceType.cpp
  src/devices/SamplerDeviceType.cpp
  src/devices/TrackGainDeviceType.cpp
  src/devices/SubtractiveSynthDeviceType.cpp
  src/devices/KickGeneratorDeviceType.cpp
  src/devices/SnareGeneratorDeviceType.cpp
  src/devices/ClapGeneratorDeviceType.cpp
  src/devices/CymbalGeneratorDeviceType.cpp
  src/devices/CrashGeneratorDeviceType.cpp
  src/devices/GateDeviceType.cpp
  src/devices/CompressorDeviceType.cpp
  src/devices/ExpanderDeviceType.cpp
  src/devices/LimiterDeviceType.cpp
  src/devices/BassSynthDeviceType.cpp
  src/model/TrackRepository.cpp
  src/model/ClipRepository.cpp
  src/model/AutomationClipStore.cpp
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
    tests/kick_generator_test.cpp
    tests/lfo_modulation_test.cpp
  )
  target_link_libraries(audioapp_engine_tests PRIVATE audioapp_engine)
  add_test(NAME engine_smoke COMMAND audioapp_engine_tests)

  add_executable(device_registry_test tests/device_registry_test.cpp)
  target_link_libraries(device_registry_test PRIVATE audioapp_engine)
  add_test(NAME device_registry_test COMMAND device_registry_test)

  add_executable(snare_generator_test tests/snare_generator_test.cpp)
  target_link_libraries(snare_generator_test PRIVATE audioapp_engine)
  add_test(NAME snare_generator_test COMMAND snare_generator_test)

  add_executable(clap_generator_test tests/clap_generator_test.cpp)
  target_link_libraries(clap_generator_test PRIVATE audioapp_engine)
  add_test(NAME clap_generator_test COMMAND clap_generator_test)

  add_executable(cymbal_generator_test tests/cymbal_generator_test.cpp)
  target_link_libraries(cymbal_generator_test PRIVATE audioapp_engine)
  add_test(NAME cymbal_generator_test COMMAND cymbal_generator_test)

  add_executable(crash_generator_test tests/crash_generator_test.cpp)
  target_link_libraries(crash_generator_test PRIVATE audioapp_engine)
  add_test(NAME crash_generator_test COMMAND crash_generator_test)

  add_executable(gate_device_test tests/gate_device_test.cpp)
  target_link_libraries(gate_device_test PRIVATE audioapp_engine)
  add_test(NAME gate_device_test COMMAND gate_device_test)

  add_executable(dynamics_processor_test tests/dynamics_processor_test.cpp)
  target_link_libraries(dynamics_processor_test PRIVATE audioapp_engine)
  add_test(NAME dynamics_processor_test COMMAND dynamics_processor_test)

  add_executable(device_types_test tests/device_types_test.cpp)
  target_link_libraries(device_types_test PRIVATE audioapp_engine)
  add_test(NAME device_types_test COMMAND device_types_test)

  add_executable(automation_filter_sweep_test tests/automation_filter_sweep_test.cpp)
  target_link_libraries(automation_filter_sweep_test PRIVATE audioapp_engine)
  add_test(NAME automation_filter_sweep_test COMMAND automation_filter_sweep_test)

  add_executable(automation_sampler_filter_sweep_test tests/automation_sampler_filter_sweep_test.cpp)
  target_link_libraries(automation_sampler_filter_sweep_test PRIVATE audioapp_engine)
  add_test(NAME automation_sampler_filter_sweep_test COMMAND automation_sampler_filter_sweep_test)

  add_executable(automation_clip_test tests/automation_clip_test.cpp)
  target_link_libraries(automation_clip_test PRIVATE audioapp_engine)
  add_test(NAME automation_clip_test COMMAND automation_clip_test)

  add_executable(automation_clip_drag_test tests/automation_clip_drag_test.cpp)
  target_link_libraries(automation_clip_drag_test PRIVATE audioapp_engine)
  add_test(NAME automation_clip_drag_test COMMAND automation_clip_drag_test)

  add_executable(remove_device_test tests/remove_device_test.cpp)
  target_link_libraries(remove_device_test PRIVATE audioapp_engine)
  add_test(NAME remove_device_test COMMAND remove_device_test)

  add_executable(subtractive_lfo_filter_test tests/subtractive_lfo_filter_test.cpp)
  target_link_libraries(subtractive_lfo_filter_test PRIVATE audioapp_engine)
  add_test(NAME subtractive_lfo_filter_test COMMAND subtractive_lfo_filter_test)

  add_executable(autobroken_routing_test tests/autobroken_routing_test.cpp)
  target_link_libraries(autobroken_routing_test PRIVATE audioapp_engine)
  add_test(NAME autobroken_routing_test COMMAND autobroken_routing_test)

  add_executable(param_id_encoding_test tests/param_id_encoding_test.cpp)
  target_link_libraries(param_id_encoding_test PRIVATE audioapp_engine)
  add_test(NAME param_id_encoding_test COMMAND param_id_encoding_test)

  add_executable(modulation_e2e_test tests/modulation_e2e_test.cpp)
  target_link_libraries(modulation_e2e_test PRIVATE audioapp_engine)
  add_test(NAME modulation_e2e_test COMMAND modulation_e2e_test)

  add_executable(bass_synth_test tests/bass_synth_test.cpp)
  target_link_libraries(bass_synth_test PRIVATE audioapp_engine)
  add_test(NAME bass_synth_test COMMAND bass_synth_test)

  add_executable(device_slot_serialization_test tests/device_slot_serialization_test.cpp)
  target_link_libraries(device_slot_serialization_test PRIVATE audioapp_engine)
  add_test(NAME device_slot_serialization_test COMMAND device_slot_serialization_test)
endif()
