#include "audioapp/DeviceSubgraph.hpp"

#include "audioapp/devices/DeviceSlot.hpp"

#include <algorithm>
#include <functional>

namespace audioapp {
namespace {

bool isMidiOnly(DeviceNodeKind kind) noexcept {
    return kind == DeviceNodeKind::MidiDelay || kind == DeviceNodeKind::MidiReceiver;
}

bool isInstrument(DeviceNodeKind kind) noexcept {
    return isInstrumentDeviceNodeKind(kind) || kind == DeviceNodeKind::DrumMachine;
}

bool hasPureInputTrim(DeviceNodeKind kind) noexcept {
    switch (kind) {
        case DeviceNodeKind::Gate:
        case DeviceNodeKind::Compressor:
        case DeviceNodeKind::Expander:
        case DeviceNodeKind::Limiter:
        case DeviceNodeKind::Delay:
        case DeviceNodeKind::Reverb:
        case DeviceNodeKind::Chorus:
        case DeviceNodeKind::Phaser:
        case DeviceNodeKind::Bitcrusher:
        case DeviceNodeKind::Distortion:
        case DeviceNodeKind::Tremolo:
            return true;
        default:
            return false;
    }
}

} // namespace

DeviceExecutionPlan compileDeviceExecutionPlan(DeviceNodeKind kind) noexcept {
    DeviceExecutionPlan plan;
    plan.logical.deviceKind = kind;
    const DevicePortMask input = isMidiOnly(kind)
        ? DevicePortMask::Midi
        : (isInstrument(kind) ? DevicePortMask::Midi
                              : DevicePortMask::Audio);
    const DevicePortMask output = isMidiOnly(kind)
        ? DevicePortMask::Midi
        : DevicePortMask::Audio;

    plan.logical.nodes[0] = {DeviceSubgraphNodeRole::InputAdapter, input, input};
    plan.logical.nodes[1] = {DeviceSubgraphNodeRole::DeviceProcessor, input, output};
    plan.logical.nodes[2] = {DeviceSubgraphNodeRole::OutputAdapter, output, output};
    plan.inputAdapterOwnsTrim = hasPureInputTrim(kind);
    return plan;
}

bool DeviceExecutionPlan::valid() const noexcept {
    return logical.nodes[0].role == DeviceSubgraphNodeRole::InputAdapter &&
           logical.nodes[1].role == DeviceSubgraphNodeRole::DeviceProcessor &&
           logical.nodes[2].role == DeviceSubgraphNodeRole::OutputAdapter &&
           logical.edges[0].sourceNode == 0 && logical.edges[0].destinationNode == 1 &&
           logical.edges[1].sourceNode == 1 && logical.edges[1].destinationNode == 2;
}

DeviceSubgraphTree buildDeviceSubgraphTree(const DeviceSlot& slot) {
    DeviceSubgraphTree tree;
    tree.deviceId = slot.id;
    tree.plan = compileDeviceExecutionPlan(
        deviceNodeKindFromTypeId(slot.config.typeId));

    auto appendSlots = [](const auto& slots, auto& destination) {
        destination.reserve(slots.size());
        for (const auto& child : slots) {
            if (child) destination.push_back(buildDeviceSubgraphTree(*child));
        }
    };
    appendSlots(slot.noteFxDevices, tree.noteFx);
    appendSlots(slot.audioFxDevices, tree.audioFx);

    if (const auto* chain = std::get_if<ChainModel>(&slot.config.instance)) {
        appendSlots(chain->devices, tree.chainChildren);
    }
    if (const auto* split = std::get_if<SplitModel>(&slot.config.instance)) {
        appendSlots(split->branch0, tree.splitBranch0);
        appendSlots(split->branch1, tree.splitBranch1);
    }
    if (const auto* mb = std::get_if<MultibandSplitModel>(&slot.config.instance)) {
        for (int b = 0; b < mb->bandCount && b < 4; ++b)
            appendSlots(mb->bands[b], tree.multibandBands[static_cast<size_t>(b)]);
    }
    if (const auto* sl = std::get_if<SpectralLoudSplitModel>(&slot.config.instance)) {
        appendSlots(sl->preFxDevices, tree.spectralPreFx);
        appendSlots(sl->postFxDevices, tree.spectralPostFx);
        for (int b = 0; b < kSpectralLoudBands; ++b)
            appendSlots(sl->bands[b], tree.spectralBands[static_cast<size_t>(b)]);
    }
    if (const auto* drum = std::get_if<DrumMachineModel>(&slot.config.instance)) {
        for (const auto& pad : drum->pads) {
            if (pad.devices.empty()) continue;
            DeviceSubgraphTree::DrumPadBranch branch;
            branch.note = pad.note;
            appendSlots(pad.devices, branch.children);
            tree.drumPads.push_back(std::move(branch));
        }
    }
    return tree;
}

DeviceSubgraphTree buildDeviceSubgraphTree(const DeviceNodePlayback& node) {
    DeviceSubgraphTree tree;
    tree.deviceId = node.deviceId;
    tree.plan = compileDeviceExecutionPlan(node.kind);

    if (const auto* chain = std::get_if<ChainParams>(&node.params);
        chain != nullptr && chain->playback != nullptr) {
        tree.chainChildren.reserve(static_cast<size_t>(chain->playback->deviceCount));
        for (int index = 0; index < chain->playback->deviceCount; ++index) {
            tree.chainChildren.push_back(
                buildDeviceSubgraphTree(chain->playback->devices[index]));
        }
    }
    if (const auto* drum = std::get_if<DrumMachineParams>(&node.params);
        drum != nullptr && drum->playback != nullptr) {
        for (int note = 0; note < 128; ++note) {
            const auto& pad = drum->playback->pads[note];
            if (pad.deviceCount <= 0) continue;
            DeviceSubgraphTree::DrumPadBranch branch;
            branch.note = note;
            branch.children.reserve(static_cast<size_t>(pad.deviceCount));
            for (int index = 0; index < pad.deviceCount; ++index) {
                branch.children.push_back(buildDeviceSubgraphTree(pad.devices[index]));
            }
            tree.drumPads.push_back(std::move(branch));
        }
    }
    if (const auto* split = std::get_if<SplitParams>(&node.params);
        split != nullptr && split->playback != nullptr) {
        auto appendBranch = [](const SplitBranchPlayback& branch, auto& destination) {
            destination.reserve(static_cast<size_t>(branch.deviceCount));
            for (int index = 0; index < branch.deviceCount; ++index) {
                destination.push_back(buildDeviceSubgraphTree(branch.devices[index]));
            }
        };
        appendBranch(split->playback->branches[0], tree.splitBranch0);
        appendBranch(split->playback->branches[1], tree.splitBranch1);
    }
    if (const auto* mb = std::get_if<MultibandSplitParams>(&node.params);
        mb != nullptr && mb->playback != nullptr) {
        const int bandCount = std::clamp(mb->playback->bandCount, 2, 4);
        for (int b = 0; b < bandCount; ++b) {
            const auto& branch = mb->playback->bands[b];
            auto& destination = tree.multibandBands[static_cast<size_t>(b)];
            destination.reserve(static_cast<size_t>(branch.deviceCount));
            for (int index = 0; index < branch.deviceCount; ++index)
                destination.push_back(buildDeviceSubgraphTree(branch.devices[index]));
        }
    }
    if (const auto* sl = std::get_if<SpectralLoudSplitParams>(&node.params);
        sl != nullptr && sl->playback != nullptr) {
        auto appendBranch = [](const SplitBranchPlayback& branch, auto& destination) {
            destination.reserve(static_cast<size_t>(branch.deviceCount));
            for (int index = 0; index < branch.deviceCount; ++index)
                destination.push_back(buildDeviceSubgraphTree(branch.devices[index]));
        };
        appendBranch(sl->playback->preFx, tree.spectralPreFx);
        appendBranch(sl->playback->postFx, tree.spectralPostFx);
        for (int b = 0; b < kSpectralLoudBands; ++b)
            appendBranch(sl->playback->bands[b], tree.spectralBands[static_cast<size_t>(b)]);
    }
    return tree;
}

uint64_t stableDeviceSubgraphNodeId(std::string_view deviceId,
                                    DeviceSubgraphNodeRole role) noexcept {
    // FNV-1a: deterministic across processes and independent of pointer
    // addresses, which makes it suitable for later processor-instance reuse.
    uint64_t hash = 1469598103934665603ull;
    for (const char c : deviceId) {
        hash ^= static_cast<uint8_t>(c);
        hash *= 1099511628211ull;
    }
    hash ^= static_cast<uint8_t>(role);
    hash *= 1099511628211ull;
    return hash;
}

CompiledDeviceSubgraphSchedule compileDeviceSubgraphTree(
    const DeviceSubgraphTree& root) noexcept {
    CompiledDeviceSubgraphSchedule schedule;
    auto append = [&](const DeviceSubgraphTree& tree,
                      uint64_t parentProcessorNodeId,
                      uint8_t depth,
                      auto&& appendRef) noexcept -> void {
        const auto appendStage = [&](DeviceSubgraphNodeRole role,
                                     CompiledDeviceSubgraphStage stage) {
            if (schedule.stepCount >= kMaxCompiledDeviceSubgraphSteps) {
                schedule.overflow = true;
                return;
            }
            schedule.steps[schedule.stepCount++] = {
                stableDeviceSubgraphNodeId(tree.deviceId, role),
                parentProcessorNodeId,
                tree.plan.logical.deviceKind,
                stage,
                depth,
            };
        };
        appendStage(DeviceSubgraphNodeRole::InputAdapter,
                    CompiledDeviceSubgraphStage::InputAdapter);
        // Note FX are MIDI processors and therefore execute before the
        // instrument's DSP. Audio FX execute after its generated audio.
        for (const auto& child : tree.noteFx) {
            const uint64_t processorId = stableDeviceSubgraphNodeId(
                tree.deviceId, DeviceSubgraphNodeRole::DeviceProcessor);
            appendRef(child, processorId, depth + 1, appendRef);
        }
        appendStage(DeviceSubgraphNodeRole::DeviceProcessor,
                    CompiledDeviceSubgraphStage::DeviceProcessor);
        const uint64_t processorId = stableDeviceSubgraphNodeId(
            tree.deviceId, DeviceSubgraphNodeRole::DeviceProcessor);
        for (const auto& child : tree.audioFx) appendRef(child, processorId, depth + 1, appendRef);
        for (const auto& child : tree.chainChildren) appendRef(child, processorId, depth + 1, appendRef);
        for (const auto& pad : tree.drumPads)
            for (const auto& child : pad.children) appendRef(child, processorId, depth + 1, appendRef);
        for (const auto& child : tree.splitBranch0) appendRef(child, processorId, depth + 1, appendRef);
        for (const auto& child : tree.splitBranch1) appendRef(child, processorId, depth + 1, appendRef);
        for (const auto& band : tree.multibandBands)
            for (const auto& child : band) appendRef(child, processorId, depth + 1, appendRef);
        for (const auto& child : tree.spectralPreFx) appendRef(child, processorId, depth + 1, appendRef);
        for (const auto& band : tree.spectralBands)
            for (const auto& child : band) appendRef(child, processorId, depth + 1, appendRef);
        for (const auto& child : tree.spectralPostFx) appendRef(child, processorId, depth + 1, appendRef);
        appendStage(DeviceSubgraphNodeRole::OutputAdapter,
                    CompiledDeviceSubgraphStage::OutputAdapter);
    };
    append(root, 0, 0, append);
    return schedule;
}

CompiledDeviceExecutionOrder compileFusedChildExecutionOrder(
    const CompiledDeviceSubgraphSchedule& schedule,
    std::span<const DeviceNodePlayback> directChildren) noexcept {
    CompiledDeviceExecutionOrder order;
    if (!schedule.valid() || directChildren.size() > order.deviceIndices.size()) {
        return order;
    }

    for (uint16_t stepIndex = 0; stepIndex < schedule.stepCount; ++stepIndex) {
        const auto& step = schedule.steps[stepIndex];
        if (step.stage != CompiledDeviceSubgraphStage::DeviceProcessor) continue;
        for (uint16_t childIndex = 0;
             childIndex < static_cast<uint16_t>(directChildren.size()); ++childIndex) {
            if (step.stableNodeId != stableDeviceSubgraphNodeId(
                    directChildren[childIndex].deviceId,
                    DeviceSubgraphNodeRole::DeviceProcessor)) {
                continue;
            }
            bool alreadyPresent = false;
            for (uint8_t existing = 0; existing < order.count; ++existing) {
                alreadyPresent |= order.deviceIndices[existing] == childIndex;
            }
            if (!alreadyPresent && order.count < order.deviceIndices.size()) {
                order.deviceIndices[order.count++] = childIndex;
            }
            break;
        }
    }
    order.complete = order.count == directChildren.size();
    return order;
}

CompiledDeviceExecutionOrder compileFusedForestExecutionOrder(
    std::span<const DeviceSubgraphTree> roots,
    std::span<const DeviceNodePlayback> flattenedDevices) noexcept {
    CompiledDeviceExecutionOrder order;
    if (flattenedDevices.size() > order.deviceIndices.size()) return order;
    for (const auto& root : roots) {
        const auto schedule = compileDeviceSubgraphTree(root);
        if (!schedule.valid()) return {};
        const auto part = compileFusedChildExecutionOrder(schedule, flattenedDevices);
        for (uint8_t item = 0; item < part.count; ++item) {
            const uint16_t index = part.deviceIndices[item];
            bool alreadyPresent = false;
            for (uint8_t existing = 0; existing < order.count; ++existing) {
                alreadyPresent |= order.deviceIndices[existing] == index;
            }
            if (!alreadyPresent && order.count < order.deviceIndices.size()) {
                order.deviceIndices[order.count++] = index;
            }
        }
    }
    order.complete = order.count == flattenedDevices.size();
    return order;
}

} // namespace audioapp
