#pragma once

#include "audioapp/FrequencyFxProcessor.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {

struct FilterInstance {
    float ffxCutoff = 0.6f;        // normalized 0-1 → 20-20000 Hz via normalizedToFrequency
    float ffxResonance = 0.3f;     // normalized 0-1 → Q 0.1-20 via normalizedToQ
    float ffxFilterMode = 0.0f;    // normalized 0-1 → 0=LP, 1=HP, 2=BP, 3=Notch

    FilterParams toPlaybackParams() const {
        FilterParams p;
        p.cutoffHz = normalizedToFrequency(ffxCutoff);
        p.resonance = normalizedToQ(ffxResonance);
        p.filterMode = static_cast<int>(std::lround(ffxFilterMode * 3.0f));
        p.filterMode = std::clamp(p.filterMode, 0, 3);
        return p;
    }
};

// === WP-3 will add FourBandEqInstance here ===
// === WP-4 will add FrequencyShifterInstance here ===

struct FourBandEqInstance {
    float ffxBand1Freq = 0.15f;    // low shelf freq
    float ffxBand1Gain = 0.5f;     // low shelf gain (mid = 0 dB)
    float ffxBand1Q = 0.5f;        // low shelf Q
    float ffxBand2Freq = 0.35f;    // low-mid peak freq
    float ffxBand2Gain = 0.5f;     // low-mid peak gain
    float ffxBand2Q = 0.5f;        // low-mid peak Q
    float ffxBand3Freq = 0.6f;     // high-mid peak freq
    float ffxBand3Gain = 0.5f;     // high-mid peak gain
    float ffxBand3Q = 0.5f;        // high-mid peak Q
    float ffxBand4Freq = 0.85f;    // high shelf freq
    float ffxBand4Gain = 0.5f;     // high shelf gain
    float ffxBand4Q = 0.5f;        // high shelf Q

    FourBandEqParams toPlaybackParams() const {
        FourBandEqParams p;
        // Band 0 = low shelf
        p.bands[0].frequencyHz = normalizedToFrequency(ffxBand1Freq);
        p.bands[0].gainDb = normalizedToDb(ffxBand1Gain);
        p.bands[0].q = normalizedToQ(ffxBand1Q);
        // Band 1 = low-mid peak
        p.bands[1].frequencyHz = normalizedToFrequency(ffxBand2Freq);
        p.bands[1].gainDb = normalizedToDb(ffxBand2Gain);
        p.bands[1].q = normalizedToQ(ffxBand2Q);
        // Band 2 = high-mid peak
        p.bands[2].frequencyHz = normalizedToFrequency(ffxBand3Freq);
        p.bands[2].gainDb = normalizedToDb(ffxBand3Gain);
        p.bands[2].q = normalizedToQ(ffxBand3Q);
        // Band 3 = high shelf
        p.bands[3].frequencyHz = normalizedToFrequency(ffxBand4Freq);
        p.bands[3].gainDb = normalizedToDb(ffxBand4Gain);
        p.bands[3].q = normalizedToQ(ffxBand4Q);
        return p;
    }
};

/// Control-thread state for the Frequency Shifter device.
/// Owned by WP-4; sibling structs (FilterInstance, FourBandEqInstance)
/// are added by WP-2 and WP-3 respectively.
struct FrequencyShifterInstance {
    float ffxShift = 0.5f;  // normalized 0-1 → -2000 to +2000 Hz (0.5 = no shift)

    FrequencyShifterParams toPlaybackParams() const {
        FrequencyShifterParams p;
        // ffxShift=0 → -2000Hz, ffxShift=0.5 → 0Hz, ffxShift=1 → +2000Hz
        p.shiftHz = (ffxShift - 0.5f) * 4000.0f;
        return p;
    }
};

} // namespace audioapp