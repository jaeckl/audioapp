#include "audioapp/ProcessorGraph.hpp"
#include "audioapp/DeviceSubgraph.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/dsp/ProcessorArena.hpp"

#include <iostream>

namespace {

int failures = 0;

struct ArenaProbeProcessor final : audioapp::DeviceProcessor {
    ~ArenaProbeProcessor() override { ++destroyed; }
    void process(audioapp::AudioBlock&, audioapp::ProcessContext&) noexcept override {}
    static inline int destroyed = 0;
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
