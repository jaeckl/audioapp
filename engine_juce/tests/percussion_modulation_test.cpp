/// E2E test suite for LFO modulation of percussion generator parameters.
///
/// Tests cover:
///   1. LFO -> Kick pitch   -> RMS change
///   2. LFO -> Snare body   -> RMS change
///   3. LFO -> Clap tone    -> RMS change
///   4. LFO -> Crash spread -> RMS change
///   5. LFO -> Cymbal width -> RMS change
///
/// Each test renders the same MIDI pattern (notes on each beat for 4 beats)
/// twice — once without modulation and once with an LFO modulating the
/// characteristic parameter at full amount (1.0). The RMS of the full
/// 4-beat buffer must differ by at least 15%.

#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/EngineHost.hpp"
#include "audioapp/MidiClipPlayback.hpp"

#include <algorithm>
#include <cmath>
#include <string>
#include <vector>

namespace {

/// Render the given percussion device type twice (unmodulated vs modulated on
/// the given param at full amount). Return true if the RMS differs by > 15%.
bool testPercussionModulation(const std::string& deviceType,
                              const std::string& param,
                              const std::string& label) {
    // === Unmodulated render ===
    audioapp::EngineHost hostU;
    hostU.createProject();
    const std::string trackU = hostU.addTrack("Test");
    hostU.selectTrack(trackU);
    const std::string devU = hostU.addDeviceToTrack(trackU, deviceType);
    const std::string clipU = hostU.createMidiClip(trackU, 0.0, 4.0);

    std::vector<audioapp::MidiNoteState> notesU;
    for (int b = 0; b < 4; ++b)
        notesU.push_back({60, static_cast<double>(b), 1.0, 100.0f});
    hostU.setMidiClipNotes(clipU, notesU);
    hostU.setPlaying(true);
    const std::vector<float> unmod = hostU.renderOffline(4.0, 48000.0);
    const float rmsU = audioapp::test::fullRms(unmod);

    if (unmod.size() < 48000)
        return false;
    if (rmsU < 1.0e-6f)
        return false;

    // === Modulated render ===
    audioapp::EngineHost hostM;
    hostM.createProject();
    const std::string trackM = hostM.addTrack("Test");
    hostM.selectTrack(trackM);
    const std::string devM = hostM.addDeviceToTrack(trackM, deviceType);
    const std::string clipM = hostM.createMidiClip(trackM, 0.0, 4.0);

    std::vector<audioapp::MidiNoteState> notesM;
    for (int b = 0; b < 4; ++b)
        notesM.push_back({60, static_cast<double>(b), 1.0, 100.0f});
    hostM.setMidiClipNotes(clipM, notesM);

    const int lfoId = hostM.createLfo(0); // 0 = LFO modulator
    hostM.updateLfoParam(lfoId, "waveform", 0.0f);    // sine
    hostM.updateLfoParam(lfoId, "rate", 4.0f);         // 4 Hz
    hostM.updateLfoParam(lfoId, "syncDivision", 0.0f); // free (Hz)
    if (!hostM.assignModulation(lfoId, devM, param, 1.0f))
        return false;

    hostM.setPlaying(true);
    const std::vector<float> mod = hostM.renderOffline(4.0, 48000.0);
    const float rmsM = audioapp::test::fullRms(mod);

    if (mod.size() < 48000)
        return false;
    if (rmsM < 1.0e-6f)
        return false;

    const float ratio = rmsM / rmsU;
    const float threshold = 1.15f;
    return (ratio > threshold) || (ratio < 1.0f / threshold);
}

} // namespace

class PercussionModulationTest : public juce::UnitTest {
public:
    PercussionModulationTest() : juce::UnitTest("PercussionModulation", "Effects") {}
    void runTest() override {
        beginTest("LFO -> Kick pitch -> RMS change");
        {
            expect(testPercussionModulation("kick_generator", "kickPitch", "Kick pitch"),
                   "kick pitch modulation changes RMS");
        }
        beginTest("LFO -> Snare body -> RMS change");
        {
            expect(testPercussionModulation("snare_generator", "snareBody", "Snare body"),
                   "snare body modulation changes RMS");
        }
        beginTest("LFO -> Clap tone -> RMS change");
        {
            expect(testPercussionModulation("clap_generator", "clapTone", "Clap tone"),
                   "clap tone modulation changes RMS");
        }
        beginTest("LFO -> Crash spread -> RMS change");
        {
            expect(testPercussionModulation("crash_generator", "crashSpread", "Crash spread"),
                   "crash spread modulation changes RMS");
        }
        beginTest("LFO -> Cymbal width -> RMS change");
        {
            expect(testPercussionModulation("cymbal_generator", "cymbalWidth", "Cymbal width"),
                   "cymbal width modulation changes RMS");
        }
    }
};
static PercussionModulationTest percussionModulationTest;