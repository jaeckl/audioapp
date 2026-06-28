#include "audioapp/model/ClipRepository.hpp"

#include "audioapp/ClipContentPlayback.hpp"

#include <algorithm>
#include <cstdlib>
#include <utility>

namespace audioapp {

ClipRepository::ClipRepository(TrackRepository& tracks) : tracks_(tracks) {}

void ClipRepository::clear() {
    nextClipNum_ = 1;
    nextSampleClipNum_ = 1;
}

std::string ClipRepository::createMidiClip(const std::string& trackId,
                                           double startBeat,
                                           double lengthBeats) {
    Track* track = tracks_.findTrack(trackId);
    if (track == nullptr) {
        return {};
    }

    MidiClip clip;
    clip.id = "clip-" + std::to_string(nextClipNum_++);
    clip.startBeat = startBeat < 0.0 ? 0.0 : startBeat;
    clip.lengthBeats = lengthBeats > 0.0 ? lengthBeats : 4.0;
    clip.naturalLengthBeats = clip.lengthBeats;

    MidiNote seed;
    seed.pitch = 60;
    seed.startBeat = 0.0;
    seed.durationBeats = 1.0;
    seed.velocity = 100.0f;
    clip.notes.push_back(seed);

    track->midiClips.push_back(std::move(clip));
    return track->midiClips.back().id;
}

bool ClipRepository::setMidiClipNotes(const std::string& clipId,
                                      const std::vector<MidiNoteState>& notes) {
    MidiClip* clip = findMidiClip(clipId);
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
    const double noteEnd = midiNotesContentLengthBeats(clip->notes, 0.0);
    if (noteEnd > 0.0) {
        clip->naturalLengthBeats = noteEnd;
    }
    return true;
}

std::string ClipRepository::createSampleClip(const std::string& trackId,
                                             const std::string& sampleId,
                                             double startBeat,
                                             double lengthBeats,
                                             const SampleBank* sampleBank,
                                             int bpm) {
    Track* track = tracks_.findTrack(trackId);
    if (track == nullptr || sampleId.empty()) {
        return {};
    }
    if (sampleBank != nullptr && sampleBank->findSample(sampleId) == nullptr) {
        return {};
    }

    SampleClip clip;
    clip.id = "sclip-" + std::to_string(nextSampleClipNum_++);
    clip.sampleId = sampleId;
    clip.startBeat = startBeat < 0.0 ? 0.0 : startBeat;
    if (lengthBeats > 0.0) {
        clip.lengthBeats = lengthBeats;
    } else if (sampleBank != nullptr) {
        clip.lengthBeats = sampleBank->beatsForSample(sampleId, bpm);
    } else {
        clip.lengthBeats = 4.0;
    }
    // The waveform's natural extent is the source sample's duration at the
    // current BPM. Resize never touches this — it only changes the playback
    // window. The UI uses it to render the waveform at its natural density.
    if (sampleBank != nullptr) {
        clip.naturalLengthBeats = sampleBank->beatsForSample(sampleId, bpm);
    } else {
        clip.naturalLengthBeats = clip.lengthBeats;
    }

    track->sampleClips.push_back(std::move(clip));
    return track->sampleClips.back().id;
}

bool ClipRepository::moveClip(const std::string& clipId,
                              const std::string& targetTrackId,
                              double startBeat) {
    Track* targetTrack = tracks_.findTrack(targetTrackId);
    if (targetTrack == nullptr || clipId.empty()) {
        return false;
    }

    const double clampedStart = startBeat < 0.0 ? 0.0 : startBeat;

    for (auto& track : tracks_.tracks()) {
        for (auto it = track.midiClips.begin(); it != track.midiClips.end(); ++it) {
            if (it->id != clipId) {
                continue;
            }
            MidiClip clip = std::move(*it);
            track.midiClips.erase(it);
            clip.startBeat = clampedStart;
            targetTrack->midiClips.push_back(std::move(clip));
            return true;
        }
    }

    for (auto& track : tracks_.tracks()) {
        for (auto it = track.sampleClips.begin(); it != track.sampleClips.end(); ++it) {
            if (it->id != clipId) {
                continue;
            }
            SampleClip clip = std::move(*it);
            track.sampleClips.erase(it);
            clip.startBeat = clampedStart;
            targetTrack->sampleClips.push_back(std::move(clip));
            return true;
        }
    }

    return false;
}

bool ClipRepository::setClipLength(const std::string& clipId, double lengthBeats) {
    const double len = lengthBeats < kMinClipLengthBeats ? kMinClipLengthBeats : lengthBeats;

    if (MidiClip* midi = findMidiClip(clipId)) {
        midi->lengthBeats = len;
        return true;
    }
    if (SampleClip* sample = findSampleClip(clipId)) {
        sample->lengthBeats = len;
        return true;
    }
    return false;
}

bool ClipRepository::setClipLoopContent(const std::string& clipId, bool loopContent) {
    if (MidiClip* midi = findMidiClip(clipId)) {
        midi->loopContent = loopContent;
        return true;
    }
    if (SampleClip* sample = findSampleClip(clipId)) {
        sample->loopContent = loopContent;
        return true;
    }
    return false;
}

bool ClipRepository::deleteClip(const std::string& clipId) {
    for (auto& track : tracks_.tracks()) {
        for (auto it = track.midiClips.begin(); it != track.midiClips.end(); ++it) {
            if (it->id == clipId) {
                track.midiClips.erase(it);
                return true;
            }
        }
        for (auto it = track.sampleClips.begin(); it != track.sampleClips.end(); ++it) {
            if (it->id == clipId) {
                track.sampleClips.erase(it);
                return true;
            }
        }
    }
    return false;
}

bool ClipRepository::duplicateClip(const std::string& clipId) {
    for (auto& track : tracks_.tracks()) {
        for (const auto& clip : track.midiClips) {
            if (clip.id != clipId) {
                continue;
            }
            MidiClip copy = clip;
            copy.id = "clip-" + std::to_string(nextClipNum_++);
            copy.startBeat = clip.startBeat + clip.lengthBeats;
            track.midiClips.push_back(std::move(copy));
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
            return true;
        }
    }
    return false;
}

MidiClip* ClipRepository::findMidiClip(const std::string& clipId) {
    for (auto& track : tracks_.tracks()) {
        for (auto& clip : track.midiClips) {
            if (clip.id == clipId) {
                return &clip;
            }
        }
    }
    return nullptr;
}

SampleClip* ClipRepository::findSampleClip(const std::string& clipId) {
    for (auto& track : tracks_.tracks()) {
        for (auto& clip : track.sampleClips) {
            if (clip.id == clipId) {
                return &clip;
            }
        }
    }
    return nullptr;
}

void ClipRepository::recomputeIdCounters() {
    auto maxSuffix = [](const std::string& id, const std::string& prefix) {
        if (id.rfind(prefix, 0) != 0) {
            return 0;
        }
        const auto suffix = id.substr(prefix.size());
        return suffix.empty() ? 0 : std::atoi(suffix.c_str());
    };

    int maxClip = 0;
    int maxSampleClip = 0;
    for (const auto& track : tracks_.tracks()) {
        for (const auto& clip : track.midiClips) {
            maxClip = std::max(maxClip, maxSuffix(clip.id, "clip-"));
        }
        for (const auto& clip : track.sampleClips) {
            maxSampleClip = std::max(maxSampleClip, maxSuffix(clip.id, "sclip-"));
        }
    }
    nextClipNum_ = maxClip + 1;
    nextSampleClipNum_ = maxSampleClip + 1;
}

} // namespace audioapp
