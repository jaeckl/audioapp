#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/WavetableOscSimd.hpp"
#include "audioapp/WavetableSynthAlgorithm.hpp"

#include <cmath>
#include <cstring>
#include <vector>

using namespace audioapp;

class WavetableOscSimdTest : public juce::UnitTest {
public:
    WavetableOscSimdTest() : juce::UnitTest("WavetableOscSimd", "Audio") {}

    void runTest() override {
        beginTest("SIMD unison bank matches scalar reference");
        {
            const auto table = makeSineWavetable(4, 256);
            constexpr float kSampleRate = 48000.0f;
            constexpr float kInvSr = 1.0f / kSampleRate;
            constexpr float kRootHz = 220.0f;
            constexpr float kFrameIndex = 1.35f;

            for (int unisonCount : {1, 3, 4, 5, 8}) {
                float ratios[kWavetableMaxUnison]{};
                float simdPhases[kWavetableMaxUnison]{};
                float scalarPhases[kWavetableMaxUnison]{};
                for (int u = 0; u < unisonCount; ++u) {
                    const float spread = unisonCount > 1
                        ? (static_cast<float>(u) / static_cast<float>(unisonCount - 1) - 0.5f) * 2.0f
                        : 0.0f;
                    ratios[u] = std::pow(2.0f, (spread * 25.0f) / 1200.0f);
                    simdPhases[u] = 0.07f * static_cast<float>(u + 1);
                    scalarPhases[u] = simdPhases[u];
                }

                float simdSum = 0.0f;
                const bool simdOk = renderWavetableUnisonBankSimd(
                    table.data(), 4, 256, kFrameIndex, kRootHz, ratios, unisonCount,
                    kInvSr, simdPhases, simdSum);

                float scalarSum = 0.0f;
                for (int u = 0; u < unisonCount; ++u) {
                    scalarPhases[u] += kRootHz * ratios[u] * kInvSr;
                    if (scalarPhases[u] >= 1.0f) {
                        scalarPhases[u] -= std::floor(scalarPhases[u]);
                    }
                    scalarSum += wavetableInterpolatedSample(
                        table.data(), 4, 256, kFrameIndex, scalarPhases[u]);
                }
                scalarSum /= static_cast<float>(unisonCount);

                expect(simdOk, juce::String("SIMD path for unison=") + juce::String(unisonCount));
                if (!simdOk) continue;

                for (int u = 0; u < unisonCount; ++u) {
                    expectWithinAbsoluteError(
                        simdPhases[u], scalarPhases[u], 1.0e-5f,
                        juce::String("phase lane ") + juce::String(u) +
                            " unison=" + juce::String(unisonCount));
                }
                expectWithinAbsoluteError(
                    simdSum, scalarSum, 1.0e-4f,
                    juce::String("bank sum unison=") + juce::String(unisonCount));
            }
        }

        beginTest("max-unison voice render audible");
        {
            const auto table = makeSineWavetable(4, 256);
            WavetableMidiNoteRegion notes[] = {
                {60, 0, 0.0, 4.0, 0.0, 4.0, 100.0f, false, 4.0},
            };
            WavetableSynthParamsPlayback params;
            params.wtUnison = 1.0f;
            params.wtDetune = 0.7f;
            params.filterCutoff = 0.7f;
            WavetableSynthRuntime runtime{};
            constexpr int kFrames = 1024;
            std::vector<float> out(static_cast<size_t>(kFrames), 0.0f);
            mixWavetableMidiNotesBlock(out.data(),
                                       kFrames,
                                       48000.0,
                                       120,
                                       0.0,
                                       notes,
                                       1,
                                       params,
                                       runtime,
                                       table.data(),
                                       4,
                                       256);
            expect(audioapp::test::peakAbs(out.data(), kFrames) > 1.0e-4f,
                   "max-unison SIMD render audible");
        }
    }

private:
    static std::vector<float> makeSineWavetable(int frameCount, int frameLength) {
        std::vector<float> pcm(static_cast<size_t>(frameCount * frameLength), 0.0f);
        for (int frame = 0; frame < frameCount; ++frame) {
            for (int i = 0; i < frameLength; ++i) {
                const float phase =
                    6.28318530718f * static_cast<float>(i) / static_cast<float>(frameLength);
                pcm[static_cast<size_t>(frame * frameLength + i)] =
                    std::sin(phase) * (0.4f + 0.15f * static_cast<float>(frame));
            }
        }
        return pcm;
    }
};

static WavetableOscSimdTest wavetableOscSimdTest;
