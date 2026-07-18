#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "TestChainHelper.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/devices/SplitMode.hpp"

#include <cmath>
#include <cstring>
#include <memory>

namespace {

/// Builds an oscillator -> split chain and compares it against an
/// oscillator-only render to prove an empty branch pair is transparent.
void renderOscillatorThroughSplit(audioapp::SplitMode mode, int frames, double sampleRate,
                                  float* left, float* right) {
    auto playback = std::make_shared<audioapp::SplitPlayback>();
    playback->mode = mode;

    audioapp::DeviceNodePlayback devices[2] = {};
    devices[0].kind = audioapp::DeviceNodeKind::Oscillator;
    devices[0].gain = 1.0f;
    devices[0].pan = 0.5f;
    devices[0].params = audioapp::OscillatorParams{440.0f};
    devices[1].kind = audioapp::DeviceNodeKind::Split;
    devices[1].gain = 1.0f;
    devices[1].pan = 0.5f;
    devices[1].params = audioapp::SplitParams{playback};

    audioapp::test::processTestChain(left, right, frames, sampleRate, 120, 0.0,
                                     nullptr, 0, devices, 2, false);
}

void renderOscillatorOnly(int frames, double sampleRate, float* left, float* right) {
    audioapp::DeviceNodePlayback devices[1] = {};
    devices[0].kind = audioapp::DeviceNodeKind::Oscillator;
    devices[0].gain = 1.0f;
    devices[0].pan = 0.5f;
    devices[0].params = audioapp::OscillatorParams{440.0f};

    audioapp::test::processTestChain(left, right, frames, sampleRate, 120, 0.0,
                                     nullptr, 0, devices, 1, false);
}

float maxAbsDiff(const float* a, const float* b, int count) noexcept {
    float worst = 0.0f;
    for (int i = 0; i < count; ++i) worst = std::max(worst, std::abs(a[i] - b[i]));
    return worst;
}

} // namespace

class SplitProcessorTest : public juce::UnitTest {
public:
    SplitProcessorTest() : juce::UnitTest("SplitProcessor", "Devices") {}

    void runTest() override {
        constexpr int kFrames = 512;
        constexpr double kSampleRate = 48000.0;

        beginTest("empty LR split is transparent (stereo passthrough)");
        {
            float dryL[kFrames], dryR[kFrames];
            float wetL[kFrames], wetR[kFrames];
            std::memset(dryL, 0, sizeof(dryL));
            std::memset(dryR, 0, sizeof(dryR));
            std::memset(wetL, 0, sizeof(wetL));
            std::memset(wetR, 0, sizeof(wetR));

            renderOscillatorOnly(kFrames, kSampleRate, dryL, dryR);
            renderOscillatorThroughSplit(audioapp::SplitMode::Lr, kFrames, kSampleRate, wetL, wetR);

            expect(audioapp::test::peakAbs(dryL, kFrames) > 0.01f,
                   "oscillator should produce non-trivial output");
            expect(maxAbsDiff(dryL, wetL, kFrames) <= 1.0e-5f,
                   "empty LR split should leave the left channel unchanged");
            expect(maxAbsDiff(dryR, wetR, kFrames) <= 1.0e-5f,
                   "empty LR split should leave the right channel unchanged");
        }

        beginTest("empty Mid-Side split is transparent (stereo passthrough)");
        {
            float dryL[kFrames], dryR[kFrames];
            float wetL[kFrames], wetR[kFrames];
            std::memset(dryL, 0, sizeof(dryL));
            std::memset(dryR, 0, sizeof(dryR));
            std::memset(wetL, 0, sizeof(wetL));
            std::memset(wetR, 0, sizeof(wetR));

            renderOscillatorOnly(kFrames, kSampleRate, dryL, dryR);
            renderOscillatorThroughSplit(audioapp::SplitMode::MidSide, kFrames, kSampleRate, wetL, wetR);

            expect(maxAbsDiff(dryL, wetL, kFrames) <= 1.0e-4f,
                   "empty Mid-Side split should reconstruct the left channel");
            expect(maxAbsDiff(dryR, wetR, kFrames) <= 1.0e-4f,
                   "empty Mid-Side split should reconstruct the right channel");
        }

        beginTest("empty LR split on left-only signal stays left-only");
        {
            float left[kFrames], right[kFrames];
            std::memset(left, 0, sizeof(left));
            std::memset(right, 0, sizeof(right));
            for (int i = 0; i < kFrames; ++i) left[i] = std::sin(static_cast<float>(i) * 0.1f);

            auto playback = std::make_shared<audioapp::SplitPlayback>();
            playback->mode = audioapp::SplitMode::Lr;
            audioapp::DeviceNodePlayback devices[1] = {};
            devices[0].kind = audioapp::DeviceNodeKind::Split;
            devices[0].gain = 1.0f;
            devices[0].pan = 0.5f;
            devices[0].params = audioapp::SplitParams{playback};

            float beforeLeft[kFrames];
            std::memcpy(beforeLeft, left, sizeof(left));
            audioapp::test::processTestChain(left, right, kFrames, kSampleRate, 120, 0.0,
                                             nullptr, 0, devices, 1, false);
            expect(maxAbsDiff(left, beforeLeft, kFrames) <= 1.0e-5f,
                   "left-only signal should pass through the L branch unchanged");
            expect(audioapp::test::peakAbs(right, kFrames) <= 1.0e-5f,
                   "right channel should remain silent for a left-only signal");
        }
    }
};

static SplitProcessorTest splitProcessorTest;
