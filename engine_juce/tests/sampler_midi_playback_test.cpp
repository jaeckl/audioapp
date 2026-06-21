#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/EngineHost.hpp"
#include "audioapp/SamplePlayback.hpp"

class SamplerMidiPlaybackTest : public juce::UnitTest {
public:
    SamplerMidiPlaybackTest() : juce::UnitTest("SamplerMidiPlayback", "Engine") {}
    void runTest() override {
        beginTest("sampler ADSR gain at zero time");
        {
            using namespace audioapp;
            expect(samplerAdsrGain(0.0f, 1.0f, 0.5f, 0.5f, 1.0f, 0.5f) <= 0.01f,
                   "ADSR gain at time 0 near zero");
        }
        beginTest("sampler ADSR gain mid-attack");
        {
            using namespace audioapp;
            expectWithinAbsoluteError(samplerAdsrGain(0.25f, 1.0f, 0.5f, 0.5f, 1.0f, 0.5f),
                                      0.5f, 0.01f);
        }
        beginTest("silent without sample assigned");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Drums");
            expect(!trackId.empty(), "track created");

            host.createMidiClip(trackId, 0.0, 4.0);
            host.setPlaying(true);

            float silent[512] = {};
            host.readMasterMix(silent, 512, 48000.0, 0.0);
            float peakSilent = 0.0f;
            for (const float sample : silent)
                peakSilent = std::max(peakSilent, std::abs(sample));
            expect(peakSilent <= 1.0e-4f, "silent when no sample assigned");
        }
        beginTest("audio with sample assigned");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Drums");
            host.createMidiClip(trackId, 0.0, 4.0);
            host.setPlaying(true);

            expect(host.setDeviceStringParameter("dev-1", "sampleId", "sample_kick"),
                   "set sampleId");

            float withSample[512] = {};
            host.readMasterMix(withSample, 512, 48000.0, 0.0);
            float peakSample = 0.0f;
            for (const float sample : withSample)
                peakSample = std::max(peakSample, std::abs(sample));
            expect(peakSample > 1.0e-4f, "non-zero audio with sample assigned");
        }
        beginTest("slow attack reduces peak");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Drums");
            host.createMidiClip(trackId, 0.0, 4.0);
            host.setPlaying(true);
            host.setDeviceStringParameter("dev-1", "sampleId", "sample_kick");

            float withSample[512] = {};
            host.readMasterMix(withSample, 512, 48000.0, 0.0);
            float peakSample = 0.0f;
            for (const float sample : withSample)
                peakSample = std::max(peakSample, std::abs(sample));

            expect(host.setDeviceParameter("dev-1", "attack", 1.0f), "set attack");

            float slowAttack[512] = {};
            host.readMasterMix(slowAttack, 512, 48000.0, 0.0);
            float peakSlow = 0.0f;
            for (const float sample : slowAttack)
                peakSlow = std::max(peakSlow, std::abs(sample));
            expect(peakSlow < peakSample * 0.95f, "slow attack reduces peak");
        }
    }
};
static SamplerMidiPlaybackTest samplerMidiPlaybackTest;