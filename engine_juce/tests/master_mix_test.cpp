#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/EngineHost.hpp"

#include <vector>

class MasterMixTest : public juce::UnitTest {
public:
    MasterMixTest() : juce::UnitTest("MasterMix", "Engine") {}
    void runTest() override {
        beginTest("master mix produces audio");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackA = host.addTrack("A");
            const std::string trackB = host.addTrack("B");
            expect(!trackA.empty(), "trackA id non-empty");
            expect(!trackB.empty(), "trackB id non-empty");

            expect(!host.createSampleClip(trackA, "sample_kick", 0.0, 0.0).empty(),
                   "createSampleClip trackA");
            expect(!host.createSampleClip(trackB, "sample_snare", 0.0, 0.0).empty(),
                   "createSampleClip trackB");

            host.setPlaying(true);

            float buffer[256] = {};
            host.readMasterMix(buffer, 256, 48000.0, 0.0);

            float peak = 0.0f;
            for (const float sample : buffer)
                peak = std::max(peak, std::abs(sample));
            expect(peak > 0.0f, "master mix should produce non-zero audio");
        }

        beginTest("live master gain ramps inside the callback");
        {
            audioapp::EngineHost host;
            host.createProject();
            const auto track = host.addTrack("Ramp");
            host.selectTrack(track);
            host.addDeviceToTrack(track, "simple_oscillator");
            const auto clip = host.createMidiClip(track, 0.0, 4.0);
            host.setMidiClipNotes(clip, {{69, 0.0, 4.0, 100.0f}});
            host.setPlaying(true);

            float buffer[128]{};
            host.setMasterGain(0.0f);
            host.readMasterMix(buffer, 128, 48000.0, 0.0);
            host.readMasterMix(buffer, 128, 48000.0, 128.0 / 24000.0);
            host.setMasterGain(1.0f);
            host.readMasterMix(buffer, 128, 48000.0, 256.0 / 24000.0);

            float latePeak = 0.0f;
            for (int frame = 96; frame < 128; ++frame)
                latePeak = std::max(latePeak, std::abs(buffer[frame]));
            expect(std::abs(buffer[0]) < 0.01f,
                   "first sample stays near the prior silent master value");
            expect(latePeak > 0.02f,
                   "master ramp reaches audible gain later in the block");
        }

        beginTest("oversized callbacks are chunk-equivalent");
        {
            constexpr int kFrames = 8193;
            constexpr int kChunk = 4096;
            constexpr double kSampleRate = 48000.0;
            constexpr double kBeatsPerFrame = 2.0 / kSampleRate;
            const auto configure = [](audioapp::EngineHost& host) {
                host.createProject();
                const auto track = host.addTrack("Oversized");
                host.addDeviceToTrack(track, "simple_oscillator");
                const auto clip = host.createMidiClip(track, 0.0, 4.0);
                host.setMidiClipNotes(clip, {{69, 0.0, 4.0, 100.0f}});
                host.setPlaying(true);
            };

            audioapp::EngineHost oversizedHost;
            audioapp::EngineHost chunkedHost;
            configure(oversizedHost);
            configure(chunkedHost);
            std::vector<float> oversized(kFrames, 0.0f);
            std::vector<float> chunked(kFrames, 0.0f);

            oversizedHost.readMasterMix(
                oversized.data(), kFrames, kSampleRate, 0.0);
            for (int offset = 0; offset < kFrames; offset += kChunk) {
                const int frames = std::min(kChunk, kFrames - offset);
                chunkedHost.readMasterMix(
                    chunked.data() + offset, frames, kSampleRate,
                    static_cast<double>(offset) * kBeatsPerFrame);
            }

            float tailPeak = 0.0f;
            float maximumDifference = 0.0f;
            for (int frame = 0; frame < kFrames; ++frame) {
                maximumDifference = std::max(
                    maximumDifference,
                    std::abs(oversized[frame] - chunked[frame]));
                if (frame >= kChunk) {
                    tailPeak = std::max(tailPeak, std::abs(oversized[frame]));
                }
            }
            expect(tailPeak > 0.01f,
                   "audio after the former 4096-frame limit is rendered");
            expect(maximumDifference < 1.0e-6f,
                   "one oversized call matches sequential bounded chunks");

            audioapp::EngineHost oversizedStereoHost;
            audioapp::EngineHost chunkedStereoHost;
            configure(oversizedStereoHost);
            configure(chunkedStereoHost);
            std::vector<float> oversizedLeft(kFrames, 0.0f);
            std::vector<float> oversizedRight(kFrames, 0.0f);
            std::vector<float> chunkedLeft(kFrames, 0.0f);
            std::vector<float> chunkedRight(kFrames, 0.0f);
            oversizedStereoHost.readMasterMixStereo(
                oversizedLeft.data(), oversizedRight.data(),
                kFrames, kSampleRate, 0.0);
            for (int offset = 0; offset < kFrames; offset += kChunk) {
                const int frames = std::min(kChunk, kFrames - offset);
                chunkedStereoHost.readMasterMixStereo(
                    chunkedLeft.data() + offset, chunkedRight.data() + offset,
                    frames, kSampleRate,
                    static_cast<double>(offset) * kBeatsPerFrame);
            }
            float stereoDifference = 0.0f;
            for (int frame = 0; frame < kFrames; ++frame) {
                stereoDifference = std::max({
                    stereoDifference,
                    std::abs(oversizedLeft[frame] - chunkedLeft[frame]),
                    std::abs(oversizedRight[frame] - chunkedRight[frame]),
                });
            }
            expect(stereoDifference < 1.0e-6f,
                   "oversized stereo rendering matches bounded chunks");
        }
    }
};
static MasterMixTest masterMixTest;
