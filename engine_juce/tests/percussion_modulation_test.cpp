/// E2E test suite for LFO modulation of percussion generator parameters.
///
/// Tests cover:
///   1. LFO -> Kick pitch   -> spectral change
///   2. LFO -> Snare body   -> spectral change
///   3. LFO -> Clap tone    -> spectral change
///   4. LFO -> Crash spread -> spectral change
///   5. LFO -> Cymbal width -> spectral change
///
/// Each test renders the percussion device with an LFO modulating the
/// characteristic parameter at full amount (1.0). Windows of the buffer
/// are compared for HF energy variation, which indicates the modulation
/// changed the spectral content (timbre) even if RMS stays constant.

#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/EngineHost.hpp"
#include "audioapp/MidiClipPlayback.hpp"

#include <algorithm>
#include <cmath>
#include <string>
#include <vector>

namespace {

/// Render the given percussion device with an LFO modulating the param at
/// full amount (1.0). Return true if windows of the output show at least
/// 1.5x HF energy variation, indicating the modulation changed the timbre.
bool testPercussionModulation(const std::string& deviceType,
                              const std::string& param,
                              const std::string& label) {
    audioapp::EngineHost host;
    host.createProject();
    const std::string trackId = host.addTrack("Test");
    host.selectTrack(trackId);
    const std::string devId = host.addDeviceToTrack(trackId, deviceType);
    const std::string clipId = host.createMidiClip(trackId, 0.0, 4.0);

    std::vector<audioapp::MidiNoteState> notes;
    for (int b = 0; b < 4; ++b)
        notes.push_back({60, static_cast<double>(b), 1.0, 100.0f});
    host.setMidiClipNotes(clipId, notes);

    const int lfoId = host.createLfo(0); // 0 = LFO modulator
    host.updateLfoParam(lfoId, "waveform", 0.0f);    // sine
    host.updateLfoParam(lfoId, "rate", 3.7f);         // 3.7 Hz (avoids zero at beat boundaries)
    host.updateLfoParam(lfoId, "syncDivision", 0.0f); // free (Hz)
    host.updateLfoParam(lfoId, "phase", 0.25f);       // 90° offset → sine starts at max
    if (!host.assignModulation(lfoId, devId, param, 1.0f)) {
        std::fprintf(stderr, "DIAG perc: assignModulation FAILED for %s %s\n",
            deviceType.c_str(), param.c_str());
        return false;
    }

    host.setPlaying(true);
    const std::vector<float> block = host.renderOffline(4.0, 48000.0);
    const float rms = audioapp::test::fullRms(block);

    if (block.size() < 48000)
        return false;
    if (rms < 1.0e-6f)
        return false;

    // Check spectral variation across windows.
    // If modulation is active, different windows should have different HF energy.
    constexpr int kWindows = 8;
    const int windowFrames = static_cast<int>(block.size()) / kWindows;
    float brightest = 0.0f;
    float darkest = std::numeric_limits<float>::infinity();
    for (int w = 0; w < kWindows; ++w) {
        const int start = w * windowFrames;
        const float hf = audioapp::test::highFrequencyEnergy(block, start, windowFrames);
        if (hf <= 0.0f) return false;
        brightest = std::max(brightest, hf);
        darkest = std::min(darkest, hf);
    }
    if (darkest <= 0.0f) return false;
    const float ratio = brightest / darkest;
    std::fprintf(stderr, "DIAG perc: type=%s param=%s rms=%g hfRatio=%g\n",
        deviceType.c_str(), param.c_str(), rms, ratio);
    return ratio >= 1.5f;
}

} // namespace

class PercussionModulationTest : public juce::UnitTest {
public:
    PercussionModulationTest() : juce::UnitTest("PercussionModulation", "Effects") {}
    void runTest() override {
        beginTest("LFO -> Kick pitch -> spectral change");
        {
            expect(testPercussionModulation("kick_generator", "kickPitch", "Kick pitch"),
                   "kick pitch modulation should change spectral content");
        }
        beginTest("LFO -> Snare body -> spectral change");
        {
            expect(testPercussionModulation("snare_generator", "snareBody", "Snare body"),
                   "snare body modulation should change spectral content");
        }
        beginTest("LFO -> Clap tone -> spectral change");
        {
            expect(testPercussionModulation("clap_generator", "clapTone", "Clap tone"),
                   "clap tone modulation should change spectral content");
        }
        beginTest("LFO -> Crash spread -> spectral change");
        {
            expect(testPercussionModulation("crash_generator", "crashSpread", "Crash spread"),
                   "crash spread modulation should change spectral content");
        }
        beginTest("LFO -> Cymbal width -> spectral change");
        {
            expect(testPercussionModulation("cymbal_generator", "cymbalWidth", "Cymbal width"),
                   "cymbal width modulation should change spectral content");
        }
    }
};
static PercussionModulationTest percussionModulationTest;