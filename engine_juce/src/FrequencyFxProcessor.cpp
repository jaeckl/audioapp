#include "audioapp/FrequencyFxProcessor.hpp"

#include <juce_core/juce_core.h>

#include <algorithm>
#include <cmath>

namespace audioapp {

namespace {

constexpr double kPi = 3.14159265358979323846;

static inline float safe_clamp(float v, float lo, float hi) noexcept {
    if (!std::isfinite(v)) return lo;
    return std::clamp(v, lo, hi);
}

static inline int safe_clamp(int v, int lo, int hi) noexcept {
    return std::clamp(v, lo, hi);
}

// Cook biquad coefficients for shelf / peak filters using the RBJ Audio EQ
// Cookbook formulas (http://www.musicdsp.org/files/Audio-EQ-Cookbook.txt).
// These are the same formulas JUCE's makeLowShelf / makeHighShelf /
// makePeakFilter use internally. We compute them directly to avoid the
// juce::dsp dependency, which is excluded from the Android modules-only build
// (see engine_juce/CMakeLists.txt: JUCE_MODULES_ONLY when ANDROID is set).
//
// The output `coeffs` uses the same convention as cookSamplerBiquad: a0 is
// pre-normalized to 1 (b0/b1/b2/a1/a2 already divided by a0).
//
// `kind`: 0 = low shelf, 1 = high shelf, 2 = peaking (peak) filter.
static void cookEqBiquad(BiquadCoeffs& coeffs,
                         int kind,
                         float sampleRate,
                         float frequencyHz,
                         float q,
                         float gainDb) noexcept {
    coeffs = BiquadCoeffs{};
    if (sampleRate <= 0.0f || frequencyHz <= 0.0f) return;

    const float f = safe_clamp(frequencyHz, 20.0f, sampleRate * 0.45f);
    const float qClamped = std::max(0.1f, q);
    const float A = std::pow(10.0f, gainDb / 40.0f);  // sqrt of linear amplitude
    const float omega = static_cast<float>(2.0 * kPi) * f / sampleRate;
    const float sn = std::sin(omega);
    const float cs = std::cos(omega);
    const float alpha = sn / (2.0f * qClamped);
    const float beta = std::sqrt(A) / qClamped;  // shelf-only
    const float Ap1 = A + 1.0f;
    const float Am1 = A - 1.0f;

    float b0 = 0.0f, b1 = 0.0f, b2 = 0.0f;
    float a0 = 1.0f, a1 = 0.0f, a2 = 0.0f;

    switch (kind) {
    case 0: { // low shelf
        b0 =      A * (Ap1 - Am1 * cs + beta * sn);
        b1 =  2.0f * A * (Am1 - Ap1 * cs);
        b2 =      A * (Ap1 - Am1 * cs - beta * sn);
        a0 =          Ap1 + Am1 * cs + beta * sn;
        a1 =     -2.0f * (Am1 + Ap1 * cs);
        a2 =          Ap1 + Am1 * cs - beta * sn;
        break;
    }
    case 1: { // high shelf
        b0 =      A * (Ap1 + Am1 * cs + beta * sn);
        b1 = -2.0f * A * (Am1 + Ap1 * cs);
        b2 =      A * (Ap1 + Am1 * cs - beta * sn);
        a0 =          Ap1 - Am1 * cs + beta * sn;
        a1 =      2.0f * (Am1 - Ap1 * cs);
        a2 =          Ap1 - Am1 * cs - beta * sn;
        break;
    }
    case 2:
    default: { // peaking EQ
        b0 =  1.0f + alpha * A;
        b1 = -2.0f * cs;
        b2 =  1.0f - alpha * A;
        a0 =  1.0f + alpha / A;
        a1 = -2.0f * cs;
        a2 =  1.0f - alpha / A;
        break;
    }
    }

    if (a0 != 0.0f) {
        const float invA0 = 1.0f / a0;
        coeffs.b0 = b0 * invA0;
        coeffs.b1 = b1 * invA0;
        coeffs.b2 = b2 * invA0;
        coeffs.a1 = a1 * invA0;
        coeffs.a2 = a2 * invA0;
    }
}

} // namespace

// --- Helpers ---
float normalizedToFrequency(float normalized) noexcept {
    const float clamped = safe_clamp(normalized, 0.0f, 1.0f);
    // Logarithmic: 0 -> 20 Hz, 1 -> 20000 Hz
    // 20 * (20000/20)^clamped = 20 * 1000^clamped
    return 20.0f * std::pow(1000.0f, clamped);
}

float normalizedToQ(float normalized) noexcept {
    const float clamped = safe_clamp(normalized, 0.0f, 1.0f);
    // 0 -> 0.1, 1 -> 20.0
    return 0.1f + clamped * 19.9f;
}

float normalizedToDb(float normalized) noexcept {
    const float clamped = safe_clamp(normalized, 0.0f, 1.0f);
    // 0 -> -24 dB, 1 -> +24 dB, 0.5 -> 0 dB (linear)
    return -24.0f + clamped * 48.0f;
}

// --- Filter ---
void processFilterStereoBlock(float* trackLeft,
                              float* trackRight,
                              int numFrames,
                              double sampleRate,
                              const FilterParams& params,
                              FilterRuntime& runtime) noexcept {
    if (trackLeft == nullptr || trackRight == nullptr || numFrames <= 0 || sampleRate <= 0.0) {
        return;
    }

    const int mode = safe_clamp(params.filterMode, 0, 3);
    const float cutoff = safe_clamp(params.cutoffHz, 20.0f, static_cast<float>(sampleRate * 0.45));
    const float q = std::max(0.1f, params.resonance);

    BiquadCoeffs coeffs;
    cookSamplerBiquad(coeffs, mode, static_cast<float>(sampleRate), cutoff, q);

    for (int i = 0; i < numFrames; ++i) {
        trackLeft[i] = processBiquadSample(trackLeft[i], coeffs, runtime.left);
        trackRight[i] = processBiquadSample(trackRight[i], coeffs, runtime.right);
    }
}

// --- 4-Band EQ ---
void processFourBandEqStereoBlock(float* trackLeft,
                                  float* trackRight,
                                  int numFrames,
                                  double sampleRate,
                                  const FourBandEqParams& params,
                                  FourBandEqRuntime& runtime) noexcept {
    if (trackLeft == nullptr || trackRight == nullptr || numFrames <= 0 || sampleRate <= 0.0) {
        return;
    }

    // Standard 4-band EQ frequencies, used when params.bands[band].frequencyHz
    // is zero or negative (defaults match common mixing-board layouts).
    constexpr float kDefaultFreqs[4] = {100.0f, 400.0f, 2500.0f, 8000.0f};
    constexpr float kDefaultQ = 0.707f;

    // Build coefficients once per block (one entry per band). The host is
    // expected to update params at block boundaries, not mid-block, so
    // recomputing here is sufficient for the contract's real-time-safety
    // requirement. The biquad coefficients are computed via cookEqBiquad
    // (RBJ Audio EQ Cookbook) — no heap allocation, no juce::dsp dependency.
    // (We previously used juce::dsp::IIR::Coefficients::make{LowShelf,
    // HighShelf,PeakFilter} which allocate internally via `new`; the Android
    // modules-only build also excludes juce_dsp, so we cook the coefficients
    // directly.)
    BiquadCoeffs bandCoeffs[4];
    for (int band = 0; band < 4; ++band) {
        const FourBandEqBandParams& bp = params.bands[band];
        const float f = bp.frequencyHz > 0.0f ? bp.frequencyHz : kDefaultFreqs[band];
        const float g = bp.gainDb;
        const float q = bp.q > 0.0f ? bp.q : kDefaultQ;

        // kind: 0 = low shelf, 1 = high shelf, 2 = peak
        int kind = 2;
        if (band == 0) kind = 0;
        else if (band == 3) kind = 1;

        cookEqBiquad(bandCoeffs[band], kind, static_cast<float>(sampleRate), f, q, g);
    }

    // Per-sample loop: apply four biquads in series per channel. No
    // allocations, no locks, no I/O.
    for (int i = 0; i < numFrames; ++i) {
        float l = trackLeft[i];
        float r = trackRight[i];
        for (int band = 0; band < 4; ++band) {
            l = processBiquadSample(l, bandCoeffs[band], runtime.bands[band][0]);
            r = processBiquadSample(r, bandCoeffs[band], runtime.bands[band][1]);
        }
        trackLeft[i] = l;
        trackRight[i] = r;
    }
}

// --- Frequency Shifter ---
//
// Ring modulator: wet = (dry + fb*prevWet) * cos(ωt), then one-pole tone LP,
// then dry/wet mix. Not SSB — equal upper/lower sidebands.
void processFrequencyShifterStereoBlock(float* trackLeft,
                                        float* trackRight,
                                        int numFrames,
                                        double sampleRate,
                                        const FrequencyShifterParams& params,
                                        FrequencyShifterRuntime& runtime) noexcept {
    if (trackLeft == nullptr || trackRight == nullptr || numFrames <= 0 || sampleRate <= 0.0) {
        return;
    }

    const double shift = static_cast<double>(
        safe_clamp(params.shiftHz, -2050.0f, 2050.0f));
    const double omega = 2.0 * kPi * shift / static_cast<double>(sampleRate);
    const float mix = safe_clamp(params.mix, 0.0f, 1.0f);
    const float feedback = safe_clamp(params.feedback, 0.0f, 0.95f) * 0.95f;
    const float tone = safe_clamp(params.tone, 0.0f, 1.0f);
    const bool toneOpen = tone >= 0.995f;

    // Tone 0 → ~200 Hz LP; tone near 1 → bypass (fully open).
    const float toneHz = 200.0f * std::pow(80.0f, tone); // ~200..16k before bypass
    const float toneCoeff = static_cast<float>(
        std::exp(-2.0 * kPi * static_cast<double>(toneHz) / sampleRate));
    const float toneGain = 1.0f - toneCoeff;

    const double stereoDetune = 1.0e-4;

    for (int i = 0; i < numFrames; ++i) {
        const float dryL = trackLeft[i];
        const float dryR = trackRight[i];

        const float ringInL = dryL + feedback * runtime.feedbackL;
        const float ringInR = dryR + feedback * runtime.feedbackR;

        float wetL = ringInL * static_cast<float>(std::cos(runtime.phaseL));
        float wetR = ringInR * static_cast<float>(std::cos(runtime.phaseR + stereoDetune));

        if (!toneOpen) {
            runtime.toneL = toneGain * wetL + toneCoeff * runtime.toneL;
            runtime.toneR = toneGain * wetR + toneCoeff * runtime.toneR;
            wetL = runtime.toneL;
            wetR = runtime.toneR;
        } else {
            runtime.toneL = wetL;
            runtime.toneR = wetR;
        }

        runtime.feedbackL = safe_clamp(wetL, -4.0f, 4.0f);
        runtime.feedbackR = safe_clamp(wetR, -4.0f, 4.0f);

        const float outL = dryL * (1.0f - mix) + wetL * mix;
        const float outR = dryR * (1.0f - mix) + wetR * mix;

        trackLeft[i] = std::isfinite(outL) ? safe_clamp(outL, -4.0f, 4.0f) : 0.0f;
        trackRight[i] = std::isfinite(outR) ? safe_clamp(outR, -4.0f, 4.0f) : 0.0f;

        runtime.phaseL += omega;
        runtime.phaseR += omega;
        if (runtime.phaseL > 1.0e6) runtime.phaseL -= 1.0e6;
        if (runtime.phaseR > 1.0e6) runtime.phaseR -= 1.0e6;
    }
}

} // namespace audioapp