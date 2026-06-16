#pragma once

#include <atomic>
#include <mutex>
#include <optional>
#include <string>
#include <vector>

#include "audioapp/MidiClipPlayback.hpp"

namespace audioapp {

struct ProjectFileData;

struct DeviceState {
    std::string id;
    std::string type;
    float frequencyHz = 440.0f;
};

struct TrackState {
    std::string id;
    std::string name;
    std::vector<DeviceState> devices;
    std::vector<MidiClipState> midiClips;
};

struct ProjectSnapshot {
    int bpm = 120;
    std::string selectedTrackId;
    double playheadBeats = 0.0;
    bool playing = false;
    std::vector<TrackState> tracks;
};

/// Authoritative project model (control thread only).
class ProjectEngine {
public:
    void createProject();
    std::string addTrack(const std::string& name);
    bool selectTrack(const std::string& trackId);
    std::string addDeviceToTrack(const std::string& trackId, const std::string& deviceType);
    bool setDeviceParameter(const std::string& deviceId,
                            const std::string& parameterId,
                            float value);
    std::string createMidiClip(const std::string& trackId,
                               double startBeat,
                               double lengthBeats);
    bool setMidiClipNotes(const std::string& clipId, const std::vector<MidiNoteState>& notes);

    ProjectSnapshot snapshot() const;
    float activeOscillatorFrequencyHz() const;

    void setPlaying(bool playing);
    bool isPlaying() const noexcept;
    double playheadBeats() const noexcept;
    void resetPlayhead() noexcept;
    void advancePlayhead(int numFrames, double sampleRate) noexcept;

    ProjectFileData toProjectFileData() const;
    bool loadFromProjectFileData(const ProjectFileData& data);

private:
    struct Device {
        std::string id;
        std::string type;
        float frequencyHz = 440.0f;
    };

    struct MidiNote {
        int pitch = 60;
        double startBeat = 0.0;
        double durationBeats = 1.0;
        float velocity = 100.0f;
    };

    struct MidiClip {
        std::string id;
        double startBeat = 0.0;
        double lengthBeats = 4.0;
        std::vector<MidiNote> notes;
    };

    struct Track {
        std::string id;
        std::string name;
        std::vector<Device> devices;
        std::vector<MidiClip> midiClips;
    };

    mutable std::mutex mutex_;
    std::string projectName_ = "Untitled";
    int bpm_ = 120;
    int nextTrackNum_ = 1;
    int nextDeviceNum_ = 1;
    int nextClipNum_ = 1;
    std::vector<Track> tracks_;
    std::string selectedTrackId_;
    std::atomic<float> activeFrequencyHz_{440.0f};
    std::atomic<bool> playing_{false};
    std::atomic<double> playheadBeats_{0.0};

    struct PlaybackNote {
        int pitch = 60;
        double clipStartBeat = 0.0;
        double clipLengthBeats = 4.0;
        double noteStartBeat = 0.0;
        double noteDurationBeats = 1.0;
    };

    static constexpr int kMaxPlaybackNotes = 64;
    PlaybackNote playbackNotes_[kMaxPlaybackNotes];
    std::atomic<int> playbackNoteCount_{0};

    void rebuildPlaybackNotesLocked();
    float frequencyForPlayheadUnlocked(double playheadBeat) const noexcept;
    void syncActiveFrequencyLocked();
    void recomputeIdCountersLocked();
    Track* findTrackLocked(const std::string& trackId);
    Device* findDeviceLocked(const std::string& deviceId);
    MidiClip* findMidiClipLocked(const std::string& clipId);
};

} // namespace audioapp
