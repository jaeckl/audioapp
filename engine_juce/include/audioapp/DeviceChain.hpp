#pragma once

#include <cstdint>
#include <atomic>
#include <cstring>
#include <variant>
#include <memory>

#include "audioapp/AutomationTypes.hpp"
#include "audioapp/devices/SplitMode.hpp"
#include "audioapp/KickAlgorithm.hpp"
#include "audioapp/SnareAlgorithm.hpp"
#include "audioapp/ClapAlgorithm.hpp"
#include "audioapp/DedicatedPercussionAlgorithm.hpp"
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
#include "audioapp/effects/DuckerParams.hpp"
#include "audioapp/effects/UtilityParams.hpp"

namespace audioapp {

enum class DrumPadParameter : uint8_t {
    Gain,
    Pan,
    Mute,
    Solo,
    ChokeGroup,
    Invalid,
};

struct DrumMachinePlayback;
struct ChainPlayback;
struct SplitPlayback;
struct MultibandSplitPlayback;
struct SpectralLoudSplitPlayback;

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
    HihatGenerator,
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
    RideGenerator,
    TomGenerator,
    RimshotGenerator,
    Split,
    MultibandSplit,
    SpectralLoudSplit,
    DcOffset,
    DeCrackler,
    DeEsser,
    DeHum,
    DeNoise,
    Ducker,
    Utility,
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
      float timeMode = 0.0f;
      float noteCount = 1.0f;
      float blurMode = 0.0f;
      float blurAmount = 0.5f;
      float inputDucking = 0.0f;
      float lowCutHz = 20.0f;
      float highCutHz = 20000.0f;
  };

struct ReverbParamsPlayback {
    float modeMorph = 2.0f;
    float decay = 0.56f;
    float preDelay = 0.112f;
    float size = 0.64f;
    float diffusion = 0.78f;
    float damping = 0.68f;
    float modulation = 0.18f;
    float lowCut = 0.26f;
    float highCut = 0.86f;
    float ducking = 0.25f;
    float freeze = 0.0f;
    float inputGain = 1.0f;
};

struct ChorusParamsPlayback {
    float modeMorph = 0.0f;
    float modeParams[4][6] = {
        {0.286f, 0.25f, 0.30f, 0.0f, 0.5f, 0.0f},
        {0.25f, 0.50f, 0.50f, 0.65f, 0.25f, 0.65f},
        {0.50f, 0.35f, 0.80f, 0.25f, 0.0f, 0.90f},
        {0.30f, 0.50f, 0.40f, 0.40f, 0.70f, 0.60f},
    };
    float inputGain = 1.0f;
};

struct PhaserParamsPlayback {
    float depth = 0.5f;
    float rateHz = 0.8f;
    float feedback = 0.3f;
    float centreFrequencyHz = 1000.0f;
    float rateMode = 0.0f;
    float waveform = 0.0f;
    float waveShape = 0.5f;
    float phaseOffset = 0.0f;
    float stereoPhase = 0.75f;
    float stages = 8.0f;
    float inputGain = 1.0f;
};

struct BitcrusherParamsPlayback {
    float rate = 0.5f;
    float bits = 8.0f;
    float mix = 0.5f;
    float mode = 0.0f;
    float shape = 0.0f;
    float jitter = 0.0f;
    float drive = 0.0f;
    float ditherMode = 0.0f;
    float ditherAmount = 0.0f;
    float clipMode = 0.0f;
    float clipAmount = 0.0f;
    float filter = 1.0f;
    float inputGain = 1.0f;
};

struct DistortionParamsPlayback {
    float drive = 0.5f;
    float tone = 0.5f;
    float mix = 0.5f;
    float sym = 0.5f;
    float inputGain = 1.0f;
};

struct TremoloParamsPlayback {
    float depth = 0.5f;
    float rateHz = 5.0f;
    float shape = 0.0f;
    float inputGain = 1.0f;
};

struct DcOffsetParamsPlayback {
    float mode = 1.0f;      // 0=Mean, 1=HPF
    float amount = 1.0f;
    float cutoff = 0.3f;
    float inputGain = 1.0f;
};

struct DeCracklerParamsPlayback {
    float sensitivity = 0.5f;
    float strength = 0.6f;
    float width = 0.4f;
    float inputGain = 1.0f;
};

struct DeEsserParamsPlayback {
    float freq = 0.55f;
    float threshold = 0.45f;
    float amount = 0.5f;
    float listen = 0.0f;   // 0/1
    float inputGain = 1.0f;
};

struct DeHumParamsPlayback {
    float mainsFreq = 0.0f; // 0=50Hz, 1=60Hz
    float depth = 0.7f;
    float harmonics = 0.4f;
    float inputGain = 1.0f;
};

struct DeNoiseParamsPlayback {
    float threshold = 0.35f;
    float reduction = 0.5f;
    float smoothing = 0.4f;
    float inputGain = 1.0f;
};

// DuckerParams / UtilityParams live in effects headers; included via DeviceSlot.

struct StutterParamsPlayback {
    float trigger = 0.0f;
    float captureMs = 500.0f;
    float rateSync = 1.0f;
    float rateBeats = 0.25f;
    float rateMs = 125.0f;
    float windowMs = 80.0f;
    float position = 0.0f;
    float gate = 0.85f;
    float fadeMs = 3.0f;
    float direction = 0.0f;
    float mix = 1.0f;
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
struct SplitParams { std::shared_ptr<const SplitPlayback> playback; };
struct MultibandSplitParams { std::shared_ptr<const MultibandSplitPlayback> playback; };
struct SpectralLoudSplitParams { std::shared_ptr<const SpectralLoudSplitPlayback> playback; };
struct GranularParams { const float* pcm=nullptr; int frameCount=0; double pcmRate=48000.0;
 float position=.25f,scan=.15f,size=.35f,density=.35f,spray=.1f,pitch=.5f,formant=.5f,character=.45f;
 float regionStart=0.f,regionEnd=1.f,attack=.02f,release=.25f,spread=.35f;
 float formX=.5f,formY=.05f; int vowel=0; };

struct ResolvedAssetUpdate {
    DeviceNodeKind kind = DeviceNodeKind::Unknown;
    SamplerParams sampler{};
    GranularParams granular{};
    int wavetableIndex = -1;
};

using DeviceVariantParams = std::variant<
    OscillatorParams,
    SamplerParams,
    SubtractiveSynthParams,
    WavetableSynthParamsPlayback,
    PhaseModSynthParams,
    KickGeneratorParams,
    SnareGeneratorParams,
    ClapGeneratorParams,
    HihatGeneratorParams,
    RideGeneratorParams,
    TomGeneratorParams,
    RimshotGeneratorParams,
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
    DcOffsetParamsPlayback,
    DeCracklerParamsPlayback,
    DeEsserParamsPlayback,
    DeHumParamsPlayback,
    DeNoiseParamsPlayback,
    DuckerParams,
    UtilityParams,
    ResonatorBankParams,
    RoutingParams,
    MidiDelayParams,
    DrumMachineParams
    ,ChainParams,
    GranularParams,
    StutterParamsPlayback,
    SplitParams,
    MultibandSplitParams,
    SpectralLoudSplitParams
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

/// One side of an LR/Mid-Side split container (L/Mid or R/Side).
struct SplitBranchPlayback {
    int deviceCount = 0;
    DeviceNodePlayback devices[8]{};
};

struct SplitPlayback {
    SplitMode mode = SplitMode::Lr;
    float branch0Gain = 1.0f;
    float branch1Gain = 1.0f;
    bool branch0Solo = false;
    bool branch1Solo = false;
    SplitBranchPlayback branches[2]{};
};

struct MultibandSplitPlayback {
    int bandCount = 2;
    float crossoverHz[3]{};
    float bandGain[4]{1.0f, 1.0f, 1.0f, 1.0f};
    SplitBranchPlayback bands[4]{};
};

struct SpectralLoudSplitPlayback {
    float highDb = -18.0f;
    float lowDb = -40.0f;
    float bandGain[3]{1.0f, 1.0f, 1.0f};
    float bandSolo[3]{};
    SplitBranchPlayback preFx{};
    SplitBranchPlayback bands[3]{};
    SplitBranchPlayback postFx{};
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

// Eight top-level devices plus up to eight Note FX and eight Audio FX owned by
// one instrument must all remain addressable in the flattened realtime graph.
static constexpr int kMaxDevicesPerTrack = 24;
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
