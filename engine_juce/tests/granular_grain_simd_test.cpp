#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/GranularGrainSimd.hpp"
#include "audioapp/GranularAlgorithm.hpp"

#include <cmath>
#include <vector>

using namespace audioapp;

class GranularGrainSimdTest : public juce::UnitTest {
public:
    GranularGrainSimdTest() : juce::UnitTest("GranularGrainSimd", "Audio") {}

    void runTest() override {
        beginTest("SIMD grain bank matches scalar");
        {
            std::vector<float> pcm(512);
            for (int i = 0; i < 512; ++i) {
                pcm[static_cast<size_t>(i)] =
                    std::sin(6.28318530718f * static_cast<float>(i) / 256.0f);
            }

            for (int grainCount : {1, 3, 4, 5, 8}) {
                float phases[kGranularMaxGrains]{};
                float positions[kGranularMaxGrains]{};
                float pans[kGranularMaxGrains]{};
                for (int g = 0; g < grainCount; ++g) {
                    phases[g] = 0.1f + 0.08f * static_cast<float>(g);
                    positions[g] = 10.0f + 3.5f * static_cast<float>(g);
                    pans[g] = 0.25f + 0.07f * static_cast<float>(g);
                }

                float simdL = 0.0f, simdR = 0.0f;
                const bool ok = renderGranularGrainBankSimd(
                    pcm.data(), 512, phases, positions, pans, grainCount, 0.7f,
                    simdL, simdR, true);
                expect(ok, "SIMD available");
                if (!ok) continue;

                float scalarL = 0.0f, scalarR = 0.0f;
                for (int g = 0; g < grainCount; ++g) {
                    const float window =
                        0.5f - 0.5f * std::cos(phases[g] * 2.0f * 3.14159265358979323846f);
                    const int index = std::min(static_cast<int>(positions[g]), 510);
                    const float fraction = positions[g] - static_cast<float>(index);
                    const float sample =
                        pcm[static_cast<size_t>(index)] * (1.0f - fraction) +
                        pcm[static_cast<size_t>(index + 1)] * fraction;
                    const float value = sample * window * 0.7f;
                    const float pan = std::clamp(pans[g], 0.0f, 1.0f);
                    scalarL += value * std::sqrt(1.0f - pan);
                    scalarR += value * std::sqrt(pan);
                }
                expectWithinAbsoluteError(simdL, scalarL, 1.0e-4f, "left");
                expectWithinAbsoluteError(simdR, scalarR, 1.0e-4f, "right");
            }
        }

        beginTest("live voice helper audible");
        {
            std::vector<float> pcm(4096);
            for (int i = 0; i < 4096; ++i) {
                pcm[static_cast<size_t>(i)] =
                    0.5f * std::sin(6.28318530718f * 110.0f * static_cast<float>(i) / 48000.0f);
            }
            GranularParams params;
            params.pcm = pcm.data();
            params.frameCount = 4096;
            params.pcmRate = 48000.0;
            params.density = 0.5f;
            params.size = 0.4f;
            float z1[3]{}, z2[3]{};
            float peak = 0.0f;
            for (int i = 0; i < 2048; ++i) {
                const float s = granularLiveVoiceSample(
                    params, 60, 100.0f, static_cast<double>(i) / 48000.0, 2.0, 48000.0, z1, z2);
                peak = std::max(peak, std::abs(s));
            }
            expect(peak > 1.0e-4f, "live granular audible");
        }
    }
};

static GranularGrainSimdTest granularGrainSimdTest;
