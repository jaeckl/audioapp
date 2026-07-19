#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/DeviceChainOrchestrator.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/FrequencyFxProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include "audioapp/dsp/ProcessContext.hpp"
#include "audioapp/dsp/ProcessorArena.hpp"

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

float peakAbs(const float* buf, int frames, int start = 0) {
    float p = 0.0f;
    for (int i = start; i < frames; ++i)
        p = std::max(p, std::abs(buf[i]));
    return p;
}

float rms(const float* buf, int frames, int start = 0) {
    double sum = 0.0;
    const int n = frames - start;
    if (n <= 0) return 0.0f;
    for (int i = start; i < frames; ++i)
        sum += static_cast<double>(buf[i]) * buf[i];
    return static_cast<float>(std::sqrt(sum / static_cast<double>(n)));
}

bool allFinite(const float* buf, int frames) {
    for (int i = 0; i < frames; ++i)
        if (!std::isfinite(buf[i])) return false;
    return true;
}

void clearNest(audioapp::SpectralLoudSplitPlayback& p) {
    p.preFx = {};
    p.postFx = {};
    for (auto& b : p.bands) b = {};
}

void resetGainsSolos(audioapp::SpectralLoudSplitPlayback& p) {
    p.highDb = -18.0f;
    p.lowDb = -40.0f;
    for (int i = 0; i < 3; ++i) {
        p.bandGain[i] = 1.0f;
        p.bandSolo[i] = 0.0f;
    }
}

struct Suite {
    std::unique_ptr<audioapp::DeviceChainScratch> scratch =
        std::make_unique<audioapp::DeviceChainScratch>();
    audioapp::ProcessorArena arena{1};
    audioapp::DeviceProcessor* proc = nullptr;
    std::shared_ptr<audioapp::SpectralLoudSplitPlayback> playback =
        std::make_shared<audioapp::SpectralLoudSplitPlayback>();
    audioapp::DeviceNodePlayback device{};
    audioapp::DeviceMeterAtomic meters[1]{};
    bool subscribed[1]{true};

    bool build() {
        device.kind = audioapp::DeviceNodeKind::SpectralLoudSplit;
        device.deviceId = "sl0";
        device.gain = 1.0f;
        device.pan = 0.5f;
        device.outputMix = 1.0f;
        device.meterSlot = 0;
        device.params = audioapp::SpectralLoudSplitParams{playback};
        audioapp::buildProcessorChain(&device, 1, arena);
        proc = arena.get(0);
        return proc != nullptr;
    }

    void process(float* left, float* right, int frames, float sr) {
        audioapp::ProcessContext ctx(*scratch);
        ctx.sampleRate = sr;
        ctx.numFrames = frames;
        ctx.bpm = 120;
        ctx.deviceMeters = meters;
        ctx.maxDeviceMeters = 1;
        ctx.meterSlotSubscribed = subscribed;
        audioapp::AudioBlock block{left, right, frames};
        proc->process(block, ctx);
    }

    void flush(float* left, float* right, int frames, float sr, float hz, float amp) {
        fillSine(left, right, frames, hz, sr, amp);
        process(left, right, frames, sr);
        fillSine(left, right, frames, hz, sr, amp);
        process(left, right, frames, sr);
    }

    void reinit() {
        proc->initParams(device.params);
        proc->resetPlaybackState();
    }
};

} // namespace

class SpectralLoudSplitProcessorTest : public juce::UnitTest {
public:
    SpectralLoudSplitProcessorTest()
        : juce::UnitTest("SpectralLoudSplitProcessor", "Devices") {}

    void runTest() override {
        constexpr int kFrames = 2048;
        constexpr float kSr = 48000.0f;
        constexpr int kSkip = 512;

        beginTest("build processor");
        Suite suite;
        expect(suite.build());
        if (suite.proc == nullptr) return;

        std::vector<float> left(static_cast<size_t>(kFrames));
        std::vector<float> right(static_cast<size_t>(kFrames));

        beginTest("passes signal with default thresholds");
        {
            resetGainsSolos(*suite.playback);
            clearNest(*suite.playback);
            suite.reinit();
            suite.flush(left.data(), right.data(), kFrames, kSr, 440.0f, 0.4f);
            expect(peakAbs(left.data(), kFrames, kSkip) > 0.01f);
            expect(allFinite(left.data(), kFrames));
        }

        beginTest("unity gains keep output near input amplitude (no hop buzz)");
        {
            resetGainsSolos(*suite.playback);
            clearNest(*suite.playback);
            suite.reinit();
            suite.flush(left.data(), right.data(), kFrames, kSr, 440.0f, 0.4f);
            const float outPeak = peakAbs(left.data(), kFrames, kFrames / 2);
            expect(outPeak > 0.25f);
            expect(outPeak < 0.55f);
        }

        beginTest("quiet-only full gain stays finite (no explode)");
        {
            resetGainsSolos(*suite.playback);
            suite.playback->bandGain[0] = 0.0f;
            suite.playback->bandGain[1] = 0.0f;
            suite.playback->bandGain[2] = 1.0f;
            suite.flush(left.data(), right.data(), kFrames, kSr, 440.0f, 0.4f);
            expect(allFinite(left.data(), kFrames));
            expect(peakAbs(left.data(), kFrames) < 2.0f);
        }

        beginTest("unity bands roughly conserve energy (partition of unity)");
        {
            resetGainsSolos(*suite.playback);
            suite.flush(left.data(), right.data(), kFrames, kSr, 440.0f, 0.4f);
            const float wet = rms(left.data(), kFrames, kSkip);
            expect(wet > 0.15f);
            expect(wet < 0.40f);
            expect(std::abs(wet - 0.283f) / 0.283f < 0.45f);
        }

        beginTest("loud solo keeps tonal energy; quiet solo quieter for loud sine");
        {
            resetGainsSolos(*suite.playback);
            suite.playback->bandSolo[0] = 1.0f;
            suite.flush(left.data(), right.data(), kFrames, kSr, 440.0f, 0.45f);
            const float loudRms = rms(left.data(), kFrames, kSkip);

            resetGainsSolos(*suite.playback);
            suite.playback->bandSolo[2] = 1.0f;
            suite.flush(left.data(), right.data(), kFrames, kSr, 440.0f, 0.45f);
            const float quietRms = rms(left.data(), kFrames, kSkip);

            expect(loudRms > 0.08f, "loud solo should keep sine energy");
            expect(quietRms < loudRms * 0.55f, "quiet solo quieter for loud tone");
        }

        beginTest("band gains scale output");
        {
            resetGainsSolos(*suite.playback);
            suite.flush(left.data(), right.data(), kFrames, kSr, 660.0f, 0.4f);
            const float fullPeak = peakAbs(left.data(), kFrames, kSkip);

            for (int i = 0; i < 3; ++i) suite.playback->bandGain[i] = 0.5f;
            suite.flush(left.data(), right.data(), kFrames, kSr, 660.0f, 0.4f);
            const float halfPeak = peakAbs(left.data(), kFrames, kSkip);

            expect(fullPeak > 0.1f);
            expect(halfPeak < fullPeak * 0.75f);
            expect(halfPeak > fullPeak * 0.25f);
        }

        beginTest("raising highDb moves energy out of loud band VU");
        {
            resetGainsSolos(*suite.playback);
            suite.playback->highDb = -30.0f;
            suite.playback->lowDb = -50.0f;
            suite.flush(left.data(), right.data(), kFrames, kSr, 440.0f, 0.5f);
            for (int i = 0; i < 4; ++i) {
                fillSine(left.data(), right.data(), kFrames, 440.0f, kSr, 0.5f);
                suite.process(left.data(), right.data(), kFrames, kSr);
            }
            const float loudVuLow = suite.meters[0].waveform[0].load();

            suite.playback->highDb = -6.0f;
            suite.playback->lowDb = -20.0f;
            suite.flush(left.data(), right.data(), kFrames, kSr, 440.0f, 0.5f);
            for (int i = 0; i < 4; ++i) {
                fillSine(left.data(), right.data(), kFrames, 440.0f, kSr, 0.5f);
                suite.process(left.data(), right.data(), kFrames, kSr);
            }
            const float loudVuHigh = suite.meters[0].waveform[0].load();

            expect(loudVuLow > 0.05f, "low highDb → more loud-band energy");
            expect(loudVuHigh < loudVuLow * 0.85f || loudVuHigh < 0.15f,
                   "higher highDb shrinks loud VU");
        }

        beginTest("meters publish band VU and spectrum when subscribed");
        {
            resetGainsSolos(*suite.playback);
            suite.flush(left.data(), right.data(), kFrames, kSr, 440.0f, 0.5f);
            for (int i = 0; i < 8; ++i) {
                fillSine(left.data(), right.data(), kFrames, 440.0f, kSr, 0.5f);
                suite.process(left.data(), right.data(), kFrames, kSr);
            }
            float spectrumPeak = 0.0f;
            for (int b = 0; b < 24; ++b)
                spectrumPeak = std::max(spectrumPeak, suite.meters[0].spectrum[b].load());
            expect(suite.meters[0].waveform[0].load() + suite.meters[0].waveform[1].load() +
                       suite.meters[0].waveform[2].load() >
                   0.05f);
            expect(spectrumPeak > 0.05f, "spectrum preview should publish");
            expect(suite.meters[0].inputPeak.load() > 0.01f);
        }

        beginTest("hop-rate amplitude modulation stays small (COLA)");
        {
            resetGainsSolos(*suite.playback);
            suite.flush(left.data(), right.data(), kFrames, kSr, 440.0f, 0.4f);
            constexpr int kHop = 256;
            float minHop = 1.0f;
            float maxHop = 0.0f;
            for (int start = kSkip; start + kHop <= kFrames; start += kHop) {
                const float p = peakAbs(left.data() + start, kHop);
                minHop = std::min(minHop, p);
                maxHop = std::max(maxHop, p);
            }
            expect(maxHop > 0.15f);
            expect((maxHop - minHop) / maxHop < 0.55f, "hop peak ripple too large");
        }

        beginTest("outputMix 0 ≈ dry; muted wet + mix1 ≈ silence");
        {
            // Direct process() does not apply fused outputMix — mimic orchestrator.
            resetGainsSolos(*suite.playback);
            clearNest(*suite.playback);
            for (int i = 0; i < 3; ++i) suite.playback->bandGain[i] = 0.0f;
            suite.reinit();

            std::vector<float> dryL(static_cast<size_t>(kFrames));
            std::vector<float> dryR(static_cast<size_t>(kFrames));
            fillSine(dryL.data(), dryR.data(), kFrames, 440.0f, kSr, 0.4f);
            fillSine(left.data(), right.data(), kFrames, 440.0f, kSr, 0.4f);
            suite.process(left.data(), right.data(), kFrames, kSr);
            fillSine(left.data(), right.data(), kFrames, 440.0f, kSr, 0.4f);
            std::memcpy(dryL.data(), left.data(), sizeof(float) * static_cast<size_t>(kFrames));
            std::memcpy(dryR.data(), right.data(), sizeof(float) * static_cast<size_t>(kFrames));
            suite.process(left.data(), right.data(), kFrames, kSr);
            // mix=0 → replace wet with dry
            audioapp::mixDryWet(left.data(), dryL.data(), kFrames, 0.0f);
            audioapp::mixDryWet(right.data(), dryR.data(), kFrames, 0.0f);
            float err = 0.0f;
            for (int i = kSkip; i < kFrames; ++i)
                err = std::max(err, std::abs(left[static_cast<size_t>(i)] - dryL[static_cast<size_t>(i)]));
            expect(err < 0.001f, "outputMix=0 keeps dry");

            // mix=1 + all band gains 0 → silence
            suite.flush(left.data(), right.data(), kFrames, kSr, 440.0f, 0.4f);
            expect(peakAbs(left.data(), kFrames, kSkip) < 0.08f);
        }

        beginTest("nested PRE FX gain 0 silences wet path");
        {
            resetGainsSolos(*suite.playback);
            clearNest(*suite.playback);
            suite.playback->preFx.deviceCount = 1;
            suite.playback->preFx.devices[0].kind = audioapp::DeviceNodeKind::Filter;
            suite.playback->preFx.devices[0].deviceId = "pre0";
            suite.playback->preFx.devices[0].gain = 0.0f;
            suite.playback->preFx.devices[0].params = audioapp::FilterParams{};
            suite.reinit();
            suite.flush(left.data(), right.data(), kFrames, kSr, 440.0f, 0.4f);
            expect(peakAbs(left.data(), kFrames, kSkip) < 0.08f);
        }

        beginTest("nested POST FX gain 0 silences output");
        {
            resetGainsSolos(*suite.playback);
            clearNest(*suite.playback);
            suite.playback->postFx.deviceCount = 1;
            suite.playback->postFx.devices[0].kind = audioapp::DeviceNodeKind::Filter;
            suite.playback->postFx.devices[0].deviceId = "post0";
            suite.playback->postFx.devices[0].gain = 0.0f;
            suite.playback->postFx.devices[0].params = audioapp::FilterParams{};
            suite.reinit();
            suite.flush(left.data(), right.data(), kFrames, kSr, 440.0f, 0.4f);
            expect(peakAbs(left.data(), kFrames, kSkip) < 0.08f);
        }

        beginTest("band nest FX gain 0 silences soloed band");
        {
            resetGainsSolos(*suite.playback);
            clearNest(*suite.playback);
            suite.playback->bands[0].deviceCount = 1;
            suite.playback->bands[0].devices[0].kind = audioapp::DeviceNodeKind::Filter;
            suite.playback->bands[0].devices[0].deviceId = "b0";
            suite.playback->bands[0].devices[0].gain = 0.0f;
            suite.playback->bands[0].devices[0].params = audioapp::FilterParams{};
            suite.playback->bandSolo[0] = 1.0f;
            suite.reinit();
            suite.flush(left.data(), right.data(), kFrames, kSr, 440.0f, 0.45f);
            expect(peakAbs(left.data(), kFrames, kSkip) < 0.1f);
        }
    }
};

static SpectralLoudSplitProcessorTest spectralLoudSplitProcessorTest;
