#pragma once

#include <array>
#include <cstdint>
#include <span>
#include <string_view>

namespace audioapp {

constexpr int kMaxProcessorGraphTracks = 8;
constexpr int kMaxProcessorGraphSourcesPerTrack = 16;
constexpr int kMaxProcessorGraphReceiversPerTrack = 16;
constexpr int kMaxProcessorGraphEdges = 32;
constexpr uint8_t kGraphTrackMidiInput = 0xFF;

enum class GraphSignalType : uint8_t {
    Audio,
    Midi,
};

enum class GraphPortDirection : uint8_t { Input, Output };
enum class GraphChannelLayout : uint8_t { None, Mono, Stereo };
enum class GraphTapKind : uint8_t { None, Meter, Analyzer, Recorder };

enum class ProcessorGraphError : uint8_t {
    None,
    TooManyTracks,
    TooManyEdges,
    Cycle,
    InvalidDeviceOrder,
    InvalidPort,
};

struct GraphSourceDefinition {
    std::string_view sourceId;
    GraphSignalType signalType = GraphSignalType::Audio;
    uint8_t deviceIndex = 0;
    GraphPortDirection direction = GraphPortDirection::Output;
    GraphChannelLayout channelLayout = GraphChannelLayout::Stereo;
    uint16_t eventCapacity = 128;
    uint16_t latencySamples = 0;
    GraphTapKind tapKind = GraphTapKind::None;
};

struct GraphReceiverDefinition {
    std::string_view sourceId;
    GraphSignalType signalType = GraphSignalType::Audio;
    uint8_t deviceIndex = 0;
    float mix = 1.0f;
    GraphPortDirection direction = GraphPortDirection::Input;
    GraphChannelLayout channelLayout = GraphChannelLayout::Stereo;
    uint16_t eventCapacity = 128;
};

struct GraphTrackDefinition {
    std::string_view trackId;
    int8_t parentGroupTrack = -1;
    std::array<GraphSourceDefinition, kMaxProcessorGraphSourcesPerTrack> sources{};
    std::array<GraphReceiverDefinition, kMaxProcessorGraphReceiversPerTrack> receivers{};
    uint8_t sourceCount = 0;
    uint8_t receiverCount = 0;
};

struct ProcessorGraphEdge {
    GraphSignalType signalType = GraphSignalType::Audio;
    uint8_t sourceTrack = 0;
    uint8_t sourceDevice = 0;
    uint8_t destinationTrack = 0;
    uint8_t destinationDevice = 0;
    float mix = 1.0f;
    uint8_t bufferSlot = 0;
    GraphChannelLayout sourceLayout = GraphChannelLayout::Stereo;
    GraphChannelLayout destinationLayout = GraphChannelLayout::Stereo;
    uint16_t eventCapacity = 0;
    uint16_t sourceLatencySamples = 0;
    uint16_t latencyCompensationSamples = 0;
    GraphTapKind tapKind = GraphTapKind::None;
};

/// Immutable playback description. Built on the control thread, then read
/// without allocation or graph traversal on the audio thread.
struct ProcessorGraphSnapshot {
    std::array<uint8_t, kMaxProcessorGraphTracks> executionOrder{};
    std::array<ProcessorGraphEdge, kMaxProcessorGraphEdges> audioEdges{};
    std::array<ProcessorGraphEdge, kMaxProcessorGraphEdges> midiEdges{};
    uint8_t trackCount = 0;
    uint8_t audioEdgeCount = 0;
    uint8_t midiEdgeCount = 0;
    uint8_t audioBufferSlotCount = 0;
    uint8_t midiBufferSlotCount = 0;
    uint16_t maxLatencySamples = 0;
    ProcessorGraphError error = ProcessorGraphError::None;

    bool valid() const noexcept { return error == ProcessorGraphError::None; }
};

ProcessorGraphSnapshot buildProcessorGraph(
    std::span<const GraphTrackDefinition> tracks) noexcept;

} // namespace audioapp
