#pragma once

#include "audioapp/FallbackPreviewOscillator.hpp"
#include "audioapp/LivePerformance.hpp"
#include "audioapp/MidiClipPlayback.hpp"
#include "audioapp/ProjectEngine.hpp"
#include "audioapp/SampleBank.hpp"
#include "audioapp/WavetableBank.hpp"
#include "audioapp/SamplePlaybackAlgorithm.hpp"
#include "audioapp/SubtractiveSynthAlgorithm.hpp"
#include "audioapp/SamplePlaybackAlgorithm.hpp"
#include "audioapp/SamplerFilter.hpp"
#include "audioapp/commands/CommandRegistry.hpp"

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
    /// Import wavetable from raw .wav bytes. Returns wavetable name on success, empty on failure.
    std::string importWavetable(const std::string& name, const std::vector<uint8_t>& wavBytes);
    /// Access the wavetable bank.
    const WavetableBank& wavetableBank() const noexcept { return wavetableBank_; }
    WavetableBank& wavetableBank() noexcept { return wavetableBank_; }
    void previewSample(const std::string& sampleId);
    /// Preview MIDI clip — plays through fallback oscillator.
    void previewMidi(const std::vector<MidiNoteState>& notes, double lengthBeats, int bpm, double startBeat = 0.0, bool loop = true);
    /// Preview preset — plays through virtual synth.
    void previewPreset(const std::string& deviceType, const std::vector<std::pair<std::string, float>>& params, const std::vector<MidiNoteState>& notes, double lengthBeats, int bpm, double startBeat = 0.0, bool loop = true);
    /// Stop any active MIDI preview.
    void stopPreview();
    void ensureAudioOutput();

    bool setRecordArmed(bool armed);
    bool undo();
    bool redo();
    int createLfo(int modulatorType = 0);
    bool removeLfo(int lfoId);
    bool updateLfoParam(int lfoId, const std::string& param, float value);
    bool batchUpdateLfoParams(int lfoId, const std::vector<std::pair<std::string, float>>& params);
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
    std::string getDeviceConfigsJson(const std::vector<std::string>& deviceIds) const;

    /// Returns lightweight meter-only JSON for streaming.
    /// Format: {"ok":true,"meters":{"dev-1":{"gr":-3.5,"in":0.85},"dev-2":{...}}}
    std::string getDeviceMetersJson();

    /// Returns param descriptor metadata for a device type as JSON.
    /// Format: {"ok":true, "deviceType":"sampler", "params":[...], "protocolVersion":1}
    std::string getParamDescriptorsJson(const std::string& deviceType) const;

    /// Access the command registry for bridge dispatch.
    commands::CommandRegistry& commandRegistry() { return commandRegistry_; }
    const commands::CommandRegistry& commandRegistry() const { return commandRegistry_; }
    /// Register all built-in commands. Called once from constructors.
    void registerAllCommands();

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
    void readPreviewMix(float* leftOut, float* rightOut, int numFrames, double sampleRate) noexcept;
    void readLiveMix(float* monoOut, int numFrames, double sampleRate) noexcept;

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
    std::unique_ptr<ProjectEngine> project_;
    SampleBank sampleBank_;
    WavetableBank wavetableBank_;
    int nextImportSampleNum_ = 1;
    commands::CommandRegistry commandRegistry_;

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
        bool isPresetPreview = false;
        bool loop = true;
        /// For live-keyboard preview (noteOn/noteOff path) — one LiveInstrumentSnapshot
        /// shared across all voices. Unused for preset preview.
        LiveInstrumentSnapshot instrument;
        std::vector<MidiNoteState> notes;
        std::vector<bool> noteUsingInstrument;
        double lengthBeats = 4.0;
        int bpm = 120;
        std::atomic<double> playheadBeats{0.0};

        // --- Preset-preview direct-renderer state ---
        // Mirrors the per-sample renderers used by the arrangement playback
        // (processDeviceChain → mixSubtractiveMidiNotesBlock / mixSamplerMidiNotesBlock /
        //  midiActiveFrequencyHz + addSineBlock). All runtimes are written on the
        // control thread (previewPreset) and read on the audio thread (readPreviewMix).

        /// Which direct renderer the preset preview should use.
        enum class PresetRenderKind : uint8_t {
            None = 0,
            Oscillator,
            Sampler,
            SubtractiveSynth,
        };
        std::atomic<PresetRenderKind> renderKind{PresetRenderKind::None};

        /// SubtractiveSynth preset params (built from DeviceRegistry + preset params).
        SubtractiveSynthParams subtractiveParams{};
        SubtractiveSynthRuntime subtractiveRuntime{};

        /// Oscillator: only frequency + phase continuity.
        float oscillatorPhase = 0.0f;

        /// Sampler preset params + filter state.
        SamplerInstrumentPlayback samplerParams{};
        BiquadState samplerFilterStates[kMaxInstrumentRegions]{};
        bool samplerHasPcm = false;

        /// All preset-preview notes are projected onto a single "virtual clip" that
        /// starts at beat 0 and loops over lengthBeats. This matches how the arrangement
        /// renderer expects note regions (clipStartBeat / clipLengthBeats / noteStartBeat).
        std::vector<MidiPlaybackNote> playbackNotes;
    };

    PreviewMidiState previewMidi_;
    LivePerformanceMixer previewMixer_;
    FallbackPreviewOscillator fallbackOsc_;
    void ensureSampleBankReady();
};

} // namespace audioapp
