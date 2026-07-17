#include "audioapp/ProjectEngine.hpp"
#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/ProjectJson.hpp"
#include "audioapp/ClipContentPlayback.hpp"
#include "audioapp/TimelineClipTypes.hpp"
#include "audioapp/MidiUtils.hpp"
#include "audioapp/MasterMix.hpp"
#include "audioapp/SamplePlaybackAlgorithm.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/DeviceChainOrchestrator.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/DeviceChainOrchestrator.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/devices/instances/BassSynthModel.hpp"
#include "audioapp/devices/instances/PhaseModSynthModel.hpp"
#include "audioapp/devices/instances/SamplerModel.hpp"
#include "audioapp/devices/instances/FrequencyFxModel.hpp"
#include "audioapp/DynamicsProcessor.hpp"
#include "audioapp/KickAlgorithm.hpp"
#include "audioapp/SnareAlgorithm.hpp"
#include "audioapp/ClapAlgorithm.hpp"
#include "audioapp/CymbalAlgorithm.hpp"
#include "audioapp/CrashAlgorithm.hpp"
#include "audioapp/SubtractiveSynthAlgorithm.hpp"
#include "audioapp/effects/DelayParams.hpp"
#include "audioapp/effects/ReverbParams.hpp"
#include "audioapp/effects/ChorusParams.hpp"
#include "audioapp/TrackFreeze.hpp"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstring>
#include <cstdlib>
#include <functional>
#include <sstream>
#include <unordered_map>
#include <vector>

namespace audioapp {

namespace {
thread_local DeviceChainScratch gProjectScratch;

bool supportsCompiledNormalizedParameter(DeviceNodeKind kind) noexcept {
    switch (kind) {
    case DeviceNodeKind::Oscillator:
    case DeviceNodeKind::Sampler:
    case DeviceNodeKind::SubtractiveSynth:
    case DeviceNodeKind::WavetableSynth:
    case DeviceNodeKind::PhaseModSynth:
    case DeviceNodeKind::Delay:
    case DeviceNodeKind::KickGenerator:
    case DeviceNodeKind::SnareGenerator:
    case DeviceNodeKind::ClapGenerator:
    case DeviceNodeKind::CymbalGenerator:
    case DeviceNodeKind::CrashGenerator:
    case DeviceNodeKind::Gate:
    case DeviceNodeKind::Compressor:
    case DeviceNodeKind::Expander:
    case DeviceNodeKind::Limiter:
    case DeviceNodeKind::BassSynth:
    case DeviceNodeKind::Filter:
    case DeviceNodeKind::FourBandEq:
    case DeviceNodeKind::FrequencyShifter:
    case DeviceNodeKind::Bitcrusher:
    case DeviceNodeKind::Distortion:
    case DeviceNodeKind::Tremolo:
    case DeviceNodeKind::ResonatorBank:
    case DeviceNodeKind::AudioReceiver:
    case DeviceNodeKind::MidiReceiver:
    case DeviceNodeKind::Chain:
    case DeviceNodeKind::Granular:
    case DeviceNodeKind::Stutter:
    case DeviceNodeKind::Chorus:
    case DeviceNodeKind::Reverb:
    case DeviceNodeKind::Phaser:
        return true;
    default:
        return false;
    }
}

// This deliberately compares the full playback payload rather than only the
// device ID/type. Sharing an arena is safe only when a rebuild would not need
// to write into its processors; parameter changes continue through the live
// command path or get a freshly built arena.
bool playbackNodesEquivalent(const DeviceNodePlayback& a,
                             const DeviceNodePlayback& b) noexcept {
    return a.kind == b.kind &&
           a.deviceId == b.deviceId &&
           a.bypassed == b.bypassed &&
           a.gain == b.gain &&
           a.pan == b.pan &&
           a.outputMix == b.outputMix &&
           a.outputWidth == b.outputWidth &&
           a.meterSlot == b.meterSlot &&
           a.automationTargetIndex == b.automationTargetIndex &&
           a.voicePolicy.maxVoices == b.voicePolicy.maxVoices &&
           a.voicePolicy.retriggerReplacesVoice == b.voicePolicy.retriggerReplacesVoice &&
           a.params.index() == b.params.index() &&
           std::memcmp(&a.params, &b.params, sizeof(DeviceVariantParams)) == 0;
}

void collectDeviceTreeIds(const DeviceSlot& slot, std::vector<std::string>& ids) {
    ids.push_back(slot.id);
    if (slot.config.typeId == device_types::kChain) {
        for (const auto& child : std::get<ChainModel>(slot.config.instance).devices)
            if (child) collectDeviceTreeIds(*child, ids);
    } else if (slot.config.typeId == device_types::kDrumMachine) {
        for (const auto& pad : std::get<DrumMachineModel>(slot.config.instance).pads)
            for (const auto& child : pad.devices)
                if (child) collectDeviceTreeIds(*child, ids);
    }
    for (const auto& child : slot.noteFxDevices)
        if (child) collectDeviceTreeIds(*child, ids);
    for (const auto& child : slot.audioFxDevices)
        if (child) collectDeviceTreeIds(*child, ids);
}

void addMetronomeClick(float* left, float* right, int frames, double sampleRate,
                       double startBeat, int bpm, float level) noexcept {
    if (!left || !right || frames <= 0 || sampleRate <= 0.0 || bpm <= 0 || level <= 0.0f) return;
    const double beatsPerFrame = (static_cast<double>(bpm) / 60.0) / sampleRate;
    for (int frame = 0; frame < frames; ++frame) {
        const double beat = startBeat + static_cast<double>(frame) * beatsPerFrame;
        const double whole = std::floor(beat + 1.0e-9);
        const double seconds = (beat - whole) * 60.0 / static_cast<double>(bpm);
        if (seconds < 0.0 || seconds >= 0.045) continue;
        const int beatIndex = static_cast<int>(whole);
        const bool accent = ((beatIndex % 4) + 4) % 4 == 0;
        const double hz = accent ? 1760.0 : 1200.0;
        const float envelope = static_cast<float>(std::exp(-seconds * 95.0));
        const float click = std::sin(static_cast<float>(seconds * hz * 2.0 * juce::MathConstants<double>::pi))
            * envelope * level * (accent ? 0.42f : 0.30f);
        left[frame] += click;
        right[frame] += click;
    }
}
} // namespace

void ProjectEngine::createProject() {
    const juce::ScopedWriteLock lock(mutex_);
    clearGraphTapsLocked();
    trackRepo_.clear();
    clipRepo_.clear();
    automationClipStore_.clear();
    projectName_ = "Untitled";
    transport_.reset();
    modulationGraph_.clear();
    activeFrequencyHz_.store(440.0f, std::memory_order_release);
    masterGain_.store(1.0f, std::memory_order_release);
    countInRemainingBeats_.store(0.0, std::memory_order_release);
    trackPlayback_.setCount(0);

    // Reset ValueTree root + re-register as listener
    projectRoot_ = state::createProjectTree();
    projectRoot_.addListener(this);
}

std::string ProjectEngine::addTrack(const std::string& name) {
    const juce::ScopedWriteLock lock(mutex_);
    const std::string trackId = trackRepo_.addTrack(name, deviceRegistry_);
    syncActiveFrequencyLocked();
    rebuildTrackPlaybackLocked();
    return trackId;
}

std::string ProjectEngine::addGroupTrack(const std::string& name) {
    const juce::ScopedWriteLock lock(mutex_);
    const std::string trackId = trackRepo_.addGroupTrack(name, deviceRegistry_);
    syncActiveFrequencyLocked();
    rebuildTrackPlaybackLocked();
    return trackId;
}

bool ProjectEngine::setTrackGroup(const std::string& trackId,
                                  const std::string& groupTrackId) {
    return moveTrack(trackId, groupTrackId, {});
}

bool ProjectEngine::moveTrack(const std::string& trackId,
                              const std::string& parentGroupId,
                              const std::string& beforeTrackId) {
    const juce::ScopedWriteLock lock(mutex_);
    const auto previousTracks = trackRepo_.tracks();
    if (!trackRepo_.moveTrack(trackId, parentGroupId, beforeTrackId)) {
        return false;
    }
    rebuildTrackPlaybackLocked();
    if (!processorGraphs_[lastBuiltProcessorGraph_].valid()) {
        trackRepo_.tracks() = previousTracks;
        rebuildTrackPlaybackLocked();
        return false;
    }
    return true;
}

bool ProjectEngine::setTrackMuted(const std::string& trackId, bool muted) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!trackRepo_.setTrackMuted(trackId, muted)) {
        return false;
    }
    syncProjectTreeLocked();
    RealtimeCommand command;
    command.type = RealtimeCommandType::TrackMute;
    command.targetId = trackId;
    command.value = muted ? 1.0f : 0.0f;
    return enqueueRealtimeCommand(std::move(command));
}

bool ProjectEngine::setTrackSoloed(const std::string& trackId, bool soloed) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!trackRepo_.setTrackSoloed(trackId, soloed)) {
        return false;
    }
    syncProjectTreeLocked();
    RealtimeCommand command;
    command.type = RealtimeCommandType::TrackSolo;
    command.targetId = trackId;
    command.value = soloed ? 1.0f : 0.0f;
    return enqueueRealtimeCommand(std::move(command));
}

bool ProjectEngine::selectTrack(const std::string& trackId) {
    const juce::ScopedWriteLock lock(mutex_);
    const bool selectionChanged = trackRepo_.selectedTrackId() != trackId;
    if (!trackRepo_.selectTrack(trackId)) {
        return false;
    }
    if (selectionChanged) {
        liveMixer_.allNotesOff();
    }
    syncActiveFrequencyLocked();
    syncProjectTreeLocked();
    return true;
}

std::string ProjectEngine::addDeviceToTrack(const std::string& trackId,
                                            const std::string& deviceType,
                                            int insertIndex) {
    const juce::ScopedWriteLock lock(mutex_);
    Track* track = trackRepo_.findTrack(trackId);
    if (track == nullptr) {
        return {};
    }

    const std::string resolvedType =
        deviceType.empty() ? device_types::kOscillator : deviceType;
    if (!deviceRegistry_.isKnownType(resolvedType)) {
        return {};
    }

    const std::string deviceId = trackRepo_.allocateDeviceId();
    DeviceSlot device = deviceRegistry_.createDefault(resolvedType, deviceId);

    size_t gainIndex = track->devices.size();
    for (size_t i = 0; i < track->devices.size(); ++i) {
        if (deviceNodeKindFromTypeId(track->devices[i].config.typeId) == DeviceNodeKind::TrackGain) {
            gainIndex = i;
            break;
        }
    }

    size_t insertAt = gainIndex;
    if (insertIndex >= 0) {
        insertAt = std::min(static_cast<size_t>(insertIndex), gainIndex);
    }

    track->devices.insert(track->devices.begin() + static_cast<std::ptrdiff_t>(insertAt),
                          std::move(device));
    syncActiveFrequencyLocked();
    rebuildTrackPlaybackLocked();
    return deviceId;
}

bool ProjectEngine::removeDeviceFromTrack(const std::string& deviceId) {
    const juce::ScopedWriteLock lock(mutex_);
    if (deviceId.empty()) {
        return false;
    }

    Track* ownerTrack = nullptr;
    size_t deviceIndex = 0;
    for (auto& track : trackRepo_.tracks()) {
        for (size_t i = 0; i < track.devices.size(); ++i) {
            if (track.devices[i].id == deviceId) {
                ownerTrack = &track;
                deviceIndex = i;
                break;
            }
        }
        if (ownerTrack != nullptr) {
            break;
        }
    }
    if (ownerTrack == nullptr) {
        return false;
    }

    const auto& slot = ownerTrack->devices[deviceIndex];
    if (deviceNodeKindFromTypeId(slot.config.typeId) == DeviceNodeKind::TrackGain) {
        return false;
    }

    ownerTrack->devices.erase(ownerTrack->devices.begin() + static_cast<std::ptrdiff_t>(deviceIndex));
    automationClipStore_.unlinkForDevice(deviceId);
    modulationGraph_.removeModulationForDevice(deviceId);
    liveMixer_.allNotesOff();
    syncActiveFrequencyLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

std::string ProjectEngine::addDeviceToDrumPad(const std::string& drumMachineId, int note,
                                              const std::string& deviceType, int insertIndex,
                                              const std::string& padName) {
    const juce::ScopedWriteLock lock(mutex_);
    DeviceSlot* machineSlot = findDeviceLocked(drumMachineId);
    if (machineSlot == nullptr || machineSlot->config.typeId != device_types::kDrumMachine ||
        note < 0 || note >= DrumMachineModel::kMidiNoteCount ||
        deviceType == device_types::kDrumMachine || !deviceRegistry_.isKnownType(deviceType)) return {};
    auto& pad = std::get<DrumMachineModel>(machineSlot->config.instance).pads[static_cast<size_t>(note)];
    if (!padName.empty()) pad.name = padName;
    if (pad.devices.size() >= DrumMachineModel::kMaxDevicesPerPad) return {};
    const std::string id = trackRepo_.allocateDeviceId();
    auto child = std::make_shared<DeviceSlot>(deviceRegistry_.createDefault(deviceType, id));
    size_t at = insertIndex < 0 ? pad.devices.size()
        : std::min(static_cast<size_t>(insertIndex), pad.devices.size());
    pad.devices.insert(pad.devices.begin() + static_cast<std::ptrdiff_t>(at), std::move(child));
    rebuildTrackPlaybackLocked();
    return id;
}

bool ProjectEngine::removeDeviceFromDrumPad(const std::string& drumMachineId, int note,
                                            const std::string& deviceId) {
    const juce::ScopedWriteLock lock(mutex_);
    DeviceSlot* machineSlot = findDeviceLocked(drumMachineId);
    if (machineSlot == nullptr || machineSlot->config.typeId != device_types::kDrumMachine ||
        note < 0 || note >= DrumMachineModel::kMidiNoteCount) return false;
    auto& pad = std::get<DrumMachineModel>(machineSlot->config.instance).pads[static_cast<size_t>(note)];
    const auto it = std::find_if(pad.devices.begin(), pad.devices.end(), [&](const auto& child) {
        return child != nullptr && child->id == deviceId;
    });
    if (it == pad.devices.end()) return false;
    pad.devices.erase(it);
    rebuildTrackPlaybackLocked();
    return true;
}

std::string ProjectEngine::addDeviceToChain(const std::string& chainId,
                                             const std::string& deviceType,
                                             int insertIndex) {
    const juce::ScopedWriteLock lock(mutex_);
    DeviceSlot* slot = findDeviceLocked(chainId);
    if (slot == nullptr || slot->config.typeId != device_types::kChain ||
        deviceType == device_types::kChain || !deviceRegistry_.isKnownType(deviceType)) return {};
    auto& devices = std::get<ChainModel>(slot->config.instance).devices;
    if (devices.size() >= 8) return {};
    const std::string id = trackRepo_.allocateDeviceId();
    auto child = std::make_shared<DeviceSlot>(deviceRegistry_.createDefault(deviceType, id));
    const size_t at = insertIndex < 0 ? devices.size()
        : std::min(static_cast<size_t>(insertIndex), devices.size());
    devices.insert(devices.begin() + static_cast<std::ptrdiff_t>(at), std::move(child));
    rebuildTrackPlaybackLocked();
    return id;
}

bool ProjectEngine::removeDeviceFromChain(const std::string& chainId,
                                           const std::string& deviceId) {
    const juce::ScopedWriteLock lock(mutex_);
    DeviceSlot* slot = findDeviceLocked(chainId);
    if (slot == nullptr || slot->config.typeId != device_types::kChain) return false;
    auto& devices = std::get<ChainModel>(slot->config.instance).devices;
    const auto it = std::find_if(devices.begin(), devices.end(), [&](const auto& child) {
        return child != nullptr && child->id == deviceId;
    });
    if (it == devices.end()) return false;
    devices.erase(it);
    automationClipStore_.unlinkForDevice(deviceId);
    modulationGraph_.removeModulationForDevice(deviceId);
    rebuildTrackPlaybackLocked();
    return true;
}

std::string ProjectEngine::addDeviceToSynthAudioFx(const std::string& deviceId,
                                                    const std::string& deviceType,
                                                    int insertIndex) {
    const juce::ScopedWriteLock lock(mutex_);
    DeviceSlot* slot = findDeviceLocked(deviceId);
    if (slot == nullptr || !device_types::isSynthType(slot->config.typeId) ||
        !device_types::isAudioFxType(deviceType)) return {};
    if (slot->audioFxDevices.size() >= 8) return {};
    const std::string id = trackRepo_.allocateDeviceId();
    auto child = std::make_shared<DeviceSlot>(deviceRegistry_.createDefault(deviceType, id));
    const size_t at = insertIndex < 0 ? slot->audioFxDevices.size()
        : std::min(static_cast<size_t>(insertIndex), slot->audioFxDevices.size());
    slot->audioFxDevices.insert(
        slot->audioFxDevices.begin() + static_cast<std::ptrdiff_t>(at), std::move(child));
    rebuildTrackPlaybackLocked();
    return id;
}

bool ProjectEngine::removeDeviceFromSynthAudioFx(const std::string& deviceId,
                                                   const std::string& subDeviceId) {
    const juce::ScopedWriteLock lock(mutex_);
    DeviceSlot* slot = findDeviceLocked(deviceId);
    if (slot == nullptr || !device_types::isSynthType(slot->config.typeId)) return false;
    auto& devices = slot->audioFxDevices;
    const auto it = std::find_if(devices.begin(), devices.end(), [&](const auto& child) {
        return child != nullptr && child->id == subDeviceId;
    });
    if (it == devices.end()) return false;
    std::vector<std::string> removedIds;
    collectDeviceTreeIds(**it, removedIds);
    devices.erase(it);
    for (const auto& id : removedIds) {
        automationClipStore_.unlinkForDevice(id);
        modulationGraph_.removeModulationForDevice(id);
    }
    rebuildTrackPlaybackLocked();
    return true;
}

std::string ProjectEngine::addDeviceToSynthNoteFx(const std::string& deviceId,
                                                    const std::string& deviceType,
                                                    int insertIndex) {
    const juce::ScopedWriteLock lock(mutex_);
    DeviceSlot* slot = findDeviceLocked(deviceId);
    if (slot == nullptr || !device_types::isSynthType(slot->config.typeId) ||
        !device_types::isNoteFxType(deviceType)) return {};
    if (slot->noteFxDevices.size() >= 8) return {};
    const std::string id = trackRepo_.allocateDeviceId();
    auto child = std::make_shared<DeviceSlot>(deviceRegistry_.createDefault(deviceType, id));
    const size_t at = insertIndex < 0 ? slot->noteFxDevices.size()
        : std::min(static_cast<size_t>(insertIndex), slot->noteFxDevices.size());
    slot->noteFxDevices.insert(
        slot->noteFxDevices.begin() + static_cast<std::ptrdiff_t>(at), std::move(child));
    rebuildTrackPlaybackLocked();
    return id;
}

bool ProjectEngine::removeDeviceFromSynthNoteFx(const std::string& deviceId,
                                                  const std::string& subDeviceId) {
    const juce::ScopedWriteLock lock(mutex_);
    DeviceSlot* slot = findDeviceLocked(deviceId);
    if (slot == nullptr || !device_types::isSynthType(slot->config.typeId)) return false;
    auto& devices = slot->noteFxDevices;
    const auto it = std::find_if(devices.begin(), devices.end(), [&](const auto& child) {
        return child != nullptr && child->id == subDeviceId;
    });
    if (it == devices.end()) return false;
    std::vector<std::string> removedIds;
    collectDeviceTreeIds(**it, removedIds);
    devices.erase(it);
    for (const auto& id : removedIds) {
        automationClipStore_.unlinkForDevice(id);
        modulationGraph_.removeModulationForDevice(id);
    }
    rebuildTrackPlaybackLocked();
    return true;
}

std::string ProjectEngine::getDevicePresetJson(const std::string& deviceId) const {
    const juce::ScopedReadLock lock(mutex_);
    std::function<const DeviceSlot*(const DeviceSlot&)> find = [&](const DeviceSlot& slot) -> const DeviceSlot* {
        if (slot.id == deviceId) return &slot;
        if (slot.config.typeId == device_types::kChain) {
            for (const auto& child : std::get<ChainModel>(slot.config.instance).devices) {
                if (child) if (const auto* found = find(*child)) return found;
            }
        } else if (slot.config.typeId == device_types::kDrumMachine) {
            for (const auto& pad : std::get<DrumMachineModel>(slot.config.instance).pads)
                for (const auto& child : pad.devices)
                    if (child) if (const auto* found = find(*child)) return found;
        }
        for (const auto& child : slot.audioFxDevices)
            if (child) if (const auto* found = find(*child)) return found;
        for (const auto& child : slot.noteFxDevices)
            if (child) if (const auto* found = find(*child)) return found;
        return nullptr;
    };
    for (const auto& track : trackRepo_.tracks())
        for (const auto& slot : track.devices)
            if (const auto* found = find(slot)) {
                std::vector<std::string> ids;
                collectDeviceTreeIds(*found, ids);
                const auto owns = [&](const std::string& id) {
                    return std::find(ids.begin(), ids.end(), id) != ids.end();
                };
                auto* root = new juce::DynamicObject();
                root->setProperty("presetVersion", 2);
                root->setProperty("device", deviceToVar(*found, deviceRegistry_));

                juce::Array<juce::var> clips;
                for (const auto& clip : automationClipStore_.clips()) {
                    if (!owns(clip.deviceId)) continue;
                    auto* value = new juce::DynamicObject();
                    value->setProperty("startBeat", clip.startBeat);
                    value->setProperty("lengthBeats", clip.lengthBeats);
                    value->setProperty("loopContent", clip.loopContent);
                    value->setProperty("deviceId", juce::String(clip.deviceId));
                    value->setProperty("paramId", juce::String(clip.paramId));
                    juce::Array<juce::var> points;
                    for (const auto& point : clip.points) {
                        auto* p = new juce::DynamicObject();
                        p->setProperty("beat", point.beat);
                        p->setProperty("value", point.value);
                        points.add(juce::var(p));
                    }
                    value->setProperty("points", points);
                    clips.add(juce::var(value));
                }
                root->setProperty("automationClips", clips);

                juce::Array<juce::var> edges;
                std::vector<int> referencedModulators;
                for (const auto& edge : modulationGraph_.modEdges()) {
                    if (!owns(edge.deviceId)) continue;
                    auto* value = new juce::DynamicObject();
                    value->setProperty("lfoId", edge.lfoId);
                    value->setProperty("deviceId", juce::String(edge.deviceId));
                    value->setProperty("paramId", juce::String(edge.paramId));
                    value->setProperty("amount", edge.amount);
                    edges.add(juce::var(value));
                    if (std::find(referencedModulators.begin(), referencedModulators.end(), edge.lfoId) == referencedModulators.end())
                        referencedModulators.push_back(edge.lfoId);
                }
                root->setProperty("modEdges", edges);
                juce::Array<juce::var> modulators;
                const juce::var allModulators = modulationGraph_.recordsToVar();
                if (const auto* all = allModulators.getArray()) {
                    for (const auto& value : *all) {
                        const auto* object = value.getDynamicObject();
                        if (object == nullptr) continue;
                        const int id = static_cast<int>(object->getProperty("id"));
                        if (std::find(referencedModulators.begin(), referencedModulators.end(), id) != referencedModulators.end())
                            modulators.add(value);
                    }
                }
                root->setProperty("modulators", modulators);
                return juce::JSON::toString(juce::var(root), true).toStdString();
            }
    return {};
}

bool ProjectEngine::applyDevicePresetJson(const std::string& deviceId,
                                          const std::string& presetJson) {
    const juce::ScopedWriteLock lock(mutex_);
    DeviceSlot* target = findDeviceLocked(deviceId);
    if (target == nullptr) return false;
    const juce::var presetRoot = juce::JSON::parse(juce::String::fromUTF8(presetJson.c_str()));
    const auto* presetObject = presetRoot.getDynamicObject();
    const juce::var deviceValue = presetObject != nullptr && presetObject->hasProperty("device")
        ? presetObject->getProperty("device") : presetRoot;
    DeviceSlot loaded = deviceFromVar(deviceValue, deviceRegistry_);
    if (loaded.id.empty() || loaded.config.typeId != target->config.typeId) return false;

    std::vector<std::string> removedChildIds;
    std::function<void(const DeviceSlot&)> collectChildren = [&](const DeviceSlot& slot) {
        if (slot.id != deviceId) removedChildIds.push_back(slot.id);
        if (slot.config.typeId == device_types::kChain) {
            for (const auto& child : std::get<ChainModel>(slot.config.instance).devices)
                if (child) collectChildren(*child);
        } else if (slot.config.typeId == device_types::kDrumMachine) {
            for (const auto& pad : std::get<DrumMachineModel>(slot.config.instance).pads)
                for (const auto& child : pad.devices) if (child) collectChildren(*child);
        }
        for (const auto& child : slot.audioFxDevices) if (child) collectChildren(*child);
        for (const auto& child : slot.noteFxDevices) if (child) collectChildren(*child);
    };
    collectChildren(*target);

    std::unordered_map<std::string, std::string> idMap;
    std::function<void(DeviceSlot&, bool)> renewIds = [&](DeviceSlot& slot, bool root) {
        const std::string oldId = slot.id;
        slot.id = root ? deviceId : trackRepo_.allocateDeviceId();
        idMap[oldId] = slot.id;
        if (slot.config.typeId == device_types::kChain) {
            for (auto& child : std::get<ChainModel>(slot.config.instance).devices)
                if (child) renewIds(*child, false);
        } else if (slot.config.typeId == device_types::kDrumMachine) {
            for (auto& pad : std::get<DrumMachineModel>(slot.config.instance).pads)
                for (auto& child : pad.devices) if (child) renewIds(*child, false);
        }
        for (auto& child : slot.audioFxDevices) if (child) renewIds(*child, false);
        for (auto& child : slot.noteFxDevices) if (child) renewIds(*child, false);
    };
    const bool bypassed = target->config.bypassed;
    renewIds(loaded, true);
    loaded.config.bypassed = bypassed;
    *target = std::move(loaded);
    const bool bundledPreset = presetObject != nullptr && presetObject->hasProperty("device");
    if (bundledPreset) {
        std::vector<std::string> clipIdsToRemove;
        for (const auto& clip : automationClipStore_.clips()) {
            if (clip.deviceId == deviceId ||
                std::find(removedChildIds.begin(), removedChildIds.end(), clip.deviceId) != removedChildIds.end())
                clipIdsToRemove.push_back(clip.id);
        }
        for (const auto& clipId : clipIdsToRemove) automationClipStore_.remove(clipId);
        modulationGraph_.removeModulationForDevice(deviceId);
    }
    for (const auto& childId : removedChildIds) {
        if (!bundledPreset) automationClipStore_.unlinkForDevice(childId);
        modulationGraph_.removeModulationForDevice(childId);
    }
    if (presetObject != nullptr) {
        std::string homeTrackId;
        for (const auto& track : trackRepo_.tracks()) {
            std::function<bool(const DeviceSlot&)> contains = [&](const DeviceSlot& slot) {
                if (slot.id == deviceId) return true;
                if (slot.config.typeId == device_types::kChain)
                    for (const auto& child : std::get<ChainModel>(slot.config.instance).devices)
                        if (child && contains(*child)) return true;
                for (const auto& child : slot.noteFxDevices) if (child && contains(*child)) return true;
                for (const auto& child : slot.audioFxDevices) if (child && contains(*child)) return true;
                return false;
            };
            for (const auto& slot : track.devices) if (contains(slot)) { homeTrackId = track.id; break; }
            if (!homeTrackId.empty()) break;
        }
        if (const auto* clips = presetObject->getProperty("automationClips").getArray()) {
            for (const auto& value : *clips) {
                const auto* object = value.getDynamicObject();
                if (object == nullptr) continue;
                const auto oldTarget = object->getProperty("deviceId").toString().toStdString();
                const auto mapped = idMap.find(oldTarget);
                if (mapped == idMap.end()) continue;
                const double start = static_cast<double>(object->getProperty("startBeat"));
                const double length = static_cast<double>(object->getProperty("lengthBeats"));
                const auto clipId = automationClipStore_.create(homeTrackId, start, length);
                automationClipStore_.assignTarget(clipId, mapped->second,
                    object->getProperty("paramId").toString().toStdString());
                std::vector<AutomationPointState> points;
                if (const auto* rawPoints = object->getProperty("points").getArray())
                    for (const auto& rawPoint : *rawPoints)
                        if (const auto* point = rawPoint.getDynamicObject())
                            points.push_back({static_cast<double>(point->getProperty("beat")),
                                              static_cast<float>(static_cast<double>(point->getProperty("value")))});
                automationClipStore_.setPoints(clipId, points);
                automationClipStore_.setLoopContent(clipId, static_cast<bool>(object->getProperty("loopContent")));
            }
        }

        ModulationGraph imported;
        imported.recordsFromVar(presetObject->getProperty("modulators"));
        auto records = modulationGraph_.lfos();
        auto edges = modulationGraph_.modEdges();
        int nextModId = 1;
        for (const auto& record : records) nextModId = std::max(nextModId, record.id + 1);
        std::unordered_map<int, int> modIdMap;
        for (auto record : imported.lfos()) {
            const int oldId = record.id;
            record.id = nextModId++;
            modIdMap[oldId] = record.id;
            records.push_back(std::move(record));
        }
        if (const auto* rawEdges = presetObject->getProperty("modEdges").getArray()) {
            for (const auto& value : *rawEdges) {
                const auto* object = value.getDynamicObject();
                if (object == nullptr) continue;
                const int oldModId = static_cast<int>(object->getProperty("lfoId"));
                const auto modIt = modIdMap.find(oldModId);
                const auto deviceIt = idMap.find(object->getProperty("deviceId").toString().toStdString());
                if (modIt == modIdMap.end() || deviceIt == idMap.end()) continue;
                edges.push_back({modIt->second, deviceIt->second,
                    object->getProperty("paramId").toString().toStdString(),
                    static_cast<float>(static_cast<double>(object->getProperty("amount")))});
            }
        }
        modulationGraph_.replaceRecords(records, edges);
    }
    liveMixer_.allNotesOff();
    syncProjectTreeLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::setDrumPadParameter(const std::string& drumMachineId, int note,
                                        const std::string& parameterId, float value) {
    const juce::ScopedWriteLock lock(mutex_);
    DeviceSlot* machineSlot = findDeviceLocked(drumMachineId);
    if (machineSlot == nullptr || machineSlot->config.typeId != device_types::kDrumMachine ||
        note < 0 || note >= DrumMachineModel::kMidiNoteCount) return false;
    auto& pad = std::get<DrumMachineModel>(machineSlot->config.instance).pads[static_cast<size_t>(note)];
    if (parameterId == "gain") pad.gain = std::clamp(value, 0.0f, 2.0f);
    else if (parameterId == "pan") pad.pan = std::clamp(value, 0.0f, 1.0f);
    else if (parameterId == "mute") pad.muted = value >= 0.5f;
    else if (parameterId == "solo") pad.solo = value >= 0.5f;
    else if (parameterId == "chokeGroup") pad.chokeGroup = std::clamp(static_cast<int>(std::lround(value)), 0, 16);
    else return false;
    syncProjectTreeLocked();
    RealtimeCommand command;
    command.type = RealtimeCommandType::DrumPad;
    command.targetId = drumMachineId;
    command.parameterId = parameterId;
    command.note = note;
    command.value = value;
    return enqueueRealtimeCommand(std::move(command));
}

bool ProjectEngine::setDeviceParameter(const std::string& deviceId,
                                       const std::string& parameterId,
                                       float value) {
    const juce::ScopedWriteLock lock(mutex_);
    DeviceSlot* device = findDeviceLocked(deviceId);
    if (device == nullptr) {
        return false;
    }
    const DeviceSlot previousDevice = *device;
    const bool routingDevice =
        isRoutingDeviceNodeKind(deviceNodeKindFromTypeId(device->config.typeId));
    const bool structuralRoutingParameter = routingDevice && parameterId == "feedback";
    const bool commonStripParameter = parameterId == "gain" || parameterId == "pan" ||
        parameterId == "bypass" || parameterId == "outputMix" ||
        parameterId == "outputWidth";

    const DeviceParameterResult result =
        deviceRegistry_.setParameter(*device, parameterId, value);
    if (!result.handled) {
        return false;
    }
    if (result.syncActiveFrequency) {
        syncActiveFrequencyLocked();
    }

    PlaybackBuildContext context{sampleBank_};
    context.wavetableBank = wavetableBank_;
    context.deviceRegistry = &deviceRegistry_;
    auto refreshCommonState = [&](DeviceNodePlayback& node) {
        node.bypassed = device->config.bypassed;
        std::visit([&](const auto& panel) {
            using T = std::decay_t<decltype(panel)>;
            if constexpr (std::is_same_v<T, MonoOutputPanel>) {
                node.gain = panel.gain;
                node.pan = 0.5f;
                node.outputMix = 1.0f;
                node.outputWidth = 1.0f;
            } else if constexpr (std::is_same_v<T, StereoOutputPanel>) {
                node.gain = panel.gain;
                node.pan = panel.pan;
                node.outputMix = panel.outputMix;
                node.outputWidth = panel.outputWidth;
            }
        }, device->config.outputPanel);
    };
    RealtimeCommand command;
    const uint64_t targetNodeId = stableDeviceSubgraphNodeId(
        deviceId, DeviceSubgraphNodeRole::DeviceProcessor);

    // Routing changes alter graph connectivity and therefore remain on the
    // structural path. Ordinary knobs only publish a block-boundary command.
    if (structuralRoutingParameter) {
        command.type = RealtimeCommandType::DeviceNode;
        command.targetId = deviceId;
        command.commonOnly = commonStripParameter;
        command.node.deviceId = deviceId;
        command.node.voicePolicy = InstrumentVoicePolicy{1, true};
        deviceRegistry_.buildPlaybackNode(*device, context, command.node);
        refreshCommonState(command.node);
        const std::lock_guard<std::recursive_mutex> playbackLock(playbackMutex_);
        const int trackCount = trackPlayback_.count();
        applyRealtimeDeviceNode(command.node, command.commonOnly);
        rebuildProcessorGraphLocked(trackCount);
        if (!processorGraphs_[lastBuiltProcessorGraph_].valid()) {
            *device = previousDevice;
            rebuildTrackPlaybackLocked();
            return false;
        }
        markDeviceOwnerFreezeStaleLocked(deviceId);
        return true;
    }

    markDeviceOwnerFreezeStaleLocked(deviceId);

    RealtimeParameterCommand parameterCommand;
    parameterCommand.targetNodeId = targetNodeId;
    if (parameterId == "gain") parameterCommand.encodedParameterId = kEncodedCommonGain;
    else if (parameterId == "pan") parameterCommand.encodedParameterId = kEncodedCommonPan;
    else if (parameterId == "bypass") parameterCommand.encodedParameterId = kEncodedCommonBypass;
    else if (parameterId == "outputMix") parameterCommand.encodedParameterId = kEncodedCommonOutputMix;
    else if (parameterId == "outputWidth") parameterCommand.encodedParameterId = kEncodedCommonOutputWidth;
    else if (const auto* type = deviceRegistry_.findForSlot(*device);
             type != nullptr && supportsCompiledNormalizedParameter(type->kind())) {
        const auto descriptors = type->paramDescriptors();
        const auto descriptor = std::find_if(
            descriptors.begin(), descriptors.end(), [&](const ParamDescriptor& candidate) {
                return parameterId == candidate.stableName;
            });
        if (descriptor != descriptors.end() && descriptor->automatable &&
            descriptor->maxValue > descriptor->minValue) {
            parameterCommand.encodedParameterId = encodeAutomationParamId(
                parameterId.c_str(), type->kind(), descriptor->localParamId);
            parameterCommand.value = std::clamp(
                (value - descriptor->minValue) /
                    (descriptor->maxValue - descriptor->minValue),
                0.0f, 1.0f);
            if (unpackParamKind(parameterCommand.encodedParameterId) != ParamKind::Common)
                return enqueueRealtimeParameter(parameterCommand);
        }
    }
    if (commonStripParameter) {
        parameterCommand.value = value;
        return enqueueRealtimeParameter(parameterCommand);
    }

    // Discrete and not-yet-normalized parameters retain the block-boundary
    // fallback until their typed stream policy is declared.
    command.type = RealtimeCommandType::DeviceNode;
    command.targetId = deviceId;
    command.commonOnly = false;
    command.node.deviceId = deviceId;
    command.node.voicePolicy = InstrumentVoicePolicy{1, true};
    deviceRegistry_.buildPlaybackNode(*device, context, command.node);
    refreshCommonState(command.node);
    return enqueueRealtimeCommand(std::move(command));
}

bool ProjectEngine::setDeviceStringParameter(const std::string& deviceId,
                                             const std::string& parameterId,
                                             const std::string& value) {
    const juce::ScopedWriteLock lock(mutex_);
    DeviceSlot* device = findDeviceLocked(deviceId);
    if (device == nullptr) {
        return false;
    }
    const DeviceSlot previousDevice = *device;
    const bool routingDevice =
        isRoutingDeviceNodeKind(deviceNodeKindFromTypeId(device->config.typeId));

    PlaybackBuildContext context{sampleBank_};
    context.wavetableBank = wavetableBank_;
    context.deviceRegistry = &deviceRegistry_;
    if (!deviceRegistry_.setStringParameter(*device, parameterId, value, context)) {
        return false;
    }

    // Fast path: update live playback node and processor in-place,
    // avoiding full track rebuild (which causes audible glitches).
    // String parameters (e.g. wavetableId, sampleId) just set runtime
    // state resolved at process time — no structural change needed.
    {
        const std::lock_guard<std::recursive_mutex> playbackLock(playbackMutex_);
        const int trackCount = trackPlayback_.count();
        for (int t = 0; t < trackCount; ++t) {
            auto& snap = trackPlayback_[t];
            for (int d = 0; d < snap.deviceCount; ++d) {
                if (snap.devices[d].deviceId == deviceId) {
                    const auto automationTargetIndex = snap.devices[d].automationTargetIndex;
                    const auto meterSlot = snap.devices[d].meterSlot;
                    deviceRegistry_.buildPlaybackNode(*device, context, snap.devices[d]);
                    snap.devices[d].automationTargetIndex = automationTargetIndex;
                    snap.devices[d].meterSlot = meterSlot;
                    if (auto* proc = snap.arena.get(d)) {
                        proc->applyPlaybackNode(snap.devices[d]);
                        proc->meterSlot = meterSlot;
                    }
                    if (routingDevice) {
                        rebuildProcessorGraphLocked(trackCount);
                        if (!processorGraphs_[lastBuiltProcessorGraph_].valid()) {
                            *device = previousDevice;
                            rebuildTrackPlaybackLocked();
                            return false;
                        }
                    }
                    markDeviceOwnerFreezeStaleLocked(deviceId);
                    return true;
                }
                DeviceNodePlayback nestedNode{};
                nestedNode.deviceId = deviceId;
                nestedNode.voicePolicy = InstrumentVoicePolicy{1, true};
                deviceRegistry_.buildPlaybackNode(*device, context, nestedNode);
                if (auto* proc = snap.arena.get(d);
                    proc != nullptr && proc->updateNestedDevice(nestedNode)) {
                    markDeviceOwnerFreezeStaleLocked(deviceId);
                    return true;
                }
            }
        }
    }

    // Fallback: device not in live playback arrays yet
    rebuildTrackPlaybackLocked();
    if (routingDevice) {
        if (!processorGraphs_[lastBuiltProcessorGraph_].valid()) {
            *device = previousDevice;
            rebuildTrackPlaybackLocked();
            return false;
        }
    }
    markDeviceOwnerFreezeStaleLocked(deviceId);
    return true;
}

bool ProjectEngine::setMasterGain(float gain) {
    masterGain_.store(std::clamp(gain, 0.0f, 1.0f), std::memory_order_release);
    return true;
}

std::string ProjectEngine::createMidiClip(const std::string& trackId,
                                          double startBeat,
                                          double lengthBeats) {
    const juce::ScopedWriteLock lock(mutex_);
    const auto* track = trackRepo_.findTrack(trackId);
    if (track == nullptr || track->isGroup || track->freeze.enabled) {
        return {};
    }
    const std::string clipId = clipRepo_.createMidiClip(trackId, startBeat, lengthBeats);
    if (clipId.empty()) {
        return {};
    }
    syncProjectTreeLocked();
    rebuildTrackPlaybackLocked();
    return clipId;
}

bool ProjectEngine::setMidiClipNotes(const std::string& clipId,
                                     const std::vector<MidiNoteState>& notes) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!clipRepo_.setMidiClipNotes(clipId, notes)) {
        return false;
    }
    syncProjectTreeLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::addMidiClipTake(const std::string& clipId,
                                    const std::string& name,
                                    double startBeatOffset,
                                    double lengthBeats,
                                    const std::vector<MidiNoteState>& notes) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!clipRepo_.addMidiClipTake(clipId, name, startBeatOffset, lengthBeats, notes)) {
        return false;
    }
    syncProjectTreeLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::setMidiClipTakeRegionTake(const std::string& clipId,
                                              int regionIndex,
                                              const std::string& takeId) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!clipRepo_.setMidiClipTakeRegionTake(clipId, regionIndex, takeId)) {
        return false;
    }
    syncProjectTreeLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::setMidiClipTakeAtBeat(const std::string& clipId,
                                          double beat,
                                          const std::string& takeId) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!clipRepo_.setMidiClipTakeAtBeat(clipId, beat, takeId)) {
        return false;
    }
    syncProjectTreeLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::splitMidiClipTakeRegionAtBeat(const std::string& clipId,
                                                  double beat) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!clipRepo_.splitMidiClipTakeRegionAtBeat(clipId, beat)) {
        return false;
    }
    syncProjectTreeLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::moveMidiClipTakeMarker(const std::string& clipId,
                                           int markerIndex,
                                           double beat) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!clipRepo_.moveMidiClipTakeMarker(clipId, markerIndex, beat)) {
        return false;
    }
    syncProjectTreeLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::setMidiClipTakeMarkerMode(const std::string& clipId,
                                              int markerIndex,
                                              bool holdPrevious) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!clipRepo_.setMidiClipTakeMarkerMode(clipId, markerIndex, holdPrevious)) {
        return false;
    }
    syncProjectTreeLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::flattenMidiComp(const std::string& clipId) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!clipRepo_.flattenMidiComp(clipId)) {
        return false;
    }
    syncProjectTreeLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::reopenMidiComp(const std::string& clipId) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!clipRepo_.reopenMidiComp(clipId)) {
        return false;
    }
    syncProjectTreeLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::deleteMidiClipTakeMarker(const std::string& clipId,
                                             int markerIndex) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!clipRepo_.deleteMidiClipTakeMarker(clipId, markerIndex)) {
        return false;
    }
    syncProjectTreeLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::setMidiClipEditorScale(const std::string& clipId,
                                           int root,
                                           const std::string& scaleId,
                                           bool highlight,
                                           bool snap,
                                           const std::string& chordQuality) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!clipRepo_.setMidiClipEditorScale(
            clipId, root, scaleId, highlight, snap, chordQuality)) {
        return false;
    }
    syncProjectTreeLocked();
    return true;
}

std::string ProjectEngine::createSampleClip(const std::string& trackId,
                                            const std::string& sampleId,
                                            double startBeat,
                                            double lengthBeats) {
    const juce::ScopedWriteLock lock(mutex_);
    const auto* track = trackRepo_.findTrack(trackId);
    if (track == nullptr || track->isGroup || track->freeze.enabled) {
        return {};
    }
    const std::string clipId = clipRepo_.createSampleClip(
        trackId, sampleId, startBeat, lengthBeats, sampleBank_, transport_.bpm());
    if (clipId.empty()) {
        return {};
    }
    rebuildTrackPlaybackLocked();
    return clipId;
}

std::string ProjectEngine::createRecordingSampleClipModelOnly(
    const std::string& trackId,
    const std::string& sampleId,
    double startBeat,
    double lengthBeats) {
    const juce::ScopedWriteLock lock(mutex_);
    const auto* track = trackRepo_.findTrack(trackId);
    if (track == nullptr || track->isGroup || track->freeze.enabled) {
        return {};
    }
    // Recording starts while transport/audio callback is already running.
    // Do not rebuild ProcessorArena here; finalizing after stop does that.
    return clipRepo_.createSampleClip(
        trackId, sampleId, startBeat, lengthBeats, sampleBank_, transport_.bpm());
}

std::string ProjectEngine::createAutomationClip(const std::string& homeTrackId,
                                                double startBeat,
                                                double lengthBeats) {
    const juce::ScopedWriteLock lock(mutex_);
    if (homeTrackId.empty()) {
        return {};
    }
    const auto* track = trackRepo_.findTrack(homeTrackId);
    if (track == nullptr || track->freeze.enabled) {
        return {};
    }
    const std::string clipId = automationClipStore_.create(homeTrackId, startBeat, lengthBeats);
    if (clipId.empty()) {
        return {};
    }
    rebuildTrackPlaybackLocked();
    return clipId;
}

bool ProjectEngine::assignAutomationTarget(const std::string& clipId,
                                           const std::string& deviceId,
                                           const std::string& paramId) {
    const juce::ScopedWriteLock lock(mutex_);
    if (findDeviceLocked(deviceId) == nullptr) {
        return false;
    }
    if (!automationClipStore_.assignTarget(clipId, deviceId, paramId)) {
        return false;
    }
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::unlinkAutomationTarget(const std::string& clipId) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!automationClipStore_.unlinkTarget(clipId)) {
        return false;
    }
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::setAutomationPoints(const std::string& clipId,
                                        const std::vector<AutomationPointState>& points) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!automationClipStore_.setPoints(clipId, points)) {
        return false;
    }
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::moveClip(const std::string& clipId,
                             const std::string& targetTrackId,
                             double startBeat) {
    const juce::ScopedWriteLock lock(mutex_);
    if (clipRepo_.findMidiClip(clipId) != nullptr ||
        clipRepo_.findSampleClip(clipId) != nullptr) {
        const auto* target = trackRepo_.findTrack(targetTrackId);
        if (target == nullptr || target->isGroup || target->freeze.enabled) {
            return false;
        }
        if (!clipRepo_.moveClip(clipId, targetTrackId, startBeat)) {
            return false;
        }
        rebuildTrackPlaybackLocked();
        return true;
    }
    // Automation clips live in the global store. Update both the
    // visual track lane (homeTrackId) and the beat position.
    if (!automationClipStore_.setStartBeat(clipId, startBeat)) {
        return false;
    }
    if (!targetTrackId.empty()) {
        const auto* target = trackRepo_.findTrack(targetTrackId);
        if (target != nullptr && target->freeze.enabled) {
            return false;
        }
        automationClipStore_.setHomeTrackId(clipId, targetTrackId);
    }
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::setClipLength(const std::string& clipId,
                                    double lengthBeats,
                                    ClipLengthTarget target) {
    const juce::ScopedWriteLock lock(mutex_);
    if (clipRepo_.findMidiClip(clipId) != nullptr ||
        clipRepo_.findSampleClip(clipId) != nullptr) {
        if (!clipRepo_.setClipLength(clipId, lengthBeats, target)) {
            return false;
        }
        rebuildTrackPlaybackLocked();
        return true;
    }
    if (!automationClipStore_.setLength(clipId, lengthBeats, target)) {
        return false;
    }
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::setClipLoopContent(const std::string& clipId, bool loopContent) {
    const juce::ScopedWriteLock lock(mutex_);
    bool updated = clipRepo_.setClipLoopContent(clipId, loopContent);
    if (!updated) {
        updated = automationClipStore_.setLoopContent(clipId, loopContent);
    }
    if (!updated) {
        return false;
    }
    syncProjectTreeLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::setSampleClipProperties(const std::string& clipId,
                                            float sourceStart, float sourceEnd,
                                            float gain, float fadeIn,
                                            float fadeOut, float fadeInCurve,
                                            float fadeOutCurve, bool reversed) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!clipRepo_.setSampleClipProperties(clipId, sourceStart, sourceEnd,
                                           gain, fadeIn, fadeOut, fadeInCurve,
                                           fadeOutCurve, reversed)) {
        return false;
    }
    syncProjectTreeLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::setSampleClipWarp(const std::string& clipId, bool warpRepitch) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!clipRepo_.setSampleClipWarp(clipId, warpRepitch)) return false;
    syncProjectTreeLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::setSampleClipSlices(const std::string& clipId,
                                        const std::vector<float>& markers) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!clipRepo_.setSampleClipSlices(clipId, markers)) return false;
    syncProjectTreeLocked();
    return true;
}

bool ProjectEngine::updateSampleClipRecordedLength(const std::string& clipId,
                                                   double lengthBeats) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!clipRepo_.updateSampleClipRecordedLength(clipId, lengthBeats)) return false;
    rebuildTrackPlaybackLocked();
    syncProjectTreeLocked();
    return true;
}

bool ProjectEngine::addRecordingTakeToSampleClip(const std::string& clipId,
                                                 const std::string& sampleId,
                                                 const std::string& name,
                                                 double recordStartBeat,
                                                 double lengthBeats) {
    const juce::ScopedWriteLock lock(mutex_);
    const auto* clip = clipRepo_.findSampleClip(clipId);
    if (clip == nullptr || sampleBank_ == nullptr || sampleBank_->findSample(sampleId) == nullptr) {
        return false;
    }
    for (const auto& track : trackRepo_.tracks()) {
        for (const auto& sampleClip : track.sampleClips) {
            if (sampleClip.id == clipId && (track.isGroup || track.freeze.enabled)) {
                return false;
            }
        }
    }
    const double startOffset = recordStartBeat - clip->startBeat;
    if (!clipRepo_.addSampleClipTake(clipId, sampleId, name, startOffset, lengthBeats)) {
        return false;
    }
    syncProjectTreeLocked();
    return true;
}

bool ProjectEngine::updateSampleClipRecordedTakeLength(const std::string& clipId,
                                                       const std::string& sampleId,
                                                       double lengthBeats) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!clipRepo_.updateSampleClipRecordedTakeLength(clipId, sampleId, lengthBeats)) {
        return false;
    }
    rebuildTrackPlaybackLocked();
    syncProjectTreeLocked();
    return true;
}

bool ProjectEngine::updateSampleClipRecordedTakeLengthModelOnly(
    const std::string& clipId,
    const std::string& sampleId,
    double lengthBeats) {
    const juce::ScopedWriteLock lock(mutex_);
    return clipRepo_.updateSampleClipRecordedTakeLength(clipId, sampleId, lengthBeats);
}

bool ProjectEngine::removeRecordingTakeFromSampleClip(const std::string& clipId,
                                                      const std::string& sampleId) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!clipRepo_.removeSampleClipTake(clipId, sampleId)) {
        return false;
    }
    syncProjectTreeLocked();
    return true;
}

bool ProjectEngine::setSampleClipTakeRegionTake(const std::string& clipId,
                                                int regionIndex,
                                                const std::string& takeId) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!clipRepo_.setSampleClipTakeRegionTake(clipId, regionIndex, takeId)) {
        return false;
    }
    rebuildTrackPlaybackLocked();
    syncProjectTreeLocked();
    return true;
}

bool ProjectEngine::setSampleClipTakeAtBeat(const std::string& clipId,
                                            double beat,
                                            const std::string& takeId) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!clipRepo_.setSampleClipTakeAtBeat(clipId, beat, takeId)) {
        return false;
    }
    rebuildTrackPlaybackLocked();
    syncProjectTreeLocked();
    return true;
}

bool ProjectEngine::splitSampleClipTakeRegionAtBeat(const std::string& clipId,
                                                    double beat) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!clipRepo_.splitSampleClipTakeRegionAtBeat(clipId, beat)) {
        return false;
    }
    rebuildTrackPlaybackLocked();
    syncProjectTreeLocked();
    return true;
}

bool ProjectEngine::moveSampleClipTakeMarker(const std::string& clipId,
                                             int markerIndex,
                                             double beat) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!clipRepo_.moveSampleClipTakeMarker(clipId, markerIndex, beat)) {
        return false;
    }
    rebuildTrackPlaybackLocked();
    syncProjectTreeLocked();
    return true;
}

bool ProjectEngine::deleteSampleClipTakeMarker(const std::string& clipId,
                                               int markerIndex) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!clipRepo_.deleteSampleClipTakeMarker(clipId, markerIndex)) {
        return false;
    }
    rebuildTrackPlaybackLocked();
    syncProjectTreeLocked();
    return true;
}

std::string ProjectEngine::exportSampleClipSlices(const std::string& clipId, int firstNote) {
    const juce::ScopedWriteLock lock(mutex_);
    Track* owner = nullptr;
    SampleClip* sourceClip = nullptr;
    for (auto& track : trackRepo_.tracks()) {
        if (auto clip = std::find_if(track.sampleClips.begin(), track.sampleClips.end(),
                [&](const SampleClip& candidate) { return candidate.id == clipId; });
            clip != track.sampleClips.end()) {
            owner = &track;
            sourceClip = &*clip;
            break;
        }
    }
    if (owner == nullptr || sourceClip == nullptr || sampleBank_ == nullptr) return {};
    const auto* sample = sampleBank_->findSample(sourceClip->sampleId);
    if (sample == nullptr || sample->pcm.empty() || sample->sampleRate <= 0.0) return {};

    const int baseNote = std::clamp(firstNote, 0, 127);
    const int maxSlices = 128 - baseNote;
    std::vector<float> bounds{0.0f};
    for (float marker : sourceClip->sliceMarkers) {
        if (static_cast<int>(bounds.size()) >= maxSlices) break;
        bounds.push_back(std::clamp(marker, 0.001f, 0.999f));
    }
    bounds.push_back(1.0f);
    if (bounds.size() < 2) return {};

    const std::string machineId = trackRepo_.allocateDeviceId();
    DeviceSlot machine = deviceRegistry_.createDefault(device_types::kDrumMachine, machineId);
    auto& model = std::get<DrumMachineModel>(machine.config.instance);
    const double durationSec = static_cast<double>(sample->pcm.size()) / sample->sampleRate;
    const double sourceWindow = std::max(0.001, static_cast<double>(sourceClip->sourceEnd - sourceClip->sourceStart));
    for (size_t i = 0; i + 1 < bounds.size() && baseNote + static_cast<int>(i) < 128; ++i) {
        auto& pad = model.pads[static_cast<size_t>(baseNote + static_cast<int>(i))];
        pad.name = sample->name + " " + std::to_string(i + 1);
        const std::string samplerId = trackRepo_.allocateDeviceId();
        auto sampler = std::make_shared<DeviceSlot>(
            deviceRegistry_.createDefault(device_types::kSampler, samplerId));
        auto& samplerModel = std::get<SamplerModel>(sampler->config.instance);
        samplerModel.sampleId = sourceClip->sampleId;
        const double sliceStart = sourceClip->reversed ? 1.0 - bounds[i + 1] : bounds[i];
        const double sliceEnd = sourceClip->reversed ? 1.0 - bounds[i] : bounds[i + 1];
        samplerModel.trimStartSec = static_cast<float>(
            (sourceClip->sourceStart + sliceStart * sourceWindow) * durationSec);
        samplerModel.trimEndSec = static_cast<float>(
            (sourceClip->sourceStart + sliceEnd * sourceWindow) * durationSec);
        samplerModel.rootPitch = static_cast<float>(pad.note);
        samplerModel.playbackMode = sourceClip->reversed ? 2 : 0;
        pad.devices.push_back(std::move(sampler));
    }

    size_t gainIndex = owner->devices.size();
    for (size_t i = 0; i < owner->devices.size(); ++i) {
        if (deviceNodeKindFromTypeId(owner->devices[i].config.typeId) == DeviceNodeKind::TrackGain) {
            gainIndex = i; break;
        }
    }
    owner->devices.insert(owner->devices.begin() + static_cast<std::ptrdiff_t>(gainIndex),
                          std::move(machine));
    syncProjectTreeLocked();
    rebuildTrackPlaybackLocked();
    return machineId;
}

bool ProjectEngine::setBpm(int bpm) {
    const int oldBpm = transport_.bpm();
    if (oldBpm == bpm) return false;

    const juce::ScopedWriteLock lock(mutex_);
    undoManager_.beginNewTransaction();
    undoManager_.perform(std::make_unique<CallbackAction>(
        [this, bpm] {
            projectRoot_.setProperty(state::props::bpm, bpm, nullptr);
            rebuildTrackPlaybackLocked();
        },
        [this, oldBpm] {
            projectRoot_.setProperty(state::props::bpm, oldBpm, nullptr);
            rebuildTrackPlaybackLocked();
        }).release());
    return true;
}

int ProjectEngine::bpm() const noexcept {
    return transport_.bpm();
}

void ProjectEngine::setMetronome(bool enabled, float level, int countInBars) noexcept {
    metronomeEnabled_.store(enabled, std::memory_order_release);
    metronomeLevel_.store(std::clamp(level, 0.0f, 1.0f), std::memory_order_release);
    const int bars = countInBars == 1 || countInBars == 2 || countInBars == 4
        ? countInBars : 0;
    countInBars_.store(bars, std::memory_order_release);
}

bool ProjectEngine::deleteTrack(const std::string& trackId) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!trackRepo_.deleteTrack(trackId)) {
        return false;
    }
    syncActiveFrequencyLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::deleteClip(const std::string& clipId) {
    const juce::ScopedWriteLock lock(mutex_);
    if (clipRepo_.findMidiClip(clipId) != nullptr ||
        clipRepo_.findSampleClip(clipId) != nullptr) {
        if (!clipRepo_.deleteClip(clipId)) {
            return false;
        }
        rebuildTrackPlaybackLocked();
        return true;
    }
    if (!automationClipStore_.remove(clipId)) {
        return false;
    }
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::duplicateClip(const std::string& clipId) {
    const juce::ScopedWriteLock lock(mutex_);
    if (clipRepo_.findMidiClip(clipId) != nullptr ||
        clipRepo_.findSampleClip(clipId) != nullptr) {
        if (!clipRepo_.duplicateClip(clipId)) {
            return false;
        }
        rebuildTrackPlaybackLocked();
        return true;
    }
    if (!automationClipStore_.duplicate(clipId)) {
        return false;
    }
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::setLoopEnabled(bool enabled) {
    const juce::ScopedWriteLock lock(mutex_);
    transport_.setLoopEnabled(enabled);
    return true;
}

bool ProjectEngine::setLoopLengthBeats(double lengthBeats) {
    const juce::ScopedWriteLock lock(mutex_);
    return transport_.setLoopLengthBeats(lengthBeats);
}

bool ProjectEngine::setLoopRegion(double startBeat, double endBeat) {
    const juce::ScopedWriteLock lock(mutex_);
    return transport_.setLoopRegion(startBeat, endBeat);
}

std::vector<float> ProjectEngine::renderOffline(double lengthBeats, double sampleRate) {
    if (lengthBeats <= 0.0 || sampleRate <= 0.0) {
        return {};
    }
    const juce::ScopedReadLock lock(mutex_);
    const int totalFrames =
        static_cast<int>(lengthBeats * sampleRate * 60.0 / static_cast<double>(std::max(transport_.bpm(), 1)));
    if (totalFrames <= 0) {
        return {};
    }
    std::vector<float> output(static_cast<size_t>(totalFrames), 0.0f);
    constexpr int kBlock = 512;
    float block[kBlock];
    for (int offset = 0; offset < totalFrames; offset += kBlock) {
        const int frames = std::min(kBlock, totalFrames - offset);
        const double beat =
            static_cast<double>(offset) / sampleRate * static_cast<double>(transport_.bpm()) / 60.0;
        std::memset(block, 0, static_cast<size_t>(frames) * sizeof(float));
        mixAtPlayheadBeat(block, frames, sampleRate, beat);
        std::memcpy(output.data() + offset, block, static_cast<size_t>(frames) * sizeof(float));
    }
    return output;
}

ProjectSnapshot ProjectEngine::snapshot() const {
    const juce::ScopedReadLock lock(mutex_);
    ProjectSnapshot snap;
    snap.bpm = transport_.bpm();
    snap.selectedTrackId = trackRepo_.selectedTrackId();
    snap.playheadBeats = transport_.playheadBeats();
    snap.playing = transport_.isPlaying();
    snap.loopEnabled = transport_.loopEnabled();
    snap.loopRegionStartBeat = transport_.loopRegionStartBeat();
    snap.loopRegionEndBeat = transport_.loopRegionEndBeat();
    snap.recordArmed = recordArmed_;
    snap.master.id = "master";
    snap.master.name = "Master";
    snap.master.gain = masterGain_.load(std::memory_order_relaxed);
    if (sampleBank_ != nullptr) {
        for (const auto& sample : sampleBank_->listSamples()) {
            SampleLibraryEntryState entry;
            entry.id = sample.id;
            entry.name = sample.name;
            entry.source = sample.source;
            entry.durationBeats = sampleBank_->beatsForSample(sample.id, transport_.bpm());
            entry.waveformPeaks = sample.peaks;
            snap.samples.push_back(std::move(entry));
        }
    }
    snap.tracks.reserve(trackRepo_.tracks().size());
    for (const auto& track : trackRepo_.tracks()) {
        TrackState ts;
        ts.id = track.id;
        ts.name = track.name;
        ts.iconKey = track.iconKey;
        ts.isGroup = track.isGroup;
        ts.muted = track.muted;
        ts.soloed = track.soloed;
        ts.parentGroupId = track.parentGroupId;
        ts.devices.reserve(track.devices.size());
        for (const auto& device : track.devices) {
            ts.devices.push_back(device);
        }
        ts.midiClips.reserve(track.midiClips.size());
        for (const auto& clip : track.midiClips) {
            MidiClipState cs;
            cs.id = clip.id;
            cs.startBeat = clip.startBeat;
            cs.lengthBeats = clip.lengthBeats;
            cs.naturalLengthBeats = clip.naturalLengthBeats;
            cs.loopContent = clip.loopContent;
            cs.editorScaleRoot = clip.editorScaleRoot;
            cs.editorScaleId = clip.editorScaleId;
            cs.editorScaleHighlight = clip.editorScaleHighlight;
            cs.editorScaleSnap = clip.editorScaleSnap;
            cs.editorChordQuality = clip.editorChordQuality;
            cs.notes.reserve(clip.notes.size());
            for (const auto& note : clip.notes) {
                cs.notes.push_back(MidiNoteState{
                    note.pitch,
                    note.startBeat,
                    note.durationBeats,
                    note.velocity,
                });
            }
            for (const auto& take : clip.takes) {
                MidiClipTakeState takeState;
                takeState.id = take.id;
                takeState.name = take.name;
                takeState.startBeatOffset = take.startBeatOffset;
                takeState.lengthBeats = take.lengthBeats;
                for (const auto& note : take.notes) {
                    takeState.notes.push_back(MidiNoteState{
                        note.pitch,
                        note.startBeat,
                        note.durationBeats,
                        note.velocity,
                    });
                }
                cs.takes.push_back(std::move(takeState));
            }
            for (const auto& region : clip.activeTakeRegions) {
                cs.activeTakeRegions.push_back({region.startBeat, region.endBeat,
                                                region.takeId, region.sourceStart,
                                                region.holdPrevious});
            }
            cs.compFlattened = clip.compFlattened;
            ts.midiClips.push_back(std::move(cs));
        }
        ts.sampleClips.reserve(track.sampleClips.size());
        for (const auto& clip : track.sampleClips) {
            SampleClipState cs;
            cs.id = clip.id;
            cs.sampleId = clip.sampleId;
            cs.startBeat = clip.startBeat;
            cs.lengthBeats = clip.lengthBeats;
            cs.naturalLengthBeats = clip.naturalLengthBeats;
            cs.loopContent = clip.loopContent;
            cs.sourceStart = clip.sourceStart; cs.sourceEnd = clip.sourceEnd;
            cs.gain = clip.gain; cs.fadeIn = clip.fadeIn; cs.fadeOut = clip.fadeOut;
            cs.fadeInCurve = clip.fadeInCurve; cs.fadeOutCurve = clip.fadeOutCurve;
            cs.reversed = clip.reversed;
            cs.warpRepitch = clip.warpRepitch;
            cs.sliceMarkers = clip.sliceMarkers;
            for (const auto& take : clip.takes) {
                cs.takes.push_back({take.id, take.sampleId, take.name,
                                    take.startBeatOffset, take.lengthBeats});
            }
            for (const auto& region : clip.activeTakeRegions) {
                cs.activeTakeRegions.push_back({region.startBeat, region.endBeat,
                                                region.takeId, region.sourceStart});
            }
            if (sampleBank_ != nullptr) {
                if (const auto* sample = sampleBank_->findSample(clip.sampleId)) {
                    cs.sampleName = sample->name;
                    cs.waveformPeaks = sample->peaks;
                }
            }
            ts.sampleClips.push_back(std::move(cs));
        }
        ts.freeze.enabled = track.freeze.enabled;
        ts.freeze.stale = track.freeze.stale;
        ts.freeze.assetId = track.freeze.assetId;
        ts.freeze.startBeat = track.freeze.startBeat;
        ts.freeze.lengthBeats = track.freeze.lengthBeats;
        ts.freeze.sampleRate = track.freeze.sampleRate;
        ts.freeze.bpmAtFreeze = track.freeze.bpmAtFreeze;
        ts.freeze.contentSignature = track.freeze.contentSignature;
        ts.freeze.waveformPeaks = track.freeze.waveformPeaks;
        snap.tracks.push_back(std::move(ts));
    }

    snap.automationClips.reserve(automationClipStore_.clips().size());
    for (const auto& clip : automationClipStore_.clips()) {
        AutomationClipState cs;
        cs.id = clip.id;
        cs.homeTrackId = clip.homeTrackId;
        cs.startBeat = clip.startBeat;
        cs.lengthBeats = clip.lengthBeats;
        cs.naturalLengthBeats = clip.naturalLengthBeats;
        cs.loopContent = clip.loopContent;
        cs.deviceId = clip.deviceId;
        cs.paramId = clip.paramId;
        cs.points.reserve(clip.points.size());
        for (const auto& point : clip.points) {
            cs.points.push_back(AutomationPointState{point.beat, point.value});
        }
        snap.automationClips.push_back(std::move(cs));
    }

    snap.lfos = modulationGraph_.lfos();
    snap.modEdges = modulationGraph_.modEdges();

    applyLiveDeviceMetersLocked(snap);

    return snap;
}

float ProjectEngine::activeOscillatorFrequencyHz() const {
    if (!transport_.isPlaying()) {
        return activeFrequencyHz_.load(std::memory_order_acquire);
    }

    const int selectedIndex = selectedTrackPlaybackIndex();
    if (selectedIndex < 0) {
        return activeFrequencyHz_.load(std::memory_order_acquire);
    }

    const auto& track = trackPlayback_[selectedIndex];
    const DeviceNodePlayback* oscillator = findOscillatorNode(track);
    if (oscillator == nullptr) {
        return 0.0f;
    }

    const double playhead = transport_.playheadBeats();
    if (trackHasActiveSampleAtPlayhead(track, playhead)) {
        return 0.0f;
    }

    MidiPlaybackNote midiNotes[32];
    const int noteCount = track.noteCount > 32 ? 32 : track.noteCount;
    for (int i = 0; i < noteCount; ++i) {
        const PlaybackNote& note = track.notes[i];
        midiNotes[i] = MidiPlaybackNote{
            note.pitch,
            note.clipStartBeat,
            note.clipLengthBeats,
            note.noteStartBeat,
            note.noteDurationBeats,
            note.velocity,
            note.loopContent,
            note.contentLengthBeats,
        };
    }
    return midiActiveFrequencyHz(midiNotes, noteCount, playhead,
                                 std::get<OscillatorParams>(oscillator->params).frequencyHz);
}

void ProjectEngine::readMasterMix(float* monoOut,
                                  int numFrames,
                                  double sampleRate,
                                  double playheadStartBeat) noexcept {
    if (monoOut == nullptr || numFrames <= 0) {
        return;
    }
    constexpr int kMaxFrames = kMaxProcessorGraphBlockFrames;
    const int framesToProcess = numFrames > kMaxFrames ? kMaxFrames : numFrames;
    thread_local float left[kMaxFrames];
    thread_local float right[kMaxFrames];
    std::memset(left, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
    std::memset(right, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
    readMasterMixStereo(left, right, framesToProcess, sampleRate, playheadStartBeat);
    for (int frame = 0; frame < framesToProcess; ++frame) {
        monoOut[frame] = (left[frame] + right[frame]) * 0.5f;
    }
    if (framesToProcess < numFrames) {
        std::memset(monoOut + framesToProcess, 0,
                    static_cast<size_t>(numFrames - framesToProcess) * sizeof(float));
    }
}

void ProjectEngine::readMasterMixStereo(float* leftOut,
                                        float* rightOut,
                                        int numFrames,
                                        double sampleRate,
                                        double playheadStartBeat) noexcept {
    if (leftOut == nullptr || rightOut == nullptr || numFrames <= 0) {
        return;
    }
    std::memset(leftOut, 0, static_cast<size_t>(numFrames) * sizeof(float));
    std::memset(rightOut, 0, static_cast<size_t>(numFrames) * sizeof(float));
    if (!transport_.isPlaying()) {
        return;
    }
    const double remaining = countInRemainingBeats_.load(std::memory_order_acquire);
    if (remaining > 0.0) {
        const int bpm = transport_.bpm();
        const double beatsPerFrame = (static_cast<double>(bpm) / 60.0) / sampleRate;
        const int preRollFrames = std::min(numFrames,
            static_cast<int>(std::ceil(remaining / beatsPerFrame)));
        const double totalBeats = static_cast<double>(countInBars_.load(std::memory_order_acquire) * 4);
        addMetronomeClick(leftOut, rightOut, preRollFrames, sampleRate,
                          totalBeats - remaining, bpm,
                          metronomeLevel_.load(std::memory_order_acquire));
        if (preRollFrames < numFrames) {
            mixAtPlayheadBeatStereo(leftOut + preRollFrames, rightOut + preRollFrames,
                numFrames - preRollFrames, sampleRate, playheadStartBeat);
        }
        return;
    }
    // The playback-state publication supplies release/acquire ordering.
    // provides happens-before for all trackPlayback_[] writes by the
    // control thread in rebuildTrackPlaybackLocked. TransportController
    // and ModulationGraph use their own atomics/double-buffering.
    mixAtPlayheadBeatStereo(leftOut, rightOut, numFrames, sampleRate, playheadStartBeat);
    if (trackPlayback_.count() <= 0 &&
        metronomeEnabled_.load(std::memory_order_acquire)) {
        addMetronomeClick(leftOut, rightOut, numFrames, sampleRate, playheadStartBeat,
                          transport_.bpm(), metronomeLevel_.load(std::memory_order_acquire));
    }
}

bool ProjectEngine::enqueueRealtimeCommand(RealtimeCommand command) noexcept {
    auto tryEnqueue = [&]() noexcept {
        const uint32_t head = realtimeCommands_.head.load(std::memory_order_relaxed);
        const uint32_t tail = realtimeCommands_.tail.load(std::memory_order_acquire);
        if (head - tail >= kRealtimeCommandCapacity) return false;
        try {
            realtimeCommands_.entries[head % kRealtimeCommandCapacity] = std::move(command);
        } catch (...) {
            return false;
        }
        realtimeCommands_.head.store(head + 1, std::memory_order_release);
        return true;
    };

    if (tryEnqueue()) return true;

    // With no running transport there may be no callback to consume commands.
    // Applying them here is safe because the playback lock excludes callbacks;
    // this path cannot affect live audio.
    if (!transport_.isPlaying()) {
        const std::lock_guard<std::recursive_mutex> playbackLock(playbackMutex_);
        drainRealtimeCommands();
        if (tryEnqueue()) return true;
    }

    realtimeCommandOverflowCount_.fetch_add(1, std::memory_order_relaxed);
    return false;
}

bool ProjectEngine::enqueueRealtimeParameter(RealtimeParameterCommand command) noexcept {
    auto tryEnqueue = [&]() noexcept {
        const uint32_t head = realtimeParameterMailbox_.head.load(std::memory_order_relaxed);
        const uint32_t tail = realtimeParameterMailbox_.tail.load(std::memory_order_acquire);
        if (head - tail >= kRealtimeCommandCapacity) return false;
        realtimeParameterMailbox_.entries[head % kRealtimeCommandCapacity] = command;
        realtimeParameterMailbox_.head.store(head + 1, std::memory_order_release);
        return true;
    };
    if (tryEnqueue()) return true;
    if (!transport_.isPlaying()) {
        const std::lock_guard<std::recursive_mutex> playbackLock(playbackMutex_);
        drainRealtimeParameters();
        if (tryEnqueue()) return true;
    }
    realtimeCommandOverflowCount_.fetch_add(1, std::memory_order_relaxed);
    return false;
}

bool ProjectEngine::applyRealtimeDeviceNode(const DeviceNodePlayback& node,
                                            bool commonOnly) noexcept {
    const int trackCount = trackPlayback_.count();
    for (int t = 0; t < trackCount; ++t) {
        auto& snap = trackPlayback_[t];
        for (int d = 0; d < snap.deviceCount; ++d) {
            auto* processor = snap.arena.get(d);
            if (snap.devices[d].deviceId == node.deviceId) {
                if (processor == nullptr) return false;
                processor->bypassed = node.bypassed;
                processor->gain = node.gain;
                processor->pan = node.pan;
                processor->outputMix = node.outputMix;
                processor->outputWidth = node.outputWidth;
                if (!commonOnly) processor->applyPlaybackNode(node);
                return true;
            }
            if (processor != nullptr &&
                processor->updateNestedDevice(node, !commonOnly)) {
                return true;
            }
        }
    }
    return false;
}

bool ProjectEngine::applyRealtimeDeviceParameter(uint64_t targetNodeId,
                                                 uint16_t encodedParameterId,
                                                 float value) noexcept {
    const int trackCount = trackPlayback_.count();
    for (int track = 0; track < trackCount; ++track) {
        auto& snapshot = trackPlayback_[track];
        for (int device = 0; device < snapshot.deviceCount; ++device) {
            auto* processor = snapshot.arena.get(device);
            if (processor == nullptr) continue;
            if (processor->stableProcessorNodeId == targetNodeId)
                return processor->setCompiledParameter(encodedParameterId, value);
            if (processor->setNestedCompiledParameter(
                    targetNodeId, encodedParameterId, value))
                return true;
        }
    }
    return false;
}

void ProjectEngine::drainRealtimeParameters() noexcept {
    uint32_t tail = realtimeParameterMailbox_.tail.load(std::memory_order_relaxed);
    const uint32_t head = realtimeParameterMailbox_.head.load(std::memory_order_acquire);
    if (tail == head) return;

    constexpr int kMaxDistinctParametersPerBlock = 128;
    const RealtimeParameterCommand* latest[kMaxDistinctParametersPerBlock]{};
    int latestCount = 0;
    uint32_t consumedEnd = tail;
    for (uint32_t cursor = tail; cursor != head; ++cursor) {
        const auto& candidate = realtimeParameterMailbox_.entries[
            cursor % kRealtimeCommandCapacity];
        int existing = -1;
        for (int index = 0; index < latestCount; ++index) {
            if (latest[index]->targetNodeId == candidate.targetNodeId &&
                latest[index]->encodedParameterId == candidate.encodedParameterId) {
                existing = index;
                break;
            }
        }
        if (existing >= 0) latest[existing] = &candidate;
        else if (latestCount < kMaxDistinctParametersPerBlock)
            latest[latestCount++] = &candidate;
        else break;
        consumedEnd = cursor + 1;
    }
    for (int index = 0; index < latestCount; ++index) {
        const auto& command = *latest[index];
        applyRealtimeDeviceParameter(command.targetNodeId,
                                     command.encodedParameterId,
                                     command.value);
    }
    realtimeParameterMailbox_.tail.store(consumedEnd, std::memory_order_release);
}

void ProjectEngine::drainRealtimeCommands() noexcept {
    uint32_t tail = realtimeCommands_.tail.load(std::memory_order_relaxed);
    const uint32_t head = realtimeCommands_.head.load(std::memory_order_acquire);
    if (tail == head) return;

    // A touch gesture can publish several values before the next callback.
    // Keep only the newest value for each target so one audio block never does
    // hundreds of obsolete processor updates.
    constexpr int kMaxDistinctTargetsPerBlock = 64;
    const RealtimeCommand* latest[kMaxDistinctTargetsPerBlock]{};
    int latestCount = 0;
    uint32_t consumedEnd = tail;
    for (uint32_t cursor = tail; cursor != head; ++cursor) {
        const auto& candidate =
            realtimeCommands_.entries[cursor % kRealtimeCommandCapacity];
        int existing = -1;
        for (int i = 0; i < latestCount; ++i) {
            const bool samePad = candidate.type != RealtimeCommandType::DrumPad ||
                                 candidate.note == latest[i]->note;
            const bool sameDeviceClass =
                candidate.type != RealtimeCommandType::DeviceNode ||
                candidate.commonOnly == latest[i]->commonOnly;
            if (latest[i]->type == candidate.type && samePad && sameDeviceClass &&
                latest[i]->targetId == candidate.targetId) {
                existing = i;
                break;
            }
        }
        if (existing >= 0) {
            latest[existing] = &candidate;
        } else if (latestCount < kMaxDistinctTargetsPerBlock) {
            latest[latestCount++] = &candidate;
        } else {
            break;
        }
        consumedEnd = cursor + 1;
    }

    for (int commandIndex = 0; commandIndex < latestCount; ++commandIndex) {
        const auto& command = *latest[commandIndex];
        switch (command.type) {
            case RealtimeCommandType::DeviceNode:
                applyRealtimeDeviceNode(command.node, command.commonOnly);
                break;
            case RealtimeCommandType::TrackMute:
            case RealtimeCommandType::TrackSolo: {
                const int count = trackPlayback_.count();
                for (int i = 0; i < count; ++i) {
                    if (trackPlayback_[i].trackId != command.targetId) continue;
                    if (command.type == RealtimeCommandType::TrackMute)
                        trackPlayback_[i].muted = command.value >= 0.5f;
                    else
                        trackPlayback_[i].soloed = command.value >= 0.5f;
                    break;
                }
                break;
            }
            case RealtimeCommandType::DrumPad: {
                const int count = trackPlayback_.count();
                for (int t = 0; t < count; ++t) {
                    auto& snap = trackPlayback_[t];
                    for (int d = 0; d < snap.deviceCount; ++d) {
                        if (snap.devices[d].deviceId != command.targetId) continue;
                        if (auto* processor = snap.arena.get(d)) {
                            processor->updateDrumPadParameter(
                                command.note, command.parameterId, command.value);
                        }
                        break;
                    }
                }
                break;
            }
        }
    }
    realtimeCommands_.tail.store(consumedEnd, std::memory_order_release);
}

void ProjectEngine::mixAtPlayheadBeatStereo(float* masterLeft,
                                            float* masterRight,
                                            int numFrames,
                                            double sampleRate,
                                            double playheadStartBeat) noexcept {
    if (masterLeft == nullptr || masterRight == nullptr || numFrames <= 0) {
        return;
    }
    // Structural publishers are rare. Avoid touching the platform recursive
    // mutex on every callback when there is no snapshot waiting to commit.
    if (trackPlayback_.pending.load(std::memory_order_acquire) >= 0) {
        const std::unique_lock<std::recursive_mutex> publishLock(
            playbackMutex_, std::try_to_lock);
        if (publishLock.owns_lock()) {
            const int committed = trackPlayback_.commitPending();
            if (committed >= 0) {
                activeProcessorGraph_.store(
                    trackPlayback_.graphIndexForState(committed),
                    std::memory_order_release);
            }
        }
    }
    PlaybackStateStorage::ReadGuard playbackRead(trackPlayback_);
    drainRealtimeCommands();
    // Full-node fallbacks may contain an older copy of common strip values.
    // Apply compact mailboxes last so the newest live gesture wins.
    drainRealtimeParameters();
    const int trackCount = trackPlayback_.count();
    if (trackCount <= 0) {
        return;
    }

    if (transport_.isPlaying()) {
        const double prevPlayhead = lastArrangementMixPlayhead_;
        if (prevPlayhead >= 0.0 && playheadStartBeat + 1e-4 < prevPlayhead) {
            for (int trackIndex = 0; trackIndex < trackCount; ++trackIndex) {
                resetPlaybackStateInArena(trackPlayback_[trackIndex].arena);
            }
            modulationGraph_.retriggerOnNote();
        }
        lastArrangementMixPlayhead_ = playheadStartBeat;
    } else {
        lastArrangementMixPlayhead_ = -1.0;
    }

    const float masterGain = masterGain_.load(std::memory_order_acquire);
    constexpr int kMaxFrames = 4096;
    thread_local float trackLeft[kMaxTracks][kMaxFrames];
    thread_local float trackRight[kMaxTracks][kMaxFrames];
    constexpr int kMaxRoutedMidiNotes = 256;
    thread_local MidiPlaybackNote routedMidi[kMaxTracks][kMaxRoutedMidiNotes];
    thread_local MidiPlaybackNote graphMidiEdges[kMaxProcessorGraphEdges][kMaxRoutedMidiNotes];
    int graphMidiEdgeCounts[kMaxProcessorGraphEdges]{};
    thread_local float graphAudioLeft[kMaxProcessorGraphEdges][kMaxFrames];
    thread_local float graphAudioRight[kMaxProcessorGraphEdges][kMaxFrames];
    int routedMidiCount[kMaxTracks]{};
    const int framesToProcess = numFrames > kMaxFrames ? kMaxFrames : numFrames;
    const double beatsPerFrame =
        (static_cast<double>(std::max(transport_.bpm(), 1)) / 60.0) / sampleRate;
    const double blockEndBeat =
        playheadStartBeat + static_cast<double>(framesToProcess) * beatsPerFrame;
    const int graphIndex = activeProcessorGraph_.load(std::memory_order_acquire);
    const ProcessorGraphSnapshot graph = processorGraphs_[graphIndex];
    const bool useGraph = graph.trackCount == trackCount;
    for (int slot = 0; slot < graph.audioBufferSlotCount; ++slot) {
        std::memset(graphAudioLeft[slot], 0,
                    static_cast<size_t>(framesToProcess) * sizeof(float));
        std::memset(graphAudioRight[slot], 0,
                    static_cast<size_t>(framesToProcess) * sizeof(float));
    }
    auto& graphFeedback = graphFeedbackBanks_[graphIndex];
    const int graphFeedbackReadIndex = graphFeedback.readIndex;
    const int graphFeedbackWriteIndex = 1 - graphFeedbackReadIndex;
    for (int slot = 0; slot < graph.feedbackBufferSlotCount; ++slot) {
        std::memset(graphFeedback.left[graphFeedbackWriteIndex][slot].data(), 0,
                    static_cast<size_t>(framesToProcess) * sizeof(float));
        std::memset(graphFeedback.right[graphFeedbackWriteIndex][slot].data(), 0,
                    static_cast<size_t>(framesToProcess) * sizeof(float));
    }

    bool anySolo = false;
    for (int i = 0; i < trackCount; ++i) {
        if (trackPlayback_[i].soloed) {
            anySolo = true;
            break;
        }
    }

    auto trackAudibleForOutput = [&](int trackIndex) -> bool {
        const TrackPlaybackSnapshot& track = trackPlayback_[trackIndex];
        if (track.muted) {
            return false;
        }
        if (!anySolo) {
            return true;
        }
        if (track.soloed) {
            return true;
        }
        for (int childIndex = 0; childIndex < trackCount; ++childIndex) {
            const TrackPlaybackSnapshot& child = trackPlayback_[childIndex];
            if (!child.soloed || child.muted) {
                continue;
            }
            int parent = child.parentGroupTrackIndex;
            while (parent >= 0) {
                if (parent == trackIndex) {
                    return true;
                }
                parent = trackPlayback_[parent].parentGroupTrackIndex;
            }
        }
        return false;
    };

        // Compute per-frame LFO values for gain/pan modulation.
    // DSP-specific params still use frame-0 (block-rate).
    const int lfoCount = modulationGraph_.lfoPlaybackCount();
    const uint32_t retriggerGeneration = modulationGraph_.noteRetriggerGeneration();
    thread_local std::vector<IModulator*> modulatorPtrs;
    bool anyPerNoteModulator = false;
    if (lfoCount > 0) {
        modulatorPtrs.resize(static_cast<size_t>(lfoCount));
        for (int i = 0; i < lfoCount; ++i) {
            modulatorPtrs[static_cast<size_t>(i)] = modulationGraph_.modulator(i);
            if (!anyPerNoteModulator && modulatorPtrs[static_cast<size_t>(i)] != nullptr &&
                modulatorPtrs[static_cast<size_t>(i)]->usesPerNoteClock()) {
                anyPerNoteModulator = true;
            }
        }
    }
    thread_local std::vector<float> lfoValues;
    if (lfoCount > 0) {
        const size_t needed = static_cast<size_t>(lfoCount) * static_cast<size_t>(framesToProcess);
        if (lfoValues.capacity() < needed) {
            lfoValues.reserve(needed + 4096);
        }
        lfoValues.resize(needed, 0.0f);
        const double playheadSeconds = playheadStartBeat * 60.0 / static_cast<double>(std::max(transport_.bpm(), 1));
        const double samplePeriod = 1.0 / std::max(sampleRate, 1.0);
        thread_local std::vector<float> noteElapsedPerFrame;
        if (anyPerNoteModulator) {
            const double invBpmSeconds = 60.0 / static_cast<double>(std::max(transport_.bpm(), 1));
            const auto noteElapsedSecondsAtBeat = [&](double beat) -> double {
                double latestOnsetBeat = -1.0;
                for (int trackIndex = 0; trackIndex < trackCount; ++trackIndex) {
                    const TrackPlaybackSnapshot& track = trackPlayback_[trackIndex];
                    for (int noteIndex = 0; noteIndex < track.noteCount; ++noteIndex) {
                        const PlaybackNote& note = track.notes[noteIndex];
                        const double onset = midiActiveNoteOnsetBeat(
                            beat,
                            note.clipStartBeat,
                            note.clipLengthBeats,
                            note.contentLengthBeats,
                            note.loopContent,
                            note.noteStartBeat,
                            note.noteDurationBeats);
                        if (onset > latestOnsetBeat) {
                            latestOnsetBeat = onset;
                        }
                    }
                }
                if (latestOnsetBeat < 0.0) {
                    return -1.0;
                }
                return (beat - latestOnsetBeat) * invBpmSeconds;
            };
            noteElapsedPerFrame.resize(static_cast<size_t>(framesToProcess));
            for (int frame = 0; frame < framesToProcess; ++frame) {
                const double frameBeat = playheadStartBeat
                    + static_cast<double>(frame) * beatsPerFrame;
                noteElapsedPerFrame[static_cast<size_t>(frame)] =
                    static_cast<float>(noteElapsedSecondsAtBeat(frameBeat));
            }
        }
        for (int i = 0; i < lfoCount; ++i) {
            auto* mod = modulationGraph_.modulator(i);
            if (mod == nullptr) continue;
            const bool perNote = mod->usesPerNoteClock();
            if (!perNote) {
                const float value = mod->evaluate(
                    playheadStartBeat,
                    transport_.bpm(),
                    0.0,
                    playheadSeconds,
                    retriggerGeneration,
                    -1.0);
                for (int frame = 0; frame < framesToProcess; ++frame) {
                    lfoValues[static_cast<size_t>(i * framesToProcess + frame)] = value;
                }
                continue;
            }
            for (int frame = 0; frame < framesToProcess; ++frame) {
                const double secondsWithinBlock = static_cast<double>(frame) * samplePeriod;
                const double frameBeat =
                    playheadStartBeat +
                    secondsWithinBlock *
                        (static_cast<double>(std::max(transport_.bpm(), 1)) / 60.0);
                const double noteElapsed = anyPerNoteModulator
                    ? static_cast<double>(noteElapsedPerFrame[static_cast<size_t>(frame)])
                    : -1.0;
                lfoValues[static_cast<size_t>(i * framesToProcess + frame)] =
                    mod->evaluate(frameBeat, transport_.bpm(),
                                  secondsWithinBlock, playheadSeconds, retriggerGeneration,
                                  noteElapsed);
            }
        }
    }

    SampleClipPlaybackRegion regions[8];

    // Prepare each track's own clip and MIDI input before graph execution.
    for (int trackIndex = 0; trackIndex < trackCount; ++trackIndex) {
        const TrackPlaybackSnapshot& track = trackPlayback_[trackIndex];
        std::memset(trackLeft[trackIndex], 0,
                    static_cast<size_t>(framesToProcess) * sizeof(float));
        std::memset(trackRight[trackIndex], 0,
                    static_cast<size_t>(framesToProcess) * sizeof(float));
        if (track.freeze.active) {
            continue;
        }
        if (track.regionCount > 0) {
            for (int i = 0; i < track.regionCount; ++i) {
                const SampleRegion& source = track.regions[i];
                regions[i] = SampleClipPlaybackRegion{
                    source.clipStartBeat,
                    source.clipLengthBeats,
                    source.pcm,
                    source.frameCount,
                    source.pcmSampleRate,
                    source.loopContent,
                    source.contentLengthBeats,
                    source.sourceStart, source.sourceEnd, source.gain,
                    source.fadeIn, source.fadeOut, source.fadeInCurve,
                    source.fadeOutCurve, source.reversed,
                };
            }
            mixSampleRegionsBlock(trackLeft[trackIndex], framesToProcess, sampleRate,
                                  transport_.bpm(), playheadStartBeat, regions,
                                  track.regionCount);
            std::copy(trackLeft[trackIndex], trackLeft[trackIndex] + framesToProcess,
                      trackRight[trackIndex]);
        }
        const int ownNoteCount = std::min(track.noteCount, kMaxRoutedMidiNotes);
        constexpr double kRouteReleaseBeats = 4.0;
        int routedCount = 0;
        for (int i = 0; i < ownNoteCount; ++i) {
            const PlaybackNote& note = track.notes[i];
            if (!blockMayContainLoopedClipNotes(
                    playheadStartBeat,
                    blockEndBeat,
                    note.clipStartBeat,
                    note.clipLengthBeats,
                    note.contentLengthBeats,
                    note.loopContent,
                    note.noteStartBeat,
                    note.noteDurationBeats,
                    kRouteReleaseBeats)) {
                continue;
            }
            routedMidi[trackIndex][routedCount] = MidiPlaybackNote{
                note.pitch,
                note.clipStartBeat,
                note.clipLengthBeats,
                note.noteStartBeat,
                note.noteDurationBeats,
                note.velocity,
                note.loopContent,
                note.contentLengthBeats,
            };
            ++routedCount;
        }
        routedMidiCount[trackIndex] = routedCount;
    }

    for (int orderIndex = 0; orderIndex < trackCount; ++orderIndex) {
        const int trackIndex = useGraph
            ? static_cast<int>(graph.executionOrder[static_cast<size_t>(orderIndex)])
            : orderIndex;
        const TrackPlaybackSnapshot& track = trackPlayback_[trackIndex];

        if (track.freeze.active) {
            FreezePlaybackRegion region{
                track.freeze.startBeat,
                track.freeze.lengthBeats,
                track.freeze.pcmL,
                track.freeze.pcmR,
                track.freeze.frameCount,
                track.freeze.pcmSampleRate,
            };
            mixFreezeStereoBlock(trackLeft[trackIndex],
                                 trackRight[trackIndex],
                                 framesToProcess,
                                 sampleRate,
                                 transport_.bpm(),
                                 playheadStartBeat,
                                 region);
            if (track.trackGainDeviceIndex >= 0) {
                DeviceChainOrchestrator::Context ctx(trackPlayback_[trackIndex].arena,
                                                       gProjectScratch);
                ctx.trackLeft = trackLeft[trackIndex];
                ctx.trackRight = trackRight[trackIndex];
                ctx.numFrames = framesToProcess;
                ctx.sampleRate = sampleRate;
                ctx.bpm = transport_.bpm();
                ctx.playheadStartBeat = playheadStartBeat;
                ctx.notes = nullptr;
                ctx.noteCount = 0;
                ctx.deviceMeters = deviceMeters_;
                ctx.maxDeviceMeters = kMaxDeviceMeters;
                ctx.meterSlotSubscribed = meterSlotSubscribed_.data();
                ctx.tapGraph = useGraph ? &graph : nullptr;
                ctx.graphTapRuntimes = graphTapRuntimes_.get();
                ctx.graphTapRuntimeCount = kMaxProcessorGraphTaps;
                ctx.lfoValues = lfoCount > 0 ? lfoValues.data() : nullptr;
                ctx.lfoCount = lfoCount;
                ctx.modulators = lfoCount > 0 ? modulatorPtrs.data() : nullptr;
                ctx.retriggerGeneration = retriggerGeneration;
                ctx.modEdges = track.modEdgeCount > 0 ? track.modEdges : nullptr;
                ctx.modEdgeCount = track.modEdgeCount;
                ctx.automationClips = track.automationClipCount > 0 ? track.automationClips : nullptr;
                ctx.automationClipCount = track.automationClipCount;
                ctx.wavetableBank = wavetableBank_;
                DeviceChainOrchestrator::processChain(
                    ctx, track.trackGainDeviceIndex, track.trackGainDeviceIndex + 1);
            }
        } else {
        const bool suppressInstruments = trackHasActiveSampleAtPlayhead(track, playheadStartBeat);
        const int noteCount = routedMidiCount[trackIndex];

        if (noteCount == 0 && track.regionCount == 0) {
            bool onlyPassthroughGain = track.deviceCount > 0;
            for (int deviceIndex = 0; deviceIndex < track.deviceCount; ++deviceIndex) {
                if (track.devices[deviceIndex].kind != DeviceNodeKind::TrackGain) {
                    onlyPassthroughGain = false;
                    break;
                }
            }
            if (onlyPassthroughGain) {
                continue;
            }
        }

        DeviceChainOrchestrator::Context ctx(trackPlayback_[trackIndex].arena, gProjectScratch);
        ctx.trackLeft = trackLeft[trackIndex];
        ctx.trackRight = trackRight[trackIndex];
        ctx.numFrames = framesToProcess;
        ctx.sampleRate = sampleRate;
        ctx.bpm = transport_.bpm();
        ctx.playheadStartBeat = playheadStartBeat;
        ctx.notes = routedMidi[trackIndex];
        ctx.noteCount = noteCount;
        ctx.suppressInstruments = suppressInstruments;
        ctx.deviceMeters = deviceMeters_;
        ctx.maxDeviceMeters = kMaxDeviceMeters;
        ctx.meterSlotSubscribed = meterSlotSubscribed_.data();
        ctx.tapGraph = useGraph ? &graph : nullptr;
        ctx.graphTapRuntimes = graphTapRuntimes_.get();
        ctx.graphTapRuntimeCount = kMaxProcessorGraphTaps;
        ctx.lfoValues = lfoCount > 0 ? lfoValues.data() : nullptr;
        ctx.lfoCount = lfoCount;
        ctx.modulators = lfoCount > 0 ? modulatorPtrs.data() : nullptr;
        ctx.retriggerGeneration = retriggerGeneration;
        ctx.modEdges = track.modEdgeCount > 0 ? track.modEdges : nullptr;
        ctx.modEdgeCount = track.modEdgeCount;
        ctx.automationClips = track.automationClipCount > 0 ? track.automationClips : nullptr;
        ctx.automationClipCount = track.automationClipCount;
        ctx.wavetableBank = wavetableBank_;
        ctx.graph = useGraph ? &graph : nullptr;
        ctx.graphTrackIndex = trackIndex;
        ctx.graphAudioLeft = &graphAudioLeft[0][0];
        ctx.graphAudioRight = &graphAudioRight[0][0];
        ctx.graphAudioStride = kMaxFrames;
        ctx.graphLatencyLines = graphLatencyLines_[graphIndex].data();
        ctx.graphFeedbackReadLeft = graphFeedback.left[graphFeedbackReadIndex][0].data();
        ctx.graphFeedbackReadRight = graphFeedback.right[graphFeedbackReadIndex][0].data();
        ctx.graphFeedbackWriteLeft = graphFeedback.left[graphFeedbackWriteIndex][0].data();
        ctx.graphFeedbackWriteRight = graphFeedback.right[graphFeedbackWriteIndex][0].data();
        ctx.graphFeedbackStride = kMaxFrames;
        ctx.graphMidiNotes = &routedMidi[0][0];
        ctx.graphMidiCounts = routedMidiCount;
        ctx.graphMidiStride = kMaxRoutedMidiNotes;
        ctx.graphMidiEdgeNotes = &graphMidiEdges[0][0];
        ctx.graphMidiEdgeCounts = graphMidiEdgeCounts;
        ctx.graphMidiEdgeStride = kMaxRoutedMidiNotes;
        if (track.deviceExecutionOrder.valid()) {
            ctx.compiledDeviceOrder = track.deviceExecutionOrder.deviceIndices.data();
            ctx.compiledDeviceOrderCount = track.deviceExecutionOrder.count;
        }

        DeviceChainOrchestrator::processChain(ctx);

        } // !track.freeze.active

        const float audibleTarget = trackAudibleForOutput(trackIndex) ? 1.0f : 0.0f;
        auto& mutableTrack = trackPlayback_[trackIndex];
        const float audibleStep = (audibleTarget - mutableTrack.audibilityGain) /
                                  static_cast<float>(std::max(1, framesToProcess));
        for (int frame = 0; frame < framesToProcess; ++frame) {
            const float audibleGain = mutableTrack.audibilityGain +
                                      audibleStep * static_cast<float>(frame + 1);
            trackLeft[trackIndex][frame] *= audibleGain;
            trackRight[trackIndex][frame] *= audibleGain;
        }
        mutableTrack.audibilityGain = audibleTarget;

        const int parentGroup = track.parentGroupTrackIndex;
        for (int frame = 0; frame < framesToProcess; ++frame) {
            if (parentGroup >= 0 && parentGroup < trackCount) {
                trackLeft[parentGroup][frame] += trackLeft[trackIndex][frame];
                trackRight[parentGroup][frame] += trackRight[trackIndex][frame];
            } else {
                masterLeft[frame] += trackLeft[trackIndex][frame];
                masterRight[frame] += trackRight[trackIndex][frame];
            }
        }
    }

    graphFeedback.readIndex = graphFeedbackWriteIndex;

    if (metronomeEnabled_.load(std::memory_order_acquire)) {
        addMetronomeClick(masterLeft, masterRight, framesToProcess, sampleRate,
                          playheadStartBeat, transport_.bpm(),
                          metronomeLevel_.load(std::memory_order_acquire));
    }

    // Simple peak limiter + emergency hard clamp for the master bus.
    float peak = 0.0f;
    for (int frame = 0; frame < framesToProcess; ++frame) {
        peak = std::max(peak, std::max(std::abs(masterLeft[frame] * masterGain),
                                        std::abs(masterRight[frame] * masterGain)));
    }

    const float limitThreshold = 0.95f;
    const float limitGain = peak > limitThreshold ? limitThreshold / peak : 1.0f;

    for (int frame = 0; frame < framesToProcess; ++frame) {
        float l = masterLeft[frame] * masterGain * limitGain;
        float r = masterRight[frame] * masterGain * limitGain;
        masterLeft[frame] = std::isfinite(l) ? std::clamp(l, -1.0f, 1.0f) : 0.0f;
        masterRight[frame] = std::isfinite(r) ? std::clamp(r, -1.0f, 1.0f) : 0.0f;
    }
}

void ProjectEngine::mixAtPlayheadBeat(float* monoOut,
                                      int numFrames,
                                      double sampleRate,
                                      double playheadStartBeat) noexcept {
    if (monoOut == nullptr || numFrames <= 0) {
        return;
    }
    constexpr int kMaxFrames = 4096;
    const int framesToProcess = numFrames > kMaxFrames ? kMaxFrames : numFrames;
    thread_local float left[kMaxFrames];
    thread_local float right[kMaxFrames];
    std::memset(left, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
    std::memset(right, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
    mixAtPlayheadBeatStereo(left, right, framesToProcess, sampleRate, playheadStartBeat);
    for (int frame = 0; frame < framesToProcess; ++frame) {
        monoOut[frame] = (left[frame] + right[frame]) * 0.5f;
    }
}

void ProjectEngine::setPlaying(bool playing) {
    if (playing) {
        const juce::ScopedWriteLock lock(mutex_);
        rebuildTrackPlaybackLocked();
    }
    if (playing && recordArmed_) {
        countInRemainingBeats_.store(
            static_cast<double>(countInBars_.load(std::memory_order_acquire) * 4),
            std::memory_order_release);
    } else if (!playing) {
        countInRemainingBeats_.store(0.0, std::memory_order_release);
    }
    transport_.setPlaying(playing);
}

bool ProjectEngine::isPlaying() const noexcept {
    return transport_.isPlaying();
}

double ProjectEngine::playheadBeats() const noexcept {
    return transport_.playheadBeats();
}

void ProjectEngine::setPlayheadBeats(double beats) noexcept {
    transport_.setPlayheadBeats(beats);
}

void ProjectEngine::resetPlayhead() noexcept {
    transport_.resetPlayhead();
}

void ProjectEngine::advancePlayhead(int numFrames, double sampleRate) noexcept {
    const double remaining = countInRemainingBeats_.load(std::memory_order_acquire);
    if (remaining > 0.0 && sampleRate > 0.0) {
        const double blockBeats = static_cast<double>(numFrames) / sampleRate *
            static_cast<double>(transport_.bpm()) / 60.0;
        if (blockBeats < remaining) {
            countInRemainingBeats_.store(remaining - blockBeats, std::memory_order_release);
            return;
        }
        countInRemainingBeats_.store(0.0, std::memory_order_release);
        const double leftoverBeats = blockBeats - remaining;
        const int leftoverFrames = static_cast<int>(std::lround(
            leftoverBeats * sampleRate * 60.0 / static_cast<double>(transport_.bpm())));
        if (leftoverFrames > 0) transport_.advancePlayhead(leftoverFrames, sampleRate);
        return;
    }
    transport_.advancePlayhead(numFrames, sampleRate);
}

TransportStateSnapshot ProjectEngine::transportState() const noexcept {
    TransportStateSnapshot state;
    state.playheadBeats = transport_.playheadBeats();
    state.playing = transport_.isPlaying();
    state.bpm = transport_.bpm();
    state.loopEnabled = transport_.loopEnabled();
    state.loopRegionStartBeat = transport_.loopRegionStartBeat();
    state.loopRegionEndBeat = transport_.loopRegionEndBeat();
    return state;
}

ProjectFileData ProjectEngine::toProjectFileData() const {
    const juce::ScopedWriteLock lock(mutex_);
    ProjectFileData file;
    file.projectFormatVersion = kProjectFormatVersion;
    file.name = projectName_;
    file.bpm = transport_.bpm();
    file.selectedTrackId = trackRepo_.selectedTrackId();
    file.loopEnabled = transport_.loopEnabled();
    file.loopRegionStartBeat = transport_.loopRegionStartBeat();
    file.loopRegionEndBeat = transport_.loopRegionEndBeat();
    file.master.id = "master";
    file.master.name = "Master";
    file.master.gain = masterGain_.load(std::memory_order_relaxed);
    if (sampleBank_ != nullptr) {
        for (const auto& sample : sampleBank_->listSamples()) {
            SampleLibraryEntryState entry;
            entry.id = sample.id;
            entry.name = sample.name;
            entry.source = sample.source;
            entry.durationBeats = sampleBank_->beatsForSample(sample.id, transport_.bpm());
            entry.waveformPeaks = sample.peaks;
            file.sampleLibrary.push_back(std::move(entry));
        }
    }
    file.tracks.reserve(trackRepo_.tracks().size());

    for (const auto& track : trackRepo_.tracks()) {
        TrackState ts;
        ts.id = track.id;
        ts.name = track.name;
        ts.iconKey = track.iconKey;
        ts.isGroup = track.isGroup;
        ts.muted = track.muted;
        ts.soloed = track.soloed;
        ts.parentGroupId = track.parentGroupId;
        for (const auto& device : track.devices) {
            ts.devices.push_back(device);
        }
        for (const auto& clip : track.midiClips) {
            MidiClipState cs;
            cs.id = clip.id;
            cs.startBeat = clip.startBeat;
            cs.lengthBeats = clip.lengthBeats;
            cs.naturalLengthBeats = clip.naturalLengthBeats;
            cs.loopContent = clip.loopContent;
            cs.editorScaleRoot = clip.editorScaleRoot;
            cs.editorScaleId = clip.editorScaleId;
            cs.editorScaleHighlight = clip.editorScaleHighlight;
            cs.editorScaleSnap = clip.editorScaleSnap;
            cs.editorChordQuality = clip.editorChordQuality;
            for (const auto& note : clip.notes) {
                cs.notes.push_back(MidiNoteState{
                    note.pitch,
                    note.startBeat,
                    note.durationBeats,
                    note.velocity,
                });
            }
            for (const auto& take : clip.takes) {
                MidiClipTakeState takeState;
                takeState.id = take.id;
                takeState.name = take.name;
                takeState.startBeatOffset = take.startBeatOffset;
                takeState.lengthBeats = take.lengthBeats;
                for (const auto& note : take.notes) {
                    takeState.notes.push_back(MidiNoteState{
                        note.pitch,
                        note.startBeat,
                        note.durationBeats,
                        note.velocity,
                    });
                }
                cs.takes.push_back(std::move(takeState));
            }
            for (const auto& region : clip.activeTakeRegions) {
                cs.activeTakeRegions.push_back({region.startBeat, region.endBeat,
                                                region.takeId, region.sourceStart,
                                                region.holdPrevious});
            }
            cs.compFlattened = clip.compFlattened;
            ts.midiClips.push_back(std::move(cs));
        }
        for (const auto& clip : track.sampleClips) {
            SampleClipState cs;
            cs.id = clip.id;
            cs.sampleId = clip.sampleId;
            cs.startBeat = clip.startBeat;
            cs.lengthBeats = clip.lengthBeats;
            cs.naturalLengthBeats = clip.naturalLengthBeats;
            cs.loopContent = clip.loopContent;
            cs.sourceStart = clip.sourceStart; cs.sourceEnd = clip.sourceEnd;
            cs.gain = clip.gain; cs.fadeIn = clip.fadeIn; cs.fadeOut = clip.fadeOut;
            cs.fadeInCurve = clip.fadeInCurve; cs.fadeOutCurve = clip.fadeOutCurve;
            cs.reversed = clip.reversed;
            cs.warpRepitch = clip.warpRepitch;
            cs.sliceMarkers = clip.sliceMarkers;
            for (const auto& take : clip.takes) {
                cs.takes.push_back({take.id, take.sampleId, take.name,
                                    take.startBeatOffset, take.lengthBeats});
            }
            for (const auto& region : clip.activeTakeRegions) {
                cs.activeTakeRegions.push_back({region.startBeat, region.endBeat,
                                                region.takeId, region.sourceStart});
            }
            if (sampleBank_ != nullptr) {
                if (const auto* sample = sampleBank_->findSample(clip.sampleId)) {
                    cs.sampleName = sample->name;
                    cs.waveformPeaks = sample->peaks;
                }
            }
            ts.sampleClips.push_back(std::move(cs));
        }
        ts.freeze.enabled = track.freeze.enabled;
        ts.freeze.stale = track.freeze.stale;
        ts.freeze.assetId = track.freeze.assetId;
        ts.freeze.startBeat = track.freeze.startBeat;
        ts.freeze.lengthBeats = track.freeze.lengthBeats;
        ts.freeze.sampleRate = track.freeze.sampleRate;
        ts.freeze.bpmAtFreeze = track.freeze.bpmAtFreeze;
        ts.freeze.contentSignature = track.freeze.contentSignature;
        ts.freeze.waveformPeaks = track.freeze.waveformPeaks;
        file.tracks.push_back(std::move(ts));
    }
    file.lfos = modulationGraph_.lfos();
    file.modEdges = modulationGraph_.modEdges();
    file.automationClips.reserve(automationClipStore_.clips().size());
    for (const auto& clip : automationClipStore_.clips()) {
        AutomationClipState cs;
        cs.id = clip.id;
        cs.homeTrackId = clip.homeTrackId;
        cs.startBeat = clip.startBeat;
        cs.lengthBeats = clip.lengthBeats;
        cs.naturalLengthBeats = clip.naturalLengthBeats;
        cs.loopContent = clip.loopContent;
        cs.deviceId = clip.deviceId;
        cs.paramId = clip.paramId;
        for (const auto& point : clip.points) {
            cs.points.push_back(AutomationPointState{point.beat, point.value});
        }
        file.automationClips.push_back(std::move(cs));
    }
    return file;
}

bool ProjectEngine::loadFromProjectFileData(const ProjectFileData& data) {
    if (data.projectFormatVersion != kProjectFormatVersion) {
        return false;
    }

    const juce::ScopedWriteLock lock(mutex_);
    clearGraphTapsLocked();
    projectName_ = data.name.empty() ? "Untitled" : data.name;
    if (data.bpm > 0) {
        transport_.setBpm(data.bpm);
    } else {
        transport_.setBpm(120);
    }
    transport_.setLoopEnabled(data.loopEnabled);
    if (!transport_.setLoopRegion(data.loopRegionStartBeat, data.loopRegionEndBeat)) {
        transport_.setLoopRegion(0.0, 16.0);
    }
    trackRepo_.setSelectedTrackId(data.selectedTrackId);
    trackRepo_.tracks().clear();

    for (const auto& trackState : data.tracks) {
        Track track;
        track.id = trackState.id;
        track.name = trackState.name;
        track.iconKey = trackState.iconKey;
        track.isGroup = trackState.isGroup;
        track.muted = trackState.muted;
        track.soloed = trackState.soloed;
        track.parentGroupId = trackState.parentGroupId;
        for (const auto& deviceState : trackState.devices) {
            track.devices.push_back(deviceState);
        }
        for (const auto& clipState : trackState.midiClips) {
            MidiClip clip;
            clip.id = clipState.id;
            clip.startBeat = clipState.startBeat;
            clip.lengthBeats = clipState.lengthBeats;
            clip.naturalLengthBeats = clipState.naturalLengthBeats > 0.0
                ? clipState.naturalLengthBeats
                : midiNotesContentLengthBeats(clipState.notes, clipState.lengthBeats);
            clip.loopContent = clipState.loopContent;
            clip.editorScaleRoot = clipState.editorScaleRoot;
            clip.editorScaleId = clipState.editorScaleId;
            clip.editorScaleHighlight = clipState.editorScaleHighlight;
            clip.editorScaleSnap = clipState.editorScaleSnap;
            clip.editorChordQuality = clipState.editorChordQuality;
            for (const auto& noteState : clipState.notes) {
                MidiNote note;
                note.pitch = noteState.pitch;
                note.startBeat = noteState.startBeat;
                note.durationBeats = noteState.durationBeats;
                note.velocity = noteState.velocity;
                clip.notes.push_back(note);
            }
            for (const auto& takeState : clipState.takes) {
                MidiClipTake take;
                take.id = takeState.id;
                take.name = takeState.name;
                take.startBeatOffset = takeState.startBeatOffset;
                take.lengthBeats = takeState.lengthBeats;
                for (const auto& noteState : takeState.notes) {
                    MidiNote note;
                    note.pitch = noteState.pitch;
                    note.startBeat = noteState.startBeat;
                    note.durationBeats = noteState.durationBeats;
                    note.velocity = noteState.velocity;
                    take.notes.push_back(note);
                }
                clip.takes.push_back(std::move(take));
            }
            for (const auto& regionState : clipState.activeTakeRegions) {
                MidiClipTakeRegion region;
                region.startBeat = regionState.startBeat;
                region.endBeat = regionState.endBeat;
                region.takeId = regionState.takeId;
                region.sourceStart = regionState.sourceStart;
                region.holdPrevious = regionState.holdPrevious;
                clip.activeTakeRegions.push_back(std::move(region));
            }
            clip.compFlattened = clipState.compFlattened;
            track.midiClips.push_back(std::move(clip));
        }
        for (const auto& clipState : trackState.sampleClips) {
            SampleClip clip;
            clip.id = clipState.id;
            clip.sampleId = clipState.sampleId;
            clip.startBeat = clipState.startBeat;
            clip.lengthBeats = clipState.lengthBeats;
            clip.naturalLengthBeats = clipState.naturalLengthBeats;
            clip.loopContent = clipState.loopContent;
            clip.sourceStart = clipState.sourceStart; clip.sourceEnd = clipState.sourceEnd;
            clip.gain = clipState.gain; clip.fadeIn = clipState.fadeIn;
            clip.fadeOut = clipState.fadeOut; clip.reversed = clipState.reversed;
            clip.warpRepitch = clipState.warpRepitch;
            clip.sliceMarkers = clipState.sliceMarkers;
            clip.fadeInCurve = clipState.fadeInCurve; clip.fadeOutCurve = clipState.fadeOutCurve;
            for (const auto& takeState : clipState.takes) {
                SampleClipTake take;
                take.id = takeState.id;
                take.sampleId = takeState.sampleId;
                take.name = takeState.name;
                take.startBeatOffset = takeState.startBeatOffset;
                take.lengthBeats = takeState.lengthBeats;
                clip.takes.push_back(std::move(take));
            }
            for (const auto& regionState : clipState.activeTakeRegions) {
                SampleClipTakeRegion region;
                region.startBeat = regionState.startBeat;
                region.endBeat = regionState.endBeat;
                region.takeId = regionState.takeId;
                region.sourceStart = regionState.sourceStart;
                clip.activeTakeRegions.push_back(std::move(region));
            }
            track.sampleClips.push_back(std::move(clip));
        }
        track.freeze.enabled = trackState.freeze.enabled;
        track.freeze.stale = trackState.freeze.stale;
        track.freeze.assetId = trackState.freeze.assetId;
        track.freeze.startBeat = trackState.freeze.startBeat;
        track.freeze.lengthBeats = trackState.freeze.lengthBeats;
        track.freeze.sampleRate = trackState.freeze.sampleRate;
        track.freeze.bpmAtFreeze = trackState.freeze.bpmAtFreeze;
        track.freeze.contentSignature = trackState.freeze.contentSignature;
        track.freeze.waveformPeaks = trackState.freeze.waveformPeaks;
        trackRepo_.tracks().push_back(std::move(track));
    }

    // Automation clips live in the global store; the per-track field on
    // TrackState is only read for legacy file fallback inside
    // parseProjectFileJson, never from this entry point.
    std::vector<AutomationClip> loadedClips;
    loadedClips.reserve(data.automationClips.size());
    for (const auto& clipState : data.automationClips) {
        AutomationClip clip;
        clip.id = clipState.id;
        clip.homeTrackId = clipState.homeTrackId;
        clip.startBeat = clipState.startBeat;
        clip.lengthBeats = clipState.lengthBeats;
        clip.naturalLengthBeats = clipState.naturalLengthBeats > 0.0
            ? clipState.naturalLengthBeats
            : automationPointsContentLengthBeats(clipState.points, clipState.lengthBeats);
        clip.loopContent = clipState.loopContent;
        clip.deviceId = clipState.deviceId;
        clip.paramId = clipState.paramId;
        for (const auto& pointState : clipState.points) {
            AutomationPoint point;
            point.beat = pointState.beat;
            point.value = pointState.value;
            clip.points.push_back(point);
        }
        loadedClips.push_back(std::move(clip));
    }
    automationClipStore_.load(loadedClips);

    recomputeIdCountersLocked();
    trackRepo_.ensureTrackGainDevices(deviceRegistry_);
    trackRepo_.ensureTrackIcons();

    modulationGraph_.replaceRecords(data.lfos, data.modEdges);
    // Rebuild the playback array BEFORE rebuilding the track snapshot.
    // The snapshot resolver maps each modulation edge's LFO domain id to its
    // compact playback array index; if rebuildPlayback() hasn't run yet, every
    // edge is dropped silently and modulation never reaches the audio thread
    // after a project reload.
    // Note: replaceRecords() already calls recomputeIdCounters() + rebuildPlayback().

    if (data.master.gain > 0.0f) {
        masterGain_.store(std::clamp(data.master.gain, 0.0f, 1.0f), std::memory_order_release);
    } else {
        masterGain_.store(1.0f, std::memory_order_release);
    }
    transport_.setPlaying(false);
    transport_.resetPlayhead();
    syncActiveFrequencyLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

int ProjectEngine::createLfo(int modulatorType) {
    const juce::ScopedWriteLock lock(mutex_);
    return modulationGraph_.createLfo(modulatorType);
}

bool ProjectEngine::removeLfo(int lfoId) {
    const juce::ScopedWriteLock lock(mutex_);
    const bool result = modulationGraph_.removeLfo(lfoId);
    if (result) {
        rebuildModEdgesLocked();
    }
    return result;
}

bool ProjectEngine::updateLfoParam(int lfoId, const std::string& param, float value) {
    const juce::ScopedWriteLock lock(mutex_);
    return modulationGraph_.updateLfoParam(lfoId, param, value);
}

bool ProjectEngine::batchUpdateLfoParams(int lfoId, const std::vector<std::pair<std::string, float>>& params) {
    const juce::ScopedWriteLock lock(mutex_);
    return modulationGraph_.batchUpdateLfoParams(lfoId, params);
}

bool ProjectEngine::assignModulation(int lfoId, const std::string& deviceId,
                                     const std::string& paramId, float amount) {
    const juce::ScopedWriteLock lock(mutex_);
    if (findDeviceLocked(deviceId) == nullptr) {
        return false;
    }
    const bool result = modulationGraph_.assignModulation(lfoId, deviceId, paramId, amount);
    if (result) {
        rebuildModEdgesLocked();
    }
    return result;
}

bool ProjectEngine::removeModulation(int lfoId,
                                     const std::string& deviceId,
                                     const std::string& paramId) {
    const juce::ScopedWriteLock lock(mutex_);
    const bool result = modulationGraph_.removeModulation(lfoId, deviceId, paramId);
    if (result) {
        rebuildModEdgesLocked();
    }
    return result;
}

bool ProjectEngine::applySubtractiveSynthPreset(
    const std::string& deviceId,
    const std::vector<std::pair<std::string, float>>& params,
    const std::vector<SubtractivePresetLfoSpec>& lfos,
    const std::vector<SubtractivePresetModSpec>& mods) {
    const juce::ScopedWriteLock lock(mutex_);
    DeviceSlot* device = findDeviceLocked(deviceId);
    if (device == nullptr || deviceNodeKindFromTypeId(device->config.typeId) != DeviceNodeKind::SubtractiveSynth) {
        return false;
    }

    std::vector<int> lfosTouchingDevice;
    for (const auto& edge : modulationGraph_.modEdges()) {
        if (edge.deviceId == deviceId) {
            lfosTouchingDevice.push_back(edge.lfoId);
        }
    }
    modulationGraph_.removeModulationForDevice(deviceId);
    for (int lfoId : lfosTouchingDevice) {
        bool stillUsed = false;
        for (const auto& edge : modulationGraph_.modEdges()) {
            if (edge.lfoId == lfoId) {
                stillUsed = true;
                break;
            }
        }
        if (!stillUsed) {
            modulationGraph_.removeLfo(lfoId);
        }
    }

    bool syncFrequency = false;
    for (const auto& [parameterId, value] : params) {
        const DeviceParameterResult result =
            deviceRegistry_.setParameter(*device, parameterId, value);
        if (!result.handled) {
            return false;
        }
        if (result.syncActiveFrequency) {
            syncFrequency = true;
        }
    }

    std::vector<int> createdLfoIds;
    createdLfoIds.reserve(lfos.size());
    for (const auto& spec : lfos) {
        const int lfoId = modulationGraph_.createLfo();
        modulationGraph_.updateLfoParam(lfoId, "waveform", static_cast<float>(spec.waveform));
        modulationGraph_.updateLfoParam(lfoId, "rate", spec.rate);
        modulationGraph_.updateLfoParam(lfoId, "syncDivision", static_cast<float>(spec.syncDivision));
        modulationGraph_.updateLfoParam(lfoId, "phase", spec.phase);
        modulationGraph_.updateLfoParam(lfoId, "polarity", static_cast<float>(spec.polarity));
        createdLfoIds.push_back(lfoId);
    }

    for (const auto& mod : mods) {
        if (mod.lfoIndex < 0 || mod.lfoIndex >= static_cast<int>(createdLfoIds.size())) {
            return false;
        }
        if (!modulationGraph_.assignModulation(
                createdLfoIds[static_cast<size_t>(mod.lfoIndex)], deviceId, mod.paramId, mod.amount)) {
            return false;
        }
    }

    if (syncFrequency) {
        syncActiveFrequencyLocked();
    }
    rebuildTrackPlaybackLocked();
    return true;
}

void ProjectEngine::recomputeIdCountersLocked() {
    trackRepo_.recomputeIdCounters();
    clipRepo_.recomputeIdCounters();
    modulationGraph_.recomputeIdCounters();
}

std::string ProjectEngine::getDeviceMetersJson() {
    // Shared lock to safely read meter slot assignments alongside the
    // audio thread (which holds exclusive lock during rebuild).
    const juce::ScopedReadLock lock(mutex_);
    std::string json = R"({"ok":true,"meters":{)";
    bool first = true;
    for (int i = 0; i < deviceMeterSlotCount_; ++i) {
        if (!meterSlotSubscribed_[i]) {
            continue;
        }
        if (!first) json += ",";
        first = false;
        const float gr = deviceMeters_[i].gainReductionDb.load(std::memory_order_relaxed);
        const float in = deviceMeters_[i].inputPeak.load(std::memory_order_relaxed);
        const float inL = deviceMeters_[i].inputPeakL.load(std::memory_order_relaxed);
        const float inR = deviceMeters_[i].inputPeakR.load(std::memory_order_relaxed);
        json += "\"";
        json += deviceMeterIds_[i];
        json += R"(":{"gr":)";
        // Format gain reduction as 1 decimal, input level as 3 decimal
        char buf[64];
        snprintf(buf, sizeof(buf), "%.1f", static_cast<double>(gr));
        json += buf;
        json += R"(,"left":)";
        snprintf(buf, sizeof(buf), "%.3f", static_cast<double>(inL));
        json += buf;
        json += R"(,"right":)";
        snprintf(buf, sizeof(buf), "%.3f", static_cast<double>(inR));
        json += buf;
        json += R"(,"in":)";
        snprintf(buf, sizeof(buf), "%.3f", static_cast<double>(in));
        json += buf;
        json += R"(,"lufs":)";
        snprintf(buf, sizeof(buf), "%.1f", static_cast<double>(deviceMeters_[i].loudness.load(std::memory_order_relaxed)));
        json += buf;
        json += R"(,"corr":)";
        snprintf(buf, sizeof(buf), "%.3f", static_cast<double>(deviceMeters_[i].correlation.load(std::memory_order_relaxed)));
        json += buf;
        json += R"(,"wave":[)";
        for (int n = 0; n < 32; ++n) { if (n) json += ","; snprintf(buf, sizeof(buf), "%.3f", static_cast<double>(deviceMeters_[i].waveform[n].load(std::memory_order_relaxed))); json += buf; }
        json += R"(],"spectrum":[)";
        for (int n = 0; n < 24; ++n) { if (n) json += ","; snprintf(buf, sizeof(buf), "%.3f", static_cast<double>(deviceMeters_[i].spectrum[n].load(std::memory_order_relaxed))); json += buf; }
        json += "]";
        json += "}";
    }
    json += "}}";
    return json;
}

void ProjectEngine::setMeterSubscriptions(const std::vector<std::string>& deviceIds) {
    const juce::ScopedWriteLock lock(mutex_);
    meterSlotSubscribed_.fill(false);
    for (const auto& id : deviceIds) {
        for (int i = 0; i < deviceMeterSlotCount_; ++i) {
            if (deviceMeterIds_[i] == id) {
                meterSlotSubscribed_[i] = true;
                break;
            }
        }
    }
}

std::string ProjectEngine::createGraphTap(const std::string& deviceId,
                                          GraphTapKind kind,
                                          uint32_t capacityFrames) {
    const juce::ScopedWriteLock lock(mutex_);
    DeviceSlot* device = findDeviceLocked(deviceId);
    if (device == nullptr || kind == GraphTapKind::None) return {};
    const auto nodeKind = deviceNodeKindFromTypeId(device->config.typeId);
    const auto plan = compileDeviceExecutionPlan(nodeKind);
    if (!plan.valid() ||
        !hasPort(plan.logical.nodes[2].outputPorts, DevicePortMask::Audio)) {
        return {};
    }

    int slot = -1;
    for (int i = 0; i < kMaxProcessorGraphTaps; ++i) {
        if (!graphTapRegistrations_[static_cast<size_t>(i)].active) {
            slot = i;
            break;
        }
    }
    if (slot < 0) return {};

    auto& runtime = graphTapRuntimes_[slot];
    uint32_t generation = runtime.generation.fetch_add(1, std::memory_order_acq_rel) + 1;
    if (generation == 0) {
        generation = 1;
        runtime.generation.store(generation, std::memory_order_release);
    }
    while (runtime.writers.load(std::memory_order_acquire) != 0) {
        std::this_thread::yield();
    }
    resetGraphTapRuntime(runtime, generation);

    auto& registration = graphTapRegistrations_[static_cast<size_t>(slot)];
    registration.active = true;
    registration.tapId = "tap-" + std::to_string(nextGraphTapId_++);
    registration.deviceId = deviceId;
    registration.sourceOutputNodeId = stableDeviceSubgraphNodeId(
        deviceId, DeviceSubgraphNodeRole::OutputAdapter);
    registration.kind = kind;
    registration.capacityFrames = std::clamp(
        capacityFrames, 1u, kGraphTapMaxBufferedFrames);
    registration.generation = generation;

    // Tap creation is a structural observer edit. Compile it into the inactive
    // playback/graph state and publish at a callback boundary.
    rebuildTrackPlaybackLocked();
    return registration.tapId;
}

bool ProjectEngine::removeGraphTap(const std::string& tapId) {
    const juce::ScopedWriteLock lock(mutex_);
    for (int slot = 0; slot < kMaxProcessorGraphTaps; ++slot) {
        auto& registration = graphTapRegistrations_[static_cast<size_t>(slot)];
        if (!registration.active || registration.tapId != tapId) continue;
        registration.active = false;
        auto& runtime = graphTapRuntimes_[slot];
        uint32_t generation = runtime.generation.fetch_add(1, std::memory_order_acq_rel) + 1;
        if (generation == 0) {
            generation = 1;
            runtime.generation.store(generation, std::memory_order_release);
        }
        rebuildTrackPlaybackLocked();
        while (runtime.writers.load(std::memory_order_acquire) != 0) {
            std::this_thread::yield();
        }
        resetGraphTapRuntime(runtime, generation);
        registration = GraphTapRegistration{};
        return true;
    }
    return false;
}

std::string ProjectEngine::readGraphTapJson(const std::string& tapId, int maxFrames) {
    // Analyzer/recorder reads advance the SPSC consumer tail, so serialize
    // readers even though they never mutate the editable project model.
    const juce::ScopedWriteLock lock(mutex_);
    int slot = -1;
    const GraphTapRegistration* registration = nullptr;
    for (int i = 0; i < kMaxProcessorGraphTaps; ++i) {
        const auto& candidate = graphTapRegistrations_[static_cast<size_t>(i)];
        if (candidate.active && candidate.tapId == tapId) {
            slot = i;
            registration = &candidate;
            break;
        }
    }
    if (registration == nullptr) {
        return R"({"ok":false,"error":"tap_not_found"})";
    }
    auto& runtime = graphTapRuntimes_[slot];
    const char* kindName = registration->kind == GraphTapKind::Meter ? "meter" :
        registration->kind == GraphTapKind::Analyzer ? "analyzer" : "recorder";
    const auto jsonString = [](const std::string& value) {
        const auto text = juce::String::fromUTF8(
            value.data(), static_cast<int>(value.size()));
        return juce::JSON::toString(juce::var(text), false).toStdString();
    };
    GraphTapMeterSnapshot meter;
    if (registration->kind == GraphTapKind::Meter) {
        while (!tryReadGraphTapMeter(runtime, meter)) {
            std::this_thread::yield();
        }
    }
    const uint64_t sequence = registration->kind == GraphTapKind::Meter
        ? meter.sequence : runtime.sequence.load(std::memory_order_acquire);
    const uint32_t sampleRate = registration->kind == GraphTapKind::Meter
        ? meter.sampleRate : runtime.sampleRate.load(std::memory_order_relaxed);
    std::string json = R"({"ok":true,"tapId":)" + jsonString(tapId) +
        R"(,"type":")" + kindName + R"(","deviceId":)" +
        jsonString(registration->deviceId) + R"(,"sequence":)" +
        std::to_string(sequence) +
        R"(,"sampleRate":)" +
        std::to_string(sampleRate) +
        R"(,"droppedFrames":)" +
        std::to_string(runtime.droppedFrames.load(std::memory_order_relaxed)) +
        R"(,"overflowed":)" +
        (runtime.overflowed.load(std::memory_order_acquire) ? "true" : "false");
    json += R"(,"sourceAvailable":)";
    json += findDeviceLocked(registration->deviceId) != nullptr ? "true" : "false";

    char buf[64];
    if (registration->kind == GraphTapKind::Meter) {
        json += R"(,"peakL":)";
        snprintf(buf, sizeof(buf), "%.6f", static_cast<double>(meter.peakL));
        json += buf;
        json += R"(,"peakR":)";
        snprintf(buf, sizeof(buf), "%.6f", static_cast<double>(meter.peakR));
        json += buf;
        json += R"(,"rmsL":)";
        snprintf(buf, sizeof(buf), "%.6f", static_cast<double>(meter.rmsL));
        json += buf;
        json += R"(,"rmsR":)";
        snprintf(buf, sizeof(buf), "%.6f", static_cast<double>(meter.rmsR));
        json += buf;
    } else {
        const uint32_t capacity = registration->capacityFrames;
        const uint64_t head = runtime.head.load(std::memory_order_acquire);
        const uint64_t tail = runtime.tail.load(std::memory_order_relaxed);
        const uint64_t available = std::min<uint64_t>(head - tail, capacity);
        if (registration->kind == GraphTapKind::Analyzer) {
            const int count = static_cast<int>(std::min<uint64_t>(
                available, kGraphTapAnalyzerWindowFrames));
            const uint64_t start = head - static_cast<uint64_t>(count);
            float mono[kGraphTapAnalyzerWindowFrames]{};
            for (int i = 0; i < count; ++i) {
                const size_t pos = static_cast<size_t>((start + i) % capacity);
                mono[kGraphTapAnalyzerWindowFrames - count + i] =
                    0.5f * (runtime.ringL[pos] + runtime.ringR[pos]);
            }
            runtime.tail.store(head, std::memory_order_release);
            json += R"(,"waveform":[)";
            constexpr int waveformBins = 32;
            for (int bin = 0; bin < waveformBins; ++bin) {
                if (bin) json += ",";
                float peak = 0.0f;
                const int begin = bin * kGraphTapAnalyzerWindowFrames / waveformBins;
                const int end = (bin + 1) * kGraphTapAnalyzerWindowFrames / waveformBins;
                for (int i = begin; i < end; ++i) peak = std::max(peak, std::abs(mono[i]));
                snprintf(buf, sizeof(buf), "%.6f", static_cast<double>(peak));
                json += buf;
            }
            json += R"(],"spectrum":[)";
            constexpr int spectrumBins = 24;
            for (int bin = 0; bin < spectrumBins; ++bin) {
                if (bin) json += ",";
                double real = 0.0;
                double imag = 0.0;
                const int frequencyBin = bin + 1;
                for (int i = 0; i < kGraphTapAnalyzerWindowFrames; ++i) {
                    const double phase = -2.0 * juce::MathConstants<double>::pi *
                        frequencyBin * i / kGraphTapAnalyzerWindowFrames;
                    real += mono[i] * std::cos(phase);
                    imag += mono[i] * std::sin(phase);
                }
                const double magnitude = std::sqrt(real * real + imag * imag) /
                    kGraphTapAnalyzerWindowFrames;
                snprintf(buf, sizeof(buf), "%.6f", magnitude);
                json += buf;
            }
            json += "]";
        } else {
            const int requested = std::clamp(maxFrames, 1, 2048);
            const int count = static_cast<int>(std::min<uint64_t>(available, requested));
            json += R"(,"frameCount":)" + std::to_string(count) + R"(,"left":[)";
            for (int i = 0; i < count; ++i) {
                if (i) json += ",";
                const size_t pos = static_cast<size_t>((tail + i) % capacity);
                snprintf(buf, sizeof(buf), "%.8f", static_cast<double>(runtime.ringL[pos]));
                json += buf;
            }
            json += R"(],"right":[)";
            for (int i = 0; i < count; ++i) {
                if (i) json += ",";
                const size_t pos = static_cast<size_t>((tail + i) % capacity);
                snprintf(buf, sizeof(buf), "%.8f", static_cast<double>(runtime.ringR[pos]));
                json += buf;
            }
            json += "]";
            runtime.tail.store(tail + static_cast<uint64_t>(count), std::memory_order_release);
        }
    }
    json += "}";
    return json;
}

void ProjectEngine::clearGraphTapsLocked() noexcept {
    for (int slot = 0; slot < kMaxProcessorGraphTaps; ++slot) {
        auto& registration = graphTapRegistrations_[static_cast<size_t>(slot)];
        if (!registration.active) continue;
        registration.active = false;
        auto& runtime = graphTapRuntimes_[slot];
        uint32_t generation = runtime.generation.fetch_add(1, std::memory_order_acq_rel) + 1;
        if (generation == 0) generation = 1;
        runtime.generation.store(generation, std::memory_order_release);
        while (runtime.writers.load(std::memory_order_acquire) != 0) {
            std::this_thread::yield();
        }
        resetGraphTapRuntime(runtime, generation);
        registration = GraphTapRegistration{};
    }
}

void ProjectEngine::applyLiveDeviceMetersLocked(ProjectSnapshot& snap) const {
    for (auto& trackState : snap.tracks) {
        for (auto& device : trackState.devices) {
            const bool isDynamics =
                deviceNodeKindFromTypeId(device.config.typeId) == DeviceNodeKind::Gate ||
                deviceNodeKindFromTypeId(device.config.typeId) == DeviceNodeKind::Compressor ||
                deviceNodeKindFromTypeId(device.config.typeId) == DeviceNodeKind::Expander ||
                deviceNodeKindFromTypeId(device.config.typeId) == DeviceNodeKind::Limiter;
            if (!isDynamics) continue;
            for (int i = 0; i < deviceMeterSlotCount_; ++i) {
                if (deviceMeterIds_[i] != device.id) {
                    continue;
                }
                DeviceMeterState meter;
                meter.deviceId = device.id;
                meter.gainReductionDb =
                    deviceMeters_[i].gainReductionDb.load(std::memory_order_relaxed);
                meter.inputLevel =
                    deviceMeters_[i].inputPeak.load(std::memory_order_relaxed);
                trackState.deviceMeters.push_back(std::move(meter));
                break;
            }
        }
    }
}

void ProjectEngine::rebuildTrackPlaybackLocked() {
    const std::lock_guard<std::recursive_mutex> playbackLock(playbackMutex_);
    if (syncingTree_) return;
    const int committedState = trackPlayback_.beginBuild();
    if (committedState >= 0) {
        activeProcessorGraph_.store(
            trackPlayback_.graphIndexForState(committedState),
            std::memory_order_release);
    }
    const int activePlaybackState = trackPlayback_.active.load(std::memory_order_acquire);
    const int activePlaybackTrackCount = trackPlayback_.counts[activePlaybackState];
    deviceMeterSlotCount_ = 0;
    int trackIndex = 0;
    for (const auto& sourceTrack : trackRepo_.tracks()) {
        if (trackIndex >= kMaxTracks) {
            break;
        }

        TrackPlaybackSnapshot& snap = trackPlayback_[trackIndex];
        snap.trackId = sourceTrack.id;
        snap.muted = sourceTrack.muted;
        snap.soloed = sourceTrack.soloed;
        snap.audibilityGain = sourceTrack.muted ? 0.0f : 1.0f;
        snap.parentGroupTrackIndex = -1;
        if (!sourceTrack.parentGroupId.empty()) {
            for (size_t parentIndex = 0; parentIndex < trackRepo_.tracks().size(); ++parentIndex) {
                const auto& parent = trackRepo_.tracks()[parentIndex];
                if (parent.id == sourceTrack.parentGroupId && parent.isGroup) {
                    snap.parentGroupTrackIndex = static_cast<int>(parentIndex);
                    break;
                }
            }
        }
        snap.noteCount = 0;
        snap.regionCount = 0;
        snap.deviceCount = 0;
        snap.deviceExecutionOrder = {};
        std::vector<DeviceSubgraphTree> deviceSubgraphRoots;
        deviceSubgraphRoots.reserve(sourceTrack.devices.size());

        // Build processor chain from device snapshot into the arena
        snap.arena.reset();

        PlaybackBuildContext context{sampleBank_};
        context.wavetableBank = wavetableBank_;
        context.deviceRegistry = &deviceRegistry_;
        auto emitDeviceToPlayback = [&](const DeviceSlot& dev) {
            if (snap.deviceCount >= kMaxDevicesPerTrack) return;
            DeviceNodePlayback& node = snap.devices[snap.deviceCount];
            node.deviceId = dev.id;
            node.bypassed = dev.config.bypassed;
            std::visit([&](const auto& panel) {
                using T = std::decay_t<decltype(panel)>;
                if constexpr (std::is_same_v<T, MonoOutputPanel>) {
                    node.gain = panel.gain;
                    node.pan = 0.5f;
                    node.outputMix = 1.0f;
                    node.outputWidth = 1.0f;
                } else if constexpr (std::is_same_v<T, StereoOutputPanel>) {
                    node.gain = panel.gain;
                    node.pan = panel.pan;
                    node.outputMix = panel.outputMix;
                    node.outputWidth = panel.outputWidth;
                } else {
                    node.gain = 1.0f;
                    node.pan = 0.5f;
                    node.outputMix = 1.0f;
                    node.outputWidth = 1.0f;
                }
            }, dev.config.outputPanel);
            node.meterSlot = -1;
            deviceRegistry_.buildPlaybackNode(dev, context, node);
            node.automationTargetIndex = static_cast<uint16_t>(snap.deviceCount);
            if (node.kind == DeviceNodeKind::DrumMachine) {
                auto playback = std::get<DrumMachineParams>(node.params).playback;
                if (playback != nullptr) {
                    auto mutablePlayback = std::const_pointer_cast<DrumMachinePlayback>(playback);
                    for (int note = 0; note < 128; ++note) {
                        auto& pad = mutablePlayback->pads[note];
                        for (int child = 0; child < pad.deviceCount; ++child) {
                            pad.devices[child].automationTargetIndex = static_cast<uint16_t>(
                                0x8000u | (static_cast<uint16_t>(snap.deviceCount) << 9u) |
                                (static_cast<uint16_t>(note) << 2u) |
                                static_cast<uint16_t>(child));
                        }
                    }
                }
            }
            if (node.kind == DeviceNodeKind::Chain) {
                auto playback = std::get<ChainParams>(node.params).playback;
                if (playback != nullptr) {
                    auto mutablePlayback = std::const_pointer_cast<ChainPlayback>(playback);
                    for (int child = 0; child < mutablePlayback->deviceCount; ++child) {
                        mutablePlayback->devices[child].automationTargetIndex = static_cast<uint16_t>(
                            0x4000u | (static_cast<uint16_t>(snap.deviceCount) << 4u) |
                            static_cast<uint16_t>(child));
                    }
                }
            }
            if ((isDynamicsDeviceNodeKind(node.kind) || isAnalysisDeviceNodeKind(node.kind)) && deviceMeterSlotCount_ < kMaxDeviceMeters) {
                node.meterSlot = static_cast<int8_t>(deviceMeterSlotCount_);
                deviceMeterIds_[deviceMeterSlotCount_] = dev.id;
                ++deviceMeterSlotCount_;
            }
            ++snap.deviceCount;
        };

        for (const auto& device : sourceTrack.devices) {
            if (snap.deviceCount >= kMaxDevicesPerTrack) break;
            deviceSubgraphRoots.push_back(buildDeviceSubgraphTree(device));
            if (device_types::isSynthType(device.config.typeId)) {
                for (const auto& fx : device.noteFxDevices)
                    if (fx) emitDeviceToPlayback(*fx);
                emitDeviceToPlayback(device);
                for (const auto& fx : device.audioFxDevices)
                    if (fx) emitDeviceToPlayback(*fx);
            } else {
                emitDeviceToPlayback(device);
            }
        }

        snap.deviceExecutionOrder = compileFusedForestExecutionOrder(
            std::span<const DeviceSubgraphTree>(deviceSubgraphRoots.data(),
                                                deviceSubgraphRoots.size()),
            std::span<const DeviceNodePlayback>(snap.devices,
                                                static_cast<size_t>(snap.deviceCount)));

        // Reuse the active processor instances only when every node payload is
        // identical. Shared arena storage keeps the old snapshot valid while
        // the audio thread finishes its block; a changed node receives a new
        // arena rather than being mutated from the control thread.
        const TrackPlaybackSnapshot* activeSnapshot =
            trackIndex < activePlaybackTrackCount
                ? &trackPlayback_.states[activePlaybackState][trackIndex]
                : nullptr;
        bool reuseActiveArena = activeSnapshot != nullptr &&
            snap.deviceCount == activeSnapshot->deviceCount &&
            snap.deviceCount == activeSnapshot->arena.size();
        if (reuseActiveArena) {
            for (int deviceIndex = 0; deviceIndex < snap.deviceCount; ++deviceIndex) {
                if (!playbackNodesEquivalent(
                        snap.devices[deviceIndex], activeSnapshot->devices[deviceIndex])) {
                    reuseActiveArena = false;
                    break;
                }
            }
        }

        if (reuseActiveArena) {
            snap.arena = activeSnapshot->arena;
        } else {
            std::unordered_map<std::string, int> activeDeviceIndices;
            if (activeSnapshot != nullptr) {
                for (int oldIndex = 0; oldIndex < activeSnapshot->deviceCount; ++oldIndex) {
                    activeDeviceIndices.emplace(activeSnapshot->devices[oldIndex].deviceId, oldIndex);
                }
            }
            for (int deviceIndex = 0; deviceIndex < snap.deviceCount; ++deviceIndex) {
                const auto& node = snap.devices[deviceIndex];
                const auto activeIt = activeDeviceIndices.find(node.deviceId);
                if (activeSnapshot != nullptr && activeIt != activeDeviceIndices.end() &&
                    playbackNodesEquivalent(node, activeSnapshot->devices[activeIt->second]) &&
                    snap.arena.reuseSlotAt(deviceIndex, activeSnapshot->arena, activeIt->second)) {
                    continue;
                }
                const IDeviceType* type = deviceRegistry_.findByKind(node.kind);
                if (type == nullptr) continue;
                auto* proc = type->createProcessor(snap.arena);
                if (proc == nullptr) continue;
                proc->applyPlaybackNode(node);
                proc->meterSlot = node.meterSlot;
            }
        }

        snap.trackGainDeviceIndex = -1;
        for (int i = 0; i < snap.deviceCount; ++i) {
            if (snap.devices[i].kind == DeviceNodeKind::TrackGain) {
                snap.trackGainDeviceIndex = i;
                break;
            }
        }

        snap.freeze = {};
        if (sourceTrack.freeze.enabled && freezeAssetStore_ != nullptr) {
            if (const FreezeAsset* asset = freezeAssetStore_->find(sourceTrack.freeze.assetId)) {
                snap.freeze.active = true;
                snap.freeze.pcmL = asset->pcmL.data();
                snap.freeze.pcmR = asset->pcmR.data();
                snap.freeze.frameCount = static_cast<int>(asset->pcmL.size());
                snap.freeze.pcmSampleRate = asset->sampleRate;
                snap.freeze.startBeat = sourceTrack.freeze.startBeat;
                snap.freeze.lengthBeats = sourceTrack.freeze.lengthBeats;
            }
        }

        if (!sourceTrack.freeze.enabled) {
        for (const auto& clip : sourceTrack.midiClips) {
            const double contentLengthBeats =
                clip.loopContent
                    ? midiClipLoopContentLengthBeats(
                          clip.notes, clip.naturalLengthBeats, clip.lengthBeats)
                    : midiClipOneShotContentLengthBeats(
                          clip.notes, clip.naturalLengthBeats, clip.lengthBeats);
            for (const auto& note : clip.notes) {
                if (snap.noteCount >= static_cast<int>(sizeof(snap.notes) / sizeof(snap.notes[0]))) {
                    break;
                }
                snap.notes[snap.noteCount++] = PlaybackNote{
                    note.pitch,
                    clip.startBeat,
                    clip.lengthBeats,
                    note.startBeat,
                    note.durationBeats,
                    note.velocity,
                    clip.loopContent,
                    contentLengthBeats,
                };
            }
        }

        if (sampleBank_ != nullptr) {
            for (const auto& clip : sourceTrack.sampleClips) {
                if (snap.regionCount >= static_cast<int>(sizeof(snap.regions) / sizeof(snap.regions[0]))) {
                    break;
                }
                const auto addRegion = [&](const SampleBank::Sample& sample,
                                           double clipStartBeat,
                                           double clipLengthBeats,
                                           double naturalLengthBeats,
                                           float sourceStart,
                                           float sourceEnd,
                                           bool loopContent) {
                    if (snap.regionCount >= static_cast<int>(sizeof(snap.regions) / sizeof(snap.regions[0])) ||
                        sample.pcm.empty() || clipLengthBeats <= 0.0) {
                        return;
                    }
                    snap.regions[snap.regionCount++] = SampleRegion{
                        clipStartBeat,
                        clipLengthBeats,
                        sample.pcm.data(),
                        static_cast<int>(sample.pcm.size()),
                        sample.sampleRate,
                        loopContent,
                        sampleClipContentLengthBeats(naturalLengthBeats,
                                                     clipLengthBeats,
                                                     sourceStart,
                                                     sourceEnd,
                                                     clip.warpRepitch),
                        sourceStart, sourceEnd, clip.gain,
                        clip.fadeIn, clip.fadeOut, clip.fadeInCurve,
                        clip.fadeOutCurve, clip.reversed,
                    };
                };
                if (!clip.takes.empty() && !clip.activeTakeRegions.empty()) {
                    for (const auto& region : clip.activeTakeRegions) {
                        const auto takeIt = std::find_if(
                            clip.takes.begin(), clip.takes.end(),
                            [&](const SampleClipTake& take) { return take.id == region.takeId; });
                        if (takeIt == clip.takes.end() || takeIt->lengthBeats <= 0.0) {
                            continue;
                        }
                        const auto* sample = sampleBank_->findSample(takeIt->sampleId);
                        const double regionLength = region.endBeat - region.startBeat;
                        if (sample == nullptr || sample->pcm.empty() || regionLength <= 0.0) {
                            continue;
                        }
                        const double sourceStartNorm =
                            std::clamp(region.sourceStart / takeIt->lengthBeats, 0.0, 1.0);
                        const double sourceEndNorm =
                            std::clamp((region.sourceStart + regionLength) / takeIt->lengthBeats,
                                       sourceStartNorm, 1.0);
                        addRegion(*sample,
                                  clip.startBeat + region.startBeat,
                                  regionLength,
                                  takeIt->lengthBeats,
                                  static_cast<float>(sourceStartNorm),
                                  static_cast<float>(sourceEndNorm),
                                  false);
                    }
                    continue;
                }
                const auto* sample = sampleBank_->findSample(clip.sampleId);
                if (sample == nullptr || sample->pcm.empty()) {
                    continue;
                }
                addRegion(*sample,
                          clip.startBeat,
                          clip.lengthBeats,
                          clip.naturalLengthBeats,
                          clip.sourceStart,
                          clip.sourceEnd,
                          clip.loopContent);
            }
        }
        }

        // Resolve per-track automation clips
        snap.automationClipCount = 0;
        for (const auto& clip : automationClipStore_.clips()) {
            if (snap.automationClipCount >= 16) break;
            if (clip.deviceId.empty()) continue;
        int di = -1;
        uint16_t targetIndex = 0;
        DeviceNodeKind targetKind = DeviceNodeKind::Unknown;
        const IDeviceType* targetType = nullptr;
        for (int i = 0; i < snap.deviceCount; ++i) {
            if (snap.devices[i].deviceId == clip.deviceId) {
                di = i;
                targetIndex = static_cast<uint16_t>(i);
                targetKind = snap.devices[i].kind;
                targetType = deviceRegistry_.findByKind(targetKind);
                break;
            }
            if (snap.devices[i].kind == DeviceNodeKind::DrumMachine) {
                const auto playback = std::get<DrumMachineParams>(snap.devices[i].params).playback;
                if (playback == nullptr) continue;
                for (int note = 0; note < 128 && di < 0; ++note) {
                    const auto& pad = playback->pads[note];
                    for (int child = 0; child < pad.deviceCount; ++child) {
                        const auto& childNode = pad.devices[child];
                        if (childNode.deviceId != clip.deviceId) continue;
                        di = i;
                        targetIndex = childNode.automationTargetIndex;
                        targetKind = childNode.kind;
                        targetType = deviceRegistry_.findByKind(targetKind);
                        break;
                    }
                }
            }
            if (snap.devices[i].kind == DeviceNodeKind::Chain) {
                const auto playback = std::get<ChainParams>(snap.devices[i].params).playback;
                if (playback == nullptr) continue;
                for (int child = 0; child < playback->deviceCount; ++child) {
                    const auto& childNode = playback->devices[child];
                    if (childNode.deviceId != clip.deviceId) continue;
                    di = i;
                    targetIndex = childNode.automationTargetIndex;
                    targetKind = childNode.kind;
                    targetType = deviceRegistry_.findByKind(targetKind);
                    break;
                }
            }
        }
        if (di < 0) continue; // target device lives on another track
        AutomationClipPlayback pb{};
        if (!automationClipPlaybackFromClip(clip, pb)) continue;
        pb.deviceIndex = targetIndex;
        pb.targetNodeId = stableDeviceSubgraphNodeId(
            clip.deviceId, DeviceSubgraphNodeRole::DeviceProcessor);
        {
            const uint16_t rawPerKindId =
                targetType ? targetType->paramIdFromString(clip.paramId) : static_cast<uint16_t>(-1);
            pb.localParamId = encodeAutomationParamId(
                clip.paramId.c_str(), targetKind, rawPerKindId);
        }
        if (pb.localParamId == 0 && clip.paramId != "gain") {
            continue;
        }
        snap.automationClips[snap.automationClipCount++] = pb;
        }

        ++trackIndex;
    }
    rebuildModEdgesLocked();
    for (int targetTrack = 0; targetTrack < trackIndex; ++targetTrack) {
        auto& snapshot = trackPlayback_[targetTrack];
        std::sort(snapshot.automationClips,
                  snapshot.automationClips + snapshot.automationClipCount,
                  [](const AutomationClipPlayback& left,
                     const AutomationClipPlayback& right) {
                      return left.targetNodeId < right.targetNodeId;
                  });
        std::sort(snapshot.modEdges,
                  snapshot.modEdges + snapshot.modEdgeCount,
                  [](const ModulationEdgePlayback& left,
                     const ModulationEdgePlayback& right) {
                      return left.targetNodeId < right.targetNodeId;
                  });
        for (int device = 0; device < snapshot.deviceCount; ++device)
            if (auto* processor = snapshot.arena.get(device))
                processor->bindCompiledParameterSpans(
                    snapshot.automationClips, snapshot.automationClipCount,
                    snapshot.modEdges, snapshot.modEdgeCount);
    }
    rebuildProcessorGraphLocked(trackIndex);
    reconcileTrackFreezeStaleLocked();
    trackPlayback_.setCount(trackIndex);

    // Keep ValueTree in sync (repos→tree) so listener can trust it for undo
    syncProjectTreeLocked();
    const bool publishImmediately = !transport_.isPlaying();
    const int builtState = trackPlayback_.publishBuild(publishImmediately);
    if (publishImmediately) {
        activeProcessorGraph_.store(
            trackPlayback_.graphIndexForState(builtState),
            std::memory_order_release);
    }
}

void ProjectEngine::rebuildProcessorGraphLocked(int trackCount) {
    std::array<GraphTrackDefinition, kMaxProcessorGraphTracks> definitions{};
    std::array<std::string, kMaxProcessorGraphTracks> midiInputIds{};
    std::array<GraphTapDefinition, kMaxProcessorGraphTaps> tapDefinitions{};
    int tapDefinitionCount = 0;
    for (int slot = 0; slot < kMaxProcessorGraphTaps; ++slot) {
        const auto& registration = graphTapRegistrations_[static_cast<size_t>(slot)];
        if (!registration.active || findDeviceLocked(registration.deviceId) == nullptr) continue;
        tapDefinitions[static_cast<size_t>(tapDefinitionCount++)] = GraphTapDefinition{
            registration.sourceOutputNodeId,
            static_cast<uint8_t>(slot),
            registration.generation,
            registration.kind,
            registration.capacityFrames,
        };
    }
    int trackIndex = 0;
    for (const auto& track : trackRepo_.tracks()) {
        if (trackIndex >= trackCount || trackIndex >= kMaxProcessorGraphTracks) break;
        auto& definition = definitions[static_cast<size_t>(trackIndex)];
        definition.trackId = track.id;
        definition.parentGroupTrack = static_cast<int8_t>(
            trackPlayback_[trackIndex].parentGroupTrackIndex);
        midiInputIds[static_cast<size_t>(trackIndex)] = "track-midi:" + track.id;
        definition.sources[definition.sourceCount++] = GraphSourceDefinition{
            midiInputIds[static_cast<size_t>(trackIndex)], GraphSignalType::Midi,
            kGraphTrackMidiInput};
        int deviceIndex = 0;
        for (const auto& device : track.devices) {
            const auto kind = deviceNodeKindFromTypeId(device.config.typeId);
            if (kind == DeviceNodeKind::MidiDelay &&
                definition.sourceCount < kMaxProcessorGraphSourcesPerTrack) {
                definition.sources[definition.sourceCount++] = GraphSourceDefinition{
                    device.id, GraphSignalType::Midi, static_cast<uint8_t>(deviceIndex)};
            } else if (!isRoutingDeviceNodeKind(kind) &&
                definition.sourceCount < kMaxProcessorGraphSourcesPerTrack) {
                auto source = GraphSourceDefinition{
                    device.id, GraphSignalType::Audio, static_cast<uint8_t>(deviceIndex)};
                if (const auto* processor = trackPlayback_[trackIndex].arena.get(deviceIndex)) {
                    source.latencySamples = processor->reportedLatencySamples();
                }
                definition.sources[definition.sourceCount++] = source;
            } else if (isRoutingDeviceNodeKind(kind) && !device.config.bypassed &&
                       definition.receiverCount < kMaxProcessorGraphReceiversPerTrack) {
                const auto& model = std::get<RoutingModel>(device.config.instance);
                GraphReceiverDefinition receiver;
                receiver.sourceId = model.sourceId;
                receiver.signalType = kind == DeviceNodeKind::AudioReceiver
                    ? GraphSignalType::Audio
                    : GraphSignalType::Midi;
                receiver.deviceIndex = static_cast<uint8_t>(deviceIndex);
                receiver.mix = kind == DeviceNodeKind::AudioReceiver ? model.routeMix : 1.0f;
                receiver.feedback = kind == DeviceNodeKind::AudioReceiver && model.feedback;
                definition.receivers[definition.receiverCount++] = receiver;
            }
            ++deviceIndex;
        }
        ++trackIndex;
    }

    // During a playback rebuild the target state has already been proven to
    // have no audio readers by beginBuild(). Bind the graph bank to that same
    // state; deriving it from the independently published graph index can
    // race a pending callback commit.
    const int inactive = PlaybackStateStorage::buildIndex >= 0
        ? PlaybackStateStorage::buildIndex
        : 1 - activeProcessorGraph_.load(std::memory_order_relaxed);
    // The inactive bank cannot be read by the callback. Prepare it here,
    // rather than bulk-clearing state from a live callback after publication.
    for (auto& delay : graphLatencyLines_[inactive]) {
        delay.left.fill(0.0f);
        delay.right.fill(0.0f);
        delay.delaySamples = 0;
        delay.writePosition = 0;
    }
    auto& feedbackBank = graphFeedbackBanks_[inactive];
    for (int ping = 0; ping < 2; ++ping) {
        for (auto& channel : feedbackBank.left[ping]) channel.fill(0.0f);
        for (auto& channel : feedbackBank.right[ping]) channel.fill(0.0f);
    }
    feedbackBank.readIndex = 0;
    processorGraphs_[inactive] = buildProcessorGraph(
        std::span<const GraphTrackDefinition>(definitions.data(), static_cast<size_t>(trackCount)),
        std::span<const GraphTapDefinition>(tapDefinitions.data(),
                                            static_cast<size_t>(tapDefinitionCount)));
    for (int edgeIndex = 0; edgeIndex < processorGraphs_[inactive].audioEdgeCount; ++edgeIndex) {
        const auto& edge = processorGraphs_[inactive].audioEdges[static_cast<size_t>(edgeIndex)];
        graphLatencyLines_[inactive][edge.bufferSlot].delaySamples = edge.latencyCompensationSamples;
    }
    lastBuiltProcessorGraph_ = inactive;
    if (PlaybackStateStorage::buildIndex >= 0)
        trackPlayback_.setSelectedGraphIndex(inactive);
    else
        activeProcessorGraph_.store(inactive, std::memory_order_release);
}

bool ProjectEngine::trackHasActiveSampleAtPlayhead(const TrackPlaybackSnapshot& track,
                                                   double playheadBeat) const noexcept {
    for (int i = 0; i < track.regionCount; ++i) {
        const SampleRegion& region = track.regions[i];
        if (playheadBeat >= region.clipStartBeat &&
            playheadBeat < region.clipStartBeat + region.clipLengthBeats) {
            return true;
        }
    }
    return false;
}

const DeviceNodePlayback* ProjectEngine::findOscillatorNode(
    const TrackPlaybackSnapshot& track) const noexcept {
    for (int i = 0; i < track.deviceCount; ++i) {
        if (track.devices[i].kind == DeviceNodeKind::Oscillator) {
            return &track.devices[i];
        }
    }
    return nullptr;
}

int ProjectEngine::selectedTrackPlaybackIndex() const noexcept {
    const int count = trackPlayback_.count();
    for (int i = 0; i < count; ++i) {
        if (trackPlayback_[i].trackId == trackRepo_.selectedTrackId()) {
            return i;
        }
    }
    return -1;
}

void ProjectEngine::syncActiveFrequencyLocked() {
    float freq = 440.0f;
    const std::string& selectedId = trackRepo_.selectedTrackId();
    if (!selectedId.empty()) {
        if (Track* track = trackRepo_.findTrack(selectedId)) {
            bool foundOscillator = false;
            for (const auto& device : track->devices) {
                if (deviceNodeKindFromTypeId(device.config.typeId) == DeviceNodeKind::Oscillator) {
                    freq = std::get<OscillatorParams>(device.config.instance).frequencyHz;
                    foundOscillator = true;
                    break;
                }
            }
            if (!foundOscillator) {
                activeFrequencyHz_.store(0.0f, std::memory_order_release);
                return;
            }
        }
    }
    activeFrequencyHz_.store(freq, std::memory_order_release);
}

void ProjectEngine::rebuildModEdgesLocked() {
    for (int t = 0; t < kMaxTracks; ++t) {
        auto& snap = trackPlayback_[t];
        snap.modEdgeCount = 0;
        for (const auto& globalEdge : modulationGraph_.modEdges()) {
            if (snap.modEdgeCount >= 16) break;
            int di = -1;
            uint16_t targetIndex = 0;
            DeviceNodeKind targetKind = DeviceNodeKind::Unknown;
            for (int i = 0; i < snap.deviceCount; ++i) {
                if (snap.devices[i].deviceId == globalEdge.deviceId) {
                    di = i;
                    targetIndex = static_cast<uint16_t>(i);
                    targetKind = snap.devices[i].kind;
                    break;
                }
                if (snap.devices[i].kind == DeviceNodeKind::DrumMachine) {
                    const auto playback =
                        std::get<DrumMachineParams>(snap.devices[i].params).playback;
                    if (playback != nullptr) {
                        for (int note = 0; note < 128 && di < 0; ++note) {
                            const auto& pad = playback->pads[note];
                            for (int child = 0; child < pad.deviceCount; ++child) {
                                if (pad.devices[child].deviceId != globalEdge.deviceId)
                                    continue;
                                di = i;
                                targetIndex = pad.devices[child].automationTargetIndex;
                                targetKind = pad.devices[child].kind;
                                break;
                            }
                        }
                    }
                }
                if (snap.devices[i].kind == DeviceNodeKind::Chain) {
                    const auto playback = std::get<ChainParams>(snap.devices[i].params).playback;
                    if (playback == nullptr) continue;
                    for (int child = 0; child < playback->deviceCount; ++child) {
                        if (playback->devices[child].deviceId != globalEdge.deviceId) continue;
                        di = i;
                        targetIndex = playback->devices[child].automationTargetIndex;
                        targetKind = playback->devices[child].kind;
                        break;
                    }
                }
                if (di >= 0) break;
            }
            if (di < 0) continue;
            const int lfoPlaybackIdx = modulationGraph_.playbackIndexForLfoId(globalEdge.lfoId);
            if (lfoPlaybackIdx < 0) continue;
            ModulationEdgePlayback& me = snap.modEdges[snap.modEdgeCount++];
            me.deviceIndex = targetIndex;
            me.targetNodeId = stableDeviceSubgraphNodeId(
                globalEdge.deviceId, DeviceSubgraphNodeRole::DeviceProcessor);
            me.lfoId = static_cast<uint16_t>(lfoPlaybackIdx);
            {
                const auto* type = deviceRegistry_.findByKind(targetKind);
                const uint16_t rawPerKindId =
                    type ? type->paramIdFromString(globalEdge.paramId)
                         : static_cast<uint16_t>(-1);
                me.localParamId = encodeAutomationParamId(
                    globalEdge.paramId.c_str(), targetKind, rawPerKindId);
            }
            if (me.localParamId == 0 && globalEdge.paramId != "gain") {
                --snap.modEdgeCount;
                continue;
            }
            me.amount = globalEdge.amount;
        }
    }
}

DeviceSlot* ProjectEngine::findDeviceLocked(const std::string& deviceId) {
    for (auto& track : trackRepo_.tracks()) {
        for (auto& device : track.devices) {
            if (device.id == deviceId) {
                return &device;
            }
            if (device.config.typeId == device_types::kDrumMachine) {
                auto& machine = std::get<DrumMachineModel>(device.config.instance);
                for (auto& pad : machine.pads) {
                    for (auto& child : pad.devices) {
                        if (child != nullptr && child->id == deviceId) return child.get();
                    }
                }
            }
            if (device.config.typeId == device_types::kChain) {
                auto& chain = std::get<ChainModel>(device.config.instance);
                for (auto& child : chain.devices) {
                    if (child != nullptr && child->id == deviceId) return child.get();
                }
            }
            for (auto& child : device.audioFxDevices) {
                if (child != nullptr && child->id == deviceId) return child.get();
            }
            for (auto& child : device.noteFxDevices) {
                if (child != nullptr && child->id == deviceId) return child.get();
            }
        }
    }
    return nullptr;
}

// ── ValueTree: rebuild repos from tree ────────────────────────

void ProjectEngine::rebuildRepoCacheFromTree() {
    syncingTree_ = true;

    // Transport from tree
    if (projectRoot_.hasProperty(state::props::bpm))
        transport_.setBpm(static_cast<int>(projectRoot_[state::props::bpm]));
    if (projectRoot_.hasProperty(state::props::playing))
        transport_.setPlaying(static_cast<bool>(projectRoot_[state::props::playing]));
    if (projectRoot_.hasProperty(state::props::loopEnabled))
        transport_.setLoopEnabled(static_cast<bool>(projectRoot_[state::props::loopEnabled]));
    if (projectRoot_.hasProperty(state::props::loopStart) && projectRoot_.hasProperty(state::props::loopEnd))
        transport_.setLoopRegion(static_cast<double>(projectRoot_[state::props::loopStart]),
                                 static_cast<double>(projectRoot_[state::props::loopEnd]));
    if (projectRoot_.hasProperty(state::props::recording))
        recordArmed_ = static_cast<bool>(projectRoot_[state::props::recording]);
    if (projectRoot_.hasProperty(state::props::masterGain))
        masterGain_.store(std::clamp(static_cast<float>(static_cast<double>(projectRoot_[state::props::masterGain])),
                                     0.0f, 1.0f), std::memory_order_release);

    // Tracks from tree → trackRepo_
    std::unordered_map<std::string, TrackFreezeData> preservedFreeze;
    for (const auto& existing : trackRepo_.tracks()) {
        if (existing.freeze.enabled) {
            preservedFreeze[existing.id] = existing.freeze;
        }
    }
    trackRepo_.tracks().clear();
    for (int ti = 0; ti < projectRoot_.getNumChildren(); ++ti) {
        auto trackTree = projectRoot_.getChild(ti);
        if (!trackTree.hasType(state::kTrackType.data())) continue;

        Track track;
        track.id = trackTree[state::props::id].toString().toStdString();
        track.name = trackTree[state::props::name].toString().toStdString();
        track.iconKey = trackTree[state::props::iconKey].toString().toStdString();
        track.isGroup = static_cast<bool>(trackTree[state::props::isGroup]);
        if (trackTree.hasProperty(state::props::muted))
            track.muted = static_cast<bool>(trackTree[state::props::muted]);
        if (trackTree.hasProperty(state::props::soloed))
            track.soloed = static_cast<bool>(trackTree[state::props::soloed]);
        track.parentGroupId = trackTree[state::props::parentGroupId].toString().toStdString();

        for (int ci = 0; ci < trackTree.getNumChildren(); ++ci) {
            auto child = trackTree.getChild(ci);

            if (child.hasType(state::kDeviceType.data())) {
                DeviceSlot device;
                device.id = child[state::props::id].toString().toStdString();
                device.config.typeId = child[state::props::typeId].toString().toStdString();
                device.config.bypassed = static_cast<bool>(child[state::props::bypassed]);
                const std::string configJson = child[state::props::configBlob].toString().toStdString();
                if (!configJson.empty())
                    device = deviceVarToSlot(configJson, deviceRegistry_);
                track.devices.push_back(std::move(device));
            } else if (child.hasType(state::kMidiClipType.data())) {
                MidiClip clip;
                clip.id = child[state::props::id].toString().toStdString();
                clip.startBeat = static_cast<double>(child[state::props::startBeat]);
                clip.lengthBeats = static_cast<double>(child[state::props::lengthBeats]);
                if (child.hasProperty(state::props::naturalLength)) {
                    clip.naturalLengthBeats =
                        static_cast<double>(child[state::props::naturalLength]);
                } else {
                    clip.naturalLengthBeats = clip.lengthBeats;
                }
                if (child.hasProperty(state::props::loopContent)) {
                    clip.loopContent = static_cast<bool>(child[state::props::loopContent]);
                }
                for (int ni = 0; ni < child.getNumChildren(); ++ni) {
                    auto noteTree = child.getChild(ni);
                    if (!noteTree.hasType(state::kMidiNoteType.data())) continue;
                    MidiNote note;
                    note.pitch = static_cast<int>(noteTree[state::props::pitch]);
                    note.startBeat = static_cast<double>(noteTree[state::props::startBeat]);
                    note.durationBeats = static_cast<double>(noteTree[state::props::duration]);
                    note.velocity = static_cast<float>(static_cast<double>(noteTree[state::props::velocity]));
                    clip.notes.push_back(std::move(note));
                }
                if (!child.hasProperty(state::props::naturalLength)) {
                    const double noteEnd = midiNotesContentLengthBeats(clip.notes, 0.0);
                    clip.naturalLengthBeats =
                        noteEnd > 0.0 ? noteEnd : clip.lengthBeats;
                }
                track.midiClips.push_back(std::move(clip));
            } else if (child.hasType(state::kSampleClipType.data())) {
                SampleClip clip;
                clip.id = child[state::props::id].toString().toStdString();
                clip.sampleId = child[state::props::sampleId].toString().toStdString();
                clip.startBeat = static_cast<double>(child[state::props::startBeat]);
                clip.lengthBeats = static_cast<double>(child[state::props::lengthBeats]);
                if (child.hasProperty(state::props::naturalLength))
                    clip.naturalLengthBeats = static_cast<double>(child[state::props::naturalLength]);
                if (child.hasProperty(state::props::loopContent)) {
                    clip.loopContent = static_cast<bool>(child[state::props::loopContent]);
                }
                if (child.hasProperty("sourceStart")) clip.sourceStart = static_cast<float>(child["sourceStart"]);
                if (child.hasProperty("sourceEnd")) clip.sourceEnd = static_cast<float>(child["sourceEnd"]);
                if (child.hasProperty("gain")) clip.gain = static_cast<float>(child["gain"]);
                if (child.hasProperty("fadeIn")) clip.fadeIn = static_cast<float>(child["fadeIn"]);
                if (child.hasProperty("fadeOut")) clip.fadeOut = static_cast<float>(child["fadeOut"]);
                if (child.hasProperty("fadeInCurve")) clip.fadeInCurve = static_cast<float>(child["fadeInCurve"]);
                if (child.hasProperty("fadeOutCurve")) clip.fadeOutCurve = static_cast<float>(child["fadeOutCurve"]);
                if (child.hasProperty("reversed")) clip.reversed = static_cast<bool>(child["reversed"]);
                if (child.hasProperty("warpRepitch")) clip.warpRepitch = static_cast<bool>(child["warpRepitch"]);
                if (child.hasProperty("sliceMarkers")) {
                    std::stringstream stream(child["sliceMarkers"].toString().toStdString());
                    std::string token;
                    while (std::getline(stream, token, ',')) {
                        try { clip.sliceMarkers.push_back(std::stof(token)); } catch (...) {}
                    }
                }
                track.sampleClips.push_back(std::move(clip));
            }
        }
        if (const auto preserved = preservedFreeze.find(track.id);
            preserved != preservedFreeze.end()) {
            track.freeze = preserved->second;
        }
        trackRepo_.tracks().push_back(std::move(track));
    }
    trackRepo_.ensureTrackIcons();
    if (projectRoot_.hasProperty(state::props::selectedTrackId))
        trackRepo_.setSelectedTrackId(projectRoot_[state::props::selectedTrackId].toString().toStdString());

    // Modulators + edges from tree → modulationGraph_
    modulationGraph_.clear();
    std::vector<ModulationGraph::ModulatorRecord> lfos;
    std::vector<ModulationEdge> edges;
    for (int mi = 0; mi < projectRoot_.getNumChildren(); ++mi) {
        auto modTree = projectRoot_.getChild(mi);

        if (modTree.hasType(state::kModEdgeType.data())) {
            ModulationEdge edge;
            edge.lfoId = static_cast<int>(modTree[state::props::lfoId]);
            edge.deviceId = modTree[state::props::deviceId].toString().toStdString();
            edge.paramId = modTree[state::props::paramId].toString().toStdString();
            edge.amount = static_cast<float>(static_cast<double>(modTree[state::props::amount]));
            edges.push_back(std::move(edge));
            continue;
        }
        if (!modTree.hasType(state::kModulatorType.data())) continue;

        ModulationGraph::ModulatorRecord rec;
        rec.id = static_cast<int>(modTree[state::props::lfoId]);
        rec.typeIndex = static_cast<int>(modTree[state::props::typeIndex]);
        if (rec.typeIndex >= 0 &&
            static_cast<size_t>(rec.typeIndex) < modulationGraph_.modulatorTypes().size()) {
            const auto& type = modulationGraph_.modulatorTypes()[static_cast<size_t>(rec.typeIndex)];
            const std::string blob = modTree[state::props::modulatorBlob].toString().toStdString();
            if (!blob.empty()) {
                auto var = juce::JSON::parse(blob);
                rec.params = type->varToParams(var);
            }
        }
        lfos.push_back(std::move(rec));
    }
    modulationGraph_.replaceRecords(lfos, edges);

    // Automation clips from tree → automationClipStore_
    automationClipStore_.clear();
    std::vector<AutomationClip> loadedClips;
    for (int ai = 0; ai < projectRoot_.getNumChildren(); ++ai) {
        auto clipTree = projectRoot_.getChild(ai);
        if (!clipTree.hasType(state::kAutomationType.data())) continue;

        AutomationClip clip;
        clip.id = clipTree[state::props::id].toString().toStdString();
        clip.homeTrackId = clipTree[state::props::homeTrackId].toString().toStdString();
        clip.startBeat = static_cast<double>(clipTree[state::props::startBeat]);
        clip.lengthBeats = static_cast<double>(clipTree[state::props::lengthBeats]);
        if (clipTree.hasProperty(state::props::naturalLength)) {
            clip.naturalLengthBeats =
                static_cast<double>(clipTree[state::props::naturalLength]);
        } else {
            clip.naturalLengthBeats = clip.lengthBeats;
        }
        if (clipTree.hasProperty(state::props::loopContent)) {
            clip.loopContent = static_cast<bool>(clipTree[state::props::loopContent]);
        }
        if (clipTree.hasProperty(state::props::deviceId))
            clip.deviceId = clipTree[state::props::deviceId].toString().toStdString();
        if (clipTree.hasProperty(state::props::paramId))
            clip.paramId = clipTree[state::props::paramId].toString().toStdString();
        for (int pi = 0; pi < clipTree.getNumChildren(); ++pi) {
            auto ptTree = clipTree.getChild(pi);
            if (!ptTree.hasType(state::kAutomationPointType.data())) continue;
            AutomationPoint pt;
            pt.beat = static_cast<double>(ptTree[state::props::beat]);
            pt.value = static_cast<float>(static_cast<double>(ptTree[state::props::value]));
            clip.points.push_back(std::move(pt));
        }
        if (!clipTree.hasProperty(state::props::naturalLength)) {
            const double pointEnd = automationPointsContentLengthBeats(clip.points, 0.0);
            clip.naturalLengthBeats = pointEnd > 0.0 ? pointEnd : clip.lengthBeats;
        }
        loadedClips.push_back(std::move(clip));
    }
    automationClipStore_.load(loadedClips);

    syncingTree_ = false;
}

// ── Sync repos -> tree (mirror repos into ValueTree) ───────────

void ProjectEngine::syncProjectTreeLocked() {
    syncingTree_ = true;
    projectRoot_.removeAllChildren(nullptr);

    projectRoot_.setProperty(state::props::bpm, transport_.bpm(), nullptr);
    projectRoot_.setProperty(state::props::selectedTrackId,
                             juce::String{trackRepo_.selectedTrackId()}, nullptr);
    projectRoot_.setProperty(state::props::playing, transport_.isPlaying(), nullptr);
    projectRoot_.setProperty(state::props::loopEnabled, transport_.loopEnabled(), nullptr);
    projectRoot_.setProperty(state::props::loopStart, transport_.loopRegionStartBeat(), nullptr);
    projectRoot_.setProperty(state::props::loopEnd, transport_.loopRegionEndBeat(), nullptr);
    projectRoot_.setProperty(state::props::masterGain,
                             static_cast<double>(masterGain_.load(std::memory_order_acquire)), nullptr);
    projectRoot_.setProperty(state::props::recording, recordArmed_, nullptr);

    for (const auto& track : trackRepo_.tracks()) {
        auto trackTree = state::createTrackTree(
            track.id, track.name, track.iconKey, track.isGroup, track.parentGroupId,
            track.muted, track.soloed);
        for (const auto& device : track.devices) {
            const std::string configJson = deviceSlotToVar(device, deviceRegistry_);
            auto devTree = state::createDeviceTree(device.id, device.config.typeId, configJson);
            devTree.setProperty(state::props::bypassed, device.config.bypassed, nullptr);
            trackTree.addChild(std::move(devTree), -1, nullptr);
        }
        for (const auto& clip : track.midiClips) {
            auto clipTree = state::createMidiClipTree(
                clip.id, clip.startBeat, clip.lengthBeats, clip.naturalLengthBeats);
            clipTree.setProperty(state::props::loopContent, clip.loopContent, nullptr);
            for (const auto& note : clip.notes) {
                juce::ValueTree noteTree{state::kMidiNoteType.data()};
                noteTree.setProperty(state::props::pitch, note.pitch, nullptr);
                noteTree.setProperty(state::props::startBeat, note.startBeat, nullptr);
                noteTree.setProperty(state::props::duration, note.durationBeats, nullptr);
                noteTree.setProperty(state::props::velocity, static_cast<double>(note.velocity), nullptr);
                clipTree.addChild(std::move(noteTree), -1, nullptr);
            }
            trackTree.addChild(std::move(clipTree), -1, nullptr);
        }
        for (const auto& clip : track.sampleClips) {
            auto clipTree = state::createSampleClipTree(
                clip.id, clip.sampleId, clip.startBeat, clip.lengthBeats, clip.naturalLengthBeats);
            clipTree.setProperty(state::props::loopContent, clip.loopContent, nullptr);
            clipTree.setProperty("sourceStart", clip.sourceStart, nullptr);
            clipTree.setProperty("sourceEnd", clip.sourceEnd, nullptr);
            clipTree.setProperty("gain", clip.gain, nullptr);
            clipTree.setProperty("fadeIn", clip.fadeIn, nullptr);
            clipTree.setProperty("fadeOut", clip.fadeOut, nullptr);
            clipTree.setProperty("fadeInCurve", clip.fadeInCurve, nullptr);
            clipTree.setProperty("fadeOutCurve", clip.fadeOutCurve, nullptr);
            clipTree.setProperty("reversed", clip.reversed, nullptr);
            clipTree.setProperty("warpRepitch", clip.warpRepitch, nullptr);
            std::string markerText;
            for (float marker : clip.sliceMarkers) {
                if (!markerText.empty()) markerText += ',';
                markerText += std::to_string(marker);
            }
            clipTree.setProperty("sliceMarkers", juce::String(markerText), nullptr);
            trackTree.addChild(std::move(clipTree), -1, nullptr);
        }
        projectRoot_.addChild(std::move(trackTree), -1, nullptr);
    }

    for (const auto& rec : modulationGraph_.lfos()) {
        std::string paramsJson = "{}";
        if (rec.typeIndex >= 0 &&
            static_cast<size_t>(rec.typeIndex) < modulationGraph_.modulatorTypes().size()) {
            const auto& type = modulationGraph_.modulatorTypes()[static_cast<size_t>(rec.typeIndex)];
            paramsJson = juce::JSON::toString(type->paramsToVar(rec.params)).toStdString();
        }
        auto modTree = state::createModulatorTree(rec.id, rec.typeIndex, paramsJson);
        projectRoot_.addChild(std::move(modTree), -1, nullptr);
    }

    for (const auto& edge : modulationGraph_.modEdges()) {
        auto edgeTree = state::createModEdgeTree(edge.lfoId, edge.deviceId, edge.paramId, edge.amount);
        projectRoot_.addChild(std::move(edgeTree), -1, nullptr);
    }

    for (const auto& clip : automationClipStore_.clips()) {
        auto clipTree = state::createAutomationClipTree(
            clip.id, clip.homeTrackId, clip.startBeat, clip.lengthBeats, clip.naturalLengthBeats);
        clipTree.setProperty(state::props::loopContent, clip.loopContent, nullptr);
        clipTree.setProperty(state::props::deviceId, juce::String{clip.deviceId}, nullptr);
        clipTree.setProperty(state::props::paramId, juce::String{clip.paramId}, nullptr);
        for (const auto& pt : clip.points) {
            juce::ValueTree ptTree{state::kAutomationPointType.data()};
            ptTree.setProperty(state::props::beat, pt.beat, nullptr);
            ptTree.setProperty(state::props::value, static_cast<double>(pt.value), nullptr);
            clipTree.addChild(std::move(ptTree), -1, nullptr);
        }
        projectRoot_.addChild(std::move(clipTree), -1, nullptr);
    }

    syncingTree_ = false;
}

// ── Undo / Redo ──────────────────────────────────────────

bool ProjectEngine::undo() {
    const juce::ScopedWriteLock lock(mutex_);
    if (!undoManager_.undo()) return false;
    // undoManager_ applies property changes → triggers listener → repos rebuilt
    return true;
}

bool ProjectEngine::redo() {
    const juce::ScopedWriteLock lock(mutex_);
    if (!undoManager_.redo()) return false;
    return true;
}

void ProjectEngine::mixTrackPreGainStereo(int trackIndex,
                                          float* trackLeft,
                                          float* trackRight,
                                          int numFrames,
                                          double sampleRate,
                                          double playheadStartBeat,
                                          const float* lfoValues,
                                          int lfoCount,
                                          IModulator* const* modulators,
                                          uint32_t retriggerGeneration) noexcept {
    if (trackLeft == nullptr || trackRight == nullptr || numFrames <= 0 || trackIndex < 0) {
        return;
    }
    const int trackCount = trackPlayback_.count();
    if (trackIndex >= trackCount) {
        return;
    }

    mixTrackPreGainStereoWithArena(trackPlayback_[trackIndex],
                                   trackPlayback_[trackIndex].arena,
                                   trackLeft, trackRight, numFrames, sampleRate,
                                   playheadStartBeat, lfoValues, lfoCount,
                                   modulators, retriggerGeneration);
}

void ProjectEngine::mixTrackPreGainStereoWithArena(
    const TrackPlaybackSnapshot& track,
    ProcessorArena& arena,
    float* trackLeft,
    float* trackRight,
    int numFrames,
    double sampleRate,
    double playheadStartBeat,
    const float* lfoValues,
    int lfoCount,
    IModulator* const* modulators,
    uint32_t retriggerGeneration,
    DeviceChainScratch* scratchOverride) noexcept {
    if (trackLeft == nullptr || trackRight == nullptr || numFrames <= 0) return;

    constexpr int kMaxFrames = 4096;
    const int framesToProcess = numFrames > kMaxFrames ? kMaxFrames : numFrames;
    const int gainIndex = track.trackGainDeviceIndex;
    if (gainIndex < 0) {
        return;
    }

    std::memset(trackLeft, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
    std::memset(trackRight, 0, static_cast<size_t>(framesToProcess) * sizeof(float));

    SampleClipPlaybackRegion regions[8];
    if (track.regionCount > 0) {
        for (int i = 0; i < track.regionCount; ++i) {
            const SampleRegion& source = track.regions[i];
            regions[i] = SampleClipPlaybackRegion{
                source.clipStartBeat,
                source.clipLengthBeats,
                source.pcm,
                source.frameCount,
                source.pcmSampleRate,
                source.loopContent,
                source.contentLengthBeats,
                source.sourceStart, source.sourceEnd, source.gain,
                source.fadeIn, source.fadeOut, source.fadeInCurve,
                source.fadeOutCurve, source.reversed,
            };
        }
        mixSampleRegionsBlock(trackLeft,
                              framesToProcess,
                              sampleRate,
                              transport_.bpm(),
                              playheadStartBeat,
                              regions,
                              track.regionCount);
        std::copy(trackLeft, trackLeft + framesToProcess, trackRight);
    }

    const double beatsPerFrame =
        (static_cast<double>(std::max(transport_.bpm(), 1)) / 60.0) / sampleRate;
    const double blockEndBeat =
        playheadStartBeat + static_cast<double>(framesToProcess) * beatsPerFrame;
    constexpr int kMaxRoutedMidiNotes = 256;
    MidiPlaybackNote routedMidi[kMaxRoutedMidiNotes];
    const int ownNoteCount = std::min(track.noteCount, kMaxRoutedMidiNotes);
    constexpr double kRouteReleaseBeats = 4.0;
    int routedCount = 0;
    for (int i = 0; i < ownNoteCount; ++i) {
        const PlaybackNote& note = track.notes[i];
        if (!blockMayContainLoopedClipNotes(playheadStartBeat,
                                            blockEndBeat,
                                            note.clipStartBeat,
                                            note.clipLengthBeats,
                                            note.contentLengthBeats,
                                            note.loopContent,
                                            note.noteStartBeat,
                                            note.noteDurationBeats,
                                            kRouteReleaseBeats)) {
            continue;
        }
        routedMidi[routedCount++] = MidiPlaybackNote{
            note.pitch,
            note.clipStartBeat,
            note.clipLengthBeats,
            note.noteStartBeat,
            note.noteDurationBeats,
            note.velocity,
            note.loopContent,
            note.contentLengthBeats,
        };
    }

    DeviceChainScratch& scratch = scratchOverride != nullptr
        ? *scratchOverride
        : gProjectScratch;
    DeviceChainOrchestrator::Context ctx(arena, scratch);
    ctx.trackLeft = trackLeft;
    ctx.trackRight = trackRight;
    ctx.numFrames = framesToProcess;
    ctx.sampleRate = sampleRate;
    ctx.bpm = transport_.bpm();
    ctx.playheadStartBeat = playheadStartBeat;
    ctx.notes = routedMidi;
    ctx.noteCount = routedCount;
    ctx.suppressInstruments = trackHasActiveSampleAtPlayhead(track, playheadStartBeat);
    ctx.deviceMeters = nullptr;
    ctx.maxDeviceMeters = 0;
    ctx.lfoValues = lfoCount > 0 ? lfoValues : nullptr;
    ctx.lfoCount = lfoCount;
    ctx.modulators = lfoCount > 0 ? modulators : nullptr;
    ctx.retriggerGeneration = retriggerGeneration;
    ctx.modEdges = track.modEdgeCount > 0 ? track.modEdges : nullptr;
    ctx.modEdgeCount = track.modEdgeCount;
    ctx.automationClips = track.automationClipCount > 0 ? track.automationClips : nullptr;
    ctx.automationClipCount = track.automationClipCount;
    ctx.wavetableBank = wavetableBank_;
    if (track.deviceExecutionOrder.valid()) {
        ctx.compiledDeviceOrder = track.deviceExecutionOrder.deviceIndices.data();
        ctx.compiledDeviceOrderCount = track.deviceExecutionOrder.count;
    }
    if (gainIndex > 0) {
        DeviceChainOrchestrator::processChain(ctx, 0, gainIndex);
    }
}

// ── ValueTree::Listener (tree is source of truth) ─────────────────

void ProjectEngine::valueTreePropertyChanged(juce::ValueTree& tree,
                                              const juce::Identifier& property) {
    if (syncingTree_) return;
    rebuildRepoCacheFromTree();
    rebuildTrackPlaybackLocked();
}

void ProjectEngine::valueTreeChildAdded(juce::ValueTree& parent,
                                         juce::ValueTree& child) {
    if (syncingTree_) return;
    rebuildRepoCacheFromTree();
    rebuildTrackPlaybackLocked();
}

void ProjectEngine::valueTreeChildRemoved(juce::ValueTree& parent,
                                           juce::ValueTree& child,
                                           int oldIndex) {
    if (syncingTree_) return;
    rebuildRepoCacheFromTree();
    rebuildTrackPlaybackLocked();
}

} // namespace audioapp
