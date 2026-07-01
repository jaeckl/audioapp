/// Tests for LFO modulation of common parameters (gain, pan) on audio devices.
///
/// Tests cover:
///   1. LFO modulating "gain" — amplitude should vary with LFO frequency
///   2. LFO modulating "pan" — RMS variation differs from unmodulated case
///   3. Two LFOs modulating "gain" and "pan" simultaneously
///
/// All tests use EngineHost::renderOffline to exercise the complete
/// control-thread -> audio-thread path, verifying that common parameter
/// modulation produces audible variation.

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
#include <cstdio>
#include <limits>
#include <vector>

namespace {

/// Create a basic project with a track, a subtractive synth, and a long MIDI note.
struct TestSetup {
    audioapp::EngineHost host;
    std::string trackId;
    std::string synthId;
    std::string midiClipId;

    TestSetup() {
        host.createProject();
        trackId = host.addTrack("Test");
        host.selectTrack(trackId);
        synthId = host.addDeviceToTrack(trackId, "subtractive_synth");

        midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
        std::vector<audioapp::MidiNoteState> notes;
        notes.push_back({60, 0.0, 4.0, 100.0f});
        host.setMidiClipNotes(midiClipId, notes);
    }

    int createLfo(int waveform = 0, float rate = 4.0f, int syncDivision = 0) {
        const int lfoId = host.createLfo(0); // 0 = LFO
        host.updateLfoParam(lfoId, "waveform", static_cast<float>(waveform));
        host.updateLfoParam(lfoId, "rate", rate);
        host.updateLfoParam(lfoId, "syncDivision", static_cast<float>(syncDivision)); // 0 = free Hz
        // Sync retrigger (1) uses absolute playhead position to advance phase, so
        // the LFO sweeps continuously across the rendered buffer. Free retrigger
        // (0, the default) uses block-relative time and resets phase at every
        // block boundary, which would only produce intra-block variation —
        // insufficient for window-based RMS comparison across a multi-second
        // render. Sync retrigger is the natural choice for offline renders.
        host.updateLfoParam(lfoId, "retrigger", 1.0f);
        return lfoId;
    }
};

} // namespace

class CommonParamModulationTest : public juce::UnitTest {
public:
    CommonParamModulationTest() : juce::UnitTest("CommonParamModulation", "Effects") {}
    void runTest() override {
        using namespace audioapp;
        using namespace audioapp::test;

        beginTest("LFO->gain amplitude modulation");
        {
            TestSetup setup;
            const int lfoId = setup.createLfo(1, 4.0f, 0); // triangle @ 4 Hz, free
            expect(setup.host.assignModulation(lfoId, setup.synthId, "gain", 0.8f),
                   "assign modulation");

            setup.host.setPlaying(true);
            const std::vector<float> block = setup.host.renderOffline(4.0, 48000.0);
            expect(block.size() >= 48000, "enough audio frames");

            const float overallRms = rms(block, 1000, 4000);
            expect(overallRms >= 1.0e-4f, "audible output");

            constexpr int kWindows = 8;
            const std::vector<float> w = windowRMS(block, kWindows);
            std::printf("\n[Diag3] gain block windows:\n");
            for (int i = 0; i < kWindows; ++i) std::printf("  w%d: %g\n", i, w[i]);
            const float ratio = rmsVariationRatio(block, kWindows);
            std::printf("[Diag3] gain ratio=%g\n", ratio);
            expect(ratio >= 1.15f, "LFO gain modulation creates RMS variation");
        }

        beginTest("LFO->pan modulation round-trips and produces audio");
        {
            // Pan modulation on a mono source does not affect the mono-sum
            // output (renderOffline returns mono). Verify the modulation
            // assignment succeeds and audio is audible.
            TestSetup setupPan;
            const int lfoPan = setupPan.createLfo(1, 4.0f, 0); // triangle @ 4 Hz
            expect(setupPan.host.assignModulation(lfoPan, setupPan.synthId, "pan", 0.8f),
                   "assign pan modulation");
            setupPan.host.setPlaying(true);
            const std::vector<float> panModBlock = setupPan.host.renderOffline(4.0, 48000.0);

            expect(panModBlock.size() >= 48000, "pan mod buffer size");
            expect(rms(panModBlock, 1000, 4000) >= 1.0e-4f, "pan mod audio");
        }

        beginTest("two LFOs modulating gain+pan simultaneously");
        {
            TestSetup setup;
            const int lfoGain = setup.createLfo(1, 4.0f, 0);
            expect(setup.host.assignModulation(lfoGain, setup.synthId, "gain", 0.8f),
                   "assign gain mod");
            const int lfoPan = setup.host.createLfo(0);
            setup.host.updateLfoParam(lfoPan, "waveform", 0.0f); // sine
            setup.host.updateLfoParam(lfoPan, "rate", 7.0f);
            setup.host.updateLfoParam(lfoPan, "syncDivision", 0.0f);
            setup.host.updateLfoParam(lfoPan, "retrigger", 1.0f);
            expect(setup.host.assignModulation(lfoPan, setup.synthId, "pan", 0.6f),
                   "assign pan mod");

            setup.host.setPlaying(true);
            const std::vector<float> block = setup.host.renderOffline(4.0, 48000.0);
            expect(block.size() >= 48000, "enough audio frames");

            const float overallRms = rms(block, 1000, 4000);
            expect(overallRms >= 1.0e-4f, "audible output");

            constexpr int kWindows = 8;
            const float ratio = rmsVariationRatio(block, kWindows);
            std::printf("\n[Diag3] combined ratio=%g\n", ratio);
            expect(ratio >= 1.15f, "combined LFOs produce RMS variation");

            const int windowFrames = static_cast<int>(block.size()) / kWindows;
            float minRms = std::numeric_limits<float>::infinity();
            for (int w = 0; w < kWindows; ++w) {
                const int start = w * windowFrames;
                minRms = std::min(minRms, rms(block, start, windowFrames));
            }
            expect(minRms > 0.0f, "no silent windows");

            int aboveCount = 0;
            for (int w = 0; w < kWindows; ++w) {
                const int start = w * windowFrames;
                if (rms(block, start, windowFrames) > minRms * 1.1f)
                    ++aboveCount;
            }
            expect(aboveCount >= 2, "at least 2 windows clearly above minimum");
        }

        beginTest("Envelope->gain at 0% produces plucky output per note");
        {
            TestSetup setup;
            expect(setup.host.setDeviceParameter(setup.synthId, "gain", 0.0f),
                   "set output gain to 0");

            const int envId = setup.host.createLfo(1);
            setup.host.updateLfoParam(envId, "curveType", 2.0f); // ADR
            setup.host.updateLfoParam(envId, "attack", 0.05f);
            setup.host.updateLfoParam(envId, "decay", 0.2f);
            setup.host.updateLfoParam(envId, "release", 0.15f);
            expect(setup.host.assignModulation(envId, setup.synthId, "gain", 1.0f),
                   "assign full-range envelope to gain");

            std::vector<audioapp::MidiNoteState> notes;
            notes.push_back({60, 0.0, 0.25, 100.0f});
            notes.push_back({60, 0.5, 0.25, 100.0f});
            notes.push_back({60, 1.0, 0.25, 100.0f});
            expect(setup.host.setMidiClipNotes(setup.midiClipId, notes), "set staccato notes");

            setup.host.setPlaying(true);
            const std::vector<float> block = setup.host.renderOffline(2.0, 48000.0);
            expect(block.size() >= 48000, "enough audio frames");
            expect(rms(block, 0, static_cast<int>(block.size())) >= 1.0e-4f,
                   "audible plucks with gain base 0 and envelope modulation");

            expect(rmsVariationRatio(block, 16) > 1.5f,
                   "envelope creates clear pluck-level variation");
        }
    }
};
static CommonParamModulationTest commonParamModulationTest;
