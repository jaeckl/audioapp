/// Regression test for the post-refactor subtractive LFO modulation bug.
///
/// Symptom (commit a8526c5): moving the manual filterCutoff knob on a
/// subtractive synth was audible, but an LFO assigned to filterCutoff on the
/// same device had no effect. Cause: the refactor routed modulation to a
/// per-track edge list with deviceIndex matching, and the per-frame LFO apply
/// inside mixSubtractiveMidiNotesBlock was never added — automation was
/// already applied per-frame there, but modulation was not.
///
/// This test renders 4 beats at 48k with a sine LFO at 4 Hz (well below the
/// Nyquist of the filter sweep range) sweeping filterCutoff. If modulation
/// is working, the high-frequency content of the render must vary
/// significantly over the render (the LFO cycles twice in 4 beats at 120 BPM
/// × 4 Hz, opening and closing the filter). A static cutoff would produce a
/// roughly constant brightness.
#include "audioapp/EngineHost.hpp"

#include <cmath>
#include <cstdlib>
#include <vector>

namespace {

float highFrequencyEnergy(const std::vector<float>& samples, int start, int count) {
    float energy = 0.0f;
    for (int i = start + 1; i < start + count && i < static_cast<int>(samples.size()); ++i) {
        const float diff = samples[static_cast<size_t>(i)] - samples[static_cast<size_t>(i - 1)];
        energy += diff * diff;
    }
    return energy;
}

float rms(const std::vector<float>& samples, int start, int count) {
    double acc = 0.0;
    const int end = std::min(start + count, static_cast<int>(samples.size()));
    for (int i = start; i < end; ++i) {
        acc += static_cast<double>(samples[static_cast<size_t>(i)]) *
               static_cast<double>(samples[static_cast<size_t>(i)]);
    }
    return end > start ? static_cast<float>(std::sqrt(acc / (end - start))) : 0.0f;
}

} // namespace

int main() {
    audioapp::EngineHost host;
    host.createProject();
    const std::string trackId = host.addTrack("LFO Sweep");
    host.selectTrack(trackId);
    const std::string synthId = host.addDeviceToTrack(trackId, "subtractive_synth");

    const std::string midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
    if (midiClipId.empty()) return EXIT_FAILURE;
    std::vector<audioapp::MidiNoteState> notes;
    notes.push_back({60, 0.0, 4.0, 100.0f});
    if (!host.setMidiClipNotes(midiClipId, notes)) return EXIT_FAILURE;

    // LFO @ 4 Hz sine, retrigger Sync, full bipolar amount. With 120 BPM
    // (= 2 beats per second), 4 Hz means ~2 cycles per beat → 8 cycles
    // across the 4-beat render.
    const int lfoId = host.createLfo(0);
    if (lfoId <= 0) return EXIT_FAILURE;
    if (!host.updateLfoParam(lfoId, "waveform", 0.0f)) return EXIT_FAILURE; // sine
    if (!host.updateLfoParam(lfoId, "rate", 4.0f)) return EXIT_FAILURE;
    if (!host.updateLfoParam(lfoId, "syncDivision", 0.0f)) return EXIT_FAILURE; // free-running Hz
    if (!host.assignModulation(lfoId, synthId, "filterCutoff", 1.0f)) return EXIT_FAILURE;

    host.setPlaying(true);
    const std::vector<float> block = host.renderOffline(4.0, 48000.0);
    if (block.size() < 48000) return EXIT_FAILURE;

    // Sanity: there must be audio. The note sustains the full clip.
    if (rms(block, 1000, 4000) < 1.0e-4f) return EXIT_FAILURE;

    // Split into 8 quarter-beat windows and measure HF energy in each.
    // With 8 LFO cycles across the render and 8 windows, the LFO is
    // guaranteed to open and close the filter in different windows. The
    // brightest window must be at least 2x the energy of the darkest.
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
    if (brightest < darkest * 2.0f) return EXIT_FAILURE;

    return EXIT_SUCCESS;
}
