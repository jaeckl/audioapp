#pragma once

#include <cstdint>

namespace audioapp {

/// Mutable per-modulator state shared across evaluate() calls.
struct EnvelopeRuntime {
    float level = 0.0f;
    int stage = 0;
    double segStartSeconds = 0.0;
    uint32_t lastRetriggerGeneration = 0;
};

/// Base class for all modulators on the audio thread.
/// Created by IModulatorType::createModulator(ModulatorArena&).
class IModulator {
public:
    virtual ~IModulator() = default;

    /// Reset runtime state (e.g. when playback starts).
    virtual void reset() noexcept = 0;

    /// Evaluate the modulator at a given frame.
    /// @param playheadBeat Current playhead position in beats.
    /// @param bpm Project BPM.
    /// @param frameSeconds Elapsed seconds since playback start (for free-running).
    /// @param retriggerGeneration Global retrigger counter (incremented on each MIDI note).
    /// @return Modulation value in [-1, 1] range.
    virtual float evaluate(double playheadBeat, int bpm,
                           double frameSeconds,
                           uint32_t retriggerGeneration) noexcept = 0;

    /// Returns the ModulatorType enum value (0=Lfo, 1=Adsr, 2=Adr).
    virtual int modulatorType() const noexcept = 0;

protected:
    IModulator() = default;
};

} // namespace audioapp