#pragma once

#include <atomic>
#include <cstdint>
#include <memory>
#include <shared_mutex>
#include <string>
#include <vector>

#include "audioapp/AutomationTypes.hpp"
#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/model/TrackModel.hpp"
#include "audioapp/model/TrackRepository.hpp"
#include "audioapp/model/ClipRepository.hpp"
#include "audioapp/LfoTypes.hpp"
#include "audioapp/LivePerformance.hpp"
#include "audioapp/MidiClipPlayback.hpp"
#include "audioapp/SampleBank.hpp"
#include "audioapp/SampleTypes.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/SubtractiveSynth.hpp"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/transport/TransportController.hpp"
#include "audioapp/modulation/ModulationGraph.hpp"

namespace audioapp {

struct ProjectFileData;

struct TrackState {
    std::string id;
    std::string name;
    std::vector<DeviceState> devices;
    std::vector<MidiClipState> midiClips;
    std::vector<SampleClipState> sampleClips;
    std::vector<AutomationClipState> automationClips;
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
    double loopRegionStartBeat = 0.0;
    double loopRegionEndBeat = 16.0;
    double loopLengthBeats() const { return loopRegionEndBeat - loopRegionStartBeat; }
    bool recordArmed = false;
    MasterTrackState master;
    std::vector<SampleLibraryEntryState> samples;
    std::vector<TrackState> tracks;
    std::vector<LfoState> lfos;
    std::vector<ModulationEdge> modEdges;
};

/// Lightweight transport read for UI polling (no track/device serialization).
struct TransportStateSnapshot {
    double playheadBeats = 0.0;
    bool playing = false;
    int bpm = 120;
    bool loopEnabled = true;
    double loopRegionStartBeat = 0.0;
    double loopRegionEndBeat = 16.0;
    double loopLengthBeats() const { return loopRegionEndBeat - loopRegionStartBeat; }
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
    bool removeDeviceFromTrack(const std::string& deviceId);
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
    std::string createAutomationClip(const std::string& trackId,
                                     double startBeat,
                                     double lengthBeats);
    bool assignAutomationTarget(const std::string& clipId,
                                const std::string& deviceId,
                                const std::string& paramId);
    bool setAutomationPoints(const std::string& clipId,
                             const std::vector<AutomationPointState>& points);
    bool setLoopEnabled(bool enabled);
    bool setLoopLengthBeats(double lengthBeats);
    bool setLoopRegion(double startBeat, double endBeat);
    std::vector<float> renderOffline(double lengthBeats, double sampleRate);

    bool setRecordArmed(bool armed);
    int createLfo(int modulatorType = 0);
    bool removeLfo(int lfoId);
    bool updateLfoParam(int lfoId, const std::string& param, float value);
    bool assignModulation(int lfoId, const std::string& deviceId, const std::string& paramId, float amount);
    bool removeModulation(int lfoId, const std::string& paramId);

    struct SubtractivePresetLfoSpec {
        int waveform = 0;
        float rate = 1.0f;
        int syncDivision = 0;
        float phase = 0.0f;
        int polarity = 0;
    };

    struct SubtractivePresetModSpec {
        int lfoIndex = 0;
        std::string paramId;
        float amount = 0.0f;
    };

    /// Replace subtractive synth params and device-local LFO/mod routing (Bitwig-style preset load).
    bool applySubtractiveSynthPreset(
        const std::string& deviceId,
        const std::vector<std::pair<std::string, float>>& params,
        const std::vector<SubtractivePresetLfoSpec>& lfos,
        const std::vector<SubtractivePresetModSpec>& mods);

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
    TransportStateSnapshot transportState() const noexcept;

    ProjectFileData toProjectFileData() const;
    bool loadFromProjectFileData(const ProjectFileData& data);

private:
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
        BiquadState samplerFilterStates[kMaxDevicesPerTrack * kMaxInstrumentRegions];
        SubtractiveSynthRuntime subtractiveRuntimes[kMaxDevicesPerTrack];
        KickGeneratorRuntime kickRuntimes[kMaxDevicesPerTrack];
        SnareGeneratorRuntime snareRuntimes[kMaxDevicesPerTrack];
        ClapGeneratorRuntime clapRuntimes[kMaxDevicesPerTrack];
        CymbalGeneratorRuntime cymbalRuntimes[kMaxDevicesPerTrack];
        CrashGeneratorRuntime crashRuntimes[kMaxDevicesPerTrack];
        DynamicsRuntime dynamicsRuntimes[kMaxDevicesPerTrack];
        float oscillatorPhase = 0.0f;
        int modEdgeCount = 0;
        ModulationEdgePlayback modEdges[16];
        int automationClipCount = 0;
        AutomationClipPlayback automationClips[16];
    };

    static constexpr int kMaxTracks = 8;

    mutable std::shared_mutex mutex_;
    std::string projectName_ = "Untitled";
    TransportController transport_;
    TrackRepository trackRepo_;
    ClipRepository clipRepo_{trackRepo_};
    std::atomic<float> activeFrequencyHz_{440.0f};
    std::atomic<float> masterGain_{1.0f};
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

    DeviceMeterAtomic deviceMeters_[kMaxDeviceMeters];
    std::string deviceMeterIds_[kMaxDeviceMeters];
    int deviceMeterSlotCount_ = 0;

    static constexpr int kMaxAutomationClips = 32;
    // Global automation playback array (per-track resolution happens in rebuildAutomationPlaybackLocked)
    // Now per-track: see TrackPlaybackSnapshot::automationClips
    // ModulationEdgePlayback arrays are also per-track: see TrackPlaybackSnapshot::modEdges

    void rebuildTrackPlaybackLocked();
    void rebuildAutomationPlaybackLocked();
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
    void applyLiveDeviceMetersLocked(ProjectSnapshot& snap) const;
    const DeviceNodePlayback* findOscillatorNode(const TrackPlaybackSnapshot& track) const noexcept;
    DeviceSlot* findDeviceLocked(const std::string& deviceId);
    bool buildLiveInstrumentForTrack(const Track& track, LiveInstrumentSnapshot& out) const;
    double sampleTimeToCaptureBeat(uint64_t sampleTime) const;
    const SampleBank* sampleBank_ = nullptr;

    ModulationGraph modulationGraph_;

    DeviceRegistry deviceRegistry_{DeviceRegistry::createBuiltIn()};
};

} // namespace audioapp
