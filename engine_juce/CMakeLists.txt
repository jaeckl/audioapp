cmake_minimum_required(VERSION 3.22)
project(audioapp_engine VERSION 0.1.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 20)
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
  src/effects/TimeBasedEffectDeviceType.cpp
  src/effects/EffectDeviceRegistration.cpp
  src/effects/EffectSnapshot.cpp
  src/effects/DelayDeviceType.cpp
  src/effects/ReverbDeviceType.cpp
  src/effects/ChorusDeviceType.cpp
  src/effects/PhaserDeviceType.cpp
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
    _SILENCE_CXX20_OLD_SHARED_PTR_ATOMIC_SUPPORT_DEPRECATION_WARNING
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

  set(AUDIOAPP_TEST_SOURCES
    tests/JuceTestRunner.cpp
    tests/adsr_modulator_test.cpp
    tests/autobroken_routing_test.cpp
    tests/automation_clip_drag_test.cpp
    tests/automation_clip_test.cpp
    tests/automation_filter_sweep_test.cpp
    tests/automation_sampler_filter_sweep_test.cpp
    tests/bass_synth_test.cpp
    tests/clap_generator_test.cpp
    tests/clip_length_test.cpp
    tests/common_param_modulation_test.cpp
    tests/crash_generator_test.cpp
    tests/cymbal_generator_test.cpp
    tests/device_chain_test.cpp
    tests/device_registry_test.cpp
    tests/device_slot_serialization_test.cpp
    tests/device_types_test.cpp
    tests/dynamics_processor_test.cpp
    tests/effect_chorus_test.cpp
    tests/effect_delay_test.cpp
    tests/effect_device_automation_test.cpp
    tests/effect_device_modulation_test.cpp
    tests/effect_phaser_test.cpp
    tests/effect_reverb_test.cpp
    tests/engine_smoke_test.cpp
    tests/gain_pan_mod_auto_test.cpp
    tests/gate_device_test.cpp
    tests/kick_generator_test.cpp
    tests/lfo_modulation_test.cpp
    tests/lfo_polarity_test.cpp
    tests/lfo_sync_bpm_test.cpp
    tests/live_performance_test.cpp
    tests/master_mix_test.cpp
    tests/midi_clip_notes_test.cpp
    tests/midi_clip_playback_test.cpp
    tests/modulation_e2e_test.cpp
    tests/oscillator_output_test.cpp
    tests/param_id_encoding_test.cpp
    tests/percussion_modulation_test.cpp
    tests/project_archive_test.cpp
    tests/project_engine_test.cpp
    tests/project_serialization_test.cpp
    tests/remove_device_test.cpp
    tests/sample_bank_test.cpp
    tests/sample_clip_test.cpp
    tests/sampler_midi_playback_test.cpp
    tests/sampler_playback_mode_test.cpp
    tests/snare_generator_test.cpp
    tests/stacked_lfo_modulation_test.cpp
    tests/subtractive_lfo_filter_test.cpp
    tests/subtractive_preset_apply_test.cpp
    tests/subtractive_synth_test.cpp
    tests/track_clip_repository_test.cpp
    tests/track_gain_test.cpp
    tests/transport_controller_test.cpp
  )

  add_executable(audioapp_juce_tests ${AUDIOAPP_TEST_SOURCES})
  target_link_libraries(audioapp_juce_tests PRIVATE audioapp_engine)
  if(MSVC)
    target_link_options(audioapp_juce_tests PRIVATE /STACK:16777216)
  endif()
  add_test(NAME audioapp_juce_tests COMMAND audioapp_juce_tests)
endif()
