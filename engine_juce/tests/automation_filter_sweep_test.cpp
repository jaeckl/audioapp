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

} // namespace

int main() {
    audioapp::EngineHost host;
    host.createProject();
    const std::string trackId = host.addTrack("Filter");
    host.selectTrack(trackId);
    const std::string synthId = host.addDeviceToTrack(trackId, "subtractive_synth");

    const std::string midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
    if (midiClipId.empty()) {
        return EXIT_FAILURE;
    }
    std::vector<audioapp::MidiNoteState> notes;
    notes.push_back({60, 0.0, 4.0, 100.0f});
    if (!host.setMidiClipNotes(midiClipId, notes)) {
        return EXIT_FAILURE;
    }

    const std::string clipId = host.createAutomationClip(trackId, 0.0, 4.0);
    if (clipId.empty()) {
        return EXIT_FAILURE;
    }
    if (!host.assignAutomationTarget(clipId, synthId, "filterCutoff")) {
        return EXIT_FAILURE;
    }

    // Open filter at start, nearly closed at end — audible brightness drop.
    std::vector<audioapp::AutomationPointState> points;
    points.push_back({0.0, 1.0f});
    points.push_back({4.0, 0.05f});
    if (!host.setAutomationPoints(clipId, points)) {
        return EXIT_FAILURE;
    }

    host.setPlaying(true);
    const std::vector<float> block = host.renderOffline(4.0, 48000.0);
    if (block.size() < 48000) {
        return EXIT_FAILURE;
    }

    const int window = 12000;
    const float earlyHf = highFrequencyEnergy(block, 4800, window);
    const float lateHf = highFrequencyEnergy(block, 120000, window);
    if (earlyHf <= 1.0e-8f || lateHf <= 1.0e-8f) {
        return EXIT_FAILURE;
    }
    if (earlyHf <= lateHf * 1.5f) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
