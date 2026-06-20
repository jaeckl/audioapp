/// LFO polarity E2E test suite.
///
/// LFO polarity constrains the modulation signal:
///   0 = bipolar  (-1 .. +1)  — full sweep both directions
///   1 = positive ( 0 .. +1)  — only opens from baseline
///   2 = negative (-1 ..  0)  — only closes from baseline
///
/// Tests cover:
///   1. Bipolar LFO on filterCutoff — wide spectral variation
///   2. Positive-only LFO — produces measurably different HF energy from bipolar
///   3. Negative-only LFO — produces measurably different HF energy from positive
///   4. Polarity persists in JSON round-trip
///
/// Each audio test creates its own isolated EngineHost / project.

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

// ---------- audio analysis helpers (inlined from modulation_e2e_test.cpp) ----------

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

/// Average HF energy across N equal windows of the sample buffer.
float averageHFPerWindow(const std::vector<float>& block, int numWindows) {
    const int windowFrames = static_cast<int>(block.size()) / numWindows;
    double total = 0.0;
    for (int w = 0; w < numWindows; ++w) {
        const int start = w * windowFrames;
        total += static_cast<double>(highFrequencyEnergy(block, start, windowFrames));
    }
    return static_cast<float>(total / static_cast<double>(numWindows));
}

/// Create a project with one track, a subtractive synth, and a sustained MIDI note.
struct PolarityTestSetup {
    audioapp::EngineHost host;
    std::string trackId;
    std::string synthId;
    std::string midiClipId;

    PolarityTestSetup() {
        host.createProject();
        trackId = host.addTrack("Test");
        host.selectTrack(trackId);
        synthId = host.addDeviceToTrack(trackId, "subtractive_synth");

        midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
        std::vector<audioapp::MidiNoteState> notes;
        notes.push_back({60, 0.0, 4.0, 100.0f});
        host.setMidiClipNotes(midiClipId, notes);
    }

    int createLfoWithPolarity(int polarity, float rate = 4.0f) {
        const int lfoId = host.createLfo(0); // 0 = LFO
        host.updateLfoParam(lfoId, "waveform", 0.0f);     // sine
        host.updateLfoParam(lfoId, "rate", rate);
        host.updateLfoParam(lfoId, "syncDivision", 0.0f); // free Hz
        host.updateLfoParam(lfoId, "polarity", static_cast<float>(polarity));
        return lfoId;
    }
};

} // namespace

int main() {
    using namespace audioapp;

    // =====================================================================
    // Test 1: Bipolar LFO (polarity=0) on filterCutoff — full sweep
    //
    // A bipolar LFO swings from -1 to +1. With amount 0.8, the filter
    // cutoff sweeps both above and below the baseline, producing wide
    // spectral variation across analysis windows.
    // =====================================================================
    {
        PolarityTestSetup setup;
        const int lfoId = setup.createLfoWithPolarity(0, 4.0f);
        if (!setup.host.assignModulation(lfoId, setup.synthId, "filterCutoff", 0.8f)) {
            return EXIT_FAILURE;
        }

        setup.host.setPlaying(true);
        const std::vector<float> block = setup.host.renderOffline(4.0, 48000.0);
        if (block.size() < 48000) return EXIT_FAILURE;
        if (rms(block, 1000, 4000) < 1.0e-4f) return EXIT_FAILURE;

        // Split into 8 half-beat windows. Bipolar modulation should
        // produce a wide spread of HF energy (filter opens AND closes).
        constexpr int kWindows = 8;
        const int windowFrames = static_cast<int>(block.size()) / kWindows;
        float brightest = 0.0f;
        float darkest = std::numeric_limits<float>::infinity();
        for (int w = 0; w < kWindows; ++w) {
            const int start = w * windowFrames;
            const float hf = highFrequencyEnergy(block, start, windowFrames);
            if (hf <= 0.0f) return EXIT_FAILURE;
            brightest = std::max(brightest, hf);
            darkest = std::min(darkest, hf);
        }
        if (darkest <= 0.0f) return EXIT_FAILURE;
        // Bipolar LFO sweeps both ways — expect > 1.5x ratio
        if (brightest < darkest * 1.5f) return EXIT_FAILURE;
    }

    // =====================================================================
    // Test 2: Positive-only LFO (polarity=1) produces different HF from bipolar
    //
    // Render with bipolar first, then change to positive-only with the
    // same LFO. The average HF energy should differ because positive-only
    // only opens the filter above baseline (no downward sweep).
    // =====================================================================
    {
        PolarityTestSetup setup;
        const int lfoId = setup.createLfoWithPolarity(0, 4.0f); // start bipolar
        if (!setup.host.assignModulation(lfoId, setup.synthId, "filterCutoff", 0.8f)) {
            return EXIT_FAILURE;
        }

        // Render with bipolar
        setup.host.setPlaying(true);
        const std::vector<float> bipolarBlock = setup.host.renderOffline(4.0, 48000.0);
        if (bipolarBlock.size() < 48000) return EXIT_FAILURE;
        if (rms(bipolarBlock, 1000, 4000) < 1.0e-4f) return EXIT_FAILURE;

        // Re-render with positive-only
        if (!setup.host.updateLfoParam(lfoId, "polarity", 1.0f)) {
            return EXIT_FAILURE;
        }
        const std::vector<float> positiveBlock = setup.host.renderOffline(4.0, 48000.0);
        if (positiveBlock.size() < 48000) return EXIT_FAILURE;
        if (rms(positiveBlock, 1000, 4000) < 1.0e-4f) return EXIT_FAILURE;

        // Compare average HF across windows
        constexpr int kWindows = 8;
        const float bipolarAvgHF = averageHFPerWindow(bipolarBlock, kWindows);
        const float positiveAvgHF = averageHFPerWindow(positiveBlock, kWindows);

        // Verifying the two polarity modes produce different average HF energy.
        // Positive-only only opens the filter, so its HF distribution differs.
        const float minHF = std::min(bipolarAvgHF, positiveAvgHF);
        const float maxHF = std::max(bipolarAvgHF, positiveAvgHF);
        if (minHF <= 0.0f) return EXIT_FAILURE;
        if (maxHF < minHF * 1.1f) return EXIT_FAILURE;
    }

    // =====================================================================
    // Test 3: Negative-only LFO (polarity=2) produces different HF from positive
    //
    // Render with positive first, then change to negative-only. The average
    // HF energy should differ because negative-only only closes the filter
    // below baseline (no upward sweep).
    // =====================================================================
    {
        PolarityTestSetup setup;
        const int lfoId = setup.createLfoWithPolarity(1, 4.0f); // start positive
        if (!setup.host.assignModulation(lfoId, setup.synthId, "filterCutoff", 0.8f)) {
            return EXIT_FAILURE;
        }

        // Render with positive
        setup.host.setPlaying(true);
        const std::vector<float> positiveBlock = setup.host.renderOffline(4.0, 48000.0);
        if (positiveBlock.size() < 48000) return EXIT_FAILURE;
        if (rms(positiveBlock, 1000, 4000) < 1.0e-4f) return EXIT_FAILURE;

        // Re-render with negative-only
        if (!setup.host.updateLfoParam(lfoId, "polarity", 2.0f)) {
            return EXIT_FAILURE;
        }
        const std::vector<float> negativeBlock = setup.host.renderOffline(4.0, 48000.0);
        if (negativeBlock.size() < 48000) return EXIT_FAILURE;
        if (rms(negativeBlock, 1000, 4000) < 1.0e-4f) return EXIT_FAILURE;

        // Compare average HF across windows
        constexpr int kWindows = 8;
        const float positiveAvgHF = averageHFPerWindow(positiveBlock, kWindows);
        const float negativeAvgHF = averageHFPerWindow(negativeBlock, kWindows);

        // The two polarity modes should produce different average HF energy.
        // Negative-only only closes the filter (darker on average).
        const float minHF = std::min(positiveAvgHF, negativeAvgHF);
        const float maxHF = std::max(positiveAvgHF, negativeAvgHF);
        if (minHF <= 0.0f) return EXIT_FAILURE;
        if (maxHF < minHF * 1.1f) return EXIT_FAILURE;
    }

    // =====================================================================
    // Test 4: Polarity persists in JSON round-trip
    //
    // Create an LFO, verify polarity=0 in JSON save. Change to polarity=1,
    // verify polarity=1. Change to polarity=2, verify polarity=2.
    // =====================================================================
    {
        audioapp::EngineHost host;
        host.createProject();
        const std::string trackId = host.addTrack("Test");
        host.selectTrack(trackId);
        host.addDeviceToTrack(trackId, "subtractive_synth");

        const int lfoId = host.createLfo(0);
        host.updateLfoParam(lfoId, "polarity", 0.0f); // bipolar

        // Round-trip 1: verify polarity=0
        {
            const std::string json = host.getProjectFileJson();
            audioapp::ProjectFileData parsed;
            if (!audioapp::parseProjectFileJson(json, parsed)) {
                return EXIT_FAILURE;
            }
            bool found = false;
            for (const auto& lfo : parsed.lfos) {
                if (lfo.id == lfoId) {
                    if (lfo.polarity != 0) return EXIT_FAILURE;
                    found = true;
                    break;
                }
            }
            if (!found) return EXIT_FAILURE;
        }

        // Change to positive-only
        if (!host.updateLfoParam(lfoId, "polarity", 1.0f)) {
            return EXIT_FAILURE;
        }

        // Round-trip 2: verify polarity=1
        {
            const std::string json = host.getProjectFileJson();
            audioapp::ProjectFileData parsed;
            if (!audioapp::parseProjectFileJson(json, parsed)) {
                return EXIT_FAILURE;
            }
            bool found = false;
            for (const auto& lfo : parsed.lfos) {
                if (lfo.id == lfoId) {
                    if (lfo.polarity != 1) return EXIT_FAILURE;
                    found = true;
                    break;
                }
            }
            if (!found) return EXIT_FAILURE;
        }

        // Change to negative-only
        if (!host.updateLfoParam(lfoId, "polarity", 2.0f)) {
            return EXIT_FAILURE;
        }

        // Round-trip 3: verify polarity=2
        {
            const std::string json = host.getProjectFileJson();
            audioapp::ProjectFileData parsed;
            if (!audioapp::parseProjectFileJson(json, parsed)) {
                return EXIT_FAILURE;
            }
            bool found = false;
            for (const auto& lfo : parsed.lfos) {
                if (lfo.id == lfoId) {
                    if (lfo.polarity != 2) return EXIT_FAILURE;
                    found = true;
                    break;
                }
            }
            if (!found) return EXIT_FAILURE;
        }
    }

    return EXIT_SUCCESS;
}