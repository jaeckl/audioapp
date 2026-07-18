#pragma once

#include <string_view>

namespace audioapp::device_types {

inline constexpr const char* kOscillator = "simple_oscillator";
inline constexpr const char* kSampler = "simple_sampler";
inline constexpr const char* kTrackGain = "track_gain";
inline constexpr const char* kSubtractiveSynth = "subtractive_synth";
inline constexpr const char* kKickGenerator = "kick_generator";
inline constexpr const char* kSnareGenerator = "snare_generator";
inline constexpr const char* kClapGenerator = "clap_generator";
inline constexpr const char* kHihatGenerator = "hihat_generator";
inline constexpr const char* kRideGenerator = "ride_generator";
inline constexpr const char* kTomGenerator = "tom_generator";
inline constexpr const char* kRimshotGenerator = "rimshot_generator";
inline constexpr const char* kCrashGenerator = "crash_generator";
inline constexpr const char* kGate = "gate";
inline constexpr const char* kCompressor = "compressor";
inline constexpr const char* kExpander = "expander";
inline constexpr const char* kLimiter = "limiter";
inline constexpr const char* kBasSynth = "bass_synth";
inline constexpr const char* kPhaseModSynth = "phase_mod_synth";
inline constexpr const char* kDelay = "delay";
inline constexpr const char* kReverb = "reverb";
inline constexpr const char* kChorus = "chorus";
inline constexpr const char* kPhaser = "phaser";
inline constexpr const char* kFilter = "filter";
inline constexpr const char* kFourBandEq = "four_band_eq";
inline constexpr const char* kFrequencyShifter = "frequency_shifter";
inline constexpr const char* kResonatorBank = "resonator_bank";
inline constexpr const char* kAudioReceiver = "audio_receiver";
inline constexpr const char* kMidiReceiver = "midi_receiver";
inline constexpr const char* kMidiDelay = "midi_delay";
inline constexpr const char* kBitcrusher = "bitcrusher";
inline constexpr const char* kDistortion = "distortion";
inline constexpr const char* kTremolo = "tremolo";
inline constexpr const char* kStutter = "stutter_fx";
inline constexpr const char* kWavetableSynth = "wavetable_synth";
inline constexpr const char* kDrumMachine = "drum_machine";
inline constexpr const char* kGranular = "granular_formant_synth";
inline constexpr const char* kOscilloscope = "oscilloscope";
inline constexpr const char* kSpectrumAnalyzer = "spectrum_analyzer";
inline constexpr const char* kLoudnessMeter = "loudness_meter";
inline constexpr const char* kStereoImager = "stereo_imager";
inline constexpr const char* kChain = "device_chain";

/// Returns true for synth/instrument device types that support audio/note FX sub-strips.
inline bool isSynthType(std::string_view typeId) {
    return typeId == kOscillator || typeId == kSubtractiveSynth ||
           typeId == kPhaseModSynth || typeId == kWavetableSynth ||
           typeId == kBasSynth || typeId == kGranular || typeId == kSampler;
}

inline bool isNoteFxType(std::string_view typeId) {
    return typeId == kMidiDelay;
}

inline bool isAudioFxType(std::string_view typeId) {
    return typeId == kGate || typeId == kCompressor || typeId == kExpander ||
           typeId == kLimiter || typeId == kDelay || typeId == kReverb ||
           typeId == kChorus || typeId == kPhaser || typeId == kFilter ||
           typeId == kFourBandEq || typeId == kFrequencyShifter ||
           typeId == kResonatorBank || typeId == kBitcrusher ||
           typeId == kDistortion || typeId == kTremolo || typeId == kStutter;
}

} // namespace audioapp::device_types
