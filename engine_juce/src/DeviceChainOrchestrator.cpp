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
#include "audioapp/devices/processors/DedicatedPercussionProcessors.hpp"
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
#include "audioapp/devices/processors/SplitProcessor.hpp"

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
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<HihatProcessor>(); },                // HihatGenerator = 7
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
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<RideProcessor>(); },
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<TomProcessor>(); },
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<RimshotProcessor>(); },
    [](ProcessorArena& a) -> DeviceProcessor* { return a.template emplace<SplitProcessor>(); },  // Split
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
            bypassValue = evaluateAutomationEnvelopeCached(ac, beatInClip);
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
static CommonControlBlock prepareCommonControls(
    DeviceProcessor& processor,
    DeviceChainScratch& scratch,
    int numFrames,
    bool dynamicGain,
    bool dynamicPan) noexcept {
    if (!processor.commonSmoothingReady) {
        processor.smoothedGain = processor.gain;
        processor.smoothedPan = processor.pan;
        processor.smoothedOutputMix = processor.outputMix;
        processor.smoothedOutputWidth = processor.outputWidth;
        processor.commonSmoothingReady = true;
    }

    CommonControlBlock controls;
    controls.numFrames = numFrames;
    controls.gainStart = processor.smoothedGain;
    controls.gainEnd = processor.gain;
    controls.panStart = processor.smoothedPan;
    controls.panEnd = processor.pan;
    controls.gainMode = dynamicGain
        ? CommonControlMode::Dynamic
        : (processor.gain != processor.smoothedGain
            ? CommonControlMode::Ramp : CommonControlMode::Constant);
    controls.panMode = dynamicPan
        ? CommonControlMode::Dynamic
        : (processor.pan != processor.smoothedPan
            ? CommonControlMode::Ramp : CommonControlMode::Constant);

    const bool writeGain = dynamicGain;
    const bool writePan = dynamicPan;
    const float inverseFrames = 1.0f / static_cast<float>(std::max(1, numFrames));
    if (writeGain) {
        const float gainStep = (controls.gainEnd - controls.gainStart) * inverseFrames;
        for (int frame = 0; frame < numFrames; ++frame)
            scratch.perFrameGain[frame] = controls.gainStart +
                gainStep * static_cast<float>(frame + 1);
        if (dynamicGain) controls.gainValues = scratch.perFrameGain;
    }
    if (writePan) {
        const float panStep = (controls.panEnd - controls.panStart) * inverseFrames;
        for (int frame = 0; frame < numFrames; ++frame)
            scratch.perFramePan[frame] = controls.panStart +
                panStep * static_cast<float>(frame + 1);
        if (dynamicPan) controls.panValues = scratch.perFramePan;
    }
    processor.smoothedGain = processor.gain;
    processor.smoothedPan = processor.pan;
    return controls;
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
                                  const CommonControlBlock& commonControls,
                                  int numFrames) noexcept {
    const float outputMixStep = (processor.outputMix - processor.smoothedOutputMix) /
                                static_cast<float>(std::max(1, numFrames));
    if (processor.outputMix != 1.0f || processor.smoothedOutputMix != 1.0f) {
        if (processor.outputMix == processor.smoothedOutputMix) {
            const float mix = processor.outputMix;
            mixDryWet(block.channelL, scratch.tempStereoL, numFrames, mix);
            mixDryWet(block.channelR, scratch.tempStereoR, numFrames, mix);
        } else {
            for (int frame = 0; frame < numFrames; ++frame) {
                const float mix = processor.smoothedOutputMix +
                                  outputMixStep * static_cast<float>(frame + 1);
                block.channelL[frame] = scratch.tempStereoL[frame] * (1.0f - mix) +
                                        block.channelL[frame] * mix;
                block.channelR[frame] = scratch.tempStereoR[frame] * (1.0f - mix) +
                                        block.channelR[frame] * mix;
            }
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
        if (commonControls.gainMode == CommonControlMode::Constant) {
            applyStereoScalarGain(block.channelL, block.channelR, numFrames,
                                  commonControls.gainEnd);
        } else {
            const float* gains = commonControls.gainValues;
            if (commonControls.gainMode == CommonControlMode::Ramp) {
                for (int frame = 0; frame < numFrames; ++frame)
                    scratch.perFrameGain[frame] = commonControls.gainAt(frame);
                gains = scratch.perFrameGain;
            }
            multiplyPerFrameGain(block.channelL, numFrames, gains);
            multiplyPerFrameGain(block.channelR, numFrames, gains);
        }
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
            const int count = std::min({activeNoteCount, ctx.graphMidiEdgeStride,
                                        static_cast<int>(edge.eventCapacity)});
            const int slot = edge.bufferSlot;
            auto* tap = ctx.graphMidiEdgeNotes + slot * ctx.graphMidiEdgeStride;
            std::copy(activeNotes, activeNotes + count, tap);
            ctx.graphMidiEdgeCounts[slot] = count;
        }
    };

    const auto captureAudioGraphTaps = [&](uint64_t nodeId) noexcept {
        if (ctx.tapGraph == nullptr || ctx.graphTapRuntimes == nullptr ||
            ctx.graphTapRuntimeCount <= 0) return;
        for (int tapIndex = 0; tapIndex < ctx.tapGraph->tapCount; ++tapIndex) {
            const auto& tap = ctx.tapGraph->taps[static_cast<size_t>(tapIndex)];
            if (tap.kind == GraphTapKind::MidiRecorder ||
                tap.sourceOutputNodeId != nodeId ||
                tap.runtimeSlot >= ctx.graphTapRuntimeCount) continue;
            processGraphTap(ctx.graphTapRuntimes[tap.runtimeSlot], tap,
                            ctx.trackLeft, ctx.trackRight, numFrames,
                            ctx.sampleRate);
        }
    };

    const auto captureMidiGraphTaps = [&](uint64_t outputNodeId) noexcept {
        if (outputNodeId == 0 || ctx.tapGraph == nullptr ||
            ctx.graphTapRuntimes == nullptr || ctx.graphTapRuntimeCount <= 0) return;
        for (int tapIndex = 0; tapIndex < ctx.tapGraph->tapCount; ++tapIndex) {
            const auto& tap = ctx.tapGraph->taps[static_cast<size_t>(tapIndex)];
            if (tap.kind != GraphTapKind::MidiRecorder ||
                tap.sourceOutputNodeId != outputNodeId ||
                tap.runtimeSlot >= ctx.graphTapRuntimeCount) continue;
            processGraphMidiTap(ctx.graphTapRuntimes[tap.runtimeSlot], tap,
                                activeNotes, activeNoteCount);
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
        captureAudioGraphTaps(proc->stableInputNodeId);
        const auto* targetAutomation =
            ctx.automationClips != nullptr && proc->automationSpanCount > 0
                ? ctx.automationClips + proc->automationSpanOffset : nullptr;
        const int targetAutomationCount = targetAutomation != nullptr
            ? proc->automationSpanCount : 0;
        const auto* targetModEdges =
            ctx.modEdges != nullptr && proc->modulationSpanCount > 0
                ? ctx.modEdges + proc->modulationSpanOffset : nullptr;
        const int targetModEdgeCount = targetModEdges != nullptr
            ? proc->modulationSpanCount : 0;
        const uint16_t di = static_cast<uint16_t>(deviceIndex);
        const DeviceNodeKind nodeKind = proc->kind();
        const bool automationBypass = evaluateCommonBypass(
            proc->bypassed,
            di,
            proc->stableProcessorNodeId,
            ctx.playheadStartBeat,
            numFrames,
            targetAutomation,
            targetAutomationCount,
            nullptr,
            0,
            nullptr,
            0,
            nullptr);
        const bool effectiveBypass = evaluateCommonBypass(
            proc->bypassed,
            di,
            proc->stableProcessorNodeId,
            ctx.playheadStartBeat,
            numFrames,
            targetAutomation,
            targetAutomationCount,
            ctx.lfoValues,
            ctx.lfoCount,
            targetModEdges,
            targetModEdgeCount,
            ctx.modulators);
        proc->publishPresentationParameter(
            kEncodedCommonBypass,
            automationBypass ? 1.0f : 0.0f,
            effectiveBypass ? 1.0f : 0.0f);
        if (effectiveBypass) {
            captureAudioGraphTaps(proc->stableProcessorNodeId);
            captureAudioGraphTaps(proc->stableOutputNodeId);
            captureMidiGraphTaps(proc->stableOutputNodeId);
            captureAudioSources(deviceIndex);
            captureMidiSources(deviceIndex);
            continue;
        }

        CommonControlBlock commonControls = prepareCommonControls(
            *proc, s, numFrames,
            proc->hasCommonGainAutomation || proc->hasCommonGainModulation,
            proc->hasCommonPanAutomation || proc->hasCommonPanModulation);

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

        const bool needsSubBlocks = nodeNeedsSubBlocks(
            deviceIndex,
            targetAutomation, targetAutomationCount,
            targetModEdges, targetModEdgeCount);

        // Build ProcessContext
        ProcessContext pc(s);
        pc.lfoValues = ctx.lfoValues;
        pc.lfoCount = ctx.lfoCount;
        const bool isContainer = nodeKind == DeviceNodeKind::Chain ||
                                 nodeKind == DeviceNodeKind::DrumMachine ||
                                 nodeKind == DeviceNodeKind::Split;
        pc.modEdges = isContainer ? ctx.modEdges : targetModEdges;
        pc.modEdgeCount = isContainer ? ctx.modEdgeCount : targetModEdgeCount;
        pc.automationClips = isContainer ? ctx.automationClips : targetAutomation;
        pc.automationClipCount = isContainer ? ctx.automationClipCount
                                             : targetAutomationCount;
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
        pc.tapGraph = ctx.tapGraph;
        pc.graphTapRuntimes = ctx.graphTapRuntimes;
        pc.graphTapRuntimeCount = ctx.graphTapRuntimeCount;
        pc.deviceIndex = deviceIndex;
        pc.needsSubBlocks = needsSubBlocks;
        pc.wavetableBank = ctx.wavetableBank;
        pc.modulators = ctx.modulators;
        pc.retriggerGeneration = ctx.retriggerGeneration;
        pc.numFrames = numFrames;
        pc.commonControls = commonControls;

        // --- Timeline automation ---
        auto modulatedParams = proc->storedParams(); // start from processor's own params
        proc->applyCompiledParameterSmoothing(modulatedParams, numFrames, ctx.sampleRate);
        struct FinalParameterTarget {
            uint16_t parameterId = 0xffff;
            float automatedValue = 0.0f;
            float modulationAmount = 0.0f;
            float compiledBaseValue = 0.0f;
            bool hasAutomation = false;
            bool hasCompiledBaseValue = false;
        };
        std::array<FinalParameterTarget, kMaxCompiledParametersPerProcessor> finalTargets{};
        int finalTargetCount = 0;
        const auto findFinalTarget = [&](uint16_t parameterId) noexcept
            -> FinalParameterTarget* {
            for (int index = 0; index < finalTargetCount; ++index)
                if (finalTargets[static_cast<size_t>(index)].parameterId == parameterId)
                    return &finalTargets[static_cast<size_t>(index)];
            return nullptr;
        };
        if (targetAutomation != nullptr && targetAutomationCount > 0) {
            for (int a = 0; a < targetAutomationCount; ++a) {
                const auto& ac = targetAutomation[a];
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
                        const float val = evaluateAutomationEnvelopeCached(ac, beatInClip);
                        if (isGain) s.perFrameGain[f] = val;
                        else s.perFramePan[f] = val;
                    }
                } else if (ac.localParamId == kEncodedCommonBypass) {
                    continue;
                } else {
                    // Processors that render automation per frame still use
                    // their local sample-accurate evaluator for DSP. Evaluate
                    // the block midpoint here as the one device-wide value
                    // exposed to presentation monitoring.
                    const bool ownsTimeVaryingControls =
                        needsSubBlocks && handlesOwnModulation(nodeKind);
                    const double beat = ctx.playheadStartBeat +
                        (ownsTimeVaryingControls
                            ? static_cast<double>(numFrames / 2) * beatsPerFrame
                            : 0.0);
                    float beatInClip = 0.0f;
                    if (!automationBeatInClip(ac, beat, beatInClip)) continue;
                    const float val = evaluateAutomationEnvelopeCached(ac, beatInClip);
                    auto* target = findFinalTarget(ac.localParamId);
                    if (target == nullptr && finalTargetCount <
                            static_cast<int>(finalTargets.size())) {
                        target = &finalTargets[static_cast<size_t>(finalTargetCount++)];
                        target->parameterId = ac.localParamId;
                    }
                    if (target != nullptr) {
                        target->automatedValue = val;
                        target->hasAutomation = true;
                    }
                }
            }
        }

        // --- LFO modulation (DSP params) ---
        if (ctx.lfoValues != nullptr && ctx.lfoCount > 0 &&
            targetModEdges != nullptr && targetModEdgeCount > 0) {
            for (int e = 0; e < targetModEdgeCount; ++e) {
                const auto& edge = targetModEdges[e];
                if (!playbackTargetMatches(edge.targetNodeId, edge.deviceIndex,
                                           proc->stableProcessorNodeId, di) ||
                    edge.lfoId >= static_cast<uint16_t>(ctx.lfoCount)) continue;
                const uint16_t pid = edge.localParamId;
                if (pid == kEncodedCommonGain ||
                    pid == kEncodedCommonPan ||
                    pid == kEncodedCommonBypass) continue;
                if (ctx.modulators != nullptr
                    && modulatorUsesPerNoteClock(ctx.modulators[edge.lfoId])) {
                    // A per-note modulator has one value per active voice, so
                    // it deliberately has no single device-wide knob value.
                    continue;
                }
                const int lfoFrame = numFrames / 2;
                const float lfoOut = ctx.lfoValues[edge.lfoId * numFrames + lfoFrame];
                const float modAmount = edge.amount * lfoOut;
                auto* target = findFinalTarget(pid);
                if (target == nullptr && finalTargetCount <
                        static_cast<int>(finalTargets.size())) {
                    target = &finalTargets[static_cast<size_t>(finalTargetCount++)];
                    target->parameterId = pid;
                }
                if (target != nullptr) {
                    target->modulationAmount += modAmount;
                    if (!target->hasCompiledBaseValue) {
                        target->compiledBaseValue = edge.baseValue;
                        target->hasCompiledBaseValue = true;
                    }
                }
            }
        }

        // Absolute automation and additive modulation meet once here. This
        // avoids applying/smoothing the same target independently per source.
        for (int index = 0; index < finalTargetCount; ++index) {
            const auto& target = finalTargets[static_cast<size_t>(index)];
            const bool ownsTimeVaryingControls =
                needsSubBlocks && handlesOwnModulation(nodeKind);
            if (!target.hasAutomation) {
                if (!ownsTimeVaryingControls) {
                    std::visit([&](auto& params) {
                        applyModulation(params, target.modulationAmount,
                                        target.parameterId);
                    }, modulatedParams);
                }
                float manualBase = target.compiledBaseValue;
                const bool hasLiveManualBase = proc->readManualEffectiveParameter(
                    target.parameterId, manualBase);
                if (hasLiveManualBase || target.hasCompiledBaseValue) {
                    proc->publishPresentationParameter(
                        target.parameterId,
                        manualBase,
                        manualBase + target.modulationAmount);
                }
                continue;
            }
            const float effective = std::clamp(target.automatedValue +
                                                   target.modulationAmount,
                                               0.0f, 1.0f);
            // Device-owned time-varying renderers apply the same automation
            // and global modulation at frame/sub-block rate. Do not apply the
            // midpoint probe to their DSP input a second time.
            if (!ownsTimeVaryingControls) {
                applyAutomationValue(
                    modulatedParams, nodeKind, target.parameterId, effective);
            }
            proc->publishPresentationParameter(
                target.parameterId, target.automatedValue, effective);
        }

        // MIDI-note transforms consume the same post-control value bank as
        // audio processors. Reading storedParams_ earlier would make live
        // changes lag one callback behind the compact parameter stream.
        if (nodeKind == DeviceNodeKind::MidiDelay) {
            const auto& params = std::get<MidiDelayParams>(modulatedParams);
            const double delayBeats = params.mode >= 0.5f
                ? static_cast<double>(params.division)
                : static_cast<double>(params.seconds) *
                    static_cast<double>(std::max(ctx.bpm, 1)) / 60.0;
            for (int i = 0; i < activeNoteCount; ++i) {
                activeNotes[i].noteStartBeat += delayBeats;
                activeNotes[i].clipLengthBeats += delayBeats;
                activeNotes[i].contentLengthBeats += delayBeats;
            }
        }

        // --- Per-frame gain/pan LFO modulation ---
        const int monitorFrame = std::clamp(numFrames / 2, 0, numFrames - 1);
        const float monitorGainBase = commonControls.gainAt(monitorFrame);
        const float monitorPanBase = commonControls.panAt(monitorFrame);
        applyCommonGainPanLfo(s, di, proc->stableProcessorNodeId, numFrames,
                              ctx.lfoValues, ctx.lfoCount,
                              targetModEdges, targetModEdgeCount,
                              ctx.modulators);
        proc->publishPresentationParameter(
            kEncodedCommonGain, monitorGainBase, commonControls.gainAt(monitorFrame));
        proc->publishPresentationParameter(
            kEncodedCommonPan, monitorPanBase, commonControls.panAt(monitorFrame));
        pc.commonControls = commonControls;

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
                if (delay.delaySamples != requestedDelay) continue;
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

        // Full-wet steady state needs no dry-buffer traffic.
        if (proc->outputMix != 1.0f || proc->smoothedOutputMix != 1.0f) {
            std::copy(block.channelL, block.channelL + numFrames, s.tempStereoL);
            std::copy(block.channelR, block.channelR + numFrames, s.tempStereoR);
        }

        runFusedInputTrimAdapter(*proc, modulatedParams, block, numFrames);

        proc->process(block, pc);

        captureAudioGraphTaps(proc->stableProcessorNodeId);
        runFusedOutputAdapter(*proc, nodeKind, block, s, commonControls, numFrames);
        captureAudioGraphTaps(proc->stableOutputNodeId);
        captureMidiGraphTaps(proc->stableOutputNodeId);
        captureAudioSources(deviceIndex);
        captureMidiSources(deviceIndex);
    }
    captureMidiGraphTaps(ctx.graphMidiOutputNodeId);
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
