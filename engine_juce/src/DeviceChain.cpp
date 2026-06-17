#include "audioapp/DeviceChain.hpp"

#include "audioapp/MasterMix.hpp"
#include "audioapp/MidiUtils.hpp"
#include "audioapp/SamplePlayback.hpp"
#include "audioapp/SubtractiveSynth.hpp"

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
                        BiquadState* samplerFilterStates,
                        SubtractiveSynthRuntime* subtractiveRuntimes,
                        const float* lfoValues,
                        int lfoCount,
                        const ModulationEdge* modEdges,
                        int modEdgeCount) noexcept {
    if (trackLeft == nullptr || trackRight == nullptr || numFrames <= 0 || devices == nullptr ||
        deviceCount <= 0) {
        return;
    }

    const int framesToProcess = numFrames > kScratchFrames ? kScratchFrames : numFrames;
    float scratch[kScratchFrames];

    for (int deviceIndex = 0; deviceIndex < deviceCount; ++deviceIndex) {
        const DeviceNodePlayback& node = devices[deviceIndex];

        // Build modulated copy of node (LFO values are per-block, computed by caller)
        DeviceNodePlayback modulated = node;
        if (lfoValues != nullptr && lfoCount > 0 && !node.deviceId.empty()) {
            // Find all edges targeting this device
            for (int e = 0; e < modEdgeCount; ++e) {
                const auto& edge = modEdges[e];
                if (edge.deviceId != node.deviceId || edge.lfoId >= lfoCount) {
                    continue;
                }
                const float lfoOut = lfoValues[edge.lfoId];
                const float modAmount = edge.amount * lfoOut;
                if (edge.paramId == "gain") {
                    modulated.gain = std::clamp(node.gain + modAmount, 0.0f, 1.0f);
                } else if (edge.paramId == "pan") {
                    modulated.pan = std::clamp(node.pan + modAmount, 0.0f, 1.0f);
                } else if (edge.paramId == "frequency") {
                    modulated.frequencyHz = std::max(20.0f, node.frequencyHz + modAmount * 440.0f);
                } else if (edge.paramId == "filterCutoff") {
                    modulated.filterCutoff = std::clamp(node.filterCutoff + modAmount, 0.0f, 1.0f);
                } else if (edge.paramId == "filterQ") {
                    modulated.filterQ = std::clamp(node.filterQ + modAmount, 0.0f, 1.0f);
                } else if (edge.paramId == "attack") {
                    modulated.attack = std::clamp(node.attack + modAmount, 0.0f, 1.0f);
                } else if (edge.paramId == "decay") {
                    modulated.decay = std::clamp(node.decay + modAmount, 0.0f, 1.0f);
                } else if (edge.paramId == "sustain") {
                    modulated.sustain = std::clamp(node.sustain + modAmount, 0.0f, 1.0f);
                } else if (edge.paramId == "release") {
                    modulated.release = std::clamp(node.release + modAmount, 0.0f, 1.0f);
                }
            }
        }

        switch (modulated.kind) {
        case DeviceNodeKind::Oscillator:
            if (!modulated.bypassed && !suppressInstruments) {
                const float frequency =
                    midiActiveFrequencyHz(notes, noteCount, playheadStartBeat, modulated.frequencyHz);
                if (frequency > 0.0f) {
                    std::memset(scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                    addSineBlock(scratch,
                                 framesToProcess,
                                 sampleRate,
                                 frequency,
                                 oscillatorPhase,
                                 kInstrumentOutputGain * modulated.gain);
                    panMixBlock(trackLeft, trackRight, scratch, framesToProcess, modulated.pan);
                }
            }
            break;

        case DeviceNodeKind::Sampler:
            if (!modulated.bypassed && !suppressInstruments && modulated.samplerPcm != nullptr && noteCount > 0) {
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
                                             modulated.samplerPcm,
                                             modulated.samplerFrameCount,
                                             modulated.samplerPcmSampleRate,
                                             modulated.gain * kInstrumentOutputGain,
                                             60,
                                             modulated.attack,
                                             modulated.decay,
                                             modulated.sustain,
                                             modulated.release,
                                             modulated.filterCutoff,
                                             modulated.filterQ,
                                             modulated.filterMode,
                                             modulated.trimStartFrame,
                                             modulated.trimEndFrame,
                                             samplerFilterStates != nullptr
                                                 ? &samplerFilterStates[deviceIndex]
                                                 : nullptr,
                                         });
                panMixBlock(trackLeft, trackRight, scratch, framesToProcess, modulated.pan);
            }
            break;

        case DeviceNodeKind::SubtractiveSynth:
            if (!modulated.bypassed && !suppressInstruments && noteCount > 0) {
                SubtractiveMidiNoteRegion regions[32];
                const int regionCount = noteCount > 32 ? 32 : noteCount;
                for (int i = 0; i < regionCount; ++i) {
                    const MidiPlaybackNote& note = notes[i];
                    regions[i] = SubtractiveMidiNoteRegion{
                        note.pitch,
                        i,
                        note.clipStartBeat,
                        note.clipLengthBeats,
                        note.noteStartBeat,
                        note.noteDurationBeats,
                        note.velocity,
                    };
                }
                std::memset(scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                SubtractiveSynthRuntime* runtime =
                    subtractiveRuntimes != nullptr ? &subtractiveRuntimes[deviceIndex]
                                                   : nullptr;
                SubtractiveSynthRuntime localRuntime{};
                mixSubtractiveMidiNotesBlock(scratch,
                                             framesToProcess,
                                             sampleRate,
                                             bpm,
                                             playheadStartBeat,
                                             regions,
                                             regionCount,
                                             modulated.subtractive,
                                             runtime != nullptr ? *runtime : localRuntime);
                panMixBlock(trackLeft, trackRight, scratch, framesToProcess, modulated.pan);
            }
            break;

        case DeviceNodeKind::TrackGain:
            for (int frame = 0; frame < framesToProcess; ++frame) {
                trackLeft[frame] *= modulated.gain;
                trackRight[frame] *= modulated.gain;
            }
            break;

        case DeviceNodeKind::Unknown:
        default:
            break;
        }
    }
}

} // namespace audioapp
