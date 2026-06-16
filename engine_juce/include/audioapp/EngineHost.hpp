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
    std::string addDeviceToTrack(const std::string& trackId, const std::string& deviceType);
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
    std::string importWavSample(const std::string& displayName, const std::vector<uint8_t>& wavBytes);
    void previewSample(const std::string& sampleId);
    void ensureAudioOutput();

    /// Desktop / tests: `.audioapp.zip` I/O via ProjectArchive.cpp (ADR-0006).
    bool saveProject(const std::string& archivePath);
    bool loadProject(const std::string& archivePath);

    /// All platforms: serialize in-memory project to `project.json` text.
    std::string getProjectFileJson() const;
    /// All platforms: restore project from `project.json` text.
    bool loadProjectFileJson(const std::string& json);

    std::string getProjectSnapshotJson() const;

    void advancePlayheadForBlock(int numFrames, double sampleRate) noexcept;
    float activeOscillatorFrequencyHz() const;
    void setPlayheadBeats(double beats) noexcept;
    void readMasterMix(float* monoOut,
                       int numFrames,
                       double sampleRate,
                       double playheadStartBeat) noexcept;
    double playheadBeats() const noexcept;
    void readPreviewMix(float* monoOut, int numFrames, double sampleRate) noexcept;

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
