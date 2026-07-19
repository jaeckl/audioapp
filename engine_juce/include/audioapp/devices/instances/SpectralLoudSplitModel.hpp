#pragma once

#include <memory>
#include <vector>

namespace audioapp {

struct DeviceSlot;

static constexpr int kSpectralLoudBands = 3;

/// Spectral loudness split: loud / mid / quiet bins by dB thresholds,
/// with PRE FX → STFT split → band FX → POST FX → Mix.
struct SpectralLoudSplitModel {
    float highDb = -18.0f; // loud ↔ mid
    float lowDb = -40.0f;  // mid ↔ quiet
    float bandGain[kSpectralLoudBands]{1.0f, 1.0f, 1.0f}; // 0..2
    float bandSolo[kSpectralLoudBands]{};                 // 0 or 1
    std::vector<std::shared_ptr<DeviceSlot>> preFxDevices;
    std::vector<std::shared_ptr<DeviceSlot>> bands[kSpectralLoudBands];
    std::vector<std::shared_ptr<DeviceSlot>> postFxDevices;

    SpectralLoudSplitModel() = default;
    SpectralLoudSplitModel(const SpectralLoudSplitModel&);
    SpectralLoudSplitModel& operator=(const SpectralLoudSplitModel&);

    static SpectralLoudSplitModel withDefaults() noexcept;
};

} // namespace audioapp
