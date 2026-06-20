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

#include "audioapp/EngineHost.hpp"
#include "audioapp/MidiClipPlayback.hpp"

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <string>
#include <vector>

namespace {

// ---------- audio analysis helpers ----------

float rms(const std::vector<float>& samples, int start, int count) {
    double acc = 0.0;
    const int end = std::min(start + count, static_cast<int>(samples.size()));
    for (int i = start; i < end; ++i) {
        acc += static_cast<double>(samples[static_cast<size_t>(i)]) *
               static_cast<double>(samples[static_cast<size_t>(i)]);
    }
    return end > start ? static_cast<float>(std::sqrt(acc / static_cast<double>(end - start))) : 0.0f;
}

float fullRms(const std::vector<float>& samples) {
    if (samples.empty())
        return 0.0f;
    return rms(samples, 0, static_cast<int>(samples.size()));
}

// ---------- helper: render a percussion device with and without modulation ----------

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
    const float rmsU = fullRms(unmod);

    if (unmod.size() < 48000) {
        // Not enough audio — the engine likely produced silence
        return false;
    }
    if (rmsU < 1.0e-6f) {
        return false;
    }

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
    if (!hostM.assignModulation(lfoId, devM, param, 1.0f)) {
        return false;
    }

    hostM.setPlaying(true);
    const std::vector<float> mod = hostM.renderOffline(4.0, 48000.0);
    const float rmsM = fullRms(mod);

    if (mod.size() < 48000) {
        return false;
    }
    if (rmsM < 1.0e-6f) {
        return false;
    }

    const float ratio = rmsM / rmsU;
    const float threshold = 1.15f;
    const bool changed = (ratio > threshold) || (ratio < 1.0f / threshold);

    return changed;
}

} // namespace

int main() {
    // =====================================================================
    // Test 1: LFO -> Kick pitch -> RMS change
    //
    // Modulating kickPitch changes the fundamental frequency of the kick
    // drum, which alters the spectral balance and thus the RMS level.
    // =====================================================================
    if (!testPercussionModulation("kick_generator", "kickPitch", "Kick pitch")) {
        return EXIT_FAILURE;
    }

    // =====================================================================
    // Test 2: LFO -> Snare body -> RMS change
    //
    // Modulating snareBody changes the body oscillator amplitude, which
    // directly affects the overall output level of the snare.
    // =====================================================================
    if (!testPercussionModulation("snare_generator", "snareBody", "Snare body")) {
        return EXIT_FAILURE;
    }

    // =====================================================================
    // Test 3: LFO -> Clap tone -> RMS change
    //
    // Modulating clapTone changes the tonal content of the clap, which
    // affects the spectral distribution and overall energy.
    // =====================================================================
    if (!testPercussionModulation("clap_generator", "clapTone", "Clap tone")) {
        return EXIT_FAILURE;
    }

    // =====================================================================
    // Test 4: LFO -> Crash spread -> RMS change
    //
    // Modulating crashSpread changes the stereo width of the crash.
    // The combined L+R RMS differs because the spread gain distribution
    // alters per-channel energy.
    // =====================================================================
    if (!testPercussionModulation("crash_generator", "crashSpread", "Crash spread")) {
        return EXIT_FAILURE;
    }

    // =====================================================================
    // Test 5: LFO -> Cymbal width -> RMS change
    //
    // Modulating cymbalWidth changes the stereo width of the cymbal.
    // The combined L+R RMS differs as the width gain alters per-channel
    // energy distribution.
    // =====================================================================
    if (!testPercussionModulation("cymbal_generator", "cymbalWidth", "Cymbal width")) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}