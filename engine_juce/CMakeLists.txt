cmake_minimum_required(VERSION 3.22)
project(audioapp_engine VERSION 0.1.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

option(AUDIOAPP_BUILD_TESTS "Build engine unit tests" ON)
# In-tree real FFT (NEON butterflies on ARM). Default ON for Android device builds.
if(ANDROID)
  option(AUDIOAPP_USE_NEON_FFT "Use in-tree NEON/scalar real FFT instead of juce::dsp::FFT" ON)
else()
  option(AUDIOAPP_USE_NEON_FFT "Use in-tree NEON/scalar real FFT instead of juce::dsp::FFT" OFF)
endif()

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
  src/ProjectEngine_freeze.cpp
  src/ProcessorGraph.cpp
  src/DeviceSubgraph.cpp
  src/LivePerformance.cpp
  src/ProjectEngine_live.cpp
  src/ProjectJson.cpp
  src/ProjectArchive.cpp
  src/MidiClipPlayback.cpp
  src/SampleBank.cpp
  src/TrackFreeze.cpp
  src/TrackFreezeAssetStore.cpp
  src/WavLoader.cpp
  src/SamplePlaybackAlgorithm.cpp
  src/SamplerFilter.cpp
  src/KickAlgorithm.cpp
  src/SubtractiveSynthAlgorithm.cpp
  src/SubtractiveOscSimd.cpp
  src/SubtractiveMorphTable.cpp
  src/WavetableSynthAlgorithm.cpp
  src/WavetableOscSimd.cpp
  src/WavetableBank.cpp
  src/PhaseModSynthAlgorithm.cpp
  src/PhaseModOscSimd.cpp
  src/GranularAlgorithm.cpp
  src/GranularGrainSimd.cpp
  src/SnareAlgorithm.cpp
  src/ClapAlgorithm.cpp
  src/DedicatedPercussionAlgorithm.cpp
  src/CrashAlgorithm.cpp
  src/MetallicNoiseSynth.cpp
  src/DynamicsProcessor.cpp
  src/FrequencyFxProcessor.cpp
  src/ResonatorBank.cpp
  src/MasterMix.cpp
  src/DeviceChain.cpp
  src/DeviceChainAutomationModulation.cpp
  src/instruments/PerNoteModulation.cpp
  src/DeviceChainOrchestrator.cpp
  src/DeviceChainScratch.cpp
  src/devices/processors/TrackGainProcessor.cpp
  src/devices/processors/OscillatorProcessor.cpp
  src/devices/processors/SamplerProcessor.cpp
  src/devices/processors/SubtractiveSynthProcessor.cpp
  src/devices/processors/WavetableSynthProcessor.cpp
  src/devices/processors/PhaseModSynthProcessor.cpp
  src/devices/processors/KickProcessor.cpp
  src/devices/processors/SnareProcessor.cpp
  src/devices/processors/ClapProcessor.cpp
  src/devices/processors/DedicatedPercussionProcessors.cpp
  src/devices/processors/CrashProcessor.cpp
  src/devices/processors/DrumMachineProcessor.cpp
  src/devices/processors/GateProcessor.cpp
  src/devices/processors/CompressorProcessor.cpp
  src/devices/processors/ExpanderProcessor.cpp
  src/devices/processors/LimiterProcessor.cpp
  src/devices/processors/DelayProcessor.cpp
  src/devices/processors/ReverbProcessor.cpp
  src/devices/processors/ChorusProcessor.cpp
  src/devices/processors/PhaserProcessor.cpp
  src/devices/processors/FilterProcessor.cpp
  src/devices/processors/FourBandEqProcessor.cpp
  src/devices/processors/FrequencyShifterProcessor.cpp
  src/devices/processors/ResonatorBankProcessor.cpp
  src/devices/processors/BitcrusherProcessor.cpp
  src/devices/processors/DistortionProcessor.cpp
  src/devices/processors/TremoloProcessor.cpp
  src/devices/processors/StutterProcessor.cpp
  src/devices/processors/DcOffsetProcessor.cpp
  src/devices/processors/DeCracklerProcessor.cpp
  src/devices/processors/DeEsserProcessor.cpp
  src/devices/processors/DeHumProcessor.cpp
  src/devices/processors/DeNoiseProcessor.cpp
  src/devices/processors/DuckerProcessor.cpp
  src/devices/processors/UtilityProcessor.cpp
  src/devices/processors/AnalysisProcessor.cpp
  src/devices/processors/ChainProcessor.cpp
  src/devices/processors/GranularProcessor.cpp
  src/devices/processors/SplitProcessor.cpp
  src/devices/processors/MultibandSplitProcessor.cpp
  src/devices/processors/SpectralLoudSplitProcessor.cpp
  src/dsp/RealFft.cpp
  src/devices/DeviceRegistry.cpp
  src/devices/DeviceTreeWalk.cpp
  src/devices/DeviceNestingValidator.cpp
  src/devices/DrumMachineModel.cpp
  src/devices/ChainModel.cpp
  src/devices/SplitModel.cpp
  src/devices/MultibandSplitModel.cpp
  src/devices/SpectralLoudSplitModel.cpp
  src/devices/DrumMachineDeviceType.cpp
  src/devices/AnalysisDeviceType.cpp
  src/devices/ChainDeviceType.cpp
  src/devices/SplitDeviceType.cpp
  src/devices/MultibandSplitDeviceType.cpp
  src/devices/SpectralLoudSplitDeviceType.cpp
  src/devices/GranularDeviceType.cpp
  src/devices/IDeviceType.cpp
  src/devices/OscillatorDeviceType.cpp
  src/devices/SamplerDeviceType.cpp
  src/devices/TrackGainDeviceType.cpp
  src/devices/SubtractiveSynthDeviceType.cpp
  src/devices/WavetableSynthDeviceType.cpp
  src/devices/KickGeneratorDeviceType.cpp
  src/devices/SnareGeneratorDeviceType.cpp
  src/devices/ClapGeneratorDeviceType.cpp
  src/devices/DedicatedPercussionDeviceTypes.cpp
  src/devices/CrashGeneratorDeviceType.cpp
  src/devices/GateDeviceType.cpp
  src/devices/CompressorDeviceType.cpp
  src/devices/ExpanderDeviceType.cpp
  src/devices/LimiterDeviceType.cpp
  src/devices/BassSynthDeviceType.cpp
  src/devices/PhaseModSynthDeviceType.cpp
  src/devices/FilterDeviceType.cpp
  src/devices/FourBandEqDeviceType.cpp
  src/devices/FrequencyShifterDeviceType.cpp
  src/devices/ResonatorBankDeviceType.cpp
    src/devices/RoutingDeviceType.cpp
    src/devices/MidiDelayDeviceType.cpp
  src/effects/TimeBasedEffectDeviceType.cpp
  src/effects/EffectDeviceRegistration.cpp
  src/effects/EffectSnapshot.cpp
  src/effects/DelayDeviceType.cpp
  src/effects/ReverbDeviceType.cpp
  src/effects/ChorusDeviceType.cpp
  src/effects/PhaserDeviceType.cpp
  src/effects/BitcrusherDeviceType.cpp
  src/effects/DistortionDeviceType.cpp
  src/effects/TremoloDeviceType.cpp
  src/effects/StutterDeviceType.cpp
  src/effects/RestoreEffectRegistration.cpp
  src/effects/DcOffsetDeviceType.cpp
  src/effects/DeCracklerDeviceType.cpp
  src/effects/DeEsserDeviceType.cpp
  src/effects/DeHumDeviceType.cpp
  src/effects/DeNoiseDeviceType.cpp
  src/effects/DuckerDeviceType.cpp
  src/effects/UtilityDeviceType.cpp
  src/model/TrackRepository.cpp
  src/model/ClipRepository.cpp
  src/model/AutomationClipStore.cpp
  src/transport/TransportController.cpp
  src/modulation/ModulationGraph.cpp
  src/modulation/LfoModulator.cpp
  src/modulation/LfoModulatorType.cpp
  src/modulation/EnvelopeModulator.cpp
  src/modulation/EnvelopeModulatorType.cpp
  src/modulation/RandomGeneratorModulator.cpp
  src/modulation/SequencerModulator.cpp
  src/modulation/CurveModulator.cpp
  src/AutomationPlayback.cpp
  src/EngineHost_commands.cpp
  src/FallbackPreviewOscillator.cpp
  src/params/ParamRegistry.cpp
  src/commands/CommandRegistry.cpp
  src/snapshot/SnapshotDelta.cpp
)

target_include_directories(audioapp_engine
  PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(audioapp_engine
  PUBLIC
    juce::juce_core
    juce::juce_data_structures
)

target_compile_definitions(audioapp_engine
  PUBLIC
    JUCE_WEB_BROWSER=0
    JUCE_USE_CURL=0
    JUCE_DISPLAY_SPLASH_SCREEN=0
    _SILENCE_CXX20_OLD_SHARED_PTR_ATOMIC_SUPPORT_DEPRECATION_WARNING
)

if(AUDIOAPP_USE_NEON_FFT)
  target_compile_definitions(audioapp_engine PUBLIC AUDIOAPP_USE_NEON_FFT=1)
endif()

if(NOT ANDROID)
  add_executable(resonator_bank_tests EXCLUDE_FROM_ALL
    tests/resonator_bank_test.cpp
  )
  target_link_libraries(resonator_bank_tests PRIVATE audioapp_engine)
  add_executable(processor_graph_tests EXCLUDE_FROM_ALL
    tests/processor_graph_test.cpp
  )
  target_link_libraries(processor_graph_tests PRIVATE audioapp_engine)
  add_executable(routing_device_tests EXCLUDE_FROM_ALL
    tests/routing_device_test.cpp
  )
  target_link_libraries(routing_device_tests PRIVATE audioapp_engine)
  add_executable(audioapp_dsp_benchmarks EXCLUDE_FROM_ALL
    benchmarks/dsp_benchmark.cpp
  )
  target_link_libraries(audioapp_dsp_benchmarks PRIVATE audioapp_engine)
  add_executable(device_correctness_matrix_tests EXCLUDE_FROM_ALL
    tests/device_correctness_matrix_test.cpp
  )
  target_link_libraries(device_correctness_matrix_tests PRIVATE audioapp_engine)
  execute_process(
    COMMAND git rev-parse --short HEAD
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    OUTPUT_VARIABLE AUDIOAPP_BENCHMARK_COMMIT
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
  )
  if(AUDIOAPP_BENCHMARK_COMMIT)
    target_compile_definitions(audioapp_dsp_benchmarks PRIVATE
      AUDIOAPP_BENCHMARK_COMMIT="${AUDIOAPP_BENCHMARK_COMMIT}"
    )
  endif()
  add_executable(clip_playback_regression_tests EXCLUDE_FROM_ALL
    tests/clip_playback_regression_test.cpp
  )
  target_link_libraries(clip_playback_regression_tests PRIVATE audioapp_engine)
  add_executable(live_performance_regression_tests EXCLUDE_FROM_ALL
    tests/JuceTestRunner.cpp
    tests/live_performance_test.cpp
  )
  target_link_libraries(live_performance_regression_tests PRIVATE audioapp_engine)
  if(MSVC)
    target_compile_options(live_performance_regression_tests PRIVATE /EHsc)
    target_link_options(live_performance_regression_tests PRIVATE /STACK:16777216)
  endif()
endif()

if(MSVC)
  target_compile_options(audioapp_engine PRIVATE /EHsc)
endif()

if(ANDROID)
  target_sources(audioapp_engine PRIVATE src/EngineHost_android.cpp)
  find_library(aaudio-lib aaudio)
  find_library(log-lib log)
  target_link_libraries(audioapp_engine
    PUBLIC
      juce::juce_audio_basics
      juce::juce_dsp
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
      juce::juce_dsp
  )
endif()

if(AUDIOAPP_BUILD_TESTS AND NOT ANDROID)
  enable_testing()

  add_test(NAME device_correctness_matrix_tests
    COMMAND device_correctness_matrix_tests)

  add_executable(audioapp_group_track_test tests/group_track_test.cpp)
  target_link_libraries(audioapp_group_track_test PRIVATE audioapp_engine)
  if(MSVC)
    target_compile_options(audioapp_group_track_test PRIVATE /EHsc)
  endif()
  add_test(NAME audioapp_group_track_test COMMAND audioapp_group_track_test)

  add_executable(audioapp_track_output_routing_test tests/track_output_routing_test.cpp)
  target_link_libraries(audioapp_track_output_routing_test PRIVATE audioapp_engine)
  if(MSVC)
    target_compile_options(audioapp_track_output_routing_test PRIVATE /EHsc)
    target_link_options(audioapp_track_output_routing_test PRIVATE /STACK:16777216)
  endif()
  add_test(NAME audioapp_track_output_routing_test COMMAND audioapp_track_output_routing_test)

  add_executable(audioapp_track_mute_solo_test tests/track_mute_solo_test.cpp)
  target_link_libraries(audioapp_track_mute_solo_test PRIVATE audioapp_engine)
  if(MSVC)
    target_compile_options(audioapp_track_mute_solo_test PRIVATE /EHsc)
    target_link_options(audioapp_track_mute_solo_test PRIVATE /STACK:16777216)
  endif()
  add_test(NAME audioapp_track_mute_solo_test COMMAND audioapp_track_mute_solo_test)

  add_executable(audioapp_track_freeze_test tests/track_freeze_test.cpp)
  target_link_libraries(audioapp_track_freeze_test PRIVATE audioapp_engine)
  if(MSVC)
    target_compile_options(audioapp_track_freeze_test PRIVATE /EHsc)
    target_link_options(audioapp_track_freeze_test PRIVATE /STACK:16777216)
  endif()
  add_test(NAME audioapp_track_freeze_test COMMAND audioapp_track_freeze_test)

  add_executable(audioapp_remove_device_test
    tests/JuceTestRunner.cpp
    tests/remove_device_test.cpp
  )
  target_link_libraries(audioapp_remove_device_test PRIVATE audioapp_engine)
  if(MSVC)
    target_compile_options(audioapp_remove_device_test PRIVATE /EHsc)
    target_link_options(audioapp_remove_device_test PRIVATE /STACK:16777216)
  endif()
  add_test(NAME audioapp_remove_device_test COMMAND audioapp_remove_device_test)

  set(AUDIOAPP_TEST_SOURCES
    tests/JuceTestRunner.cpp
    tests/analysis_processor_test.cpp
    tests/autobroken_routing_test.cpp
    tests/automation_clip_drag_test.cpp
    tests/automation_clip_test.cpp
    tests/automation_filter_sweep_test.cpp
    tests/automation_sampler_filter_sweep_test.cpp
    tests/bass_synth_test.cpp
    tests/clap_generator_test.cpp
    tests/clip_length_test.cpp
    tests/clip_loop_content_test.cpp
    tests/common_param_modulation_test.cpp
    tests/crash_generator_test.cpp
    tests/dedicated_percussion_test.cpp
    tests/device_chain_test.cpp
    tests/device_chain_scratch_reentrancy_test.cpp
    tests/nested_chain_meter_test.cpp
    tests/device_nesting_validator_test.cpp
    tests/device_open_nesting_smoke_test.cpp
    tests/device_recursive_find_test.cpp
    tests/device_registry_test.cpp
    tests/device_slot_serialization_test.cpp
    tests/device_types_test.cpp
    tests/dynamics_processor_test.cpp
    tests/effect_chorus_test.cpp
    tests/effect_distortion_test.cpp
    tests/effect_delay_test.cpp
    tests/effect_device_automation_test.cpp
    tests/effect_device_modulation_test.cpp
    tests/effect_phaser_test.cpp
    tests/effect_reverb_test.cpp
    tests/frequency_fx_test.cpp
    tests/filter_device_test.cpp
    tests/four_band_eq_test.cpp
    tests/frequency_shifter_test.cpp
    tests/restore_fx_test.cpp
    tests/restore_fx_dsp_test.cpp
    tests/restore_fx_integration_test.cpp
    tests/engine_smoke_test.cpp
    tests/gain_pan_mod_auto_test.cpp
    tests/gate_device_test.cpp
    tests/kick_generator_test.cpp
    tests/lfo_modulation_test.cpp
    tests/lfo_polarity_test.cpp
    tests/lfo_sync_bpm_test.cpp
    tests/live_performance_test.cpp
    tests/play_transport_responsiveness_test.cpp
    tests/master_mix_test.cpp
    tests/midi_clip_notes_test.cpp
    tests/midi_comp_flatten_test.cpp
    tests/midi_clip_playback_test.cpp
    tests/modulation_e2e_test.cpp
    tests/oscillator_output_test.cpp
    tests/param_id_encoding_test.cpp
    tests/percussion_modulation_test.cpp
    tests/project_archive_test.cpp
    tests/project_engine_test.cpp
    tests/project_serialization_test.cpp
    tests/project_template_load_test.cpp
    tests/remove_device_test.cpp
    tests/sample_bank_test.cpp
    tests/sample_clip_test.cpp
    tests/sampler_midi_playback_test.cpp
    tests/sampler_playback_mode_test.cpp
    tests/snare_generator_test.cpp
    tests/split_processor_test.cpp
    tests/multiband_split_processor_test.cpp
    tests/spectral_loud_split_processor_test.cpp
    tests/spectral_loud_split_engine_test.cpp
    tests/real_fft_test.cpp
    tests/stacked_lfo_modulation_test.cpp
    tests/subtractive_lfo_filter_test.cpp
    tests/subtractive_control_rate_test.cpp
    tests/wavetable_control_rate_test.cpp
    tests/wavetable_osc_simd_test.cpp
    tests/phasemod_control_rate_test.cpp
    tests/phasemod_osc_simd_test.cpp
    tests/granular_control_rate_test.cpp
    tests/granular_grain_simd_test.cpp
    tests/subtractive_osc_simd_test.cpp
    tests/subtractive_morph_table_test.cpp
    tests/subtractive_preset_apply_test.cpp
    tests/subtractive_synth_test.cpp
    tests/phase_mod_synth_test.cpp
    tests/track_clip_repository_test.cpp
    tests/track_gain_test.cpp
    tests/transport_controller_test.cpp
    tests/fallback_oscillator_test.cpp
  )

  add_executable(audioapp_juce_tests ${AUDIOAPP_TEST_SOURCES})
  target_link_libraries(audioapp_juce_tests PRIVATE audioapp_engine)
  target_compile_definitions(audioapp_juce_tests PRIVATE
    AUDIOAPP_GOLDEN_DIR="${CMAKE_CURRENT_SOURCE_DIR}/tests/golden"
  )
  # Optionally regenerate golden files: cmake -DAUDIOAPP_REGENERATE_GOLDEN=ON
  if(AUDIOAPP_REGENERATE_GOLDEN)
    target_compile_definitions(audioapp_juce_tests PRIVATE AUDIOAPP_REGENERATE_GOLDEN)
  endif()
  if(MSVC)
    target_link_options(audioapp_juce_tests PRIVATE /STACK:67108864)
    target_compile_options(audioapp_juce_tests PRIVATE /EHsc)
  endif()
  add_test(NAME audioapp_juce_tests COMMAND audioapp_juce_tests)
endif()
