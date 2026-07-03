#include "audioapp/model/ClipRepository.hpp"

#include <algorithm>

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
    if (!clip->loopContent && noteEnd > clip->naturalLengthBeats) {
        clip->naturalLengthBeats = noteEnd;
    }
    return true;
}

bool ClipRepository::setMidiClipEditorScale(const std::string& clipId,
                                            int root,
                                            const std::string& scaleId,
                                            bool highlight,
                                            bool snap,
                                            const std::string& chordQuality) {
    MidiClip* clip = findMidiClip(clipId);
    if (clip == nullptr) {
        return false;
    }
    clip->editorScaleRoot = ((root % 12) + 12) % 12;
    clip->editorScaleId = scaleId.empty() ? "major" : scaleId;
    clip->editorScaleHighlight = highlight;
    clip->editorScaleSnap = snap;
    clip->editorChordQuality = chordQuality.empty() ? "off" : chordQuality;
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

bool ClipRepository::setClipLength(const std::string& clipId,
                                   double lengthBeats,
                                   ClipLengthTarget target) {
    const double len = lengthBeats < kMinClipLengthBeats ? kMinClipLengthBeats : lengthBeats;

    if (MidiClip* midi = findMidiClip(clipId)) {
        if (target == ClipLengthTarget::Content) {
            midi->naturalLengthBeats = len;
        } else {
            midi->lengthBeats = len;
        }
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

bool ClipRepository::setSampleClipProperties(const std::string& clipId,
                                             float sourceStart,
                                             float sourceEnd,
                                             float gain,
                                             float fadeIn,
                                             float fadeOut,
                                             float fadeInCurve,
                                             float fadeOutCurve,
                                             bool reversed) {
    auto* clip = findSampleClip(clipId);
    if (clip == nullptr) return false;
    clip->sourceStart = std::clamp(sourceStart, 0.0f, 0.999f);
    clip->sourceEnd = std::clamp(sourceEnd, clip->sourceStart + 0.001f, 1.0f);
    clip->gain = std::clamp(gain, 0.0f, 4.0f);
    clip->fadeIn = std::clamp(fadeIn, 0.0f, 1.0f);
    clip->fadeOut = std::clamp(fadeOut, 0.0f, 1.0f);
    clip->fadeInCurve = std::clamp(fadeInCurve, 0.0f, 1.0f);
    clip->fadeOutCurve = std::clamp(fadeOutCurve, 0.0f, 1.0f);
    clip->reversed = reversed;
    return true;
}

bool ClipRepository::setSampleClipWarp(const std::string& clipId, bool warpRepitch) {
    auto* clip = findSampleClip(clipId);
    if (clip == nullptr) return false;
    clip->warpRepitch = warpRepitch;
    return true;
}

bool ClipRepository::setSampleClipSlices(const std::string& clipId,
                                         const std::vector<float>& markers) {
    auto* clip = findSampleClip(clipId);
    if (clip == nullptr) return false;
    auto sorted = markers;
    std::sort(sorted.begin(), sorted.end());
    clip->sliceMarkers.clear();
    clip->sliceMarkers.reserve(std::min<size_t>(sorted.size(), 126));
    for (float marker : sorted) {
        const float value = std::clamp(marker, 0.001f, 0.999f);
        if (clip->sliceMarkers.empty() || value - clip->sliceMarkers.back() >= 0.001f)
            clip->sliceMarkers.push_back(value);
    }
    return true;
}

bool ClipRepository::updateSampleClipRecordedLength(const std::string& clipId,
                                                    double lengthBeats) {
    auto* clip = findSampleClip(clipId);
    if (clip == nullptr) {
        return false;
    }
    const double len = lengthBeats < kMinClipLengthBeats ? kMinClipLengthBeats : lengthBeats;
    clip->lengthBeats = len;
    clip->naturalLengthBeats = len;
    return true;
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
