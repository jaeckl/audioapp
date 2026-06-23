// FrequencyFxTest - DSP-level tests for the three frequency FX processors:
// filter (LP/HP/BP/Notch), 4-band EQ, and frequency shifter.
#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/FrequencyFxProcessor.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <random>
#include <vector>

namespace {

// Fill `buf` with a sine wave of `freqHz` at `sampleRate`.
// `amplitude` is the peak amplitude (default 0.5 to avoid clipping).
void fillSine(std::vector<float>& buf, double sampleRate, double freqHz, double amplitude = 0.5) {
    for (size_t i = 0; i < buf.size(); ++i) {
        buf[i] = static_cast<float>(amplitude * std::sin(
            2.0 * juce::MathConstants<double>::pi * freqHz * static_cast<double>(i) / sampleRate));
    }
}

// Peak absolute sample value of a mono buffer.
float peakAbsBuf(const std::vector<float>& buf) {
    return audioapp::test::peak(buf, 0, static_cast<int>(buf.size()));
}

// True if every sample is finite (no NaN/Inf).
bool allFinite(const std::vector<float>& buf) {
    for (float v : buf) {
        if (!std::isfinite(v)) return false;
    }
    return true;
}

} // namespace

class FrequencyFxTest : public juce::UnitTest {
public:
    FrequencyFxTest() : juce::UnitTest("FrequencyFx", "FrequencyFx") {}

    void runTest() override
    {
        constexpr int kFrames = 4096;
        constexpr double kSampleRate = 48000.0;

        // --- Filter tests ---

        beginTest("filter silence in silence out");
        {
            std::vector<float> left(kFrames, 0.0f);
            std::vector<float> right(kFrames, 0.0f);
            audioapp::FilterParams params;
            params.cutoffHz = 1000.0f;
            params.resonance = 0.707f;
            params.filterMode = 0; // LP
            audioapp::FilterRuntime runtime;
            audioapp::processFilterStereoBlock(left.data(), right.data(), kFrames,
                                                kSampleRate, params, runtime);
            expect(peakAbsBuf(left) <= 1.0e-6f, "left should remain silent");
            expect(peakAbsBuf(right) <= 1.0e-6f, "right should remain silent");
        }

        beginTest("filter LP preserves low freq");
        {
            // 100 Hz sine, LP@1000Hz, Q=0.7 — well below cutoff so passes.
            std::vector<float> left(kFrames);
            std::vector<float> right(kFrames);
            fillSine(left, kSampleRate, 100.0);
            fillSine(right, kSampleRate, 100.0);
            const float inputPeak = peakAbsBuf(left);

            audioapp::FilterParams params;
            params.cutoffHz = 1000.0f;
            params.resonance = 0.707f;
            params.filterMode = 0; // LP
            audioapp::FilterRuntime runtime;
            audioapp::processFilterStereoBlock(left.data(), right.data(), kFrames,
                                                kSampleRate, params, runtime);
            const float outputPeak = peakAbsBuf(left);
            expect(outputPeak > inputPeak * 0.9f,
                   "LP@1000Hz should pass 100 Hz sine (peak > 90% of input)");
        }

        beginTest("filter HP attenuates low freq");
        {
            // 100 Hz sine, HP@500Hz, Q=0.7 — well below cutoff so rejected.
            std::vector<float> left(kFrames);
            std::vector<float> right(kFrames);
            fillSine(left, kSampleRate, 100.0);
            fillSine(right, kSampleRate, 100.0);
            const float inputPeak = peakAbsBuf(left);

            audioapp::FilterParams params;
            params.cutoffHz = 500.0f;
            params.resonance = 0.707f;
            params.filterMode = 1; // HP
            audioapp::FilterRuntime runtime;
            audioapp::processFilterStereoBlock(left.data(), right.data(), kFrames,
                                                kSampleRate, params, runtime);
            const float outputPeak = peakAbsBuf(left);
            expect(outputPeak < inputPeak * 0.1f,
                   "HP@500Hz should reject 100 Hz sine (peak < 10% of input)");
        }

        beginTest("filter BP passes center");
        {
            // 500 Hz sine, BP@500Hz, Q=2 — at the band center so passes.
            std::vector<float> left(kFrames);
            std::vector<float> right(kFrames);
            fillSine(left, kSampleRate, 500.0);
            fillSine(right, kSampleRate, 500.0);
            const float inputPeak = peakAbsBuf(left);

            audioapp::FilterParams params;
            params.cutoffHz = 500.0f;
            params.resonance = 2.0f;
            params.filterMode = 2; // BP
            audioapp::FilterRuntime runtime;
            audioapp::processFilterStereoBlock(left.data(), right.data(), kFrames,
                                                kSampleRate, params, runtime);
            const float outputPeak = peakAbsBuf(left);
            expect(outputPeak > inputPeak * 0.5f,
                   "BP@500Hz should pass 500 Hz sine (peak > 50% of input)");
        }

        beginTest("filter notch attenuates center");
        {
            // 500 Hz sine, Notch@500Hz, Q=5 — at the notch center so rejected.
            std::vector<float> left(kFrames);
            std::vector<float> right(kFrames);
            fillSine(left, kSampleRate, 500.0);
            fillSine(right, kSampleRate, 500.0);
            const float inputPeak = peakAbsBuf(left);

            audioapp::FilterParams params;
            params.cutoffHz = 500.0f;
            params.resonance = 5.0f;
            params.filterMode = 3; // Notch
            audioapp::FilterRuntime runtime;
            audioapp::processFilterStereoBlock(left.data(), right.data(), kFrames,
                                                kSampleRate, params, runtime);

            // The biquad starts from zero state (z1=z2=0) and the input
            // sine has a step-like start, so the first ~150 samples contain
            // the filter's impulse-response transient. Skip those and
            // measure the steady-state peak on the tail.
            constexpr int kSettle = 256;
            float tailPeak = 0.0f;
            for (int i = kSettle; i < kFrames; ++i) {
                const float a = std::fabs(left[i]);
                if (a > tailPeak) tailPeak = a;
            }
            expect(tailPeak < inputPeak * 0.5f,
                   "Notch@500Hz should reject 500 Hz sine (steady-state peak < 50% of input)");
        }

        beginTest("filter different modes differ");
        {
            // Same input processed through LP and HP — outputs should differ.
            std::vector<float> lpLeft(kFrames);
            std::vector<float> lpRight(kFrames);
            fillSine(lpLeft, kSampleRate, 200.0);
            fillSine(lpRight, kSampleRate, 200.0);

            audioapp::FilterParams lpParams;
            lpParams.cutoffHz = 1000.0f;
            lpParams.resonance = 0.707f;
            lpParams.filterMode = 0; // LP
            audioapp::FilterRuntime lpRuntime;
            audioapp::processFilterStereoBlock(lpLeft.data(), lpRight.data(), kFrames,
                                                kSampleRate, lpParams, lpRuntime);

            std::vector<float> hpLeft(kFrames);
            std::vector<float> hpRight(kFrames);
            fillSine(hpLeft, kSampleRate, 200.0);
            fillSine(hpRight, kSampleRate, 200.0);

            audioapp::FilterParams hpParams;
            hpParams.cutoffHz = 1000.0f;
            hpParams.resonance = 0.707f;
            hpParams.filterMode = 1; // HP
            audioapp::FilterRuntime hpRuntime;
            audioapp::processFilterStereoBlock(hpLeft.data(), hpRight.data(), kFrames,
                                                kSampleRate, hpParams, hpRuntime);

            // Compute peak difference between the two outputs.
            float maxDiff = 0.0f;
            for (int i = 0; i < kFrames; ++i) {
                const float d = std::fabs(lpLeft[i] - hpLeft[i]);
                if (d > maxDiff) maxDiff = d;
            }
            expect(maxDiff > 0.05f, "LP vs HP outputs should differ significantly");
        }

        // --- EQ tests ---

        beginTest("eq identity at zero dB");
        {
            // All bands at gainDb=0 → unity gain at most frequencies.
            std::vector<float> left(kFrames);
            std::vector<float> right(kFrames);
            fillSine(left, kSampleRate, 1000.0);
            fillSine(right, kSampleRate, 1000.0);
            const float inputPeak = peakAbsBuf(left);

            audioapp::FourBandEqParams params;
            for (int b = 0; b < 4; ++b) {
                params.bands[b].frequencyHz = 1000.0f;
                params.bands[b].gainDb = 0.0f;
                params.bands[b].q = 0.707f;
            }
            audioapp::FourBandEqRuntime runtime;
            audioapp::processFourBandEqStereoBlock(left.data(), right.data(), kFrames,
                                                    kSampleRate, params, runtime);
            const float outputPeak = peakAbsBuf(left);
            // ±1 dB tolerance: ratio is ~0.89 to 1.12.
            const float ratio = outputPeak / std::max(inputPeak, 1.0e-9f);
            expect(ratio > 0.89f && ratio < 1.12f,
                   "EQ at 0 dB should pass 1 kHz near unity (±1 dB)");
        }

        beginTest("eq low shelf boost");
        {
            // Low shelf at 100 Hz, +12 dB → boosts 100 Hz sine.
            std::vector<float> left(kFrames);
            std::vector<float> right(kFrames);
            fillSine(left, kSampleRate, 100.0);
            fillSine(right, kSampleRate, 100.0);
            const float inputPeak = peakAbsBuf(left);

            audioapp::FourBandEqParams params;
            params.bands[0].frequencyHz = 100.0f;
            params.bands[0].gainDb = 12.0f;
            params.bands[0].q = 0.707f;
            for (int b = 1; b < 4; ++b) {
                params.bands[b].frequencyHz = 1000.0f;
                params.bands[b].gainDb = 0.0f;
                params.bands[b].q = 0.707f;
            }
            audioapp::FourBandEqRuntime runtime;
            audioapp::processFourBandEqStereoBlock(left.data(), right.data(), kFrames,
                                                    kSampleRate, params, runtime);
            const float outputPeak = peakAbsBuf(left);
            expect(outputPeak > inputPeak,
                   "Low shelf +12 dB at 100 Hz should boost 100 Hz sine");
        }

        beginTest("eq high shelf cut");
        {
            // High shelf at 5 kHz, -12 dB → attenuates 5 kHz sine.
            std::vector<float> left(kFrames);
            std::vector<float> right(kFrames);
            fillSine(left, kSampleRate, 5000.0);
            fillSine(right, kSampleRate, 5000.0);
            const float inputPeak = peakAbsBuf(left);

            audioapp::FourBandEqParams params;
            params.bands[3].frequencyHz = 5000.0f;
            params.bands[3].gainDb = -12.0f;
            params.bands[3].q = 0.707f;
            for (int b = 0; b < 3; ++b) {
                params.bands[b].frequencyHz = 100.0f;
                params.bands[b].gainDb = 0.0f;
                params.bands[b].q = 0.707f;
            }
            audioapp::FourBandEqRuntime runtime;
            audioapp::processFourBandEqStereoBlock(left.data(), right.data(), kFrames,
                                                    kSampleRate, params, runtime);
            const float outputPeak = peakAbsBuf(left);
            expect(outputPeak < inputPeak,
                   "High shelf -12 dB at 5 kHz should attenuate 5 kHz sine");
        }

        // --- Frequency shifter tests ---

        beginTest("freq shifter center passes");
        {
            // shift=0 → output should equal input (cos(0)=1 every sample).
            std::vector<float> left(kFrames);
            std::vector<float> right(kFrames);
            fillSine(left, kSampleRate, 440.0);
            fillSine(right, kSampleRate, 440.0);
            const std::vector<float> origLeft = left;
            const std::vector<float> origRight = right;

            audioapp::FrequencyShifterParams params;
            params.shiftHz = 0.0f;
            audioapp::FrequencyShifterRuntime runtime;
            audioapp::processFrequencyShifterStereoBlock(left.data(), right.data(), kFrames,
                                                          kSampleRate, params, runtime);

            float maxDiffL = 0.0f;
            float maxDiffR = 0.0f;
            for (int i = 0; i < kFrames; ++i) {
                const float dL = std::fabs(left[i] - origLeft[i]);
                const float dR = std::fabs(right[i] - origRight[i]);
                if (dL > maxDiffL) maxDiffL = dL;
                if (dR > maxDiffR) maxDiffR = dR;
            }
            expect(maxDiffL < 1.0e-3f, "shift=0 should leave left nearly unchanged");
            expect(maxDiffR < 1.0e-3f, "shift=0 should leave right nearly unchanged");
        }

        beginTest("freq shifter nonzero modulates");
        {
            // shift=1000 Hz → ring modulation moves energy around.
            std::vector<float> left(kFrames);
            std::vector<float> right(kFrames);
            fillSine(left, kSampleRate, 440.0);
            fillSine(right, kSampleRate, 440.0);
            const std::vector<float> origLeft = left;

            audioapp::FrequencyShifterParams params;
            params.shiftHz = 1000.0f;
            audioapp::FrequencyShifterRuntime runtime;
            audioapp::processFrequencyShifterStereoBlock(left.data(), right.data(), kFrames,
                                                          kSampleRate, params, runtime);

            // Ring modulation produces sum/difference sidebands; with shift=1000
            // and input=440, expect at least one peak with amplitude > 0.3 of input.
            float maxDiff = 0.0f;
            for (int i = 0; i < kFrames; ++i) {
                const float d = std::fabs(left[i] - origLeft[i]);
                if (d > maxDiff) maxDiff = d;
            }
            expect(maxDiff > 0.3f, "shift=1000 Hz should modulate the input");
        }

        beginTest("freq shifter zero input");
        {
            std::vector<float> left(kFrames, 0.0f);
            std::vector<float> right(kFrames, 0.0f);
            audioapp::FrequencyShifterParams params;
            params.shiftHz = 1000.0f;
            audioapp::FrequencyShifterRuntime runtime;
            audioapp::processFrequencyShifterStereoBlock(left.data(), right.data(), kFrames,
                                                          kSampleRate, params, runtime);
            expect(peakAbsBuf(left) <= 1.0e-6f, "zero input + shift=1000 → left silent");
            expect(peakAbsBuf(right) <= 1.0e-6f, "zero input + shift=1000 → right silent");
        }

        beginTest("ffx processing no crash");
        {
            // Random parameters across all three processors with random input.
            std::mt19937 rng(0xC0FFEE);
            std::uniform_real_distribution<float> uniform(-1.0f, 1.0f);

            std::vector<float> left(kFrames);
            std::vector<float> right(kFrames);
            for (int i = 0; i < kFrames; ++i) {
                left[i] = uniform(rng);
                right[i] = uniform(rng);
            }

            audioapp::FilterParams fParams;
            fParams.cutoffHz = static_cast<float>(rng() % 20000);
            fParams.resonance = 0.5f + (rng() % 100) / 100.0f * 19.5f;
            fParams.filterMode = rng() % 4;
            audioapp::FilterRuntime fRuntime;
            audioapp::processFilterStereoBlock(left.data(), right.data(), kFrames,
                                                kSampleRate, fParams, fRuntime);
            expect(allFinite(left) && allFinite(right), "filter output finite");

            audioapp::FourBandEqParams eqParams;
            for (int b = 0; b < 4; ++b) {
                eqParams.bands[b].frequencyHz = static_cast<float>(rng() % 20000);
                eqParams.bands[b].gainDb = -24.0f + (rng() % 4800) / 100.0f;
                eqParams.bands[b].q = 0.1f + (rng() % 1900) / 100.0f;
            }
            audioapp::FourBandEqRuntime eqRuntime;
            audioapp::processFourBandEqStereoBlock(left.data(), right.data(), kFrames,
                                                    kSampleRate, eqParams, eqRuntime);
            expect(allFinite(left) && allFinite(right), "eq output finite");

            audioapp::FrequencyShifterParams fsParams;
            fsParams.shiftHz = -2000.0f + (rng() % 4000);
            audioapp::FrequencyShifterRuntime fsRuntime;
            audioapp::processFrequencyShifterStereoBlock(left.data(), right.data(), kFrames,
                                                          kSampleRate, fsParams, fsRuntime);
            expect(allFinite(left) && allFinite(right), "freq shifter output finite");
        }
    }
};

static FrequencyFxTest frequencyFxTest;