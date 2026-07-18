#pragma once

#include <array>
#include <atomic>
#include <cstdint>
#include <span>
#include <string_view>

namespace audioapp {

constexpr int kMaxProcessorGraphTracks = 8;
constexpr int kMaxProcessorGraphSourcesPerTrack = 16;
constexpr int kMaxProcessorGraphReceiversPerTrack = 16;
constexpr int kMaxProcessorGraphEdges = 32;
constexpr int kMaxProcessorGraphFeedbackEdges = 8;
constexpr int kMaxProcessorGraphTaps = 16;
constexpr int kMaxProcessorGraphBlockFrames = 4096;
/// Bounded, allocation-free delay storage for route latency compensation.
constexpr int kMaxProcessorGraphLatencySamples = 4096;
constexpr uint32_t kGraphTapDefaultRecorderFrames = 32768;
constexpr uint32_t kGraphTapMaxBufferedFrames = 65536;
constexpr int kGraphTapAnalyzerWindowFrames = 256;
constexpr uint32_t kGraphTapMaxBufferedMidiEvents = 4096;
constexpr uint8_t kGraphTrackMidiInput = 0xFF;

enum class GraphSignalType : uint8_t {
    Audio,
    Midi,
};

enum class GraphPortDirection : uint8_t { Input, Output };
enum class GraphChannelLayout : uint8_t { None, Mono, Stereo };
enum class GraphTapKind : uint8_t { None, Meter, Analyzer, Recorder, MidiRecorder };
enum class GraphTapPort : uint8_t { Output, Input, ProcessorOutput, Sidechain };

enum class ProcessorGraphError : uint8_t {
    None,
    TooManyTracks,
    TooManyEdges,
    Cycle,
    InvalidDeviceOrder,
    InvalidPort,
    MultipleAudioInputs,
    TooManyTaps,
    InvalidTap,
};

struct GraphSourceDefinition {
    std::string_view sourceId;
    GraphSignalType signalType = GraphSignalType::Audio;
    uint8_t deviceIndex = 0;
    GraphPortDirection direction = GraphPortDirection::Output;
    GraphChannelLayout channelLayout = GraphChannelLayout::Stereo;
    uint16_t eventCapacity = 128;
    uint16_t latencySamples = 0;
};

struct GraphReceiverDefinition {
    std::string_view sourceId;
    GraphSignalType signalType = GraphSignalType::Audio;
    uint8_t deviceIndex = 0;
    float mix = 1.0f;
    GraphPortDirection direction = GraphPortDirection::Input;
    GraphChannelLayout channelLayout = GraphChannelLayout::Stereo;
    uint16_t eventCapacity = 128;
    /// Feedback is explicit and always read from the preceding callback block.
    bool feedback = false;
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
    bool feedback = false;
    uint8_t feedbackBufferSlot = 0;
};

/// Control-thread tap definition. The source is a stable logical Output
/// Adapter node ID; runtimeSlot/generation address preallocated session state.
struct GraphTapDefinition {
    uint64_t sourceOutputNodeId = 0;
    uint8_t runtimeSlot = 0;
    uint32_t generation = 0;
    GraphTapKind kind = GraphTapKind::None;
    uint32_t capacityFrames = kGraphTapDefaultRecorderFrames;
};

/// Immutable audio-thread binding. Taps are observers, not routing edges, so
/// they have no destination, route buffer, dependency, or latency field.
struct CompiledGraphTap {
    uint64_t sourceOutputNodeId = 0;
    uint8_t runtimeSlot = 0;
    uint32_t generation = 0;
    GraphTapKind kind = GraphTapKind::None;
    uint32_t capacityFrames = kGraphTapDefaultRecorderFrames;
};

struct GraphTapMidiEvent {
    int pitch = 60;
    double clipStartBeat = 0.0;
    double clipLengthBeats = 4.0;
    double noteStartBeat = 0.0;
    double noteDurationBeats = 1.0;
    float velocity = 100.0f;
    bool loopContent = false;
    double contentLengthBeats = 4.0;
};

/// Preallocated SPSC/latest-value state shared by one tap generation. Meter
/// readers use atomics. Analyzer/recorder readers consume ring data using
/// head/tail release/acquire publication; the audio callback is the sole writer.
struct GraphTapRuntime {
    std::atomic<uint32_t> generation{1};
    std::atomic<uint32_t> writers{0};
    std::atomic<uint64_t> sequence{0};
    std::atomic<uint64_t> droppedFrames{0};
    std::atomic<bool> overflowed{false};
    std::atomic<uint32_t> sampleRate{48000};

    std::atomic<float> peakL{0.0f};
    std::atomic<float> peakR{0.0f};
    std::atomic<float> rmsL{0.0f};
    std::atomic<float> rmsR{0.0f};
    // Even while stable and odd while the audio thread publishes a meter
    // block. This makes the individually atomic fields one coherent snapshot.
    std::atomic<uint64_t> meterRevision{0};

    alignas(64) std::array<float, kGraphTapMaxBufferedFrames> ringL{};
    alignas(64) std::array<float, kGraphTapMaxBufferedFrames> ringR{};
    alignas(64) std::array<GraphTapMidiEvent,
                           kGraphTapMaxBufferedMidiEvents> midiRing{};
    alignas(64) std::atomic<uint64_t> head{0};
    alignas(64) std::atomic<uint64_t> tail{0};
};

struct GraphTapMeterSnapshot {
    uint64_t sequence = 0;
    uint32_t sampleRate = 48000;
    float peakL = 0.0f;
    float peakR = 0.0f;
    float rmsL = 0.0f;
    float rmsR = 0.0f;
};

/// Attempts one non-blocking seqlock read. A false result contains no usable
/// snapshot; callers may retry without ever delaying the audio thread.
bool tryReadGraphTapMeter(const GraphTapRuntime& runtime,
                          GraphTapMeterSnapshot& snapshot) noexcept;

void resetGraphTapRuntime(GraphTapRuntime& runtime, uint32_t generation) noexcept;
void processGraphTap(GraphTapRuntime& runtime,
                     const CompiledGraphTap& tap,
                     const float* left,
                     const float* right,
                     int numFrames,
                     double sampleRate) noexcept;

struct MidiPlaybackNote;
void processGraphMidiTap(GraphTapRuntime& runtime,
                         const CompiledGraphTap& tap,
                         const MidiPlaybackNote* notes,
                         int noteCount) noexcept;

/// Audio-thread-owned state for a compiled route delay. The compiler keeps the
/// required delay on the immutable edge; this storage only carries samples
/// between callback blocks and is never allocated or locked by the callback.
struct ProcessorGraphDelayLine {
    std::array<float, kMaxProcessorGraphLatencySamples> left{};
    std::array<float, kMaxProcessorGraphLatencySamples> right{};
    uint16_t delaySamples = 0;
    uint16_t writePosition = 0;
};

/// Immutable playback description. Built on the control thread, then read
/// without allocation or graph traversal on the audio thread.
struct ProcessorGraphSnapshot {
    std::array<uint8_t, kMaxProcessorGraphTracks> executionOrder{};
    std::array<ProcessorGraphEdge, kMaxProcessorGraphEdges> audioEdges{};
    std::array<ProcessorGraphEdge, kMaxProcessorGraphEdges> midiEdges{};
    std::array<CompiledGraphTap, kMaxProcessorGraphTaps> taps{};
    uint8_t trackCount = 0;
    uint8_t audioEdgeCount = 0;
    uint8_t midiEdgeCount = 0;
    uint8_t audioBufferSlotCount = 0;
    uint8_t midiBufferSlotCount = 0;
    uint8_t feedbackBufferSlotCount = 0;
    uint8_t tapCount = 0;
    uint16_t maxLatencySamples = 0;
    ProcessorGraphError error = ProcessorGraphError::None;

    bool valid() const noexcept { return error == ProcessorGraphError::None; }
};

ProcessorGraphSnapshot buildProcessorGraph(
    std::span<const GraphTrackDefinition> tracks,
    std::span<const GraphTapDefinition> taps = {}) noexcept;

} // namespace audioapp
