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

bool appendEdge(ProcessorGraphSnapshot& graph, ProcessorGraphEdge edge) noexcept {
    auto& count = edge.signalType == GraphSignalType::Audio
        ? graph.audioEdgeCount
        : graph.midiEdgeCount;
    auto& edges = edge.signalType == GraphSignalType::Audio
        ? graph.audioEdges
        : graph.midiEdges;
    if (count >= kMaxProcessorGraphEdges) return false;
    edge.bufferSlot = count;
    edges[count++] = edge;
    if (edge.signalType == GraphSignalType::Audio)
        graph.audioBufferSlotCount = count;
    else
        graph.midiBufferSlotCount = count;
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
                    if (candidate.direction != GraphPortDirection::Output ||
                        receiver.direction != GraphPortDirection::Input) {
                        graph.audioEdgeCount = 0;
                        graph.midiEdgeCount = 0;
                        graph.error = ProcessorGraphError::InvalidPort;
                        return graph;
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
                    edge.sourceLayout = receiver.signalType == GraphSignalType::Audio
                        ? candidate.channelLayout : GraphChannelLayout::None;
                    edge.destinationLayout = receiver.signalType == GraphSignalType::Audio
                        ? receiver.channelLayout : GraphChannelLayout::None;
                    edge.eventCapacity = receiver.signalType == GraphSignalType::Midi
                        ? std::min(candidate.eventCapacity, receiver.eventCapacity) : 0;
                    edge.sourceLatencySamples = candidate.latencySamples;
                    edge.tapKind = candidate.tapKind;
                    graph.maxLatencySamples = std::max(
                        graph.maxLatencySamples, candidate.latencySamples);
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

    // Compile per-destination latency alignment metadata. Runtime delay slots
    // are only exercised when a source reports non-zero latency.
    for (int i = 0; i < graph.audioEdgeCount; ++i) {
        auto& edge = graph.audioEdges[static_cast<size_t>(i)];
        uint16_t destinationMax = edge.sourceLatencySamples;
        for (int j = 0; j < graph.audioEdgeCount; ++j) {
            const auto& peer = graph.audioEdges[static_cast<size_t>(j)];
            if (peer.destinationTrack == edge.destinationTrack &&
                peer.destinationDevice == edge.destinationDevice) {
                destinationMax = std::max(destinationMax, peer.sourceLatencySamples);
            }
        }
        edge.latencyCompensationSamples = static_cast<uint16_t>(
            destinationMax - edge.sourceLatencySamples);
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
    for (int track = 0; track < graph.trackCount; ++track) {
        const int parent = tracks[static_cast<size_t>(track)].parentGroupTrack;
        if (parent >= 0 && parent < graph.trackCount && parent != track) {
            ++indegree[static_cast<size_t>(parent)];
        }
    }

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
        const int parent = tracks[static_cast<size_t>(next)].parentGroupTrack;
        if (parent >= 0 && parent < graph.trackCount && parent != next &&
            indegree[static_cast<size_t>(parent)] > 0) {
            --indegree[static_cast<size_t>(parent)];
        }
    }
    return graph;
}

} // namespace audioapp
