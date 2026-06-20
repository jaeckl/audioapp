/// Test: Gain/pan modulation + automation combine additively without conflict.
///
/// Tests verify that:
///   1. Automation-only on gain: smooth RMS ramp (early lower, late higher)
///   2. Modulation-only on gain: periodic RMS variation across windows
///   3. Combined mod+auto on gain: overall upward RMS trend WITH ripple
///   4. Combined mod+auto on pan: no crash, valid audio output
///
/// All tests use EngineHost::renderOffline to exercise the complete
/// control-thread -> audio-thread path for combined mod/auto on common params.

#include "audioapp/AutomationTypes.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/EngineHost.hpp"
#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/ProjectJson.hpp"
#include "audioapp/SubtractiveSynth.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <vector>

namespace {

// ---------- audio analysis helpers ----------

float rms(const std::vector<float>& samples, int start, int count) {
    double acc = 0.0;
    const int end = std::min(start + count, static_cast<int>(samples.size()));
    for (int i = start; i < end; ++i) {
        const double s = static_cast<double>(samples[static_cast<size_t>(i)]);
        acc += s * s;
    }
    return end > start ? static_cast<float>(std::sqrt(acc / static_cast<double>(end - start))) : 0.0f;
}

float peak(const std::vector<float>& samples, int start, int count) {
    float p = 0.0f;
    const int end = std::min(start + count, static_cast<int>(samples.size()));
    for (int i = start; i < end; ++i)
        p = std::max(p, std::abs(samples[static_cast<size_t>(i)]));
    return p;
}

/// Compute RMS for each of `numWindows` evenly-spaced windows in `samples`.
std::vector<float> windowRMS(const std::vector<float>& samples, int numWindows) {
    std::vector<float> result(static_cast<size_t>(numWindows), 0.0f);
    const int windowFrames = static_cast<int>(samples.size()) / numWindows;
    for (int w = 0; w < numWindows; ++w) {
        result[static_cast<size_t>(w)] = rms(samples, w * windowFrames, windowFrames);
    }
    return result;
}

} // namespace

int main() {
    using namespace audioapp;

    // =====================================================================
    // Test 1: Automation-only on gain — smooth RMS ramp
    //
    // Ramp gain from 0.0 -> 1.0 over 4 beats. With no other modulation,
    // the RMS envelope should follow the ramp monotonically: early windows
    // are quieter, later windows are louder.
    // =====================================================================
    {
        EngineHost host;
        host.createProject();
        const std::string trackId = host.addTrack("Test");
        host.selectTrack(trackId);
        const std::string synthId = host.addDeviceToTrack(trackId, "subtractive_synth");

        const std::string midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
        if (midiClipId.empty()) return EXIT_FAILURE;
        std::vector<MidiNoteState> notes;
        notes.push_back({60, 0.0, 4.0, 100.0f});
        if (!host.setMidiClipNotes(midiClipId, notes)) return EXIT_FAILURE;

        // Automation ramp 0.0 -> 1.0 over 4 beats
        const std::string autoClipId = host.createAutomationClip(trackId, 0.0, 4.0);
        if (autoClipId.empty()) return EXIT_FAILURE;
        if (!host.assignAutomationTarget(autoClipId, synthId, "gain")) return EXIT_FAILURE;
        std::vector<AutomationPointState> points;
        points.push_back({0.0, 0.0f});
        points.push_back({4.0, 1.0f});
        if (!host.setAutomationPoints(autoClipId, points)) return EXIT_FAILURE;

        host.setPlaying(true);
        const std::vector<float> block = host.renderOffline(4.0, 48000.0);
        if (block.size() < 48000) return EXIT_FAILURE;

        constexpr int kWindows = 8;
        const std::vector<float> rmsPerWindow = windowRMS(block, kWindows);

        // Gain ramps from 0.0 (silent) to 1.0. Window 0 should be much
        // quieter than window 4 (midpoint where gain ~0.5).
        if (rmsPerWindow[0] >= rmsPerWindow[4]) return EXIT_FAILURE;

        // Verify monotonic upward trend: at least 6 of 7 adjacent pairs
        // should show rising RMS (one flat/zero pair at the silent start
        // is tolerable).
        int risingPairs = 0;
        for (int w = 1; w < kWindows; ++w) {
            if (rmsPerWindow[w] > rmsPerWindow[w - 1])
                ++risingPairs;
        }
        if (risingPairs < kWindows - 2) return EXIT_FAILURE;
    }

    // =====================================================================
    // Test 2: Modulation-only on gain — periodic RMS variation
    //
    // Triangle LFO at 4 Hz, +/-0.3 amount on gain. Default gain is 1.0,
    // so the effective gain oscillates between 0.7 and 1.3. Adjacent
    // windows should have measurably different RMS.
    // =====================================================================
    {
        EngineHost host;
        host.createProject();
        const std::string trackId = host.addTrack("Test");
        host.selectTrack(trackId);
        const std::string synthId = host.addDeviceToTrack(trackId, "subtractive_synth");

        const std::string midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
        if (midiClipId.empty()) return EXIT_FAILURE;
        std::vector<MidiNoteState> notes;
        notes.push_back({60, 0.0, 4.0, 100.0f});
        if (!host.setMidiClipNotes(midiClipId, notes)) return EXIT_FAILURE;

        // Triangle LFO on gain, +/-0.3
        const int lfoId = host.createLfo(0);
        host.updateLfoParam(lfoId, "waveform", 1.0f);   // triangle
        host.updateLfoParam(lfoId, "rate", 4.0f);
        host.updateLfoParam(lfoId, "syncDivision", 0.0f); // free Hz
        if (!host.assignModulation(lfoId, synthId, "gain", 0.3f)) {
            return EXIT_FAILURE;
        }

        host.setPlaying(true);
        const std::vector<float> block = host.renderOffline(4.0, 48000.0);
        if (block.size() < 48000) return EXIT_FAILURE;
        if (rms(block, 1000, 4000) < 1.0e-4f) return EXIT_FAILURE;

        constexpr int kWindows = 8;
        const std::vector<float> rmsPerWindow = windowRMS(block, kWindows);

        // With a 4 Hz LFO and 8 windows over 4 beats (~2 sec at 120 BPM),
        // each window spans ~0.25s = 1 LFO cycle. Adjacent windows should
        // differ because the triangle wave moves continuously.
        int differingPairs = 0;
        for (int w = 1; w < kWindows; ++w) {
            const float a = rmsPerWindow[w - 1];
            const float b = rmsPerWindow[w];
            const float maxVal = std::max(a, b);
            if (maxVal > 1.0e-6f && std::abs(a - b) / maxVal > 0.05f)
                ++differingPairs;
        }
        if (differingPairs < 4) return EXIT_FAILURE;
    }

    // =====================================================================
    // Test 3: Combined mod+auto on gain — ramp + ripple
    //
    // Both automation ramp (0.0 -> 1.0) and triangle LFO (4 Hz, +/-0.3)
    // on the same gain parameter. The result should show BOTH:
    //   - Overall upward RMS trend (from automation)
    //   - Periodic ripple (from LFO)
    // =====================================================================
    {
        EngineHost host;
        host.createProject();
        const std::string trackId = host.addTrack("Test");
        host.selectTrack(trackId);
        const std::string synthId = host.addDeviceToTrack(trackId, "subtractive_synth");

        const std::string midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
        if (midiClipId.empty()) return EXIT_FAILURE;
        std::vector<MidiNoteState> notes;
        notes.push_back({60, 0.0, 4.0, 100.0f});
        if (!host.setMidiClipNotes(midiClipId, notes)) return EXIT_FAILURE;

        // Automation ramp 0.0 -> 1.0 over 4 beats
        const std::string autoClipId = host.createAutomationClip(trackId, 0.0, 4.0);
        if (autoClipId.empty()) return EXIT_FAILURE;
        if (!host.assignAutomationTarget(autoClipId, synthId, "gain")) return EXIT_FAILURE;
        std::vector<AutomationPointState> points;
        points.push_back({0.0, 0.0f});
        points.push_back({4.0, 1.0f});
        if (!host.setAutomationPoints(autoClipId, points)) return EXIT_FAILURE;

        // Triangle LFO on gain, +/-0.3
        const int lfoId = host.createLfo(0);
        host.updateLfoParam(lfoId, "waveform", 1.0f);   // triangle
        host.updateLfoParam(lfoId, "rate", 4.0f);
        host.updateLfoParam(lfoId, "syncDivision", 0.0f); // free Hz
        if (!host.assignModulation(lfoId, synthId, "gain", 0.3f)) {
            return EXIT_FAILURE;
        }

        host.setPlaying(true);
        const std::vector<float> block = host.renderOffline(4.0, 48000.0);
        if (block.size() < 48000) return EXIT_FAILURE;

        constexpr int kWindows = 8;
        const std::vector<float> rmsPerWindow = windowRMS(block, kWindows);

        // A) Upward trend: window 0 should be quieter than window 4
        if (rmsPerWindow[0] >= rmsPerWindow[4]) return EXIT_FAILURE;

        // B) Ripple: at least 3 adjacent pairs should differ by > 5%
        int differingPairs = 0;
        for (int w = 1; w < kWindows; ++w) {
            const float a = rmsPerWindow[w - 1];
            const float b = rmsPerWindow[w];
            const float maxVal = std::max(a, b);
            if (maxVal > 1.0e-6f && std::abs(a - b) / maxVal > 0.05f)
                ++differingPairs;
        }
        if (differingPairs < 3) return EXIT_FAILURE;

        // C) No double-apply: the combined gain (auto + mod) should not
        // cause clipping or unexpected silence. Peak in the later windows
        // (where gain is highest) should stay within reasonable bounds.
        constexpr int kPeakCheckWindows = 2;
        const int peakWindowFrames = static_cast<int>(block.size()) / kWindows;
        const float peakLevel = peak(block, peakWindowFrames * (kWindows - kPeakCheckWindows),
                                     peakWindowFrames * kPeakCheckWindows);
        if (peakLevel > 2.0f) return EXIT_FAILURE;
    }

    // =====================================================================
    // Test 4: Combined mod+auto on pan — no crash, valid output
    //
    // Pan automation + LFO modulation on the same pan parameter.
    // Since renderOffline produces mono output, pan changes don't
    // affect mono amplitude measurably. This test verifies the engine
    // doesn't crash or produce invalid output under combined pan mod+auto.
    // =====================================================================
    {
        EngineHost host;
        host.createProject();
        const std::string trackId = host.addTrack("Test");
        host.selectTrack(trackId);
        const std::string synthId = host.addDeviceToTrack(trackId, "subtractive_synth");

        const std::string midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
        if (midiClipId.empty()) return EXIT_FAILURE;
        std::vector<MidiNoteState> notes;
        notes.push_back({60, 0.0, 4.0, 100.0f});
        if (!host.setMidiClipNotes(midiClipId, notes)) return EXIT_FAILURE;

        // Pan automation: sweep -1.0 -> 1.0 (left -> right)
        const std::string autoClipId = host.createAutomationClip(trackId, 0.0, 4.0);
        if (autoClipId.empty()) return EXIT_FAILURE;
        if (!host.assignAutomationTarget(autoClipId, synthId, "pan")) return EXIT_FAILURE;
        std::vector<AutomationPointState> points;
        points.push_back({0.0, -1.0f});
        points.push_back({4.0, 1.0f});
        if (!host.setAutomationPoints(autoClipId, points)) return EXIT_FAILURE;

        // Triangle LFO on pan, +/-0.3
        const int lfoId = host.createLfo(0);
        host.updateLfoParam(lfoId, "waveform", 1.0f);   // triangle
        host.updateLfoParam(lfoId, "rate", 4.0f);
        host.updateLfoParam(lfoId, "syncDivision", 0.0f); // free Hz
        if (!host.assignModulation(lfoId, synthId, "pan", 0.3f)) {
            return EXIT_FAILURE;
        }

        host.setPlaying(true);
        const std::vector<float> block = host.renderOffline(4.0, 48000.0);
        if (block.size() < 48000) return EXIT_FAILURE;

        // Verify audio is produced
        if (rms(block, 1000, 4000) < 1.0e-4f) return EXIT_FAILURE;

        // Verify peak doesn't clip
        if (peak(block, 0, static_cast<int>(block.size())) > 2.0f) {
            return EXIT_FAILURE;
        }
    }

    return EXIT_SUCCESS;
}