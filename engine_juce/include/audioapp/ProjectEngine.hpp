#pragma once

#include <atomic>
#include <cstdint>
#include <mutex>
#include <string>
#include <vector>
#include <vector>

#include "audioapp/LivePerformance.hpp"
#include "audioapp/MidiClipPlayback.hpp"
#include "audioapp/SampleBank.hpp"
#include "audioapp/SampleTypes.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/SubtractiveSynth.hpp"

namespace audioapp {

struct ProjectFileData;

struct DeviceState {
    std::string id;
    std::string type;
    float frequencyHz = 440.0f;
    float gain = 1.0f;
    float pan = 0.5f;
    std::string sampleId;
    float attack = 0.01f;
    float decay = 0.3f;
    float sustain = 0.7f;
    float release = 0.4f;
    float filterCutoff = 1.0f;
    float filterQ = 0.35f;
    int filterMode = 0;
    float trimStartSec = 0.0f;
    float trimEndSec = 0.0f;
    bool bypassed = false;
    int osc1Wave = 2;
    int osc2Wave = 2;
    float osc1Octave = 0.5f;
    float osc1Semi = 0.0f;
    float osc1Detune = 0.5f;
    float osc2Octave = 0.5f;
    float osc2Semi = 0.0f;
    float osc2Detune = 0.5f;
    float osc1Level = 0.85f;
    float osc2Level = 0.5f;
    float noiseLevel = 0.0f;
    int oscMixMode = 0;
    float unisonVoices = 0.0f;
    float unisonDetune = 0.35f;
    float filterEnvAmount = 0.5f;
    float filterAttack = 0.05f;
    float filterDecay = 0.35f;
    float filterSustain = 0.4f;
    float filterRelease = 0.45f;
    float glideMs = 0.0f;
    float velocitySensitivity = 1.0f;
};

struct TrackState {
    std::string id;
    std::string name;
    std::vector<DeviceState> devices;
    std::vector<MidiClipState> midiClips;
    std::vector<SampleClipState> sampleClips;
};

struct MasterTrackState {
    std::string id = "master";
    std::string name = "Master";
    float gain = 1.0f;
};

struct ProjectSnapshot {
    int bpm = 120;
    std::string selectedTrackId;
    double playheadBeats = 0.0;
    bool playing = false;
    bool loopEnabled = true;
    double loopLengthBeats = 16.0;
    bool recordArmed = false;
    MasterTrackState master;
    std::vector<SampleLibraryEntryState> samples;
    std::vector<TrackState> tracks;
};

/// Authoritative project model (control thread only).
class ProjectEngine {
public:
    void createProject();
    std::string addTrack(const std::string& name);
    bool selectTrack(const std::string& trackId);
    std::string addDeviceToTrack(const std::string& trackId,
                                 const std::string& deviceType,
                                 int insertIndex = -1);
    bool setDeviceParameter(const std::string& deviceId,
                            const std::string& parameterId,
                            float value);
    bool setDeviceStringParameter(const std::string& deviceId,
                                  const std::string& parameterId,
                                  const std::string& value);
    bool setMasterGain(float gain);
    std::string createMidiClip(const std::string& trackId,
                               double startBeat,
                               double lengthBeats);
    bool setMidiClipNotes(const std::string& clipId, const std::vector<MidiNoteState>& notes);
    std::string createSampleClip(const std::string& trackId,
                                 const std::string& sampleId,
                                 double startBeat,
                                 double lengthBeats);
    bool moveClip(const std::string& clipId,
                  const std::string& targetTrackId,
                  double startBeat);
    bool setClipLength(const std::string& clipId, double lengthBeats);
    bool setBpm(int bpm);
    bool deleteTrack(const std::string& trackId);
    bool deleteClip(const std::string& clipId);
    bool duplicateClip(const std::string& clipId);
    bool setLoopEnabled(bool enabled);
    bool setLoopLengthBeats(double lengthBeats);
    std::vector<float> renderOffline(double lengthBeats, double sampleRate);

    bool setRecordArmed(bool armed);
    bool noteOn(int pitch, float velocity);
    bool noteOff(int pitch);
    void allNotesOff();
    void clearCapture();
    bool commitCapture();
    void readLiveMix(float* monoOut, int numFrames, double sampleRate) noexcept;
    void setLivePitchBend(float bend) noexcept;
    void setLiveModulation(float mod) noexcept;

    ProjectSnapshot snapshot() const;
    float activeOscillatorFrequencyHz() const;
    void readMasterMix(float* monoOut,
                       int numFrames,
                       double sampleRate,
                       double playheadStartBeat) noexcept;
    void readMasterMixStereo(float* leftOut,
                             float* rightOut,
                             int numFrames,
                             double sampleRate,
                             double playheadStartBeat) noexcept;

    void setSampleBank(const SampleBank* bank) { sampleBank_ = bank; }

    void setPlaying(bool playing);
    bool isPlaying() const noexcept;
    double playheadBeats() const noexcept;
    void setPlayheadBeats(double beats) noexcept;
    void resetPlayhead() noexcept;
    void advancePlayhead(int numFrames, double sampleRate) noexcept;

    ProjectFileData toProjectFileData() const;
    bool loadFromProjectFileData(const ProjectFileData& data);

private:
    struct Device {
        std::string id;
        std::string type;
        float frequencyHz = 440.0f;
        float gain = 1.0f;
        float pan = 0.5f;
        std::string sampleId;
        float attack = 0.01f;
        float decay = 0.3f;
        float sustain = 0.7f;
        float release = 0.4f;
        float filterCutoff = 1.0f;
        float filterQ = 0.35f;
        int filterMode = 0;
        float trimStartSec = 0.0f;
        float trimEndSec = 0.0f;
        bool bypassed = false;
        int osc1Wave = 2;
        int osc2Wave = 2;
        float osc1Octave = 0.5f;
        float osc1Semi = 0.0f;
        float osc1Detune = 0.5f;
        float osc2Octave = 0.5f;
        float osc2Semi = 0.0f;
        float osc2Detune = 0.5f;
        float osc1Level = 0.85f;
        float osc2Level = 0.5f;
        float noiseLevel = 0.0f;
        int oscMixMode = 0;
        float unisonVoices = 0.0f;
        float unisonDetune = 0.35f;
        float filterEnvAmount = 0.5f;
        float filterAttack = 0.05f;
        float filterDecay = 0.35f;
        float filterSustain = 0.4f;
        float filterRelease = 0.45f;
        float glideMs = 0.0f;
        float velocitySensitivity = 1.0f;
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

    struct SampleClip {
        std::string id;
        std::string sampleId;
        double startBeat = 0.0;
        double lengthBeats = 4.0;
    };

    struct Track {
        std::string id;
        std::string name;
        std::vector<Device> devices;
        std::vector<MidiClip> midiClips;
        std::vector<SampleClip> sampleClips;
    };

    struct PlaybackNote {
        int pitch = 60;
        double clipStartBeat = 0.0;
        double clipLengthBeats = 4.0;
        double noteStartBeat = 0.0;
        double noteDurationBeats = 1.0;
        float velocity = 100.0f;
    };

    struct SampleRegion {
        double clipStartBeat = 0.0;
        double clipLengthBeats = 4.0;
        const float* pcm = nullptr;
        int frameCount = 0;
        double pcmSampleRate = 48000.0;
    };

    struct TrackPlaybackSnapshot {
        std::string trackId;
        int noteCount = 0;
        PlaybackNote notes[32];
        int regionCount = 0;
        SampleRegion regions[8];
        int deviceCount = 0;
        DeviceNodePlayback devices[kMaxDevicesPerTrack];
        BiquadState samplerFilterStates[kMaxDevicesPerTrack];
        SubtractiveSynthRuntime subtractiveRuntimes[kMaxDevicesPerTrack];
        float oscillatorPhase = 0.0f;
    };

    static constexpr int kMaxTracks = 8;

    mutable std::mutex mutex_;
    std::string projectName_ = "Untitled";
    int bpm_ = 120;
    int nextTrackNum_ = 1;
    int nextDeviceNum_ = 1;
    int nextClipNum_ = 1;
    int nextSampleClipNum_ = 1;
    std::vector<Track> tracks_;
    std::string selectedTrackId_;
    std::atomic<float> activeFrequencyHz_{440.0f};
    std::atomic<bool> playing_{false};
    std::atomic<double> playheadBeats_{0.0};
    std::atomic<float> masterGain_{1.0f};
    bool loopEnabled_ = true;
    double loopLengthBeats_ = 16.0;
    bool recordArmed_ = false;

    struct CaptureEvent {
        enum class Type { NoteOn, NoteOff };
        Type type = Type::NoteOn;
        int pitch = 60;
        float velocity = 100.0f;
        uint64_t sampleTime = 0;
    };
    std::vector<CaptureEvent> captureEvents_;
    uint64_t captureStartSample_ = 0;
    bool captureActive_ = false;
    LivePerformanceMixer liveMixer_;
    std::atomic<float> livePitchBend_{0.0f};
    std::atomic<float> liveModulation_{0.0f};

    TrackPlaybackSnapshot trackPlayback_[kMaxTracks];
    std::atomic<int> trackPlaybackCount_{0};

    void rebuildTrackPlaybackLocked();
    void mixAtPlayheadBeat(float* monoOut,
                           int numFrames,
                           double sampleRate,
                           double playheadStartBeat) noexcept;
    void mixAtPlayheadBeatStereo(float* masterLeft,
                                 float* masterRight,
                                 int numFrames,
                                 double sampleRate,
                                 double playheadStartBeat) noexcept;
    bool trackHasActiveSampleAtPlayhead(const TrackPlaybackSnapshot& track, double playheadBeat) const noexcept;
    int selectedTrackPlaybackIndex() const noexcept;
    void syncActiveFrequencyLocked();
    void recomputeIdCountersLocked();
    void ensureTrackGainDevicesLocked();
    const DeviceNodePlayback* findOscillatorNode(const TrackPlaybackSnapshot& track) const noexcept;
    Track* findTrackLocked(const std::string& trackId);
    Device* findDeviceLocked(const std::string& deviceId);
    MidiClip* findMidiClipLocked(const std::string& clipId);
    SampleClip* findSampleClipLocked(const std::string& clipId);
    bool buildLiveInstrumentForTrack(const Track& track, LiveInstrumentSnapshot& out) const;
    double sampleTimeToCaptureBeat(uint64_t sampleTime) const;
    static SubtractiveSynthParams subtractiveParamsFromDevice(const Device& device);
    static void copyDeviceToState(const Device& src, DeviceState& dst);
    static void copyStateToDevice(const DeviceState& src, Device& dst);

    const SampleBank* sampleBank_ = nullptr;
};

} // namespace audioapp
