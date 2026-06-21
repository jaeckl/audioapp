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
#include "audioapp/SubtractiveSynth.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
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
            const float ratio = rmsVariationRatio(block, kWindows);
            expect(ratio >= 1.5f, "LFO gain modulation creates RMS variation");
        }

        beginTest("LFO->pan RMS variation vs unmodulated");
        {
            // Render WITHOUT pan modulation first (baseline)
            audioapp::EngineHost hostUnmod;
            hostUnmod.createProject();
            const std::string trackU = hostUnmod.addTrack("Test");
            hostUnmod.selectTrack(trackU);
            const std::string synthU = hostUnmod.addDeviceToTrack(trackU, "subtractive_synth");
            const std::string clipU = hostUnmod.createMidiClip(trackU, 0.0, 4.0);
            std::vector<MidiNoteState> notesU;
            notesU.push_back({60, 0.0, 4.0, 100.0f});
            hostUnmod.setMidiClipNotes(clipU, notesU);
            hostUnmod.setPlaying(true);
            const std::vector<float> unmodBlock = hostUnmod.renderOffline(4.0, 48000.0);

            // Render WITH pan modulation
            TestSetup setupPan;
            const int lfoPan = setupPan.createLfo(1, 4.0f, 0); // triangle @ 4 Hz
            expect(setupPan.host.assignModulation(lfoPan, setupPan.synthId, "pan", 0.8f),
                   "assign pan modulation");
            setupPan.host.setPlaying(true);
            const std::vector<float> panModBlock = setupPan.host.renderOffline(4.0, 48000.0);

            expect(unmodBlock.size() >= 48000, "unmod buffer size");
            expect(panModBlock.size() >= 48000, "pan mod buffer size");
            expect(rms(unmodBlock, 1000, 4000) >= 1.0e-4f, "unmod audio");
            expect(rms(panModBlock, 1000, 4000) >= 1.0e-4f, "pan mod audio");

            constexpr int kWindows = 8;
            const float unmodRatio = rmsVariationRatio(unmodBlock, kWindows);
            const float panRatio = rmsVariationRatio(panModBlock, kWindows);
            
            expect(panRatio >= unmodRatio * 1.15f,
                   "pan modulation adds RMS variation beyond baseline");
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
            expect(setup.host.assignModulation(lfoPan, setup.synthId, "pan", 0.6f),
                   "assign pan mod");

            setup.host.setPlaying(true);
            const std::vector<float> block = setup.host.renderOffline(4.0, 48000.0);
            expect(block.size() >= 48000, "enough audio frames");

            const float overallRms = rms(block, 1000, 4000);
            expect(overallRms >= 1.0e-4f, "audible output");

            constexpr int kWindows = 8;
            const float ratio = rmsVariationRatio(block, kWindows);
            expect(ratio >= 1.5f, "combined LFOs produce RMS variation");

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
            expect(aboveCount >= 3, "at least 3 windows clearly above minimum");
        }
    }
};
static CommonParamModulationTest commonParamModulationTest;