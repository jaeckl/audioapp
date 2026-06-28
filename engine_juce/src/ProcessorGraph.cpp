#include "audioapp/ProcessorGraph.hpp"

#include <algorithm>

namespace audioapp {
namespace {

void setLinearOrder(ProcessorGraphSnapshot& graph, int trackCount) noexcept {
    graph.trackCount = static_cast<uint8_t>(std::clamp(trackCount, 0, kMaxProcessorGraphTracks));
    for (int i = 0; i < graph.trackCount; ++i) {
        graph.executionOrder[static_cast<size_t>(i)] = static_cast<uint8_t>(i);
    }
}

bool appendEdge(ProcessorGraphSnapshot& graph, const ProcessorGraphEdge& edge) noexcept {
    auto& count = edge.signalType == GraphSignalType::Audio
        ? graph.audioEdgeCount
        : graph.midiEdgeCount;
    auto& edges = edge.signalType == GraphSignalType::Audio
        ? graph.audioEdges
        : graph.midiEdges;
    if (count >= kMaxProcessorGraphEdges) return false;
    edges[count++] = edge;
    return true;
}

} // namespace

ProcessorGraphSnapshot buildProcessorGraph(
    std::span<const GraphTrackDefinition> tracks) noexcept {
    ProcessorGraphSnapshot graph;
    if (tracks.size() > static_cast<size_t>(kMaxProcessorGraphTracks)) {
        setLinearOrder(graph, kMaxProcessorGraphTracks);
        graph.error = ProcessorGraphError::TooManyTracks;
        return graph;
    }
    setLinearOrder(graph, static_cast<int>(tracks.size()));

    for (int destination = 0; destination < graph.trackCount; ++destination) {
        const auto& destinationTrack = tracks[static_cast<size_t>(destination)];
        for (int ri = 0; ri < destinationTrack.receiverCount; ++ri) {
            const auto& receiver = destinationTrack.receivers[static_cast<size_t>(ri)];
            if (receiver.sourceId.empty()) continue;
            for (int source = 0; source < graph.trackCount; ++source) {
                const auto& sourceTrack = tracks[static_cast<size_t>(source)];
                for (int si = 0; si < sourceTrack.sourceCount; ++si) {
                    const auto& candidate = sourceTrack.sources[static_cast<size_t>(si)];
                    if (candidate.signalType != receiver.signalType ||
                        candidate.sourceId != receiver.sourceId) {
                        continue;
                    }
                    if (source == destination &&
                        candidate.deviceIndex != kGraphTrackMidiInput &&
                        candidate.deviceIndex >= receiver.deviceIndex) {
                        graph.audioEdgeCount = 0;
                        graph.midiEdgeCount = 0;
                        graph.error = ProcessorGraphError::InvalidDeviceOrder;
                        return graph;
                    }
                    ProcessorGraphEdge edge;
                    edge.signalType = receiver.signalType;
                    edge.sourceTrack = static_cast<uint8_t>(source);
                    edge.sourceDevice = candidate.deviceIndex;
                    edge.destinationTrack = static_cast<uint8_t>(destination);
                    edge.destinationDevice = receiver.deviceIndex;
                    edge.mix = std::clamp(receiver.mix, 0.0f, 1.0f);
                    if (!appendEdge(graph, edge)) {
                        graph.audioEdgeCount = 0;
                        graph.midiEdgeCount = 0;
                        graph.error = ProcessorGraphError::TooManyEdges;
                        return graph;
                    }
                }
            }
        }
    }

    std::array<uint8_t, kMaxProcessorGraphTracks> indegree{};
    auto countDependencies = [&](const auto& edges, int count) {
        for (int i = 0; i < count; ++i) {
            const auto& edge = edges[static_cast<size_t>(i)];
            if (edge.sourceTrack != edge.destinationTrack)
                ++indegree[edge.destinationTrack];
        }
    };
    countDependencies(graph.audioEdges, graph.audioEdgeCount);
    countDependencies(graph.midiEdges, graph.midiEdgeCount);

    std::array<bool, kMaxProcessorGraphTracks> emitted{};
    int emittedCount = 0;
    while (emittedCount < graph.trackCount) {
        int next = -1;
        for (int track = 0; track < graph.trackCount; ++track) {
            if (!emitted[static_cast<size_t>(track)] && indegree[static_cast<size_t>(track)] == 0) {
                next = track;
                break;
            }
        }
        if (next < 0) {
            graph.audioEdgeCount = 0;
            graph.midiEdgeCount = 0;
            setLinearOrder(graph, graph.trackCount);
            graph.error = ProcessorGraphError::Cycle;
            return graph;
        }
        emitted[static_cast<size_t>(next)] = true;
        graph.executionOrder[static_cast<size_t>(emittedCount++)] = static_cast<uint8_t>(next);
        auto releaseDependencies = [&](const auto& edges, int count) {
            for (int i = 0; i < count; ++i) {
                const auto& edge = edges[static_cast<size_t>(i)];
                if (edge.sourceTrack != edge.destinationTrack &&
                    edge.sourceTrack == next && indegree[edge.destinationTrack] > 0) {
                    --indegree[edge.destinationTrack];
                }
            }
        };
        releaseDependencies(graph.audioEdges, graph.audioEdgeCount);
        releaseDependencies(graph.midiEdges, graph.midiEdgeCount);
    }
    return graph;
}

} // namespace audioapp
