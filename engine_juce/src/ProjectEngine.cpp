#include "audioapp/ProjectEngine.hpp"
#include "audioapp/ProjectJson.hpp"
#include "audioapp/TimelineClipTypes.hpp"
#include "audioapp/MidiUtils.hpp"
#include "audioapp/MasterMix.hpp"
#include "audioapp/SamplePlayback.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/OscillatorInstance.hpp"
#include "audioapp/devices/instances/TrackGainInstance.hpp"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstring>
#include <cstdlib>
#include <vector>

namespace audioapp {

void ProjectEngine::createProject() {
    std::lock_guard<std::mutex> lock(mutex_);
    trackRepo_.clear();
    clipRepo_.clear();
    projectName_ = "Untitled";
    nextLfoId_ = 1;
    bpm_ = 120;
    activeFrequencyHz_.store(440.0f, std::memory_order_release);
    playing_.store(false, std::memory_order_release);
    playheadBeats_.store(0.0, std::memory_order_release);
    masterGain_.store(1.0f, std::memory_order_release);
    trackPlaybackCount_.store(0, std::memory_order_release);
    lfos_.clear();
    modEdges_.clear();
    lfoPlaybackCount_.store(0, std::memory_order_release);
    modEdgePlaybackCount_.store(0, std::memory_order_release);
}

std::string ProjectEngine::addTrack(const std::string& name) {
    std::lock_guard<std::mutex> lock(mutex_);
    const std::string trackId = trackRepo_.addTrack(name, deviceRegistry_);
    syncActiveFrequencyLocked();
    rebuildTrackPlaybackLocked();
    return trackId;
}

bool ProjectEngine::selectTrack(const std::string& trackId) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!trackRepo_.selectTrack(trackId)) {
        return false;
    }
    syncActiveFrequencyLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

std::string ProjectEngine::addDeviceToTrack(const std::string& trackId,
                                            const std::string& deviceType,
                                            int insertIndex) {
    std::lock_guard<std::mutex> lock(mutex_);
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

bool ProjectEngine::setDeviceParameter(const std::string& deviceId,
                                       const std::string& parameterId,
                                       float value) {
    std::lock_guard<std::mutex> lock(mutex_);
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
    std::lock_guard<std::mutex> lock(mutex_);
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
    std::lock_guard<std::mutex> lock(mutex_);
    const std::string clipId = clipRepo_.createMidiClip(trackId, startBeat, lengthBeats);
    if (clipId.empty()) {
        return {};
    }
    rebuildTrackPlaybackLocked();
    return clipId;
}

bool ProjectEngine::setMidiClipNotes(const std::string& clipId,
                                     const std::vector<MidiNoteState>& notes) {
    std::lock_guard<std::mutex> lock(mutex_);
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
    std::lock_guard<std::mutex> lock(mutex_);
    const std::string clipId = clipRepo_.createSampleClip(
        trackId, sampleId, startBeat, lengthBeats, sampleBank_, bpm_);
    if (clipId.empty()) {
        return {};
    }
    rebuildTrackPlaybackLocked();
    return clipId;
}

bool ProjectEngine::moveClip(const std::string& clipId,
                             const std::string& targetTrackId,
                             double startBeat) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!clipRepo_.moveClip(clipId, targetTrackId, startBeat)) {
        return false;
    }
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::setClipLength(const std::string& clipId, double lengthBeats) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!clipRepo_.setClipLength(clipId, lengthBeats)) {
        return false;
    }
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::setBpm(int bpm) {
    if (bpm < 40 || bpm > 300) {
        return false;
    }
    std::lock_guard<std::mutex> lock(mutex_);
    bpm_ = bpm;
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::deleteTrack(const std::string& trackId) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!trackRepo_.deleteTrack(trackId)) {
        return false;
    }
    syncActiveFrequencyLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::deleteClip(const std::string& clipId) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!clipRepo_.deleteClip(clipId)) {
        return false;
    }
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::duplicateClip(const std::string& clipId) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!clipRepo_.duplicateClip(clipId)) {
        return false;
    }
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::setLoopEnabled(bool enabled) {
    std::lock_guard<std::mutex> lock(mutex_);
    loopEnabled_ = enabled;
    return true;
}

bool ProjectEngine::setLoopLengthBeats(double lengthBeats) {
    if (lengthBeats < 1.0) {
        return false;
    }
    std::lock_guard<std::mutex> lock(mutex_);
    loopLengthBeats_ = lengthBeats;
    return true;
}

std::vector<float> ProjectEngine::renderOffline(double lengthBeats, double sampleRate) {
    if (lengthBeats <= 0.0 || sampleRate <= 0.0) {
        return {};
    }
    std::lock_guard<std::mutex> lock(mutex_);
    const int totalFrames =
        static_cast<int>(lengthBeats * sampleRate * 60.0 / static_cast<double>(std::max(bpm_, 1)));
    if (totalFrames <= 0) {
        return {};
    }
    std::vector<float> output(static_cast<size_t>(totalFrames), 0.0f);
    constexpr int kBlock = 512;
    float block[kBlock];
    for (int offset = 0; offset < totalFrames; offset += kBlock) {
        const int frames = std::min(kBlock, totalFrames - offset);
        const double beat =
            static_cast<double>(offset) / sampleRate * static_cast<double>(bpm_) / 60.0;
        std::memset(block, 0, static_cast<size_t>(frames) * sizeof(float));
        mixAtPlayheadBeat(block, frames, sampleRate, beat);
        std::memcpy(output.data() + offset, block, static_cast<size_t>(frames) * sizeof(float));
    }
    return output;
}

ProjectSnapshot ProjectEngine::snapshot() const {
    std::lock_guard<std::mutex> lock(mutex_);
    ProjectSnapshot snap;
    snap.bpm = bpm_;
    snap.selectedTrackId = trackRepo_.selectedTrackId();
    snap.playheadBeats = playheadBeats_.load(std::memory_order_relaxed);
    snap.playing = playing_.load(std::memory_order_relaxed);
    snap.loopEnabled = loopEnabled_;
    snap.loopLengthBeats = loopLengthBeats_;
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
            entry.durationBeats = sampleBank_->beatsForSample(sample.id, bpm_);
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

    snap.lfos = lfos_;
    snap.modEdges = modEdges_;

    return snap;
}

float ProjectEngine::activeOscillatorFrequencyHz() const {
    if (!playing_.load(std::memory_order_acquire)) {
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

    const double playhead = playheadBeats_.load(std::memory_order_acquire);
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
    float left[kMaxFrames];
    float right[kMaxFrames];
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
    if (!playing_.load(std::memory_order_acquire)) {
        return;
    }
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
    float trackLeft[kMaxFrames];
    float trackRight[kMaxFrames];
    const int framesToProcess = numFrames > kMaxFrames ? kMaxFrames : numFrames;

        // Compute per-frame LFO values for gain/pan modulation.
    // DSP-specific params still use frame-0 (block-rate).
    const int lfoCount = lfoPlaybackCount_.load(std::memory_order_acquire);
    const int edgeCount = modEdgePlaybackCount_.load(std::memory_order_acquire);
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
        const double playheadSeconds = playheadStartBeat * 60.0 / static_cast<double>(std::max(bpm_, 1));
        const double samplePeriod = 1.0 / std::max(sampleRate, 1.0);
        for (int i = 0; i < lfoCount; ++i) {
            const auto& lfo = lfoPlayback_[i].state;
            for (int frame = 0; frame < framesToProcess; ++frame) {
                const double frameSeconds = playheadSeconds + static_cast<double>(frame) * samplePeriod;
                double phase;
                if (lfo.syncDivision == 0) {
                    // Hz mode: phase derived from wall clock
                    phase = frameSeconds * static_cast<double>(lfo.rate) + static_cast<double>(lfo.phase);
                } else {
                    // Sync mode: derive phase from playhead position
                    const double beatDuration = lfoSyncBeats(lfo.syncDivision);
                    const double frameBeat = playheadStartBeat + static_cast<double>(frame) * samplePeriod * (static_cast<double>(std::max(bpm_, 1)) / 60.0);
                    phase = (beatDuration > 0.0) ? (frameBeat / beatDuration) : 0.0;
                    phase += static_cast<double>(lfo.phase);
                }
                lfoValues[i * framesToProcess + frame] = lfoEvaluate(
                    static_cast<LfoWaveform>(lfo.waveform),
                    static_cast<float>(phase));
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
                                  bpm_,
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
                           bpm_,
                           playheadStartBeat,
                           midiNotes,
                           noteCount,
                           track.devices,
                           track.deviceCount,
                           oscillatorPhase,
                           suppressInstruments,
                           trackPlayback_[trackIndex].samplerFilterStates,
                           trackPlayback_[trackIndex].subtractiveRuntimes,
                           lfoCount > 0 ? lfoValues.data() : nullptr,
                           lfoCount,
                           modEdgePlayback_,
                           edgeCount);
        trackPlayback_[trackIndex].oscillatorPhase = oscillatorPhase;

        for (int frame = 0; frame < framesToProcess; ++frame) {
            masterLeft[frame] += trackLeft[frame];
            masterRight[frame] += trackRight[frame];
        }
    }

    for (int frame = 0; frame < framesToProcess; ++frame) {
        masterLeft[frame] = std::tanh(masterLeft[frame] * masterGain);
        masterRight[frame] = std::tanh(masterRight[frame] * masterGain);
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
    float left[kMaxFrames];
    float right[kMaxFrames];
    mixAtPlayheadBeatStereo(left, right, framesToProcess, sampleRate, playheadStartBeat);
    for (int frame = 0; frame < framesToProcess; ++frame) {
        monoOut[frame] = (left[frame] + right[frame]) * 0.5f;
    }
}

void ProjectEngine::setPlaying(bool playing) {
    if (playing) {
        std::lock_guard<std::mutex> lock(mutex_);
        rebuildTrackPlaybackLocked();
        resetPlayhead();
    }
    playing_.store(playing, std::memory_order_release);
}

bool ProjectEngine::isPlaying() const noexcept {
    return playing_.load(std::memory_order_acquire);
}

double ProjectEngine::playheadBeats() const noexcept {
    return playheadBeats_.load(std::memory_order_acquire);
}

void ProjectEngine::setPlayheadBeats(double beats) noexcept {
    const double clamped = beats < 0.0 ? 0.0 : beats;
    playheadBeats_.store(clamped, std::memory_order_release);
}

void ProjectEngine::resetPlayhead() noexcept {
    playheadBeats_.store(0.0, std::memory_order_release);
}

void ProjectEngine::advancePlayhead(int numFrames, double sampleRate) noexcept {
    if (!playing_.load(std::memory_order_acquire)) {
        return;
    }
    const double current = playheadBeats_.load(std::memory_order_relaxed);
    double next = advancePlayheadBeats(current, numFrames, sampleRate, bpm_);
    if (loopEnabled_ && loopLengthBeats_ > 0.0 && next >= loopLengthBeats_) {
        next = std::fmod(next, loopLengthBeats_);
    }
    playheadBeats_.store(next, std::memory_order_release);
}

ProjectFileData ProjectEngine::toProjectFileData() const {
    std::lock_guard<std::mutex> lock(mutex_);
    ProjectFileData file;
    file.projectFormatVersion = kProjectFormatVersion;
    file.name = projectName_;
    file.bpm = bpm_;
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
            entry.durationBeats = sampleBank_->beatsForSample(sample.id, bpm_);
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
    file.lfos = lfos_;
    file.modEdges = modEdges_;
    return file;
}

bool ProjectEngine::loadFromProjectFileData(const ProjectFileData& data) {
    if (data.projectFormatVersion != kProjectFormatVersion) {
        return false;
    }

    std::lock_guard<std::mutex> lock(mutex_);
    projectName_ = data.name.empty() ? "Untitled" : data.name;
    bpm_ = data.bpm > 0 ? data.bpm : 120;
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

    recomputeIdCountersLocked();
    trackRepo_.ensureTrackGainDevices(deviceRegistry_);

    lfos_ = data.lfos;
    modEdges_ = data.modEdges;

    if (data.master.gain > 0.0f) {
        masterGain_.store(std::clamp(data.master.gain, 0.0f, 1.0f), std::memory_order_release);
    } else {
        masterGain_.store(1.0f, std::memory_order_release);
    }
    playing_.store(false, std::memory_order_release);
    playheadBeats_.store(0.0, std::memory_order_release);
    syncActiveFrequencyLocked();
    rebuildTrackPlaybackLocked();
    rebuildLfoPlaybackLocked();
    return true;
}

int ProjectEngine::createLfo() {
    std::lock_guard<std::mutex> lock(mutex_);
    LfoState lfo;
    lfo.id = nextLfoId_++;
    lfo.waveform = static_cast<int>(LfoWaveform::Sine);
    lfo.rate = 1.0f;
    lfo.syncDivision = 3; // 1/4
    lfo.phase = 0.0f;
    lfos_.push_back(std::move(lfo));
    rebuildLfoPlaybackLocked();
    return lfo.id;
}

bool ProjectEngine::removeLfo(int lfoId) {
    std::lock_guard<std::mutex> lock(mutex_);
    for (auto it = lfos_.begin(); it != lfos_.end(); ++it) {
        if (it->id != lfoId) {
            continue;
        }
        lfos_.erase(it);
        // Remove all edges referencing this LFO
        for (auto eit = modEdges_.begin(); eit != modEdges_.end();) {
            if (eit->lfoId == lfoId) {
                eit = modEdges_.erase(eit);
            } else {
                ++eit;
            }
        }
        rebuildLfoPlaybackLocked();
        return true;
    }
    return false;
}

bool ProjectEngine::updateLfoParam(int lfoId, const std::string& param, float value) {
    std::lock_guard<std::mutex> lock(mutex_);
    for (auto& lfo : lfos_) {
        if (lfo.id != lfoId) {
            continue;
        }
        if (param == "waveform") {
            lfo.waveform = std::clamp(static_cast<int>(value), 0, static_cast<int>(LfoWaveform::Ramp));
        } else if (param == "rate") {
            lfo.rate = std::max(0.01f, value);
        } else if (param == "syncDivision") {
            lfo.syncDivision = std::clamp(static_cast<int>(value), 0, 5);
        } else if (param == "phase") {
            lfo.phase = std::clamp(value, 0.0f, 1.0f);
        } else {
            return false;
        }
        rebuildLfoPlaybackLocked();
        return true;
    }
    return false;
}

bool ProjectEngine::assignModulation(int lfoId, const std::string& deviceId,
                                     const std::string& paramId, float amount) {
    std::lock_guard<std::mutex> lock(mutex_);
    // Check LFO exists
    bool lfoOk = false;
    for (const auto& lfo : lfos_) {
        if (lfo.id == lfoId) {
            lfoOk = true;
            break;
        }
    }
    if (!lfoOk) {
        return false;
    }
    // Check device exists
    if (findDeviceLocked(deviceId) == nullptr) {
        return false;
    }
    // Update existing edge or add new one
    for (auto& edge : modEdges_) {
        if (edge.lfoId == lfoId && edge.paramId == paramId) {
            edge.deviceId = deviceId;
            edge.amount = std::clamp(amount, -1.0f, 1.0f);
            rebuildLfoPlaybackLocked();
            return true;
        }
    }
    ModulationEdge edge;
    edge.lfoId = lfoId;
    edge.deviceId = deviceId;
    edge.paramId = paramId;
    edge.amount = std::clamp(amount, -1.0f, 1.0f);
    modEdges_.push_back(std::move(edge));
    rebuildLfoPlaybackLocked();
    return true;
}

bool ProjectEngine::removeModulation(int lfoId, const std::string& paramId) {
    std::lock_guard<std::mutex> lock(mutex_);
    for (auto it = modEdges_.begin(); it != modEdges_.end(); ++it) {
        if (it->lfoId == lfoId && it->paramId == paramId) {
            modEdges_.erase(it);
            rebuildLfoPlaybackLocked();
            return true;
        }
    }
    return false;
}

void ProjectEngine::rebuildLfoPlaybackLocked() {
    int lfoIndex = 0;
    for (const auto& lfo : lfos_) {
        if (lfoIndex >= kMaxLfos) {
            break;
        }
        lfoPlayback_[lfoIndex].state = lfo;
        ++lfoIndex;
    }
    lfoPlaybackCount_.store(lfoIndex, std::memory_order_release);

    int edgeIndex = 0;
    for (const auto& edge : modEdges_) {
        if (edgeIndex >= kMaxModEdges) {
            break;
        }
        modEdgePlayback_[edgeIndex] = edge;
        ++edgeIndex;
    }
    modEdgePlaybackCount_.store(edgeIndex, std::memory_order_release);
}

void ProjectEngine::recomputeIdCountersLocked() {
    trackRepo_.recomputeIdCounters();
    clipRepo_.recomputeIdCounters();

    int maxLfo = 0;
    for (const auto& lfo : lfos_) {
        maxLfo = std::max(maxLfo, lfo.id);
    }
    nextLfoId_ = maxLfo + 1;
}

void ProjectEngine::rebuildTrackPlaybackLocked() {
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

            DeviceNodePlayback& node = snap.devices[snap.deviceCount++];
            node.deviceId = device.id;
            node.bypassed = device.bypassed;
            node.gain = device.gain;
            node.pan = device.pan;

            const PlaybackBuildContext context{sampleBank_};
            deviceRegistry_.buildPlaybackNode(device, context, node);
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
