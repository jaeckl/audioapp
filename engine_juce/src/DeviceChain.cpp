#include "audioapp/DeviceChain.hpp"

#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/ClipContentPlayback.hpp"
#include "audioapp/MidiUtils.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {

bool isDynamicsDeviceNodeKind(const DeviceNodeKind kind) noexcept {
    return kind == DeviceNodeKind::Gate || kind == DeviceNodeKind::Compressor ||
           kind == DeviceNodeKind::Expander || kind == DeviceNodeKind::Limiter;
}

bool isInstrumentDeviceNodeKind(const DeviceNodeKind kind) noexcept {
    return kind == DeviceNodeKind::Oscillator || kind == DeviceNodeKind::Sampler ||
           kind == DeviceNodeKind::SubtractiveSynth || kind == DeviceNodeKind::KickGenerator ||
           kind == DeviceNodeKind::SnareGenerator || kind == DeviceNodeKind::ClapGenerator ||
           kind == DeviceNodeKind::HihatGenerator || kind == DeviceNodeKind::CrashGenerator ||
           kind == DeviceNodeKind::RideGenerator || kind == DeviceNodeKind::TomGenerator ||
           kind == DeviceNodeKind::RimshotGenerator ||
           kind == DeviceNodeKind::BassSynth ||
           kind == DeviceNodeKind::PhaseModSynth ||
           kind == DeviceNodeKind::WavetableSynth ||
           kind == DeviceNodeKind::DrumMachine || kind == DeviceNodeKind::Granular;
}

bool isFrequencyFxDeviceNodeKind(DeviceNodeKind kind) noexcept {
    return kind == DeviceNodeKind::Filter ||
           kind == DeviceNodeKind::FourBandEq ||
           kind == DeviceNodeKind::FrequencyShifter ||
           kind == DeviceNodeKind::ResonatorBank;
}

bool isRoutingDeviceNodeKind(DeviceNodeKind kind) noexcept {
    return kind == DeviceNodeKind::AudioReceiver ||
           kind == DeviceNodeKind::MidiReceiver;
}

bool isAnalysisDeviceNodeKind(DeviceNodeKind kind) noexcept {
    return kind == DeviceNodeKind::Oscilloscope ||
           kind == DeviceNodeKind::SpectrumAnalyzer ||
           kind == DeviceNodeKind::LoudnessMeter ||
           kind == DeviceNodeKind::StereoImager;
}

bool handlesOwnModulation(DeviceNodeKind kind) noexcept {
    // Returns true for instrument types that implement their own per-frame or
    // sub-block modulation inside their process() method, either via explicit
    // sub-block loops (Oscillator, Sampler) or held global modulation inside
    // mix*MidiNotesBlock (SubtractiveSynth, BassSynth, PhaseModSynth, WavetableSynth, Granular).
    // Percussion generators (Kick, Snare, Clap, Cymbal, Crash) depend on the
    // orchestrator applying block-rate modulation to ctx.modulatedParams and
    // so must return false here.
    return kind == DeviceNodeKind::Oscillator ||
           kind == DeviceNodeKind::Sampler ||
           kind == DeviceNodeKind::SubtractiveSynth ||
           kind == DeviceNodeKind::BassSynth ||
           kind == DeviceNodeKind::PhaseModSynth ||
           kind == DeviceNodeKind::WavetableSynth ||
           kind == DeviceNodeKind::Granular;
}

float midiActiveFrequencyHz(const MidiPlaybackNote* notes,
                            int noteCount,
                            double playheadBeat,
                            float idleFrequencyHz) noexcept {
    auto noteActive = [](const MidiPlaybackNote& note, double beat) noexcept -> bool {
        return isMidiNoteActiveInClip(
            beat,
            note.clipStartBeat,
            note.clipLengthBeats,
            note.contentLengthBeats,
            note.loopContent,
            note.noteStartBeat,
            note.noteDurationBeats);
    };
    int pitch = -1;
    for (int i = 0; i < noteCount; ++i) {
        if (!noteActive(notes[i], playheadBeat)) continue;
        pitch = notes[i].pitch;
    }
    if (pitch >= 0) return midiNoteToHz(pitch);
    return idleFrequencyHz;
}

DeviceNodeKind deviceNodeKindFromTypeId(const std::string& typeId) noexcept {
    using namespace device_types;
    if (typeId == kOscillator)       return DeviceNodeKind::Oscillator;
    if (typeId == kSampler)          return DeviceNodeKind::Sampler;
    if (typeId == kSubtractiveSynth) return DeviceNodeKind::SubtractiveSynth;
    if (typeId == kKickGenerator)    return DeviceNodeKind::KickGenerator;
    if (typeId == kSnareGenerator)   return DeviceNodeKind::SnareGenerator;
    if (typeId == kClapGenerator)    return DeviceNodeKind::ClapGenerator;
    if (typeId == kHihatGenerator)   return DeviceNodeKind::HihatGenerator;
    if (typeId == kRideGenerator)    return DeviceNodeKind::RideGenerator;
    if (typeId == kTomGenerator)     return DeviceNodeKind::TomGenerator;
    if (typeId == kRimshotGenerator) return DeviceNodeKind::RimshotGenerator;
    if (typeId == kCrashGenerator)   return DeviceNodeKind::CrashGenerator;
    if (typeId == kGate)             return DeviceNodeKind::Gate;
    if (typeId == kCompressor)       return DeviceNodeKind::Compressor;
    if (typeId == kExpander)         return DeviceNodeKind::Expander;
    if (typeId == kLimiter)          return DeviceNodeKind::Limiter;
    if (typeId == kTrackGain)        return DeviceNodeKind::TrackGain;
    if (typeId == kBasSynth)         return DeviceNodeKind::BassSynth;
    if (typeId == kPhaseModSynth)    return DeviceNodeKind::PhaseModSynth;
    if (typeId == kDelay)            return DeviceNodeKind::Delay;
    if (typeId == kReverb)           return DeviceNodeKind::Reverb;
    if (typeId == kChorus)           return DeviceNodeKind::Chorus;
    if (typeId == kPhaser)           return DeviceNodeKind::Phaser;
    if (typeId == kFilter)           return DeviceNodeKind::Filter;
    if (typeId == kFourBandEq)       return DeviceNodeKind::FourBandEq;
    if (typeId == kFrequencyShifter) return DeviceNodeKind::FrequencyShifter;
    if (typeId == kBitcrusher)       return DeviceNodeKind::Bitcrusher;
    if (typeId == kDistortion)       return DeviceNodeKind::Distortion;
    if (typeId == kTremolo)          return DeviceNodeKind::Tremolo;
    if (typeId == kStutter)          return DeviceNodeKind::Stutter;
    if (typeId == kWavetableSynth)   return DeviceNodeKind::WavetableSynth;
    if (typeId == kResonatorBank)    return DeviceNodeKind::ResonatorBank;
    if (typeId == kAudioReceiver)    return DeviceNodeKind::AudioReceiver;
    if (typeId == kMidiReceiver)     return DeviceNodeKind::MidiReceiver;
    if (typeId == kMidiDelay)        return DeviceNodeKind::MidiDelay;
    if (typeId == kDrumMachine)      return DeviceNodeKind::DrumMachine;
    if (typeId == kGranular)         return DeviceNodeKind::Granular;
    if (typeId == kOscilloscope)     return DeviceNodeKind::Oscilloscope;
    if (typeId == kSpectrumAnalyzer) return DeviceNodeKind::SpectrumAnalyzer;
    if (typeId == kLoudnessMeter)    return DeviceNodeKind::LoudnessMeter;
    if (typeId == kStereoImager)     return DeviceNodeKind::StereoImager;
    if (typeId == kChain)            return DeviceNodeKind::Chain;
    if (typeId == kLrSplit)          return DeviceNodeKind::Split;
    if (typeId == kMsSplit)          return DeviceNodeKind::Split;
    if (typeId == kMbSplit2 || typeId == kMbSplit3 || typeId == kMbSplit4)
        return DeviceNodeKind::MultibandSplit;
    if (typeId == kSpectralLoudSplit)
        return DeviceNodeKind::SpectralLoudSplit;
    if (typeId == kDcOffset)         return DeviceNodeKind::DcOffset;
    if (typeId == kDeCrackler)       return DeviceNodeKind::DeCrackler;
    if (typeId == kDeEsser)          return DeviceNodeKind::DeEsser;
    if (typeId == kDeHum)            return DeviceNodeKind::DeHum;
    if (typeId == kDeNoise)          return DeviceNodeKind::DeNoise;
    if (typeId == kDucker)           return DeviceNodeKind::Ducker;
    if (typeId == kUtility)          return DeviceNodeKind::Utility;
    return DeviceNodeKind::Unknown;
}

} // namespace audioapp
