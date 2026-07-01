#include <juce_core/juce_core.h>
#include "TestHelpers.h"

#include "audioapp/EngineHost.hpp"
#include "audioapp/ProjectJson.hpp"

#include <cmath>

class AutomationClipTest : public juce::UnitTest {
public:
    AutomationClipTest()
        : juce::UnitTest("Automation Clip", "Automation") {}

    void runTest() override {
        using namespace audioapp;

        beginTest("Automation clip CRUD and serialization");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Test");
            host.selectTrack(trackId);
            const std::string synthId = host.addDeviceToTrack(trackId, "subtractive_synth");

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
            points.push_back({2.0, 0.2f});
            points.push_back({4.0, 0.9f});
            expect(host.setAutomationPoints(clipId, points));

            const auto parsed = audioapp::test::readProjectData(host);
            expectEquals(static_cast<int>(parsed.automationClips.size()), 1);
            const auto& clip = parsed.automationClips[0];
            expect(clip.deviceId == synthId);
            expect(clip.paramId == "filterCutoff");
            expectEquals(static_cast<int>(clip.points.size()), 3);
            expect(clip.homeTrackId == trackId);

            expect(host.unlinkAutomationTarget(clipId));
            const auto unlinked = audioapp::test::readProjectData(host);
            expectEquals(static_cast<int>(unlinked.automationClips.size()), 1);
            expect(unlinked.automationClips[0].deviceId.empty());
            expect(unlinked.automationClips[0].paramId.empty());
            expectEquals(static_cast<int>(unlinked.automationClips[0].points.size()), 3);

            const std::string json = host.getProjectFileJson();
            audioapp::EngineHost loaded;
            loaded.createProject();
            expect(loaded.loadProjectFileJson(json));
            const auto reloaded = audioapp::test::readProjectData(loaded);
            expect(!reloaded.automationClips.empty());
            expect(reloaded.automationClips[0].homeTrackId == trackId);

            host.setPlaying(true);
            const std::vector<float> block = host.renderOffline(4.0, 48000.0);
            expect(!block.empty());

            float peak = 0.0f;
            for (float sample : block) {
                peak = std::max(peak, std::abs(sample));
            }
            expect(peak >= 1.0e-4f, "Audio should have non-zero output");
        }
    }
};

static AutomationClipTest automationClipTest;
