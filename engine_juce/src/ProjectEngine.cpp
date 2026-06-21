#include "audioapp/ProjectEngine.hpp"
#include "audioapp/ProjectJson.hpp"
#include "audioapp/TimelineClipTypes.hpp"
#include "audioapp/MidiUtils.hpp"
#include "audioapp/MasterMix.hpp"
#include "audioapp/SamplePlayback.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/OscillatorInstance.hpp"
#include "audioapp/devices/instances/SubtractiveSynthInstance.hpp"
#include "audioapp/devices/instances/TrackGainInstance.hpp"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstring>
#include <cstdlib>
#include <shared_mutex>
#include <vector>

namespace audioapp {

void ProjectEngine::createProject() {
    std::lock_guard<std::shared_mutex> lock(mutex_);
    trackRepo_.clear();
    clipRepo_.clear();
    automationClipStore_.clear();
    projectName_ = "Untitled";
    transport_.reset();
    modulationGraph_.clear();
    activeFrequencyHz_.store(440.0f, std::memory_order_release);
    masterGain_.store(1.0f, std::memory_order_release);
    trackPlaybackCount_.store(0, std::memory_order_release);
}

std::string ProjectEngine::addTrack(const std::string& name) {
    std::lock_guard<std::shared_mutex> lock(mutex_);
    const std::string trackId = trackRepo_.addTrack(name, deviceRegistry_);
    syncActiveFrequencyLocked();
    rebuildTrackPlaybackLocked();
    return trackId;
}

bool ProjectEngine::selectTrack(const std::string& trackId) {
    std::lock_guard<std::shared_mutex> lock(mutex_);
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
    std::lock_guard<std::shared_mutex> lock(mutex_);
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
        if (std::holds_alternative<TrackGainInstance>(track->devices[i].instance)) {
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
    if (std::holds_alternative<TrackGainInstance>(slot.instance)) {
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
    std::lock_guard<std::shared_mutex> lock(mutex_);
    DeviceSlot* device = findDeviceLocked(deviceId);
    if (device == nullptr) {
        return false;
    }

    const DeviceParameterResult result =
        deviceRegistry_.setParameter(*device, parameterId, value);
    if (!result.handled) {
        return false;
    }
    if (result.syncActiveFrequency) {
        syncActiveFrequencyLocked();
    }
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::setDeviceStringParameter(const std::string& deviceId,
                                             const std::string& parameterId,
                                             const std::string& value) {
    std::lock_guard<std::shared_mutex> lock(mutex_);
    DeviceSlot* device = findDeviceLocked(deviceId);
    if (device == nullptr) {
        return false;
    }

    const PlaybackBuildContext context{sampleBank_};
    if (!deviceRegistry_.setStringParameter(*device, parameterId, value, context)) {
        return false;
    }
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::setMasterGain(float gain) {
    masterGain_.store(std::clamp(gain, 0.0f, 1.0f), std::memory_order_release);
    return true;
}

std::string ProjectEngine::createMidiClip(const std::string& trackId,
                                          double startBeat,
                                          double lengthBeats) {
    std::lock_guard<std::shared_mutex> lock(mutex_);
    const std::string clipId = clipRepo_.createMidiClip(trackId, startBeat, lengthBeats);
    if (clipId.empty()) {
        return {};
    }
    rebuildTrackPlaybackLocked();
    return clipId;
}

bool ProjectEngine::setMidiClipNotes(const std::string& clipId,
                                     const std::vector<MidiNoteState>& notes) {
    std::lock_guard<std::shared_mutex> lock(mutex_);
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
    std::lock_guard<std::shared_mutex> lock(mutex_);
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
    std::lock_guard<std::shared_mutex> lock(mutex_);
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
    std::lock_guard<std::shared_mutex> lock(mutex_);
    if (findDeviceLocked(deviceId) == nullptr) {
        return false;
    }
    if (!automationClipStore_.assignTarget(clipId, deviceId, paramId)) {
        return false;
    }
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::setAutomationPoints(const std::string& clipId,
                                        const std::vector<AutomationPointState>& points) {
    std::lock_guard<std::shared_mutex> lock(mutex_);
    if (!automationClipStore_.setPoints(clipId, points)) {
        return false;
    }
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::moveClip(const std::string& clipId,
                             const std::string& targetTrackId,
                             double startBeat) {
    std::lock_guard<std::shared_mutex> lock(mutex_);
    if (clipRepo_.findMidiClip(clipId) != nullptr ||
        clipRepo_.findSampleClip(clipId) != nullptr) {
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

bool ProjectEngine::setClipLength(const std::string& clipId, double lengthBeats) {
    std::lock_guard<std::shared_mutex> lock(mutex_);
    if (clipRepo_.findMidiClip(clipId) != nullptr ||
        clipRepo_.findSampleClip(clipId) != nullptr) {
        if (!clipRepo_.setClipLength(clipId, lengthBeats)) {
            return false;
        }
        rebuildTrackPlaybackLocked();
        return true;
    }
    if (!automationClipStore_.setLength(clipId, lengthBeats)) {
        return false;
    }
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::setBpm(int bpm) {
    if (!transport_.setBpm(bpm)) {
        return false;
    }
    std::lock_guard<std::shared_mutex> lock(mutex_);
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::deleteTrack(const std::string& trackId) {
    std::lock_guard<std::shared_mutex> lock(mutex_);
    if (!trackRepo_.deleteTrack(trackId)) {
        return false;
    }
    syncActiveFrequencyLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::deleteClip(const std::string& clipId) {
    std::lock_guard<std::shared_mutex> lock(mutex_);
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
    std::lock_guard<std::shared_mutex> lock(mutex_);
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
    std::lock_guard<std::shared_mutex> lock(mutex_);
    transport_.setLoopEnabled(enabled);
    return true;
}

bool ProjectEngine::setLoopLengthBeats(double lengthBeats) {
    std::lock_guard<std::shared_mutex> lock(mutex_);
    return transport_.setLoopLengthBeats(lengthBeats);
}

bool ProjectEngine::setLoopRegion(double startBeat, double endBeat) {
    std::lock_guard<std::shared_mutex> lock(mutex_);
    return transport_.setLoopRegion(startBeat, endBeat);
}

std::vector<float> ProjectEngine::renderOffline(double lengthBeats, double sampleRate) {
    if (lengthBeats <= 0.0 || sampleRate <= 0.0) {
        return {};
    }
    std::shared_lock<std::shared_mutex> lock(mutex_);
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
    std::shared_lock<std::shared_mutex> lock(mutex_);
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
        ts.devices.reserve(track.devices.size());
        for (const auto& device : track.devices) {
            ts.devices.push_back(deviceRegistry_.toSnapshotState(device));
        }
        ts.midiClips.reserve(track.midiClips.size());
        for (const auto& clip : track.midiClips) {
            MidiClipState cs;
            cs.id = clip.id;
            cs.startBeat = clip.startBeat;
            cs.lengthBeats = clip.lengthBeats;
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
    std::shared_lock<std::shared_mutex> lock(mutex_);
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
    thread_local float trackLeft[kMaxFrames];
    thread_local float trackRight[kMaxFrames];
    const int framesToProcess = numFrames > kMaxFrames ? kMaxFrames : numFrames;

        // Compute per-frame LFO values for gain/pan modulation.
    // DSP-specific params still use frame-0 (block-rate).
    const int lfoCount = modulationGraph_.lfoPlaybackCount();
    // Per-frame LFO buffer: lfoValues[lfoId * framesToProcess + frame]
    // thread_local vector avoids large stack allocation and is allocation-free
    // after the first warm-up call on the audio thread.
    thread_local std::vector<float> lfoValues;
    if (lfoCount > 0) {
        const size_t needed = static_cast<size_t>(lfoCount) * static_cast<size_t>(framesToProcess);
        if (lfoValues.capacity() < needed) {
            lfoValues.reserve(needed + 4096);
        }
        lfoValues.resize(needed, 0.0f);
        const double playheadSeconds = playheadStartBeat * 60.0 / static_cast<double>(std::max(transport_.bpm(), 1));
        const double samplePeriod = 1.0 / std::max(sampleRate, 1.0);
        const uint32_t retriggerGeneration = modulationGraph_.noteRetriggerGeneration();
        for (int i = 0; i < lfoCount; ++i) {
            auto& entry = modulationGraph_.lfoPlaybackEntryMutable(i);
            const auto& lfo = entry.state;
            for (int frame = 0; frame < framesToProcess; ++frame) {
                const double frameSeconds = playheadSeconds + static_cast<double>(frame) * samplePeriod;
                const double frameBeat =
                    playheadStartBeat +
                    static_cast<double>(frame) * samplePeriod *
                        (static_cast<double>(std::max(transport_.bpm(), 1)) / 60.0);
                float value = 0.0f;
                if (lfo.retrigger == static_cast<int>(ModulatorRetrigger::OnNote)) {
                    value = modulatorEvaluateOnNote(lfo,
                                                    frameSeconds,
                                                    retriggerGeneration,
                                                    entry.envelope.lastRetriggerGeneration,
                                                    entry.envelope.level,
                                                    entry.envelope.stage,
                                                    entry.envelope.segStartSeconds);
                } else {
                    value = modulatorEvaluateSynced(lfo,
                                                    frameBeat,
                                                    transport_.bpm(),
                                                    frameSeconds - playheadSeconds);
                }
                lfoValues[i * framesToProcess + frame] = value;
            }
        }
    }

    SampleClipPlaybackRegion regions[8];

    for (int trackIndex = 0; trackIndex < trackCount; ++trackIndex) {
        const TrackPlaybackSnapshot& track = trackPlayback_[trackIndex];
        std::memset(trackLeft, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
        std::memset(trackRight, 0, static_cast<size_t>(framesToProcess) * sizeof(float));

        if (track.regionCount > 0) {
            for (int i = 0; i < track.regionCount; ++i) {
                const SampleRegion& source = track.regions[i];
                regions[i] = SampleClipPlaybackRegion{
                    source.clipStartBeat,
                    source.clipLengthBeats,
                    source.pcm,
                    source.frameCount,
                    source.pcmSampleRate,
                };
            }
            mixSampleRegionsBlock(trackLeft,
                                  framesToProcess,
                                  sampleRate,
                                  transport_.bpm(),
                                  playheadStartBeat,
                                  regions,
                                  track.regionCount);
            for (int frame = 0; frame < framesToProcess; ++frame) {
                trackRight[frame] = trackLeft[frame];
            }
        }

        const bool suppressInstruments = trackHasActiveSampleAtPlayhead(track, playheadStartBeat);

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
            };
        }

        float oscillatorPhase = track.oscillatorPhase;
        processDeviceChain(trackLeft,
                           trackRight,
                           framesToProcess,
                           sampleRate,
                           transport_.bpm(),
                           playheadStartBeat,
                           midiNotes,
                           noteCount,
                           track.devices,
                           track.deviceCount,
                           oscillatorPhase,
                           suppressInstruments,
                           trackPlayback_[trackIndex].samplerFilterStates,
                           trackPlayback_[trackIndex].subtractiveRuntimes,
                           trackPlayback_[trackIndex].kickRuntimes,
                           trackPlayback_[trackIndex].snareRuntimes,
                           trackPlayback_[trackIndex].clapRuntimes,
                           trackPlayback_[trackIndex].cymbalRuntimes,
                           trackPlayback_[trackIndex].crashRuntimes,
                           trackPlayback_[trackIndex].dynamicsRuntimes,
                           deviceMeters_,
                           deviceMeterSlotCount_,
                           lfoCount > 0 ? lfoValues.data() : nullptr,
                           lfoCount,
                           track.modEdgeCount > 0 ? track.modEdges : nullptr,
                           track.modEdgeCount,
                           track.automationClipCount > 0 ? track.automationClips : nullptr,
                           track.automationClipCount);
        trackPlayback_[trackIndex].oscillatorPhase = oscillatorPhase;

        for (int frame = 0; frame < framesToProcess; ++frame) {
            masterLeft[frame] += trackLeft[frame];
            masterRight[frame] += trackRight[frame];
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
        std::lock_guard<std::shared_mutex> lock(mutex_);
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
    std::lock_guard<std::shared_mutex> lock(mutex_);
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
        for (const auto& device : track.devices) {
            ts.devices.push_back(deviceRegistry_.toSnapshotState(device));
        }
        for (const auto& clip : track.midiClips) {
            MidiClipState cs;
            cs.id = clip.id;
            cs.startBeat = clip.startBeat;
            cs.lengthBeats = clip.lengthBeats;
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

    std::lock_guard<std::shared_mutex> lock(mutex_);
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
        for (const auto& deviceState : trackState.devices) {
            track.devices.push_back(deviceRegistry_.slotFromSnapshot(deviceState));
        }
        for (const auto& clipState : trackState.midiClips) {
            MidiClip clip;
            clip.id = clipState.id;
            clip.startBeat = clipState.startBeat;
            clip.lengthBeats = clipState.lengthBeats;
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

    modulationGraph_.load(data.lfos, data.modEdges);
    modulationGraph_.recomputeIdCounters();
    // Rebuild the playback array BEFORE rebuilding the track snapshot.
    // The snapshot resolver maps each modulation edge's LFO domain id to its
    // compact playback array index; if rebuildPlayback() hasn't run yet, every
    // edge is dropped silently and modulation never reaches the audio thread
    // after a project reload.
    modulationGraph_.rebuildPlayback();

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
    std::lock_guard<std::shared_mutex> lock(mutex_);
    return modulationGraph_.createLfo(modulatorType);
}

bool ProjectEngine::removeLfo(int lfoId) {
    std::lock_guard<std::shared_mutex> lock(mutex_);
    const bool result = modulationGraph_.removeLfo(lfoId);
    if (result) {
        rebuildTrackPlaybackLocked();
    }
    return result;
}

bool ProjectEngine::updateLfoParam(int lfoId, const std::string& param, float value) {
    std::lock_guard<std::shared_mutex> lock(mutex_);
    const bool result = modulationGraph_.updateLfoParam(lfoId, param, value);
    if (result) {
        rebuildTrackPlaybackLocked();
    }
    return result;
}

bool ProjectEngine::assignModulation(int lfoId, const std::string& deviceId,
                                     const std::string& paramId, float amount) {
    std::lock_guard<std::shared_mutex> lock(mutex_);
    if (findDeviceLocked(deviceId) == nullptr) {
        return false;
    }
    const bool result = modulationGraph_.assignModulation(lfoId, deviceId, paramId, amount);
    if (result) {
        rebuildTrackPlaybackLocked();
    }
    return result;
}

bool ProjectEngine::removeModulation(int lfoId, const std::string& paramId) {
    std::lock_guard<std::shared_mutex> lock(mutex_);
    const bool result = modulationGraph_.removeModulation(lfoId, paramId);
    if (result) {
        rebuildTrackPlaybackLocked();
    }
    return result;
}

bool ProjectEngine::applySubtractiveSynthPreset(
    const std::string& deviceId,
    const std::vector<std::pair<std::string, float>>& params,
    const std::vector<SubtractivePresetLfoSpec>& lfos,
    const std::vector<SubtractivePresetModSpec>& mods) {
    std::lock_guard<std::shared_mutex> lock(mutex_);
    DeviceSlot* device = findDeviceLocked(deviceId);
    if (device == nullptr || !std::holds_alternative<SubtractiveSynthInstance>(device->instance)) {
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

void ProjectEngine::applyLiveDeviceMetersLocked(ProjectSnapshot& snap) const {
    for (auto& trackState : snap.tracks) {
        for (auto& device : trackState.devices) {
            if (device.type != "gate" && device.type != "compressor" &&
                device.type != "expander" && device.type != "limiter") {
                continue;
            }
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
    deviceMeterSlotCount_ = 0;
    int trackIndex = 0;
    for (const auto& sourceTrack : trackRepo_.tracks()) {
        if (trackIndex >= kMaxTracks) {
            break;
        }

        TrackPlaybackSnapshot& snap = trackPlayback_[trackIndex];
        snap.trackId = sourceTrack.id;
        snap.noteCount = 0;
        snap.regionCount = 0;
        snap.deviceCount = 0;

        for (const auto& device : sourceTrack.devices) {
            if (snap.deviceCount >= kMaxDevicesPerTrack) {
                break;
            }

            DeviceNodePlayback& node = snap.devices[snap.deviceCount];
            node.deviceId = device.id;
            node.bypassed = device.bypassed;
            node.gain = device.gain;
            node.pan = device.pan;
            node.meterSlot = -1;

            const PlaybackBuildContext context{sampleBank_};
            deviceRegistry_.buildPlaybackNode(device, context, node);
            if (isDynamicsDeviceNodeKind(node.kind) && deviceMeterSlotCount_ < kMaxDeviceMeters) {
                node.meterSlot = static_cast<int8_t>(deviceMeterSlotCount_);
                deviceMeterIds_[deviceMeterSlotCount_] = device.id;
                ++deviceMeterSlotCount_;
            }
            ++snap.deviceCount;
        }

        for (const auto& clip : sourceTrack.midiClips) {
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
                };
            }
        }

        // Resolve per-track modulation edges — convert deviceId to deviceIndex
        snap.modEdgeCount = 0;
        for (const auto& globalEdge : modulationGraph_.modEdges()) {
            if (snap.modEdgeCount >= 16) break;
            // Find deviceIndex for this edge's deviceId within this track
            int di = -1;
            for (int i = 0; i < snap.deviceCount; ++i) {
                if (snap.devices[i].deviceId == globalEdge.deviceId) {
                    di = i;
                    break;
                }
            }
            if (di < 0) continue; // edge targets a different track
            // Resolve domain LFO id → compact playback array index.
            // The audio thread indexes lfoValues[] by this compact index,
            // not by the domain LFO id (which starts at 1, not 0).
            const int lfoPlaybackIdx = modulationGraph_.playbackIndexForLfoId(globalEdge.lfoId);
            if (lfoPlaybackIdx < 0) continue; // LFO has been removed
            ModulationEdgePlayback& me = snap.modEdges[snap.modEdgeCount++];
            me.deviceIndex = static_cast<uint16_t>(di);
            me.lfoId = static_cast<uint16_t>(lfoPlaybackIdx);
            me.localParamId = paramIdFromString(globalEdge.paramId.c_str(), snap.devices[di].kind);
            me.amount = globalEdge.amount;
        }

        // Resolve per-track automation clips. Clips live in the global
        // AutomationClipStore; for the **audio** side, we pull in any
        // clip whose target device is on this track. Layout (where the
        // clip is rendered in the arrangement view) is determined by the
        // clip's `homeTrackId` and is handled by the Flutter side — the
        // audio thread only cares about device matching.
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
            pb.localParamId = paramIdFromString(clip.paramId.c_str(), snap.devices[di].kind);
            snap.automationClips[snap.automationClipCount++] = pb;
        }

        ++trackIndex;
    }
    trackPlaybackCount_.store(trackIndex, std::memory_order_release);
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
                if (std::holds_alternative<OscillatorInstance>(device.instance)) {
                    freq = std::get<OscillatorInstance>(device.instance).frequencyHz;
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

} // namespace audioapp
