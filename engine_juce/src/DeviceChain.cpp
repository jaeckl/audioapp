#include "audioapp/DeviceChain.hpp"

#include "audioapp/MasterMix.hpp"
#include "audioapp/MidiUtils.hpp"
#include "audioapp/SamplePlayback.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

namespace {

constexpr int kScratchFrames = 4096;

bool isMidiNoteActive(const MidiPlaybackNote& note, double beat) {
    if (beat < note.clipStartBeat || beat >= note.clipStartBeat + note.clipLengthBeats) {
        return false;
    }
    const double posInClip = beat - note.clipStartBeat;
    const double loopedBeat = std::fmod(posInClip, note.clipLengthBeats);
    const double noteEnd = std::min(note.noteStartBeat + note.noteDurationBeats, note.clipLengthBeats);
    return loopedBeat >= note.noteStartBeat && loopedBeat < noteEnd;
}

void panMixBlock(float* trackLeft,
                 float* trackRight,
                 const float* mono,
                 int numFrames,
                 float pan) noexcept {
    const float angle = std::clamp(pan, 0.0f, 1.0f) * 1.57079632679f;
    const float leftGain = std::cos(angle);
    const float rightGain = std::sin(angle);
    for (int frame = 0; frame < numFrames; ++frame) {
        const float sample = mono[frame];
        trackLeft[frame] += sample * leftGain;
        trackRight[frame] += sample * rightGain;
    }
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

void processDeviceChain(float* trackLeft,
                        float* trackRight,
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
    if (trackLeft == nullptr || trackRight == nullptr || numFrames <= 0 || devices == nullptr ||
        deviceCount <= 0) {
        return;
    }

    const int framesToProcess = numFrames > kScratchFrames ? kScratchFrames : numFrames;
    float scratch[kScratchFrames];

    for (int deviceIndex = 0; deviceIndex < deviceCount; ++deviceIndex) {
        const DeviceNodePlayback& node = devices[deviceIndex];

        switch (node.kind) {
        case DeviceNodeKind::Oscillator:
            if (!node.bypassed && !suppressInstruments) {
                const float frequency =
                    midiActiveFrequencyHz(notes, noteCount, playheadStartBeat, node.frequencyHz);
                if (frequency > 0.0f) {
                    std::memset(scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                    addSineBlock(scratch,
                                 framesToProcess,
                                 sampleRate,
                                 frequency,
                                 oscillatorPhase,
                                 kInstrumentOutputGain * node.gain);
                    panMixBlock(trackLeft, trackRight, scratch, framesToProcess, node.pan);
                }
            }
            break;

        case DeviceNodeKind::Sampler:
            if (!node.bypassed && !suppressInstruments && node.samplerPcm != nullptr && noteCount > 0) {
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
                std::memset(scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                mixSamplerMidiNotesBlock(scratch,
                                         framesToProcess,
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
                panMixBlock(trackLeft, trackRight, scratch, framesToProcess, node.pan);
            }
            break;

        case DeviceNodeKind::TrackGain:
            for (int frame = 0; frame < framesToProcess; ++frame) {
                trackLeft[frame] *= node.gain;
                trackRight[frame] *= node.gain;
            }
            break;

        case DeviceNodeKind::Unknown:
        default:
            break;
        }
    }
}

} // namespace audioapp
