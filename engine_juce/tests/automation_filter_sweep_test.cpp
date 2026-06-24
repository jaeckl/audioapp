/// Golden-file test for filter cutoff automation on a subtractive synth.
///
/// Renders 4 beats of a synth note with an automation sweep from cutoff=1.0
/// to cutoff=0.25 and compares the output to a golden reference.
///
/// To regenerate goldens: build with -DAUDIOAPP_REGENERATE_GOLDEN=ON and run.

#include <juce_core/juce_core.h>
#include "TestHelpers.h"

#include "audioapp/EngineHost.hpp"

#include <vector>

class AutomationFilterSweepTest : public juce::UnitTest {
public:
    AutomationFilterSweepTest()
        : juce::UnitTest("Automation Filter Sweep", "Automation") {}

    void runTest() override {
        beginTest("Filter cutoff automation sweep");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Filter");
            host.selectTrack(trackId);
            const std::string synthId = host.addDeviceToTrack(trackId, "subtractive_synth");
            expect(host.setDeviceParameter(synthId, "filterQ", 0.0f));

            const std::string midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
            expect(!midiClipId.empty());
            std::vector<audioapp::MidiNoteState> notes;
            notes.push_back({60, 0.0, 4.0, 100.0f});
            expect(host.setMidiClipNotes(midiClipId, notes));

            const std::string clipId = host.createAutomationClip(trackId, 0.0, 4.0);
            expect(!clipId.empty());
            expect(host.assignAutomationTarget(clipId, synthId, "filterCutoff"));

            std::vector<audioapp::AutomationPointState> points;
            points.push_back({0.0, 1.0f});
            points.push_back({4.0, 0.25f});
            expect(host.setAutomationPoints(clipId, points));

            expect(audioapp::test::checkRenderGolden(
                "automation_filter_sweep.bin", host, 4.0, 48000.0));
        }
    }
};

static AutomationFilterSweepTest automationFilterSweepTest;