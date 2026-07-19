#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/AutomationTypes.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/GranularAlgorithm.hpp"

#include <cmath>
#include <vector>

using namespace audioapp;

class GranularControlRateTest : public juce::UnitTest {
public:
    GranularControlRateTest() : juce::UnitTest("GranularControlRate", "Regression") {}

    void runTest() override {
        using namespace audioapp::test;

        beginTest("synthetic pcm renders audible output");
        {
            const auto pcm = makePcm(4096);
            auto leftRight = render(pcm, GranularParams{});
            expect(peakAbsStereo(leftRight.first.data(), leftRight.second.data(),
                                 static_cast<int>(leftRight.first.size())) > 1.0e-4f);
        }

        beginTest("LFO density changes output with S&H");
        {
            constexpr int kFrames = 24000;
            std::vector<float> lfo(static_cast<size_t>(kFrames));
            for (int i = 0; i < kFrames; ++i) {
                lfo[static_cast<size_t>(i)] =
                    std::sin(static_cast<float>(i) * 0.91f * 6.28318530718f / 48000.0f);
            }
            ModulationEdgePlayback edge{};
            edge.deviceIndex = 0;
            edge.lfoId = 0;
            edge.localParamId = packParamId(ParamKind::Granular, 3); // density
            edge.amount = 0.8f;

            GranularParams params;
            params.density = 0.3f;
            const auto pcm = makePcm(8192);
            auto swept = render(pcm, params, &lfo[0], 1, kFrames, &edge, 1);
            expect(fullRms(swept.first) > 1.0e-5f, "S&H LFO density still audible");
        }

        beginTest("vowel helper sets form points");
        {
            float x = 0.0f, y = 0.0f;
            granularVowelFormPoint(0, x, y);
            expectWithinAbsoluteError(x, 0.5f, 1.0e-5f);
            expectWithinAbsoluteError(y, 0.05f, 1.0e-5f);
            granularVowelFormPoint(5, x, y);
            expectWithinAbsoluteError(x, 0.5f, 1.0e-5f);
            expectWithinAbsoluteError(y, 0.95f, 1.0e-5f);
        }
    }

private:
    static std::vector<float> makePcm(int frames) {
        std::vector<float> pcm(static_cast<size_t>(frames), 0.0f);
        for (int i = 0; i < frames; ++i) {
            pcm[static_cast<size_t>(i)] =
                0.4f * std::sin(6.28318530718f * 220.0f * static_cast<float>(i) / 48000.0f);
        }
        return pcm;
    }

    static std::pair<std::vector<float>, std::vector<float>> render(
        const std::vector<float>& pcm,
        GranularParams params,
        const float* lfoValues = nullptr,
        int lfoCount = 0,
        int numFrames = 2048,
        const ModulationEdgePlayback* edges = nullptr,
        int edgeCount = 0) {
        params.pcm = pcm.data();
        params.frameCount = static_cast<int>(pcm.size());
        params.pcmRate = 48000.0;
        MidiPlaybackNote notes[1]{};
        notes[0].pitch = 60;
        notes[0].clipStartBeat = 0.0;
        notes[0].clipLengthBeats = 4.0;
        notes[0].noteStartBeat = 0.0;
        notes[0].noteDurationBeats = 4.0;
        notes[0].velocity = 100.0f;
        notes[0].loopContent = false;
        notes[0].contentLengthBeats = 4.0;

        GranularFormantFilterState state{};
        std::vector<float> left(static_cast<size_t>(numFrames), 0.0f);
        std::vector<float> right(static_cast<size_t>(numFrames), 0.0f);
        const uint16_t deviceIndex = 0;
        mixGranularMidiNotesBlock(left.data(),
                                  right.data(),
                                  numFrames,
                                  48000.0,
                                  120,
                                  0.0,
                                  notes,
                                  1,
                                  params,
                                  state,
                                  nullptr,
                                  0,
                                  nullptr,
                                  lfoValues,
                                  lfoCount,
                                  numFrames,
                                  edges,
                                  edgeCount,
                                  edges != nullptr ? &deviceIndex : nullptr);
        return {left, right};
    }
};

static GranularControlRateTest granularControlRateTest;
