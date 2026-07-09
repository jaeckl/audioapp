#pragma once

#include <cstdint>
#include <atomic>
#include <cstring>
#include <variant>
#include <memory>

#include "audioapp/AutomationTypes.hpp"
#include "audioapp/KickAlgorithm.hpp"
#include "audioapp/SnareAlgorithm.hpp"
#include "audioapp/ClapAlgorithm.hpp"
#include "audioapp/CymbalAlgorithm.hpp"
#include "audioapp/CrashAlgorithm.hpp"
#include "audioapp/DynamicsProcessor.hpp"
#include "audioapp/ModulationTypes.hpp"
#include "audioapp/SamplerFilter.hpp"
#include "audioapp/SamplePlaybackAlgorithm.hpp"
#include "audioapp/PhaseModSynthAlgorithm.hpp"
#include "audioapp/SubtractiveSynthAlgorithm.hpp"
#include "audioapp/WavetableSynthAlgorithm.hpp"
#include "audioapp/FrequencyFxProcessor.hpp"
#include "audioapp/ResonatorBank.hpp"
#include "audioapp/RoutingDevices.hpp"
#include "audioapp/MidiDelay.hpp"
#include "audioapp/effects/StutterParams.hpp"

namespace audioapp {

struct DrumMachinePlayback;
struct ChainPlayback;

static constexpr int kMaxInstrumentRegions = 32;

/// Runtime voice constraints supplied by a hosting container. Standalone
/// instruments retain their native polyphony; drum-pad chains can request a
/// single replacing voice without changing the device's saved parameters.
struct InstrumentVoicePolicy {
    int maxVoices = 0; // 0 = use the instrument's native limit
    bool retriggerReplacesVoice = false;
};

// ModulationEdgePlayback is defined in AutomationTypes.hpp

struct MidiPlaybackNote {
    int pitch = 60;
    double clipStartBeat = 0.0;
    double clipLengthBeats = 4.0;
    double noteStartBeat = 0.0;
    double noteDurationBeats = 1.0;
    float velocity = 100.0f;
    bool loopContent = false;
    double contentLengthBeats = 4.0;
};

enum class DeviceNodeKind : uint8_t {
    Unknown = 0,
    Oscillator,
    Sampler,
    SubtractiveSynth,
    KickGenerator,
    SnareGenerator,
    ClapGenerator,
    CymbalGenerator,
    CrashGenerator,
    Gate,
    Compressor,
    Expander,
    Limiter,
    TrackGain,
    BassSynth,
    PhaseModSynth,
    Delay,
    Reverb,
    Chorus,
    Phaser,
    Filter,
    FourBandEq,
    FrequencyShifter,
    Bitcrusher,
    Distortion,
    Tremolo,
    WavetableSynth,
    ResonatorBank,
    AudioReceiver,
    MidiReceiver,
    MidiDelay,
    DrumMachine,
    Oscilloscope,
    SpectrumAnalyzer,
    LoudnessMeter,
    StereoImager,
    Chain,
    Granular,
    Stutter,
};

// --- Per-device DSP-only parameter structs ---

struct OscillatorParams {
    float frequencyHz = 440.0f;
};

struct DelayParamsPlayback {
    float timeMs = 250.0f;
    float feedback = 0.4f;
    float mix = 0.5f;
    float inputGain = 1.0f;
};

struct ReverbParamsPlayback {
    float roomSize = 0.5f;
    float damping = 0.5f;
    float wetLevel = 0.33f;
    float dryLevel = 0.7f;
    float width = 1.0f;
    float inputGain = 1.0f;
};

struct ChorusParamsPlayback {
    float depth = 0.25f;
    float rateHz = 1.5f;
    float mix = 0.4f;
    float centreDelayMs = 7.0f;
    float feedback = 0.0f;
    float inputGain = 1.0f;
};

struct PhaserParamsPlayback {
    float depth = 0.5f;
    float rateHz = 0.8f;
    float feedback = 0.3f;
    float centreFrequencyHz = 1000.0f;
    float inputGain = 1.0f;
};

struct BitcrusherParamsPlayback {
    float rate = 0.5f;
    float bits = 8.0f;
    float mix = 0.5f;
    float inputGain = 1.0f;
};

struct DistortionParamsPlayback {
    float drive = 0.5f;
    float tone = 0.5f;
    float mix = 0.5f;
    float inputGain = 1.0f;
};

struct TremoloParamsPlayback {
    float depth = 0.5f;
    float rateHz = 5.0f;
    float shape = 0.0f;
    float inputGain = 1.0f;
};

struct StutterParamsPlayback {
    float trigger = 0.0f;
    float captureMs = 500.0f;
    float rateMs = 125.0f;
    float windowMs = 80.0f;
    float position = 0.0f;
    float gate = 0.85f;
    float fadeMs = 3.0f;
    float direction = 0.0f;
    float mix = 0.75f;
    float duck = 0.45f;
    float outputGain = 1.0f;
};

struct SamplerParams {
    const float* samplerPcm = nullptr;
    int samplerFrameCount = 0;
    double samplerPcmSampleRate = 48000.0;
    float attack = 0.01f;
    float decay = 0.1f;
    float sustain = 1.0f;
    float release = 0.2f;
    float filterCutoff = 1.0f;
    float filterQ = 0.5f;
    int filterMode = 0;
    float filterEnvAmount = 0.5f;
    float filterAttack = 0.05f;
    float filterDecay = 0.35f;
    float filterSustain = 0.4f;
    float filterRelease = 0.45f;
    int trimStartFrame = 0;
    int trimEndFrame = 0;
    int regionStartFrame = 0;
    int regionEndFrame = 0;
    int rootPitch = 60;
    float rootFineTune = 0.0f;
    int playbackMode = 0;
};

struct TrackGainParams {};
struct DrumMachineParams {
    std::shared_ptr<const DrumMachinePlayback> playback;
};
struct ChainParams { std::shared_ptr<const ChainPlayback> playback; float mix=1.0f; float gain=1.0f; };
struct GranularParams { const float* pcm=nullptr; int frameCount=0; double pcmRate=48000.0;
 float position=.25f,scan=.15f,size=.35f,density=.35f,spray=.1f,pitch=.5f,formant=.5f,character=.45f;
 float regionStart=0.f,regionEnd=1.f,attack=.02f,release=.25f,spread=.35f;
 float formX=.5f,formY=.05f; int vowel=0; };

using DeviceVariantParams = std::variant<
    OscillatorParams,
    SamplerParams,
    SubtractiveSynthParams,
    WavetableSynthParams,
    PhaseModSynthParams,
    KickGeneratorParams,
    SnareGeneratorParams,
    ClapGeneratorParams,
    CymbalGeneratorParams,
    CrashGeneratorParams,
    GateParams,
    CompressorParams,
    ExpanderParams,
    LimiterParams,
    TrackGainParams,
    DelayParamsPlayback,
    ReverbParamsPlayback,
    ChorusParamsPlayback,
    PhaserParamsPlayback,
    FilterParams,
    FourBandEqParams,
    FrequencyShifterParams,
    BitcrusherParamsPlayback,
    DistortionParamsPlayback,
    TremoloParamsPlayback,
    ResonatorBankParams,
    RoutingParams,
    MidiDelayParams,
    DrumMachineParams
    ,ChainParams,
    GranularParams,
    StutterParamsPlayback
>;

/// Per-track device chain node (built on control thread, read on audio thread).
struct DeviceNodePlayback {
    DeviceNodeKind kind = DeviceNodeKind::Unknown;
    std::string deviceId;
    bool bypassed = false;
    float gain = 1.0f;
    float pan = 0.5f;
    float outputMix = 1.0f;
    float outputWidth = 1.0f;
    int8_t meterSlot = -1;
    uint16_t automationTargetIndex = 0;
    InstrumentVoicePolicy voicePolicy{};
    DeviceVariantParams params;
};

struct ChainPlayback {
    float mix = 1.0f;
    float gain = 1.0f;
    int deviceCount = 0;
    DeviceNodePlayback devices[8]{};
};

struct DrumPadPlayback {
    int note = 0;
    float gain = 1.0f;
    float pan = 0.5f;
    bool muted = false;
    bool solo = false;
    int chokeGroup = 0;
    int deviceCount = 0;
    DeviceNodePlayback devices[4]{};
};

struct DrumMachinePlayback {
    DrumPadPlayback pads[128]{};
};

static constexpr int kMaxDevicesPerTrack = 16;
static constexpr float kInstrumentOutputGain = 0.2f;

struct DeviceMeterAtomic {
    std::atomic<float> gainReductionDb{0.0f};
    std::atomic<float> inputPeak{0.0f};
    std::atomic<float> inputPeakL{0.0f};
    std::atomic<float> inputPeakR{0.0f};
    std::atomic<float> loudness{ -70.0f };
    std::atomic<float> correlation{0.0f};
    std::atomic<float> waveform[32]{};
    std::atomic<float> spectrum[24]{};
};

static constexpr int kMaxDeviceMeters = 128;

bool isDynamicsDeviceNodeKind(DeviceNodeKind kind) noexcept;
bool isInstrumentDeviceNodeKind(DeviceNodeKind kind) noexcept;
bool handlesOwnModulation(DeviceNodeKind kind) noexcept;
bool isFrequencyFxDeviceNodeKind(DeviceNodeKind kind) noexcept;
bool isRoutingDeviceNodeKind(DeviceNodeKind kind) noexcept;
bool isAnalysisDeviceNodeKind(DeviceNodeKind kind) noexcept;

/// Map a device type string (e.g. "simple_sampler") to its DeviceNodeKind.
DeviceNodeKind deviceNodeKindFromTypeId(const std::string& typeId) noexcept;

float midiActiveFrequencyHz(const MidiPlaybackNote* notes,
                            int noteCount,
                            double playheadBeat,
                            float idleFrequencyHz) noexcept;

} // namespace audioapp
