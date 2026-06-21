#include <juce_core/juce_core.h>
#include "TestHelpers.h"

#include "audioapp/EngineHost.hpp"

#include <cmath>
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

            const std::string midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
            expect(!midiClipId.empty());
            std::vector<audioapp::MidiNoteState> notes;
            notes.push_back({60, 0.0, 4.0, 100.0f});
            expect(host.setMidiClipNotes(midiClipId, notes));

            const std::string clipId = host.createAutomationClip(trackId, 0.0, 4.0);
            expect(!clipId.empty());
            expect(host.assignAutomationTarget(clipId, synthId, "filterCutoff"));

            // Open filter at start, nearly closed at end — audible brightness drop.
            std::vector<audioapp::AutomationPointState> points;
            points.push_back({0.0, 1.0f});
            points.push_back({4.0, 0.05f});
            expect(host.setAutomationPoints(clipId, points));

            host.setPlaying(true);
            const std::vector<float> block = host.renderOffline(4.0, 48000.0);
            expect(block.size() >= 48000);

            const int window = 12000;
            const int earlyStart = static_cast<int>(block.size()) / 20;
            const int lateStart = static_cast<int>(block.size() * 3) / 4;
            const float earlyHf = audioapp::test::highFrequencyEnergy(block, earlyStart, window);
            const float lateHf = audioapp::test::highFrequencyEnergy(block, lateStart, window);
            expect(earlyHf > 1.0e-8f && lateHf > 1.0e-8f);
            expect(earlyHf > lateHf * 1.5f, "Early HF should be > 1.5x late HF");
        }
    }
};

static AutomationFilterSweepTest automationFilterSweepTest;