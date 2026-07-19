#include "audioapp/ProcessorGraph.hpp"
#include "audioapp/DeviceChain.hpp"

#include <algorithm>
#include <cmath>

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
    if (edge.feedback) {
        if (graph.feedbackBufferSlotCount >= kMaxProcessorGraphFeedbackEdges) return false;
        edge.feedbackBufferSlot = graph.feedbackBufferSlotCount++;
    }
    edges[count++] = edge;
    if (edge.signalType == GraphSignalType::Audio)
        graph.audioBufferSlotCount = count;
    else
        graph.midiBufferSlotCount = count;
    return true;
}

} // namespace

ProcessorGraphSnapshot buildProcessorGraph(
    std::span<const GraphTrackDefinition> tracks,
    std::span<const GraphTapDefinition> taps) noexcept {
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
            int matchedAudioSources = 0;
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
                    if (receiver.signalType == GraphSignalType::Audio && ++matchedAudioSources > 1) {
                        graph.audioEdgeCount = 0;
                        graph.midiEdgeCount = 0;
                        graph.error = ProcessorGraphError::MultipleAudioInputs;
                        return graph;
                    }
                    if (receiver.signalType == GraphSignalType::Audio &&
                        candidate.channelLayout != receiver.channelLayout) {
                        graph.audioEdgeCount = 0;
                        graph.midiEdgeCount = 0;
                        graph.error = ProcessorGraphError::InvalidPort;
                        return graph;
                    }
                    if (receiver.signalType == GraphSignalType::Midi &&
                        (candidate.eventCapacity == 0 || receiver.eventCapacity == 0)) {
                        graph.audioEdgeCount = 0;
                        graph.midiEdgeCount = 0;
                        graph.error = ProcessorGraphError::InvalidPort;
                        return graph;
                    }
                    if (!receiver.feedback && source == destination &&
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
                    edge.feedback = receiver.feedback;
                    if (edge.feedback && receiver.signalType != GraphSignalType::Audio) {
                        graph.audioEdgeCount = 0;
                        graph.midiEdgeCount = 0;
                        graph.error = ProcessorGraphError::InvalidPort;
                        return graph;
                    }
                    graph.maxLatencySamples = std::max(
                        graph.maxLatencySamples, candidate.latencySamples);
                    if (candidate.latencySamples > kMaxProcessorGraphLatencySamples) {
                        graph.audioEdgeCount = 0;
                        graph.midiEdgeCount = 0;
                        graph.error = ProcessorGraphError::InvalidPort;
                        return graph;
                    }
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

    if (taps.size() > static_cast<size_t>(kMaxProcessorGraphTaps)) {
        graph.error = ProcessorGraphError::TooManyTaps;
        graph.tapCount = 0;
        return graph;
    }
    for (const auto& tap : taps) {
        if (tap.sourceOutputNodeId == 0 || tap.kind == GraphTapKind::None ||
            tap.runtimeSlot >= kMaxProcessorGraphTaps || tap.generation == 0) {
            graph.error = ProcessorGraphError::InvalidTap;
            graph.tapCount = 0;
            return graph;
        }
        auto compiled = CompiledGraphTap{
            tap.sourceOutputNodeId,
            tap.runtimeSlot,
            tap.generation,
            tap.kind,
            std::clamp(tap.capacityFrames, 1u, kGraphTapMaxBufferedFrames),
        };
        graph.taps[graph.tapCount++] = compiled;
    }
    // Sort so forEachGraphTapOnSource can binary-search by sourceOutputNodeId.
    if (graph.tapCount > 1) {
        std::sort(graph.taps.begin(),
                  graph.taps.begin() + graph.tapCount,
                  [](const CompiledGraphTap& a, const CompiledGraphTap& b) noexcept {
                      if (a.sourceOutputNodeId != b.sourceOutputNodeId) {
                          return a.sourceOutputNodeId < b.sourceOutputNodeId;
                      }
                      return static_cast<uint8_t>(a.kind) < static_cast<uint8_t>(b.kind);
                  });
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
            if (!edge.feedback && edge.sourceTrack != edge.destinationTrack)
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
                if (!edge.feedback && edge.sourceTrack != edge.destinationTrack &&
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

void resetGraphTapRuntime(GraphTapRuntime& runtime, uint32_t generation) noexcept {
    runtime.generation.store(generation, std::memory_order_release);
    runtime.sequence.store(0, std::memory_order_relaxed);
    runtime.droppedFrames.store(0, std::memory_order_relaxed);
    runtime.overflowed.store(false, std::memory_order_relaxed);
    runtime.sampleRate.store(48000, std::memory_order_relaxed);
    runtime.peakL.store(0.0f, std::memory_order_relaxed);
    runtime.peakR.store(0.0f, std::memory_order_relaxed);
    runtime.rmsL.store(0.0f, std::memory_order_relaxed);
    runtime.rmsR.store(0.0f, std::memory_order_relaxed);
    runtime.meterRevision.store(0, std::memory_order_relaxed);
    runtime.head.store(0, std::memory_order_relaxed);
    runtime.tail.store(0, std::memory_order_relaxed);
}

bool tryReadGraphTapMeter(const GraphTapRuntime& runtime,
                          GraphTapMeterSnapshot& snapshot) noexcept {
    const uint64_t before = runtime.meterRevision.load(std::memory_order_acquire);
    if ((before & 1u) != 0u) return false;

    GraphTapMeterSnapshot candidate;
    candidate.sequence = runtime.sequence.load(std::memory_order_relaxed);
    candidate.sampleRate = runtime.sampleRate.load(std::memory_order_relaxed);
    candidate.peakL = runtime.peakL.load(std::memory_order_relaxed);
    candidate.peakR = runtime.peakR.load(std::memory_order_relaxed);
    candidate.rmsL = runtime.rmsL.load(std::memory_order_relaxed);
    candidate.rmsR = runtime.rmsR.load(std::memory_order_relaxed);

    const uint64_t after = runtime.meterRevision.load(std::memory_order_acquire);
    if (before != after || (after & 1u) != 0u) return false;
    snapshot = candidate;
    return true;
}

void processGraphTap(GraphTapRuntime& runtime,
                     const CompiledGraphTap& tap,
                     const float* left,
                     const float* right,
                     int numFrames,
                     double sampleRate) noexcept {
    if (tap.kind == GraphTapKind::MidiRecorder) return;
    if (left == nullptr || right == nullptr || numFrames <= 0 ||
        runtime.generation.load(std::memory_order_acquire) != tap.generation) {
        return;
    }
    runtime.writers.fetch_add(1, std::memory_order_acq_rel);
    if (runtime.generation.load(std::memory_order_acquire) != tap.generation) {
        runtime.writers.fetch_sub(1, std::memory_order_release);
        return;
    }
    const auto publishedSampleRate = static_cast<uint32_t>(
        std::clamp(std::lround(sampleRate), 1l, 768000l));

    if (tap.kind == GraphTapKind::Meter) {
        float peakL = 0.0f;
        float peakR = 0.0f;
        double sumL = 0.0;
        double sumR = 0.0;
        for (int frame = 0; frame < numFrames; ++frame) {
            peakL = std::max(peakL, std::abs(left[frame]));
            peakR = std::max(peakR, std::abs(right[frame]));
            sumL += static_cast<double>(left[frame]) * left[frame];
            sumR += static_cast<double>(right[frame]) * right[frame];
        }
        runtime.meterRevision.fetch_add(1, std::memory_order_acq_rel);
        runtime.sampleRate.store(publishedSampleRate, std::memory_order_relaxed);
        runtime.peakL.store(peakL, std::memory_order_relaxed);
        runtime.peakR.store(peakR, std::memory_order_relaxed);
        runtime.rmsL.store(static_cast<float>(std::sqrt(sumL / numFrames)),
                           std::memory_order_relaxed);
        runtime.rmsR.store(static_cast<float>(std::sqrt(sumR / numFrames)),
                           std::memory_order_relaxed);
        runtime.sequence.fetch_add(1, std::memory_order_relaxed);
        runtime.meterRevision.fetch_add(1, std::memory_order_release);
    } else {
        runtime.sampleRate.store(publishedSampleRate, std::memory_order_relaxed);
        if (tap.kind == GraphTapKind::Recorder &&
            runtime.overflowed.load(std::memory_order_acquire)) {
            runtime.droppedFrames.fetch_add(static_cast<uint64_t>(numFrames),
                                            std::memory_order_relaxed);
        } else {
            const uint64_t head = runtime.head.load(std::memory_order_relaxed);
            const uint64_t tail = runtime.tail.load(std::memory_order_acquire);
            const uint32_t capacity = std::clamp(
                tap.capacityFrames, 1u, kGraphTapMaxBufferedFrames);
            const uint64_t used = head - tail;
            const uint64_t available = used < capacity ? capacity - used : 0;
            const int writable = static_cast<int>(std::min<uint64_t>(
                available, static_cast<uint64_t>(numFrames)));
            for (int frame = 0; frame < writable; ++frame) {
                const size_t position = static_cast<size_t>((head + frame) % capacity);
                runtime.ringL[position] = left[frame];
                runtime.ringR[position] = right[frame];
            }
            if (writable > 0) {
                runtime.head.store(head + static_cast<uint64_t>(writable),
                                   std::memory_order_release);
                runtime.sequence.fetch_add(static_cast<uint64_t>(writable),
                                           std::memory_order_release);
            }
            if (writable < numFrames) {
                runtime.droppedFrames.fetch_add(
                    static_cast<uint64_t>(numFrames - writable),
                    std::memory_order_relaxed);
                runtime.overflowed.store(true, std::memory_order_release);
            }
        }
    }
    runtime.writers.fetch_sub(1, std::memory_order_release);
}

void processGraphMidiTap(GraphTapRuntime& runtime,
                         const CompiledGraphTap& tap,
                         const MidiPlaybackNote* notes,
                         int noteCount) noexcept {
    if (tap.kind != GraphTapKind::MidiRecorder || notes == nullptr || noteCount <= 0 ||
        runtime.generation.load(std::memory_order_acquire) != tap.generation) return;
    runtime.writers.fetch_add(1, std::memory_order_acq_rel);
    if (runtime.generation.load(std::memory_order_acquire) != tap.generation) {
        runtime.writers.fetch_sub(1, std::memory_order_release);
        return;
    }
    const uint32_t capacity = std::clamp(
        tap.capacityFrames, 1u, kGraphTapMaxBufferedMidiEvents);
    const uint64_t head = runtime.head.load(std::memory_order_relaxed);
    const uint64_t tail = runtime.tail.load(std::memory_order_acquire);
    const uint64_t used = head - tail;
    const uint64_t available = used < capacity ? capacity - used : 0;
    const int writable = static_cast<int>(std::min<uint64_t>(
        available, static_cast<uint64_t>(noteCount)));
    for (int index = 0; index < writable; ++index) {
        const auto& note = notes[index];
        runtime.midiRing[static_cast<size_t>((head + index) % capacity)] = {
            note.pitch, note.clipStartBeat, note.clipLengthBeats,
            note.noteStartBeat, note.noteDurationBeats, note.velocity,
            note.loopContent, note.contentLengthBeats};
    }
    if (writable > 0) {
        runtime.head.store(head + static_cast<uint64_t>(writable),
                           std::memory_order_release);
        runtime.sequence.fetch_add(static_cast<uint64_t>(writable),
                                   std::memory_order_release);
    }
    if (writable < noteCount) {
        runtime.droppedFrames.fetch_add(
            static_cast<uint64_t>(noteCount - writable),
            std::memory_order_relaxed);
        runtime.overflowed.store(true, std::memory_order_release);
    }
    runtime.writers.fetch_sub(1, std::memory_order_release);
}

} // namespace audioapp
