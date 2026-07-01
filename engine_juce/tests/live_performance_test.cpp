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

        beginTest("per-note envelope does not cut overlapping live voice");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Live synth");
            host.selectTrack(trackId);
            const std::string synthId = host.addDeviceToTrack(trackId, "subtractive_synth");
            expect(!synthId.empty(), "synth added");
            expect(host.setDeviceParameter(synthId, "gain", 0.0f), "base gain at zero");
            const int envelopeId = host.createLfo(1);
            host.updateLfoParam(envelopeId, "curveType", 2.0f);
            host.updateLfoParam(envelopeId, "attack", 0.01f);
            host.updateLfoParam(envelopeId, "decay", 0.5f);
            host.updateLfoParam(envelopeId, "release", 0.1f);
            expect(host.assignModulation(envelopeId, synthId, "gain", 1.0f),
                   "envelope assigned to gain");

            host.enterPlayMode();
            expect(host.noteOn(60, 110.0f), "first note starts");
            std::vector<float> warmup(1024, 0.0f);
            host.readLiveMix(warmup.data(), static_cast<int>(warmup.size()), 48000.0);
            expect(host.noteOn(67, 110.0f), "second note starts");
            host.noteOff(60);

            std::vector<float> overlap(2048, 0.0f);
            host.readLiveMix(overlap.data(), static_cast<int>(overlap.size()), 48000.0);
            expect(audioapp::test::hasNonZeroSample(overlap),
                   "second voice remains audible after first note-off");
            host.allNotesOff();
        }
    }
};
static LivePerformanceTest livePerformanceTest;
