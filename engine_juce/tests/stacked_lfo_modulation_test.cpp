/// Golden-file test suite for stacked LFO modulation.
///
/// Each test renders 4 beats with a specific LFO configuration and compares
/// the output to a golden reference.
///
/// To regenerate goldens: build with -DAUDIOAPP_REGENERATE_GOLDEN=ON and run.

#include <juce_core/juce_core.h>
#include "TestHelpers.h"

#include "audioapp/EngineHost.hpp"

#include <vector>

namespace {

struct FreshHost {
    audioapp::EngineHost host;
    std::string trackId;
    std::string synthId;
    std::string midiClipId;

    FreshHost() {
        host.createProject();
        trackId = host.addTrack("Test");
        host.selectTrack(trackId);
        synthId = host.addDeviceToTrack(trackId, "subtractive_synth");

        midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
        std::vector<audioapp::MidiNoteState> notes;
        notes.push_back({60, 0.0, 4.0, 100.0f});
        host.setMidiClipNotes(midiClipId, notes);
    }

    int createLfo(int waveform, float rate, int syncDivision = 0) {
        const int lfoId = host.createLfo(0);
        host.updateLfoParam(lfoId, "waveform", static_cast<float>(waveform));
        host.updateLfoParam(lfoId, "rate", rate);
        host.updateLfoParam(lfoId, "syncDivision", static_cast<float>(syncDivision));
        return lfoId;
    }
};

} // namespace

class StackedLfoModulationTest : public juce::UnitTest {
public:
    StackedLfoModulationTest()
        : juce::UnitTest("Stacked LFO Modulation", "Modulation") {}

    void runTest() override {
        beginTest("Two LFOs on different params produce stacked modulation");
        {
            FreshHost setup;
            const int lfo1 = setup.createLfo(0, 3.0f, 0);
            expect(setup.host.assignModulation(lfo1, setup.synthId, "filterCutoff", 0.8f));
            const int lfo2 = setup.createLfo(3, 7.0f, 0);
            expect(setup.host.assignModulation(lfo2, setup.synthId, "filterQ", 0.5f));

            expect(audioapp::test::checkRenderGolden(
                "stacked_lfo_diff_params.bin", setup.host, 4.0, 48000.0, 2.0e-4f));
        }

        beginTest("Two LFOs on the same param — stacked configuration");
        {
            FreshHost stacked;
            const int lfo1S = stacked.createLfo(0, 2.0f, 0);
            expect(stacked.host.assignModulation(lfo1S, stacked.synthId, "filterCutoff", 0.5f));
            const int lfo2S = stacked.createLfo(0, 5.0f, 0);
            expect(stacked.host.assignModulation(lfo2S, stacked.synthId, "filterCutoff", 0.3f));

            expect(audioapp::test::checkRenderGolden(
                "stacked_lfo_same_param.bin", stacked.host, 4.0, 48000.0, 2.0e-4f));

            // Single-LFO configuration
            FreshHost single;
            const int lfo1N = single.createLfo(0, 2.0f, 0);
            expect(single.host.assignModulation(lfo1N, single.synthId, "filterCutoff", 0.5f));

            expect(audioapp::test::checkRenderGolden(
                "stacked_lfo_single.bin", single.host, 4.0, 48000.0, 2.0e-4f));
        }

        beginTest("Remove one LFO — remaining LFO still audible");
        {
            FreshHost both;
            const int lfo1B = both.createLfo(0, 3.0f, 0);
            expect(both.host.assignModulation(lfo1B, both.synthId, "filterCutoff", 0.8f));
            const int lfo2B = both.createLfo(3, 7.0f, 0);
            expect(both.host.assignModulation(lfo2B, both.synthId, "filterQ", 0.5f));

            expect(audioapp::test::checkRenderGolden(
                "stacked_lfo_both.bin", both.host, 4.0, 48000.0, 2.0e-4f));

            FreshHost one;
            const int lfo1O = one.createLfo(0, 3.0f, 0);
            expect(one.host.assignModulation(lfo1O, one.synthId, "filterCutoff", 0.8f));

            expect(audioapp::test::checkRenderGolden(
                "stacked_lfo_one.bin", one.host, 4.0, 48000.0, 2.0e-4f));
        }
    }
};

static StackedLfoModulationTest stackedLfoModulationTest;