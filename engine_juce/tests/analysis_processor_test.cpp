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

std::array<float, 24> analyzeSine(const std::vector<int>& chunks,
                                  double sampleRate, float frequency,
                                  float dcOffset = 0.0f) {
    audioapp::AnalysisProcessor processor(
        audioapp::DeviceNodeKind::SpectrumAnalyzer);
    processor.meterSlot = 0;
    auto scratch = std::make_unique<audioapp::DeviceChainScratch>();
    audioapp::DeviceMeterAtomic meter[1]{};
    bool subscribed[1]{true};
    audioapp::ProcessContext context(*scratch);
    context.sampleRate = sampleRate;
    context.deviceMeters = meter;
    context.maxDeviceMeters = 1;
    context.meterSlotSubscribed = subscribed;

    constexpr int kSamples = 8192;
    int rendered = 0;
    int chunkIndex = 0;
    while (rendered < kSamples) {
        const int frames = std::min(
            chunks[static_cast<size_t>(chunkIndex % chunks.size())],
            kSamples - rendered);
        std::vector<float> left(static_cast<size_t>(frames));
        std::vector<float> right(static_cast<size_t>(frames));
        for (int frame = 0; frame < frames; ++frame) {
            const float sample = dcOffset + 0.5f * std::sin(static_cast<float>(
                2.0 * juce::MathConstants<double>::pi * frequency *
                static_cast<double>(rendered + frame) / sampleRate));
            left[static_cast<size_t>(frame)] = sample;
            right[static_cast<size_t>(frame)] = sample;
        }
        context.numFrames = frames;
        audioapp::AudioBlock block{left.data(), right.data(), frames};
        processor.process(block, context);
        rendered += frames;
        ++chunkIndex;
    }

    std::array<float, 24> result{};
    for (int band = 0; band < 24; ++band) {
        result[static_cast<size_t>(band)] =
            meter[0].spectrum[band].load(std::memory_order_relaxed);
    }
    return result;
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
    }
};

static AnalysisProcessorTest analysisProcessorTest;
