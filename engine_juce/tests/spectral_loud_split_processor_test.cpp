#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "TestChainHelper.hpp"
#include "audioapp/DeviceChain.hpp"

#include <cmath>
#include <cstring>
#include <memory>
#include <vector>

namespace {

void fillSine(float* left, float* right, int frames, float hz, float sr, float amp) {
    for (int i = 0; i < frames; ++i) {
        const float t = static_cast<float>(i) / sr;
        const float s = amp * std::sin(2.0f * 3.14159265f * hz * t);
        left[i] = s;
        right[i] = s;
    }
}

class SpectralLoudSplitProcessorTest : public juce::UnitTest {
public:
    SpectralLoudSplitProcessorTest()
        : juce::UnitTest("SpectralLoudSplitProcessor", "Devices") {}

    void runTest() override {
        beginTest("passes signal with default thresholds");
        constexpr int kFrames = 2048;
        constexpr float kSr = 48000.0f;
        std::vector<float> left(static_cast<size_t>(kFrames));
        std::vector<float> right(static_cast<size_t>(kFrames));
        fillSine(left.data(), right.data(), kFrames, 440.0f, kSr, 0.4f);

        auto playback = std::make_shared<audioapp::SpectralLoudSplitPlayback>();
        audioapp::DeviceNodePlayback devices[1]{};
        devices[0].kind = audioapp::DeviceNodeKind::SpectralLoudSplit;
        devices[0].deviceId = "sl0";
        devices[0].outputMix = 1.0f;
        devices[0].params = audioapp::SpectralLoudSplitParams{playback};

        audioapp::ProcessorArena arena(1);
        audioapp::buildProcessorChain(devices, 1, arena);
        auto* proc = arena.get(0);
        expect(proc != nullptr);

        audioapp::DeviceChainScratch scratch;
        audioapp::ProcessContext ctx(scratch);
        ctx.sampleRate = kSr;
        ctx.numFrames = kFrames;
        audioapp::AudioBlock block{left.data(), right.data(), kFrames};
        proc->process(block, ctx);

        fillSine(left.data(), right.data(), kFrames, 440.0f, kSr, 0.4f);
        proc->process(block, ctx);

        float peak = 0.0f;
        for (int i = 0; i < kFrames; ++i)
            peak = std::max(peak, std::max(std::abs(left[static_cast<size_t>(i)]),
                                           std::abs(right[static_cast<size_t>(i)])));
        expect(peak > 0.01f);

        beginTest("unity gains keep output near input amplitude (no hop buzz)");
        // After latency flush, peak should stay close to input amp (0.4), not
        // chopped by hop-rate AM. Allow STFT delay + soft reconstruction error.
        std::vector<float> inL(static_cast<size_t>(kFrames));
        std::vector<float> inR(static_cast<size_t>(kFrames));
        fillSine(inL.data(), inR.data(), kFrames, 440.0f, kSr, 0.4f);
        std::memcpy(left.data(), inL.data(), sizeof(float) * static_cast<size_t>(kFrames));
        std::memcpy(right.data(), inR.data(), sizeof(float) * static_cast<size_t>(kFrames));
        proc->process(block, ctx);
        fillSine(left.data(), right.data(), kFrames, 440.0f, kSr, 0.4f);
        proc->process(block, ctx);

        float outPeak = 0.0f;
        for (int i = kFrames / 2; i < kFrames; ++i)
            outPeak = std::max(outPeak, std::abs(left[static_cast<size_t>(i)]));
        expect(outPeak > 0.25f);
        expect(outPeak < 0.55f);

        beginTest("quiet-only full gain stays finite (no explode)");
        playback->bandGain[0] = 0.0f;
        playback->bandGain[1] = 0.0f;
        playback->bandGain[2] = 1.0f;
        fillSine(left.data(), right.data(), kFrames, 440.0f, kSr, 0.4f);
        proc->process(block, ctx);
        float quietPeak = 0.0f;
        bool finite = true;
        for (int i = 0; i < kFrames; ++i) {
            const float s = left[static_cast<size_t>(i)];
            if (!std::isfinite(s)) finite = false;
            quietPeak = std::max(quietPeak, std::abs(s));
        }
        expect(finite);
        expect(quietPeak < 2.0f);
    }
};

static SpectralLoudSplitProcessorTest spectralLoudSplitProcessorTest;

} // namespace
