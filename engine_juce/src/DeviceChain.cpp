#include "audioapp/DeviceChain.hpp"

#include "audioapp/MasterMix.hpp"
#include "audioapp/MidiUtils.hpp"
#include "audioapp/SamplePlayback.hpp"

#include <cmath>

namespace audioapp {

namespace {

bool isMidiNoteActive(const MidiPlaybackNote& note, double beat) {
    if (beat < note.clipStartBeat || beat >= note.clipStartBeat + note.clipLengthBeats) {
        return false;
    }
    const double posInClip = beat - note.clipStartBeat;
    const double loopedBeat = std::fmod(posInClip, note.clipLengthBeats);
    return loopedBeat >= note.noteStartBeat
        && loopedBeat < (note.noteStartBeat + note.noteDurationBeats);
}

} // namespace

float midiActiveFrequencyHz(const MidiPlaybackNote* notes,
                            int noteCount,
                            double playheadBeat,
                            float idleFrequencyHz) noexcept {
    int pitch = -1;
    for (int i = 0; i < noteCount; ++i) {
        if (!isMidiNoteActive(notes[i], playheadBeat)) {
            continue;
        }
        pitch = notes[i].pitch;
    }
    if (pitch >= 0) {
        return midiNoteToHz(pitch);
    }
    return idleFrequencyHz;
}

void processDeviceChain(float* trackBuffer,
                        int numFrames,
                        double sampleRate,
                        int bpm,
                        double playheadStartBeat,
                        const MidiPlaybackNote* notes,
                        int noteCount,
                        const DeviceNodePlayback* devices,
                        int deviceCount,
                        float& oscillatorPhase,
                        bool suppressInstruments,
                        BiquadState* samplerFilterStates) noexcept {
    if (trackBuffer == nullptr || numFrames <= 0 || devices == nullptr || deviceCount <= 0) {
        return;
    }

    for (int deviceIndex = 0; deviceIndex < deviceCount; ++deviceIndex) {
        const DeviceNodePlayback& node = devices[deviceIndex];

        switch (node.kind) {
        case DeviceNodeKind::Oscillator:
            if (!suppressInstruments) {
                const float frequency =
                    midiActiveFrequencyHz(notes, noteCount, playheadStartBeat, node.frequencyHz);
                if (frequency > 0.0f) {
                    addSineBlock(trackBuffer,
                                 numFrames,
                                 sampleRate,
                                 frequency,
                                 oscillatorPhase,
                                 kInstrumentOutputGain);
                }
            }
            break;

        case DeviceNodeKind::Sampler:
            if (!suppressInstruments && node.samplerPcm != nullptr && noteCount > 0) {
                SamplerMidiNoteRegion regions[32];
                const int regionCount = noteCount > 32 ? 32 : noteCount;
                for (int i = 0; i < regionCount; ++i) {
                    const MidiPlaybackNote& note = notes[i];
                    regions[i] = SamplerMidiNoteRegion{
                        note.pitch,
                        note.clipStartBeat,
                        note.clipLengthBeats,
                        note.noteStartBeat,
                        note.noteDurationBeats,
                        note.velocity,
                    };
                }
                mixSamplerMidiNotesBlock(trackBuffer,
                                         numFrames,
                                         sampleRate,
                                         bpm,
                                         playheadStartBeat,
                                         regions,
                                         regionCount,
                                         SamplerInstrumentPlayback{
                                             node.samplerPcm,
                                             node.samplerFrameCount,
                                             node.samplerPcmSampleRate,
                                             node.gain * kInstrumentOutputGain,
                                             60,
                                             node.attack,
                                             node.decay,
                                             node.sustain,
                                             node.release,
                                             node.filterCutoff,
                                             node.filterQ,
                                             node.filterMode,
                                             node.trimStartFrame,
                                             node.trimEndFrame,
                                             samplerFilterStates != nullptr
                                                 ? &samplerFilterStates[deviceIndex]
                                                 : nullptr,
                                         });
            }
            break;

        case DeviceNodeKind::TrackGain:
            for (int frame = 0; frame < numFrames; ++frame) {
                trackBuffer[frame] *= node.gain;
            }
            break;

        case DeviceNodeKind::Unknown:
        default:
            break;
        }
    }
}

} // namespace audioapp
