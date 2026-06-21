#pragma once

#include "audioapp/FallbackPreviewOscillator.hpp"
#include "audioapp/MidiClipPlayback.hpp"
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
    /// `trackId` is the home track the clip is rendered on in the
    /// arrangement view. The target device is set later via
    /// `assignAutomationTarget` and may live on any track.
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
    /// Preview MIDI clip — plays through fallback oscillator.
    void previewMidi(const std::vector<MidiNoteState>& notes, double lengthBeats, int bpm);
    /// Stop any active MIDI preview.
    void stopPreview();
    void ensureAudioOutput();

    bool setRecordArmed(bool armed);
    int createLfo(int modulatorType = 0);
    bool removeLfo(int lfoId);
    bool updateLfoParam(int lfoId, const std::string& param, float value);
    bool assignModulation(int lfoId, const std::string& deviceId, const std::string& paramId, float amount);
    bool removeModulation(int lfoId, const std::string& paramId);
    bool applySubtractiveSynthPreset(
        const std::string& deviceId,
        const std::vector<std::pair<std::string, float>>& params,
        const std::vector<ProjectEngine::SubtractivePresetLfoSpec>& lfos,
        const std::vector<ProjectEngine::SubtractivePresetModSpec>& mods);
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
    /// Returns JSON for a subset of devices, indexed by their deviceId.
    /// Used for selective frontend polling.
    /// Format: { "ok": true, "devices": { "dev-1": { "type":"...", "parameters":{...}, "meters":{...} }, ... } }
    std::string getDeviceStatesJson(const std::vector<std::string>& deviceIds) const;

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
    std::unique_ptr<ProjectEngine> project_;
    SampleBank sampleBank_;
    int nextImportSampleNum_ = 1;

    struct PreviewVoice {
        std::atomic<bool> active{false};
        std::atomic<int> position{0};
        const float* pcmData = nullptr;
        int pcmSize = 0;
        std::atomic<double> sampleRate{48000.0};
    };

    PreviewVoice previewVoice_;
    /// Holds sample PCM data alive while preview is active (shared_ptr prevents UAF
    /// if a new preview overwrites pcmData while the audio thread is still reading).
    std::shared_ptr<const std::vector<float>> previewBuffer_;

    struct PreviewMidiState {
        std::atomic<bool> active{false};
        std::vector<MidiNoteState> notes;
        double lengthBeats = 4.0;
        int bpm = 120;
        std::atomic<double> playheadBeats{0.0};
    };

    PreviewMidiState previewMidi_;
    FallbackPreviewOscillator fallbackOsc_;
    void ensureSampleBankReady();
};

} // namespace audioapp
