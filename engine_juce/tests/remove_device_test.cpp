#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/EngineHost.hpp"

#include <cmath>
#include <atomic>
#include <string>
#include <thread>
#include <vector>

namespace {

float meanAbsDifference(const std::vector<float>& a, const std::vector<float>& b) noexcept {
    const size_t count = std::min(a.size(), b.size());
    if (count == 0) return 0.0f;
    double acc = 0.0;
    for (size_t i = 0; i < count; ++i) {
        acc += std::abs(a[i] - b[i]);
    }
    return static_cast<float>(acc / static_cast<double>(count));
}

} // namespace

class RemoveDeviceTest : public juce::UnitTest {
public:
    RemoveDeviceTest() : juce::UnitTest("RemoveDevice", "Devices") {}
    void runTest() override {
        beginTest("remove device from track");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Devices");
            host.selectTrack(trackId);

            const std::string samplerId = host.addDeviceToTrack(trackId, "simple_sampler");
            const std::string fxId = host.addDeviceToTrack(trackId, "compressor");
            expect(!samplerId.empty(), "sampler created");
            expect(!fxId.empty(), "compressor created");

            const std::string clipId = host.createAutomationClip(trackId, 0.0, 4.0);
            expect(!clipId.empty(), "auto clip created");
            expect(host.assignAutomationTarget(clipId, fxId, "threshold"),
                   "assign auto target");
            const int lfoId = host.createLfo();
            expect(lfoId > 0, "LFO created");
            expect(host.assignModulation(lfoId, fxId, "threshold", 0.5f),
                   "assign modulation");

            expect(host.removeDeviceFromTrack(fxId), "remove fx device");

            const std::string json = host.getProjectSnapshotJson();
            expect(!audioapp::test::snapshotContainsDevice(json, fxId),
                   "removed device not in snapshot");
            expect(json.find("\"deviceId\":\"" + fxId + "\"") == std::string::npos,
                   "no auto target referencing removed device");
            expect(audioapp::test::snapshotContainsDevice(json, samplerId),
                   "sampler still in snapshot");
        }
        beginTest("remove missing device returns false");
        {
            audioapp::EngineHost host;
            host.createProject();
            expect(!host.removeDeviceFromTrack("dev-missing"),
                   "remove missing returns false");
        }
        beginTest("remove track-1 (always-present device) returns false");
        {
            audioapp::EngineHost host;
            host.createProject();
            host.addTrack("Devices");
            host.selectTrack("track-1");
            expect(!host.removeDeviceFromTrack("dev-1"),
                   "remove track_gain returns false");
        }
        beginTest("remove all devices from track");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Devices");
            host.selectTrack(trackId);

            const std::string samplerId = host.addDeviceToTrack(trackId, "simple_sampler");
            expect(!samplerId.empty(), "sampler created");

            expect(host.removeDeviceFromTrack(samplerId),
                   "remove sampler device");
        }
        beginTest("fx after removed device still processes");
        {
            auto renderAfterRemove = [](bool bypassDistortion) {
                audioapp::EngineHost host;
                host.createProject();
                const std::string trackId = host.addTrack("FX chain");
                host.selectTrack(trackId);

                const std::string oscId = host.addDeviceToTrack(trackId, "simple_oscillator");
                const std::string removedFxId = host.addDeviceToTrack(trackId, "bitcrusher");
                const std::string tremoloId = host.addDeviceToTrack(trackId, "tremolo");
                const std::string distortionId = host.addDeviceToTrack(trackId, "distortion");
                if (oscId.empty() || removedFxId.empty() || tremoloId.empty() || distortionId.empty()) {
                    return std::vector<float>{};
                }

                host.setDeviceParameter(tremoloId, "tremDepth", 0.75f);
                host.setDeviceParameter(distortionId, "distDrive", 1.0f);
                host.setDeviceParameter(distortionId, "distMix", 1.0f);

                const std::string clipId = host.createMidiClip(trackId, 0.0, 4.0);
                std::vector<audioapp::MidiNoteState> notes;
                notes.push_back({60, 0.0, 4.0, 100.0f});
                host.setMidiClipNotes(clipId, notes);

                host.removeDeviceFromTrack(removedFxId);
                if (bypassDistortion) {
                    host.setDeviceParameter(distortionId, "bypass", 1.0f);
                }
                return host.renderOffline(4.0, 48000.0);
            };

            const auto active = renderAfterRemove(false);
            const auto bypassed = renderAfterRemove(true);
            expect(audioapp::test::hasNonZeroSample(active), "active chain renders audio");
            expect(audioapp::test::hasNonZeroSample(bypassed), "bypassed comparison renders audio");
            expect(meanAbsDifference(active, bypassed) > 1.0e-4f,
                   "second remaining FX still changes audio after removing earlier FX");
        }
        beginTest("live edits and phase-mod deletion are audio-thread safe");
        {
            audioapp::EngineHost host;
            host.createProject();
            const auto trackId = host.addTrack("Live edits");
            host.selectTrack(trackId);
            const auto synthId = host.addDeviceToTrack(trackId, "phase_mod_synth");
            const auto clipId = host.createMidiClip(trackId, 0.0, 4.0);
            host.setMidiClipNotes(clipId, {{60, 0.0, 4.0, 100.0f}});
            host.setPlaying(true);

            std::atomic<bool> keepRendering{true};
            std::atomic<bool> finiteOutput{true};
            std::thread audio([&] {
                float left[128]{};
                float right[128]{};
                double beat = 0.0;
                while (keepRendering.load(std::memory_order_acquire)) {
                    host.readMasterMixStereo(left, right, 128, 48000.0, beat);
                    for (int i = 0; i < 128; ++i) {
                        if (!std::isfinite(left[i]) || !std::isfinite(right[i])) {
                            finiteOutput.store(false, std::memory_order_release);
                        }
                    }
                    beat += 128.0 / 48000.0 * 2.0;
                }
            });

            for (int i = 0; i < 250; ++i) {
                expect(host.setDeviceParameter(
                    synthId, "pmFeedback", static_cast<float>(i % 100) / 100.0f));
                expect(host.setTrackMuted(trackId, (i % 7) == 0));
                expect(host.setTrackSoloed(trackId, (i % 11) == 0));
            }
            expect(host.setTrackMuted(trackId, false));
            expect(host.setTrackSoloed(trackId, false));
            expect(host.removeDeviceFromTrack(synthId), "phase-mod synth removed during playback");
            keepRendering.store(false, std::memory_order_release);
            audio.join();
            expect(finiteOutput.load(std::memory_order_acquire), "all concurrent output remained finite");

            float left[256]{};
            float right[256]{};
            host.readMasterMixStereo(left, right, 256, 48000.0, 1.0);
            float peak = 0.0f;
            for (int i = 0; i < 256; ++i) {
                peak = std::max(peak, std::max(std::abs(left[i]), std::abs(right[i])));
            }
            expect(peak < 1.0e-6f, "removed phase-mod synth leaves no stuck sine voice");
        }
        beginTest("live knob gestures never emit an empty audio block");
        {
            audioapp::EngineHost host;
            host.createProject();
            const auto trackId = host.addTrack("Continuous live edit");
            host.selectTrack(trackId);
            host.addDeviceToTrack(trackId, "simple_oscillator");
            const auto distortionId = host.addDeviceToTrack(trackId, "distortion");
            const auto clipId = host.createMidiClip(trackId, 0.0, 16.0);
            host.setMidiClipNotes(clipId, {{60, 0.0, 16.0, 100.0f}});
            host.setPlaying(true);

            std::atomic<bool> keepRendering{true};
            std::atomic<int> renderedBlocks{0};
            std::atomic<int> silentBlocksAfterSignal{0};
            std::thread audio([&] {
                float left[128]{};
                float right[128]{};
                double beat = 0.0;
                bool signalStarted = false;
                while (keepRendering.load(std::memory_order_acquire)) {
                    host.readMasterMixStereo(left, right, 128, 48000.0, beat);
                    float peak = 0.0f;
                    for (int i = 0; i < 128; ++i)
                        peak = std::max(peak, std::max(std::abs(left[i]), std::abs(right[i])));
                    signalStarted |= peak > 1.0e-5f;
                    if (signalStarted && peak < 1.0e-8f)
                        silentBlocksAfterSignal.fetch_add(1, std::memory_order_relaxed);
                    renderedBlocks.fetch_add(1, std::memory_order_release);
                    beat += 128.0 / 48000.0 * 2.0;
                }
            });

            for (int i = 0; i < 2000; ++i) {
                expect(host.setDeviceParameter(
                    distortionId, "distDrive", static_cast<float>(i % 100) / 99.0f));
                std::this_thread::yield();
            }
            while (renderedBlocks.load(std::memory_order_acquire) < 100)
                std::this_thread::yield();
            keepRendering.store(false, std::memory_order_release);
            audio.join();
            expectEquals(silentBlocksAfterSignal.load(std::memory_order_acquire), 0,
                         "no callback was replaced by silence during a knob gesture");
        }
        beginTest("structural swaps keep the previous graph rendering");
        {
            audioapp::EngineHost host;
            host.createProject();
            const auto trackId = host.addTrack("Structural continuity");
            host.selectTrack(trackId);
            host.addDeviceToTrack(trackId, "simple_oscillator");
            const auto clipId = host.createMidiClip(trackId, 0.0, 16.0);
            host.setMidiClipNotes(clipId, {{60, 0.0, 16.0, 100.0f}});
            host.setPlaying(true);

            std::atomic<bool> keepRendering{true};
            std::atomic<int> renderedBlocks{0};
            std::atomic<int> silentBlocksAfterSignal{0};
            std::thread audio([&] {
                float left[128]{};
                float right[128]{};
                double beat = 0.0;
                bool signalStarted = false;
                while (keepRendering.load(std::memory_order_acquire)) {
                    host.readMasterMixStereo(left, right, 128, 48000.0, beat);
                    float peak = 0.0f;
                    for (int i = 0; i < 128; ++i)
                        peak = std::max(peak, std::max(std::abs(left[i]), std::abs(right[i])));
                    signalStarted |= peak > 1.0e-5f;
                    if (signalStarted && peak < 1.0e-8f)
                        silentBlocksAfterSignal.fetch_add(1, std::memory_order_relaxed);
                    renderedBlocks.fetch_add(1, std::memory_order_release);
                    beat += 128.0 / 48000.0 * 2.0;
                }
            });

            for (int i = 0; i < 40; ++i) {
                const auto effectId = host.addDeviceToTrack(trackId, "distortion");
                expect(!effectId.empty(), "effect added during playback");
                expect(host.removeDeviceFromTrack(effectId), "effect removed during playback");
            }
            while (renderedBlocks.load(std::memory_order_acquire) < 100)
                std::this_thread::yield();
            keepRendering.store(false, std::memory_order_release);
            audio.join();
            expectEquals(silentBlocksAfterSignal.load(std::memory_order_acquire), 0,
                         "no structural rebuild replaced a callback with silence");
        }
        beginTest("drum virtual-strip child parameters reach live DSP");
        {
            audioapp::EngineHost host;
            host.createProject();
            const auto trackId = host.addTrack("Drums");
            host.selectTrack(trackId);
            const auto machineId = host.addDeviceToTrack(trackId, "drum_machine");
            const auto kickId = host.addDeviceToDrumPad(machineId, 36, "kick_generator");
            const auto clipId = host.createMidiClip(trackId, 0.0, 1.0);
            host.setMidiClipNotes(clipId, {{36, 0.0, 0.25, 127.0f}});

            expect(host.setDeviceParameter(kickId, "kickPitch", 0.05f));
            const auto low = host.renderOffline(1.0, 48000.0);
            expect(host.setDeviceParameter(kickId, "kickPitch", 0.95f));
            const auto high = host.renderOffline(1.0, 48000.0);

            expect(audioapp::test::hasNonZeroSample(low), "low-pitch pad child renders");
            expect(audioapp::test::hasNonZeroSample(high), "high-pitch pad child renders");
            expect(meanAbsDifference(low, high) > 1.0e-4f,
                   "nested kick parameter changes generated audio");
        }
        beginTest("move device within track preserves ids and order");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Reorder");
            host.selectTrack(trackId);

            const std::string oscId = host.addDeviceToTrack(trackId, "simple_oscillator");
            const std::string fxId = host.addDeviceToTrack(trackId, "compressor");
            const std::string delayId = host.addDeviceToTrack(trackId, "delay");
            expect(!oscId.empty() && !fxId.empty() && !delayId.empty(),
                   "devices created");

            expect(host.moveDeviceInTrack(delayId, 0), "move delay to front");
            const std::string json = host.getProjectSnapshotJson();
            expect(json.find("\"id\":\"" + delayId + "\"") != std::string::npos,
                   "delay id preserved");
            expect(json.find("\"id\":\"" + oscId + "\"") != std::string::npos,
                   "oscillator id preserved");
            const auto delayPos = json.find("\"id\":\"" + delayId + "\"");
            const auto oscPos = json.find("\"id\":\"" + oscId + "\"");
            expect(delayPos < oscPos, "delay now before oscillator");

            expect(!host.moveDeviceInTrack("dev-1", 0),
                   "cannot move track_gain");
            expect(!host.moveDeviceInTrack("missing", 0),
                   "missing device returns false");
        }
    }
};
static RemoveDeviceTest removeDeviceTest;
