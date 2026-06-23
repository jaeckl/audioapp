/// LFO polarity E2E test suite.
///
/// LFO polarity constrains the modulation signal:
///   0 = bipolar  (-1 .. +1)  — full sweep both directions
///   1 = positive ( 0 .. +1)  — only opens from baseline
///   2 = negative (-1 ..  0)  — only closes from baseline
///
/// Tests cover:
///   1. Bipolar LFO on filterCutoff — wide spectral variation
///   2. Positive-only LFO — produces measurably different HF energy from bipolar
///   3. Negative-only LFO — produces measurably different HF energy from positive
///   4. Polarity persists in JSON round-trip
///
/// Each audio test creates its own isolated EngineHost / project.

#include <juce_core/juce_core.h>
#include "TestHelpers.h"

#include "audioapp/AutomationTypes.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/EngineHost.hpp"
#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/ProjectJson.hpp"
#include "audioapp/SubtractiveSynthAlgorithm.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>
#include <vector>

namespace {

/// Create a project with one track, a subtractive synth, and a sustained MIDI note.
struct PolarityTestSetup {
    audioapp::EngineHost host;
    std::string trackId;
    std::string synthId;
    std::string midiClipId;

    PolarityTestSetup() {
        host.createProject();
        trackId = host.addTrack("Test");
        host.selectTrack(trackId);
        synthId = host.addDeviceToTrack(trackId, "subtractive_synth");

        midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
        std::vector<audioapp::MidiNoteState> notes;
        notes.push_back({60, 0.0, 4.0, 100.0f});
        host.setMidiClipNotes(midiClipId, notes);
    }

    int createLfoWithPolarity(int polarity, float rate = 4.0f) {
        const int lfoId = host.createLfo(0); // 0 = LFO
        host.updateLfoParam(lfoId, "waveform", 0.0f);     // sine
        host.updateLfoParam(lfoId, "rate", rate);
        host.updateLfoParam(lfoId, "syncDivision", 0.0f); // free Hz
        host.updateLfoParam(lfoId, "polarity", static_cast<float>(polarity));
        return lfoId;
    }
};

} // namespace

class LfoPolarityTest : public juce::UnitTest {
public:
    LfoPolarityTest()
        : juce::UnitTest("LFO Polarity", "Modulation") {}

    void runTest() override {
        using namespace audioapp;

        beginTest("Bipolar LFO on filterCutoff — full sweep");
        {
            PolarityTestSetup setup;
            const int lfoId = setup.createLfoWithPolarity(0, 4.0f);
            expect(setup.host.assignModulation(lfoId, setup.synthId, "filterCutoff", 0.8f));

            setup.host.setPlaying(true);
            const std::vector<float> block = setup.host.renderOffline(4.0, 48000.0);
            expect(block.size() >= 48000);
            expect(audioapp::test::rms(block, 1000, 4000) >= 1.0e-4f);

            // Split into 8 half-beat windows. Bipolar modulation should
            // produce a wide spread of HF energy (filter opens AND closes).
            constexpr int kWindows = 8;
            const int windowFrames = static_cast<int>(block.size()) / kWindows;
            float brightest = 0.0f;
            float darkest = std::numeric_limits<float>::infinity();
            for (int w = 0; w < kWindows; ++w) {
                const int start = w * windowFrames;
                const float hf = audioapp::test::highFrequencyEnergy(block, start, windowFrames);
                expect(hf > 0.0f);
                brightest = std::max(brightest, hf);
                darkest = std::min(darkest, hf);
            }
            expect(darkest > 0.0f);
            // Bipolar LFO sweeps both ways — expect > 1.5x ratio
            expect(brightest >= darkest * 1.5f, "Bipolar LFO should produce wide HF variation");
        }

        beginTest("Positive-only LFO produces different HF from bipolar");
        {
            PolarityTestSetup setup;
            const int lfoId = setup.createLfoWithPolarity(0, 4.0f); // start bipolar
            expect(setup.host.assignModulation(lfoId, setup.synthId, "filterCutoff", 0.8f));

            // Render with bipolar
            setup.host.setPlaying(true);
            const std::vector<float> bipolarBlock = setup.host.renderOffline(4.0, 48000.0);
            expect(bipolarBlock.size() >= 48000);
            expect(audioapp::test::rms(bipolarBlock, 1000, 4000) >= 1.0e-4f);

            // Re-render with positive-only
            expect(setup.host.updateLfoParam(lfoId, "polarity", 1.0f));
            const std::vector<float> positiveBlock = setup.host.renderOffline(4.0, 48000.0);
            expect(positiveBlock.size() >= 48000);
            expect(audioapp::test::rms(positiveBlock, 1000, 4000) >= 1.0e-4f);

            // Compare average HF across windows
            constexpr int kWindows = 8;
            const float bipolarAvgHF = audioapp::test::averageHFPerWindow(bipolarBlock, kWindows);
            const float positiveAvgHF = audioapp::test::averageHFPerWindow(positiveBlock, kWindows);

            // Verifying the two polarity modes produce different average HF energy.
            const float minHF = std::min(bipolarAvgHF, positiveAvgHF);
            const float maxHF = std::max(bipolarAvgHF, positiveAvgHF);
            expect(minHF > 0.0f);
            expect(maxHF >= minHF * 1.1f, "Positive-only should produce different HF from bipolar");
        }

        beginTest("Negative-only LFO produces different HF from positive");
        {
            PolarityTestSetup setup;
            const int lfoId = setup.createLfoWithPolarity(1, 4.0f); // start positive
            expect(setup.host.assignModulation(lfoId, setup.synthId, "filterCutoff", 0.8f));

            // Render with positive
            setup.host.setPlaying(true);
            const std::vector<float> positiveBlock = setup.host.renderOffline(4.0, 48000.0);
            expect(positiveBlock.size() >= 48000);
            expect(audioapp::test::rms(positiveBlock, 1000, 4000) >= 1.0e-4f);

            // Re-render with negative-only
            expect(setup.host.updateLfoParam(lfoId, "polarity", 2.0f));
            const std::vector<float> negativeBlock = setup.host.renderOffline(4.0, 48000.0);
            expect(negativeBlock.size() >= 48000);
            expect(audioapp::test::rms(negativeBlock, 1000, 4000) >= 1.0e-4f);

            // Compare average HF across windows
            constexpr int kWindows = 8;
            const float positiveAvgHF = audioapp::test::averageHFPerWindow(positiveBlock, kWindows);
            const float negativeAvgHF = audioapp::test::averageHFPerWindow(negativeBlock, kWindows);

            const float minHF = std::min(positiveAvgHF, negativeAvgHF);
            const float maxHF = std::max(positiveAvgHF, negativeAvgHF);
            expect(minHF > 0.0f);
            expect(maxHF >= minHF * 1.1f, "Negative-only should produce different HF from positive");
        }

        beginTest("Polarity persists in JSON round-trip");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Test");
            host.selectTrack(trackId);
            host.addDeviceToTrack(trackId, "subtractive_synth");

            const int lfoId = host.createLfo(0);
            host.updateLfoParam(lfoId, "polarity", 0.0f); // bipolar

            // Round-trip 1: verify polarity=0
            {
                const std::string json = host.getProjectFileJson();
                audioapp::ProjectFileData parsed;
                expect(audioapp::test::parseProjectJsonInto(json, parsed));
                bool found = false;
                for (const auto& lfo : parsed.lfos) {
                    if (lfo.id == lfoId) {
                        expectEquals(lfo.polarity, 0);
                        found = true;
                        break;
                    }
                }
                expect(found, "LFO found in round-trip 1");
            }

            // Change to positive-only
            expect(host.updateLfoParam(lfoId, "polarity", 1.0f));

            // Round-trip 2: verify polarity=1
            {
                const std::string json = host.getProjectFileJson();
                audioapp::ProjectFileData parsed;
                expect(audioapp::test::parseProjectJsonInto(json, parsed));
                bool found = false;
                for (const auto& lfo : parsed.lfos) {
                    if (lfo.id == lfoId) {
                        expectEquals(lfo.polarity, 1);
                        found = true;
                        break;
                    }
                }
                expect(found, "LFO found in round-trip 2");
            }

            // Change to negative-only
            expect(host.updateLfoParam(lfoId, "polarity", 2.0f));

            // Round-trip 3: verify polarity=2
            {
                const std::string json = host.getProjectFileJson();
                audioapp::ProjectFileData parsed;
                expect(audioapp::test::parseProjectJsonInto(json, parsed));
                bool found = false;
                for (const auto& lfo : parsed.lfos) {
                    if (lfo.id == lfoId) {
                        expectEquals(lfo.polarity, 2);
                        found = true;
                        break;
                    }
                }
                expect(found, "LFO found in round-trip 3");
            }
        }
    }
};

static LfoPolarityTest lfoPolarityTest;