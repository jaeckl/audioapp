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
    const std::string trackId = host.addTrack("Sampler");
    host.selectTrack(trackId);
    const std::string samplerId = host.addDeviceToTrack(trackId, "simple_sampler");
    if (samplerId.empty()) {
        return EXIT_FAILURE;
    }
    if (!host.setDeviceStringParameter(samplerId, "sampleId", "sample_kick")) {
        return EXIT_FAILURE;
    }
    // Isolate automation — no per-note filter envelope modulation.
    if (!host.setDeviceParameter(samplerId, "filterEnvAmount", 0.0f)) {
        return EXIT_FAILURE;
    }

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
    if (!host.assignAutomationTarget(clipId, samplerId, "filterCutoff")) {
        return EXIT_FAILURE;
    }

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

    float peak = 0.0f;
    for (float sample : block) {
        peak = std::max(peak, std::abs(sample));
    }
    if (peak < 1.0e-4f) {
        return EXIT_FAILURE;
    }

    const int window = std::min(12000, static_cast<int>(block.size()) / 4);
    const int earlyStart = static_cast<int>(block.size()) / 20;
    const int lateStart = static_cast<int>(block.size() * 3) / 4;
    const float earlyHf = highFrequencyEnergy(block, earlyStart, window);
    const float lateHf = highFrequencyEnergy(block, lateStart, window);
    if (earlyHf <= 1.0e-8f || lateHf <= 1.0e-8f) {
        return EXIT_FAILURE;
    }
    if (earlyHf <= lateHf * 1.5f) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
