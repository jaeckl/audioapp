#pragma once

#include <array>
#include <cstdint>
#include <string>
#include <string_view>
#include <span>
#include <vector>

#include "audioapp/DeviceChain.hpp"

namespace audioapp {

struct DeviceSlot;

enum class DeviceSubgraphNodeRole : uint8_t {
    InputAdapter,
    DeviceProcessor,
    OutputAdapter,
};

enum class DevicePortMask : uint8_t {
    None = 0,
    Audio = 1 << 0,
    Midi = 1 << 1,
};

constexpr DevicePortMask operator|(DevicePortMask a, DevicePortMask b) noexcept {
    return static_cast<DevicePortMask>(static_cast<uint8_t>(a) | static_cast<uint8_t>(b));
}

constexpr bool hasPort(DevicePortMask ports, DevicePortMask port) noexcept {
    return (static_cast<uint8_t>(ports) & static_cast<uint8_t>(port)) != 0;
}

struct DeviceSubgraphNode {
    DeviceSubgraphNodeRole role = DeviceSubgraphNodeRole::DeviceProcessor;
    DevicePortMask inputPorts = DevicePortMask::None;
    DevicePortMask outputPorts = DevicePortMask::None;
};

struct DeviceSubgraphEdge {
    uint8_t sourceNode = 0;
    uint8_t destinationNode = 0;
};

/// Control-thread logical representation. Each built-in device exposes this
/// same three-node topology even when the compiled audio plan fuses it.
struct DeviceSubgraphDefinition {
    DeviceNodeKind deviceKind = DeviceNodeKind::Unknown;
    std::array<DeviceSubgraphNode, 3> nodes{};
    std::array<DeviceSubgraphEdge, 2> edges{{{0, 1}, {1, 2}}};
};

/// Audio-thread execution contract. The default plan deliberately fuses all
/// three logical nodes; it is metadata, not an extra processor or buffer.
struct DeviceExecutionPlan {
    DeviceSubgraphDefinition logical{};
    bool fuseInputWithProcessor = true;
    bool fuseProcessorWithOutput = true;
    /// A legacy inputGain parameter is a pure pre-DSP trim. Its dry signal is
    /// captured before this fused adapter so outputMix keeps prior semantics.
    bool inputAdapterOwnsTrim = false;
    bool valid() const noexcept;
};

DeviceExecutionPlan compileDeviceExecutionPlan(DeviceNodeKind kind) noexcept;

/// Control-thread hierarchy for device containers. This is intentionally not
/// embedded in the realtime execution plan: vectors and strings belong to the
/// graph-definition/compiler side, never the audio callback.
struct DeviceSubgraphTree {
    struct DrumPadBranch {
        int note = 0;
        std::vector<DeviceSubgraphTree> children;
    };

    std::string deviceId;
    DeviceExecutionPlan plan{};
    std::vector<DeviceSubgraphTree> noteFx;
    std::vector<DeviceSubgraphTree> audioFx;
    std::vector<DeviceSubgraphTree> chainChildren;
    std::vector<DrumPadBranch> drumPads;
    std::vector<DeviceSubgraphTree> splitBranch0;
    std::vector<DeviceSubgraphTree> splitBranch1;
};

DeviceSubgraphTree buildDeviceSubgraphTree(const DeviceSlot& slot);
/// Playback-snapshot equivalent used by container processors. Unlike the
/// editable DeviceSlot tree it contains no vectors owned by the audio thread.
DeviceSubgraphTree buildDeviceSubgraphTree(const DeviceNodePlayback& node);

enum class CompiledDeviceSubgraphStage : uint8_t {
    InputAdapter,
    DeviceProcessor,
    OutputAdapter,
};

struct CompiledDeviceSubgraphStep {
    uint64_t stableNodeId = 0;
    uint64_t parentProcessorNodeId = 0;
    DeviceNodeKind deviceKind = DeviceNodeKind::Unknown;
    CompiledDeviceSubgraphStage stage = CompiledDeviceSubgraphStage::DeviceProcessor;
    uint8_t depth = 0;
};

/// Fixed-size, control-thread compiler output. It deliberately contains no
/// processor pointers: runtime-instance ownership is the next migration step.
static constexpr int kMaxCompiledDeviceSubgraphSteps = 512;
struct CompiledDeviceSubgraphSchedule {
    std::array<CompiledDeviceSubgraphStep, kMaxCompiledDeviceSubgraphSteps> steps{};
    uint16_t stepCount = 0;
    bool overflow = false;
    bool valid() const noexcept { return !overflow; }
};

uint64_t stableDeviceSubgraphNodeId(std::string_view deviceId,
                                    DeviceSubgraphNodeRole role) noexcept;
CompiledDeviceSubgraphSchedule compileDeviceSubgraphTree(
    const DeviceSubgraphTree& root) noexcept;

/// Fused executor input: maps the DSP stages selected by a nested schedule to
/// the container arena's direct child indices. The audio thread only iterates
/// this fixed array; it never traverses a tree or resolves device IDs.
struct CompiledDeviceExecutionOrder {
    std::array<uint16_t, kMaxDevicesPerTrack> deviceIndices{};
    uint8_t count = 0;
    bool complete = false;
    bool valid() const noexcept { return complete; }
};

CompiledDeviceExecutionOrder compileFusedChildExecutionOrder(
    const CompiledDeviceSubgraphSchedule& schedule,
    std::span<const DeviceNodePlayback> directChildren) noexcept;
CompiledDeviceExecutionOrder compileFusedForestExecutionOrder(
    std::span<const DeviceSubgraphTree> roots,
    std::span<const DeviceNodePlayback> flattenedDevices) noexcept;

} // namespace audioapp
