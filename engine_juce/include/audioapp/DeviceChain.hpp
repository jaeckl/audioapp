#pragma once

#include <cstdint>
#include <atomic>
#include <cstring>
#include <variant>

#include "audioapp/AutomationTypes.hpp"
#include "audioapp/KickGenerator.hpp"
#include "audioapp/SnareGenerator.hpp"
#include "audioapp/ClapGenerator.hpp"
#include "audioapp/CymbalGenerator.hpp"
#include "audioapp/CrashGenerator.hpp"
#include "audioapp/DynamicsProcessor.hpp"
#include "audioapp/LfoTypes.hpp"
#include "audioapp/SamplerFilter.hpp"
#include "audioapp/SamplePlayback.hpp"
#include "audioapp/PhaseModSynth.hpp"
#include "audioapp/SubtractiveSynth.hpp"
#include "audioapp/FrequencyFxProcessor.hpp"

namespace audioapp {

static constexpr int kMaxInstrumentRegions = 32;

// ModulationEdgePlayback is defined in AutomationTypes.hpp

struct MidiPlaybackNote {
    int pitch = 60;
    double clipStartBeat = 0.0;
    double clipLengthBeats = 4.0;
    double noteStartBeat = 0.0;
    double noteDurationBeats = 1.0;
    float velocity = 100.0f;
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

using DeviceVariantParams = std::variant<
    OscillatorParams,
    SamplerParams,
    SubtractiveSynthParams,
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
    FrequencyShifterParams
>;

/// Per-track device chain node (built on control thread, read on audio thread).
struct DeviceNodePlayback {
    DeviceNodeKind kind = DeviceNodeKind::Unknown;
    std::string deviceId;
    bool bypassed = false;
    float gain = 1.0f;
    float pan = 0.5f;
    int8_t meterSlot = -1;
    DeviceVariantParams params;
};

static constexpr int kMaxDevicesPerTrack = 16;
static constexpr float kInstrumentOutputGain = 0.2f;

struct DeviceMeterAtomic {
    std::atomic<float> gainReductionDb{0.0f};
    std::atomic<float> inputPeak{0.0f};
};

static constexpr int kMaxDeviceMeters = 128;

bool isDynamicsDeviceNodeKind(DeviceNodeKind kind) noexcept;
bool isInstrumentDeviceNodeKind(DeviceNodeKind kind) noexcept;
bool isFrequencyFxDeviceNodeKind(DeviceNodeKind kind) noexcept;

float midiActiveFrequencyHz(const MidiPlaybackNote* notes,
                            int noteCount,
                            double playheadBeat,
                            float idleFrequencyHz) noexcept;

struct TimeBasedEffectRuntime {
    static constexpr int kBufferSize = 192000; // 4 seconds at 48kHz
    float* bufferLeft = nullptr;
    float* bufferRight = nullptr;
    int writeIndex = 0;
    float lfoPhase = 0.0f;

    // Allpass filter states for phaser (4 stages for stereo)
    float phaserStateL[4] = {0.0f};
    float phaserStateR[4] = {0.0f};

    TimeBasedEffectRuntime() {
        bufferLeft = new float[kBufferSize]();
        bufferRight = new float[kBufferSize]();
    }
    ~TimeBasedEffectRuntime() {
        delete[] bufferLeft;
        delete[] bufferRight;
    }
    TimeBasedEffectRuntime(const TimeBasedEffectRuntime& other) {
        bufferLeft = new float[kBufferSize]();
        bufferRight = new float[kBufferSize]();
        std::memcpy(bufferLeft, other.bufferLeft, kBufferSize * sizeof(float));
        std::memcpy(bufferRight, other.bufferRight, kBufferSize * sizeof(float));
        writeIndex = other.writeIndex;
        lfoPhase = other.lfoPhase;
        std::memcpy(phaserStateL, other.phaserStateL, sizeof(phaserStateL));
        std::memcpy(phaserStateR, other.phaserStateR, sizeof(phaserStateR));
    }
    TimeBasedEffectRuntime& operator=(const TimeBasedEffectRuntime& other) {
        if (this != &other) {
            std::memcpy(bufferLeft, other.bufferLeft, kBufferSize * sizeof(float));
            std::memcpy(bufferRight, other.bufferRight, kBufferSize * sizeof(float));
            writeIndex = other.writeIndex;
            lfoPhase = other.lfoPhase;
            std::memcpy(phaserStateL, other.phaserStateL, sizeof(phaserStateL));
            std::memcpy(phaserStateR, other.phaserStateR, sizeof(phaserStateR));
        }
        return *this;
    }
    TimeBasedEffectRuntime(TimeBasedEffectRuntime&& other) noexcept {
        bufferLeft = other.bufferLeft;
        bufferRight = other.bufferRight;
        writeIndex = other.writeIndex;
        lfoPhase = other.lfoPhase;
        std::memcpy(phaserStateL, other.phaserStateL, sizeof(phaserStateL));
        std::memcpy(phaserStateR, other.phaserStateR, sizeof(phaserStateR));
        other.bufferLeft = nullptr;
        other.bufferRight = nullptr;
    }
    TimeBasedEffectRuntime& operator=(TimeBasedEffectRuntime&& other) noexcept {
        if (this != &other) {
            delete[] bufferLeft;
            delete[] bufferRight;
            bufferLeft = other.bufferLeft;
            bufferRight = other.bufferRight;
            writeIndex = other.writeIndex;
            lfoPhase = other.lfoPhase;
            std::memcpy(phaserStateL, other.phaserStateL, sizeof(phaserStateL));
            std::memcpy(phaserStateR, other.phaserStateR, sizeof(phaserStateR));
            other.bufferLeft = nullptr;
            other.bufferRight = nullptr;
        }
        return *this;
    }
};

/// Process track device chain in order.
/// modulationEdges and automationClips are expected to be pre-filtered per-track
/// with deviceIndex matching the devices[] array positions.
void processDeviceChain(float* trackLeft,
                        float* trackRight,
                        int numFrames,
                        double sampleRate,
                        int bpm,
                        double playheadStartBeat,
                        const MidiPlaybackNote* notes,
                        int noteCount,
                        const DeviceNodePlayback* devices,
                        int deviceCount,
                        float& oscillatorPhase,
                        bool suppressInstruments,
                        BiquadState* samplerFilterStates = nullptr,
                        SubtractiveSynthRuntime* subtractiveRuntimes = nullptr,
                        KickGeneratorRuntime* kickRuntimes = nullptr,
                        SnareGeneratorRuntime* snareRuntimes = nullptr,
                        ClapGeneratorRuntime* clapRuntimes = nullptr,
                        CymbalGeneratorRuntime* cymbalRuntimes = nullptr,
                        CrashGeneratorRuntime* crashRuntimes = nullptr,
                        PhaseModSynthRuntime* phaseModRuntimes = nullptr,
                        DynamicsRuntime* dynamicsRuntimes = nullptr,
                        TimeBasedEffectRuntime* timeBasedRuntimes = nullptr,
                        DeviceMeterAtomic* deviceMeters = nullptr,
                        int maxDeviceMeters = 0,
                        const float* lfoValues = nullptr,
                        int lfoCount = 0,
                        const ModulationEdgePlayback* modEdges = nullptr,
                        int modEdgeCount = 0,
                        const AutomationClipPlayback* automationClips = nullptr,
                        int automationClipCount = 0,
                        FilterRuntime* filterRuntimes = nullptr,
                        FourBandEqRuntime* fourBandEqRuntimes = nullptr,
                        FrequencyShifterRuntime* frequencyShifterRuntimes = nullptr) noexcept;

} // namespace audioapp