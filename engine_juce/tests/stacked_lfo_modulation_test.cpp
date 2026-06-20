/// Test suite for stacked LFO modulation.
///
/// Tests cover:
///   1. Two LFOs on different params (filterCutoff + filterQ) produce complex
///      spectral variation beyond the single-LFO case.
///   2. Two LFOs on the SAME param (both filterCutoff) — verify additive
///      amounts produce stronger modulation than a single LFO alone.
///   3. Removing one LFO from a stacked modulation setup reduces spectral
///      variation.
///
/// All tests use EngineHost::renderOffline to exercise the complete
/// control-thread -> audio-thread path.

#include "audioapp/EngineHost.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <limits>
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
    return end > start ? static_cast<float>(std::sqrt(acc / (end - start))) : 0.0f;
}

float highFrequencyEnergy(const std::vector<float>& samples, int start, int count) {
    float energy = 0.0f;
    const int end = std::min(start + count, static_cast<int>(samples.size()));
    for (int i = start + 1; i < end; ++i) {
        const float diff = samples[static_cast<size_t>(i)] - samples[static_cast<size_t>(i - 1)];
        energy += diff * diff;
    }
    return energy;
}

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

    std::vector<float> render() {
        host.setPlaying(true);
        return host.renderOffline(4.0, 48000.0);
    }
};

/// Compute max/min HF energy ratio across N windows.
float hfEnergyVariation(const std::vector<float>& samples, int numWindows) {
    const int windowFrames = static_cast<int>(samples.size()) / numWindows;
    float brightest = 0.0f;
    float darkest = std::numeric_limits<float>::infinity();
    for (int w = 0; w < numWindows; ++w) {
        const int start = w * windowFrames;
        const float hf = highFrequencyEnergy(samples, start, windowFrames);
        if (hf <= 0.0f) return 1.0f;
        brightest = std::max(brightest, hf);
        darkest = std::min(darkest, hf);
    }
    if (darkest <= 0.0f) return 1.0f;
    return brightest / darkest;
}

} // namespace

int main() {
    // =====================================================================
    // Test 1: Two LFOs on different params produce audible stacked modulation
    //
    // LFO-1 (sine, 3 Hz) modulates filterCutoff at 0.8 amount.
    // LFO-2 (square, 7 Hz) modulates filterQ at 0.5 amount.
    // =====================================================================
    {
        TestSetup setup;

        const int lfo1 = setup.createLfo(0, 3.0f, 0); // sine @ 3 Hz
        if (!setup.host.assignModulation(lfo1, setup.synthId, "filterCutoff", 0.8f)) {
            return EXIT_FAILURE;
        }

        const int lfo2 = setup.createLfo(3, 7.0f, 0); // square @ 7 Hz
        if (!setup.host.assignModulation(lfo2, setup.synthId, "filterQ", 0.5f)) {
            return EXIT_FAILURE;
        }

        const std::vector<float> block = setup.render();
        if (block.size() < 48000) return EXIT_FAILURE;
        if (rms(block, 1000, 4000) < 1.0e-4f) return EXIT_FAILURE;

        // With two LFOs sweeping different filter params, the stacked
        // modulation should produce strong spectral variation.
        constexpr int kWindows = 8;
        const float variation = hfEnergyVariation(block, kWindows);
        if (variation < 2.0f) return EXIT_FAILURE;
    }

    // =====================================================================
    // Test 2: Two LFOs on the same param — verify additive amounts
    //
    // Both LFOs modulate filterCutoff with different rates and amounts.
    // The stacked (additive) modulation should produce stronger spectral
    // variation than a single LFO alone.
    // =====================================================================
    {
        TestSetup setup;

        // LFO-1 (sine, 2 Hz) at 0.5 amount on filterCutoff
        const int lfo1 = setup.createLfo(0, 2.0f, 0);
        if (!setup.host.assignModulation(lfo1, setup.synthId, "filterCutoff", 0.5f)) {
            return EXIT_FAILURE;
        }

        // LFO-2 (sine, 5 Hz) at 0.3 amount on same filterCutoff
        const int lfo2 = setup.createLfo(0, 5.0f, 0);
        if (!setup.host.assignModulation(lfo2, setup.synthId, "filterCutoff", 0.3f)) {
            return EXIT_FAILURE;
        }

        const std::vector<float> stackedBlock = setup.render();
        if (stackedBlock.size() < 48000) return EXIT_FAILURE;
        if (rms(stackedBlock, 1000, 4000) < 1.0e-4f) return EXIT_FAILURE;

        constexpr int kWindows = 8;
        const float stackedVariation = hfEnergyVariation(stackedBlock, kWindows);
        if (stackedVariation < 2.0f) return EXIT_FAILURE;

        // Remove LFO-2's modulation on filterCutoff, keeping only LFO-1.
        if (!setup.host.removeModulation(lfo2, "filterCutoff")) {
            return EXIT_FAILURE;
        }

        const std::vector<float> singleBlock = setup.render();
        if (rms(singleBlock, 1000, 4000) < 1.0e-4f) return EXIT_FAILURE;

        const float singleVariation = hfEnergyVariation(singleBlock, kWindows);

        // The stacked (two-LFO) variation must exceed the single-LFO variation.
        // Two LFOs on the same param with additive amounts (0.5 + 0.3 = 0.8
        // total depth) should sweep the filter harder than 0.5 alone.
        if (singleVariation >= stackedVariation) {
            return EXIT_FAILURE;
        }
    }

    // =====================================================================
    // Test 3: Remove one LFO — verify spectral variation decreases
    //
    // Set up two LFOs on different params (filterCutoff + filterQ), render
    // with both, then remove filterQ modulation and verify the spectral
    // variation drops compared to the stacked case.
    // =====================================================================
    {
        TestSetup setup;

        const int lfo1 = setup.createLfo(0, 3.0f, 0); // sine @ 3 Hz
        if (!setup.host.assignModulation(lfo1, setup.synthId, "filterCutoff", 0.8f)) {
            return EXIT_FAILURE;
        }

        const int lfo2 = setup.createLfo(3, 7.0f, 0); // square @ 7 Hz
        if (!setup.host.assignModulation(lfo2, setup.synthId, "filterQ", 0.5f)) {
            return EXIT_FAILURE;
        }

        const std::vector<float> bothBlock = setup.render();
        if (bothBlock.size() < 48000) return EXIT_FAILURE;
        if (rms(bothBlock, 1000, 4000) < 1.0e-4f) return EXIT_FAILURE;

        constexpr int kWindows = 8;
        const float bothVariation = hfEnergyVariation(bothBlock, kWindows);
        if (bothVariation < 2.0f) return EXIT_FAILURE;

        // Remove LFO-2's filterQ modulation, keeping LFO-1 on filterCutoff.
        if (!setup.host.removeModulation(lfo2, "filterQ")) {
            return EXIT_FAILURE;
        }

        const std::vector<float> oneBlock = setup.render();
        if (rms(oneBlock, 1000, 4000) < 1.0e-4f) return EXIT_FAILURE;

        const float oneVariation = hfEnergyVariation(oneBlock, kWindows);

        // Removing one LFO should reduce spectral variation: two modulators
        // on different params produce richer variation than one alone.
        if (oneVariation >= bothVariation) {
            return EXIT_FAILURE;
        }
    }

    return EXIT_SUCCESS;
}