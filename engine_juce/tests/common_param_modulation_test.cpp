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
#include <limits>
#include <vector>

namespace {

// ---------- audio analysis helpers (same as modulation_e2e_test.cpp) ----------

float rms(const std::vector<float>& samples, int start, int count) {
    double acc = 0.0;
    const int end = std::min(start + count, static_cast<int>(samples.size()));
    for (int i = start; i < end; ++i) {
        acc += static_cast<double>(samples[static_cast<size_t>(i)]) *
               static_cast<double>(samples[static_cast<size_t>(i)]);
    }
    return end > start ? static_cast<float>(std::sqrt(acc / (end - start))) : 0.0f;
}

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

/// Compute max/min RMS ratio across N equal windows of a block.
float rmsVariationRatio(const std::vector<float>& block, int numWindows) {
    if (block.empty() || numWindows < 2) return 1.0f;
    const int windowFrames = static_cast<int>(block.size()) / numWindows;
    float maxRms = 0.0f;
    float minRms = std::numeric_limits<float>::infinity();
    for (int w = 0; w < numWindows; ++w) {
        const int start = w * windowFrames;
        const float r = rms(block, start, windowFrames);
        if (r <= 0.0f) continue;
        maxRms = std::max(maxRms, r);
        minRms = std::min(minRms, r);
    }
    return (minRms > 0.0f) ? (maxRms / minRms) : 1.0f;
}

} // namespace

int main() {
    using namespace audioapp;

    // =====================================================================
    // Test 1: LFO → gain → amplitude modulation (RMS variation across windows)
    //
    // Create a SubtractiveSynth with sustained MIDI note, add a triangle LFO
    // modulating "gain" at 0.8 amount. Render 4 beats. The output amplitude
    // should vary with the LFO frequency, producing different RMS levels in
    // consecutive windows.
    // =====================================================================
    {
        TestSetup setup;
        const int lfoId = setup.createLfo(1, 4.0f, 0); // triangle @ 4 Hz, free
        if (!setup.host.assignModulation(lfoId, setup.synthId, "gain", 0.8f)) {
            return EXIT_FAILURE;
        }

        setup.host.setPlaying(true);
        const std::vector<float> block = setup.host.renderOffline(4.0, 48000.0);
        if (block.size() < 48000) return EXIT_FAILURE;

        // Verify audio is produced
        const float overallRms = rms(block, 1000, 4000);
        if (overallRms < 1.0e-4f) return EXIT_FAILURE;

        // With a 4 Hz triangle LFO at 0.8 bipolar amount modulating gain
        // (default 1.0), gain varies from ~0.2 to ~1.0. This should produce
        // clear RMS variation across 8 half-beat windows.
        constexpr int kWindows = 8;
        const float ratio = rmsVariationRatio(block, kWindows);
        // The LFO cycles 16 times in 4 seconds. Multiple windows must
        // have significantly different RMS levels.
        if (ratio < 1.5f) return EXIT_FAILURE;
    }

    // =====================================================================
    // Test 2: LFO → pan → RMS variation differs from unmodulated case
    //
    // Pan modulation affects the mono sum because the stereo mix uses
    // cos(angle)+sin(angle) as a per-frame factor, which varies from 1.0
    // to ~1.414 as pan sweeps between extremes. Verify that a pan-modulated
    // render shows different (higher) RMS window-to-window variation than
    // an otherwise identical unmodulated render.
    // =====================================================================
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
        if (!setupPan.host.assignModulation(lfoPan, setupPan.synthId, "pan", 0.8f)) {
            return EXIT_FAILURE;
        }
        setupPan.host.setPlaying(true);
        const std::vector<float> panModBlock = setupPan.host.renderOffline(4.0, 48000.0);

        if (unmodBlock.size() < 48000) return EXIT_FAILURE;
        if (panModBlock.size() < 48000) return EXIT_FAILURE;
        if (rms(unmodBlock, 1000, 4000) < 1.0e-4f) return EXIT_FAILURE;
        if (rms(panModBlock, 1000, 4000) < 1.0e-4f) return EXIT_FAILURE;

        constexpr int kWindows = 8;

        // Compute RMS variation for unmodulated block
        const float unmodRatio = rmsVariationRatio(unmodBlock, kWindows);

        // Compute RMS variation for pan-modulated block
        const float panRatio = rmsVariationRatio(panModBlock, kWindows);

        // The pan-modulated block should have more RMS variation than the
        // unmodulated block. The unmodulated block has some variation from
        // the amp attack transient, but pan modulation adds additional
        // variation from the cos+sin factor sweeping between 1.0 and ~1.414.
        if (panRatio < unmodRatio * 1.15f) return EXIT_FAILURE;
    }

    // =====================================================================
    // Test 3: Two LFOs modulating gain + pan simultaneously
    //
    // Two independent LFOs modulate gain and pan. The combined effect
    // should produce even more RMS variation than either alone, and the
    // pattern should differ from single-parameter modulation.
    // =====================================================================
    {
        TestSetup setup;
        // LFO 1: triangle, 4 Hz, modulating gain at 0.8
        const int lfoGain = setup.createLfo(1, 4.0f, 0);
        if (!setup.host.assignModulation(lfoGain, setup.synthId, "gain", 0.8f)) {
            return EXIT_FAILURE;
        }
        // LFO 2: sine, 7 Hz, modulating pan at 0.6
        const int lfoPan = setup.host.createLfo(0); // 0 = LFO
        setup.host.updateLfoParam(lfoPan, "waveform", 0.0f); // sine
        setup.host.updateLfoParam(lfoPan, "rate", 7.0f);
        setup.host.updateLfoParam(lfoPan, "syncDivision", 0.0f);
        if (!setup.host.assignModulation(lfoPan, setup.synthId, "pan", 0.6f)) {
            return EXIT_FAILURE;
        }

        setup.host.setPlaying(true);
        const std::vector<float> block = setup.host.renderOffline(4.0, 48000.0);
        if (block.size() < 48000) return EXIT_FAILURE;

        const float overallRms = rms(block, 1000, 4000);
        if (overallRms < 1.0e-4f) return EXIT_FAILURE;

        constexpr int kWindows = 8;
        const float ratio = rmsVariationRatio(block, kWindows);

        // Both LFOs together should produce clear RMS variation.
        // The gain LFO alone already produces >1.5x ratio; with pan
        // adding additional amplitude modulation, the ratio should
        // still be clearly detectable.
        if (ratio < 1.5f) return EXIT_FAILURE;

        // Verify the combined modulation produces RMS values that are
        // not trivially correlated with a single LFO: the per-window
        // RMS values should be spread such that at least 3 distinct
        // windows have RMS > 10% above the minimum (demonstrating
        // complex modulation interaction rather than a simple on/off).
        const int windowFrames = static_cast<int>(block.size()) / kWindows;
        float minRms = std::numeric_limits<float>::infinity();
        for (int w = 0; w < kWindows; ++w) {
            const int start = w * windowFrames;
            minRms = std::min(minRms, rms(block, start, windowFrames));
        }
        if (minRms <= 0.0f) return EXIT_FAILURE;
        int aboveCount = 0;
        for (int w = 0; w < kWindows; ++w) {
            const int start = w * windowFrames;
            if (rms(block, start, windowFrames) > minRms * 1.1f) {
                ++aboveCount;
            }
        }
        // At least 3 windows should be clearly above the quietest window
        if (aboveCount < 3) return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}