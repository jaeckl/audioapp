#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/AutomationTypes.hpp"
#include "audioapp/PhaseModSynthAlgorithm.hpp"

#include <cmath>
#include <vector>

using namespace audioapp;

class PhaseModControlRateTest : public juce::UnitTest {
public:
    PhaseModControlRateTest() : juce::UnitTest("PhaseModControlRate", "Regression") {}

    void runTest() override {
        using namespace audioapp::test;

        beginTest("constant params render audible output");
        {
            const auto block = renderBlock(PhaseModSynthParams{});
            expect(peakAbs(block.data(), static_cast<int>(block.size())) > 1.0e-4f);
        }

        beginTest("LFO filterCutoff sweep");
        {
            constexpr int kFrames = 48000;
            std::vector<float> lfo(static_cast<size_t>(kFrames));
            for (int i = 0; i < kFrames; ++i) {
                lfo[static_cast<size_t>(i)] =
                    std::sin(static_cast<float>(i) * 0.73f * 6.28318530718f / 48000.0f);
            }

            ModulationEdgePlayback edge{};
            edge.deviceIndex = 0;
            edge.lfoId = 0;
            edge.localParamId =
                packParamId(ParamKind::PhaseModSynth,
                            static_cast<uint16_t>(PhaseModSynthParam::FilterCutoff));
            edge.amount = 1.0f;

            PhaseModSynthParams params;
            params.filterCutoff = 0.25f;
            params.filterEnvAmount = 0.0f;
            params.operators[0].level = 1.0f;
            params.operators[0].ratio = 1.0f;

            const auto block = renderBlock(params, &lfo[0], 1, kFrames, &edge, 1);
            expect(filterSweepDetected(block, 8, 1.5f), "LFO filterCutoff sweep with S&H");
        }

        beginTest("unison detune changes output");
        {
            PhaseModSynthParams single;
            single.unisonVoices = 0.0f;
            single.operators[0].level = 1.0f;
            PhaseModSynthParams multi;
            multi.unisonVoices = 1.0f;
            multi.unisonDetune = 0.7f;
            multi.operators[0].level = 1.0f;
            const auto one = renderBlock(single);
            const auto many = renderBlock(multi);
            expect(fullRms(many) > 0.0f);
            expect(std::abs(fullRms(one) - fullRms(many)) > 1.0e-6f);
        }

        beginTest("feedback changes output");
        {
            PhaseModSynthParams dry;
            dry.feedback = 0.0f;
            dry.operators[0].level = 1.0f;
            dry.operators[0].attack = 0.0f;
            PhaseModSynthParams fb;
            fb.feedback = 0.6f;
            fb.operators[0].level = 1.0f;
            fb.operators[0].attack = 0.0f;
            expect(std::abs(fullRms(renderBlock(dry)) - fullRms(renderBlock(fb))) > 1.0e-6f ||
                   peakAbs(renderBlock(fb).data(), 2048) > 0.0f);
        }
    }

private:
    static std::vector<float> renderBlock(const PhaseModSynthParams& params,
                                          const float* lfoValues = nullptr,
                                          int lfoCount = 0,
                                          int numFrames = 2048,
                                          const ModulationEdgePlayback* edges = nullptr,
                                          int edgeCount = 0) {
        PhaseModSynthParams local = params;
        if (local.operators[0].level <= 0.0f) {
            local.operators[0].level = 1.0f;
            local.operators[0].ratio = 1.0f;
        }
        PhaseModSynthMidiNoteRegion notes[] = {
            {60, 0, 0.0, 4.0, 0.0, 4.0, 100.0f, false, 4.0},
        };
        PhaseModSynthRuntime runtime{};
        std::vector<float> out(static_cast<size_t>(numFrames), 0.0f);
        const uint16_t deviceIndex = 0;
        mixPhaseModMidiNotesBlock(
            out.data(),
            numFrames,
            48000.0,
            120,
            0.0,
            notes,
            1,
            local,
            runtime,
            nullptr,
            0,
            nullptr,
            lfoValues,
            lfoCount,
            numFrames,
            edges,
            edgeCount,
            edges != nullptr ? &deviceIndex : nullptr);
        return out;
    }
};

static PhaseModControlRateTest phaseModControlRateTest;
