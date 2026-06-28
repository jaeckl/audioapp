#include "audioapp/DeviceChain.hpp"

#include "audioapp/AutomationPlayback.hpp"
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
           kind == DeviceNodeKind::CymbalGenerator || kind == DeviceNodeKind::CrashGenerator ||
           kind == DeviceNodeKind::BassSynth ||
           kind == DeviceNodeKind::PhaseModSynth ||
           kind == DeviceNodeKind::WavetableSynth;
}

bool isFrequencyFxDeviceNodeKind(DeviceNodeKind kind) noexcept {
    return kind == DeviceNodeKind::Filter ||
           kind == DeviceNodeKind::FourBandEq ||
           kind == DeviceNodeKind::FrequencyShifter ||
           kind == DeviceNodeKind::ResonatorBank;
}

bool handlesOwnModulation(DeviceNodeKind kind) noexcept {
    // Returns true for instrument types that implement their own per-frame or
    // sub-block modulation inside their process() method, either via explicit
    // sub-block loops (Oscillator, Sampler) or per-frame LFO reads inside
    // their mix*MidiNotesBlock (SubtractiveSynth, BassSynth, PhaseModSynth).
    // Percussion generators (Kick, Snare, Clap, Cymbal, Crash) depend on the
    // orchestrator applying block-rate modulation to ctx.modulatedParams and
    // so must return false here.
    return kind == DeviceNodeKind::Oscillator ||
           kind == DeviceNodeKind::Sampler ||
           kind == DeviceNodeKind::SubtractiveSynth ||
           kind == DeviceNodeKind::BassSynth ||
           kind == DeviceNodeKind::PhaseModSynth;
}

float midiActiveFrequencyHz(const MidiPlaybackNote* notes,
                            int noteCount,
                            double playheadBeat,
                            float idleFrequencyHz) noexcept {
    auto noteActive = [](const MidiPlaybackNote& note, double beat) noexcept -> bool {
        if (beat < note.clipStartBeat || beat >= note.clipStartBeat + note.clipLengthBeats) {
            return false;
        }
        const double posInClip = beat - note.clipStartBeat;
        const double loopedBeat = std::fmod(posInClip, note.clipLengthBeats);
        const double noteEnd = std::min(note.noteStartBeat + note.noteDurationBeats, note.clipLengthBeats);
        return loopedBeat >= note.noteStartBeat && loopedBeat < noteEnd;
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
    if (typeId == kCymbalGenerator)  return DeviceNodeKind::CymbalGenerator;
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
    if (typeId == kWavetableSynth)   return DeviceNodeKind::WavetableSynth;
    if (typeId == kResonatorBank)    return DeviceNodeKind::ResonatorBank;
    return DeviceNodeKind::Unknown;
}

} // namespace audioapp
