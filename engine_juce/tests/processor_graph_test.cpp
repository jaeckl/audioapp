#include "audioapp/ProcessorGraph.hpp"

#include <iostream>

namespace {

int failures = 0;

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

    if (failures != 0) return 1;
    std::cout << "All processor graph tests passed\n";
    return 0;
}
