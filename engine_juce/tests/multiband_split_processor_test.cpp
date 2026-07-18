#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "TestChainHelper.hpp"
#include "audioapp/DeviceChain.hpp"

#include <cmath>
#include <cstring>
#include <memory>

namespace {

void renderThroughMultiband(int bandCount, int frames, double sampleRate,
                            float* left, float* right) {
    auto playback = std::make_shared<audioapp::MultibandSplitPlayback>();
    playback->bandCount = bandCount;
    if (bandCount == 2) {
        playback->crossoverHz[0] = 1000.0f;
    } else if (bandCount == 3) {
        playback->crossoverHz[0] = 200.0f;
        playback->crossoverHz[1] = 2000.0f;
    } else {
        playback->crossoverHz[0] = 100.0f;
        playback->crossoverHz[1] = 500.0f;
        playback->crossoverHz[2] = 2000.0f;
    }
    for (int b = 0; b < 4; ++b) playback->bandGain[b] = 1.0f;

    audioapp::DeviceNodePlayback devices[1] = {};
    devices[0].kind = audioapp::DeviceNodeKind::MultibandSplit;
    devices[0].gain = 1.0f;
    devices[0].pan = 0.5f;
    devices[0].params = audioapp::MultibandSplitParams{playback};

    audioapp::test::processTestChain(left, right, frames, sampleRate, 120, 0.0,
                                     nullptr, 0, devices, 1, false);
}

float rms(const float* a, int count) noexcept {
    double sum = 0.0;
    for (int i = 0; i < count; ++i) sum += static_cast<double>(a[i]) * a[i];
    return static_cast<float>(std::sqrt(sum / static_cast<double>(count)));
}

} // namespace

class MultibandSplitProcessorTest : public juce::UnitTest {
public:
    MultibandSplitProcessorTest()
        : juce::UnitTest("MultibandSplitProcessor", "Devices") {}

    void runTest() override {
        constexpr int kFrames = 2048;
        constexpr double kSampleRate = 48000.0;

        beginTest("empty 2-band MB split approximately reconstructs (energy smoke)");
        {
            float dryL[kFrames], dryR[kFrames];
            float wetL[kFrames], wetR[kFrames];
            std::memset(dryL, 0, sizeof(dryL));
            std::memset(dryR, 0, sizeof(dryR));
            std::memset(wetL, 0, sizeof(wetL));
            std::memset(wetR, 0, sizeof(wetR));
            for (int i = 0; i < kFrames; ++i) {
                const float t = static_cast<float>(i) / static_cast<float>(kSampleRate);
                dryL[i] = 0.5f * std::sin(2.0f * 3.14159265f * 440.0f * t);
                dryR[i] = 0.5f * std::sin(2.0f * 3.14159265f * 660.0f * t);
                wetL[i] = dryL[i];
                wetR[i] = dryR[i];
            }

            renderThroughMultiband(2, kFrames, kSampleRate, wetL, wetR);

            // Skip filter transient; LR complementary sum ≈ input in steady state.
            constexpr int kSkip = 512;
            const float dryRmsL = rms(dryL + kSkip, kFrames - kSkip);
            const float wetRmsL = rms(wetL + kSkip, kFrames - kSkip);
            const float dryRmsR = rms(dryR + kSkip, kFrames - kSkip);
            const float wetRmsR = rms(wetR + kSkip, kFrames - kSkip);
            expect(dryRmsL > 0.01f, "dry left should have energy");
            expect(std::abs(wetRmsL - dryRmsL) / dryRmsL < 0.15f,
                   "2-band empty MB split should conserve left energy within 15%");
            expect(std::abs(wetRmsR - dryRmsR) / dryRmsR < 0.15f,
                   "2-band empty MB split should conserve right energy within 15%");
            // Sample-accurate identity not expected: LR4 sum is allpass (phase), not zero delay.
        }

        beginTest("empty 4-band MB split energy smoke");
        {
            float dryL[kFrames], wetL[kFrames], wetR[kFrames];
            std::memset(dryL, 0, sizeof(dryL));
            std::memset(wetL, 0, sizeof(wetL));
            std::memset(wetR, 0, sizeof(wetR));
            for (int i = 0; i < kFrames; ++i) {
                const float t = static_cast<float>(i) / static_cast<float>(kSampleRate);
                dryL[i] = 0.4f * std::sin(2.0f * 3.14159265f * 880.0f * t);
                wetL[i] = dryL[i];
                wetR[i] = dryL[i];
            }
            renderThroughMultiband(4, kFrames, kSampleRate, wetL, wetR);
            constexpr int kSkip = 768;
            const float dryRms = rms(dryL + kSkip, kFrames - kSkip);
            const float wetRms = rms(wetL + kSkip, kFrames - kSkip);
            expect(dryRms > 0.01f, "dry should have energy");
            expect(std::abs(wetRms - dryRms) / dryRms < 0.25f,
                   "4-band empty MB split should roughly conserve energy");
        }
    }
};

static MultibandSplitProcessorTest multibandSplitProcessorTest;
