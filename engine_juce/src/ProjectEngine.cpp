#include "audioapp/ProjectEngine.hpp"
#include "audioapp/ProjectJson.hpp"
#include "audioapp/MidiUtils.hpp"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdlib>

namespace audioapp {

void ProjectEngine::createProject() {
    std::lock_guard<std::mutex> lock(mutex_);
    tracks_.clear();
    selectedTrackId_.clear();
    projectName_ = "Untitled";
    nextTrackNum_ = 1;
    nextDeviceNum_ = 1;
    nextClipNum_ = 1;
    bpm_ = 120;
    activeFrequencyHz_.store(440.0f, std::memory_order_release);
    playing_.store(false, std::memory_order_release);
    playheadBeats_.store(0.0, std::memory_order_release);
    playbackNoteCount_.store(0, std::memory_order_release);
}

std::string ProjectEngine::addTrack(const std::string& name) {
    std::lock_guard<std::mutex> lock(mutex_);
    Track track;
    track.id = "track-" + std::to_string(nextTrackNum_++);
    track.name = name.empty() ? ("Track " + std::to_string(tracks_.size() + 1)) : name;

    Device osc;
    osc.id = "dev-" + std::to_string(nextDeviceNum_++);
    osc.type = "simple_oscillator";
    osc.frequencyHz = 440.0f;
    track.devices.push_back(std::move(osc));

    tracks_.push_back(std::move(track));
    selectedTrackId_ = tracks_.back().id;
    syncActiveFrequencyLocked();
    rebuildPlaybackNotesLocked();
    return selectedTrackId_;
}

bool ProjectEngine::selectTrack(const std::string& trackId) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (findTrackLocked(trackId) == nullptr) {
        return false;
    }
    selectedTrackId_ = trackId;
    syncActiveFrequencyLocked();
    rebuildPlaybackNotesLocked();
    return true;
}

std::string ProjectEngine::addDeviceToTrack(const std::string& trackId, const std::string& deviceType) {
    std::lock_guard<std::mutex> lock(mutex_);
    Track* track = findTrackLocked(trackId);
    if (track == nullptr) {
        return {};
    }

    Device device;
    device.id = "dev-" + std::to_string(nextDeviceNum_++);
    device.type = deviceType.empty() ? "simple_oscillator" : deviceType;
    device.frequencyHz = 440.0f;
    track->devices.push_back(std::move(device));
    syncActiveFrequencyLocked();
    rebuildPlaybackNotesLocked();
    return track->devices.back().id;
}

bool ProjectEngine::setDeviceParameter(const std::string& deviceId,
                                       const std::string& parameterId,
                                       float value) {
    std::lock_guard<std::mutex> lock(mutex_);
    Device* device = findDeviceLocked(deviceId);
    if (device == nullptr || parameterId != "frequency") {
        return false;
    }
    device->frequencyHz = value;
    syncActiveFrequencyLocked();
    rebuildPlaybackNotesLocked();
    return true;
}

std::string ProjectEngine::createMidiClip(const std::string& trackId,
                                          double startBeat,
                                          double lengthBeats) {
    std::lock_guard<std::mutex> lock(mutex_);
    Track* track = findTrackLocked(trackId);
    if (track == nullptr) {
        return {};
    }

    MidiClip clip;
    clip.id = "clip-" + std::to_string(nextClipNum_++);
    clip.startBeat = startBeat < 0.0 ? 0.0 : startBeat;
    clip.lengthBeats = lengthBeats > 0.0 ? lengthBeats : 4.0;

    MidiNote seed;
    seed.pitch = 60;
    seed.startBeat = 0.0;
    seed.durationBeats = 1.0;
    seed.velocity = 100.0f;
    clip.notes.push_back(seed);

    track->midiClips.push_back(std::move(clip));
    rebuildPlaybackNotesLocked();
    return track->midiClips.back().id;
}

bool ProjectEngine::setMidiClipNotes(const std::string& clipId,
                                     const std::vector<MidiNoteState>& notes) {
    std::lock_guard<std::mutex> lock(mutex_);
    MidiClip* clip = findMidiClipLocked(clipId);
    if (clip == nullptr) {
        return false;
    }

    clip->notes.clear();
    clip->notes.reserve(notes.size());
    for (const auto& note : notes) {
        MidiNote stored;
        stored.pitch = note.pitch;
        stored.startBeat = note.startBeat < 0.0 ? 0.0 : note.startBeat;
        stored.durationBeats = note.durationBeats > 0.0 ? note.durationBeats : 0.25;
        stored.velocity = note.velocity;
        clip->notes.push_back(stored);
    }
    rebuildPlaybackNotesLocked();
    return true;
}

ProjectSnapshot ProjectEngine::snapshot() const {
    std::lock_guard<std::mutex> lock(mutex_);
    ProjectSnapshot snap;
    snap.bpm = bpm_;
    snap.selectedTrackId = selectedTrackId_;
    snap.playheadBeats = playheadBeats_.load(std::memory_order_relaxed);
    snap.playing = playing_.load(std::memory_order_relaxed);
    snap.tracks.reserve(tracks_.size());
    for (const auto& track : tracks_) {
        TrackState ts;
        ts.id = track.id;
        ts.name = track.name;
        ts.devices.reserve(track.devices.size());
        for (const auto& device : track.devices) {
            DeviceState ds;
            ds.id = device.id;
            ds.type = device.type;
            ds.frequencyHz = device.frequencyHz;
            ts.devices.push_back(ds);
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
        snap.tracks.push_back(std::move(ts));
    }
    return snap;
}

float ProjectEngine::activeOscillatorFrequencyHz() const {
    if (playing_.load(std::memory_order_acquire)) {
        return frequencyForPlayheadUnlocked(playheadBeats_.load(std::memory_order_acquire));
    }
    return activeFrequencyHz_.load(std::memory_order_acquire);
}

void ProjectEngine::setPlaying(bool playing) {
    if (playing) {
        std::lock_guard<std::mutex> lock(mutex_);
        rebuildPlaybackNotesLocked();
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

void ProjectEngine::resetPlayhead() noexcept {
    playheadBeats_.store(0.0, std::memory_order_release);
}

void ProjectEngine::advancePlayhead(int numFrames, double sampleRate) noexcept {
    if (!playing_.load(std::memory_order_acquire)) {
        return;
    }
    const double current = playheadBeats_.load(std::memory_order_relaxed);
    const double next = advancePlayheadBeats(current, numFrames, sampleRate, bpm_);
    playheadBeats_.store(next, std::memory_order_release);
}

ProjectFileData ProjectEngine::toProjectFileData() const {
    std::lock_guard<std::mutex> lock(mutex_);
    ProjectFileData file;
    file.projectFormatVersion = kProjectFormatVersion;
    file.name = projectName_;
    file.bpm = bpm_;
    file.selectedTrackId = selectedTrackId_;
    file.tracks.reserve(tracks_.size());

    for (const auto& track : tracks_) {
        TrackState ts;
        ts.id = track.id;
        ts.name = track.name;
        for (const auto& device : track.devices) {
            ts.devices.push_back(DeviceState{device.id, device.type, device.frequencyHz});
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
        file.tracks.push_back(std::move(ts));
    }
    return file;
}

bool ProjectEngine::loadFromProjectFileData(const ProjectFileData& data) {
    if (data.projectFormatVersion != kProjectFormatVersion) {
        return false;
    }

    std::lock_guard<std::mutex> lock(mutex_);
    projectName_ = data.name.empty() ? "Untitled" : data.name;
    bpm_ = data.bpm > 0 ? data.bpm : 120;
    selectedTrackId_ = data.selectedTrackId;
    tracks_.clear();

    for (const auto& trackState : data.tracks) {
        Track track;
        track.id = trackState.id;
        track.name = trackState.name;
        for (const auto& deviceState : trackState.devices) {
            Device device;
            device.id = deviceState.id;
            device.type = deviceState.type;
            device.frequencyHz = deviceState.frequencyHz;
            track.devices.push_back(std::move(device));
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
        tracks_.push_back(std::move(track));
    }

    recomputeIdCountersLocked();
    playing_.store(false, std::memory_order_release);
    playheadBeats_.store(0.0, std::memory_order_release);
    syncActiveFrequencyLocked();
    rebuildPlaybackNotesLocked();
    return true;
}

void ProjectEngine::recomputeIdCountersLocked() {
    auto maxSuffix = [](const std::string& id, const std::string& prefix) {
        if (id.rfind(prefix, 0) != 0) {
            return 0;
        }
        const auto suffix = id.substr(prefix.size());
        return suffix.empty() ? 0 : std::atoi(suffix.c_str());
    };

    int maxTrack = 0;
    int maxDevice = 0;
    int maxClip = 0;
    for (const auto& track : tracks_) {
        maxTrack = std::max(maxTrack, maxSuffix(track.id, "track-"));
        for (const auto& device : track.devices) {
            maxDevice = std::max(maxDevice, maxSuffix(device.id, "dev-"));
        }
        for (const auto& clip : track.midiClips) {
            maxClip = std::max(maxClip, maxSuffix(clip.id, "clip-"));
        }
    }
    nextTrackNum_ = maxTrack + 1;
    nextDeviceNum_ = maxDevice + 1;
    nextClipNum_ = maxClip + 1;
}

void ProjectEngine::rebuildPlaybackNotesLocked() {
    int count = 0;
    if (Track* track = findTrackLocked(selectedTrackId_)) {
        for (const auto& clip : track->midiClips) {
            for (const auto& note : clip.notes) {
                if (count >= kMaxPlaybackNotes) {
                    break;
                }
                playbackNotes_[count++] = PlaybackNote{
                    note.pitch,
                    clip.startBeat,
                    clip.lengthBeats,
                    note.startBeat,
                    note.durationBeats,
                };
            }
        }
    }
    playbackNoteCount_.store(count, std::memory_order_release);
}

float ProjectEngine::frequencyForPlayheadUnlocked(double playheadBeat) const noexcept {
    const int count = playbackNoteCount_.load(std::memory_order_acquire);
    int pitch = -1;
    for (int i = 0; i < count; ++i) {
        const PlaybackNote& note = playbackNotes_[i];
        if (playheadBeat < note.clipStartBeat || playheadBeat >= note.clipStartBeat + note.clipLengthBeats) {
            continue;
        }
        const double posInClip = playheadBeat - note.clipStartBeat;
        const double loopedBeat = std::fmod(posInClip, note.clipLengthBeats);
        const bool active = loopedBeat >= note.noteStartBeat
            && loopedBeat < (note.noteStartBeat + note.noteDurationBeats);
        if (active) {
            pitch = note.pitch;
        }
    }
    if (pitch >= 0) {
        return midiNoteToHz(pitch);
    }
    return activeFrequencyHz_.load(std::memory_order_relaxed);
}

void ProjectEngine::syncActiveFrequencyLocked() {
    float freq = 440.0f;
    if (!selectedTrackId_.empty()) {
        if (Track* track = findTrackLocked(selectedTrackId_)) {
            for (const auto& device : track->devices) {
                if (device.type == "simple_oscillator") {
                    freq = device.frequencyHz;
                    break;
                }
            }
        }
    }
    activeFrequencyHz_.store(freq, std::memory_order_release);
}

ProjectEngine::Track* ProjectEngine::findTrackLocked(const std::string& trackId) {
    for (auto& track : tracks_) {
        if (track.id == trackId) {
            return &track;
        }
    }
    return nullptr;
}

ProjectEngine::Device* ProjectEngine::findDeviceLocked(const std::string& deviceId) {
    for (auto& track : tracks_) {
        for (auto& device : track.devices) {
            if (device.id == deviceId) {
                return &device;
            }
        }
    }
    return nullptr;
}

ProjectEngine::MidiClip* ProjectEngine::findMidiClipLocked(const std::string& clipId) {
    for (auto& track : tracks_) {
        for (auto& clip : track.midiClips) {
            if (clip.id == clipId) {
                return &clip;
            }
        }
    }
    return nullptr;
}

} // namespace audioapp
