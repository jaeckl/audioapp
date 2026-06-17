#pragma once

#include <cstdint>

#include "audioapp/SamplerFilter.hpp"

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
    TrackGain,
};

/// Immutable per-track device chain node (built on control thread, read on audio thread).
struct DeviceNodePlayback {
    DeviceNodeKind kind = DeviceNodeKind::Unknown;
    float frequencyHz = 440.0f;
    float gain = 1.0f;
    float pan = 0.5f;
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
    bool bypassed = false;
};

static constexpr int kMaxDevicesPerTrack = 16;
static constexpr float kInstrumentOutputGain = 0.2f;

float midiActiveFrequencyHz(const MidiPlaybackNote* notes,
                            int noteCount,
                            double playheadBeat,
                            float idleFrequencyHz) noexcept;

/// Process track device chain in order: instruments add audio, effects transform in place.
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
                        BiquadState* samplerFilterStates = nullptr) noexcept;

} // namespace audioapp
