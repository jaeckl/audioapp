/// Golden-file test for filter cutoff automation on a sampler with a kick sample.
///
/// To regenerate goldens: build with -DAUDIOAPP_REGENERATE_GOLDEN=ON and run.

#include <juce_core/juce_core.h>
#include "TestHelpers.h"

#include "audioapp/EngineHost.hpp"

#include <vector>

class AutomationSamplerFilterSweepTest : public juce::UnitTest {
public:
    AutomationSamplerFilterSweepTest()
        : juce::UnitTest("Automation Sampler Filter Sweep", "Automation") {}

    void runTest() override {
        beginTest("Sampler filter cutoff automation sweep");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Sampler");
            host.selectTrack(trackId);
            const std::string samplerId = host.addDeviceToTrack(trackId, "simple_sampler");
            expect(!samplerId.empty());
            expect(host.setDeviceStringParameter(samplerId, "sampleId", "sample_kick"));
            expect(host.setDeviceParameter(samplerId, "filterEnvAmount", 0.0f));
            expect(host.setDeviceParameter(samplerId, "filterQ", 0.0f));
            expect(host.setDeviceParameter(samplerId, "playbackMode", 1.0f)); // Loop

            const std::string midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
            expect(!midiClipId.empty());
            std::vector<audioapp::MidiNoteState> notes;
            notes.push_back({60, 0.0, 4.0, 100.0f});
            expect(host.setMidiClipNotes(midiClipId, notes));

            const std::string clipId = host.createAutomationClip(trackId, 0.0, 4.0);
            expect(!clipId.empty());
            expect(host.assignAutomationTarget(clipId, samplerId, "filterCutoff"));

            std::vector<audioapp::AutomationPointState> points;
            points.push_back({0.0, 1.0f});
            points.push_back({4.0, 0.25f});
            expect(host.setAutomationPoints(clipId, points));

            expect(audioapp::test::checkRenderGolden(
                "automation_sampler_filter_sweep.bin", host, 4.0, 48000.0));
        }
    }
};

static AutomationSamplerFilterSweepTest automationSamplerFilterSweepTest;