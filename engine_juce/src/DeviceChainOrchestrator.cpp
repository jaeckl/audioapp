#include "audioapp/DeviceChainOrchestrator.hpp"
#include "audioapp/devices/DevicePanelTypes.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/DeviceChainAutomationModulation.hpp"
#include "audioapp/AutomationPlayback.hpp"

using namespace audioapp::DeviceChainAutomationModulation;

// Include all modular processors
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
            proc->bypassed = node.bypassed;
            proc->meterSlot = node.meterSlot;
            proc->gain = node.gain;
            proc->pan = node.pan;
            proc->initParams(node.params);
            ++count;
        }
    }

    return count;
}

// =======================================================================
// LFO gain/pan modulation
// =======================================================================

void DeviceChainOrchestrator::applyCommonGainPanLfo(
    DeviceChainScratch& scratch,
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

// =======================================================================
// Main orchestrator loop — virtual dispatch instead of switch
// =======================================================================

void DeviceChainOrchestrator::processChain(Context& ctx) noexcept {
    auto& s = ctx.scratch;
    const int numFrames = ctx.numFrames > kScratchFrames ? kScratchFrames : ctx.numFrames;

    const double beatsPerFrame =
        (static_cast<double>(std::max(ctx.bpm, 1)) / 60.0) / ctx.sampleRate;

    for (int deviceIndex = 0; deviceIndex < ctx.arena.size(); ++deviceIndex) {
        auto* proc = ctx.arena.get(deviceIndex);
        if (proc == nullptr || proc->bypassed) continue;

        // Initialize per-frame gain/pan from processor instance
        for (int f = 0; f < numFrames; ++f) {
            s.perFrameGain[f] = proc->gain;
            s.perFramePan[f] = proc->pan;
        }

        const uint16_t di = static_cast<uint16_t>(deviceIndex);
        const DeviceNodeKind nodeKind = proc->kind();

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
        pc.notes = ctx.notes;
        pc.noteCount = ctx.noteCount;
        pc.playheadBeat = ctx.playheadStartBeat;
        pc.bpm = ctx.bpm;
        pc.sampleRate = ctx.sampleRate;
        pc.suppressInstruments = ctx.suppressInstruments;
        pc.deviceMeters = ctx.deviceMeters;
        pc.maxDeviceMeters = ctx.maxDeviceMeters;
        pc.deviceIndex = deviceIndex;
        pc.needsSubBlocks = needsSubBlocks;

        // --- Timeline automation ---
        auto modulatedParams = DeviceVariantParams{}; // start from defaults; will be overridden
        if (ctx.automationClips != nullptr && ctx.automationClipCount > 0) {
            for (int a = 0; a < ctx.automationClipCount; ++a) {
                const auto& ac = ctx.automationClips[a];
                if (ac.deviceIndex != di) continue;

                if (ac.localParamId == kEncodedCommonGain ||
                    ac.localParamId == kEncodedCommonPan) {
                    const bool isGain = ac.localParamId == kEncodedCommonGain;
                    for (int f = 0; f < numFrames; ++f) {
                        const double beat = ctx.playheadStartBeat + static_cast<double>(f) * beatsPerFrame;
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
                    if ((nodeKind == DeviceNodeKind::SubtractiveSynth ||
                         nodeKind == DeviceNodeKind::BassSynth ||
                         nodeKind == DeviceNodeKind::PhaseModSynth) &&
                        nodeHasDspAutomation(di, ctx.automationClips, ctx.automationClipCount)) {
                        continue;
                    }
                    const double beat = ctx.playheadStartBeat;
                    if (beat < static_cast<double>(ac.clipStartBeat) ||
                        beat >= static_cast<double>(ac.clipStartBeat + ac.clipLengthBeats)) continue;
                    const float beatInClip = static_cast<float>(beat - static_cast<double>(ac.clipStartBeat));
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
                if (edge.deviceIndex != di || edge.lfoId >= static_cast<uint16_t>(ctx.lfoCount)) continue;
                const uint16_t pid = edge.localParamId;
                if (pid == kEncodedCommonGain || pid == kEncodedCommonPan) continue;
                if (!needsSubBlocks) {
                    if ((nodeKind == DeviceNodeKind::SubtractiveSynth ||
                         nodeKind == DeviceNodeKind::BassSynth ||
                         nodeKind == DeviceNodeKind::PhaseModSynth) &&
                        (nodeHasDspAutomation(di, ctx.automationClips, ctx.automationClipCount) ||
                         nodeHasDspModulation(di, ctx.modEdges, ctx.modEdgeCount))) continue;
                    const float lfoOut = ctx.lfoValues[edge.lfoId * numFrames];
                    const float modAmount = edge.amount * lfoOut;
                    std::visit([&](auto& params) {
                        applyModulation(params, modAmount, pid);
                    }, modulatedParams);
                }
            }
        }

        // --- Per-frame gain/pan LFO modulation ---
        applyCommonGainPanLfo(s, di, numFrames,
                              ctx.lfoValues, ctx.lfoCount,
                              ctx.modEdges, ctx.modEdgeCount);

        // --- Process device via virtual dispatch ---
        pc.modulatedParams = &modulatedParams;
        AudioBlock block{ctx.trackLeft, ctx.trackRight, numFrames};
        proc->process(block, pc);

        // --- Apply per-frame gain/pan for non-instrument processors ---
        if (!isInstrumentDeviceNodeKind(nodeKind) &&
            nodeKind != DeviceNodeKind::TrackGain) {
            StereoOutputPanel::applyInPlace(block, numFrames, s.perFrameGain);
        }
    }
}

} // namespace audioapp