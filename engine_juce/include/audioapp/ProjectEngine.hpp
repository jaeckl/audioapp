#pragma once

#include <atomic>
#include <mutex>
#include <array>
#include <cstdint>
#include <memory>
#include <string>
#include <thread>
#include <vector>

#include "audioapp/AutomationTypes.hpp"
#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/model/TrackModel.hpp"
#include "audioapp/model/TrackRepository.hpp"
#include "audioapp/model/ClipRepository.hpp"
#include "audioapp/model/AutomationClipStore.hpp"
#include "audioapp/state/ProjectTree.hpp"
#include "audioapp/state/UndoCommands.hpp"
#include "audioapp/ModulationTypes.hpp"
#include "audioapp/LivePerformance.hpp"
#include "audioapp/MidiClipPlayback.hpp"
#include "audioapp/SampleBank.hpp"
#include "audioapp/TrackFreezeAssetStore.hpp"
#include "audioapp/WavetableBank.hpp"
#include "audioapp/SampleTypes.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/ProcessorGraph.hpp"
#include "audioapp/dsp/ProcessorArena.hpp"
#include "audioapp/SubtractiveSynthAlgorithm.hpp"
#include "audioapp/PhaseModSynthAlgorithm.hpp"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/transport/TransportController.hpp"
#include "audioapp/modulation/ModulationGraph.hpp"

namespace audioapp {

struct ProjectFileData;
struct DeviceChainScratch;

/// Live meter readouts for dynamics devices (gate, compressor, expander, limiter).
/// Populated by applyLiveDeviceMetersLocked() during snapshot building.
/// Not persisted to project files — runtime-only.
struct DeviceMeterState {
    std::string deviceId;
    float gainReductionDb = 0.0f;
    float inputLevel = 0.0f;
};

struct TrackFreezeState {
    bool enabled = false;
    bool stale = false;
    std::string assetId;
    double startBeat = 0.0;
    double lengthBeats = 0.0;
    double sampleRate = 48000.0;
    int bpmAtFreeze = 120;
    uint64_t contentSignature = 0;
    std::vector<float> waveformPeaks;
};

struct TrackState {
    std::string id;
    std::string name;
    std::string iconKey;
    bool isGroup = false;
    bool muted = false;
    bool soloed = false;
    std::string parentGroupId;
    std::vector<DeviceSlot> devices;
    /// Parallel meter array by deviceId. Only populated for snapshot serialization.
    std::vector<DeviceMeterState> deviceMeters;
    std::vector<MidiClipState> midiClips;
    std::vector<SampleClipState> sampleClips;
    TrackFreezeState freeze;
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
    std::vector<ModulationGraph::ModulatorRecord> lfos;
    std::vector<ModulationEdge> modEdges;
    /// Global automation-clip store.
    std::vector<AutomationClipState> automationClips;
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
class ProjectEngine : private juce::ValueTree::Listener {
public:
    void createProject();
    std::string addTrack(const std::string& name);
    std::string addGroupTrack(const std::string& name);
    bool setTrackGroup(const std::string& trackId, const std::string& groupTrackId);
    bool moveTrack(const std::string& trackId,
                   const std::string& parentGroupId,
                   const std::string& beforeTrackId);
    bool setTrackMuted(const std::string& trackId, bool muted);
    bool setTrackSoloed(const std::string& trackId, bool soloed);
    bool selectTrack(const std::string& trackId);
    std::string addDeviceToTrack(const std::string& trackId,
                                 const std::string& deviceType,
                                 int insertIndex = -1);
    bool removeDeviceFromTrack(const std::string& deviceId);
    std::string addDeviceToDrumPad(const std::string& drumMachineId, int note,
                                   const std::string& deviceType, int insertIndex = -1,
                                   const std::string& padName = {});
    bool removeDeviceFromDrumPad(const std::string& drumMachineId, int note,
                                 const std::string& deviceId);
    std::string addDeviceToChain(const std::string& chainId, const std::string& deviceType,
                                 int insertIndex = -1);
    bool removeDeviceFromChain(const std::string& chainId, const std::string& deviceId);
    std::string addDeviceToSynthAudioFx(const std::string& deviceId,
                                        const std::string& deviceType,
                                        int insertIndex = -1);
    bool removeDeviceFromSynthAudioFx(const std::string& deviceId,
                                      const std::string& subDeviceId);
    std::string addDeviceToSynthNoteFx(const std::string& deviceId,
                                       const std::string& deviceType,
                                       int insertIndex = -1);
    bool removeDeviceFromSynthNoteFx(const std::string& deviceId,
                                     const std::string& subDeviceId);
    std::string getDevicePresetJson(const std::string& deviceId) const;
    bool applyDevicePresetJson(const std::string& deviceId, const std::string& presetJson);
    bool setDrumPadParameter(const std::string& drumMachineId, int note,
                             const std::string& parameterId, float value);
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
    bool addMidiClipTake(const std::string& clipId,
                         const std::string& name,
                         double startBeatOffset,
                         double lengthBeats,
                         const std::vector<MidiNoteState>& notes);
    bool setMidiClipTakeRegionTake(const std::string& clipId,
                                   int regionIndex,
                                   const std::string& takeId);
    bool setMidiClipTakeAtBeat(const std::string& clipId,
                               double beat,
                               const std::string& takeId);
    bool splitMidiClipTakeRegionAtBeat(const std::string& clipId,
                                       double beat);
    bool moveMidiClipTakeMarker(const std::string& clipId,
                                int markerIndex,
                                double beat);
    bool setMidiClipTakeMarkerMode(const std::string& clipId,
                                   int markerIndex,
                                   bool holdPrevious);
    bool flattenMidiComp(const std::string& clipId);
    bool reopenMidiComp(const std::string& clipId);
    bool deleteMidiClipTakeMarker(const std::string& clipId,
                                  int markerIndex);
    bool setMidiClipEditorScale(const std::string& clipId,
                                int root,
                                const std::string& scaleId,
                                bool highlight,
                                bool snap,
                                const std::string& chordQuality);
    std::string createSampleClip(const std::string& trackId,
                                 const std::string& sampleId,
                                 double startBeat,
                                 double lengthBeats);
    std::string createRecordingSampleClipModelOnly(const std::string& trackId,
                                                   const std::string& sampleId,
                                                   double startBeat,
                                                   double lengthBeats);
    bool moveClip(const std::string& clipId,
                  const std::string& targetTrackId,
                  double startBeat);
    bool setClipLength(const std::string& clipId,
                       double lengthBeats,
                       ClipLengthTarget target = ClipLengthTarget::Arrangement);
    bool setClipLoopContent(const std::string& clipId, bool loopContent);
    bool setSampleClipProperties(const std::string& clipId, float sourceStart,
                                 float sourceEnd, float gain, float fadeIn,
                                 float fadeOut, float fadeInCurve,
                                 float fadeOutCurve, bool reversed);
    bool setSampleClipWarp(const std::string& clipId, bool warpRepitch);
    bool setSampleClipSlices(const std::string& clipId, const std::vector<float>& markers);
    bool updateSampleClipRecordedLength(const std::string& clipId, double lengthBeats);
    bool addRecordingTakeToSampleClip(const std::string& clipId,
                                      const std::string& sampleId,
                                      const std::string& name,
                                      double recordStartBeat,
                                      double lengthBeats);
    bool updateSampleClipRecordedTakeLength(const std::string& clipId,
                                            const std::string& sampleId,
                                            double lengthBeats);
    bool updateSampleClipRecordedTakeLengthModelOnly(const std::string& clipId,
                                                     const std::string& sampleId,
                                                     double lengthBeats);
    bool removeRecordingTakeFromSampleClip(const std::string& clipId,
                                           const std::string& sampleId);
    bool setSampleClipTakeRegionTake(const std::string& clipId,
                                     int regionIndex,
                                     const std::string& takeId);
    bool setSampleClipTakeAtBeat(const std::string& clipId,
                                 double beat,
                                 const std::string& takeId);
    bool splitSampleClipTakeRegionAtBeat(const std::string& clipId,
                                         double beat);
    bool moveSampleClipTakeMarker(const std::string& clipId,
                                  int markerIndex,
                                  double beat);
    bool deleteSampleClipTakeMarker(const std::string& clipId,
                                    int markerIndex);
    std::string exportSampleClipSlices(const std::string& clipId, int firstNote);
    bool setBpm(int bpm);
    int bpm() const noexcept;
    void setMetronome(bool enabled, float level, int countInBars) noexcept;
    bool deleteTrack(const std::string& trackId);
    bool deleteClip(const std::string& clipId);
    bool duplicateClip(const std::string& clipId);
    /// Creates a new automation clip in the global store. `homeTrackId`
    /// is the track the clip is rendered on in the arrangement view — the
    /// target device can live on any track.
    std::string createAutomationClip(const std::string& homeTrackId,
                                     double startBeat,
                                     double lengthBeats);
    bool assignAutomationTarget(const std::string& clipId,
                                const std::string& deviceId,
                                const std::string& paramId);
    bool unlinkAutomationTarget(const std::string& clipId);
    bool setAutomationPoints(const std::string& clipId,
                             const std::vector<AutomationPointState>& points);
    bool setLoopEnabled(bool enabled);
    bool setLoopLengthBeats(double lengthBeats);
    bool setLoopRegion(double startBeat, double endBeat);
    std::vector<float> renderOffline(double lengthBeats, double sampleRate);
    bool freezeTrack(const std::string& trackId, TrackFreezeAssetStore& assets);
    bool unfreezeTrack(const std::string& trackId, TrackFreezeAssetStore& assets);
    bool refreshTrackFreeze(const std::string& trackId, TrackFreezeAssetStore& assets);
    void ensureFrozenAssets(TrackFreezeAssetStore& assets);
    bool isTrackFrozen(const std::string& trackId) const;

    bool setRecordArmed(bool armed);
    int createLfo(int modulatorType = 0,
                  const std::string& ownerDeviceId = {});
    bool removeLfo(int lfoId);
    bool updateLfoParam(int lfoId, const std::string& param, float value);
    bool batchUpdateLfoParams(int lfoId, const std::vector<std::pair<std::string, float>>& params);
    bool assignModulation(int lfoId, const std::string& deviceId, const std::string& paramId, float amount);
    bool removeModulation(int lfoId, const std::string& deviceId, const std::string& paramId);

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
    bool beginMidiRecordingSession(const std::string& trackId,
                                   double startBeat,
                                   double quantizeStep);
    bool finishMidiRecordingSession(double endBeat = -1.0);
    void cancelMidiRecordingSession();
    void readLiveMix(float* monoOut, int numFrames, double sampleRate) noexcept;
    bool hasLiveVoices() const noexcept;
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

    void setSampleBank(SampleBank* bank) { sampleBank_ = bank; }
    const SampleBank* sampleBank() const noexcept { return sampleBank_; }
    SampleBank* sampleBank() noexcept { return sampleBank_; }
    void setWavetableBank(const WavetableBank* bank) { wavetableBank_ = bank; }
    void setFreezeAssetStore(const TrackFreezeAssetStore* store) { freezeAssetStore_ = store; }

    /// Expose the device registry for serialization dispatch.
    const DeviceRegistry& deviceRegistry() const { return deviceRegistry_; }

    /// Lightweight meter-only JSON (no project snapshot).
    /// Reads atomics directly. Format: {"ok":true,"meters":{"dev-1":{"gr":-3.5,"in":0.85}}}
    std::string getDeviceMetersJson();
    void setMeterSubscriptions(const std::vector<std::string>& deviceIds);

    /// Runtime-only observers on device, track/group, or master output ports.
    /// targetId may identify a device output, a track/group output, or "master".
    std::string createGraphTap(const std::string& targetId,
                               GraphTapKind kind,
                               uint32_t capacityFrames = kGraphTapDefaultRecorderFrames,
                               GraphTapPort port = GraphTapPort::Output);
    bool removeGraphTap(const std::string& tapId);
    std::string readGraphTapJson(const std::string& tapId, int maxFrames = 512);
    std::string readEffectiveParameterJson(const std::string& deviceId,
                                           const std::string& parameterId);
    std::string readEffectiveParametersJson(
        const std::vector<std::pair<std::string, std::string>>& requests);

    /// Expose modulator types for serialization dispatch.
    const std::vector<std::unique_ptr<IModulatorType>>& modulatorTypes() const {
        return modulationGraph_.modulatorTypes();
    }

    void setPlaying(bool playing);
    bool isPlaying() const noexcept;
    double playheadBeats() const noexcept;
    void setPlayheadBeats(double beats) noexcept;
    void resetPlayhead() noexcept;
    void advancePlayhead(int numFrames, double sampleRate) noexcept;
    TransportStateSnapshot transportState() const noexcept;

    ProjectFileData toProjectFileData() const;
    bool loadFromProjectFileData(const ProjectFileData& data);

    /// Undo / redo support.
    bool undo();
    bool redo();
    juce::UndoManager& undoManager() { return undoManager_; }

private:
    struct PlaybackNote {
        int pitch = 60;
        double clipStartBeat = 0.0;
        double clipLengthBeats = 4.0;
        double noteStartBeat = 0.0;
        double noteDurationBeats = 1.0;
        float velocity = 100.0f;
        bool loopContent = false;
        double contentLengthBeats = 4.0;
    };

    struct SampleRegion {
        double clipStartBeat = 0.0;
        double clipLengthBeats = 4.0;
        const float* pcm = nullptr;
        int frameCount = 0;
        double pcmSampleRate = 48000.0;
        bool loopContent = false;
        double contentLengthBeats = 4.0;
        float sourceStart = 0.0f;
        float sourceEnd = 1.0f;
        float gain = 1.0f;
        float fadeIn = 0.0f;
        float fadeOut = 0.0f;
        float fadeInCurve = 0.5f;
        float fadeOutCurve = 0.5f;
        bool reversed = false;
    };

    static constexpr int kMaxTracks = 8;

    struct TrackPlaybackSnapshot {
        std::string trackId;
        uint64_t outputNodeId = 0;
        bool outputTapActive = false;
        int parentGroupTrackIndex = -1;
        bool muted = false;
        bool soloed = false;
        float audibilityGain = 1.0f;
        int noteCount = 0;
        PlaybackNote notes[256];
        int regionCount = 0;
        SampleRegion regions[8];
        int deviceCount = 0;
        DeviceNodePlayback devices[kMaxDevicesPerTrack];
        CompiledDeviceExecutionOrder deviceExecutionOrder;
        int modEdgeCount = 0;
        ModulationEdgePlayback modEdges[16];
        int automationClipCount = 0;
        AutomationClipPlayback automationClips[16];
        ProcessorArena arena;  // processors + runtime state
        struct FreezePlayback {
            bool active = false;
            const float* pcmL = nullptr;
            const float* pcmR = nullptr;
            int frameCount = 0;
            double pcmSampleRate = 48000.0;
            double startBeat = 0.0;
            double lengthBeats = 0.0;
        } freeze;
        int trackGainDeviceIndex = -1;
    };

    struct PlaybackStateStorage {
        TrackPlaybackSnapshot states[2][kMaxTracks];
        std::atomic<int> active{0};
        std::atomic<int> pending{-1};
        std::atomic<int> readers[2]{};
        int counts[2]{};
        int graphIndices[2]{};
        inline static thread_local int buildIndex = -1;
        inline static thread_local int readIndex = -1;

        int selectedIndex() const noexcept {
            if (buildIndex >= 0) return buildIndex;
            if (readIndex >= 0) return readIndex;
            return active.load(std::memory_order_acquire);
        }
        TrackPlaybackSnapshot& operator[](int index) noexcept {
            return states[selectedIndex()][index];
        }
        const TrackPlaybackSnapshot& operator[](int index) const noexcept {
            return states[selectedIndex()][index];
        }
        int count() const noexcept { return counts[selectedIndex()]; }
        void setCount(int count) noexcept { counts[selectedIndex()] = count; }
        int graphIndexForState(int state) const noexcept { return graphIndices[state]; }
        void setSelectedGraphIndex(int index) noexcept {
            graphIndices[selectedIndex()] = index;
        }

        int commitPending() noexcept {
            const int next = pending.exchange(-1, std::memory_order_acq_rel);
            if (next >= 0) active.store(next, std::memory_order_release);
            return next;
        }
        int beginBuild() noexcept {
            const int committed = commitPending();
            const int target = 1 - active.load(std::memory_order_acquire);
            while (readers[target].load(std::memory_order_acquire) != 0)
                std::this_thread::yield();
            buildIndex = target;
            return committed;
        }
        int publishBuild(bool immediate) noexcept {
            const int built = buildIndex;
            buildIndex = -1;
            if (immediate) active.store(built, std::memory_order_release);
            else pending.store(built, std::memory_order_release);
            return built;
        }

        struct ReadGuard {
            PlaybackStateStorage& storage;
            int index = 0;
            explicit ReadGuard(PlaybackStateStorage& owner) noexcept : storage(owner) {
                for (;;) {
                    index = storage.active.load(std::memory_order_acquire);
                    storage.readers[index].fetch_add(1, std::memory_order_acq_rel);
                    if (index == storage.active.load(std::memory_order_acquire)) break;
                    storage.readers[index].fetch_sub(1, std::memory_order_release);
                }
                readIndex = index;
            }
            ~ReadGuard() {
                readIndex = -1;
                storage.readers[index].fetch_sub(1, std::memory_order_release);
            }
            ReadGuard(const ReadGuard&) = delete;
            ReadGuard& operator=(const ReadGuard&) = delete;
        };
    };

    enum class RealtimeCommandType : uint8_t {
        DeviceNode,
        TrackMute,
        TrackSolo,
        DrumPad,
        ResolvedAsset,
    };

    struct RealtimeCommand {
        RealtimeCommandType type = RealtimeCommandType::DeviceNode;
        DeviceNodePlayback node{};
        std::string targetId;
        DrumPadParameter drumPadParameter = DrumPadParameter::Invalid;
        ResolvedAssetUpdate resolvedAsset{};
        uint64_t targetNodeId = 0;
        float value = 0.0f;
        int note = 0;
        bool commonOnly = false;
    };

    // Single-producer/single-consumer queue. The control thread owns writes and
    // the audio thread owns reads. Slots are preallocated, so consuming a
    // command never allocates or waits for the control thread.
    static constexpr uint32_t kRealtimeCommandCapacity = 512;
    struct RealtimeCommandQueue {
        std::array<RealtimeCommand, kRealtimeCommandCapacity> entries{};
        std::atomic<uint32_t> head{0};
        std::atomic<uint32_t> tail{0};
    };

    mutable juce::ReadWriteLock mutex_;
    // Protects the processor arenas and playback snapshots from control-thread
    // rebuilds/parameter writes while the audio callback is using them.  The
    // audio thread only ever try-locks this mutex, so it can never block behind
    // project editing work.
    mutable std::recursive_mutex playbackMutex_;
    RealtimeCommandQueue realtimeCommands_;
    struct RealtimeParameterCommand {
        uint64_t targetNodeId = 0;
        uint16_t encodedParameterId = 0;
        float value = 0.0f;
        float startValue = std::numeric_limits<float>::quiet_NaN();
        ParameterUpdateRate rate = ParameterUpdateRate::Smoothed;
    };
    struct RealtimeParameterQueue {
        std::array<RealtimeParameterCommand, kRealtimeCommandCapacity> entries{};
        std::atomic<uint32_t> head{0};
        std::atomic<uint32_t> tail{0};
    };
    RealtimeParameterQueue realtimeParameterMailbox_;
    std::atomic<uint64_t> realtimeCommandOverflowCount_{0};
    std::string projectName_ = "Untitled";
    TransportController transport_;
    TrackRepository trackRepo_;
    ClipRepository clipRepo_{trackRepo_};
    std::atomic<float> activeFrequencyHz_{440.0f};
    std::atomic<float> masterGain_{1.0f};
    // Audio-thread-owned ramp origin. Control writes only masterGain_.
    float smoothedMasterGain_ = 1.0f;
    std::atomic<bool> metronomeEnabled_{false};
    std::atomic<float> metronomeLevel_{0.65f};
    std::atomic<int> countInBars_{1};
    std::atomic<double> countInRemainingBeats_{0.0};
    bool recordArmed_ = false;

    struct CaptureEvent {
        enum class Type { NoteOn, NoteOff };
        Type type = Type::NoteOn;
        int pitch = 60;
        float velocity = 100.0f;
        uint64_t sampleTime = 0;
    };
    static constexpr int kMaxCaptureEvents = 4096;
    std::array<CaptureEvent, kMaxCaptureEvents> captureEvents_;
    int captureEventHead_ = 0;
    int captureEventCount_ = 0;
    uint64_t captureStartSample_ = 0;
    double captureStartPlayheadBeat_ = 0.0;
    double captureQuantizeStep_ = 0.25;
    std::string captureTrackId_;
    bool captureActive_ = false;
    LivePerformanceMixer liveMixer_;
    std::atomic<float> livePitchBend_{0.0f};
    std::atomic<float> liveModulation_{0.0f};

    PlaybackStateStorage trackPlayback_;
    ProcessorGraphSnapshot processorGraphs_[2];
    std::atomic<int> activeProcessorGraph_{0};
    int lastBuiltProcessorGraph_ = 0; // control thread only
    struct GraphTapRegistration {
        enum class SourceScope : uint8_t { Device, Track, Master };
        bool active = false;
        std::string tapId;
        std::string targetId;
        SourceScope sourceScope = SourceScope::Device;
        uint64_t sourceOutputNodeId = 0;
        GraphTapKind kind = GraphTapKind::None;
        GraphTapPort port = GraphTapPort::Output;
        uint32_t capacityFrames = kGraphTapDefaultRecorderFrames;
        uint32_t generation = 0;
    };
    std::array<GraphTapRegistration, kMaxProcessorGraphTaps> graphTapRegistrations_{};
    std::unique_ptr<GraphTapRuntime[]> graphTapRuntimes_ =
        std::make_unique<GraphTapRuntime[]>(kMaxProcessorGraphTaps);
    uint64_t nextGraphTapId_ = 1;
    // Each immutable graph owns a pre-cleared bank. The audio callback never
    // clears delay memory when a live structural edit is published.
    std::unique_ptr<std::array<ProcessorGraphDelayLine, kMaxProcessorGraphEdges>[]>
        graphLatencyLines_ =
            std::make_unique<std::array<ProcessorGraphDelayLine, kMaxProcessorGraphEdges>[]>(2);
    struct GraphFeedbackBank {
        std::array<std::array<float, kMaxProcessorGraphBlockFrames>,
                   kMaxProcessorGraphFeedbackEdges> left[2]{};
        std::array<std::array<float, kMaxProcessorGraphBlockFrames>,
                   kMaxProcessorGraphFeedbackEdges> right[2]{};
        int readIndex = 0;
    };
    // Like latency lines, feedback state is tied to the immutable graph it
    // belongs to, so a new route never consumes a stale predecessor block.
    std::unique_ptr<GraphFeedbackBank[]> graphFeedbackBanks_ =
        std::make_unique<GraphFeedbackBank[]>(2);

    DeviceMeterAtomic deviceMeters_[kMaxDeviceMeters];
    std::string deviceMeterIds_[kMaxDeviceMeters];
    std::array<bool, kMaxDeviceMeters> meterSlotSubscribed_{};
    int deviceMeterSlotCount_ = 0;

    static constexpr int kMaxAutomationClips = 32;
    // Global automation playback array (per-track resolution happens in rebuildAutomationPlaybackLocked)
    //
    // Now per-track: see TrackPlaybackSnapshot::automationClips
    // ModulationEdgePlayback arrays are also per-track: see TrackPlaybackSnapshot::modEdges

    void rebuildTrackPlaybackLocked();
    bool enqueueRealtimeCommand(RealtimeCommand command) noexcept;
    bool enqueueRealtimeParameter(RealtimeParameterCommand command) noexcept;
    void drainRealtimeCommands() noexcept;
    void drainRealtimeParameters() noexcept;
    bool applyRealtimeDeviceNode(const DeviceNodePlayback& node,
                                 bool commonOnly) noexcept;
    bool applyRealtimeDeviceParameter(uint64_t targetNodeId,
                                      uint16_t encodedParameterId,
                                      float value,
                                      float startValue,
                                      ParameterUpdateRate rate) noexcept;
    void rebuildProcessorGraphLocked(int trackCount);
    void rebuildRepoCacheFromTree();
    void syncProjectTreeLocked();
    /// Lightweight edge re-resolution: re-populates per-track snap.modEdges[]
    /// from the global modulationGraph_ edge list without touching DSP processors
    /// or any other playback state. Safe to call during live playback.
    void rebuildModEdgesLocked();
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
    void mixTrackPreGainStereo(int trackIndex,
                               float* trackLeft,
                               float* trackRight,
                               int numFrames,
                               double sampleRate,
                               double playheadStartBeat,
                               const float* lfoValues,
                               int lfoCount,
                               IModulator* const* modulators,
                               uint32_t retriggerGeneration) noexcept;
    void mixTrackPreGainStereoWithArena(const TrackPlaybackSnapshot& track,
                                        ProcessorArena& arena,
                                        float* trackLeft,
                                        float* trackRight,
                                        int numFrames,
                                        double sampleRate,
                                        double playheadStartBeat,
                                        const float* lfoValues,
                                        int lfoCount,
                                        IModulator* const* modulators,
                                        uint32_t retriggerGeneration,
                                        DeviceChainScratch* scratchOverride = nullptr) noexcept;
    bool trackHasActiveSampleAtPlayhead(const TrackPlaybackSnapshot& track, double playheadBeat) const noexcept;
    int selectedTrackPlaybackIndex() const noexcept;
    void syncActiveFrequencyLocked();
    void recomputeIdCountersLocked();
    void applyLiveDeviceMetersLocked(ProjectSnapshot& snap) const;
    void clearGraphTapsLocked() noexcept;
    const DeviceNodePlayback* findOscillatorNode(const TrackPlaybackSnapshot& track) const noexcept;
    DeviceSlot* findDeviceLocked(const std::string& deviceId);
    bool buildLiveInstrumentForTrack(const Track& track, int pitch,
                                     LiveInstrumentSnapshot& out) const;
    double sampleTimeToCaptureBeat(uint64_t sampleTime) const;
    bool freezeTrackLocked(Track& track, int trackIndex, TrackFreezeAssetStore& assets);

    void reconcileTrackFreezeStaleLocked();
    void markDeviceOwnerFreezeStaleLocked(const std::string& deviceId);
    SampleBank* sampleBank_ = nullptr;
    const WavetableBank* wavetableBank_ = nullptr;
    const TrackFreezeAssetStore* freezeAssetStore_ = nullptr;

    // ── ValueTree::Listener overrides ─────────────────────────
    void valueTreePropertyChanged(juce::ValueTree& tree,
                                  const juce::Identifier& property) override;
    void valueTreeChildAdded(juce::ValueTree& parent,
                             juce::ValueTree& child) override;
    void valueTreeChildRemoved(juce::ValueTree& parent,
                               juce::ValueTree& child,
                               int oldIndex) override;

    // ── ValueTree state ──────────────────────────────────────
    juce::ValueTree projectRoot_{state::createProjectTree()};
    /// Re-entrancy guard: set true during rebuildRepoCacheFromTree() so listener
    /// callbacks don't trigger recursive rebuilds.
    bool syncingTree_ = false;
    juce::UndoManager undoManager_;

    ModulationGraph modulationGraph_;
    AutomationClipStore automationClipStore_;

    /// Previous arrangement-mix playhead (audio thread). Used to detect loop wrap.
    double lastArrangementMixPlayhead_ = -1.0;

    DeviceRegistry deviceRegistry_{DeviceRegistry::createBuiltIn()};
};

} // namespace audioapp
