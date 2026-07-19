#include <juce_core/juce_core.h>

#include "TestHelpers.h"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/devices/processors/AnalysisProcessor.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <memory>
#include <vector>

namespace {

struct AnalysisContext {
    std::unique_ptr<audioapp::DeviceChainScratch> scratch;
    audioapp::DeviceMeterAtomic meter[1]{};
    bool subscribed[1]{true};
    audioapp::ProcessContext context;
    audioapp::AnalysisProcessor processor;

    explicit AnalysisContext(double sampleRate)
        : scratch(std::make_unique<audioapp::DeviceChainScratch>()),
          context(*scratch),
          processor(audioapp::DeviceNodeKind::SpectrumAnalyzer) {
        processor.meterSlot = 0;
        context.sampleRate = sampleRate;
        context.deviceMeters = meter;
        context.maxDeviceMeters = 1;
        context.meterSlotSubscribed = subscribed;
    }

    void renderSine(int frames, float frequency, float dcOffset, int startSample) {
        std::vector<float> left(static_cast<size_t>(frames));
        std::vector<float> right(static_cast<size_t>(frames));
        for (int frame = 0; frame < frames; ++frame) {
            const float sample = dcOffset + 0.5f * std::sin(static_cast<float>(
                2.0 * juce::MathConstants<double>::pi * frequency *
                static_cast<double>(startSample + frame) / context.sampleRate));
            left[static_cast<size_t>(frame)] = sample;
            right[static_cast<size_t>(frame)] = sample;
        }
        context.numFrames = frames;
        audioapp::AudioBlock block{left.data(), right.data(), frames};
        processor.process(block, context);
    }

    std::array<float, 24> readSpectrum() const {
        std::array<float, 24> result{};
        for (int band = 0; band < 24; ++band) {
            result[static_cast<size_t>(band)] =
                meter[0].spectrum[band].load(std::memory_order_relaxed);
        }
        return result;
    }

    int peakBand(const std::array<float, 24>& spectrum) const {
        return static_cast<int>(std::distance(
            spectrum.begin(), std::max_element(spectrum.begin(), spectrum.end())));
    }
};

std::array<float, 24> analyzeSine(const std::vector<int>& chunks,
                                  double sampleRate, float frequency,
                                  float dcOffset = 0.0f) {
    AnalysisContext ctx(sampleRate);
    constexpr int kSamples = 8192;
    int rendered = 0;
    int chunkIndex = 0;
    while (rendered < kSamples) {
        const int frames = std::min(
            chunks[static_cast<size_t>(chunkIndex % chunks.size())],
            kSamples - rendered);
        ctx.renderSine(frames, frequency, dcOffset, rendered);
        rendered += frames;
        ++chunkIndex;
    }
    return ctx.readSpectrum();
}

std::vector<int> collectPublishPeaks(double sampleRate, float frequency,
                                     int totalSamples) {
    AnalysisContext ctx(sampleRate);
    std::vector<int> peaks;
    std::array<float, 24> previous{};
    bool havePrevious = false;
    int rendered = 0;
    while (rendered < totalSamples) {
        ctx.renderSine(64, frequency, 0.0f, rendered);
        rendered += 64;
        const auto spectrum = ctx.readSpectrum();
        if (!havePrevious) {
            previous = spectrum;
            havePrevious = true;
            peaks.push_back(ctx.peakBand(spectrum));
            continue;
        }
        float delta = 0.0f;
        for (int band = 0; band < 24; ++band) {
            delta = std::max(delta, std::abs(
                spectrum[static_cast<size_t>(band)] -
                previous[static_cast<size_t>(band)]));
        }
        if (delta > 0.02f) {
            peaks.push_back(ctx.peakBand(spectrum));
            previous = spectrum;
        }
    }
    return peaks;
}

} // namespace

class AnalysisProcessorTest : public juce::UnitTest {
public:
    AnalysisProcessorTest() : juce::UnitTest("AnalysisProcessor", "Devices") {}

    void runTest() override {
        for (const double sampleRate : {44100.0, 48000.0, 96000.0}) {
            beginTest("FFT identifies 1 kHz at " +
                      juce::String(static_cast<int>(sampleRate)) + " Hz");
            const auto spectrum = analyzeSine({257}, sampleRate, 1000.0f);
            const auto peak = static_cast<int>(std::distance(
                spectrum.begin(), std::max_element(spectrum.begin(), spectrum.end())));
            expect(peak >= 12 && peak <= 14,
                   "1 kHz should peak in its logarithmic frequency band");
            expect(spectrum[static_cast<size_t>(peak)] > 0.75f,
                   "1 kHz peak should be clearly visible");
        }

        beginTest("FFT windows are callback-boundary invariant");
        const auto regular = analyzeSine({512}, 48000.0, 1000.0f);
        const auto irregular = analyzeSine({1, 17, 257, 509}, 48000.0, 1000.0f);
        float difference = 0.0f;
        for (int band = 0; band < 24; ++band) {
            difference = std::max(difference, std::abs(
                regular[static_cast<size_t>(band)] -
                irregular[static_cast<size_t>(band)]));
        }
        expect(difference < 1.0e-5f,
               "fixed FFT windows must not depend on callback sizes");

        beginTest("DC is removed before windowing");
        const auto dc = analyzeSine({257}, 48000.0, 0.0f, 0.5f);
        expect(*std::max_element(dc.begin(), dc.end()) < 0.1f,
               "a DC signal should not leak into audible spectrum bands");

        beginTest("440 Hz peak band is stable across consecutive publish cycles");
        const auto peaks = collectPublishPeaks(48000.0, 440.0f, 16384);
        expect(peaks.size() >= 2, "expected at least two spectrum publishes");
        const int last = peaks.back();
        const int prev = peaks[static_cast<size_t>(peaks.size() - 2)];
        expect(std::abs(last - prev) <= 1,
               "440 Hz peak band should stay within one band across publishes");

        beginTest("1 kHz harmonic rejection keeps distant bands low");
        {
            const auto spectrum = analyzeSine({257}, 48000.0, 1000.0f);
            const int peak = static_cast<int>(std::distance(
                spectrum.begin(), std::max_element(spectrum.begin(), spectrum.end())));
            expect(spectrum[0] < 0.5f * spectrum[static_cast<size_t>(peak)],
                   "lowest band should stay well below the 1 kHz peak");
            expect(spectrum[static_cast<size_t>(peak)] - spectrum[0] > 0.4f,
                   "peak band should dominate the lowest band");
            expect(peak >= 12 && peak <= 14, "1 kHz should remain in expected band");
        }

        beginTest("resetPlaybackState clears stale spectrum peaks");
        {
            AnalysisContext ctx(48000.0);
            ctx.renderSine(8192, 1000.0f, 0.0f, 0);
            const auto beforeReset = ctx.readSpectrum();
            expect(*std::max_element(beforeReset.begin(), beforeReset.end()) > 0.5f,
                   "pre-reset spectrum should show a visible peak");
            ctx.processor.resetPlaybackState();
            for (int band = 0; band < 24; ++band) {
                ctx.meter[0].spectrum[band].store(0.0f, std::memory_order_relaxed);
            }
            ctx.renderSine(512, 0.0f, 0.0f, 8192);
            const auto afterReset = ctx.readSpectrum();
            expect(*std::max_element(afterReset.begin(), afterReset.end()) < 0.15f,
                   "after reset, silence should not resurrect the old 1 kHz peak");
        }

        beginTest("200 Hz and 4 kHz peak in expected bands at 48 kHz");
        {
            const auto low = analyzeSine({257}, 48000.0, 200.0f);
            const int lowPeak = static_cast<int>(std::distance(
                low.begin(), std::max_element(low.begin(), low.end())));
            expect(lowPeak >= 6 && lowPeak <= 10,
                   "200 Hz should peak in a low-mid logarithmic band");

            const auto high = analyzeSine({257}, 48000.0, 4000.0f);
            const int highPeak = static_cast<int>(std::distance(
                high.begin(), std::max_element(high.begin(), high.end())));
            expect(highPeak >= 17 && highPeak <= 21,
                   "4 kHz should peak in an upper-mid logarithmic band");
        }
    }
};

static AnalysisProcessorTest analysisProcessorTest;
