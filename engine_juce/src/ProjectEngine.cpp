#include "audioapp/ProjectEngine.hpp"
#include "audioapp/ProjectJson.hpp"
#include "audioapp/TimelineClipTypes.hpp"
#include "audioapp/MidiUtils.hpp"
#include "audioapp/MasterMix.hpp"
#include "audioapp/SamplePlayback.hpp"
#include "audioapp/DeviceChain.hpp"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstring>
#include <cstdlib>

namespace audioapp {

SubtractiveSynthParams ProjectEngine::subtractiveParamsFromDevice(const Device& device) {
    SubtractiveSynthParams params;
    params.gain = device.gain;
    params.osc1Wave = device.osc1Wave;
    params.osc2Wave = device.osc2Wave;
    params.osc1Shape = device.osc1Shape;
    params.osc2Shape = device.osc2Shape;
    params.osc1Octave = device.osc1Octave;
    params.osc1Semi = device.osc1Semi;
    params.osc1Detune = device.osc1Detune;
    params.osc2Octave = device.osc2Octave;
    params.osc2Semi = device.osc2Semi;
    params.osc2Detune = device.osc2Detune;
    params.osc1Level = device.osc1Level;
    params.osc2Level = device.osc2Level;
    params.oscMix = device.oscMix;
    params.osc1Sync = device.osc1Sync;
    params.osc2Sync = device.osc2Sync;
    params.noiseLevel = device.noiseLevel;
    params.oscMixMode = device.oscMixMode;
    params.unisonVoices = device.unisonVoices;
    params.unisonDetune = device.unisonDetune;
    params.filterMode = device.filterMode;
    params.filterCutoff = device.filterCutoff;
    params.filterQ = device.filterQ;
    params.filterEnvAmount = device.filterEnvAmount;
    params.filterAttack = device.filterAttack;
    params.filterDecay = device.filterDecay;
    params.filterSustain = device.filterSustain;
    params.filterRelease = device.filterRelease;
    params.ampAttack = device.attack;
    params.ampDecay = device.decay;
    params.ampSustain = device.sustain;
    params.ampRelease = device.release;
    params.glideMs = device.glideMs;
    params.velocitySensitivity = device.velocitySensitivity;
    return params;
}

void ProjectEngine::copyDeviceToState(const Device& src, DeviceState& dst) {
    dst.id = src.id;
    dst.type = src.type;
    dst.frequencyHz = src.frequencyHz;
    dst.gain = src.gain;
    dst.pan = src.pan;
    dst.sampleId = src.sampleId;
    dst.attack = src.attack;
    dst.decay = src.decay;
    dst.sustain = src.sustain;
    dst.release = src.release;
    dst.filterCutoff = src.filterCutoff;
    dst.filterQ = src.filterQ;
    dst.filterMode = src.filterMode;
    dst.trimStartSec = src.trimStartSec;
    dst.trimEndSec = src.trimEndSec;
    dst.bypassed = src.bypassed;
    dst.osc1Wave = src.osc1Wave;
    dst.osc2Wave = src.osc2Wave;
    dst.osc1Shape = src.osc1Shape;
    dst.osc2Shape = src.osc2Shape;
    dst.osc1Octave = src.osc1Octave;
    dst.osc1Semi = src.osc1Semi;
    dst.osc1Detune = src.osc1Detune;
    dst.osc2Octave = src.osc2Octave;
    dst.osc2Semi = src.osc2Semi;
    dst.osc2Detune = src.osc2Detune;
    dst.osc1Level = src.osc1Level;
    dst.osc2Level = src.osc2Level;
    dst.oscMix = src.oscMix;
    dst.osc1Sync = src.osc1Sync;
    dst.osc2Sync = src.osc2Sync;
    dst.noiseLevel = src.noiseLevel;
    dst.oscMixMode = src.oscMixMode;
    dst.unisonVoices = src.unisonVoices;
    dst.unisonDetune = src.unisonDetune;
    dst.filterEnvAmount = src.filterEnvAmount;
    dst.filterAttack = src.filterAttack;
    dst.filterDecay = src.filterDecay;
    dst.filterSustain = src.filterSustain;
    dst.filterRelease = src.filterRelease;
    dst.glideMs = src.glideMs;
    dst.velocitySensitivity = src.velocitySensitivity;
}

void ProjectEngine::copyStateToDevice(const DeviceState& src, Device& dst) {
    dst.id = src.id;
    dst.type = src.type;
    dst.frequencyHz = src.frequencyHz;
    dst.gain = src.gain;
    dst.pan = src.pan;
    dst.sampleId = src.sampleId;
    dst.attack = src.attack;
    dst.decay = src.decay;
    dst.sustain = src.sustain;
    dst.release = src.release;
    dst.filterCutoff = src.filterCutoff;
    dst.filterQ = src.filterQ;
    dst.filterMode = src.filterMode;
    dst.trimStartSec = src.trimStartSec;
    dst.trimEndSec = src.trimEndSec;
    dst.bypassed = src.bypassed;
    dst.osc1Wave = src.osc1Wave;
    dst.osc2Wave = src.osc2Wave;
    dst.osc1Shape = src.osc1Shape;
    dst.osc2Shape = src.osc2Shape;
    dst.osc1Octave = src.osc1Octave;
    dst.osc1Semi = src.osc1Semi;
    dst.osc1Detune = src.osc1Detune;
    dst.osc2Octave = src.osc2Octave;
    dst.osc2Semi = src.osc2Semi;
    dst.osc2Detune = src.osc2Detune;
    dst.osc1Level = src.osc1Level;
    dst.osc2Level = src.osc2Level;
    dst.oscMix = src.oscMix;
    dst.osc1Sync = src.osc1Sync;
    dst.osc2Sync = src.osc2Sync;
    dst.noiseLevel = src.noiseLevel;
    dst.oscMixMode = src.oscMixMode;
    dst.unisonVoices = src.unisonVoices;
    dst.unisonDetune = src.unisonDetune;
    dst.filterEnvAmount = src.filterEnvAmount;
    dst.filterAttack = src.filterAttack;
    dst.filterDecay = src.filterDecay;
    dst.filterSustain = src.filterSustain;
    dst.filterRelease = src.filterRelease;
    dst.glideMs = src.glideMs;
    dst.velocitySensitivity = src.velocitySensitivity;
}

void ProjectEngine::createProject() {
    std::lock_guard<std::mutex> lock(mutex_);
    tracks_.clear();
    selectedTrackId_.clear();
    projectName_ = "Untitled";
    nextTrackNum_ = 1;
    nextDeviceNum_ = 1;
    nextClipNum_ = 1;
    nextSampleClipNum_ = 1;
    bpm_ = 120;
    activeFrequencyHz_.store(440.0f, std::memory_order_release);
    playing_.store(false, std::memory_order_release);
    playheadBeats_.store(0.0, std::memory_order_release);
    masterGain_.store(1.0f, std::memory_order_release);
    trackPlaybackCount_.store(0, std::memory_order_release);
}

std::string ProjectEngine::addTrack(const std::string& name) {
    std::lock_guard<std::mutex> lock(mutex_);
    Track track;
    track.id = "track-" + std::to_string(nextTrackNum_++);
    track.name = name.empty() ? ("Track " + std::to_string(tracks_.size() + 1)) : name;

    Device osc;
    osc.id = "dev-" + std::to_string(nextDeviceNum_++);
    osc.type = "simple_sampler";
    osc.gain = 1.0f;
    track.devices.push_back(std::move(osc));

    Device gain;
    gain.id = "dev-" + std::to_string(nextDeviceNum_++);
    gain.type = "track_gain";
    gain.gain = 1.0f;
    track.devices.push_back(std::move(gain));

    tracks_.push_back(std::move(track));
    selectedTrackId_ = tracks_.back().id;
    syncActiveFrequencyLocked();
    rebuildTrackPlaybackLocked();
    return selectedTrackId_;
}

bool ProjectEngine::selectTrack(const std::string& trackId) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (findTrackLocked(trackId) == nullptr) {
        return false;
    }
    selectedTrackId_ = trackId;
    syncActiveFrequencyLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

std::string ProjectEngine::addDeviceToTrack(const std::string& trackId,
                                            const std::string& deviceType,
                                            int insertIndex) {
    std::lock_guard<std::mutex> lock(mutex_);
    Track* track = findTrackLocked(trackId);
    if (track == nullptr) {
        return {};
    }

    Device device;
    device.id = "dev-" + std::to_string(nextDeviceNum_++);
    device.type = deviceType.empty() ? "simple_oscillator" : deviceType;
    device.frequencyHz = 440.0f;
    if (device.type == "subtractive_synth") {
        device.attack = 0.02f;
        device.decay = 0.25f;
        device.sustain = 0.75f;
        device.release = 0.35f;
        device.filterCutoff = 0.75f;
        device.filterQ = 0.2f;
        device.osc1Wave = 2;
        device.osc2Wave = 2;
        device.osc1Shape = 0.5f;
        device.osc2Shape = 0.5f;
        device.osc1Level = 0.85f;
        device.osc2Level = 0.5f;
        device.filterEnvAmount = 0.5f;
        device.filterAttack = 0.05f;
        device.filterDecay = 0.35f;
        device.filterSustain = 0.4f;
        device.filterRelease = 0.45f;
        device.velocitySensitivity = 1.0f;
    }
    const std::string deviceId = device.id;

    size_t gainIndex = track->devices.size();
    for (size_t i = 0; i < track->devices.size(); ++i) {
        if (track->devices[i].type == "track_gain") {
            gainIndex = i;
            break;
        }
    }

    size_t insertAt = gainIndex;
    if (insertIndex >= 0) {
        insertAt = std::min(static_cast<size_t>(insertIndex), gainIndex);
    }

    track->devices.insert(track->devices.begin() + static_cast<std::ptrdiff_t>(insertAt),
                          std::move(device));
    syncActiveFrequencyLocked();
    rebuildTrackPlaybackLocked();
    return deviceId;
}

bool ProjectEngine::setDeviceParameter(const std::string& deviceId,
                                       const std::string& parameterId,
                                       float value) {
    std::lock_guard<std::mutex> lock(mutex_);
    Device* device = findDeviceLocked(deviceId);
    if (device == nullptr) {
        return false;
    }
    if (parameterId == "frequency" && device->type == "simple_oscillator") {
        device->frequencyHz = value;
        syncActiveFrequencyLocked();
        rebuildTrackPlaybackLocked();
        return true;
    }
    if (parameterId == "gain" && device->type == "track_gain") {
        device->gain = std::clamp(value, 0.0f, 1.0f);
        rebuildTrackPlaybackLocked();
        return true;
    }
    if (parameterId == "gain" && device->type == "simple_sampler") {
        device->gain = std::clamp(value, 0.0f, 1.0f);
        rebuildTrackPlaybackLocked();
        return true;
    }
    if (parameterId == "gain" && device->type == "simple_oscillator") {
        device->gain = std::clamp(value, 0.0f, 1.0f);
        rebuildTrackPlaybackLocked();
        return true;
    }
    if (parameterId == "gain" && device->type == "subtractive_synth") {
        device->gain = std::clamp(value, 0.0f, 1.0f);
        rebuildTrackPlaybackLocked();
        return true;
    }
    if (parameterId == "pan" && device->type != "track_gain") {
        device->pan = std::clamp(value, 0.0f, 1.0f);
        rebuildTrackPlaybackLocked();
        return true;
    }
    if (parameterId == "bypass" && device->type != "track_gain") {
        device->bypassed = value >= 0.5f;
        rebuildTrackPlaybackLocked();
        return true;
    }
    if (device->type == "simple_sampler") {
        if (parameterId == "attack" || parameterId == "decay" || parameterId == "release") {
            const float clamped = std::clamp(value, 0.0f, 1.0f);
            if (parameterId == "attack") {
                device->attack = clamped;
            } else if (parameterId == "decay") {
                device->decay = clamped;
            } else {
                device->release = clamped;
            }
            rebuildTrackPlaybackLocked();
            return true;
        }
        if (parameterId == "sustain") {
            device->sustain = std::clamp(value, 0.0f, 1.0f);
            rebuildTrackPlaybackLocked();
            return true;
        }
        if (parameterId == "filterCutoff") {
            device->filterCutoff = std::clamp(value, 0.0f, 1.0f);
            rebuildTrackPlaybackLocked();
            return true;
        }
        if (parameterId == "filterQ") {
            device->filterQ = std::clamp(value, 0.0f, 1.0f);
            rebuildTrackPlaybackLocked();
            return true;
        }
        if (parameterId == "filterMode") {
            device->filterMode = std::clamp(static_cast<int>(std::lround(value)), 0, 3);
            rebuildTrackPlaybackLocked();
            return true;
        }
        if (parameterId == "trimStartSec") {
            device->trimStartSec = std::max(0.0f, value);
            rebuildTrackPlaybackLocked();
            return true;
        }
        if (parameterId == "trimEndSec") {
            device->trimEndSec = std::max(0.0f, value);
            rebuildTrackPlaybackLocked();
            return true;
        }
    }
    if (device->type == "subtractive_synth") {
        if (parameterId == "attack" || parameterId == "decay" || parameterId == "release" ||
            parameterId == "sustain") {
            const float clamped = std::clamp(value, 0.0f, 1.0f);
            if (parameterId == "attack") {
                device->attack = clamped;
            } else if (parameterId == "decay") {
                device->decay = clamped;
            } else if (parameterId == "release") {
                device->release = clamped;
            } else {
                device->sustain = clamped;
            }
            rebuildTrackPlaybackLocked();
            return true;
        }
        if (parameterId == "filterCutoff" || parameterId == "filterQ" || parameterId == "filterEnvAmount" ||
            parameterId == "filterAttack" || parameterId == "filterDecay" || parameterId == "filterSustain" ||
            parameterId == "filterRelease" || parameterId == "osc1Octave" || parameterId == "osc1Semi" ||
            parameterId == "osc1Detune" || parameterId == "osc2Octave" || parameterId == "osc2Semi" ||
            parameterId == "osc2Detune" || parameterId == "osc1Level" || parameterId == "osc2Level" ||
            parameterId == "oscMix" || parameterId == "osc1Sync" || parameterId == "osc2Sync" ||
            parameterId == "noiseLevel" || parameterId == "unisonVoices" || parameterId == "unisonDetune" ||
            parameterId == "glideMs" || parameterId == "velocitySensitivity") {
            float clamped = std::clamp(value, 0.0f, 1.0f);
            if (parameterId == "filterCutoff") {
                device->filterCutoff = clamped;
            } else if (parameterId == "filterQ") {
                device->filterQ = clamped;
            } else if (parameterId == "filterEnvAmount") {
                device->filterEnvAmount = clamped;
            } else if (parameterId == "filterAttack") {
                device->filterAttack = clamped;
            } else if (parameterId == "filterDecay") {
                device->filterDecay = clamped;
            } else if (parameterId == "filterSustain") {
                device->filterSustain = clamped;
            } else if (parameterId == "filterRelease") {
                device->filterRelease = clamped;
            } else if (parameterId == "osc1Octave") {
                device->osc1Octave = clamped;
            } else if (parameterId == "osc1Semi") {
                device->osc1Semi = clamped;
            } else if (parameterId == "osc1Detune") {
                device->osc1Detune = clamped;
            } else if (parameterId == "osc2Octave") {
                device->osc2Octave = clamped;
            } else if (parameterId == "osc2Semi") {
                device->osc2Semi = clamped;
            } else if (parameterId == "osc2Detune") {
                device->osc2Detune = clamped;
            } else if (parameterId == "osc1Level") {
                device->osc1Level = clamped;
            } else if (parameterId == "osc2Level") {
                device->osc2Level = clamped;
            } else if (parameterId == "oscMix") {
                device->oscMix = clamped;
            } else if (parameterId == "osc1Sync") {
                device->osc1Sync = clamped;
            } else if (parameterId == "osc2Sync") {
                device->osc2Sync = clamped;
            } else if (parameterId == "noiseLevel") {
                device->noiseLevel = clamped;
            } else if (parameterId == "unisonVoices") {
                device->unisonVoices = clamped;
            } else if (parameterId == "unisonDetune") {
                device->unisonDetune = clamped;
            } else if (parameterId == "glideMs") {
                device->glideMs = clamped;
            } else {
                device->velocitySensitivity = clamped;
            }
            rebuildTrackPlaybackLocked();
            return true;
        }
        if (parameterId == "osc1Wave") {
            device->osc1Wave = std::clamp(static_cast<int>(std::lround(value)), 0, 4);
            device->osc1Shape = static_cast<float>(device->osc1Wave) / 4.0f;
            rebuildTrackPlaybackLocked();
            return true;
        }
        if (parameterId == "osc2Wave") {
            device->osc2Wave = std::clamp(static_cast<int>(std::lround(value)), 0, 4);
            device->osc2Shape = static_cast<float>(device->osc2Wave) / 4.0f;
            rebuildTrackPlaybackLocked();
            return true;
        }
        if (parameterId == "osc1Shape") {
            const float clamped = std::clamp(value, 0.0f, 1.0f);
            device->osc1Shape = clamped;
            device->osc1Wave =
                std::clamp(static_cast<int>(std::lround(clamped * 4.0f)), 0, 4);
            rebuildTrackPlaybackLocked();
            return true;
        }
        if (parameterId == "osc2Shape") {
            const float clamped = std::clamp(value, 0.0f, 1.0f);
            device->osc2Shape = clamped;
            device->osc2Wave =
                std::clamp(static_cast<int>(std::lround(clamped * 4.0f)), 0, 4);
            rebuildTrackPlaybackLocked();
            return true;
        }
        if (parameterId == "oscMixMode") {
            device->oscMixMode = std::clamp(static_cast<int>(std::lround(value)), 0, 4);
            rebuildTrackPlaybackLocked();
            return true;
        }
    }
    return false;
}

bool ProjectEngine::setDeviceStringParameter(const std::string& deviceId,
                                             const std::string& parameterId,
                                             const std::string& value) {
    std::lock_guard<std::mutex> lock(mutex_);
    Device* device = findDeviceLocked(deviceId);
    if (device == nullptr) {
        return false;
    }
    if (parameterId == "sampleId" && device->type == "simple_sampler") {
        if (!value.empty() && sampleBank_ != nullptr && sampleBank_->findSample(value) == nullptr) {
            return false;
        }
        device->sampleId = value;
        rebuildTrackPlaybackLocked();
        return true;
    }
    return false;
}

bool ProjectEngine::setMasterGain(float gain) {
    masterGain_.store(std::clamp(gain, 0.0f, 1.0f), std::memory_order_release);
    return true;
}

std::string ProjectEngine::createMidiClip(const std::string& trackId,
                                          double startBeat,
                                          double lengthBeats) {
    std::lock_guard<std::mutex> lock(mutex_);
    Track* track = findTrackLocked(trackId);
    if (track == nullptr) {
        return {};
    }

    MidiClip clip;
    clip.id = "clip-" + std::to_string(nextClipNum_++);
    clip.startBeat = startBeat < 0.0 ? 0.0 : startBeat;
    clip.lengthBeats = lengthBeats > 0.0 ? lengthBeats : 4.0;

    MidiNote seed;
    seed.pitch = 60;
    seed.startBeat = 0.0;
    seed.durationBeats = 1.0;
    seed.velocity = 100.0f;
    clip.notes.push_back(seed);

    track->midiClips.push_back(std::move(clip));
    rebuildTrackPlaybackLocked();
    return track->midiClips.back().id;
}

bool ProjectEngine::setMidiClipNotes(const std::string& clipId,
                                     const std::vector<MidiNoteState>& notes) {
    std::lock_guard<std::mutex> lock(mutex_);
    MidiClip* clip = findMidiClipLocked(clipId);
    if (clip == nullptr) {
        return false;
    }

    clip->notes.clear();
    clip->notes.reserve(notes.size());
    for (const auto& note : notes) {
        MidiNote stored;
        stored.pitch = note.pitch;
        stored.startBeat = note.startBeat < 0.0 ? 0.0 : note.startBeat;
        stored.durationBeats = note.durationBeats > 0.0 ? note.durationBeats : 0.25;
        stored.velocity = note.velocity;
        clip->notes.push_back(stored);
    }
    rebuildTrackPlaybackLocked();
    return true;
}

std::string ProjectEngine::createSampleClip(const std::string& trackId,
                                            const std::string& sampleId,
                                            double startBeat,
                                            double lengthBeats) {
    std::lock_guard<std::mutex> lock(mutex_);
    Track* track = findTrackLocked(trackId);
    if (track == nullptr || sampleId.empty()) {
        return {};
    }
    if (sampleBank_ != nullptr && sampleBank_->findSample(sampleId) == nullptr) {
        return {};
    }

    SampleClip clip;
    clip.id = "sclip-" + std::to_string(nextSampleClipNum_++);
    clip.sampleId = sampleId;
    clip.startBeat = startBeat < 0.0 ? 0.0 : startBeat;
    if (lengthBeats > 0.0) {
        clip.lengthBeats = lengthBeats;
    } else if (sampleBank_ != nullptr) {
        clip.lengthBeats = sampleBank_->beatsForSample(sampleId, bpm_);
    } else {
        clip.lengthBeats = 4.0;
    }

    track->sampleClips.push_back(std::move(clip));
    rebuildTrackPlaybackLocked();
    return track->sampleClips.back().id;
}

bool ProjectEngine::moveClip(const std::string& clipId,
                             const std::string& targetTrackId,
                             double startBeat) {
    std::lock_guard<std::mutex> lock(mutex_);
    Track* targetTrack = findTrackLocked(targetTrackId);
    if (targetTrack == nullptr || clipId.empty()) {
        return false;
    }

    const double clampedStart = startBeat < 0.0 ? 0.0 : startBeat;

    for (auto& track : tracks_) {
        for (auto it = track.midiClips.begin(); it != track.midiClips.end(); ++it) {
            if (it->id != clipId) {
                continue;
            }
            MidiClip clip = std::move(*it);
            track.midiClips.erase(it);
            clip.startBeat = clampedStart;
            targetTrack->midiClips.push_back(std::move(clip));
            rebuildTrackPlaybackLocked();
            return true;
        }
    }

    for (auto& track : tracks_) {
        for (auto it = track.sampleClips.begin(); it != track.sampleClips.end(); ++it) {
            if (it->id != clipId) {
                continue;
            }
            SampleClip clip = std::move(*it);
            track.sampleClips.erase(it);
            clip.startBeat = clampedStart;
            targetTrack->sampleClips.push_back(std::move(clip));
            rebuildTrackPlaybackLocked();
            return true;
        }
    }

    return false;
}

bool ProjectEngine::setClipLength(const std::string& clipId, double lengthBeats) {
    std::lock_guard<std::mutex> lock(mutex_);
    const double len = lengthBeats < kMinClipLengthBeats ? kMinClipLengthBeats : lengthBeats;

    if (MidiClip* midi = findMidiClipLocked(clipId)) {
        midi->lengthBeats = len;
        rebuildTrackPlaybackLocked();
        return true;
    }
    if (SampleClip* sample = findSampleClipLocked(clipId)) {
        sample->lengthBeats = len;
        rebuildTrackPlaybackLocked();
        return true;
    }
    return false;
}

bool ProjectEngine::setBpm(int bpm) {
    if (bpm < 40 || bpm > 300) {
        return false;
    }
    std::lock_guard<std::mutex> lock(mutex_);
    bpm_ = bpm;
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::deleteTrack(const std::string& trackId) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (tracks_.size() <= 1) {
        return false;
    }
    for (auto it = tracks_.begin(); it != tracks_.end(); ++it) {
        if (it->id != trackId) {
            continue;
        }
        tracks_.erase(it);
        if (selectedTrackId_ == trackId) {
            selectedTrackId_ = tracks_.empty() ? std::string{} : tracks_.front().id;
        }
        syncActiveFrequencyLocked();
        rebuildTrackPlaybackLocked();
        return true;
    }
    return false;
}

bool ProjectEngine::deleteClip(const std::string& clipId) {
    std::lock_guard<std::mutex> lock(mutex_);
    for (auto& track : tracks_) {
        for (auto it = track.midiClips.begin(); it != track.midiClips.end(); ++it) {
            if (it->id == clipId) {
                track.midiClips.erase(it);
                rebuildTrackPlaybackLocked();
                return true;
            }
        }
        for (auto it = track.sampleClips.begin(); it != track.sampleClips.end(); ++it) {
            if (it->id == clipId) {
                track.sampleClips.erase(it);
                rebuildTrackPlaybackLocked();
                return true;
            }
        }
    }
    return false;
}

bool ProjectEngine::duplicateClip(const std::string& clipId) {
    std::lock_guard<std::mutex> lock(mutex_);
    for (auto& track : tracks_) {
        for (const auto& clip : track.midiClips) {
            if (clip.id != clipId) {
                continue;
            }
            MidiClip copy = clip;
            copy.id = "clip-" + std::to_string(nextClipNum_++);
            copy.startBeat = clip.startBeat + clip.lengthBeats;
            track.midiClips.push_back(std::move(copy));
            rebuildTrackPlaybackLocked();
            return true;
        }
        for (const auto& clip : track.sampleClips) {
            if (clip.id != clipId) {
                continue;
            }
            SampleClip copy = clip;
            copy.id = "sclip-" + std::to_string(nextSampleClipNum_++);
            copy.startBeat = clip.startBeat + clip.lengthBeats;
            track.sampleClips.push_back(std::move(copy));
            rebuildTrackPlaybackLocked();
            return true;
        }
    }
    return false;
}

bool ProjectEngine::setLoopEnabled(bool enabled) {
    std::lock_guard<std::mutex> lock(mutex_);
    loopEnabled_ = enabled;
    return true;
}

bool ProjectEngine::setLoopLengthBeats(double lengthBeats) {
    if (lengthBeats < 1.0) {
        return false;
    }
    std::lock_guard<std::mutex> lock(mutex_);
    loopLengthBeats_ = lengthBeats;
    return true;
}

std::vector<float> ProjectEngine::renderOffline(double lengthBeats, double sampleRate) {
    if (lengthBeats <= 0.0 || sampleRate <= 0.0) {
        return {};
    }
    std::lock_guard<std::mutex> lock(mutex_);
    const int totalFrames =
        static_cast<int>(lengthBeats * sampleRate * 60.0 / static_cast<double>(std::max(bpm_, 1)));
    if (totalFrames <= 0) {
        return {};
    }
    std::vector<float> output(static_cast<size_t>(totalFrames), 0.0f);
    constexpr int kBlock = 512;
    float block[kBlock];
    for (int offset = 0; offset < totalFrames; offset += kBlock) {
        const int frames = std::min(kBlock, totalFrames - offset);
        const double beat =
            static_cast<double>(offset) / sampleRate * static_cast<double>(bpm_) / 60.0;
        std::memset(block, 0, static_cast<size_t>(frames) * sizeof(float));
        mixAtPlayheadBeat(block, frames, sampleRate, beat);
        std::memcpy(output.data() + offset, block, static_cast<size_t>(frames) * sizeof(float));
    }
    return output;
}

ProjectSnapshot ProjectEngine::snapshot() const {
    std::lock_guard<std::mutex> lock(mutex_);
    ProjectSnapshot snap;
    snap.bpm = bpm_;
    snap.selectedTrackId = selectedTrackId_;
    snap.playheadBeats = playheadBeats_.load(std::memory_order_relaxed);
    snap.playing = playing_.load(std::memory_order_relaxed);
    snap.loopEnabled = loopEnabled_;
    snap.loopLengthBeats = loopLengthBeats_;
    snap.recordArmed = recordArmed_;
    snap.master.id = "master";
    snap.master.name = "Master";
    snap.master.gain = masterGain_.load(std::memory_order_relaxed);
    if (sampleBank_ != nullptr) {
        for (const auto& sample : sampleBank_->listSamples()) {
            SampleLibraryEntryState entry;
            entry.id = sample.id;
            entry.name = sample.name;
            entry.source = sample.source;
            entry.durationBeats = sampleBank_->beatsForSample(sample.id, bpm_);
            entry.waveformPeaks = sample.peaks;
            snap.samples.push_back(std::move(entry));
        }
    }
    snap.tracks.reserve(tracks_.size());
    for (const auto& track : tracks_) {
        TrackState ts;
        ts.id = track.id;
        ts.name = track.name;
        ts.devices.reserve(track.devices.size());
        for (const auto& device : track.devices) {
            DeviceState ds;
            copyDeviceToState(device, ds);
            ts.devices.push_back(std::move(ds));
        }
        ts.midiClips.reserve(track.midiClips.size());
        for (const auto& clip : track.midiClips) {
            MidiClipState cs;
            cs.id = clip.id;
            cs.startBeat = clip.startBeat;
            cs.lengthBeats = clip.lengthBeats;
            cs.notes.reserve(clip.notes.size());
            for (const auto& note : clip.notes) {
                cs.notes.push_back(MidiNoteState{
                    note.pitch,
                    note.startBeat,
                    note.durationBeats,
                    note.velocity,
                });
            }
            ts.midiClips.push_back(std::move(cs));
        }
        ts.sampleClips.reserve(track.sampleClips.size());
        for (const auto& clip : track.sampleClips) {
            SampleClipState cs;
            cs.id = clip.id;
            cs.sampleId = clip.sampleId;
            cs.startBeat = clip.startBeat;
            cs.lengthBeats = clip.lengthBeats;
            if (sampleBank_ != nullptr) {
                if (const auto* sample = sampleBank_->findSample(clip.sampleId)) {
                    cs.sampleName = sample->name;
                    cs.waveformPeaks = sample->peaks;
                }
            }
            ts.sampleClips.push_back(std::move(cs));
        }
        snap.tracks.push_back(std::move(ts));
    }
    return snap;
}

float ProjectEngine::activeOscillatorFrequencyHz() const {
    if (!playing_.load(std::memory_order_acquire)) {
        return activeFrequencyHz_.load(std::memory_order_acquire);
    }

    const int selectedIndex = selectedTrackPlaybackIndex();
    if (selectedIndex < 0) {
        return activeFrequencyHz_.load(std::memory_order_acquire);
    }

    const auto& track = trackPlayback_[selectedIndex];
    const DeviceNodePlayback* oscillator = findOscillatorNode(track);
    if (oscillator == nullptr) {
        return 0.0f;
    }

    const double playhead = playheadBeats_.load(std::memory_order_acquire);
    if (trackHasActiveSampleAtPlayhead(track, playhead)) {
        return 0.0f;
    }

    MidiPlaybackNote midiNotes[32];
    const int noteCount = track.noteCount > 32 ? 32 : track.noteCount;
    for (int i = 0; i < noteCount; ++i) {
        const PlaybackNote& note = track.notes[i];
        midiNotes[i] = MidiPlaybackNote{
            note.pitch,
            note.clipStartBeat,
            note.clipLengthBeats,
            note.noteStartBeat,
            note.noteDurationBeats,
            note.velocity,
        };
    }
    return midiActiveFrequencyHz(midiNotes, noteCount, playhead, oscillator->frequencyHz);
}

void ProjectEngine::readMasterMix(float* monoOut,
                                  int numFrames,
                                  double sampleRate,
                                  double playheadStartBeat) noexcept {
    if (monoOut == nullptr || numFrames <= 0) {
        return;
    }
    constexpr int kMaxFrames = 4096;
    const int framesToProcess = numFrames > kMaxFrames ? kMaxFrames : numFrames;
    float left[kMaxFrames];
    float right[kMaxFrames];
    readMasterMixStereo(left, right, framesToProcess, sampleRate, playheadStartBeat);
    for (int frame = 0; frame < framesToProcess; ++frame) {
        monoOut[frame] = (left[frame] + right[frame]) * 0.5f;
    }
    if (framesToProcess < numFrames) {
        std::memset(monoOut + framesToProcess, 0,
                    static_cast<size_t>(numFrames - framesToProcess) * sizeof(float));
    }
}

void ProjectEngine::readMasterMixStereo(float* leftOut,
                                        float* rightOut,
                                        int numFrames,
                                        double sampleRate,
                                        double playheadStartBeat) noexcept {
    if (leftOut == nullptr || rightOut == nullptr || numFrames <= 0) {
        return;
    }
    std::memset(leftOut, 0, static_cast<size_t>(numFrames) * sizeof(float));
    std::memset(rightOut, 0, static_cast<size_t>(numFrames) * sizeof(float));
    if (!playing_.load(std::memory_order_acquire)) {
        return;
    }
    mixAtPlayheadBeatStereo(leftOut, rightOut, numFrames, sampleRate, playheadStartBeat);
}

void ProjectEngine::mixAtPlayheadBeatStereo(float* masterLeft,
                                            float* masterRight,
                                            int numFrames,
                                            double sampleRate,
                                            double playheadStartBeat) noexcept {
    if (masterLeft == nullptr || masterRight == nullptr || numFrames <= 0) {
        return;
    }

    const int trackCount = trackPlaybackCount_.load(std::memory_order_acquire);
    if (trackCount <= 0) {
        return;
    }

    const float masterGain = masterGain_.load(std::memory_order_acquire);
    constexpr int kMaxFrames = 4096;
    float trackLeft[kMaxFrames];
    float trackRight[kMaxFrames];
    const int framesToProcess = numFrames > kMaxFrames ? kMaxFrames : numFrames;

    SampleClipPlaybackRegion regions[8];

    for (int trackIndex = 0; trackIndex < trackCount; ++trackIndex) {
        const TrackPlaybackSnapshot& track = trackPlayback_[trackIndex];
        std::memset(trackLeft, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
        std::memset(trackRight, 0, static_cast<size_t>(framesToProcess) * sizeof(float));

        if (track.regionCount > 0) {
            for (int i = 0; i < track.regionCount; ++i) {
                const SampleRegion& source = track.regions[i];
                regions[i] = SampleClipPlaybackRegion{
                    source.clipStartBeat,
                    source.clipLengthBeats,
                    source.pcm,
                    source.frameCount,
                    source.pcmSampleRate,
                };
            }
            mixSampleRegionsBlock(trackLeft,
                                  framesToProcess,
                                  sampleRate,
                                  bpm_,
                                  playheadStartBeat,
                                  regions,
                                  track.regionCount);
            for (int frame = 0; frame < framesToProcess; ++frame) {
                trackRight[frame] = trackLeft[frame];
            }
        }

        const bool suppressInstruments = trackHasActiveSampleAtPlayhead(track, playheadStartBeat);

        MidiPlaybackNote midiNotes[32];
        const int noteCount = track.noteCount > 32 ? 32 : track.noteCount;
        for (int i = 0; i < noteCount; ++i) {
            const PlaybackNote& note = track.notes[i];
            midiNotes[i] = MidiPlaybackNote{
                note.pitch,
                note.clipStartBeat,
                note.clipLengthBeats,
                note.noteStartBeat,
                note.noteDurationBeats,
                note.velocity,
            };
        }

        float oscillatorPhase = track.oscillatorPhase;
        processDeviceChain(trackLeft,
                           trackRight,
                           framesToProcess,
                           sampleRate,
                           bpm_,
                           playheadStartBeat,
                           midiNotes,
                           noteCount,
                           track.devices,
                           track.deviceCount,
                           oscillatorPhase,
                           suppressInstruments,
                           trackPlayback_[trackIndex].samplerFilterStates,
                           trackPlayback_[trackIndex].subtractiveRuntimes);
        trackPlayback_[trackIndex].oscillatorPhase = oscillatorPhase;

        for (int frame = 0; frame < framesToProcess; ++frame) {
            masterLeft[frame] += trackLeft[frame];
            masterRight[frame] += trackRight[frame];
        }
    }

    for (int frame = 0; frame < framesToProcess; ++frame) {
        masterLeft[frame] = std::tanh(masterLeft[frame] * masterGain);
        masterRight[frame] = std::tanh(masterRight[frame] * masterGain);
    }
}

void ProjectEngine::mixAtPlayheadBeat(float* monoOut,
                                      int numFrames,
                                      double sampleRate,
                                      double playheadStartBeat) noexcept {
    if (monoOut == nullptr || numFrames <= 0) {
        return;
    }
    constexpr int kMaxFrames = 4096;
    const int framesToProcess = numFrames > kMaxFrames ? kMaxFrames : numFrames;
    float left[kMaxFrames];
    float right[kMaxFrames];
    mixAtPlayheadBeatStereo(left, right, framesToProcess, sampleRate, playheadStartBeat);
    for (int frame = 0; frame < framesToProcess; ++frame) {
        monoOut[frame] = (left[frame] + right[frame]) * 0.5f;
    }
}

void ProjectEngine::setPlaying(bool playing) {
    if (playing) {
        std::lock_guard<std::mutex> lock(mutex_);
        rebuildTrackPlaybackLocked();
        resetPlayhead();
    }
    playing_.store(playing, std::memory_order_release);
}

bool ProjectEngine::isPlaying() const noexcept {
    return playing_.load(std::memory_order_acquire);
}

double ProjectEngine::playheadBeats() const noexcept {
    return playheadBeats_.load(std::memory_order_acquire);
}

void ProjectEngine::setPlayheadBeats(double beats) noexcept {
    const double clamped = beats < 0.0 ? 0.0 : beats;
    playheadBeats_.store(clamped, std::memory_order_release);
}

void ProjectEngine::resetPlayhead() noexcept {
    playheadBeats_.store(0.0, std::memory_order_release);
}

void ProjectEngine::advancePlayhead(int numFrames, double sampleRate) noexcept {
    if (!playing_.load(std::memory_order_acquire)) {
        return;
    }
    const double current = playheadBeats_.load(std::memory_order_relaxed);
    double next = advancePlayheadBeats(current, numFrames, sampleRate, bpm_);
    if (loopEnabled_ && loopLengthBeats_ > 0.0 && next >= loopLengthBeats_) {
        next = std::fmod(next, loopLengthBeats_);
    }
    playheadBeats_.store(next, std::memory_order_release);
}

ProjectFileData ProjectEngine::toProjectFileData() const {
    std::lock_guard<std::mutex> lock(mutex_);
    ProjectFileData file;
    file.projectFormatVersion = kProjectFormatVersion;
    file.name = projectName_;
    file.bpm = bpm_;
    file.selectedTrackId = selectedTrackId_;
    file.master.id = "master";
    file.master.name = "Master";
    file.master.gain = masterGain_.load(std::memory_order_relaxed);
    if (sampleBank_ != nullptr) {
        for (const auto& sample : sampleBank_->listSamples()) {
            SampleLibraryEntryState entry;
            entry.id = sample.id;
            entry.name = sample.name;
            entry.source = sample.source;
            entry.durationBeats = sampleBank_->beatsForSample(sample.id, bpm_);
            entry.waveformPeaks = sample.peaks;
            file.sampleLibrary.push_back(std::move(entry));
        }
    }
    file.tracks.reserve(tracks_.size());

    for (const auto& track : tracks_) {
        TrackState ts;
        ts.id = track.id;
        ts.name = track.name;
        for (const auto& device : track.devices) {
            DeviceState ds;
            copyDeviceToState(device, ds);
            ts.devices.push_back(std::move(ds));
        }
        for (const auto& clip : track.midiClips) {
            MidiClipState cs;
            cs.id = clip.id;
            cs.startBeat = clip.startBeat;
            cs.lengthBeats = clip.lengthBeats;
            for (const auto& note : clip.notes) {
                cs.notes.push_back(MidiNoteState{
                    note.pitch,
                    note.startBeat,
                    note.durationBeats,
                    note.velocity,
                });
            }
            ts.midiClips.push_back(std::move(cs));
        }
        for (const auto& clip : track.sampleClips) {
            SampleClipState cs;
            cs.id = clip.id;
            cs.sampleId = clip.sampleId;
            cs.startBeat = clip.startBeat;
            cs.lengthBeats = clip.lengthBeats;
            if (sampleBank_ != nullptr) {
                if (const auto* sample = sampleBank_->findSample(clip.sampleId)) {
                    cs.sampleName = sample->name;
                    cs.waveformPeaks = sample->peaks;
                }
            }
            ts.sampleClips.push_back(std::move(cs));
        }
        file.tracks.push_back(std::move(ts));
    }
    return file;
}

bool ProjectEngine::loadFromProjectFileData(const ProjectFileData& data) {
    if (data.projectFormatVersion != kProjectFormatVersion) {
        return false;
    }

    std::lock_guard<std::mutex> lock(mutex_);
    projectName_ = data.name.empty() ? "Untitled" : data.name;
    bpm_ = data.bpm > 0 ? data.bpm : 120;
    selectedTrackId_ = data.selectedTrackId;
    tracks_.clear();

    for (const auto& trackState : data.tracks) {
        Track track;
        track.id = trackState.id;
        track.name = trackState.name;
        for (const auto& deviceState : trackState.devices) {
            Device device;
            copyStateToDevice(deviceState, device);
            track.devices.push_back(std::move(device));
        }
        for (const auto& clipState : trackState.midiClips) {
            MidiClip clip;
            clip.id = clipState.id;
            clip.startBeat = clipState.startBeat;
            clip.lengthBeats = clipState.lengthBeats;
            for (const auto& noteState : clipState.notes) {
                MidiNote note;
                note.pitch = noteState.pitch;
                note.startBeat = noteState.startBeat;
                note.durationBeats = noteState.durationBeats;
                note.velocity = noteState.velocity;
                clip.notes.push_back(note);
            }
            track.midiClips.push_back(std::move(clip));
        }
        for (const auto& clipState : trackState.sampleClips) {
            SampleClip clip;
            clip.id = clipState.id;
            clip.sampleId = clipState.sampleId;
            clip.startBeat = clipState.startBeat;
            clip.lengthBeats = clipState.lengthBeats;
            track.sampleClips.push_back(std::move(clip));
        }
        tracks_.push_back(std::move(track));
    }

    recomputeIdCountersLocked();
    ensureTrackGainDevicesLocked();
    if (data.master.gain > 0.0f) {
        masterGain_.store(std::clamp(data.master.gain, 0.0f, 1.0f), std::memory_order_release);
    } else {
        masterGain_.store(1.0f, std::memory_order_release);
    }
    playing_.store(false, std::memory_order_release);
    playheadBeats_.store(0.0, std::memory_order_release);
    syncActiveFrequencyLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

void ProjectEngine::recomputeIdCountersLocked() {
    auto maxSuffix = [](const std::string& id, const std::string& prefix) {
        if (id.rfind(prefix, 0) != 0) {
            return 0;
        }
        const auto suffix = id.substr(prefix.size());
        return suffix.empty() ? 0 : std::atoi(suffix.c_str());
    };

    int maxTrack = 0;
    int maxDevice = 0;
    int maxClip = 0;
    int maxSampleClip = 0;
    for (const auto& track : tracks_) {
        maxTrack = std::max(maxTrack, maxSuffix(track.id, "track-"));
        for (const auto& device : track.devices) {
            maxDevice = std::max(maxDevice, maxSuffix(device.id, "dev-"));
        }
        for (const auto& clip : track.midiClips) {
            maxClip = std::max(maxClip, maxSuffix(clip.id, "clip-"));
        }
        for (const auto& clip : track.sampleClips) {
            maxSampleClip = std::max(maxSampleClip, maxSuffix(clip.id, "sclip-"));
        }
    }
    nextTrackNum_ = maxTrack + 1;
    nextDeviceNum_ = maxDevice + 1;
    nextClipNum_ = maxClip + 1;
    nextSampleClipNum_ = maxSampleClip + 1;
}

void ProjectEngine::rebuildTrackPlaybackLocked() {
    int trackIndex = 0;
    for (const auto& sourceTrack : tracks_) {
        if (trackIndex >= kMaxTracks) {
            break;
        }

        TrackPlaybackSnapshot& snap = trackPlayback_[trackIndex];
        snap.trackId = sourceTrack.id;
        snap.noteCount = 0;
        snap.regionCount = 0;
        snap.deviceCount = 0;

        for (const auto& device : sourceTrack.devices) {
            if (snap.deviceCount >= kMaxDevicesPerTrack) {
                break;
            }

            DeviceNodePlayback& node = snap.devices[snap.deviceCount++];
            node.bypassed = device.bypassed;
            if (device.type == "simple_oscillator") {
                node.kind = DeviceNodeKind::Oscillator;
                node.frequencyHz = device.frequencyHz;
                node.gain = device.gain;
                node.pan = device.pan;
            } else if (device.type == "simple_sampler") {
                node.kind = DeviceNodeKind::Sampler;
                node.gain = device.gain;
                node.pan = device.pan;
                node.attack = device.attack;
                node.decay = device.decay;
                node.sustain = device.sustain;
                node.release = device.release;
                node.filterCutoff = device.filterCutoff;
                node.filterQ = device.filterQ;
                node.filterMode = device.filterMode;
                node.samplerPcm = nullptr;
                node.samplerFrameCount = 0;
                node.samplerPcmSampleRate = 48000.0;
                if (sampleBank_ != nullptr && !device.sampleId.empty()) {
                    if (const auto* sample = sampleBank_->findSample(device.sampleId)) {
                        if (!sample->pcm.empty()) {
                            node.samplerPcm = sample->pcm.data();
                            node.samplerFrameCount = static_cast<int>(sample->pcm.size());
                            node.samplerPcmSampleRate = sample->sampleRate;
                            const int frameCount = node.samplerFrameCount;
                            node.trimStartFrame = std::clamp(
                                static_cast<int>(device.trimStartSec * sample->sampleRate),
                                0,
                                std::max(0, frameCount - 1));
                            node.trimEndFrame = device.trimEndSec > 0.0f
                                ? std::clamp(static_cast<int>(device.trimEndSec * sample->sampleRate),
                                             node.trimStartFrame + 1,
                                             frameCount)
                                : frameCount;
                        }
                    }
                }
            } else if (device.type == "track_gain") {
                node.kind = DeviceNodeKind::TrackGain;
                node.gain = device.gain;
            } else if (device.type == "subtractive_synth") {
                node.kind = DeviceNodeKind::SubtractiveSynth;
                node.gain = device.gain;
                node.pan = device.pan;
                node.subtractive = subtractiveParamsFromDevice(device);
            } else {
                node.kind = DeviceNodeKind::Unknown;
            }
        }

        for (const auto& clip : sourceTrack.midiClips) {
            for (const auto& note : clip.notes) {
                if (snap.noteCount >= static_cast<int>(sizeof(snap.notes) / sizeof(snap.notes[0]))) {
                    break;
                }
                snap.notes[snap.noteCount++] = PlaybackNote{
                    note.pitch,
                    clip.startBeat,
                    clip.lengthBeats,
                    note.startBeat,
                    note.durationBeats,
                    note.velocity,
                };
            }
        }

        if (sampleBank_ != nullptr) {
            for (const auto& clip : sourceTrack.sampleClips) {
                if (snap.regionCount >= static_cast<int>(sizeof(snap.regions) / sizeof(snap.regions[0]))) {
                    break;
                }
                const auto* sample = sampleBank_->findSample(clip.sampleId);
                if (sample == nullptr || sample->pcm.empty()) {
                    continue;
                }
                snap.regions[snap.regionCount++] = SampleRegion{
                    clip.startBeat,
                    clip.lengthBeats,
                    sample->pcm.data(),
                    static_cast<int>(sample->pcm.size()),
                    sample->sampleRate,
                };
            }
        }

        ++trackIndex;
    }
    trackPlaybackCount_.store(trackIndex, std::memory_order_release);
}

bool ProjectEngine::trackHasActiveSampleAtPlayhead(const TrackPlaybackSnapshot& track,
                                                   double playheadBeat) const noexcept {
    for (int i = 0; i < track.regionCount; ++i) {
        const SampleRegion& region = track.regions[i];
        if (playheadBeat >= region.clipStartBeat &&
            playheadBeat < region.clipStartBeat + region.clipLengthBeats) {
            return true;
        }
    }
    return false;
}

const DeviceNodePlayback* ProjectEngine::findOscillatorNode(
    const TrackPlaybackSnapshot& track) const noexcept {
    for (int i = 0; i < track.deviceCount; ++i) {
        if (track.devices[i].kind == DeviceNodeKind::Oscillator) {
            return &track.devices[i];
        }
    }
    return nullptr;
}

int ProjectEngine::selectedTrackPlaybackIndex() const noexcept {
    const int count = trackPlaybackCount_.load(std::memory_order_acquire);
    for (int i = 0; i < count; ++i) {
        if (trackPlayback_[i].trackId == selectedTrackId_) {
            return i;
        }
    }
    return -1;
}

void ProjectEngine::syncActiveFrequencyLocked() {
    float freq = 440.0f;
    if (!selectedTrackId_.empty()) {
        if (Track* track = findTrackLocked(selectedTrackId_)) {
            bool foundOscillator = false;
            for (const auto& device : track->devices) {
                if (device.type == "simple_oscillator") {
                    freq = device.frequencyHz;
                    foundOscillator = true;
                    break;
                }
            }
            if (!foundOscillator) {
                activeFrequencyHz_.store(0.0f, std::memory_order_release);
                return;
            }
        }
    }
    activeFrequencyHz_.store(freq, std::memory_order_release);
}

ProjectEngine::Track* ProjectEngine::findTrackLocked(const std::string& trackId) {
    for (auto& track : tracks_) {
        if (track.id == trackId) {
            return &track;
        }
    }
    return nullptr;
}

ProjectEngine::Device* ProjectEngine::findDeviceLocked(const std::string& deviceId) {
    for (auto& track : tracks_) {
        for (auto& device : track.devices) {
            if (device.id == deviceId) {
                return &device;
            }
        }
    }
    return nullptr;
}

ProjectEngine::MidiClip* ProjectEngine::findMidiClipLocked(const std::string& clipId) {
    for (auto& track : tracks_) {
        for (auto& clip : track.midiClips) {
            if (clip.id == clipId) {
                return &clip;
            }
        }
    }
    return nullptr;
}

ProjectEngine::SampleClip* ProjectEngine::findSampleClipLocked(const std::string& clipId) {
    for (auto& track : tracks_) {
        for (auto& clip : track.sampleClips) {
            if (clip.id == clipId) {
                return &clip;
            }
        }
    }
    return nullptr;
}

void ProjectEngine::ensureTrackGainDevicesLocked() {
    for (auto& track : tracks_) {
        bool hasGain = false;
        for (const auto& device : track.devices) {
            if (device.type == "track_gain") {
                hasGain = true;
                break;
            }
        }
        if (hasGain) {
            continue;
        }
        Device gain;
        gain.id = "dev-" + std::to_string(nextDeviceNum_++);
        gain.type = "track_gain";
        gain.gain = 1.0f;
        track.devices.push_back(std::move(gain));
    }
}

} // namespace audioapp
