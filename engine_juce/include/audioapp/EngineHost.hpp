#pragma once

#include "audioapp/ProjectEngine.hpp"
#include "audioapp/SampleBank.hpp"

#include <atomic>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

namespace audioapp {

class EngineHost {
public:
    EngineHost();
    ~EngineHost();

    EngineHost(const EngineHost&) = delete;
    EngineHost& operator=(const EngineHost&) = delete;

    std::string ping() const;
    void setPlaying(bool shouldPlay);
    bool isPlaying() const noexcept;

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
    std::string createAutomationClip(const std::string& trackId,
                                     double startBeat,
                                     double lengthBeats);
    bool assignAutomationTarget(const std::string& clipId,
                                const std::string& deviceId,
                                const std::string& paramId);
    bool setAutomationPoints(const std::string& clipId,
                             const std::vector<AutomationPointState>& points);
    bool setBpm(int bpm);
    bool deleteTrack(const std::string& trackId);
    bool deleteClip(const std::string& clipId);
    bool duplicateClip(const std::string& clipId);
    bool setLoopEnabled(bool enabled);
    bool setLoopLengthBeats(double lengthBeats);
    bool setLoopRegion(double startBeat, double endBeat);
    std::vector<float> renderOffline(double lengthBeats, double sampleRate);
    std::string importWavSample(const std::string& displayName, const std::vector<uint8_t>& wavBytes);
    void previewSample(const std::string& sampleId);
    void ensureAudioOutput();

    bool setRecordArmed(bool armed);
    int createLfo();
    bool removeLfo(int lfoId);
    bool updateLfoParam(int lfoId, const std::string& param, float value);
    bool assignModulation(int lfoId, const std::string& deviceId, const std::string& paramId, float amount);
    bool removeModulation(int lfoId, const std::string& paramId);
    bool noteOn(int pitch, float velocity);
    bool noteOff(int pitch);
    void allNotesOff();
    void clearCapture();
    bool commitCapture();
    void enterPlayMode();
    void setPitchBend(float bend) noexcept;
    void setModulation(float mod) noexcept;

    bool saveProject(const std::string& archivePath);
    bool loadProject(const std::string& archivePath);
    std::string getProjectFileJson() const;
    bool loadProjectFileJson(const std::string& json);

    std::string getProjectSnapshotJson() const;
    std::string getTransportStateJson() const;

    void advancePlayheadForBlock(int numFrames, double sampleRate) noexcept;
    float activeOscillatorFrequencyHz() const;
    void setPlayheadBeats(double beats) noexcept;
    void readMasterMix(float* monoOut,
                       int numFrames,
                       double sampleRate,
                       double playheadStartBeat) noexcept;
    void readMasterMixStereo(float* leftOut,
                             float* rightOut,
                             int numFrames,
                             double sampleRate,
                             double playheadStartBeat) noexcept;
    double playheadBeats() const noexcept;
    void readPreviewMix(float* monoOut, int numFrames, double sampleRate) noexcept;
    void readLiveMix(float* monoOut, int numFrames, double sampleRate) noexcept;

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
    ProjectEngine project_;
    SampleBank sampleBank_;
    int nextImportSampleNum_ = 1;

    struct PreviewVoice {
        std::atomic<bool> active{false};
        std::atomic<int> position{0};
        std::vector<float> pcm;
        std::atomic<double> sampleRate{48000.0};
    };

    PreviewVoice previewVoice_;
    void ensureSampleBankReady();
};

} // namespace audioapp
