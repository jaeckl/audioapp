#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/AutomationTypes.hpp"
#include "audioapp/WavetableSynthAlgorithm.hpp"

#include <cmath>
#include <vector>

using namespace audioapp;

class WavetableControlRateTest : public juce::UnitTest {
public:
    WavetableControlRateTest() : juce::UnitTest("WavetableControlRate", "Regression") {}

    void runTest() override {
        using namespace audioapp::test;

        beginTest("synthetic wavetable renders audible output");
        {
            const auto table = makeSineWavetable(4, 256);
            const auto block = renderBlock(table, WavetableSynthParamsPlayback{});
            expect(block.size() > 0);
            expect(peakAbs(block.data(), static_cast<int>(block.size())) > 1.0e-4f);
        }

        beginTest("wtOctave changes output");
        {
            const auto table = makeSineWavetable(4, 256);
            WavetableSynthParamsPlayback lowOct;
            lowOct.wtOctave = 0.5f;
            WavetableSynthParamsPlayback highOct;
            highOct.wtOctave = 0.75f;
            const auto low = renderBlock(table, lowOct);
            const auto high = renderBlock(table, highOct);
            expect(std::abs(fullRms(low) - fullRms(high)) > 1.0e-5f ||
                   highFrequencyEnergy(high, 0, static_cast<int>(high.size())) !=
                       highFrequencyEnergy(low, 0, static_cast<int>(low.size())),
                   "wtOctave affects spectrum or level");
        }

        beginTest("LFO filterCutoff sweep");
        {
            const auto table = makeSineWavetable(4, 256);
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
                packParamId(ParamKind::WavetableSynth,
                            static_cast<uint16_t>(WavetableParam::FilterCutoff));
            edge.amount = 1.0f;

            WavetableSynthParamsPlayback params;
            params.filterCutoff = 0.25f;
            params.filterEnvAmount = 0.0f;

            const std::vector<float> block =
                renderBlock(table, params, &lfo[0], 1, kFrames, &edge, 1);
            expect(filterSweepDetected(block, 8, 1.5f), "LFO filterCutoff sweep");
        }

        beginTest("unison increases voice density");
        {
            const auto table = makeSineWavetable(4, 256);
            WavetableSynthParamsPlayback single;
            single.wtUnison = 0.0f;
            WavetableSynthParamsPlayback multi;
            multi.wtUnison = 1.0f;
            multi.wtDetune = 0.5f;
            const auto oneVoice = renderBlock(table, single);
            const auto manyVoice = renderBlock(table, multi);
            expect(fullRms(manyVoice) > 0.0f);
            expect(std::abs(fullRms(oneVoice) - fullRms(manyVoice)) > 1.0e-6f,
                   "unison detune changes output");
        }

        beginTest("sub oscillator audible with silent wavetable gain path");
        {
            const auto table = makeSineWavetable(4, 256);
            WavetableSynthParamsPlayback silentWt;
            silentWt.wtSubLevel = 0.0f;
            silentWt.wtNoiseLevel = 0.0f;
            silentWt.filterCutoff = 1.0f;
            WavetableSynthParamsPlayback withSub = silentWt;
            withSub.wtSubLevel = 1.0f;
            withSub.wtSubOctave = 1;
            // Zero the table so only sub contributes.
            std::vector<float> zeroTable(table.size(), 0.0f);
            const auto bare = renderBlock(zeroTable, silentWt);
            const auto subbed = renderBlock(zeroTable, withSub);
            expect(fullRms(bare) < 1.0e-4f, "silent table stays quiet");
            expect(fullRms(subbed) > 1.0e-3f, "sub level produces energy");
        }

        beginTest("noise generator audible with silent wavetable");
        {
            std::vector<float> zeroTable(4 * 256, 0.0f);
            WavetableSynthParamsPlayback silent;
            silent.wtNoiseLevel = 0.0f;
            WavetableSynthParamsPlayback noisy = silent;
            noisy.wtNoiseLevel = 1.0f;
            noisy.wtNoiseColor = 0.8f;
            const auto bare = renderBlock(zeroTable, silent);
            const auto hiss = renderBlock(zeroTable, noisy);
            expect(fullRms(bare) < 1.0e-4f);
            expect(fullRms(hiss) > 1.0e-3f, "noise level produces energy");
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
                    std::sin(phase) * (0.5f + 0.5f * static_cast<float>(frame) /
                                                  static_cast<float>(frameCount - 1));
            }
        }
        return pcm;
    }

    static std::vector<float> renderBlock(const std::vector<float>& table,
                                          const WavetableSynthParamsPlayback& params,
                                          const float* lfoValues = nullptr,
                                          int lfoCount = 0,
                                          int numFrames = 2048,
                                          const ModulationEdgePlayback* edges = nullptr,
                                          int edgeCount = 0) {
        WavetableMidiNoteRegion notes[] = {
            {60, 0, 0.0, 4.0, 0.0, 4.0, 100.0f, false, 4.0},
        };
        WavetableSynthRuntime runtime{};
        std::vector<float> out(static_cast<size_t>(numFrames), 0.0f);
        const uint16_t deviceIndex = 0;
        mixWavetableMidiNotesBlock(
            out.data(),
            numFrames,
            48000.0,
            120,
            0.0,
            notes,
            1,
            params,
            runtime,
            table.data(),
            4,
            256,
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

static WavetableControlRateTest wavetableControlRateTest;
