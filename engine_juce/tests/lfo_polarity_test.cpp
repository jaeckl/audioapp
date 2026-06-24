/// LFO polarity E2E test suite — golden-file approach.
///
/// Tests 1-3 use golden file comparisons for render output. Test 4 verifies
/// polarity persists in JSON round-trip (deterministic, no golden needed).
///
/// To regenerate goldens: build with -DAUDIOAPP_REGENERATE_GOLDEN=ON and run.

#include <juce_core/juce_core.h>
#include "TestHelpers.h"

#include "audioapp/EngineHost.hpp"
#include "audioapp/ProjectJson.hpp"

#include <vector>

namespace {

struct PolarityTestSetup {
    audioapp::EngineHost host;
    std::string trackId;
    std::string synthId;
    std::string midiClipId;

    PolarityTestSetup() {
        host.createProject();
        trackId = host.addTrack("Test");
        host.selectTrack(trackId);
        synthId = host.addDeviceToTrack(trackId, "subtractive_synth");

        midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
        std::vector<audioapp::MidiNoteState> notes;
        notes.push_back({60, 0.0, 4.0, 100.0f});
        host.setMidiClipNotes(midiClipId, notes);
    }

    int createLfoWithPolarity(int polarity, float rate = 4.0f) {
        const int lfoId = host.createLfo(0);
        host.updateLfoParam(lfoId, "waveform", 0.0f);
        host.updateLfoParam(lfoId, "rate", rate);
        host.updateLfoParam(lfoId, "syncDivision", 0.0f);
        host.updateLfoParam(lfoId, "polarity", static_cast<float>(polarity));
        return lfoId;
    }
};

} // namespace

class LfoPolarityTest : public juce::UnitTest {
public:
    LfoPolarityTest()
        : juce::UnitTest("LFO Polarity", "Modulation") {}

    void runTest() override {
        beginTest("Bipolar LFO on filterCutoff — full sweep");
        {
            PolarityTestSetup setup;
            const int lfoId = setup.createLfoWithPolarity(0, 4.0f);
            expect(setup.host.assignModulation(lfoId, setup.synthId, "filterCutoff", 0.8f));

            expect(audioapp::test::checkRenderGolden(
                "lfo_polarity_bipolar.bin", setup.host, 4.0, 48000.0, 2.0e-4f));
        }

        beginTest("Positive-only LFO produces different output from bipolar");
        {
            // Bipolar render
            PolarityTestSetup setup;
            const int lfoId = setup.createLfoWithPolarity(0, 4.0f);
            expect(setup.host.assignModulation(lfoId, setup.synthId, "filterCutoff", 0.8f));

            expect(audioapp::test::checkRenderGolden(
                "lfo_polarity_bipolar_solo.bin", setup.host, 4.0, 48000.0, 2.0e-4f));

            // Positive-only render (reassign LFO params)
            expect(setup.host.updateLfoParam(lfoId, "polarity", 1.0f));

            expect(audioapp::test::checkRenderGolden(
                "lfo_polarity_positive.bin", setup.host, 4.0, 48000.0, 2.0e-4f));
        }

        beginTest("Negative-only LFO produces different output from positive");
        {
            PolarityTestSetup setup;
            const int lfoId = setup.createLfoWithPolarity(1, 4.0f);
            expect(setup.host.assignModulation(lfoId, setup.synthId, "filterCutoff", 0.8f));

            expect(audioapp::test::checkRenderGolden(
                "lfo_polarity_positive_solo.bin", setup.host, 4.0, 48000.0, 2.0e-4f));

            expect(setup.host.updateLfoParam(lfoId, "polarity", 2.0f));

            expect(audioapp::test::checkRenderGolden(
                "lfo_polarity_negative.bin", setup.host, 4.0, 48000.0, 2.0e-4f));
        }

        beginTest("Polarity persists in JSON round-trip");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Test");
            host.selectTrack(trackId);
            host.addDeviceToTrack(trackId, "subtractive_synth");

            const int lfoId = host.createLfo(0);
            host.updateLfoParam(lfoId, "polarity", 0.0f); // bipolar

            // Round-trip 1: verify polarity=0
            {
                const std::string json = host.getProjectFileJson();
                audioapp::ProjectFileData parsed;
                expect(audioapp::test::parseProjectJsonInto(json, parsed));
                bool found = false;
                for (const auto& lfo : parsed.lfos) {
                    if (lfo.id == lfoId) {
                        expectEquals(lfo.polarity, 0);
                        found = true;
                        break;
                    }
                }
                expect(found, "LFO found in round-trip 1");
            }

            // Change to positive-only
            expect(host.updateLfoParam(lfoId, "polarity", 1.0f));

            // Round-trip 2: verify polarity=1
            {
                const std::string json = host.getProjectFileJson();
                audioapp::ProjectFileData parsed;
                expect(audioapp::test::parseProjectJsonInto(json, parsed));
                bool found = false;
                for (const auto& lfo : parsed.lfos) {
                    if (lfo.id == lfoId) {
                        expectEquals(lfo.polarity, 1);
                        found = true;
                        break;
                    }
                }
                expect(found, "LFO found in round-trip 2");
            }

            // Change to negative-only
            expect(host.updateLfoParam(lfoId, "polarity", 2.0f));

            // Round-trip 3: verify polarity=2
            {
                const std::string json = host.getProjectFileJson();
                audioapp::ProjectFileData parsed;
                expect(audioapp::test::parseProjectJsonInto(json, parsed));
                bool found = false;
                for (const auto& lfo : parsed.lfos) {
                    if (lfo.id == lfoId) {
                        expectEquals(lfo.polarity, 2);
                        found = true;
                        break;
                    }
                }
                expect(found, "LFO found in round-trip 3");
            }
        }
    }
};

static LfoPolarityTest lfoPolarityTest;