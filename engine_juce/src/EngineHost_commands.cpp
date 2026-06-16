#include "audioapp/EngineHost.hpp"
#include "audioapp/ProjectJson.hpp"
#include "audioapp/ProjectArchive.hpp"

namespace audioapp {

void EngineHost::createProject() {
    project_.createProject();
}

std::string EngineHost::addTrack(const std::string& name) {
    return project_.addTrack(name);
}

bool EngineHost::selectTrack(const std::string& trackId) {
    return project_.selectTrack(trackId);
}

std::string EngineHost::addDeviceToTrack(const std::string& trackId, const std::string& deviceType) {
    return project_.addDeviceToTrack(trackId, deviceType);
}

bool EngineHost::setDeviceParameter(const std::string& deviceId,
                                    const std::string& parameterId,
                                    float value) {
    return project_.setDeviceParameter(deviceId, parameterId, value);
}

std::string EngineHost::getProjectSnapshotJson() const {
    return snapshotToJson(project_.snapshot());
}

float EngineHost::activeOscillatorFrequencyHz() const {
    return project_.activeOscillatorFrequencyHz();
}

std::string EngineHost::createMidiClip(const std::string& trackId, double startBeat, double lengthBeats) {
    return project_.createMidiClip(trackId, startBeat, lengthBeats);
}

bool EngineHost::setMidiClipNotes(const std::string& clipId, const std::vector<MidiNoteState>& notes) {
    return project_.setMidiClipNotes(clipId, notes);
}

bool EngineHost::saveProject(const std::string& archivePath) {
    return saveProjectToArchive(project_, archivePath);
}

bool EngineHost::loadProject(const std::string& archivePath) {
    return loadProjectFromArchive(project_, archivePath);
}

std::string EngineHost::getProjectFileJson() const {
    return projectFileToJson(project_.toProjectFileData());
}

bool EngineHost::loadProjectFileJson(const std::string& json) {
    ProjectFileData data;
    if (!parseProjectFileJson(json, data)) {
        return false;
    }
    return project_.loadFromProjectFileData(data);
}

void EngineHost::advancePlayheadForBlock(int numFrames, double sampleRate) noexcept {
    project_.advancePlayhead(numFrames, sampleRate);
}

} // namespace audioapp
