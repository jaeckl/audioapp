#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/EngineHost.hpp"
#include "audioapp/SampleBank.hpp"

class LivePerformanceTest : public juce::UnitTest {
public:
    LivePerformanceTest() : juce::UnitTest("LivePerformance", "Engine") {}
    void runTest() override {
        beginTest("note on produces audio");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Live");
            host.selectTrack(trackId);
            // addTrack auto-creates a track_gain device at dev-1; add a sampler
            // and use the returned id so setDeviceStringParameter hits the right slot.
            const std::string samplerId = host.addDeviceToTrack(trackId, "simple_sampler");
            expect(!samplerId.empty(), "sampler added");
            expect(host.setDeviceStringParameter(samplerId, "sampleId", "sample_kick"),
                   "set sampleId");
            host.setRecordArmed(false);

            host.enterPlayMode();
            const bool noteStarted = host.noteOn(60, 110.0f);
            expect(noteStarted, "noteOn should start");

            std::vector<float> buffer(2048, 0.0f);
            host.readLiveMix(buffer.data(), static_cast<int>(buffer.size()), 48000.0);
            expect(audioapp::test::hasNonZeroSample(buffer),
                   "live mix should contain audio");

            host.noteOff(60);
            host.allNotesOff();
        }
    }
};
static LivePerformanceTest livePerformanceTest;