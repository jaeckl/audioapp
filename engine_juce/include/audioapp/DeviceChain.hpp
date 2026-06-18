#pragma once

#include <cstdint>
#include <variant>

#include "audioapp/AutomationTypes.hpp"
#include "audioapp/KickGenerator.hpp"
#include "audioapp/SnareGenerator.hpp"
#include "audioapp/ClapGenerator.hpp"
#include "audioapp/CymbalGenerator.hpp"
#include "audioapp/DynamicsProcessor.hpp"
#include "audioapp/LfoTypes.hpp"
#include "audioapp/SamplerFilter.hpp"
#include "audioapp/SubtractiveSynth.hpp"

namespace audioapp {

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
    Gate,
    Compressor,
    Expander,
    Limiter,
    TrackGain,
};

// --- Per-device DSP-only parameter structs ---
// These hold parameters specific to each device's processing logic.
// Universal properties (gain, pan) live on DeviceNodePlayback itself.

struct OscillatorParams {
    float frequencyHz = 440.0f;
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
    int trimStartFrame = 0;
    int trimEndFrame = 0;
    int regionStartFrame = 0;
    int regionEndFrame = 0;
};

struct TrackGainParams {};

// SubtractiveSynthParams is defined in SubtractiveSynth.hpp (includes
// internal voice-level gain, individual oscillator params, filter, etc.)

using DeviceVariantParams = std::variant<
    OscillatorParams,
    SamplerParams,
    SubtractiveSynthParams,
    KickGeneratorParams,
    SnareGeneratorParams,
    ClapGeneratorParams,
    CymbalGeneratorParams,
    GateParams,
    CompressorParams,
    ExpanderParams,
    LimiterParams,
    TrackGainParams
>;

/// Per-track device chain node (built on control thread, read on audio thread).
struct DeviceNodePlayback {
    DeviceNodeKind kind = DeviceNodeKind::Unknown;
    std::string deviceId;
    bool bypassed = false;
    float gain = 1.0f;   // universal output gain (every device has one)
    float pan = 0.5f;    // universal stereo pan
    DeviceVariantParams params;
};

static constexpr int kMaxDevicesPerTrack = 16;
static constexpr float kInstrumentOutputGain = 0.2f;

float midiActiveFrequencyHz(const MidiPlaybackNote* notes,
                            int noteCount,
                            double playheadBeat,
                            float idleFrequencyHz) noexcept;

/// Process track device chain in order.
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
                        DynamicsRuntime* dynamicsRuntimes = nullptr,
                        const float* lfoValues = nullptr,
                        int lfoCount = 0,
                        const ModulationEdge* modEdges = nullptr,
                        int modEdgeCount = 0,
                        const AutomationClipPlayback* automationClips = nullptr,
                        int automationClipCount = 0) noexcept;

} // namespace audioapp