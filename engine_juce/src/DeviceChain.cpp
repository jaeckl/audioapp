#include "audioapp/DeviceChain.hpp"
#include "audioapp/DeviceChainProcessor.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/DeviceChainAutomationModulation.hpp"

#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/MidiUtils.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {

namespace {

thread_local DeviceChainScratch gScratch;


using namespace audioapp::DeviceChainAutomationModulation;

} // namespace

// =======================================================================
// Public API
// =======================================================================

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
                        KickGeneratorRuntime* kickRuntimes,
                        SnareGeneratorRuntime* snareRuntimes,
                        ClapGeneratorRuntime* clapRuntimes,
                        CymbalGeneratorRuntime* cymbalRuntimes,
                        CrashGeneratorRuntime* crashRuntimes,
                        PhaseModSynthRuntime* phaseModRuntimes,
                        DynamicsRuntime* dynamicsRuntimes,
                        TimeBasedEffectRuntime* timeBasedRuntimes,
                        DeviceMeterAtomic* deviceMeters,
                        int maxDeviceMeters,
                        const float* lfoValues,
                        int lfoCount,
                        const ModulationEdgePlayback* modEdges,
                        int modEdgeCount,
                        const AutomationClipPlayback* automationClips,
                        int automationClipCount,
                        FilterRuntime* filterRuntimes,
                        FourBandEqRuntime* fourBandEqRuntimes,
                        FrequencyShifterRuntime* frequencyShifterRuntimes) noexcept {
    if (trackLeft == nullptr || trackRight == nullptr || numFrames <= 0 || devices == nullptr ||
        deviceCount <= 0) {
        return;
    }

    const int framesToProcess = numFrames > kScratchFrames ? kScratchFrames : numFrames;
    auto& s = gScratch;

    const double beatsPerFrame =
        (static_cast<double>(std::max(bpm, 1)) / 60.0) / sampleRate;

    for (int deviceIndex = 0; deviceIndex < deviceCount; ++deviceIndex) {
        const DeviceNodePlayback& node = devices[deviceIndex];
        if (node.bypassed) continue;

        auto modulatedParams = node.params;
        for (int f = 0; f < framesToProcess; ++f) {
            s.perFrameGain[f] = node.gain;
            s.perFramePan[f] = node.pan;
        }

        const uint16_t di = static_cast<uint16_t>(deviceIndex);
        const bool needsSubBlocks = nodeNeedsSubBlocks(
            node, deviceIndex, automationClips, automationClipCount, modEdges, modEdgeCount);

        // --- Timeline automation ---
        if (automationClips != nullptr && automationClipCount > 0) {
            for (int a = 0; a < automationClipCount; ++a) {
                const auto& ac = automationClips[a];
                if (ac.deviceIndex != di) continue;

                // Encoded kind tag prevents CommonParam::Gain (0) from
                // being confused with SubtractiveSynth::FilterCutoff (0x3000).
                if (ac.localParamId == kEncodedCommonGain ||
                    ac.localParamId == kEncodedCommonPan) {
                    const bool isGain = ac.localParamId == kEncodedCommonGain;
                    for (int f = 0; f < framesToProcess; ++f) {
                        const double beat = playheadStartBeat + static_cast<double>(f) * beatsPerFrame;
                        if (beat < static_cast<double>(ac.clipStartBeat) ||
                            beat >= static_cast<double>(ac.clipStartBeat + ac.clipLengthBeats)) {
                            continue;
                        }
                        const float beatInClip = static_cast<float>(beat - static_cast<double>(ac.clipStartBeat));
                        const float val = evaluateAutomationEnvelope(ac.points, ac.pointCount, beatInClip);
                        if (isGain) s.perFrameGain[f] = val;
                        else s.perFramePan[f] = val;
                    }
                } else if (!needsSubBlocks) {
                    if ((node.kind == DeviceNodeKind::SubtractiveSynth ||
                         node.kind == DeviceNodeKind::BassSynth ||
                         node.kind == DeviceNodeKind::PhaseModSynth) &&
                        nodeHasDspAutomation(di, automationClips, automationClipCount)) {
                        continue;
                    }
                    const double beat = playheadStartBeat;
                    if (beat < static_cast<double>(ac.clipStartBeat) ||
                        beat >= static_cast<double>(ac.clipStartBeat + ac.clipLengthBeats)) continue;
                    const float beatInClip = static_cast<float>(beat - static_cast<double>(ac.clipStartBeat));
                    const float val = evaluateAutomationEnvelope(ac.points, ac.pointCount, beatInClip);
                    applyAutomationValue(modulatedParams, node.kind, ac.localParamId, val);
                }
            }
        }

        // --- LFO modulation (DSP params) ---
        if (lfoValues != nullptr && lfoCount > 0 && modEdges != nullptr && modEdgeCount > 0) {
            for (int e = 0; e < modEdgeCount; ++e) {
                const auto& edge = modEdges[e];
                if (edge.deviceIndex != di || edge.lfoId >= static_cast<uint16_t>(lfoCount)) continue;
                const uint16_t pid = edge.localParamId;
                if (pid == kEncodedCommonGain || pid == kEncodedCommonPan) continue;
                if (!needsSubBlocks) {
                    if ((node.kind == DeviceNodeKind::SubtractiveSynth ||
                         node.kind == DeviceNodeKind::BassSynth ||
                         node.kind == DeviceNodeKind::PhaseModSynth) &&
                        (nodeHasDspAutomation(di, automationClips, automationClipCount) ||
                         nodeHasDspModulation(di, modEdges, modEdgeCount))) continue;
                    const float lfoOut = lfoValues[edge.lfoId * framesToProcess];
                    const float modAmount = edge.amount * lfoOut;
                    std::visit([&](auto& params) {
                        applyModulation(params, modAmount, pid);
                    }, modulatedParams);
                }
            }
        }

        // --- Per-frame gain/pan LFO modulation ---
        audioapp::DeviceChainProcessor::applyCommonGainPanLfo(
            s, di, framesToProcess,
            lfoValues, lfoCount, modEdges, modEdgeCount);

        // --- Process device ---
        audioapp::DeviceChainProcessor::processDeviceNode(
            node, deviceIndex,
            trackLeft, trackRight,
            framesToProcess,
            sampleRate, bpm, playheadStartBeat,
            notes, noteCount,
            modulatedParams,
            needsSubBlocks,
            suppressInstruments,
            s,
            oscillatorPhase,
            samplerFilterStates,
            subtractiveRuntimes,
            kickRuntimes,
            snareRuntimes,
            clapRuntimes,
            cymbalRuntimes,
            crashRuntimes,
            phaseModRuntimes,
            dynamicsRuntimes,
            timeBasedRuntimes,
            deviceMeters, maxDeviceMeters,
            lfoValues, lfoCount,
            modEdges, modEdgeCount,
            automationClips, automationClipCount,
            filterRuntimes,
            fourBandEqRuntimes,
            frequencyShifterRuntimes);
    }
}

} // namespace audioapp