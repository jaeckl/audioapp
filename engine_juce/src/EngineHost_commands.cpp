#include "audioapp/EngineHost.hpp"
#include "audioapp/ProjectJson.hpp"
#include "audioapp/ProjectArchive.hpp"

#include <memory>
#include <unordered_map>

namespace audioapp {

void EngineHost::ensureSampleBankReady() {
    sampleBank_.registerBundledDefaults();
    project_->setSampleBank(&sampleBank_);
}

void EngineHost::createProject() {
    ensureSampleBankReady();
    project_->createProject();
}

std::string EngineHost::addTrack(const std::string& name) {
    return project_->addTrack(name);
}

bool EngineHost::selectTrack(const std::string& trackId) {
    return project_->selectTrack(trackId);
}

std::string EngineHost::addDeviceToTrack(const std::string& trackId,
                                         const std::string& deviceType,
                                         int insertIndex) {
    return project_->addDeviceToTrack(trackId, deviceType, insertIndex);
}

bool EngineHost::removeDeviceFromTrack(const std::string& deviceId) {
    return project_->removeDeviceFromTrack(deviceId);
}

bool EngineHost::setDeviceParameter(const std::string& deviceId,
                                    const std::string& parameterId,
                                    float value) {
    return project_->setDeviceParameter(deviceId, parameterId, value);
}

bool EngineHost::setDeviceStringParameter(const std::string& deviceId,
                                          const std::string& parameterId,
                                          const std::string& value) {
    return project_->setDeviceStringParameter(deviceId, parameterId, value);
}

bool EngineHost::setMasterGain(float gain) {
    return project_->setMasterGain(gain);
}

std::string EngineHost::getProjectSnapshotJson() const {
    return snapshotToJson(project_->snapshot(), project_->deviceRegistry());
}

std::string EngineHost::getDeviceStatesJson(const std::vector<std::string>& deviceIds) const {
    auto snap = project_->snapshot();
    auto* obj = new juce::DynamicObject();
    auto* devicesObj = new juce::DynamicObject();

    // Build device map: deviceId → (DeviceSlot*, TrackState*)
    std::unordered_map<std::string, std::pair<const DeviceSlot*, const TrackState*>> deviceMap;
    for (const auto& track : snap.tracks) {
        for (const auto& device : track.devices) {
            deviceMap[device.id] = {&device, &track};
        }
    }

    for (const auto& deviceId : deviceIds) {
        auto it = deviceMap.find(deviceId);
        if (it == deviceMap.end()) continue;
        const auto& [slot, track] = it->second;

        // Serialize via registry dispatch (no round-trip)
        juce::var deviceVar = audioapp::deviceToVar(*slot, project_->deviceRegistry());

        // Inject meters from this track's deviceMeters
        for (const auto& meter : track->deviceMeters) {
            if (meter.deviceId == deviceId) {
                if (auto* devObj = deviceVar.getDynamicObject()) {
                    auto* metersObj = new juce::DynamicObject();
                    metersObj->setProperty("gainReductionDb",
                        static_cast<double>(meter.gainReductionDb));
                    metersObj->setProperty("inputLevel",
                        static_cast<double>(meter.inputLevel));
                    devObj->setProperty("meters", juce::var(metersObj));
                }
                break;
            }
        }
        devicesObj->setProperty(juce::String::fromUTF8(deviceId.c_str()), deviceVar);
    }

    obj->setProperty("ok", true);
    obj->setProperty("devices", juce::var(devicesObj));
    return juce::JSON::toString(juce::var(obj), false).toStdString();
}

std::string EngineHost::getTransportStateJson() const {
    return buildBridgeOkTransportState(project_->transportState());
}

float EngineHost::activeOscillatorFrequencyHz() const {
    return project_->activeOscillatorFrequencyHz();
}

double EngineHost::playheadBeats() const noexcept {
    return project_->playheadBeats();
}

void EngineHost::setPlayheadBeats(double beats) noexcept {
    project_->setPlayheadBeats(beats);
}

void EngineHost::readMasterMix(float* monoOut,
                               int numFrames,
                               double sampleRate,
                               double playheadStartBeat) noexcept {
    project_->readMasterMix(monoOut, numFrames, sampleRate, playheadStartBeat);
}

void EngineHost::readMasterMixStereo(float* leftOut,
                                     float* rightOut,
                                     int numFrames,
                                     double sampleRate,
                                     double playheadStartBeat) noexcept {
    project_->readMasterMixStereo(leftOut, rightOut, numFrames, sampleRate, playheadStartBeat);
}

void EngineHost::readPreviewMix(float* monoOut, int numFrames, double sampleRate) noexcept {
    if (monoOut == nullptr || numFrames <= 0 || !previewVoice_.active.load(std::memory_order_acquire)) {
        return;
    }

    const float* pcm = previewVoice_.pcmData;
    const int pcmSize = previewVoice_.pcmSize;
    if (pcm == nullptr || pcmSize <= 0) {
        previewVoice_.active.store(false, std::memory_order_release);
        return;
    }

    int position = previewVoice_.position.load(std::memory_order_relaxed);
    for (int frame = 0; frame < numFrames; ++frame) {
        if (position >= pcmSize) {
            previewVoice_.active.store(false, std::memory_order_release);
            for (int rest = frame; rest < numFrames; ++rest) {
                monoOut[rest] = 0.0f;
            }
            previewVoice_.position.store(position, std::memory_order_release);
            return;
        }
        monoOut[frame] += pcm[static_cast<size_t>(position++)];
    }
    previewVoice_.position.store(position, std::memory_order_release);
}

void EngineHost::readLiveMix(float* monoOut, int numFrames, double sampleRate) noexcept {
    project_->readLiveMix(monoOut, numFrames, sampleRate);
}

std::string EngineHost::createMidiClip(const std::string& trackId, double startBeat, double lengthBeats) {
    return project_->createMidiClip(trackId, startBeat, lengthBeats);
}

bool EngineHost::setMidiClipNotes(const std::string& clipId, const std::vector<MidiNoteState>& notes) {
    return project_->setMidiClipNotes(clipId, notes);
}

std::string EngineHost::createSampleClip(const std::string& trackId,
                                         const std::string& sampleId,
                                         double startBeat,
                                         double lengthBeats) {
    ensureSampleBankReady();
    return project_->createSampleClip(trackId, sampleId, startBeat, lengthBeats);
}

bool EngineHost::moveClip(const std::string& clipId,
                          const std::string& targetTrackId,
                          double startBeat) {
    return project_->moveClip(clipId, targetTrackId, startBeat);
}

bool EngineHost::setClipLength(const std::string& clipId, double lengthBeats) {
    return project_->setClipLength(clipId, lengthBeats);
}

std::string EngineHost::createAutomationClip(const std::string& trackId,
                                             double startBeat,
                                             double lengthBeats) {
    return project_->createAutomationClip(trackId, startBeat, lengthBeats);
}

bool EngineHost::assignAutomationTarget(const std::string& clipId,
                                          const std::string& deviceId,
                                          const std::string& paramId) {
    return project_->assignAutomationTarget(clipId, deviceId, paramId);
}

bool EngineHost::setAutomationPoints(const std::string& clipId,
                                     const std::vector<AutomationPointState>& points) {
    return project_->setAutomationPoints(clipId, points);
}

bool EngineHost::setBpm(int bpm) {
    return project_->setBpm(bpm);
}

bool EngineHost::deleteTrack(const std::string& trackId) {
    return project_->deleteTrack(trackId);
}

bool EngineHost::deleteClip(const std::string& clipId) {
    return project_->deleteClip(clipId);
}

bool EngineHost::duplicateClip(const std::string& clipId) {
    return project_->duplicateClip(clipId);
}

bool EngineHost::setLoopEnabled(bool enabled) {
    return project_->setLoopEnabled(enabled);
}

bool EngineHost::setLoopLengthBeats(double lengthBeats) {
    return project_->setLoopLengthBeats(lengthBeats);
}

bool EngineHost::setLoopRegion(double startBeat, double endBeat) {
    return project_->setLoopRegion(startBeat, endBeat);
}

bool EngineHost::setRecordArmed(bool armed) {
    return project_->setRecordArmed(armed);
}

int EngineHost::createLfo(int modulatorType) {
    return project_->createLfo(modulatorType);
}

bool EngineHost::removeLfo(int lfoId) {
    return project_->removeLfo(lfoId);
}

bool EngineHost::updateLfoParam(int lfoId, const std::string& param, float value) {
    return project_->updateLfoParam(lfoId, param, value);
}

bool EngineHost::assignModulation(int lfoId, const std::string& deviceId, const std::string& paramId, float amount) {
    return project_->assignModulation(lfoId, deviceId, paramId, amount);
}

bool EngineHost::removeModulation(int lfoId, const std::string& paramId) {
    return project_->removeModulation(lfoId, paramId);
}

bool EngineHost::applySubtractiveSynthPreset(
    const std::string& deviceId,
    const std::vector<std::pair<std::string, float>>& params,
    const std::vector<ProjectEngine::SubtractivePresetLfoSpec>& lfos,
    const std::vector<ProjectEngine::SubtractivePresetModSpec>& mods) {
    return project_->applySubtractiveSynthPreset(deviceId, params, lfos, mods);
}

bool EngineHost::noteOn(int pitch, float velocity) {
    ensureAudioOutput();
    return project_->noteOn(pitch, velocity);
}

bool EngineHost::noteOff(int pitch) {
    return project_->noteOff(pitch);
}

void EngineHost::allNotesOff() {
    project_->allNotesOff();
}

void EngineHost::clearCapture() {
    project_->clearCapture();
}

bool EngineHost::commitCapture() {
    return project_->commitCapture();
}

void EngineHost::enterPlayMode() {
    ensureAudioOutput();
}

void EngineHost::setPitchBend(float bend) noexcept {
    project_->setLivePitchBend(bend);
}

void EngineHost::setModulation(float mod) noexcept {
    project_->setLiveModulation(mod);
}

std::vector<float> EngineHost::renderOffline(double lengthBeats, double sampleRate) {
    return project_->renderOffline(lengthBeats, sampleRate);
}

std::string EngineHost::importWavSample(const std::string& displayName,
                                        const std::vector<uint8_t>& wavBytes) {
    ensureSampleBankReady();
    const std::string id = "sample_import_" + std::to_string(nextImportSampleNum_++);
    const std::string name = displayName.empty() ? "Imported sample" : displayName;
    if (!sampleBank_.loadFromWavBytes(id, name, "imported", wavBytes, 120)) {
        return {};
    }
    return id;
}

void EngineHost::previewSample(const std::string& sampleId) {
    const auto* sample = sampleBank_.findSample(sampleId);
    if (sample == nullptr || sample->pcm.empty()) {
        return;
    }
    // Atomically swap in a new shared_ptr so the audio thread never reads freed memory.
    auto buf = std::make_shared<const std::vector<float>>(sample->pcm);
    previewVoice_.pcmData = buf->data();
    previewVoice_.pcmSize = static_cast<int>(buf->size());
    previewVoice_.sampleRate.store(sample->sampleRate, std::memory_order_release);
    previewVoice_.position.store(0, std::memory_order_release);
    previewVoice_.active.store(true, std::memory_order_release);
    std::atomic_store(&previewBuffer_, std::move(buf));
    ensureAudioOutput();
}

bool EngineHost::saveProject(const std::string& archivePath) {
    return saveProjectToArchive(*project_, archivePath);
}

bool EngineHost::loadProject(const std::string& archivePath) {
    ensureSampleBankReady();
    return loadProjectFromArchive(*project_, archivePath);
}

std::string EngineHost::getProjectFileJson() const {
    return projectFileToJson(project_->toProjectFileData(),
                             project_->deviceRegistry());
}

bool EngineHost::loadProjectFileJson(const std::string& json) {
    ProjectFileData data;
    if (!parseProjectFileJson(json, data, project_->deviceRegistry())) {
        return false;
    }
    ensureSampleBankReady();
    sampleBank_.clearImported();
    sampleBank_.restoreMetadata(data.sampleLibrary, data.bpm > 0 ? data.bpm : 120);
    if (!project_->loadFromProjectFileData(data)) {
        return false;
    }
    return true;
}

void EngineHost::advancePlayheadForBlock(int numFrames, double sampleRate) noexcept {
    project_->advancePlayhead(numFrames, sampleRate);
}

} // namespace audioapp
