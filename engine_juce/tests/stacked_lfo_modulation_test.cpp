/// Test suite for stacked LFO modulation.
///
/// Tests cover:
///   1. Two LFOs on different params (filterCutoff + filterQ) produce complex
///      spectral variation beyond the single-LFO case.
///   2. Two LFOs on the SAME param (both filterCutoff) — verify additive
///      amounts produce stronger modulation than a single LFO alone.
///   3. Removing one LFO from a stacked modulation setup reduces spectral
///      variation.
///
/// All tests use EngineHost::renderOffline to exercise the complete
/// control-thread -> audio-thread path.

#include <juce_core/juce_core.h>
#include "TestHelpers.h"

#include "audioapp/EngineHost.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>
#include <vector>

namespace {

struct TestSetup {
    audioapp::EngineHost host;
    std::string trackId;
    std::string synthId;
    std::string midiClipId;

    TestSetup() {
        host.createProject();
        trackId = host.addTrack("Test");
        host.selectTrack(trackId);
        synthId = host.addDeviceToTrack(trackId, "subtractive_synth");

        midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
        std::vector<audioapp::MidiNoteState> notes;
        notes.push_back({60, 0.0, 4.0, 100.0f});
        host.setMidiClipNotes(midiClipId, notes);
    }

    int createLfo(int waveform = 0, float rate = 4.0f, int syncDivision = 0) {
        const int lfoId = host.createLfo(0); // 0 = LFO
        host.updateLfoParam(lfoId, "waveform", static_cast<float>(waveform));
        host.updateLfoParam(lfoId, "rate", rate);
        host.updateLfoParam(lfoId, "syncDivision", static_cast<float>(syncDivision)); // 0 = free Hz
        return lfoId;
    }

    std::vector<float> render() {
        host.setPlaying(true);
        return host.renderOffline(4.0, 48000.0);
    }
};

/// Compute max/min HF energy ratio across N windows.
float hfEnergyVariation(const std::vector<float>& samples, int numWindows) {
    const int windowFrames = static_cast<int>(samples.size()) / numWindows;
    float brightest = 0.0f;
    float darkest = std::numeric_limits<float>::infinity();
    for (int w = 0; w < numWindows; ++w) {
        const int start = w * windowFrames;
        const float hf = audioapp::test::highFrequencyEnergy(samples, start, windowFrames);
        if (hf <= 0.0f) return 1.0f;
        brightest = std::max(brightest, hf);
        darkest = std::min(darkest, hf);
    }
    if (darkest <= 0.0f) return 1.0f;
    return brightest / darkest;
}

} // namespace

class StackedLfoModulationTest : public juce::UnitTest {
public:
    StackedLfoModulationTest()
        : juce::UnitTest("Stacked LFO Modulation", "Modulation") {}

    void runTest() override {
        beginTest("Two LFOs on different params produce audible stacked modulation");
        {
            TestSetup setup;

            const int lfo1 = setup.createLfo(0, 3.0f, 0); // sine @ 3 Hz
            expect(setup.host.assignModulation(lfo1, setup.synthId, "filterCutoff", 0.8f));

            const int lfo2 = setup.createLfo(3, 7.0f, 0); // square @ 7 Hz
            expect(setup.host.assignModulation(lfo2, setup.synthId, "filterQ", 0.5f));

            const std::vector<float> block = setup.render();
            expect(block.size() >= 48000);
            expect(audioapp::test::rms(block, 1000, 4000) >= 1.0e-4f);

            constexpr int kWindows = 8;
            const float variation = hfEnergyVariation(block, kWindows);
            expect(variation >= 2.0f, "Stacked LFOs should produce strong spectral variation");
        }

        beginTest("Two LFOs on the same param — verify additive amounts");
        {
            TestSetup setup;

            // LFO-1 (sine, 2 Hz) at 0.5 amount on filterCutoff
            const int lfo1 = setup.createLfo(0, 2.0f, 0);
            expect(setup.host.assignModulation(lfo1, setup.synthId, "filterCutoff", 0.5f));

            // LFO-2 (sine, 5 Hz) at 0.3 amount on same filterCutoff
            const int lfo2 = setup.createLfo(0, 5.0f, 0);
            expect(setup.host.assignModulation(lfo2, setup.synthId, "filterCutoff", 0.3f));

            const std::vector<float> stackedBlock = setup.render();
            expect(stackedBlock.size() >= 48000);
            expect(audioapp::test::rms(stackedBlock, 1000, 4000) >= 1.0e-4f);

            constexpr int kWindows = 8;
            const float stackedVariation = hfEnergyVariation(stackedBlock, kWindows);
            expect(stackedVariation >= 2.0f, "Stacked LFOs on same param should produce variation");

            // Remove LFO-2's modulation on filterCutoff, keeping only LFO-1.
            expect(setup.host.removeModulation(lfo2, "filterCutoff"));

            const std::vector<float> singleBlock = setup.render();
            expect(audioapp::test::rms(singleBlock, 1000, 4000) >= 1.0e-4f);

            const float singleVariation = hfEnergyVariation(singleBlock, kWindows);

            // The stacked (two-LFO) variation must exceed the single-LFO variation.
            expect(singleVariation < stackedVariation,
                   "Stacked LFO variation should exceed single LFO variation");
        }

        beginTest("Remove one LFO — verify spectral variation decreases");
        {
            TestSetup setup;

            const int lfo1 = setup.createLfo(0, 3.0f, 0); // sine @ 3 Hz
            expect(setup.host.assignModulation(lfo1, setup.synthId, "filterCutoff", 0.8f));

            const int lfo2 = setup.createLfo(3, 7.0f, 0); // square @ 7 Hz
            expect(setup.host.assignModulation(lfo2, setup.synthId, "filterQ", 0.5f));

            const std::vector<float> bothBlock = setup.render();
            expect(bothBlock.size() >= 48000);
            expect(audioapp::test::rms(bothBlock, 1000, 4000) >= 1.0e-4f);

            constexpr int kWindows = 8;
            const float bothVariation = hfEnergyVariation(bothBlock, kWindows);
            expect(bothVariation >= 2.0f, "Both LFOs should produce strong variation");

            // Remove LFO-2's filterQ modulation, keeping LFO-1 on filterCutoff.
            expect(setup.host.removeModulation(lfo2, "filterQ"));

            const std::vector<float> oneBlock = setup.render();
            expect(audioapp::test::rms(oneBlock, 1000, 4000) >= 1.0e-4f);

            const float oneVariation = hfEnergyVariation(oneBlock, kWindows);

            // Removing one LFO should reduce spectral variation.
            expect(oneVariation < bothVariation,
                   "Removing one LFO should reduce spectral variation");
        }
    }
};

static StackedLfoModulationTest stackedLfoModulationTest;