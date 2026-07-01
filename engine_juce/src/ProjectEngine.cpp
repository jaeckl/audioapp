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
#include "audioapp/effects/PhaserParams.hpp"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstring>
#include <cstdlib>
#include <vector>

namespace audioapp {

namespace {
thread_local DeviceChainScratch gProjectScratch;
} // namespace

void ProjectEngine::createProject() {
    const juce::ScopedWriteLock lock(mutex_);
    trackRepo_.clear();
    clipRepo_.clear();
    automationClipStore_.clear();
    projectName_ = "Untitled";
    transport_.reset();
    modulationGraph_.clear();
    activeFrequencyHz_.store(440.0f, std::memory_order_release);
    masterGain_.store(1.0f, std::memory_order_release);
    trackPlaybackCount_.store(0, std::memory_order_release);

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
    const int graphIndex = activeProcessorGraph_.load(std::memory_order_acquire);
    if (!processorGraphs_[graphIndex].valid()) {
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
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::setTrackSoloed(const std::string& trackId, bool soloed) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!trackRepo_.setTrackSoloed(trackId, soloed)) {
        return false;
    }
    syncProjectTreeLocked();
    rebuildTrackPlaybackLocked();
    return true;
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
    rebuildTrackPlaybackLocked();
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

    const DeviceParameterResult result =
        deviceRegistry_.setParameter(*device, parameterId, value);
    if (!result.handled) {
        return false;
    }
    if (result.syncActiveFrequency) {
        syncActiveFrequencyLocked();
    }

    // Fast path: update live playback node and processor params in-place,
    // preserving all runtime state (oscillator phases, filter biquad states,
    // delay buffers, voice runtime, etc.). Falls back to full rebuild if
    // the device hasn't been built into playback yet.
    PlaybackBuildContext context{sampleBank_};
    context.wavetableBank = wavetableBank_;
    for (int t = 0; t < kMaxTracks; ++t) {
        auto& snap = trackPlayback_[t];
        for (int d = 0; d < snap.deviceCount; ++d) {
            if (snap.devices[d].deviceId != deviceId) continue;
            deviceRegistry_.buildPlaybackNode(*device, context, snap.devices[d]);
            snap.devices[d].bypassed = device->config.bypassed;

            // Common strip controls live in the output panel rather than the
            // device-specific parameter variant, so buildPlaybackNode cannot
            // refresh them for the fast path.
            std::visit([&](const auto& panel) {
                using T = std::decay_t<decltype(panel)>;
                if constexpr (std::is_same_v<T, MonoOutputPanel>) {
                    snap.devices[d].gain = panel.gain;
                    snap.devices[d].pan = 0.5f;
                } else if constexpr (std::is_same_v<T, StereoOutputPanel>) {
                    snap.devices[d].gain = panel.gain;
                    snap.devices[d].pan = panel.pan;
                    snap.devices[d].outputMix = panel.outputMix;
                    snap.devices[d].outputWidth = panel.outputWidth;
                }
            }, device->config.outputPanel);

            auto* proc = snap.arena.get(d);
            if (proc != nullptr) {
                proc->initParams(snap.devices[d].params);
                proc->bypassed = snap.devices[d].bypassed;
                proc->gain = snap.devices[d].gain;
                proc->pan = snap.devices[d].pan;
                proc->outputMix = snap.devices[d].outputMix;
                proc->outputWidth = snap.devices[d].outputWidth;
            }
            if (routingDevice) {
                rebuildProcessorGraphLocked(trackPlaybackCount_.load(std::memory_order_acquire));
                const int graphIndex = activeProcessorGraph_.load(std::memory_order_acquire);
                if (!processorGraphs_[graphIndex].valid()) {
                    *device = previousDevice;
                    rebuildTrackPlaybackLocked();
                    return false;
                }
            }
            return true;
        }
    }

    // Fallback: device not in live playback arrays yet (e.g. during initial load)
    rebuildTrackPlaybackLocked();
    if (routingDevice) {
        const int graphIndex = activeProcessorGraph_.load(std::memory_order_acquire);
        if (!processorGraphs_[graphIndex].valid()) {
            *device = previousDevice;
            rebuildTrackPlaybackLocked();
            return false;
        }
    }
    return true;
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
    if (!deviceRegistry_.setStringParameter(*device, parameterId, value, context)) {
        return false;
    }

    // Fast path: update live playback node and processor in-place,
    // avoiding full track rebuild (which causes audible glitches).
    // String parameters (e.g. wavetableId, sampleId) just set runtime
    // state resolved at process time — no structural change needed.
    for (int t = 0; t < kMaxTracks; ++t) {
        auto& snap = trackPlayback_[t];
        for (int d = 0; d < snap.deviceCount; ++d) {
            if (snap.devices[d].deviceId != deviceId) continue;
            deviceRegistry_.buildPlaybackNode(*device, context, snap.devices[d]);
            auto* proc = snap.arena.get(d);
            if (proc != nullptr) {
                proc->initParams(snap.devices[d].params);
            }
            if (routingDevice) {
                rebuildProcessorGraphLocked(trackPlaybackCount_.load(std::memory_order_acquire));
                const int graphIndex = activeProcessorGraph_.load(std::memory_order_acquire);
                if (!processorGraphs_[graphIndex].valid()) {
                    *device = previousDevice;
                    rebuildTrackPlaybackLocked();
                    return false;
                }
            }
            return true;
        }
    }

    // Fallback: device not in live playback arrays yet
    rebuildTrackPlaybackLocked();
    if (routingDevice) {
        const int graphIndex = activeProcessorGraph_.load(std::memory_order_acquire);
        if (!processorGraphs_[graphIndex].valid()) {
            *device = previousDevice;
            rebuildTrackPlaybackLocked();
            return false;
        }
    }
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
    if (track == nullptr || track->isGroup) {
        return {};
    }
    const std::string clipId = clipRepo_.createMidiClip(trackId, startBeat, lengthBeats);
    if (clipId.empty()) {
        return {};
    }
    rebuildTrackPlaybackLocked();
    return clipId;
}

bool ProjectEngine::setMidiClipNotes(const std::string& clipId,
                                     const std::vector<MidiNoteState>& notes) {
    const juce::ScopedWriteLock lock(mutex_);
    if (!clipRepo_.setMidiClipNotes(clipId, notes)) {
        return false;
    }
    rebuildTrackPlaybackLocked();
    return true;
}

std::string ProjectEngine::createSampleClip(const std::string& trackId,
                                            const std::string& sampleId,
                                            double startBeat,
                                            double lengthBeats) {
    const juce::ScopedWriteLock lock(mutex_);
    const auto* track = trackRepo_.findTrack(trackId);
    if (track == nullptr || track->isGroup) {
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

std::string ProjectEngine::createAutomationClip(const std::string& homeTrackId,
                                                double startBeat,
                                                double lengthBeats) {
    const juce::ScopedWriteLock lock(mutex_);
    if (homeTrackId.empty() || trackRepo_.findTrack(homeTrackId) == nullptr) {
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
        if (target == nullptr || target->isGroup) {
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
            cs.notes.reserve(clip.notes.size());
            for (const auto& note : clip.notes) {
                cs.notes.push_back(MidiNoteState{
                    note.pitch,
                    note.startBeat,
                    note.durationBeats,
                    note.velocity,
                });
            }
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
            if (sampleBank_ != nullptr) {
                if (const auto* sample = sampleBank_->findSample(clip.sampleId)) {
                    cs.sampleName = sample->name;
                    cs.waveformPeaks = sample->peaks;
                }
            }
            ts.sampleClips.push_back(std::move(cs));
        }
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
    constexpr int kMaxFrames = 4096;
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
    // No shared_lock needed: trackPlaybackCount_ release/acquire ordering
    // provides happens-before for all trackPlayback_[] writes by the
    // control thread in rebuildTrackPlaybackLocked. TransportController
    // and ModulationGraph use their own atomics/double-buffering.
    mixAtPlayheadBeatStereo(leftOut, rightOut, numFrames, sampleRate, playheadStartBeat);
}

void ProjectEngine::mixAtPlayheadBeatStereo(float* masterLeft,
                                            float* masterRight,
                                            int numFrames,
                                            double sampleRate,
                                            double playheadStartBeat) noexcept {
    if (masterLeft == nullptr || masterRight == nullptr || numFrames <= 0) {
        return;
    }

    const int trackCount = trackPlaybackCount_.load(std::memory_order_acquire);
    if (trackCount <= 0) {
        return;
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
    const int graphIndex = activeProcessorGraph_.load(std::memory_order_acquire);
    const ProcessorGraphSnapshot graph = processorGraphs_[graphIndex];
    const bool useGraph = graph.trackCount == trackCount;
    for (int edgeIndex = 0; edgeIndex < graph.audioEdgeCount; ++edgeIndex) {
        std::memset(graphAudioLeft[edgeIndex], 0,
                    static_cast<size_t>(framesToProcess) * sizeof(float));
        std::memset(graphAudioRight[edgeIndex], 0,
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
    if (lfoCount > 0) {
        modulatorPtrs.resize(static_cast<size_t>(lfoCount));
        for (int i = 0; i < lfoCount; ++i) {
            modulatorPtrs[static_cast<size_t>(i)] = modulationGraph_.modulator(i);
        }
    }
    const double beatsPerFrame =
        (static_cast<double>(std::max(transport_.bpm(), 1)) / 60.0) / sampleRate;
    thread_local std::vector<float> lfoValues;
    if (lfoCount > 0) {
        const size_t needed = static_cast<size_t>(lfoCount) * static_cast<size_t>(framesToProcess);
        if (lfoValues.capacity() < needed) {
            lfoValues.reserve(needed + 4096);
        }
        lfoValues.resize(needed, 0.0f);
        const double playheadSeconds = playheadStartBeat * 60.0 / static_cast<double>(std::max(transport_.bpm(), 1));
        const double samplePeriod = 1.0 / std::max(sampleRate, 1.0);
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
            return (beat - latestOnsetBeat) * 60.0
                / static_cast<double>(std::max(transport_.bpm(), 1));
        };
        for (int i = 0; i < lfoCount; ++i) {
            auto* mod = modulationGraph_.modulator(i);
            if (mod == nullptr) continue;
            for (int frame = 0; frame < framesToProcess; ++frame) {
                const double secondsWithinBlock = static_cast<double>(frame) * samplePeriod;
                const double frameBeat =
                    playheadStartBeat +
                    secondsWithinBlock *
                        (static_cast<double>(std::max(transport_.bpm(), 1)) / 60.0);
                const double noteElapsed = noteElapsedSecondsAtBeat(frameBeat);
                lfoValues[i * framesToProcess + frame] =
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
                };
            }
            mixSampleRegionsBlock(trackLeft[trackIndex], framesToProcess, sampleRate,
                                  transport_.bpm(), playheadStartBeat, regions,
                                  track.regionCount);
            std::copy(trackLeft[trackIndex], trackLeft[trackIndex] + framesToProcess,
                      trackRight[trackIndex]);
        }
        const int ownNoteCount = std::min(track.noteCount, kMaxRoutedMidiNotes);
        for (int i = 0; i < ownNoteCount; ++i) {
            const PlaybackNote& note = track.notes[i];
            routedMidi[trackIndex][i] = MidiPlaybackNote{
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
        routedMidiCount[trackIndex] = ownNoteCount;
    }

    for (int orderIndex = 0; orderIndex < trackCount; ++orderIndex) {
        const int trackIndex = useGraph
            ? static_cast<int>(graph.executionOrder[static_cast<size_t>(orderIndex)])
            : orderIndex;
        const TrackPlaybackSnapshot& track = trackPlayback_[trackIndex];

        const bool suppressInstruments = trackHasActiveSampleAtPlayhead(track, playheadStartBeat);
        const int noteCount = routedMidiCount[trackIndex];

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
        ctx.maxDeviceMeters = deviceMeterSlotCount_;
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
        ctx.graphMidiNotes = &routedMidi[0][0];
        ctx.graphMidiCounts = routedMidiCount;
        ctx.graphMidiStride = kMaxRoutedMidiNotes;
        ctx.graphMidiEdgeNotes = &graphMidiEdges[0][0];
        ctx.graphMidiEdgeCounts = graphMidiEdgeCounts;
        ctx.graphMidiEdgeStride = kMaxRoutedMidiNotes;

        DeviceChainOrchestrator::processChain(ctx);

        if (!trackAudibleForOutput(trackIndex)) {
            std::memset(trackLeft[trackIndex], 0,
                        static_cast<size_t>(framesToProcess) * sizeof(float));
            std::memset(trackRight[trackIndex], 0,
                        static_cast<size_t>(framesToProcess) * sizeof(float));
        }

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
            for (const auto& note : clip.notes) {
                cs.notes.push_back(MidiNoteState{
                    note.pitch,
                    note.startBeat,
                    note.durationBeats,
                    note.velocity,
                });
            }
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
            if (sampleBank_ != nullptr) {
                if (const auto* sample = sampleBank_->findSample(clip.sampleId)) {
                    cs.sampleName = sample->name;
                    cs.waveformPeaks = sample->peaks;
                }
            }
            ts.sampleClips.push_back(std::move(cs));
        }
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
    projectName_ = data.name.empty() ? "Untitled" : data.name;
    if (data.bpm > 0) {
        transport_.setBpm(data.bpm);
    } else {
        transport_.setBpm(120);
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
            for (const auto& noteState : clipState.notes) {
                MidiNote note;
                note.pitch = noteState.pitch;
                note.startBeat = noteState.startBeat;
                note.durationBeats = noteState.durationBeats;
                note.velocity = noteState.velocity;
                clip.notes.push_back(note);
            }
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
            track.sampleClips.push_back(std::move(clip));
        }
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

bool ProjectEngine::removeModulation(int lfoId, const std::string& paramId) {
    const juce::ScopedWriteLock lock(mutex_);
    const bool result = modulationGraph_.removeModulation(lfoId, paramId);
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
        if (!first) json += ",";
        first = false;
        const float gr = deviceMeters_[i].gainReductionDb.load(std::memory_order_relaxed);
        const float in = deviceMeters_[i].inputPeak.load(std::memory_order_relaxed);
        json += "\"";
        json += deviceMeterIds_[i];
        json += R"(":{"gr":)";
        // Format gain reduction as 1 decimal, input level as 3 decimal
        char buf[64];
        snprintf(buf, sizeof(buf), "%.1f", static_cast<double>(gr));
        json += buf;
        json += R"(,"in":)";
        snprintf(buf, sizeof(buf), "%.3f", static_cast<double>(in));
        json += buf;
        json += "}";
    }
    json += "}}";
    return json;
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
    if (syncingTree_) return;
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

        // Build processor chain from device snapshot into the arena
        snap.arena.reset();

        for (const auto& device : sourceTrack.devices) {
            if (snap.deviceCount >= kMaxDevicesPerTrack) {
                break;
            }

            DeviceNodePlayback& node = snap.devices[snap.deviceCount];
            node.deviceId = device.id;
            node.bypassed = device.config.bypassed;
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
            }, device.config.outputPanel);
            node.meterSlot = -1;

            PlaybackBuildContext context{sampleBank_};
            context.wavetableBank = wavetableBank_;
            deviceRegistry_.buildPlaybackNode(device, context, node);
            if (isDynamicsDeviceNodeKind(node.kind) && deviceMeterSlotCount_ < kMaxDeviceMeters) {
                node.meterSlot = static_cast<int8_t>(deviceMeterSlotCount_);
                deviceMeterIds_[deviceMeterSlotCount_] = device.id;
                ++deviceMeterSlotCount_;
            }

            // Create processor via IDeviceType virtual dispatch
            const IDeviceType* type = deviceRegistry_.findForSlot(device);
            if (type != nullptr) {
                auto* proc = type->createProcessor(snap.arena);
                if (proc != nullptr) {
                    proc->bypassed = node.bypassed;
                    proc->meterSlot = node.meterSlot;
                    proc->gain = node.gain;
                    proc->pan = node.pan;
                    proc->outputMix = node.outputMix;
                    proc->outputWidth = node.outputWidth;
                    proc->initParams(node.params);
                }
            }

            ++snap.deviceCount;
        }

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
                const auto* sample = sampleBank_->findSample(clip.sampleId);
                if (sample == nullptr || sample->pcm.empty()) {
                    continue;
                }
                snap.regions[snap.regionCount++] = SampleRegion{
                    clip.startBeat,
                    clip.lengthBeats,
                    sample->pcm.data(),
                    static_cast<int>(sample->pcm.size()),
                    sample->sampleRate,
                    clip.loopContent,
                    clip.naturalLengthBeats,
                };
            }
        }

        rebuildModEdgesLocked();

        // Resolve per-track automation clips
        snap.automationClipCount = 0;
        for (const auto& clip : automationClipStore_.clips()) {
            if (snap.automationClipCount >= 16) break;
            if (clip.deviceId.empty()) continue;
            int di = -1;
        for (int i = 0; i < snap.deviceCount; ++i) {
            if (snap.devices[i].deviceId == clip.deviceId) {
                di = i;
                break;
            }
        }
        if (di < 0) continue; // target device lives on another track
        AutomationClipPlayback pb{};
        if (!automationClipPlaybackFromClip(clip, pb)) continue;
        pb.deviceIndex = static_cast<uint16_t>(di);
        {
            const auto* type = deviceRegistry_.findByKind(snap.devices[di].kind);
            const uint16_t rawPerKindId =
                type ? type->paramIdFromString(clip.paramId) : static_cast<uint16_t>(-1);
            pb.localParamId = encodeAutomationParamId(
                clip.paramId.c_str(), snap.devices[di].kind, rawPerKindId);
        }
        if (pb.localParamId == 0 && clip.paramId != "gain") {
            continue;
        }
        snap.automationClips[snap.automationClipCount++] = pb;
        }

        ++trackIndex;
    }
    rebuildProcessorGraphLocked(trackIndex);
    trackPlaybackCount_.store(trackIndex, std::memory_order_release);

    // Keep ValueTree in sync (repos→tree) so listener can trust it for undo
    syncProjectTreeLocked();
}

void ProjectEngine::rebuildProcessorGraphLocked(int trackCount) {
    std::array<GraphTrackDefinition, kMaxProcessorGraphTracks> definitions{};
    std::array<std::string, kMaxProcessorGraphTracks> midiInputIds{};
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
                definition.sources[definition.sourceCount++] = GraphSourceDefinition{
                    device.id, GraphSignalType::Audio, static_cast<uint8_t>(deviceIndex)};
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
                definition.receivers[definition.receiverCount++] = receiver;
            }
            ++deviceIndex;
        }
        ++trackIndex;
    }

    const int inactive = 1 - activeProcessorGraph_.load(std::memory_order_relaxed);
    processorGraphs_[inactive] = buildProcessorGraph(
        std::span<const GraphTrackDefinition>(definitions.data(), static_cast<size_t>(trackCount)));
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
    const int count = trackPlaybackCount_.load(std::memory_order_acquire);
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
            for (int i = 0; i < snap.deviceCount; ++i) {
                if (snap.devices[i].deviceId == globalEdge.deviceId) {
                    di = i;
                    break;
                }
            }
            if (di < 0) continue;
            const int lfoPlaybackIdx = modulationGraph_.playbackIndexForLfoId(globalEdge.lfoId);
            if (lfoPlaybackIdx < 0) continue;
            ModulationEdgePlayback& me = snap.modEdges[snap.modEdgeCount++];
            me.deviceIndex = static_cast<uint16_t>(di);
            me.lfoId = static_cast<uint16_t>(lfoPlaybackIdx);
            {
                const auto* type = deviceRegistry_.findByKind(snap.devices[di].kind);
                const uint16_t rawPerKindId =
                    type ? type->paramIdFromString(globalEdge.paramId)
                         : static_cast<uint16_t>(-1);
                me.localParamId = encodeAutomationParamId(
                    globalEdge.paramId.c_str(), snap.devices[di].kind, rawPerKindId);
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
                track.sampleClips.push_back(std::move(clip));
            }
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
