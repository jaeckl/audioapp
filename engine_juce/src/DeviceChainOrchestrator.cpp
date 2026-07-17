#include "audioapp/DeviceChainOrchestrator.hpp"
#include "audioapp/devices/DevicePanelTypes.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/DeviceChainAutomationModulation.hpp"
#include "audioapp/instruments/PerNoteModulation.hpp"
#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"

using namespace audioapp::DeviceChainAutomationModulation;

// Include all modular processors
#include "audioapp/devices/processors/WavetableSynthProcessor.hpp"
#include "audioapp/devices/processors/TrackGainProcessor.hpp"
#include "audioapp/devices/processors/OscillatorProcessor.hpp"
#include "audioapp/devices/processors/SamplerProcessor.hpp"
#include "audioapp/devices/processors/SubtractiveSynthProcessor.hpp" // also defines BassSynthProcessor
#include "audioapp/devices/processors/PhaseModSynthProcessor.hpp"
#include "audioapp/devices/processors/KickProcessor.hpp"
#include "audioapp/devices/processors/SnareProcessor.hpp"
#include "audioapp/devices/processors/ClapProcessor.hpp"
#include "audioapp/devices/processors/CymbalProcessor.hpp"
#include "audioapp/devices/processors/CrashProcessor.hpp"
#include "audioapp/devices/processors/GateProcessor.hpp"
#include "audioapp/devices/processors/CompressorProcessor.hpp"
#include "audioapp/devices/processors/ExpanderProcessor.hpp"
#include "audioapp/devices/processors/LimiterProcessor.hpp"
#include "audioapp/devices/processors/DelayProcessor.hpp"
#include "audioapp/devices/processors/ReverbProcessor.hpp"
#include "audioapp/devices/processors/ChorusProcessor.hpp"
#include "audioapp/devices/processors/PhaserProcessor.hpp"
#include "audioapp/devices/processors/FilterProcessor.hpp"
#include "audioapp/devices/processors/FourBandEqProcessor.hpp"
#include "audioapp/devices/processors/FrequencyShifterProcessor.hpp"
#include "audioapp/devices/processors/ResonatorBankProcessor.hpp"
#include "audioapp/devices/processors/RoutingProcessor.hpp"
#include "audioapp/devices/processors/DrumMachineProcessor.hpp"
#include "audioapp/devices/processors/AnalysisProcessor.hpp"
#include "audioapp/devices/processors/ChainProcessor.hpp"
#include "audioapp/devices/processors/GranularProcessor.hpp"
#include "audioapp/devices/processors/StutterProcessor.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {

// =======================================================================
// Processor Factory — control thread only
// =======================================================================

using FactoryFn = DeviceProcessor* (*)(ProcessorArena&);
static const FactoryFn kProcessorFactories[] = {
    nullptr,  // Unknown = 0
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<OscillatorProcessor>(); },           // Oscillator = 1
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<SamplerProcessor>(); },             // Sampler = 2
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<SubtractiveSynthProcessor>(); },    // SubtractiveSynth = 3
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<KickProcessor>(); },                 // KickGenerator = 4
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<SnareProcessor>(); },                // SnareGenerator = 5
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<ClapProcessor>(); },                 // ClapGenerator = 6
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<CymbalProcessor>(); },               // CymbalGenerator = 7
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<CrashProcessor>(); },                // CrashGenerator = 8
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<GateProcessor>(); },                 // Gate = 9
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<CompressorProcessor>(); },           // Compressor = 10
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<ExpanderProcessor>(); },             // Expander = 11
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<LimiterProcessor>(); },              // Limiter = 12
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<TrackGainProcessor>(); },            // TrackGain = 13
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<BassSynthProcessor>(); },            // BassSynth = 14
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<PhaseModSynthProcessor>(); },        // PhaseModSynth = 15
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<DelayProcessor>(); },                // Delay = 16
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<ReverbProcessor>(); },               // Reverb = 17
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<ChorusProcessor>(); },               // Chorus = 18
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<PhaserProcessor>(); },               // Phaser = 19
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<FilterProcessor>(); },               // Filter = 20
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<FourBandEqProcessor>(); },           // FourBandEq = 21
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<FrequencyShifterProcessor>(); },     // FrequencyShifter = 22
    nullptr,  // Bitcrusher = 23 (handled inline)
    nullptr,  // Distortion = 24 (handled inline)
    nullptr,  // Tremolo = 25 (handled inline)
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<WavetableSynthProcessor>(); },        // WavetableSynth = 26
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<ResonatorBankProcessor>(); },          // ResonatorBank = 27
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<RoutingProcessor>(DeviceNodeKind::AudioReceiver); }, // 28
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<RoutingProcessor>(DeviceNodeKind::MidiReceiver); },  // 29
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<RoutingProcessor>(DeviceNodeKind::MidiDelay); },     // 30
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<DrumMachineProcessor>(); },                         // 31
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<AnalysisProcessor>(DeviceNodeKind::Oscilloscope); },
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<AnalysisProcessor>(DeviceNodeKind::SpectrumAnalyzer); },
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<AnalysisProcessor>(DeviceNodeKind::LoudnessMeter); },
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<AnalysisProcessor>(DeviceNodeKind::StereoImager); },
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<ChainProcessor>(); },
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<GranularProcessor>(); },
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<StutterProcessor>(); },
};
static constexpr size_t kNumFactories = sizeof(kProcessorFactories) / sizeof(kProcessorFactories[0]);

int buildProcessorChain(const DeviceNodePlayback* devices, int deviceCount,
                        ProcessorArena& arena) noexcept {
    arena.reset();
    if (devices == nullptr || deviceCount <= 0) return 0;

    int count = 0;
    for (int i = 0; i < deviceCount; ++i) {
        const auto& node = devices[i];
        DeviceProcessor* proc = nullptr;

        const size_t idx = static_cast<size_t>(node.kind);
        if (idx < kNumFactories) {
            auto factory = kProcessorFactories[idx];
            if (factory != nullptr) {
                proc = factory(arena);
            }
        }

        if (proc != nullptr) {
            proc->applyPlaybackNode(node);
            proc->meterSlot = node.meterSlot;
            proc->smoothedGain = node.gain;
            proc->smoothedPan = node.pan;
            proc->smoothedOutputMix = node.outputMix;
            proc->smoothedOutputWidth = node.outputWidth;
            proc->commonSmoothingReady = true;
            proc->voicePolicy = node.voicePolicy;
            proc->initParams(node.params);
            ++count;
        }
    }

    return count;
}

// =======================================================================
// Common parameter modulation
// =======================================================================

void DeviceChainOrchestrator::applyCommonGainPanLfo(
    DeviceChainScratch& scratch,
    uint16_t deviceIndex,
    uint64_t processorNodeId,
    int framesToProcess,
    const float* lfoValues, int lfoCount,
    const ModulationEdgePlayback* modEdges, int modEdgeCount,
    IModulator* const* modulators) noexcept {

    if (lfoValues != nullptr && lfoCount > 0 && modEdges != nullptr && modEdgeCount > 0) {
        for (int e = 0; e < modEdgeCount; ++e) {
            const auto& edge = modEdges[e];
            if (!playbackTargetMatches(edge.targetNodeId, edge.deviceIndex,
                                       processorNodeId, deviceIndex) ||
                edge.lfoId >= static_cast<uint16_t>(lfoCount)) continue;
            if (modulators != nullptr && modulatorUsesPerNoteClock(modulators[edge.lfoId])) {
                continue;
            }
            const uint16_t pid = edge.localParamId;
            if (pid == kEncodedCommonGain) {
                for (int f = 0; f < framesToProcess; ++f) {
                    const float lfoOut = lfoValues[edge.lfoId * framesToProcess + f];
                    scratch.perFrameGain[f] = std::clamp(
                        scratch.perFrameGain[f] + edge.amount * lfoOut, 0.0f, 1.0f);
                }
            } else if (pid == kEncodedCommonPan) {
                for (int f = 0; f < framesToProcess; ++f) {
                    const float lfoOut = lfoValues[edge.lfoId * framesToProcess + f];
                    scratch.perFramePan[f] = std::clamp(
                        scratch.perFramePan[f] + edge.amount * lfoOut, 0.0f, 1.0f);
                }
            }
        }
    }
}

static bool evaluateCommonBypass(
    bool baseBypassed,
    uint16_t deviceIndex,
    uint64_t processorNodeId,
    double playheadBeat,
    int framesToProcess,
    const AutomationClipPlayback* automationClips,
    int automationClipCount,
    const float* lfoValues,
    int lfoCount,
    const ModulationEdgePlayback* modEdges,
    int modEdgeCount,
    IModulator* const* modulators) noexcept {

    float bypassValue = baseBypassed ? 1.0f : 0.0f;

    if (automationClips != nullptr && automationClipCount > 0) {
        for (int a = 0; a < automationClipCount; ++a) {
            const auto& ac = automationClips[a];
            if (!playbackTargetMatches(ac.targetNodeId, ac.deviceIndex,
                                       processorNodeId, deviceIndex) ||
                ac.localParamId != kEncodedCommonBypass) {
                continue;
            }
            float beatInClip = 0.0f;
            if (!automationBeatInClip(ac, playheadBeat, beatInClip)) {
                continue;
            }
            bypassValue = evaluateAutomationEnvelope(
                ac.points, ac.pointCount, beatInClip);
        }
    }

    if (lfoValues != nullptr && lfoCount > 0 &&
        modEdges != nullptr && modEdgeCount > 0) {
        const int lfoFrame = std::max(0, framesToProcess / 2);
        for (int e = 0; e < modEdgeCount; ++e) {
            const auto& edge = modEdges[e];
            if (!playbackTargetMatches(edge.targetNodeId, edge.deviceIndex,
                                       processorNodeId, deviceIndex) ||
                edge.localParamId != kEncodedCommonBypass ||
                edge.lfoId >= static_cast<uint16_t>(lfoCount)) {
                continue;
            }
            if (modulators != nullptr &&
                modulatorUsesPerNoteClock(modulators[edge.lfoId])) {
                continue;
            }
            const float lfoOut = lfoValues[edge.lfoId * framesToProcess + lfoFrame];
            bypassValue += edge.amount * lfoOut;
        }
    }

    return std::clamp(bypassValue, 0.0f, 1.0f) >= 0.5f;
}

// Fused logical InputAdapter. It owns universal strip targets and their
// block-ramped values; device-specific input controls remain in the DSP until
// their parameter families are migrated to generic adapter policies.
static void runFusedInputAdapter(DeviceProcessor& processor,
                                 DeviceChainScratch& scratch,
                                 int numFrames) noexcept {
    if (!processor.commonSmoothingReady) {
        processor.smoothedGain = processor.gain;
        processor.smoothedPan = processor.pan;
        processor.smoothedOutputMix = processor.outputMix;
        processor.smoothedOutputWidth = processor.outputWidth;
        processor.commonSmoothingReady = true;
    }
    const float gainStep = (processor.gain - processor.smoothedGain) /
                           static_cast<float>(std::max(1, numFrames));
    const float panStep = (processor.pan - processor.smoothedPan) /
                          static_cast<float>(std::max(1, numFrames));
    for (int frame = 0; frame < numFrames; ++frame) {
        scratch.perFrameGain[frame] = processor.smoothedGain +
            gainStep * static_cast<float>(frame + 1);
        scratch.perFramePan[frame] = processor.smoothedPan +
            panStep * static_cast<float>(frame + 1);
    }
    processor.smoothedGain = processor.gain;
    processor.smoothedPan = processor.pan;
}

// Legacy inputGain is semantically an InputAdapter trim for these device
// families. Neutralising it in the per-block parameter copy lets the DSP stay
// unchanged while moving the actual multiply into the shared fused adapter.
static float extractInputAdapterTrim(DeviceVariantParams& params) noexcept {
    return std::visit([](auto& value) noexcept -> float {
        if constexpr (requires { value.inputGain; }) {
            const float trim = std::clamp(value.inputGain, 0.0f, 1.0f);
            value.inputGain = 1.0f;
            return trim;
        }
        return 1.0f;
    }, params);
}

static void runFusedInputTrimAdapter(DeviceProcessor& processor,
                                     DeviceVariantParams& params,
                                     AudioBlock& block,
                                     int numFrames) noexcept {
    if (!processor.executionPlan.inputAdapterOwnsTrim) return;
    const float trim = extractInputAdapterTrim(params);
    if (trim != 1.0f) {
        applyStereoScalarGain(block.channelL, block.channelR, numFrames, trim);
    }
}

// Fused logical OutputAdapter. It is deliberately in-place: dry data lives in
// preallocated scratch and no intermediate graph buffers are introduced.
static void runFusedOutputAdapter(DeviceProcessor& processor,
                                  DeviceNodeKind nodeKind,
                                  AudioBlock& block,
                                  DeviceChainScratch& scratch,
                                  int numFrames) noexcept {
    const float outputMixStep = (processor.outputMix - processor.smoothedOutputMix) /
                                static_cast<float>(std::max(1, numFrames));
    if (processor.outputMix != 1.0f || processor.smoothedOutputMix != 1.0f) {
        for (int frame = 0; frame < numFrames; ++frame) {
            const float mix = processor.smoothedOutputMix +
                              outputMixStep * static_cast<float>(frame + 1);
            block.channelL[frame] = scratch.tempStereoL[frame] * (1.0f - mix) +
                                    block.channelL[frame] * mix;
            block.channelR[frame] = scratch.tempStereoR[frame] * (1.0f - mix) +
                                    block.channelR[frame] * mix;
        }
    }
    processor.smoothedOutputMix = processor.outputMix;

    const float outputWidthStep = (processor.outputWidth - processor.smoothedOutputWidth) /
                                  static_cast<float>(std::max(1, numFrames));
    if (processor.outputWidth != 1.0f || processor.smoothedOutputWidth != 1.0f) {
        for (int frame = 0; frame < numFrames; ++frame) {
            const float width = processor.smoothedOutputWidth +
                                outputWidthStep * static_cast<float>(frame + 1);
            const float mid = (block.channelL[frame] + block.channelR[frame]) * 0.5f;
            const float side = (block.channelL[frame] - block.channelR[frame]) * 0.5f * width;
            block.channelL[frame] = mid + side;
            block.channelR[frame] = mid - side;
        }
    }
    processor.smoothedOutputWidth = processor.outputWidth;

    if (!isInstrumentDeviceNodeKind(nodeKind) && nodeKind != DeviceNodeKind::TrackGain) {
        StereoOutputPanel::applyInPlace(block, numFrames, scratch.perFrameGain);
    }
}

// =======================================================================
// Main orchestrator loop — virtual dispatch instead of switch
// =======================================================================

void DeviceChainOrchestrator::processChain(Context& ctx,
                                           int startDeviceIndex,
                                           int exclusiveEndDeviceIndex) noexcept {
    auto& s = ctx.scratch;
    s.perNoteModCache.reset();
    const int numFrames = ctx.numFrames > kScratchFrames ? kScratchFrames : ctx.numFrames;
    const int arenaSize = ctx.arena.size();
    const int start = std::max(0, startDeviceIndex);
    const int end = exclusiveEndDeviceIndex < 0
        ? arenaSize
        : std::min(exclusiveEndDeviceIndex, arenaSize);

    const double beatsPerFrame =
        (static_cast<double>(std::max(ctx.bpm, 1)) / 60.0) / ctx.sampleRate;

    constexpr int kMaxActiveNotes = 128;
    MidiPlaybackNote activeNotes[kMaxActiveNotes];
    int activeNoteCount = std::min(ctx.noteCount, kMaxActiveNotes);
    if (ctx.notes != nullptr && activeNoteCount > 0) {
        std::copy(ctx.notes, ctx.notes + activeNoteCount, activeNotes);
    }

    auto captureAudioSources = [&](int deviceIndex) noexcept {
        if (ctx.graph == nullptr || ctx.graphAudioLeft == nullptr ||
            ctx.graphAudioRight == nullptr || ctx.graphAudioStride <= 0) return;
        for (int edgeIndex = 0; edgeIndex < ctx.graph->audioEdgeCount; ++edgeIndex) {
            const auto& edge = ctx.graph->audioEdges[static_cast<size_t>(edgeIndex)];
            if (edge.sourceTrack != ctx.graphTrackIndex || edge.sourceDevice != deviceIndex) continue;
            if (edge.feedback) {
                if (ctx.graphFeedbackWriteLeft == nullptr || ctx.graphFeedbackWriteRight == nullptr ||
                    ctx.graphFeedbackStride <= 0) continue;
                const int slot = edge.feedbackBufferSlot;
                float* tapLeft = ctx.graphFeedbackWriteLeft + slot * ctx.graphFeedbackStride;
                float* tapRight = ctx.graphFeedbackWriteRight + slot * ctx.graphFeedbackStride;
                std::copy(ctx.trackLeft, ctx.trackLeft + numFrames, tapLeft);
                std::copy(ctx.trackRight, ctx.trackRight + numFrames, tapRight);
                continue;
            }
            const int slot = edge.bufferSlot;
            float* tapLeft = ctx.graphAudioLeft + slot * ctx.graphAudioStride;
            float* tapRight = ctx.graphAudioRight + slot * ctx.graphAudioStride;
            std::copy(ctx.trackLeft, ctx.trackLeft + numFrames, tapLeft);
            std::copy(ctx.trackRight, ctx.trackRight + numFrames, tapRight);
        }
    };

    auto captureMidiSources = [&](int deviceIndex) noexcept {
        if (ctx.graph == nullptr || ctx.graphMidiEdgeNotes == nullptr ||
            ctx.graphMidiEdgeCounts == nullptr || ctx.graphMidiEdgeStride <= 0) return;
        for (int edgeIndex = 0; edgeIndex < ctx.graph->midiEdgeCount; ++edgeIndex) {
            const auto& edge = ctx.graph->midiEdges[static_cast<size_t>(edgeIndex)];
            if (edge.sourceTrack != ctx.graphTrackIndex || edge.sourceDevice != deviceIndex) continue;
            const int count = std::min(activeNoteCount, ctx.graphMidiEdgeStride);
            const int slot = edge.bufferSlot;
            auto* tap = ctx.graphMidiEdgeNotes + slot * ctx.graphMidiEdgeStride;
            std::copy(activeNotes, activeNotes + count, tap);
            ctx.graphMidiEdgeCounts[slot] = count;
        }
    };

    const bool useCompiledOrder = ctx.compiledDeviceOrder != nullptr &&
        ctx.compiledDeviceOrderCount > 0;
    const int iterationCount = useCompiledOrder
        ? ctx.compiledDeviceOrderCount
        : end - start;
    for (int iteration = 0; iteration < iterationCount; ++iteration) {
        const int deviceIndex = useCompiledOrder
            ? static_cast<int>(ctx.compiledDeviceOrder[iteration])
            : start + iteration;
        if (deviceIndex < start || deviceIndex >= end) continue;
        auto* proc = ctx.arena.get(deviceIndex);
        if (proc == nullptr) continue;
        // The logical device subgraph is InputAdapter -> DSP -> OutputAdapter.
        // The plan is fused, so this check adds no buffers or dispatch layers.
        if (!proc->executionPlan.valid()) continue;
        const uint16_t di = static_cast<uint16_t>(deviceIndex);
        const bool effectiveBypass = evaluateCommonBypass(
            proc->bypassed,
            di,
            proc->stableProcessorNodeId,
            ctx.playheadStartBeat,
            numFrames,
            ctx.automationClips,
            ctx.automationClipCount,
            ctx.lfoValues,
            ctx.lfoCount,
            ctx.modEdges,
            ctx.modEdgeCount,
            ctx.modulators);
        if (effectiveBypass) {
            captureAudioSources(deviceIndex);
            captureMidiSources(deviceIndex);
            continue;
        }

        runFusedInputAdapter(*proc, s, numFrames);

        const DeviceNodeKind nodeKind = proc->kind();

        if (nodeKind == DeviceNodeKind::MidiReceiver && ctx.graph != nullptr &&
            ctx.graphMidiNotes != nullptr && ctx.graphMidiCounts != nullptr) {
            for (int edgeIndex = 0; edgeIndex < ctx.graph->midiEdgeCount; ++edgeIndex) {
                const auto& edge = ctx.graph->midiEdges[static_cast<size_t>(edgeIndex)];
                if (edge.destinationTrack != ctx.graphTrackIndex ||
                    edge.destinationDevice != deviceIndex) continue;
                const bool trackInput = edge.sourceDevice == kGraphTrackMidiInput;
                const int source = edge.sourceTrack;
                const auto* sourceNotes = trackInput
                    ? ctx.graphMidiNotes + source * ctx.graphMidiStride
                    : ctx.graphMidiEdgeNotes + edge.bufferSlot * ctx.graphMidiEdgeStride;
                const int sourceCount = trackInput
                    ? ctx.graphMidiCounts[source]
                    : ctx.graphMidiEdgeCounts[edge.bufferSlot];
                for (int i = 0; i < sourceCount && activeNoteCount < kMaxActiveNotes; ++i) {
                    activeNotes[activeNoteCount++] = sourceNotes[i];
                }
            }
        }

        if (nodeKind == DeviceNodeKind::MidiDelay) {
            const auto params = std::get<MidiDelayParams>(proc->storedParams());
            const double delayBeats = params.mode >= 0.5f
                ? static_cast<double>(params.division)
                : static_cast<double>(params.seconds) * static_cast<double>(std::max(ctx.bpm, 1)) / 60.0;
            for (int i = 0; i < activeNoteCount; ++i) {
                activeNotes[i].noteStartBeat += delayBeats;
                activeNotes[i].clipLengthBeats += delayBeats;
            }
        }

        // nodeNeedsSubBlocks only uses deviceIndex/clips/edges; pass a dummy node
        const DeviceNodePlayback dummyNode{};
        const bool needsSubBlocks = nodeNeedsSubBlocks(
            dummyNode, deviceIndex,
            ctx.automationClips, ctx.automationClipCount,
            ctx.modEdges, ctx.modEdgeCount);

        // Build ProcessContext
        ProcessContext pc(s);
        pc.lfoValues = ctx.lfoValues;
        pc.lfoCount = ctx.lfoCount;
        pc.modEdges = ctx.modEdges;
        pc.modEdgeCount = ctx.modEdgeCount;
        pc.automationClips = ctx.automationClips;
        pc.automationClipCount = ctx.automationClipCount;
        pc.notes = activeNotes;
        pc.noteCount = activeNoteCount;
        pc.playheadBeat = ctx.playheadStartBeat;
        pc.bpm = ctx.bpm;
        pc.sampleRate = ctx.sampleRate;
        pc.suppressInstruments = ctx.suppressInstruments;
        pc.voicePolicy = proc->voicePolicy;
        pc.deviceMeters = ctx.deviceMeters;
        pc.maxDeviceMeters = ctx.maxDeviceMeters;
        pc.meterSlotSubscribed = ctx.meterSlotSubscribed;
        pc.deviceIndex = deviceIndex;
        pc.needsSubBlocks = needsSubBlocks;
        pc.wavetableBank = ctx.wavetableBank;
        pc.modulators = ctx.modulators;
        pc.retriggerGeneration = ctx.retriggerGeneration;
        pc.numFrames = numFrames;

        // --- Timeline automation ---
        auto modulatedParams = proc->storedParams(); // start from processor's own params
        if (ctx.automationClips != nullptr && ctx.automationClipCount > 0) {
            for (int a = 0; a < ctx.automationClipCount; ++a) {
                const auto& ac = ctx.automationClips[a];
                if (!playbackTargetMatches(ac.targetNodeId, ac.deviceIndex,
                                           proc->stableProcessorNodeId, di)) continue;

                if (ac.localParamId == kEncodedCommonGain ||
                    ac.localParamId == kEncodedCommonPan) {
                    const bool isGain = ac.localParamId == kEncodedCommonGain;
                    for (int f = 0; f < numFrames; ++f) {
                        const double beat = ctx.playheadStartBeat + static_cast<double>(f) * beatsPerFrame;
                        float beatInClip = 0.0f;
                        if (!automationBeatInClip(ac, beat, beatInClip)) {
                            continue;
                        }
                        const float val = evaluateAutomationEnvelope(ac.points, ac.pointCount, beatInClip);
                        if (isGain) s.perFrameGain[f] = val;
                        else s.perFramePan[f] = val;
                    }
                } else if (ac.localParamId == kEncodedCommonBypass) {
                    continue;
                } else if (!needsSubBlocks || !handlesOwnModulation(nodeKind)) {
                    const double beat = ctx.playheadStartBeat;
                    float beatInClip = 0.0f;
                    if (!automationBeatInClip(ac, beat, beatInClip)) continue;
                    const float val = evaluateAutomationEnvelope(ac.points, ac.pointCount, beatInClip);
                    applyAutomationValue(modulatedParams, nodeKind, ac.localParamId, val);
                }
            }
        }

        // --- LFO modulation (DSP params) ---
        if (ctx.lfoValues != nullptr && ctx.lfoCount > 0 &&
            ctx.modEdges != nullptr && ctx.modEdgeCount > 0) {
            for (int e = 0; e < ctx.modEdgeCount; ++e) {
                const auto& edge = ctx.modEdges[e];
                if (!playbackTargetMatches(edge.targetNodeId, edge.deviceIndex,
                                           proc->stableProcessorNodeId, di) ||
                    edge.lfoId >= static_cast<uint16_t>(ctx.lfoCount)) continue;
                const uint16_t pid = edge.localParamId;
                if (pid == kEncodedCommonGain ||
                    pid == kEncodedCommonPan ||
                    pid == kEncodedCommonBypass) continue;
                if (!needsSubBlocks || !handlesOwnModulation(nodeKind)) {
                    if (ctx.modulators != nullptr
                        && modulatorUsesPerNoteClock(ctx.modulators[edge.lfoId])) {
                        continue;
                    }
                    const int lfoFrame = numFrames / 2;
                    const float lfoOut = ctx.lfoValues[edge.lfoId * numFrames + lfoFrame];
                    const float modAmount = edge.amount * lfoOut;
                    std::visit([&](auto& params) {
                        applyModulation(params, modAmount, pid);
                    }, modulatedParams);
                }
            }
        }

        // --- Per-frame gain/pan LFO modulation ---
        applyCommonGainPanLfo(s, di, proc->stableProcessorNodeId, numFrames,
                              ctx.lfoValues, ctx.lfoCount,
                              ctx.modEdges, ctx.modEdgeCount,
                              ctx.modulators);

        // --- Process device via virtual dispatch ---
        pc.modulatedParams = &modulatedParams;
        AudioBlock block{ctx.trackLeft, ctx.trackRight, numFrames};

        if (nodeKind == DeviceNodeKind::AudioReceiver && ctx.graph != nullptr &&
            ctx.graphAudioLeft != nullptr && ctx.graphAudioRight != nullptr) {
            const float mix = std::get<RoutingParams>(modulatedParams).routeMix;
            for (int edgeIndex = 0; edgeIndex < ctx.graph->audioEdgeCount; ++edgeIndex) {
                const auto& edge = ctx.graph->audioEdges[static_cast<size_t>(edgeIndex)];
                if (edge.destinationTrack != ctx.graphTrackIndex ||
                    edge.destinationDevice != deviceIndex) continue;
                const bool useFeedback = edge.feedback && ctx.graphFeedbackReadLeft != nullptr &&
                    ctx.graphFeedbackReadRight != nullptr && ctx.graphFeedbackStride > 0;
                const float* sourceLeft = useFeedback
                    ? ctx.graphFeedbackReadLeft + edge.feedbackBufferSlot * ctx.graphFeedbackStride
                    : ctx.graphAudioLeft + edge.bufferSlot * ctx.graphAudioStride;
                const float* sourceRight = useFeedback
                    ? ctx.graphFeedbackReadRight + edge.feedbackBufferSlot * ctx.graphFeedbackStride
                    : ctx.graphAudioRight + edge.bufferSlot * ctx.graphAudioStride;
                if (edge.latencyCompensationSamples == 0 || ctx.graphLatencyLines == nullptr) {
                    for (int frame = 0; frame < numFrames; ++frame) {
                        block.channelL[frame] = block.channelL[frame] * (1.0f - mix) + sourceLeft[frame] * mix;
                        block.channelR[frame] = block.channelR[frame] * (1.0f - mix) + sourceRight[frame] * mix;
                    }
                    continue;
                }
                auto& delay = ctx.graphLatencyLines[edge.bufferSlot];
                const uint16_t requestedDelay = std::min<uint16_t>(
                    edge.latencyCompensationSamples, kMaxProcessorGraphLatencySamples);
                if (delay.delaySamples != requestedDelay) {
                    // A route shape changes only with an immutable graph swap.
                    // Reset lazily here so the control thread never mutates
                    // state owned by the audio callback.
                    delay.left.fill(0.0f);
                    delay.right.fill(0.0f);
                    delay.delaySamples = requestedDelay;
                    delay.writePosition = 0;
                }
                for (int frame = 0; frame < numFrames; ++frame) {
                    const uint16_t position = delay.writePosition;
                    const float delayedLeft = delay.left[position];
                    const float delayedRight = delay.right[position];
                    delay.left[position] = sourceLeft[frame];
                    delay.right[position] = sourceRight[frame];
                    delay.writePosition = static_cast<uint16_t>(
                        (position + 1) % requestedDelay);
                    block.channelL[frame] = block.channelL[frame] * (1.0f - mix) + delayedLeft * mix;
                    block.channelR[frame] = block.channelR[frame] * (1.0f - mix) + delayedRight * mix;
                }
            }
        }

        // Save dry signal for outputMix blend
        std::copy(block.channelL, block.channelL + numFrames, s.tempStereoL);
        std::copy(block.channelR, block.channelR + numFrames, s.tempStereoR);

        runFusedInputTrimAdapter(*proc, modulatedParams, block, numFrames);

        proc->process(block, pc);

        runFusedOutputAdapter(*proc, nodeKind, block, s, numFrames);
        captureAudioSources(deviceIndex);
        captureMidiSources(deviceIndex);
    }
}

void resetPlaybackStateInArena(ProcessorArena& arena) noexcept {
    for (int i = 0; i < arena.size(); ++i) {
        if (DeviceProcessor* proc = arena.get(i)) {
            proc->resetPlaybackState();
        }
    }
}

void resetInstrumentPlaybackStateInArena(ProcessorArena& arena) noexcept {
    for (int i = 0; i < arena.size(); ++i) {
        DeviceProcessor* proc = arena.get(i);
        if (proc != nullptr && isInstrumentDeviceNodeKind(proc->kind())) {
            proc->resetPlaybackState();
        }
    }
}

} // namespace audioapp
