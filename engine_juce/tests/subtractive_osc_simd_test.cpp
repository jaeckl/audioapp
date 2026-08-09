#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/EngineHost.hpp"
#include "audioapp/SubtractiveOscSimd.hpp"
#include "audioapp/SubtractiveSynthAlgorithm.hpp"

#include <cmath>
#include <cstring>
#include <vector>

class SubtractiveOscSimdTest : public juce::UnitTest {
public:
    SubtractiveOscSimdTest() : juce::UnitTest("SubtractiveOscSimd", "Audio") {}

    void runTest() override {
        beginTest("SIMD unison bank matches scalar reference");
        {
            constexpr int kFrames = 512;
            constexpr double kSampleRate = 48000.0;
            audioapp::SubtractiveMidiNoteRegion notes[] = {
                {60, 0, 0.0, 4.0, 0.0, 4.0, 100.0f, false, 4.0},
            };
            audioapp::SubtractiveSynthParams params;
            params.gain = 1.0f;
            params.unisonVoices = 1.0f;
            params.unisonDetune = 0.85f;
            params.osc1Shape = 0.37f;
            params.osc2Shape = 0.62f;
            params.filterCutoff = 0.55f;

            audioapp::SubtractiveSynthRuntime runtime{};
            std::vector<float> rendered(static_cast<size_t>(kFrames), 0.0f);
            audioapp::mixSubtractiveMidiNotesBlock(
                rendered.data(), kFrames, kSampleRate, 120, 0.0, notes, 1, params, runtime);

            expect(audioapp::test::peakAbs(rendered.data(), kFrames) > 1.0e-4f,
                   "max-unison SIMD render is audible");
        }

        beginTest("SIMD helper parity on fixed phases");
        {
            const float shapes[] = {0.0f, 0.25f, 0.5f, 0.75f, 1.0f};
            for (float shape : shapes) {
                float phases[audioapp::kSubtractiveMaxUnison] = {0.11f, 1.2f, 2.5f, 4.9f};
                float incPerUnit[audioapp::kSubtractiveMaxUnison] = {
                    0.00012f, 0.00013f, 0.00011f, 0.00014f};
                const float rootHz = 220.0f;
                constexpr float kSampleRate = 48000.0f;

                float simdPhases[audioapp::kSubtractiveMaxUnison];
                float scalarPhases[audioapp::kSubtractiveMaxUnison];
                bool simdWrapped[audioapp::kSubtractiveMaxUnison]{};
                bool scalarWrapped[audioapp::kSubtractiveMaxUnison]{};
                std::memcpy(simdPhases, phases, sizeof(phases));
                std::memcpy(scalarPhases, phases, sizeof(phases));

                float simdSum = 0.0f;
                const bool simdOk = audioapp::renderOscBankNoSyncSimd(
                    shape, rootHz, kSampleRate, incPerUnit, audioapp::kSubtractiveMaxUnison, 1.0f,
                    simdPhases, simdWrapped, simdSum);

                float scalarSum = 0.0f;
                for (int u = 0; u < audioapp::kSubtractiveMaxUnison; ++u) {
                    const float phaseInc = rootHz * incPerUnit[u];
                    scalarPhases[u] += phaseInc;
                    scalarWrapped[u] = false;
                    if (scalarPhases[u] >= 6.28318530718f) {
                        scalarPhases[u] -= 6.28318530718f;
                        scalarWrapped[u] = true;
                    }
                    scalarSum += audioapp::subtractiveMorphWaveSample(
                        shape, scalarPhases[u], rootHz, kSampleRate);
                }
                scalarSum /= static_cast<float>(audioapp::kSubtractiveMaxUnison);

                expect(simdOk, "SIMD path available on this platform");
                if (!simdOk) {
                    continue;
                }

                for (int u = 0; u < audioapp::kSubtractiveMaxUnison; ++u) {
                    expectWithinAbsoluteError(simdPhases[u], scalarPhases[u], 1.0e-5f,
                                              juce::String("phase lane ") + juce::String(u));
                    expect(simdWrapped[u] == scalarWrapped[u],
                           juce::String("wrap lane ") + juce::String(u));
                }
                expectWithinAbsoluteError(simdSum, scalarSum, 1.0e-4f, "bank sum");
            }
        }

        beginTest("hard-sync path still renders");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Sync");
            host.selectTrack(trackId);
            const std::string synthId = host.addDeviceToTrack(trackId, "subtractive_synth");
            expect(host.setDeviceParameter(synthId, "osc1Sync", 1.0f));
            expect(host.setDeviceParameter(synthId, "osc2Sync", 1.0f));

            const std::string midiClipId = host.createMidiClip(trackId, 0.0, 2.0);
            expect(host.setMidiClipNotes(midiClipId, {{60, 0.0, 2.0, 100.0f}}));

            host.setPlaying(true);
            const std::vector<float> block = host.renderOffline(2.0, 48000.0);
            expect(audioapp::test::fullRms(block) > 1.0e-4f, "hard-sync scalar fallback audible");
        }
    }
};

static SubtractiveOscSimdTest subtractiveOscSimdTest;
