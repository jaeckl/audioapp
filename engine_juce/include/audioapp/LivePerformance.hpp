#pragma once

#include <atomic>
#include <cstdint>

#include "audioapp/DeviceChain.hpp"
#include "audioapp/SamplerFilter.hpp"
#include "audioapp/SubtractiveSynth.hpp"

namespace audioapp {

static constexpr int kLiveMaxVoices = 16;

enum class LiveInstrumentKind : uint8_t {
    None = 0,
    Oscillator,
    Sampler,
    SubtractiveSynth,
};

/// Immutable instrument snapshot copied on note-on (control thread writes, audio thread reads).
struct LiveInstrumentSnapshot {
    LiveInstrumentKind kind = LiveInstrumentKind::None;
    float frequencyHz = 440.0f;
    float gain = 1.0f;
    const float* samplerPcm = nullptr;
    int samplerFrameCount = 0;
    double samplerPcmSampleRate = 48000.0;
    int rootPitch = 60;
    float attack = 0.01f;
    float decay = 0.3f;
    float sustain = 0.7f;
    float release = 0.4f;
    float filterCutoff = 1.0f;
    float filterQ = 0.35f;
    int filterMode = 0;
    int trimStartFrame = 0;
    int trimEndFrame = 0;
    int regionStartFrame = 0;
    int regionEndFrame = 0;
    SubtractiveSynthParams subtractive{};
};

struct LiveVoiceSlot {
    std::atomic<uint32_t> active{0};
    int pitch = 60;
    float velocity = 100.0f;
    uint64_t startSample = 0;
    uint64_t releaseSample = 0;
    bool releasing = false;
    LiveInstrumentSnapshot instrument{};
    float oscillatorPhase = 0.0f;
    BiquadState filterState{};
    SubtractiveVoiceRuntime subtractive{};
    double subtractiveStartSec = 0.0;
    double subtractiveReleaseSec = -1.0;
};

/// RT-safe live voice mixer + sample clock (control thread configures, audio thread reads).
class LivePerformanceMixer {
public:
    void reset() noexcept;
    void advanceSampleClock(int numFrames) noexcept;
    uint64_t sampleClock() const noexcept;

    int noteOn(const LiveInstrumentSnapshot& instrument, int pitch, float velocity) noexcept;
    void noteOff(int pitch) noexcept;
    void allNotesOff() noexcept;

    void readMix(float* monoOut, int numFrames, double sampleRate) noexcept;

private:
    std::atomic<uint64_t> sampleClock_{0};
    LiveVoiceSlot voices_[kLiveMaxVoices];

    void releaseVoice(LiveVoiceSlot& voice, uint64_t now) noexcept;
};

} // namespace audioapp
