#include "audioapp/DeviceChain.hpp"

#include "audioapp/AutomationPlayback.hpp"
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

// ---- Per-type modulation overloads ----
// These handle DSP-specific parameters only (block-rate, use lfoValue at frame 0).

void applyModulation(OscillatorParams& p, float modAmount, const std::string& paramId) noexcept {
    if (paramId == "frequency") {
        p.frequencyHz = std::max(20.0f, p.frequencyHz + modAmount * 440.0f);
    }
}

void applyModulation(SamplerParams& p, float modAmount, const std::string& paramId) noexcept {
    if (paramId == "filterCutoff") {
        p.filterCutoff = std::clamp(p.filterCutoff + modAmount, 0.0f, 1.0f);
    } else if (paramId == "filterQ") {
        p.filterQ = std::clamp(p.filterQ + modAmount, 0.0f, 1.0f);
    } else if (paramId == "attack") {
        p.attack = std::clamp(p.attack + modAmount, 0.0f, 1.0f);
    } else if (paramId == "decay") {
        p.decay = std::clamp(p.decay + modAmount, 0.0f, 1.0f);
    } else if (paramId == "sustain") {
        p.sustain = std::clamp(p.sustain + modAmount, 0.0f, 1.0f);
    } else if (paramId == "release") {
        p.release = std::clamp(p.release + modAmount, 0.0f, 1.0f);
    }
}

void applyModulation(TrackGainParams&, float, const std::string&) noexcept {}

void applyModulation(SubtractiveSynthParams& p, float modAmount, const std::string& paramId) noexcept {
    if (paramId == "filterCutoff") {
        p.filterCutoff = std::clamp(p.filterCutoff + modAmount, 0.0f, 1.0f);
    } else if (paramId == "filterQ") {
        p.filterQ = std::clamp(p.filterQ + modAmount, 0.0f, 1.0f);
    } else if (paramId == "filterMode") {
        p.filterMode = std::clamp(
            static_cast<int>(std::lround(static_cast<float>(p.filterMode) + modAmount * 4.0f)), 0, 4);
    } else if (paramId == "attack") {
        p.ampAttack = std::clamp(p.ampAttack + modAmount, 0.0f, 1.0f);
    } else if (paramId == "decay") {
        p.ampDecay = std::clamp(p.ampDecay + modAmount, 0.0f, 1.0f);
    } else if (paramId == "sustain") {
        p.ampSustain = std::clamp(p.ampSustain + modAmount, 0.0f, 1.0f);
    } else if (paramId == "release") {
        p.ampRelease = std::clamp(p.ampRelease + modAmount, 0.0f, 1.0f);
    } else if (paramId == "osc1Shape") {
        p.osc1Shape = std::clamp(p.osc1Shape + modAmount, 0.0f, 1.0f);
    } else if (paramId == "osc2Shape") {
        p.osc2Shape = std::clamp(p.osc2Shape + modAmount, 0.0f, 1.0f);
    } else if (paramId == "osc1Octave") {
        p.osc1Octave = std::clamp(p.osc1Octave + modAmount, 0.0f, 1.0f);
    } else if (paramId == "osc1Semi") {
        p.osc1Semi = std::clamp(p.osc1Semi + modAmount, 0.0f, 1.0f);
    } else if (paramId == "osc1Detune") {
        p.osc1Detune = std::clamp(p.osc1Detune + modAmount, 0.0f, 1.0f);
    } else if (paramId == "osc2Octave") {
        p.osc2Octave = std::clamp(p.osc2Octave + modAmount, 0.0f, 1.0f);
    } else if (paramId == "osc2Semi") {
        p.osc2Semi = std::clamp(p.osc2Semi + modAmount, 0.0f, 1.0f);
    } else if (paramId == "osc2Detune") {
        p.osc2Detune = std::clamp(p.osc2Detune + modAmount, 0.0f, 1.0f);
    } else if (paramId == "oscMix") {
        p.oscMix = std::clamp(p.oscMix + modAmount, 0.0f, 1.0f);
    } else if (paramId == "osc1Sync") {
        p.osc1Sync = std::clamp(p.osc1Sync + modAmount, 0.0f, 1.0f);
    } else if (paramId == "osc2Sync") {
        p.osc2Sync = std::clamp(p.osc2Sync + modAmount, 0.0f, 1.0f);
    } else if (paramId == "noiseLevel") {
        p.noiseLevel = std::clamp(p.noiseLevel + modAmount, 0.0f, 1.0f);
    } else if (paramId == "oscMixMode") {
        p.oscMixMode = std::clamp(
            static_cast<int>(std::lround(static_cast<float>(p.oscMixMode) + modAmount * 4.0f)), 0, 4);
    } else if (paramId == "unisonVoices") {
        p.unisonVoices = std::clamp(p.unisonVoices + modAmount, 0.0f, 1.0f);
    } else if (paramId == "unisonDetune") {
        p.unisonDetune = std::clamp(p.unisonDetune + modAmount, 0.0f, 1.0f);
    } else if (paramId == "filterEnvAmount") {
        p.filterEnvAmount = std::clamp(p.filterEnvAmount + modAmount, 0.0f, 1.0f);
    } else if (paramId == "filterAttack") {
        p.filterAttack = std::clamp(p.filterAttack + modAmount, 0.0f, 1.0f);
    } else if (paramId == "filterDecay") {
        p.filterDecay = std::clamp(p.filterDecay + modAmount, 0.0f, 1.0f);
    } else if (paramId == "filterSustain") {
        p.filterSustain = std::clamp(p.filterSustain + modAmount, 0.0f, 1.0f);
    } else if (paramId == "filterRelease") {
        p.filterRelease = std::clamp(p.filterRelease + modAmount, 0.0f, 1.0f);
    } else if (paramId == "glideMs") {
        p.glideMs = std::clamp(p.glideMs + modAmount, 0.0f, 1.0f);
    } else if (paramId == "velocitySensitivity") {
        p.velocitySensitivity = std::clamp(p.velocitySensitivity + modAmount, 0.0f, 1.0f);
    }
}

/// Multiply buffer by per-frame gain values.
void multiplyPerFrameGain(float* buffer, int frames, const float* perFrameGain) noexcept {
    for (int f = 0; f < frames; ++f) {
        buffer[f] *= perFrameGain[f];
    }
}

/// Mix mono buffer into stereo with per-frame pan values.
void mixStereoPerFramePan(float* trackLeft, float* trackRight,
                           const float* mono, int frames,
                           const float* perFramePan) noexcept {
    for (int f = 0; f < frames; ++f) {
        const float angle = std::clamp(perFramePan[f], 0.0f, 1.0f) * 1.57079632679f;
        trackLeft[f] += mono[f] * std::cos(angle);
        trackRight[f] += mono[f] * std::sin(angle);
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
                        int modEdgeCount,
                        const AutomationClipPlayback* automationClips,
                        int automationClipCount) noexcept {
    if (trackLeft == nullptr || trackRight == nullptr || numFrames <= 0 || devices == nullptr ||
        deviceCount <= 0) {
        return;
    }

    const int framesToProcess = numFrames > kScratchFrames ? kScratchFrames : numFrames;
    float scratch[kScratchFrames];

    for (int deviceIndex = 0; deviceIndex < deviceCount; ++deviceIndex) {
        const DeviceNodePlayback& node = devices[deviceIndex];

        if (node.bypassed) {
            continue;
        }

        // --- Apply modulation to DSP-specific params (block-rate) ---
        auto modulatedParams = node.params;

        if (lfoValues != nullptr && lfoCount > 0 && !node.deviceId.empty()) {
            for (int e = 0; e < modEdgeCount; ++e) {
                const auto& edge = modEdges[e];
                if (edge.deviceId != node.deviceId || edge.lfoId >= lfoCount) {
                    continue;
                }
                if (edge.paramId != "gain" && edge.paramId != "pan") {
                    // DSP-specific param — block-rate (first-frame LFO value)
                    const float lfoOut = lfoValues[edge.lfoId * framesToProcess];
                    const float modAmount = edge.amount * lfoOut;
                    std::visit([&](auto& params) {
                        applyModulation(params, modAmount, edge.paramId);
                    }, modulatedParams);
                }
            }
        }

        // --- Build per-frame gain/pan arrays ---
        // Always build them from the base values; edges add modulation per-frame.
        float perFrameGain[kScratchFrames];
        float perFramePan[kScratchFrames];
        for (int f = 0; f < framesToProcess; ++f) {
            perFrameGain[f] = node.gain;
            perFramePan[f] = node.pan;
        }

        if (lfoValues != nullptr && lfoCount > 0 && !node.deviceId.empty()) {
            for (int e = 0; e < modEdgeCount; ++e) {
                const auto& edge = modEdges[e];
                if (edge.deviceId != node.deviceId || edge.lfoId >= lfoCount) {
                    continue;
                }
                if (edge.paramId == "gain") {
                    for (int f = 0; f < framesToProcess; ++f) {
                        const float lfoOut = lfoValues[edge.lfoId * framesToProcess + f];
                        perFrameGain[f] = std::clamp(perFrameGain[f] + edge.amount * lfoOut, 0.0f, 1.0f);
                    }
                } else if (edge.paramId == "pan") {
                    for (int f = 0; f < framesToProcess; ++f) {
                        const float lfoOut = lfoValues[edge.lfoId * framesToProcess + f];
                        perFramePan[f] = std::clamp(perFramePan[f] + edge.amount * lfoOut, 0.0f, 1.0f);
                    }
                }
            }
        }

        // --- Apply timeline automation (block-rate absolute values) ---
        if (automationClips != nullptr && automationClipCount > 0 && !node.deviceId.empty()) {
            for (int a = 0; a < automationClipCount; ++a) {
                const AutomationClipPlayback& ac = automationClips[a];
                if (std::string(ac.deviceId) != node.deviceId) {
                    continue;
                }
                const double beat = playheadStartBeat;
                if (beat < static_cast<double>(ac.clipStartBeat) ||
                    beat >= static_cast<double>(ac.clipStartBeat + ac.clipLengthBeats)) {
                    continue;
                }
                const float beatInClip =
                    static_cast<float>(beat - static_cast<double>(ac.clipStartBeat));
                const float value =
                    evaluateAutomationEnvelope(ac.points, ac.pointCount, beatInClip);
                const std::string paramId(ac.paramId);
                if (paramId == "gain") {
                    for (int f = 0; f < framesToProcess; ++f) {
                        perFrameGain[f] = value;
                    }
                } else if (paramId == "pan") {
                    for (int f = 0; f < framesToProcess; ++f) {
                        perFramePan[f] = value;
                    }
                } else {
                    applyAutomationValue(modulatedParams, node.kind, paramId, value);
                }
            }
        }

        // --- Process device and apply per-frame gain/pan ---
        switch (node.kind) {
        case DeviceNodeKind::Oscillator: {
            if (!suppressInstruments) {
                auto p = std::get<OscillatorParams>(modulatedParams);
                p.frequencyHz = midiActiveFrequencyHz(notes, noteCount,
                    playheadStartBeat, p.frequencyHz);
                // Produce oscillator output at kInstrumentOutputGain scale,
                // then layer external gain and pan per-frame.
                const float frequency = p.frequencyHz;
                if (frequency > 0.0f) {
                    std::memset(scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                    addSineBlock(scratch, framesToProcess, sampleRate, frequency,
                                 oscillatorPhase, kInstrumentOutputGain);
                    multiplyPerFrameGain(scratch, framesToProcess, perFrameGain);
                    mixStereoPerFramePan(trackLeft, trackRight, scratch,
                                         framesToProcess, perFramePan);
                }
            }
            break;
        }
        case DeviceNodeKind::Sampler: {
            if (!suppressInstruments) {
                const auto& p = std::get<SamplerParams>(modulatedParams);
                if (p.samplerPcm != nullptr && noteCount > 0) {
                    SamplerMidiNoteRegion regions[32];
                    const int regionCount = noteCount > 32 ? 32 : noteCount;
                    for (int i = 0; i < regionCount; ++i) {
                        const MidiPlaybackNote& note = notes[i];
                        regions[i] = SamplerMidiNoteRegion{
                            note.pitch, note.clipStartBeat, note.clipLengthBeats,
                            note.noteStartBeat, note.noteDurationBeats, note.velocity,
                        };
                    }
                    std::memset(scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                    mixSamplerMidiNotesBlock(scratch, framesToProcess, sampleRate, bpm,
                                             playheadStartBeat, regions, regionCount,
                                             SamplerInstrumentPlayback{
                                                 p.samplerPcm,
                                                 p.samplerFrameCount,
                                                 p.samplerPcmSampleRate,
                                                 kInstrumentOutputGain,
                                                 60,
                                                 p.attack, p.decay,
                                                 p.sustain, p.release,
                                                 p.filterCutoff, p.filterQ,
                                                 p.filterMode,
                                                 p.trimStartFrame, p.trimEndFrame,
                                                 p.regionStartFrame, p.regionEndFrame,
                                                 samplerFilterStates != nullptr
                                                     ? &samplerFilterStates[deviceIndex] : nullptr,
                                             });
                    multiplyPerFrameGain(scratch, framesToProcess, perFrameGain);
                    mixStereoPerFramePan(trackLeft, trackRight, scratch,
                                         framesToProcess, perFramePan);
                }
            }
            break;
        }
        case DeviceNodeKind::SubtractiveSynth: {
            if (!suppressInstruments) {
                const auto& synthParams = std::get<SubtractiveSynthParams>(modulatedParams);
                if (noteCount > 0) {
                    SubtractiveMidiNoteRegion regions[32];
                    const int regionCount = noteCount > 32 ? 32 : noteCount;
                    for (int i = 0; i < regionCount; ++i) {
                        const MidiPlaybackNote& note = notes[i];
                        regions[i] = SubtractiveMidiNoteRegion{
                            note.pitch, i,
                            note.clipStartBeat, note.clipLengthBeats,
                            note.noteStartBeat, note.noteDurationBeats,
                            note.velocity,
                        };
                    }
                    std::memset(scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                    SubtractiveSynthRuntime localRuntime{};
                    mixSubtractiveMidiNotesBlock(scratch, framesToProcess, sampleRate, bpm,
                                                 playheadStartBeat, regions, regionCount,
                                                 synthParams,
                                                 subtractiveRuntimes != nullptr
                                                     ? subtractiveRuntimes[deviceIndex] : localRuntime);
                    multiplyPerFrameGain(scratch, framesToProcess, perFrameGain);
                    mixStereoPerFramePan(trackLeft, trackRight, scratch,
                                         framesToProcess, perFramePan);
                }
            }
            break;
        }
        case DeviceNodeKind::TrackGain: {
            for (int f = 0; f < framesToProcess; ++f) {
                trackLeft[f] *= perFrameGain[f];
                trackRight[f] *= perFrameGain[f];
            }
            break;
        }
        case DeviceNodeKind::Unknown:
        default:
            break;
        }
    }
}

} // namespace audioapp