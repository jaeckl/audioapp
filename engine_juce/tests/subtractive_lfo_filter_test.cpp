/// Regression test for the post-refactor subtractive LFO modulation bug.
///
/// Symptom (commit a8526c5): moving the manual filterCutoff knob on a
/// subtractive synth was audible, but an LFO assigned to filterCutoff on the
/// same device had no effect. Cause: the refactor routed modulation to a
/// per-track edge list with deviceIndex matching, and the per-frame LFO apply
/// inside mixSubtractiveMidiNotesBlock was never added — automation was
/// already applied per-frame there, but modulation was not.
///
/// This test renders 4 beats at 48k with a 0.73 Hz sine LFO sweeping
/// filterCutoff. The deliberately non-integral rate prevents each 0.25-second
/// analysis window from averaging one identical complete LFO cycle.

#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/EngineHost.hpp"

#include <cmath>
#include <limits>
#include <vector>

class SubtractiveLfoFilterTest : public juce::UnitTest {
public:
    SubtractiveLfoFilterTest() : juce::UnitTest("SubtractiveLfoFilter", "Regression") {}
    void runTest() override {
        using namespace audioapp::test;

        beginTest("LFO filterCutoff sweep detection");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("LFO Sweep");
            host.selectTrack(trackId);
            const std::string synthId = host.addDeviceToTrack(trackId, "subtractive_synth");
            expect(host.setDeviceParameter(synthId, "filterCutoff", 0.25f),
                   "set a sweepable base cutoff");
            expect(host.setDeviceParameter(synthId, "filterEnvAmount", 0.0f),
                   "remove envelope brightness from the LFO-only test");

            const std::string midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
            expect(!midiClipId.empty(), "midi clip created");
            std::vector<audioapp::MidiNoteState> notes;
            notes.push_back({60, 0.0, 4.0, 100.0f});
            expect(host.setMidiClipNotes(midiClipId, notes), "set midi notes");

            const int lfoId = host.createLfo(0);
            expect(lfoId > 0, "LFO created");
            expect(host.updateLfoParam(lfoId, "waveform", 0.0f), "set sine");
            expect(host.updateLfoParam(lfoId, "rate", 0.73f), "set non-integral rate");
            expect(host.updateLfoParam(lfoId, "syncDivision", 0.0f), "set syncDiv");
            expect(host.assignModulation(lfoId, synthId, "filterCutoff", 1.0f),
                   "assign modulation");

            host.setPlaying(true);
            const std::vector<float> block = host.renderOffline(4.0, 48000.0);
            expect(block.size() >= 48000, "enough audio frames");
            expect(rms(block, 1000, 4000) >= 1.0e-4f, "audible output");

            constexpr int kWindows = 8;
            expect(filterSweepDetected(block, kWindows, 1.8f),
                   "LFO filterCutoff sweep detected");
        }
    }
};
static SubtractiveLfoFilterTest subtractiveLfoFilterTest;
