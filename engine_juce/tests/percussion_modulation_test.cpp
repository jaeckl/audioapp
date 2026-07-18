/// E2E test suite for LFO modulation of percussion generator parameters.
///
/// Tests cover:
///   1. LFO -> Kick pitch   -> spectral change
///   2. LFO -> Snare body   -> spectral change
///   3. LFO -> Clap tone    -> spectral change
///   4. LFO -> Crash spread -> stereo-width change
///   5. LFO -> Cymbal width -> stereo-width change
///
/// Each test renders the percussion device with an LFO modulating the
/// characteristic parameter at full amount (1.0). Windows of the buffer
/// are compared for HF energy variation, which indicates the modulation
/// changed the spectral content (timbre) even if RMS stays constant.

#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/EngineHost.hpp"
#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/MidiClipPlayback.hpp"
#include "audioapp/PercussionPitch.hpp"

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
    if (param == "crashSpread" || param == "cymbalWidth") {
        constexpr int kFrames = 96000;
        constexpr int kBlock = 512;
        std::vector<float> left(kFrames, 0.0f);
        std::vector<float> right(kFrames, 0.0f);
        for (int offset = 0; offset < kFrames; offset += kBlock) {
            const int frames = std::min(kBlock, kFrames - offset);
            const double beat = static_cast<double>(offset) / 48000.0 * 2.0;
            host.readMasterMixStereo(left.data() + offset, right.data() + offset,
                                     frames, 48000.0, beat);
        }
        float widest = 0.0f;
        float narrowest = std::numeric_limits<float>::infinity();
        constexpr int kWindows = 8;
        const int windowFrames = kFrames / kWindows;
        for (int window = 0; window < kWindows; ++window) {
            double sideEnergy = 0.0;
            double midEnergy = 0.0;
            const int begin = window * windowFrames;
            for (int frame = begin; frame < begin + windowFrames; ++frame) {
                const double mid = left[frame] + right[frame];
                const double side = left[frame] - right[frame];
                midEnergy += mid * mid;
                sideEnergy += side * side;
            }
            const float width = static_cast<float>(
                std::sqrt(sideEnergy / std::max(midEnergy, 1.0e-12)));
            widest = std::max(widest, width);
            narrowest = std::min(narrowest, width);
        }
        const float widthRatio = widest / std::max(narrowest, 1.0e-6f);
        std::fprintf(stderr, "DIAG perc: type=%s param=%s widthRatio=%g\n",
            deviceType.c_str(), param.c_str(), widthRatio);
        const float requiredRatio = param == "cymbalWidth" ? 1.05f : 1.2f;
        return widthRatio >= requiredRatio;
    }
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
        beginTest("percussion keytrack follows MIDI pitch only when enabled");
        {
            const float fixed = audioapp::percussionPitchRatio(0.5f, 72, 60, 0.0f);
            const float tracked = audioapp::percussionPitchRatio(0.5f, 72, 60, 1.0f);
            expectWithinAbsoluteError(fixed, 1.0f, 0.0001f,
                                      "disabled keytrack should keep fixed tuning");
            expectWithinAbsoluteError(tracked, 2.0f, 0.0001f,
                                      "enabled keytrack should follow semitones");
        }
        beginTest("all percussion keytrack parameters compile for realtime DSP");
        {
            const struct {
                const char* name;
                audioapp::DeviceNodeKind kind;
            } cases[] = {
                {"kickKeyTrack", audioapp::DeviceNodeKind::KickGenerator},
                {"snareKeyTrack", audioapp::DeviceNodeKind::SnareGenerator},
                {"clapKeyTrack", audioapp::DeviceNodeKind::ClapGenerator},
                {"cymbalKeyTrack", audioapp::DeviceNodeKind::CymbalGenerator},
                {"crashKeyTrack", audioapp::DeviceNodeKind::CrashGenerator},
            };
            for (const auto& item : cases) {
                const auto encoded = audioapp::paramIdFromString(item.name, item.kind);
                expect(encoded != 0 &&
                           std::string(audioapp::paramIdToString(encoded, item.kind)) == item.name,
                       std::string(item.name) + " should round-trip through compiled parameter IDs");
            }
        }
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
                   "crash spread modulation should change stereo width");
        }
        beginTest("LFO -> Cymbal width -> spectral change");
        {
            expect(testPercussionModulation("cymbal_generator", "cymbalWidth", "Cymbal width"),
                   "cymbal width modulation should change stereo width");
        }
    }
};
static PercussionModulationTest percussionModulationTest;
