#include "audioapp/ProcessorGraph.hpp"
#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/DeviceSubgraph.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/PhaseModSynthDeviceType.hpp"
#include "audioapp/devices/processors/WavetableSynthProcessor.hpp"
#include "audioapp/devices/processors/TrackGainProcessor.hpp"
#include "audioapp/dsp/ProcessorArena.hpp"

#include <iostream>
#include <cmath>
#include <memory>
#include <array>

namespace {

int failures = 0;

struct ArenaProbeProcessor final : audioapp::DeviceProcessor {
    ~ArenaProbeProcessor() override { ++destroyed; }
    void process(audioapp::AudioBlock&, audioapp::ProcessContext&) noexcept override {}
    static inline int destroyed = 0;
};

struct SmoothingProbeProcessor final : audioapp::DeviceProcessor {
    void process(audioapp::AudioBlock&, audioapp::ProcessContext&) noexcept override {}
    audioapp::DeviceNodeKind kind() const noexcept override {
        return audioapp::DeviceNodeKind::Distortion;
    }
};

struct PhaseModSmoothingProbeProcessor final : audioapp::DeviceProcessor {
    void process(audioapp::AudioBlock&, audioapp::ProcessContext&) noexcept override {}
    audioapp::DeviceNodeKind kind() const noexcept override {
        return audioapp::DeviceNodeKind::PhaseModSynth;
    }
};

struct SamplerAssetProbeProcessor final : audioapp::DeviceProcessor {
    void process(audioapp::AudioBlock&, audioapp::ProcessContext&) noexcept override {}
    audioapp::DeviceNodeKind kind() const noexcept override {
        return audioapp::DeviceNodeKind::Sampler;
    }
};

void expect(bool condition, const char* message) {
    if (condition) return;
    ++failures;
    std::cerr << "FAIL: " << message << '\n';
}

audioapp::GraphSourceDefinition source(const char* id, audioapp::GraphSignalType type,
                                       int device) {
    return {id, type, static_cast<uint8_t>(device)};
}

audioapp::GraphReceiverDefinition receiver(const char* id, audioapp::GraphSignalType type,
                                           int device, float mix = 1.0f) {
    return {id, type, static_cast<uint8_t>(device), mix};
}

} // namespace

int main() {
    using namespace audioapp;

    CommonControlBlock constantControls;
    constantControls.gainEnd = 0.25f;
    constantControls.panEnd = 0.75f;
    constantControls.numFrames = 8;
    expect(constantControls.gainAt(4) == 0.25f &&
           constantControls.panAt(4) == 0.75f,
           "constant common controls do not require per-frame buffers");

    CommonControlBlock rampControls;
    rampControls.gainMode = CommonControlMode::Ramp;
    rampControls.panMode = CommonControlMode::Ramp;
    rampControls.gainStart = 1.0f;
    rampControls.gainEnd = 0.5f;
    rampControls.panStart = 0.5f;
    rampControls.panEnd = 1.0f;
    rampControls.numFrames = 8;
    expect(rampControls.gainAt(0) > rampControls.gainAt(7) &&
           std::abs(rampControls.gainAt(7) - 0.5f) < 1.0e-6f &&
           std::abs(rampControls.panAt(7) - 1.0f) < 1.0e-6f,
           "manual common-control ramps reach their target at the block boundary");

    auto controlScratch = std::make_unique<DeviceChainScratch>();
    float controlLeft[8];
    float controlRight[8];
    std::fill_n(controlLeft, 8, 1.0f);
    std::fill_n(controlRight, 8, 1.0f);
    AudioBlock controlBlock{controlLeft, controlRight, 8};
    ProcessContext controlContext(*controlScratch);
    controlContext.numFrames = 8;
    controlContext.commonControls = constantControls;
    TrackGainProcessor trackGain;
    trackGain.process(controlBlock, controlContext);
    expect(std::abs(controlLeft[3] - 0.125f) < 1.0e-6f &&
           std::abs(controlRight[3] - 0.25f) < 1.0e-6f,
           "Track Gain constant mode applies precomputed scalar channel gains");

    SmoothingProbeProcessor commonTargetProbe;
    commonTargetProbe.stableProcessorNodeId = 77;
    AutomationClipPlayback commonAutomation[1]{};
    commonAutomation[0].targetNodeId = 77;
    commonAutomation[0].localParamId = kEncodedCommonGain;
    ModulationEdgePlayback commonModulation[1]{};
    commonModulation[0].targetNodeId = 77;
    commonModulation[0].localParamId = kEncodedCommonPan;
    commonTargetProbe.bindCompiledParameterSpans(
        commonAutomation, 1, commonModulation, 1);
    expect(commonTargetProbe.hasCommonGainAutomation &&
           commonTargetProbe.hasCommonPanModulation &&
           !commonTargetProbe.hasCommonPanAutomation &&
           !commonTargetProbe.hasCommonGainModulation,
           "compiled parameter spans classify dynamic common controls once");

    GraphTrackDefinition linear[3];
    linear[0].trackId = "a";
    linear[1].trackId = "b";
    linear[2].trackId = "c";
    auto graph = buildProcessorGraph(linear);
    expect(graph.valid(), "linear tracks build a valid graph");
    expect(graph.trackCount == 3 && graph.audioEdgeCount == 0 && graph.midiEdgeCount == 0,
           "linear graph contains no cross-track edges");

    GraphTrackDefinition routed[3];
    routed[0].trackId = "source";
    routed[0].sources[0] = source("audio-dev", GraphSignalType::Audio, 2);
    routed[0].sources[0].channelLayout = GraphChannelLayout::Stereo;
    routed[0].sources[0].latencySamples = 64;
    routed[0].sourceCount = 1;
    routed[1].trackId = "midi-source";
    routed[1].sources[0] = source("track-midi", GraphSignalType::Midi, kGraphTrackMidiInput);
    routed[1].sourceCount = 1;
    routed[2].trackId = "destination";
    routed[2].receivers[0] = receiver("audio-dev", GraphSignalType::Audio, 1, 0.5f);
    routed[2].receivers[1] = receiver("track-midi", GraphSignalType::Midi, 2);
    routed[2].receiverCount = 2;
    graph = buildProcessorGraph(routed);
    expect(graph.valid(), "typed routes build a valid graph");
    expect(graph.audioEdgeCount == 1 && graph.midiEdgeCount == 1,
           "audio and MIDI edges remain distinct");
    expect(graph.executionOrder[2] == 2, "destination executes after both sources");
    expect(graph.audioEdges[0].mix == 0.5f, "receiver mix is compiled into audio edge");
    expect(graph.audioEdges[0].sourceDevice == 2 &&
           graph.audioEdges[0].destinationDevice == 1,
           "edge retains source and receiver insertion points");
    expect(graph.audioEdges[0].bufferSlot == 0 && graph.midiEdges[0].bufferSlot == 0 &&
           graph.audioBufferSlotCount == 1 && graph.midiBufferSlotCount == 1,
           "compiler assigns independent preallocated audio and MIDI buffer slots");
    expect(graph.midiEdges[0].eventCapacity == 128,
           "default MIDI ports retain their event capacity");
    expect(graph.audioEdges[0].sourceLayout == GraphChannelLayout::Stereo &&
           graph.maxLatencySamples == 64,
           "typed port and latency metadata reach the immutable edge");

    const GraphTapDefinition taps[] = {
        {1001, 0, 7, GraphTapKind::Meter, 64},
        {1001, 1, 9, GraphTapKind::Recorder, 4},
    };
    graph = buildProcessorGraph(linear, taps);
    expect(graph.valid() && graph.tapCount == 2,
           "multiple taps compile without a routing receiver");
    expect(graph.audioEdgeCount == 0 && graph.audioBufferSlotCount == 0,
           "taps create no routing edges or route buffers");
    expect(graph.taps[0].sourceOutputNodeId == 1001 &&
           graph.taps[1].kind == GraphTapKind::Recorder,
           "compiled taps retain stable output IDs and kinds");

    const GraphTapDefinition invalidTap[] = {
        {0, 0, 1, GraphTapKind::Meter, 64},
    };
    graph = buildProcessorGraph(linear, invalidTap);
    expect(graph.error == ProcessorGraphError::InvalidTap,
           "zero stable output IDs are rejected");

    expect(unpackParamKind(packParamId(ParamKind::Delay, 9)) == ParamKind::Delay &&
           unpackParamId(packParamId(ParamKind::Delay, 9)) == 9,
           "six-bit parameter kinds preserve the added delay namespace");
    DeviceVariantParams normalizedDelay = DelayParamsPlayback{};
    applyAutomationValue(normalizedDelay, DeviceNodeKind::Delay,
                         packParamId(ParamKind::Delay, 0), 0.5f);
    applyAutomationValue(normalizedDelay, DeviceNodeKind::Delay,
                         packParamId(ParamKind::Delay, 9), 0.5f);
    expect(std::abs(std::get<DelayParamsPlayback>(normalizedDelay).timeMs - 2500.0f) < 1.0e-6f &&
           std::abs(std::get<DelayParamsPlayback>(normalizedDelay).highCutHz - 11000.0f) < 1.0e-6f,
           "delay mailbox normalization follows descriptor ranges");
    DeviceVariantParams normalizedDistortion = DistortionParamsPlayback{};
    applyAutomationValue(normalizedDistortion, DeviceNodeKind::Distortion,
                         packParamId(ParamKind::Distortion, 0), 0.75f);
    expect(std::abs(std::get<DistortionParamsPlayback>(normalizedDistortion).drive - 0.75f) < 1.0e-6f,
           "distortion mailbox values reach the typed evaluator");
    DeviceVariantParams normalizedTremolo = TremoloParamsPlayback{};
    applyAutomationValue(normalizedTremolo, DeviceNodeKind::Tremolo,
                         packParamId(ParamKind::Tremolo, 1), 0.5f);
    expect(std::abs(std::get<TremoloParamsPlayback>(normalizedTremolo).rateHz - 10.05f) < 1.0e-5f,
           "tremolo rate normalization follows its physical range");

    AutomationClipPlayback cursorClip{};
    cursorClip.pointCount = 3;
    cursorClip.points[0] = {0.0f, 0.0f};
    cursorClip.points[1] = {1.0f, 1.0f};
    cursorClip.points[2] = {2.0f, 0.0f};
    expect(std::abs(evaluateAutomationEnvelopeCached(cursorClip, 0.25f) - 0.25f) < 1.0e-6f &&
           cursorClip.envelopeCursor == 0,
           "automation cursor evaluates the first forward segment");
    expect(std::abs(evaluateAutomationEnvelopeCached(cursorClip, 1.5f) - 0.5f) < 1.0e-6f &&
           cursorClip.envelopeCursor == 1,
           "automation cursor advances monotonically");
    expect(std::abs(evaluateAutomationEnvelopeCached(cursorClip, 0.5f) - 0.5f) < 1.0e-6f &&
           cursorClip.envelopeCursor == 0,
           "automation cursor resets after transport rewind");

    const ParamDescriptor continuousDescriptor{0, "drive", "Drive", 0.0f,
                                               0.0f, 1.0f, true, true};
    const ParamDescriptor discreteDescriptor{1, "waveform", "Waveform", 0.0f,
                                             0.0f, 4.0f, true, true,
                                             ParameterUpdateRate::Discrete};
    expect(parameterUpdateRateFor(continuousDescriptor) == ParameterUpdateRate::Smoothed &&
           parameterUpdateRateFor(discreteDescriptor) == ParameterUpdateRate::Discrete,
           "parameter metadata separates continuous gestures from selectors");

    const PhaseModSynthDeviceType phaseModType;
    const auto declaredPhaseModParams = phaseModType.paramDescriptors();
    const auto rateFor = [&](std::string_view name) {
        const auto found = std::find_if(
            declaredPhaseModParams.begin(), declaredPhaseModParams.end(),
            [&](const ParamDescriptor& descriptor) {
                return name == descriptor.stableName;
            });
        return found == declaredPhaseModParams.end()
            ? ParameterUpdateRate::AudioRate
            : parameterUpdateRateFor(*found);
    };
    expect(rateFor("pmOp1Wave") == ParameterUpdateRate::Discrete &&
               rateFor("pmAlgoIndex") == ParameterUpdateRate::Discrete &&
               rateFor("pmMono") == ParameterUpdateRate::Discrete &&
               rateFor("pmLegato") == ParameterUpdateRate::Discrete &&
               rateFor("pmLfoDest") == ParameterUpdateRate::Discrete &&
               rateFor("pmOp1Fine") == ParameterUpdateRate::Smoothed,
           "Phase Mod declares selector and continuous rates without name heuristics");

    DeviceVariantParams delayParams = DelayParamsPlayback{};
    applyAutomationValue(delayParams, DeviceNodeKind::Delay,
                         packParamId(ParamKind::Delay, 3), 1.0f);
    applyAutomationValue(delayParams, DeviceNodeKind::Delay,
                         packParamId(ParamKind::Delay, 4), 1.0f);
    applyAutomationValue(delayParams, DeviceNodeKind::Delay,
                         packParamId(ParamKind::Delay, 5), 1.0f);
    const auto& compactDelay = std::get<DelayParamsPlayback>(delayParams);
    expect(compactDelay.timeMode == 3.0f && compactDelay.noteCount == 8.0f &&
               compactDelay.blurMode == 2.0f,
           "all numeric delay controls use compact typed updates");

    SmoothingProbeProcessor smoothingProbe;
    smoothingProbe.initParams(DistortionParamsPlayback{});
    const auto encodedDrive = packParamId(ParamKind::Distortion, 0);
    expect(smoothingProbe.setCompiledParameter(encodedDrive, 0.8f,
                                               ParameterUpdateRate::Smoothed,
                                               0.2f),
           "compiled smoothing accepts the previous and target gesture values");
    DeviceVariantParams smoothedParams = smoothingProbe.storedParams();
    smoothingProbe.applyCompiledParameterSmoothing(smoothedParams, 128, 48000.0);
    const float firstSmoothed = std::get<DistortionParamsPlayback>(smoothedParams).drive;
    float monitoredValue = 0.0f;
    expect(firstSmoothed > 0.2f && firstSmoothed < 0.8f &&
           smoothingProbe.readEffectiveParameter(encodedDrive, monitoredValue) &&
           std::abs(monitoredValue - firstSmoothed) < 1.0e-6f,
           "live DSP targets ramp and publish their effective value atomically");
    smoothingProbe.publishFinalEffectiveParameter(encodedDrive,
                                                   firstSmoothed + 0.1f);
    smoothingProbe.publishAutomationBaseParameter(encodedDrive,
                                                   firstSmoothed + 0.05f);
    float manualBase = 0.0f;
    float automationBase = 0.0f;
    expect(smoothingProbe.readManualEffectiveParameter(encodedDrive, manualBase) &&
               std::abs(manualBase - firstSmoothed) < 1.0e-6f &&
               smoothingProbe.readEffectiveParameter(encodedDrive, monitoredValue,
                                                       &automationBase) &&
               std::abs(automationBase - (firstSmoothed + 0.05f)) < 1.0e-6f &&
               std::abs(monitoredValue - (firstSmoothed + 0.1f)) < 1.0e-6f,
           "manual, automated, and final presentation values remain separate");
    smoothingProbe.setCompiledParameter(encodedDrive, 0.0f,
                                        ParameterUpdateRate::Discrete);
    expect(smoothingProbe.readEffectiveParameter(encodedDrive, monitoredValue) &&
           monitoredValue == 0.0f,
           "discrete parameters step without interpolation");

    PhaseModSmoothingProbeProcessor largeParameterProbe;
    largeParameterProbe.initParams(PhaseModSynthParams{});
    int phaseModDescriptorCount = 0;
    const auto* phaseModDescriptors = paramDescriptorsForKind(
        DeviceNodeKind::PhaseModSynth, phaseModDescriptorCount);
    expect(phaseModDescriptorCount > 16 &&
           phaseModDescriptorCount <=
               static_cast<int>(kMaxCompiledParametersPerProcessor),
           "compiled parameter bank covers the largest registered device");
    bool acceptedEveryPhaseModParameter = phaseModDescriptors != nullptr;
    for (int index = 0; index < phaseModDescriptorCount; ++index) {
        const auto encoded = encodeAutomationParamId(
            phaseModDescriptors[index].stableName,
            DeviceNodeKind::PhaseModSynth,
            phaseModDescriptors[index].localParamId);
        acceptedEveryPhaseModParameter &= largeParameterProbe.setCompiledParameter(
            encoded, 0.75f, ParameterUpdateRate::Smoothed, 0.25f);
    }
    DeviceVariantParams largeSmoothedParams = largeParameterProbe.storedParams();
    largeParameterProbe.applyCompiledParameterSmoothing(
        largeSmoothedParams, 128, 48000.0);
    bool publishedEveryPhaseModParameter = true;
    for (int index = 0; index < phaseModDescriptorCount; ++index) {
        const auto encoded = encodeAutomationParamId(
            phaseModDescriptors[index].stableName,
            DeviceNodeKind::PhaseModSynth,
            phaseModDescriptors[index].localParamId);
        float effective = 0.0f;
        publishedEveryPhaseModParameter &=
            largeParameterProbe.readEffectiveParameter(encoded, effective);
    }
    expect(acceptedEveryPhaseModParameter && publishedEveryPhaseModParameter,
           "devices with more than 16 parameters never drop live updates or monitors");

    SamplerAssetProbeProcessor samplerAssetProbe;
    SamplerParams originalSampler;
    originalSampler.attack = 0.73f;
    samplerAssetProbe.initParams(originalSampler);
    float replacementPcm[4]{0.1f, 0.2f, 0.3f, 0.4f};
    ResolvedAssetUpdate samplerAsset;
    samplerAsset.kind = DeviceNodeKind::Sampler;
    samplerAsset.sampler.samplerPcm = replacementPcm;
    samplerAsset.sampler.samplerFrameCount = 4;
    samplerAsset.sampler.trimEndFrame = 4;
    expect(samplerAssetProbe.applyResolvedAsset(samplerAsset),
           "resolved sampler sources update through the POD asset command");
    const auto& updatedSampler =
        std::get<SamplerParams>(samplerAssetProbe.storedParams());
    expect(updatedSampler.samplerPcm == replacementPcm &&
               updatedSampler.samplerFrameCount == 4 &&
               updatedSampler.attack == 0.73f,
           "sample replacement preserves unrelated DSP and voice parameters");

    WavetableSynthProcessor wavetableAssetProbe;
    WavetableSynthParams wavetableParams;
    wavetableParams.wavetableIndex = 2;
    wavetableAssetProbe.initParams(wavetableParams);
    ResolvedAssetUpdate wavetableAsset;
    wavetableAsset.kind = DeviceNodeKind::WavetableSynth;
    wavetableAsset.wavetableIndex = 7;
    expect(wavetableAssetProbe.applyResolvedAsset(wavetableAsset) &&
               wavetableAssetProbe.wavetableIndex() == 7,
           "wavetable replacement uses a resolved numeric bank index");

    std::array<GraphTapDefinition, kMaxProcessorGraphTaps> maximumTaps{};
    for (int i = 0; i < kMaxProcessorGraphTaps; ++i) {
        maximumTaps[static_cast<size_t>(i)] = {
            1001, static_cast<uint8_t>(i), static_cast<uint32_t>(i + 1),
            GraphTapKind::Meter, 64};
    }
    graph = buildProcessorGraph(linear, maximumTaps);
    expect(graph.valid() && graph.tapCount == kMaxProcessorGraphTaps,
           "the documented maximum graph-tap count compiles");
    std::array<GraphTapDefinition, kMaxProcessorGraphTaps + 1> tooManyTaps{};
    std::copy(maximumTaps.begin(), maximumTaps.end(), tooManyTaps.begin());
    tooManyTaps.back() = {1001, 0, 99, GraphTapKind::Meter, 64};
    graph = buildProcessorGraph(linear, tooManyTaps);
    expect(graph.error == ProcessorGraphError::TooManyTaps,
           "one tap beyond the fixed realtime capacity is rejected");
    const GraphTapDefinition invalidTapFields[] = {
        {1001, static_cast<uint8_t>(kMaxProcessorGraphTaps), 1,
         GraphTapKind::Meter, 64},
        {1001, 0, 1, GraphTapKind::None, 64},
        {1001, 0, 0, GraphTapKind::Meter, 64},
    };
    for (const auto& invalid : invalidTapFields) {
        graph = buildProcessorGraph(linear, std::span<const GraphTapDefinition>(&invalid, 1));
        expect(graph.error == ProcessorGraphError::InvalidTap,
               "invalid runtime slot, kind, and generation are rejected");
    }

    auto meterRuntime = std::make_unique<GraphTapRuntime>();
    resetGraphTapRuntime(*meterRuntime, 7);
    const float tapLeft[] = {0.25f, -0.5f, 1.0f, 0.0f};
    const float tapRight[] = {-0.25f, 0.5f, -0.75f, 0.25f};
    processGraphTap(*meterRuntime, CompiledGraphTap{1001, 0, 7,
        GraphTapKind::Meter, 64}, tapLeft, tapRight, 4, 48000.0);
    expect(std::abs(meterRuntime->peakL.load() - 1.0f) < 1.0e-6f &&
           std::abs(meterRuntime->peakR.load() - 0.75f) < 1.0e-6f,
           "meter tap publishes stereo peaks");
    expect(std::abs(meterRuntime->rmsL.load() -
                    std::sqrt((0.0625f + 0.25f + 1.0f) / 4.0f)) < 1.0e-6f,
           "meter tap publishes RMS");
    GraphTapMeterSnapshot meterSnapshot;
    expect(tryReadGraphTapMeter(*meterRuntime, meterSnapshot) &&
           meterSnapshot.sequence == 1 && meterSnapshot.sampleRate == 48000 &&
           std::abs(meterSnapshot.peakL - 1.0f) < 1.0e-6f &&
           std::abs(meterSnapshot.rmsR -
                    std::sqrt((0.0625f + 0.25f + 0.5625f + 0.0625f) / 4.0f)) < 1.0e-6f,
           "meter tap exposes one coherent published snapshot");
    meterRuntime->meterRevision.fetch_add(1, std::memory_order_acq_rel);
    expect(!tryReadGraphTapMeter(*meterRuntime, meterSnapshot),
           "meter snapshot rejects an in-progress publication");
    meterRuntime->meterRevision.fetch_add(1, std::memory_order_release);

    auto recorderRuntime = std::make_unique<GraphTapRuntime>();
    resetGraphTapRuntime(*recorderRuntime, 9);
    const float recorderLeft[] = {1, 2, 3, 4, 5, 6};
    const float recorderRight[] = {-1, -2, -3, -4, -5, -6};
    const CompiledGraphTap recorderTap{1001, 1, 9,
        GraphTapKind::Recorder, 4};
    processGraphTap(*recorderRuntime, recorderTap,
                    recorderLeft, recorderRight, 6, 44100.0);
    expect(recorderRuntime->head.load() == 4 &&
           recorderRuntime->droppedFrames.load() == 2 &&
           recorderRuntime->overflowed.load(),
           "recorder tap reports bounded overflow without overwriting");
    expect(recorderRuntime->ringL[0] == 1.0f && recorderRuntime->ringL[3] == 4.0f,
           "recorder tap retains ordered bit-exact samples");
    processGraphTap(*recorderRuntime, recorderTap,
                    recorderLeft, recorderRight, 2, 44100.0);
    expect(recorderRuntime->head.load() == 4 &&
           recorderRuntime->droppedFrames.load() == 4,
           "overflowed recorder rejects later samples");
    resetGraphTapRuntime(*recorderRuntime, 10);
    processGraphTap(*recorderRuntime, recorderTap,
                    recorderLeft, recorderRight, 2, 44100.0);
    expect(recorderRuntime->head.load() == 0,
           "stale tap generations cannot write reused runtime slots");

    resetGraphTapRuntime(*recorderRuntime, 11);
    const CompiledGraphTap wrappingRecorderTap{1001, 1, 11,
        GraphTapKind::Recorder, 4};
    processGraphTap(*recorderRuntime, wrappingRecorderTap,
                    recorderLeft, recorderRight, 3, 44100.0);
    recorderRuntime->tail.store(2, std::memory_order_release);
    processGraphTap(*recorderRuntime, wrappingRecorderTap,
                    recorderLeft + 3, recorderRight + 3, 3, 44100.0);
    expect(recorderRuntime->head.load() == 6 &&
           recorderRuntime->ringL[2] == 3.0f &&
           recorderRuntime->ringL[3] == 4.0f &&
           recorderRuntime->ringL[0] == 5.0f &&
           recorderRuntime->ringL[1] == 6.0f,
           "recorder ring wraps while retaining unread sample order");

    auto analyzerRuntime = std::make_unique<GraphTapRuntime>();
    resetGraphTapRuntime(*analyzerRuntime, 12);
    const CompiledGraphTap analyzerTap{1001, 2, 12,
        GraphTapKind::Analyzer, 4};
    processGraphTap(*analyzerRuntime, analyzerTap,
                    recorderLeft, recorderRight, 6, 48000.0);
    expect(analyzerRuntime->head.load() == 4 &&
           analyzerRuntime->droppedFrames.load() == 2 &&
           analyzerRuntime->overflowed.load(),
           "analyzer reports bounded overflow without overwriting unread audio");
    analyzerRuntime->tail.store(4, std::memory_order_release);
    processGraphTap(*analyzerRuntime, analyzerTap,
                    recorderLeft + 4, recorderRight + 4, 2, 48000.0);
    expect(analyzerRuntime->head.load() == 6 &&
           analyzerRuntime->ringL[0] == 5.0f && analyzerRuntime->ringL[1] == 6.0f,
           "analyzer resumes publication after its consumer drains the ring");

    GraphTrackDefinition parallel[3];
    parallel[0].trackId = "fast";
    parallel[0].sources[0] = source("bus", GraphSignalType::Audio, 0);
    parallel[0].sources[0].latencySamples = 32;
    parallel[0].sourceCount = 1;
    parallel[1].trackId = "slow";
    parallel[1].sources[0] = source("bus", GraphSignalType::Audio, 0);
    parallel[1].sources[0].latencySamples = 96;
    parallel[1].sourceCount = 1;
    parallel[2].trackId = "sum";
    parallel[2].receivers[0] = receiver("bus", GraphSignalType::Audio, 0);
    parallel[2].receiverCount = 1;
    graph = buildProcessorGraph(parallel);
    expect(graph.error == ProcessorGraphError::MultipleAudioInputs,
           "an AudioReceiver accepts exactly one incoming audio edge");

    parallel[0].sources[0].direction = GraphPortDirection::Input;
    graph = buildProcessorGraph(parallel);
    expect(graph.error == ProcessorGraphError::InvalidPort,
           "source and receiver port directions are validated");

    GraphTrackDefinition feedback[2];
    feedback[0].trackId = "source";
    feedback[0].sources[0] = source("feedback-bus", GraphSignalType::Audio, 0);
    feedback[0].sourceCount = 1;
    feedback[1].trackId = "destination";
    feedback[1].receivers[0] = receiver("feedback-bus", GraphSignalType::Audio, 0);
    feedback[1].receivers[0].feedback = true;
    feedback[1].receiverCount = 1;
    graph = buildProcessorGraph(feedback);
    expect(graph.valid() && graph.feedbackBufferSlotCount == 1 && graph.audioEdges[0].feedback,
           "explicit audio feedback routes compile into one-block buffer slots");

    GraphTrackDefinition cyclic[2];
    cyclic[0].trackId = "a";
    cyclic[0].sources[0] = source("a-out", GraphSignalType::Audio, 0);
    cyclic[0].receivers[0] = receiver("b-out", GraphSignalType::Audio, 1);
    cyclic[0].sourceCount = cyclic[0].receiverCount = 1;
    cyclic[1].trackId = "b";
    cyclic[1].sources[0] = source("b-out", GraphSignalType::Audio, 0);
    cyclic[1].receivers[0] = receiver("a-out", GraphSignalType::Audio, 1);
    cyclic[1].sourceCount = cyclic[1].receiverCount = 1;
    graph = buildProcessorGraph(cyclic);
    expect(graph.error == ProcessorGraphError::Cycle, "cycles are rejected");
    expect(graph.audioEdgeCount == 0, "rejected graph falls back without routes");

    const auto distortionPlan = compileDeviceExecutionPlan(DeviceNodeKind::Distortion);
    expect(distortionPlan.valid(), "effect has a valid three-node device subgraph");
    expect(hasPort(distortionPlan.logical.nodes[0].inputPorts, DevicePortMask::Audio),
           "effect input adapter accepts audio");
    expect(hasPort(distortionPlan.logical.nodes[2].outputPorts, DevicePortMask::Audio),
           "effect output adapter exposes audio");
    expect(distortionPlan.fuseInputWithProcessor && distortionPlan.fuseProcessorWithOutput,
           "default device plan remains fused for realtime execution");
    expect(distortionPlan.inputAdapterOwnsTrim,
           "pure effect input trim belongs to the logical input adapter");

    const auto synthPlan = compileDeviceExecutionPlan(DeviceNodeKind::SubtractiveSynth);
    expect(synthPlan.valid(), "instrument has a valid three-node device subgraph");
    expect(hasPort(synthPlan.logical.nodes[0].inputPorts, DevicePortMask::Midi),
           "instrument input adapter accepts MIDI");
    expect(hasPort(synthPlan.logical.nodes[2].outputPorts, DevicePortMask::Audio),
           "instrument output adapter exposes audio");

    const auto midiPlan = compileDeviceExecutionPlan(DeviceNodeKind::MidiDelay);
    expect(hasPort(midiPlan.logical.nodes[0].inputPorts, DevicePortMask::Midi) &&
           !hasPort(midiPlan.logical.nodes[0].inputPorts, DevicePortMask::Audio),
           "MIDI utility remains MIDI-only at the logical boundary");
    expect(!midiPlan.inputAdapterOwnsTrim,
           "MIDI utilities do not receive an audio input trim adapter");

    const auto targetNode = stableDeviceSubgraphNodeId(
        "stable-target", DeviceSubgraphNodeRole::DeviceProcessor);
    expect(playbackTargetMatches(targetNode, 7, targetNode, 3),
           "stable automation target survives flattened index changes");
    expect(!playbackTargetMatches(targetNode, 3, targetNode + 1, 3),
           "stable target identity takes precedence over a stale cached index");
    expect(playbackTargetMatches(0, 3, targetNode, 3),
           "legacy index-only playback data remains compatible");

    DeviceSlot container;
    container.id = "chain";
    container.config.typeId = "chain";
    container.config.instance = ChainModel{};
    auto child = std::make_shared<DeviceSlot>();
    child->id = "child-distortion";
    child->config.typeId = "distortion";
    child->config.instance = DistortionParams{};
    std::get<ChainModel>(container.config.instance).devices.push_back(child);
    const auto tree = buildDeviceSubgraphTree(container);
    expect(tree.plan.valid(), "container has its own device subgraph");
    expect(tree.chainChildren.size() == 1 && tree.chainChildren[0].deviceId == "child-distortion",
           "chain children are explicit control-thread subgraphs");
    const auto schedule = compileDeviceSubgraphTree(tree);
    expect(schedule.valid() && schedule.stepCount == 6,
           "nested chain compiles to fixed adapter/DSP schedule");
    expect(schedule.steps[0].stage == CompiledDeviceSubgraphStage::InputAdapter &&
           schedule.steps[1].stage == CompiledDeviceSubgraphStage::DeviceProcessor &&
           schedule.steps[5].stage == CompiledDeviceSubgraphStage::OutputAdapter,
           "compiled root retains adapter/DSP/adapter boundaries");
    expect(schedule.steps[2].parentProcessorNodeId == schedule.steps[1].stableNodeId,
           "compiled child retains stable parent processor identity");

    auto playbackChain = std::make_shared<ChainPlayback>();
    playbackChain->deviceCount = 1;
    playbackChain->devices[0].deviceId = "playback-child";
    playbackChain->devices[0].kind = DeviceNodeKind::Distortion;
    DeviceNodePlayback playbackContainer;
    playbackContainer.deviceId = "playback-chain";
    playbackContainer.kind = DeviceNodeKind::Chain;
    playbackContainer.params = ChainParams{playbackChain};
    const auto playbackSchedule = compileDeviceSubgraphTree(
        buildDeviceSubgraphTree(playbackContainer));
    expect(playbackSchedule.valid() && playbackSchedule.stepCount == 6,
           "container playback compiles its immutable nested child schedule");
    expect(playbackSchedule.steps[2].stableNodeId ==
               stableDeviceSubgraphNodeId("playback-child", DeviceSubgraphNodeRole::InputAdapter),
           "playback schedule uses stable child device identity rather than arena index");
    const auto executionOrder = compileFusedChildExecutionOrder(
        playbackSchedule,
        std::span<const DeviceNodePlayback>(playbackChain->devices, 1));
    expect(executionOrder.valid() && executionOrder.count == 1 &&
               executionOrder.deviceIndices[0] == 0,
           "compiled schedule produces a fixed fused child execution order");

    DeviceSubgraphTree synthTree;
    synthTree.deviceId = "synth";
    synthTree.plan = compileDeviceExecutionPlan(DeviceNodeKind::SubtractiveSynth);
    synthTree.noteFx.push_back(DeviceSubgraphTree{
        "note-fx", compileDeviceExecutionPlan(DeviceNodeKind::MidiDelay)});
    synthTree.audioFx.push_back(DeviceSubgraphTree{
        "audio-fx", compileDeviceExecutionPlan(DeviceNodeKind::Distortion)});
    DeviceNodePlayback flattenedSynth[3];
    flattenedSynth[0].deviceId = "note-fx";
    flattenedSynth[0].kind = DeviceNodeKind::MidiDelay;
    flattenedSynth[1].deviceId = "synth";
    flattenedSynth[1].kind = DeviceNodeKind::SubtractiveSynth;
    flattenedSynth[2].deviceId = "audio-fx";
    flattenedSynth[2].kind = DeviceNodeKind::Distortion;
    const DeviceSubgraphTree forest[] = {synthTree};
    const auto synthExecutionOrder = compileFusedForestExecutionOrder(
        forest, flattenedSynth);
    expect(synthExecutionOrder.valid() && synthExecutionOrder.count == 3 &&
               synthExecutionOrder.deviceIndices[0] == 0 &&
               synthExecutionOrder.deviceIndices[1] == 1 &&
               synthExecutionOrder.deviceIndices[2] == 2,
           "synth Note FX, DSP, and Audio FX execute in compiled signal order");

    ArenaProbeProcessor::destroyed = 0;
    {
        ProcessorArena activeArena;
        auto* activeProcessor = activeArena.emplace<ArenaProbeProcessor>();
        ProcessorArena rebuildingArena = activeArena;
        expect(rebuildingArena.sharesStorageWith(activeArena),
               "identical snapshots share processor storage");
        rebuildingArena.reset();
        expect(!rebuildingArena.sharesStorageWith(activeArena) &&
               rebuildingArena.size() == 0 && activeArena.size() == 1 &&
               activeProcessor != nullptr && ArenaProbeProcessor::destroyed == 0,
               "rebuild detaches without destroying active processors");
    }
    expect(ArenaProbeProcessor::destroyed == 1,
           "shared processor storage is destroyed after the final snapshot releases it");

    ArenaProbeProcessor::destroyed = 0;
    {
        ProcessorArena sourceArena;
        sourceArena.emplace<ArenaProbeProcessor>();
        auto* retainedProcessor = sourceArena.emplace<ArenaProbeProcessor>();
        ProcessorArena changedArena;
        expect(changedArena.reuseSlotAt(0, sourceArena, 1),
               "a compatible processor slot can move to a new device index");
        changedArena.emplaceAt<ArenaProbeProcessor>(1);
        expect(changedArena.sharesSlotWith(0, sourceArena, 1) &&
               changedArena.get(0) == retainedProcessor &&
               sourceArena.size() == 2 && changedArena.size() == 2,
               "partial rebuild preserves the selected processor while adding a new slot");
        sourceArena.reset();
        expect(ArenaProbeProcessor::destroyed == 1 && changedArena.get(0) == retainedProcessor,
               "removing an old snapshot does not cut the retained processor slot");
    }
    expect(ArenaProbeProcessor::destroyed == 3,
           "partially shared slots release exactly once after their final owner");

    if (failures != 0) return 1;
    std::cout << "All processor graph tests passed\n";
    return 0;
}
