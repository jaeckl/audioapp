#include "audioapp/DeviceChain.hpp"

#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/MidiUtils.hpp"

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
           kind == DeviceNodeKind::PhaseModSynth;
}

bool isFrequencyFxDeviceNodeKind(DeviceNodeKind kind) noexcept {
    return kind == DeviceNodeKind::Filter ||
           kind == DeviceNodeKind::FourBandEq ||
           kind == DeviceNodeKind::FrequencyShifter;
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

} // namespace audioapp