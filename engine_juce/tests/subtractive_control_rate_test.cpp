/// Subtractive synth control-rate (S&H) regression: global automation/LFO targets and
/// filter-coeff / osc-Hz holds are refreshed every kSubtractiveControlSubBlockFrames
/// while amp envelopes and oscillator phase stay per-sample.

#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/EngineHost.hpp"
#include "audioapp/SubtractiveSynthAlgorithm.hpp"

#include <cmath>
#include <vector>

class SubtractiveControlRateTest : public juce::UnitTest {
public:
    SubtractiveControlRateTest() : juce::UnitTest("SubtractiveControlRate", "Regression") {}

    void runTest() override {
        using namespace audioapp::test;

        beginTest("constant params render audible output");
        {
            constexpr int kFrames = 1024;
            constexpr double kSampleRate = 48000.0;
            audioapp::SubtractiveMidiNoteRegion notes[] = {
                {60, 0, 0.0, 4.0, 0.0, 4.0, 100.0f, false, 4.0},
            };
            audioapp::SubtractiveSynthParams params;
            params.gain = 1.0f;
            params.filterCutoff = 0.6f;
            audioapp::SubtractiveSynthRuntime runtime{};
            std::vector<float> out(static_cast<size_t>(kFrames), 0.0f);
            audioapp::mixSubtractiveMidiNotesBlock(
                out.data(), kFrames, kSampleRate, 120, 0.0, notes, 1, params, runtime);
            expect(peakAbs(out.data(), kFrames) > 1.0e-4f, "audible dry render");
        }

        beginTest("LFO filterCutoff sweep non-integral rate");
        {
            expect(renderLfoFilterSweep(0.73f), "non-integral LFO still sweeps cutoff");
        }

        beginTest("automation filterCutoff sweep");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("AutoSweep");
            host.selectTrack(trackId);
            const std::string synthId = host.addDeviceToTrack(trackId, "subtractive_synth");
            expect(host.setDeviceParameter(synthId, "filterCutoff", 0.2f));
            expect(host.setDeviceParameter(synthId, "filterEnvAmount", 0.0f));

            const std::string midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
            expect(!midiClipId.empty());
            expect(host.setMidiClipNotes(midiClipId, {{60, 0.0, 4.0, 100.0f}}));

            const std::string autoClipId = host.createAutomationClip(trackId, 0.0, 4.0);
            expect(host.assignAutomationTarget(autoClipId, synthId, "filterCutoff"));
            expect(host.setAutomationPoints(autoClipId, {{0.0, 0.15f}, {4.0, 0.85f}}));

            host.setPlaying(true);
            const std::vector<float> block = host.renderOffline(4.0, 48000.0);
            expect(block.size() >= 48000);
            expect(filterSweepDetected(block, 8, 1.8f), "held automation still sweeps cutoff");
        }
    }

private:
    static bool renderLfoFilterSweep(float lfoRateNorm) {
        using namespace audioapp::test;

        audioapp::EngineHost host;
        host.createProject();
        const std::string trackId = host.addTrack("ControlRate");
        host.selectTrack(trackId);
        const std::string synthId = host.addDeviceToTrack(trackId, "subtractive_synth");
        if (!host.setDeviceParameter(synthId, "filterCutoff", 0.25f)) return false;
        if (!host.setDeviceParameter(synthId, "filterEnvAmount", 0.0f)) return false;

        const std::string midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
        if (midiClipId.empty()) return false;
        std::vector<audioapp::MidiNoteState> notes{{60, 0.0, 4.0, 100.0f}};
        if (!host.setMidiClipNotes(midiClipId, notes)) return false;

        const int lfoId = host.createLfo(0);
        if (lfoId <= 0) return false;
        if (!host.updateLfoParam(lfoId, "waveform", 0.0f)) return false;
        if (!host.updateLfoParam(lfoId, "rate", lfoRateNorm)) return false;
        if (!host.updateLfoParam(lfoId, "syncDivision", 0.0f)) return false;
        if (!host.assignModulation(lfoId, synthId, "filterCutoff", 1.0f)) return false;

        host.setPlaying(true);
        const std::vector<float> block = host.renderOffline(4.0, 48000.0);
        if (block.size() < 48000) return false;
        if (rms(block, 1000, 4000) < 1.0e-4f) return false;
        return filterSweepDetected(block, 8, 1.8f);
    }
};

static SubtractiveControlRateTest subtractiveControlRateTest;
