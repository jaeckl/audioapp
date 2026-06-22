#include "audioapp/DeviceChainProcessor.hpp"
#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/DeviceChainAutomationModulation.hpp"
#include "audioapp/MasterMix.hpp"
#include "audioapp/MidiUtils.hpp"
#include "audioapp/SamplePlayback.hpp"
#include "audioapp/SubtractiveSynth.hpp"
#include "audioapp/KickGenerator.hpp"
#include "audioapp/SnareGenerator.hpp"
#include "audioapp/ClapGenerator.hpp"
#include "audioapp/CymbalGenerator.hpp"
#include "audioapp/CrashGenerator.hpp"
#include "audioapp/DynamicsProcessor.hpp"
#include "audioapp/FrequencyFxProcessor.hpp"
#include "audioapp/PhaseModSynth.hpp"
#include "audioapp/devices/instances/FrequencyFxInstance.hpp"
#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp::DeviceChainProcessor {
using namespace audioapp::DeviceChainAutomationModulation;

namespace {

float stereoBlockPeak(const float* left, const float* right, int frameCount) noexcept {
    float peak = 0.0f;
    for (int i = 0; i < frameCount; ++i) {
        peak = std::max(peak, std::max(std::abs(left[i]), std::abs(right[i])));
    }
    return peak;
}

void publishDynamicsMeters(const DeviceNodePlayback& n,
                           const DynamicsRuntime& runtime,
                           float inputPeak,
                           DeviceMeterAtomic* meters,
                           int maxMeters) noexcept {
    if (meters == nullptr || n.meterSlot < 0 || n.meterSlot >= maxMeters) {
        return;
    }
    meters[n.meterSlot].gainReductionDb.store(runtime.gainReductionDb,
                                              std::memory_order_relaxed);
    meters[n.meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
}
void applyStereoScalarGain(float* left, float* right, int frames, float gain) noexcept {
    for (int f = 0; f < frames; ++f) {
        left[f] *= gain;
        right[f] *= gain;
    }
}
void multiplyPerFrameGain(float* buffer, int frames, const float* gain) noexcept {
    for (int f = 0; f < frames; ++f) {
        buffer[f] *= gain[f];
    }
}
void mixStereoPerFramePan(float* trackLeftL, float* trackRightL,
                          const float* mono, int frames,
                          const float* perFramePan) noexcept {
    for (int f = 0; f < frames; ++f) {
        const float angle = std::clamp(perFramePan[f], 0.0f, 1.0f) * 1.57079632679f;
        trackLeftL[f] += mono[f] * std::cos(angle);
        trackRightL[f] += mono[f] * std::sin(angle);
    }
}
} // namespace

void applyCommonGainPanLfo(DeviceChainScratch& scratch,
                            uint16_t deviceIndex,
                            int framesToProcess,
                            const float* lfoValues, int lfoCount,
                            const ModulationEdgePlayback* modEdges, int modEdgeCount) noexcept {
    if (lfoValues != nullptr && lfoCount > 0 && modEdges != nullptr && modEdgeCount > 0) {
        for (int e = 0; e < modEdgeCount; ++e) {
            const auto& edge = modEdges[e];
            if (edge.deviceIndex != deviceIndex || edge.lfoId >= static_cast<uint16_t>(lfoCount)) continue;
            const uint16_t pid = edge.localParamId;
            if (pid == kEncodedCommonGain) {
                for (int f = 0; f < framesToProcess; ++f) {
                    const float lfoOut = lfoValues[edge.lfoId * framesToProcess + f];
                    scratch.perFrameGain[f] = std::clamp(scratch.perFrameGain[f] + edge.amount * lfoOut, 0.0f, 1.0f);
                }
            } else if (pid == kEncodedCommonPan) {
                for (int f = 0; f < framesToProcess; ++f) {
                    const float lfoOut = lfoValues[edge.lfoId * framesToProcess + f];
                    scratch.perFramePan[f] = std::clamp(scratch.perFramePan[f] + edge.amount * lfoOut, 0.0f, 1.0f);
                }
            }
        }
    }
}

void processDeviceNode(
    const DeviceNodePlayback& node,
    int deviceIndex,
    float* trackLeft, float* trackRight,
    int framesToProcess,
    double sampleRate, int bpm, double playheadStartBeat,
    const MidiPlaybackNote* notes, int noteCount,
    const DeviceVariantParams& modulatedParams,
    bool needsSubBlocks,
    bool suppressInstruments,
    DeviceChainScratch& scratch,
    float& oscillatorPhase,
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
    DeviceMeterAtomic* deviceMeters, int maxDeviceMeters,
    const float* lfoValues, int lfoCount,
    const ModulationEdgePlayback* modEdges, int modEdgeCount,
    const AutomationClipPlayback* automationClips, int automationClipCount,
    FilterRuntime* filterRuntimes,
    FourBandEqRuntime* fourBandEqRuntimes,
    FrequencyShifterRuntime* frequencyShifterRuntimes) noexcept {

    const double beatsPerFrame =
        (static_cast<double>(std::max(bpm, 1)) / 60.0) / sampleRate;

    const uint16_t di = static_cast<uint16_t>(deviceIndex);

    auto midiActiveFrequencyHz = [&](float idleFrequencyHz) noexcept {
        auto noteActive = [](const MidiPlaybackNote& note, double beat) {
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
            if (!noteActive(notes[i], playheadStartBeat)) continue;
            pitch = notes[i].pitch;
        }
        if (pitch >= 0) return midiNoteToHz(pitch);
        return idleFrequencyHz;
    };

    switch (node.kind) {
    case DeviceNodeKind::Oscillator: {
        if (!suppressInstruments) {
            std::memset(scratch.scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
            if (needsSubBlocks) {
                for (int sub = 0; sub < framesToProcess; sub += kAutomationSubBlockFrames) {
                    const int subLen = std::min(kAutomationSubBlockFrames, framesToProcess - sub);
                    const double subBeat = playheadStartBeat + static_cast<double>(sub) * beatsPerFrame;
                    auto subParams = dspParamsAtFrame(node, deviceIndex, subBeat, sub, framesToProcess,
                        automationClips, automationClipCount, lfoValues, lfoCount, modEdges, modEdgeCount);
                    auto p = std::get<OscillatorParams>(subParams);
                    p.frequencyHz = midiActiveFrequencyHz(p.frequencyHz);
                    if (p.frequencyHz > 0.0f) {
                        addSineBlock(scratch.scratch + sub, subLen, sampleRate, p.frequencyHz,
                                     oscillatorPhase, kInstrumentOutputGain);
                    }
                }
            } else {
                auto p = std::get<OscillatorParams>(modulatedParams);
                p.frequencyHz = midiActiveFrequencyHz(p.frequencyHz);
                if (p.frequencyHz > 0.0f) {
                    addSineBlock(scratch.scratch, framesToProcess, sampleRate, p.frequencyHz,
                                 oscillatorPhase, kInstrumentOutputGain);
                }
            }
            multiplyPerFrameGain(scratch.scratch, framesToProcess, scratch.perFrameGain);
            mixStereoPerFramePan(trackLeft, trackRight, scratch.scratch, framesToProcess, scratch.perFramePan);
        }
        break;
    }
    case DeviceNodeKind::Sampler: {
        if (!suppressInstruments) {
            const auto& baseParams = std::get<SamplerParams>(modulatedParams);
            if (baseParams.samplerPcm != nullptr && noteCount > 0) {
                const int regionCount = noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : noteCount;
                for (int i = 0; i < regionCount; ++i) {
                    const MidiPlaybackNote& note = notes[i];
                    scratch.samplerRegions[i] = SamplerMidiNoteRegion{
                        note.pitch, note.clipStartBeat, note.clipLengthBeats,
                        note.noteStartBeat, note.noteDurationBeats, note.velocity,
                    };
                }
                std::memset(scratch.scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                BiquadState* noteFilterBase = nullptr;
                if (samplerFilterStates != nullptr) {
                    noteFilterBase = &samplerFilterStates[deviceIndex * kMaxInstrumentRegions];
                }
                std::memset(scratch.samplerNoteFilterStates, 0, sizeof(scratch.samplerNoteFilterStates));
                BiquadState* effectiveNoteFilters =
                    noteFilterBase != nullptr ? noteFilterBase : scratch.samplerNoteFilterStates;

                const auto render = [&](int sub, int subLen, double subBeat, const SamplerParams& p) {
                    mixSamplerMidiNotesBlock(scratch.scratch + sub, subLen, sampleRate, bpm, subBeat,
                        scratch.samplerRegions, regionCount, SamplerInstrumentPlayback{
                            p.samplerPcm, p.samplerFrameCount, p.samplerPcmSampleRate,
                            kInstrumentOutputGain, p.rootPitch, p.rootFineTune,
                            p.attack, p.decay, p.sustain, p.release,
                            p.filterCutoff, p.filterQ, p.filterMode,
                            p.filterEnvAmount, p.filterAttack, p.filterDecay, p.filterSustain, p.filterRelease,
                            p.trimStartFrame, p.trimEndFrame, p.regionStartFrame, p.regionEndFrame,
                            p.playbackMode, nullptr, effectiveNoteFilters, regionCount,
                        });
                };
                if (needsSubBlocks) {
                    for (int sub = 0; sub < framesToProcess; sub += kAutomationSubBlockFrames) {
                        const int subLen = std::min(kAutomationSubBlockFrames, framesToProcess - sub);
                        const double subBeat = playheadStartBeat + static_cast<double>(sub) * beatsPerFrame;
                        auto subParams = dspParamsAtFrame(node, deviceIndex, subBeat, sub, framesToProcess,
                            automationClips, automationClipCount, lfoValues, lfoCount, modEdges, modEdgeCount);
                        const auto p = std::get<SamplerParams>(subParams);
                        render(sub, subLen, subBeat, p);
                    }
                } else {
                    render(0, framesToProcess, playheadStartBeat, baseParams);
                }
                multiplyPerFrameGain(scratch.scratch, framesToProcess, scratch.perFrameGain);
                mixStereoPerFramePan(trackLeft, trackRight, scratch.scratch, framesToProcess, scratch.perFramePan);
            }
        }
        break;
    }
    case DeviceNodeKind::BassSynth:
    case DeviceNodeKind::SubtractiveSynth: {
        if (!suppressInstruments && noteCount > 0) {
            const int regionCount = noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : noteCount;
            for (int i = 0; i < regionCount; ++i) {
                const MidiPlaybackNote& note = notes[i];
                // Use pitch as stable voice identifier across block boundaries
                scratch.subtractiveRegions[i] = SubtractiveMidiNoteRegion{note.pitch, note.pitch,
                    note.clipStartBeat, note.clipLengthBeats,
                    note.noteStartBeat, note.noteDurationBeats, note.velocity};
            }
            std::memset(scratch.scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
            SubtractiveSynthRuntime localRuntime{};
            auto& runtime = subtractiveRuntimes != nullptr ? subtractiveRuntimes[deviceIndex] : localRuntime;
            const bool hasAuto = nodeHasDspAutomation(di, automationClips, automationClipCount);
            const bool hasMod = lfoValues != nullptr && lfoCount > 0 && modEdges != nullptr && modEdgeCount > 0 &&
                                nodeHasDspModulation(di, modEdges, modEdgeCount);
            mixSubtractiveMidiNotesBlock(scratch.scratch, framesToProcess, sampleRate, bpm, playheadStartBeat,
                scratch.subtractiveRegions, regionCount, std::get<SubtractiveSynthParams>(modulatedParams), runtime,
                hasAuto ? automationClips : nullptr, hasAuto ? automationClipCount : 0,
                hasAuto ? &di : nullptr,
                hasMod ? lfoValues : nullptr, hasMod ? lfoCount : 0, hasMod ? framesToProcess : 0,
                hasMod ? modEdges : nullptr, hasMod ? modEdgeCount : 0,
                hasMod ? &di : nullptr);
            multiplyPerFrameGain(scratch.scratch, framesToProcess, scratch.perFrameGain);
            mixStereoPerFramePan(trackLeft, trackRight, scratch.scratch, framesToProcess, scratch.perFramePan);
        }
        break;
    }
    case DeviceNodeKind::KickGenerator: {
        if (!suppressInstruments && noteCount > 0) {
            const auto& kp = std::get<KickGeneratorParams>(modulatedParams);
            const int regionCount = noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : noteCount;
            for (int i = 0; i < regionCount; ++i) {
                const MidiPlaybackNote& note = notes[i];
                scratch.kickRegions[i] = KickMidiNoteRegion{note.pitch, i,
                    note.clipStartBeat, note.clipLengthBeats,
                    note.noteStartBeat, note.noteDurationBeats, note.velocity};
            }
            std::memset(scratch.scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
            KickGeneratorRuntime localRuntime{};
            mixKickMidiNotesBlock(scratch.scratch, framesToProcess, sampleRate, bpm, playheadStartBeat,
                scratch.kickRegions, regionCount, kp,
                kickRuntimes != nullptr ? kickRuntimes[deviceIndex] : localRuntime);
            multiplyPerFrameGain(scratch.scratch, framesToProcess, scratch.perFrameGain);
            mixStereoPerFramePan(trackLeft, trackRight, scratch.scratch, framesToProcess, scratch.perFramePan);
        }
        break;
    }
    case DeviceNodeKind::SnareGenerator: {
        if (!suppressInstruments && noteCount > 0) {
            const auto& sp = std::get<SnareGeneratorParams>(modulatedParams);
            const int regionCount = noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : noteCount;
            for (int i = 0; i < regionCount; ++i) {
                const MidiPlaybackNote& note = notes[i];
                scratch.snareRegions[i] = SnareMidiNoteRegion{note.pitch, i,
                    note.clipStartBeat, note.clipLengthBeats,
                    note.noteStartBeat, note.noteDurationBeats, note.velocity};
            }
            std::memset(scratch.scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
            SnareGeneratorRuntime localRuntime{};
            mixSnareMidiNotesBlock(scratch.scratch, framesToProcess, sampleRate, bpm, playheadStartBeat,
                scratch.snareRegions, regionCount, sp,
                snareRuntimes != nullptr ? snareRuntimes[deviceIndex] : localRuntime);
            multiplyPerFrameGain(scratch.scratch, framesToProcess, scratch.perFrameGain);
            mixStereoPerFramePan(trackLeft, trackRight, scratch.scratch, framesToProcess, scratch.perFramePan);
        }
        break;
    }
    case DeviceNodeKind::ClapGenerator: {
        if (!suppressInstruments && noteCount > 0) {
            const auto& cp = std::get<ClapGeneratorParams>(modulatedParams);
            const int regionCount = noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : noteCount;
            for (int i = 0; i < regionCount; ++i) {
                const MidiPlaybackNote& note = notes[i];
                scratch.clapRegions[i] = ClapMidiNoteRegion{note.pitch, i,
                    note.clipStartBeat, note.clipLengthBeats,
                    note.noteStartBeat, note.noteDurationBeats, note.velocity};
            }
            std::memset(scratch.scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
            ClapGeneratorRuntime localRuntime{};
            mixClapMidiNotesBlock(scratch.scratch, framesToProcess, sampleRate, bpm, playheadStartBeat,
                scratch.clapRegions, regionCount, cp,
                clapRuntimes != nullptr ? clapRuntimes[deviceIndex] : localRuntime);
            multiplyPerFrameGain(scratch.scratch, framesToProcess, scratch.perFrameGain);
            mixStereoPerFramePan(trackLeft, trackRight, scratch.scratch, framesToProcess, scratch.perFramePan);
        }
        break;
    }
    case DeviceNodeKind::CymbalGenerator: {
        if (!suppressInstruments && noteCount > 0) {
            const auto& cyp = std::get<CymbalGeneratorParams>(modulatedParams);
            const int regionCount = noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : noteCount;
            for (int i = 0; i < regionCount; ++i) {
                const MidiPlaybackNote& note = notes[i];
                scratch.cymbalRegions[i] = CymbalMidiNoteRegion{note.pitch, i,
                    note.clipStartBeat, note.clipLengthBeats,
                    note.noteStartBeat, note.noteDurationBeats, note.velocity};
            }
            std::memset(scratch.tempStereoL, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
            std::memset(scratch.tempStereoR, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
            CymbalGeneratorRuntime localRuntime{};
            mixCymbalMidiNotesBlockStereo(scratch.tempStereoL, scratch.tempStereoR, framesToProcess, sampleRate, bpm,
                playheadStartBeat, scratch.cymbalRegions, regionCount, cyp,
                cymbalRuntimes != nullptr ? cymbalRuntimes[deviceIndex] : localRuntime, scratch.perFrameGain);
            for (int f = 0; f < framesToProcess; ++f) {
                const float angle = std::clamp(scratch.perFramePan[f], 0.0f, 1.0f) * 1.57079632679f;
                trackLeft[f] += scratch.tempStereoL[f] * std::cos(angle) + scratch.tempStereoR[f] * std::cos(angle);
                trackRight[f] += scratch.tempStereoL[f] * std::sin(angle) + scratch.tempStereoR[f] * std::sin(angle);
            }
        }
        break;
    }
    case DeviceNodeKind::CrashGenerator: {
        if (!suppressInstruments && noteCount > 0) {
            const auto& crp = std::get<CrashGeneratorParams>(modulatedParams);
            const int regionCount = noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : noteCount;
            for (int i = 0; i < regionCount; ++i) {
                const MidiPlaybackNote& note = notes[i];
                scratch.crashRegions[i] = CrashMidiNoteRegion{note.pitch, i,
                    note.clipStartBeat, note.clipLengthBeats,
                    note.noteStartBeat, note.noteDurationBeats, note.velocity};
            }
            std::memset(scratch.tempStereoL, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
            std::memset(scratch.tempStereoR, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
            CrashGeneratorRuntime localRuntime{};
            mixCrashMidiNotesBlockStereo(scratch.tempStereoL, scratch.tempStereoR, framesToProcess, sampleRate, bpm,
                playheadStartBeat, scratch.crashRegions, regionCount, crp,
                crashRuntimes != nullptr ? crashRuntimes[deviceIndex] : localRuntime, scratch.perFrameGain);
            for (int f = 0; f < framesToProcess; ++f) {
                const float angle = std::clamp(scratch.perFramePan[f], 0.0f, 1.0f) * 1.57079632679f;
                trackLeft[f] += scratch.tempStereoL[f] * std::cos(angle) + scratch.tempStereoR[f] * std::cos(angle);
                trackRight[f] += scratch.tempStereoL[f] * std::sin(angle) + scratch.tempStereoR[f] * std::sin(angle);
            }
        }
        break;
    }
    case DeviceNodeKind::PhaseModSynth: {
        if (!suppressInstruments && noteCount > 0) {
            const int regionCount = noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : noteCount;
            for (int i = 0; i < regionCount; ++i) {
                const MidiPlaybackNote& note = notes[i];
                scratch.phaseModRegions[i] = PhaseModSynthMidiNoteRegion{note.pitch, note.pitch,
                    note.clipStartBeat, note.clipLengthBeats,
                    note.noteStartBeat, note.noteDurationBeats, note.velocity};
            }
            std::memset(scratch.scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
            PhaseModSynthRuntime localRuntime{};
            auto& runtime = phaseModRuntimes != nullptr ? phaseModRuntimes[deviceIndex] : localRuntime;
            const bool hasAuto = nodeHasDspAutomation(di, automationClips, automationClipCount);
            const bool hasMod = lfoValues != nullptr && lfoCount > 0 && modEdges != nullptr && modEdgeCount > 0 &&
                                nodeHasDspModulation(di, modEdges, modEdgeCount);
            mixPhaseModMidiNotesBlock(scratch.scratch, framesToProcess, sampleRate, bpm, playheadStartBeat,
                scratch.phaseModRegions, regionCount, std::get<PhaseModSynthParams>(modulatedParams), runtime,
                hasAuto ? automationClips : nullptr, hasAuto ? automationClipCount : 0,
                hasAuto ? &di : nullptr,
                hasMod ? lfoValues : nullptr, hasMod ? lfoCount : 0, hasMod ? framesToProcess : 0,
                hasMod ? modEdges : nullptr, hasMod ? modEdgeCount : 0,
                hasMod ? &di : nullptr);
            multiplyPerFrameGain(scratch.scratch, framesToProcess, scratch.perFrameGain);
            mixStereoPerFramePan(trackLeft, trackRight, scratch.scratch, framesToProcess, scratch.perFramePan);
        }
        break;
    }
    case DeviceNodeKind::Gate: {
        auto p = std::get<GateParams>(modulatedParams);
        DynamicsRuntime localRuntime{};
        auto& runtime = dynamicsRuntimes != nullptr ? dynamicsRuntimes[deviceIndex] : localRuntime;
        applyStereoScalarGain(trackLeft, trackRight, framesToProcess, std::clamp(p.inputGain, 0.0f, 1.0f));
        const float inputPeak = stereoBlockPeak(trackLeft, trackRight, framesToProcess);
        processGateStereoBlock(trackLeft, trackRight, framesToProcess, sampleRate, p, runtime);
        publishDynamicsMeters(node, runtime, inputPeak, deviceMeters, maxDeviceMeters);
        for (int f = 0; f < framesToProcess; ++f) {
            trackLeft[f] *= scratch.perFrameGain[f];
            trackRight[f] *= scratch.perFrameGain[f];
        }
        break;
    }
    case DeviceNodeKind::Compressor: {
        auto p = std::get<CompressorParams>(modulatedParams);
        DynamicsRuntime localRuntime{};
        auto& runtime = dynamicsRuntimes != nullptr ? dynamicsRuntimes[deviceIndex] : localRuntime;
        applyStereoScalarGain(trackLeft, trackRight, framesToProcess, std::clamp(p.inputGain, 0.0f, 1.0f));
        const float inputPeak = stereoBlockPeak(trackLeft, trackRight, framesToProcess);
        processCompressorStereoBlock(trackLeft, trackRight, framesToProcess, sampleRate, p, runtime);
        publishDynamicsMeters(node, runtime, inputPeak, deviceMeters, maxDeviceMeters);
        for (int f = 0; f < framesToProcess; ++f) {
            trackLeft[f] *= scratch.perFrameGain[f];
            trackRight[f] *= scratch.perFrameGain[f];
        }
        break;
    }
    case DeviceNodeKind::Expander: {
        auto p = std::get<ExpanderParams>(modulatedParams);
        DynamicsRuntime localRuntime{};
        auto& runtime = dynamicsRuntimes != nullptr ? dynamicsRuntimes[deviceIndex] : localRuntime;
        applyStereoScalarGain(trackLeft, trackRight, framesToProcess, std::clamp(p.inputGain, 0.0f, 1.0f));
        const float inputPeak = stereoBlockPeak(trackLeft, trackRight, framesToProcess);
        processExpanderStereoBlock(trackLeft, trackRight, framesToProcess, sampleRate, p, runtime);
        publishDynamicsMeters(node, runtime, inputPeak, deviceMeters, maxDeviceMeters);
        for (int f = 0; f < framesToProcess; ++f) {
            trackLeft[f] *= scratch.perFrameGain[f];
            trackRight[f] *= scratch.perFrameGain[f];
        }
        break;
    }
    case DeviceNodeKind::Limiter: {
        auto p = std::get<LimiterParams>(modulatedParams);
        DynamicsRuntime localRuntime{};
        auto& runtime = dynamicsRuntimes != nullptr ? dynamicsRuntimes[deviceIndex] : localRuntime;
        applyStereoScalarGain(trackLeft, trackRight, framesToProcess, std::clamp(p.inputGain, 0.0f, 1.0f));
        const float inputPeak = stereoBlockPeak(trackLeft, trackRight, framesToProcess);
        processLimiterStereoBlock(trackLeft, trackRight, framesToProcess, sampleRate, p, runtime);
        publishDynamicsMeters(node, runtime, inputPeak, deviceMeters, maxDeviceMeters);
        for (int f = 0; f < framesToProcess; ++f) {
            trackLeft[f] *= scratch.perFrameGain[f];
            trackRight[f] *= scratch.perFrameGain[f];
        }
        break;
    }
    case DeviceNodeKind::Filter: {
        auto p = std::get<FilterParams>(modulatedParams);
        FilterRuntime localRuntime{};
        auto& runtime = filterRuntimes != nullptr ? filterRuntimes[deviceIndex] : localRuntime;
        processFilterStereoBlock(trackLeft, trackRight, framesToProcess, sampleRate, p, runtime);
        for (int f = 0; f < framesToProcess; ++f) {
            trackLeft[f] *= scratch.perFrameGain[f];
            trackRight[f] *= scratch.perFrameGain[f];
        }
        break;
    }
    case DeviceNodeKind::FourBandEq: {
        auto p = std::get<FourBandEqParams>(modulatedParams);
        FourBandEqRuntime localRuntime{};
        auto& runtime = fourBandEqRuntimes != nullptr ? fourBandEqRuntimes[deviceIndex] : localRuntime;
        processFourBandEqStereoBlock(trackLeft, trackRight, framesToProcess, sampleRate, p, runtime);
        for (int f = 0; f < framesToProcess; ++f) {
            trackLeft[f] *= scratch.perFrameGain[f];
            trackRight[f] *= scratch.perFrameGain[f];
        }
        break;
    }
    case DeviceNodeKind::FrequencyShifter: {
        auto p = std::get<FrequencyShifterParams>(modulatedParams);
        FrequencyShifterRuntime localRuntime{};
        auto& runtime = frequencyShifterRuntimes != nullptr ? frequencyShifterRuntimes[deviceIndex] : localRuntime;
        processFrequencyShifterStereoBlock(trackLeft, trackRight, framesToProcess, sampleRate, p, runtime);
        for (int f = 0; f < framesToProcess; ++f) {
            trackLeft[f] *= scratch.perFrameGain[f];
            trackRight[f] *= scratch.perFrameGain[f];
        }
        break;
    }
    case DeviceNodeKind::Delay: {
        auto p = std::get<DelayParamsPlayback>(node.params);
        if (timeBasedRuntimes != nullptr) {
            auto& rt = timeBasedRuntimes[deviceIndex];
            applyStereoScalarGain(trackLeft, trackRight, framesToProcess, std::clamp(p.inputGain, 0.0f, 1.0f));

            float delayTimeMs = std::clamp(p.timeMs, 1.0f, 2000.0f);
            int delaySamples = static_cast<int>(std::round((delayTimeMs / 1000.0f) * sampleRate));
            delaySamples = std::clamp(delaySamples, 1, TimeBasedEffectRuntime::kBufferSize - 1);

            float fb = std::clamp(p.feedback, 0.0f, 0.95f);
            float mix = std::clamp(p.mix, 0.0f, 1.0f);

            for (int f = 0; f < framesToProcess; ++f) {
                float dryL = trackLeft[f];
                float dryR = trackRight[f];

                int readIdx = (rt.writeIndex - delaySamples + TimeBasedEffectRuntime::kBufferSize) % TimeBasedEffectRuntime::kBufferSize;
                float delayedL = rt.bufferLeft[readIdx];
                float delayedR = rt.bufferRight[readIdx];

                trackLeft[f] = (1.0f - mix) * dryL + mix * delayedL;
                trackRight[f] = (1.0f - mix) * dryR + mix * delayedR;

                rt.bufferLeft[rt.writeIndex] = dryL + fb * delayedL;
                rt.bufferRight[rt.writeIndex] = dryR + fb * delayedR;

                rt.writeIndex = (rt.writeIndex + 1) % TimeBasedEffectRuntime::kBufferSize;
            }
        }
        if (deviceMeters != nullptr && node.meterSlot >= 0 && node.meterSlot < maxDeviceMeters) {
            float inputPeak = stereoBlockPeak(trackLeft, trackRight, framesToProcess);
            deviceMeters[node.meterSlot].gainReductionDb.store(0.0f, std::memory_order_relaxed);
            deviceMeters[node.meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
        }
        for (int f = 0; f < framesToProcess; ++f) {
            trackLeft[f] *= scratch.perFrameGain[f];
            trackRight[f] *= scratch.perFrameGain[f];
        }
        break;
    }
    case DeviceNodeKind::Reverb: {
        auto p = std::get<ReverbParamsPlayback>(node.params);
        if (timeBasedRuntimes != nullptr) {
            auto& rt = timeBasedRuntimes[deviceIndex];
            applyStereoScalarGain(trackLeft, trackRight, framesToProcess, std::clamp(p.inputGain, 0.0f, 1.0f));

            float roomSize = std::clamp(p.roomSize, 0.0f, 1.0f);
            float wet = std::clamp(p.wetLevel, 0.0f, 1.0f);
            float dry = std::clamp(p.dryLevel, 0.0f, 1.0f);

            // Tap delay times in samples
            int tapsL[4] = { 1601, 2377, 3511, 4999 };
            int tapsR[4] = { 1867, 2693, 3821, 5413 };

            float sizeScale = 0.5f + 1.5f * roomSize;
            float fb = 0.7f + 0.25f * roomSize;

            for (int f = 0; f < framesToProcess; ++f) {
                float dryL = trackLeft[f];
                float dryR = trackRight[f];

                float wetL = 0.0f;
                float wetR = 0.0f;

                for (int i = 0; i < 4; ++i) {
                    int dL = static_cast<int>(tapsL[i] * sizeScale);
                    dL = std::clamp(dL, 10, TimeBasedEffectRuntime::kBufferSize - 1);
                    int readIdxL = (rt.writeIndex - dL + TimeBasedEffectRuntime::kBufferSize) % TimeBasedEffectRuntime::kBufferSize;
                    wetL += rt.bufferLeft[readIdxL];

                    int dR = static_cast<int>(tapsR[i] * sizeScale);
                    dR = std::clamp(dR, 10, TimeBasedEffectRuntime::kBufferSize - 1);
                    int readIdxR = (rt.writeIndex - dR + TimeBasedEffectRuntime::kBufferSize) % TimeBasedEffectRuntime::kBufferSize;
                    wetR += rt.bufferRight[readIdxR];
                }

                wetL *= 0.25f;
                wetR *= 0.25f;

                // Simple 1st-order allpass diffusion stages on the wet signal
                float apG = 0.6f;
                float xApL = wetL;
                float yApL = apG * xApL + rt.phaserStateL[0];
                rt.phaserStateL[0] = xApL - apG * yApL;
                wetL = yApL;

                float xApR = wetR;
                float yApR = apG * xApR + rt.phaserStateR[0];
                rt.phaserStateR[0] = xApR - apG * yApR;
                wetR = yApR;

                trackLeft[f] = dry * dryL + wet * wetL;
                trackRight[f] = dry * dryR + wet * wetR;

                rt.bufferLeft[rt.writeIndex] = dryL + fb * wetL;
                rt.bufferRight[rt.writeIndex] = dryR + fb * wetR;

                rt.writeIndex = (rt.writeIndex + 1) % TimeBasedEffectRuntime::kBufferSize;
            }
        }
        if (deviceMeters != nullptr && node.meterSlot >= 0 && node.meterSlot < maxDeviceMeters) {
            float inputPeak = stereoBlockPeak(trackLeft, trackRight, framesToProcess);
            deviceMeters[node.meterSlot].gainReductionDb.store(0.0f, std::memory_order_relaxed);
            deviceMeters[node.meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
        }
        for (int f = 0; f < framesToProcess; ++f) {
            trackLeft[f] *= scratch.perFrameGain[f];
            trackRight[f] *= scratch.perFrameGain[f];
        }
        break;
    }
    case DeviceNodeKind::Chorus: {
        auto p = std::get<ChorusParamsPlayback>(node.params);
        if (timeBasedRuntimes != nullptr) {
            auto& rt = timeBasedRuntimes[deviceIndex];
            applyStereoScalarGain(trackLeft, trackRight, framesToProcess, std::clamp(p.inputGain, 0.0f, 1.0f));

            float depth = std::clamp(p.depth, 0.0f, 1.0f);
            float rateHz = std::clamp(p.rateHz, 0.1f, 5.0f);
            float mix = std::clamp(p.mix, 0.0f, 1.0f);
            float centreDelayMs = std::clamp(p.centreDelayMs, 1.0f, 20.0f);
            float fb = std::clamp(p.feedback, 0.0f, 0.95f);

            for (int f = 0; f < framesToProcess; ++f) {
                float dryL = trackLeft[f];
                float dryR = trackRight[f];

                rt.lfoPhase += static_cast<float>((2.0 * 3.1415926535f * rateHz) / sampleRate);
                if (rt.lfoPhase > static_cast<float>(2.0 * 3.1415926535f)) {
                    rt.lfoPhase -= static_cast<float>(2.0 * 3.1415926535f);
                }

                float delayMsL = centreDelayMs + depth * 5.0f * sinf(rt.lfoPhase);
                float delayMsR = centreDelayMs + depth * 5.0f * cosf(rt.lfoPhase);

                float delaySamplesL = (delayMsL / 1000.0f) * static_cast<float>(sampleRate);
                float delaySamplesR = (delayMsR / 1000.0f) * static_cast<float>(sampleRate);

                delaySamplesL = std::clamp(delaySamplesL, 1.0f, static_cast<float>(TimeBasedEffectRuntime::kBufferSize - 2));
                delaySamplesR = std::clamp(delaySamplesR, 1.0f, static_cast<float>(TimeBasedEffectRuntime::kBufferSize - 2));

                auto readInterpolated = [&](float* buf, float delayS) {
                    int idx1 = (rt.writeIndex - static_cast<int>(delayS) + TimeBasedEffectRuntime::kBufferSize) % TimeBasedEffectRuntime::kBufferSize;
                    int idx2 = (idx1 - 1 + TimeBasedEffectRuntime::kBufferSize) % TimeBasedEffectRuntime::kBufferSize;
                    float frac = delayS - floorf(delayS);
                    return (1.0f - frac) * buf[idx1] + frac * buf[idx2];
                };

                float delayedL = readInterpolated(rt.bufferLeft, delaySamplesL);
                float delayedR = readInterpolated(rt.bufferRight, delaySamplesR);

                trackLeft[f] = (1.0f - mix) * dryL + mix * delayedL;
                trackRight[f] = (1.0f - mix) * dryR + mix * delayedR;

                rt.bufferLeft[rt.writeIndex] = dryL + fb * delayedL;
                rt.bufferRight[rt.writeIndex] = dryR + fb * delayedR;

                rt.writeIndex = (rt.writeIndex + 1) % TimeBasedEffectRuntime::kBufferSize;
            }
        }
        if (deviceMeters != nullptr && node.meterSlot >= 0 && node.meterSlot < maxDeviceMeters) {
            float inputPeak = stereoBlockPeak(trackLeft, trackRight, framesToProcess);
            deviceMeters[node.meterSlot].gainReductionDb.store(0.0f, std::memory_order_relaxed);
            deviceMeters[node.meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
        }
        for (int f = 0; f < framesToProcess; ++f) {
            trackLeft[f] *= scratch.perFrameGain[f];
            trackRight[f] *= scratch.perFrameGain[f];
        }
        break;
    }
    case DeviceNodeKind::Phaser: {
        auto p = std::get<PhaserParamsPlayback>(node.params);
        if (timeBasedRuntimes != nullptr) {
            auto& rt = timeBasedRuntimes[deviceIndex];
            applyStereoScalarGain(trackLeft, trackRight, framesToProcess, std::clamp(p.inputGain, 0.0f, 1.0f));

            float depth = std::clamp(p.depth, 0.0f, 1.0f);
            float rateHz = std::clamp(p.rateHz, 0.1f, 5.0f);
            float fb = std::clamp(p.feedback, 0.0f, 0.95f);
            float centreFreq = std::clamp(p.centreFrequencyHz, 20.0f, 20000.0f);

            for (int f = 0; f < framesToProcess; ++f) {
                float dryL = trackLeft[f];
                float dryR = trackRight[f];

                rt.lfoPhase += static_cast<float>((2.0 * 3.1415926535f * rateHz) / sampleRate);
                if (rt.lfoPhase > static_cast<float>(2.0 * 3.1415926535f)) {
                    rt.lfoPhase -= static_cast<float>(2.0 * 3.1415926535f);
                }

                float modFreq = centreFreq * powf(2.0f, depth * 2.0f * sinf(rt.lfoPhase));
                modFreq = std::clamp(modFreq, 20.0f, static_cast<float>(sampleRate * 0.49));

                float g = -cosf(3.1415926535f * modFreq / static_cast<float>(sampleRate));

                float inL = dryL + fb * rt.phaserStateL[3];
                float inR = dryR + fb * rt.phaserStateR[3];

                for (int i = 0; i < 4; ++i) {
                    float xL = inL;
                    float yL = g * xL + rt.phaserStateL[i];
                    rt.phaserStateL[i] = xL - g * yL;
                    inL = yL;

                    float xR = inR;
                    float yR = g * xR + rt.phaserStateR[i];
                    rt.phaserStateR[i] = xR - g * yR;
                    inR = yR;
                }

                trackLeft[f] = 0.5f * (dryL + inL);
                trackRight[f] = 0.5f * (dryR + inR);
            }
        }
        if (deviceMeters != nullptr && node.meterSlot >= 0 && node.meterSlot < maxDeviceMeters) {
            float inputPeak = stereoBlockPeak(trackLeft, trackRight, framesToProcess);
            deviceMeters[node.meterSlot].gainReductionDb.store(0.0f, std::memory_order_relaxed);
            deviceMeters[node.meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
        }
        for (int f = 0; f < framesToProcess; ++f) {
            trackLeft[f] *= scratch.perFrameGain[f];
            trackRight[f] *= scratch.perFrameGain[f];
        }
        break;
    }
    case DeviceNodeKind::TrackGain: {
        for (int f = 0; f < framesToProcess; ++f) {
            trackLeft[f] *= scratch.perFrameGain[f];
            trackRight[f] *= scratch.perFrameGain[f];
        }
        break;
    }
    default:
        break;
    }
}

} // namespace audioapp::DeviceChainProcessor