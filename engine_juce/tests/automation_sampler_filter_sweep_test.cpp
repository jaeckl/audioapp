#include <juce_core/juce_core.h>
#include "TestHelpers.h"

#include "audioapp/EngineHost.hpp"

#include <cmath>
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

            host.setPlaying(true);
            const std::vector<float> block = host.renderOffline(4.0, 48000.0);
            expect(block.size() >= 48000);

            float peak = 0.0f;
            for (float sample : block) {
                peak = std::max(peak, std::abs(sample));
            }
            expect(peak >= 1.0e-4f);

            const int window = std::min(12000, static_cast<int>(block.size()) / 4);
            const int earlyStart = static_cast<int>(block.size()) / 20;
            const int lateStart = static_cast<int>(block.size() * 3) / 4;
            const float earlyHf = audioapp::test::highFrequencyEnergy(block, earlyStart, window);
            const float lateHf = audioapp::test::highFrequencyEnergy(block, lateStart, window);
            expect(earlyHf > 1.0e-8f && lateHf > 1.0e-8f);
            // Kick sample is mostly low-frequency content, so the filter
            // sweep produces a modest HF ratio difference.
            expect(earlyHf > lateHf * 1.2f, "Early HF should be > 1.2x late HF");
        }
    }
};

static AutomationSamplerFilterSweepTest automationSamplerFilterSweepTest;