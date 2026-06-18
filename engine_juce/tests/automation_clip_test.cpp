#include "audioapp/EngineHost.hpp"
#include "audioapp/ProjectJson.hpp"

#include <cmath>
#include <cstdlib>

namespace {

audioapp::ProjectFileData readProjectData(const audioapp::EngineHost& host) {
    audioapp::ProjectFileData data;
    if (!audioapp::parseProjectFileJson(host.getProjectFileJson(), data)) {
        return {};
    }
    return data;
}

} // namespace

int main() {
    audioapp::EngineHost host;
    host.createProject();
    const std::string trackId = host.addTrack("Test");
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

    std::vector<audioapp::AutomationPointState> points;
    points.push_back({0.0, 1.0f});
    points.push_back({2.0, 0.2f});
    points.push_back({4.0, 0.9f});
    if (!host.setAutomationPoints(clipId, points)) {
        return EXIT_FAILURE;
    }

    const auto parsed = readProjectData(host);
    if (parsed.tracks.empty() || parsed.tracks[0].automationClips.size() != 1) {
        return EXIT_FAILURE;
    }
    const auto& clip = parsed.tracks[0].automationClips[0];
    if (clip.deviceId != synthId || clip.paramId != "filterCutoff" || clip.points.size() != 3) {
        return EXIT_FAILURE;
    }

    const std::string json = host.getProjectFileJson();
    audioapp::EngineHost loaded;
    loaded.createProject();
    if (!loaded.loadProjectFileJson(json)) {
        return EXIT_FAILURE;
    }
    const auto reloaded = readProjectData(loaded);
    if (reloaded.tracks.empty() || reloaded.tracks[0].automationClips.empty()) {
        return EXIT_FAILURE;
    }

    host.setPlaying(true);
    const std::vector<float> block = host.renderOffline(4.0, 48000.0);
    if (block.empty()) {
        return EXIT_FAILURE;
    }

    float peak = 0.0f;
    for (float sample : block) {
        peak = std::max(peak, std::abs(sample));
    }
    if (peak < 1.0e-4f) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
