#include "audioapp/model/ClipRepository.hpp"

#include <algorithm>

#include "audioapp/ClipContentPlayback.hpp"

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <utility>

namespace audioapp {

namespace {

constexpr double kMinTakeRegionBeats = 0.001;

void normalizeCompRegions(SampleClip& clip) {
    auto& regions = clip.activeTakeRegions;
    regions.erase(std::remove_if(regions.begin(), regions.end(),
                                 [](const SampleClipTakeRegion& region) {
                                     return region.endBeat <= region.startBeat + kMinTakeRegionBeats;
                                 }),
                  regions.end());
    std::sort(regions.begin(), regions.end(), [](const auto& a, const auto& b) {
        return a.startBeat < b.startBeat;
    });

    std::vector<SampleClipTakeRegion> merged;
    merged.reserve(regions.size());
    for (const auto& region : regions) {
        if (!merged.empty() && merged.back().takeId == region.takeId &&
            std::abs(merged.back().endBeat - region.startBeat) <= kMinTakeRegionBeats &&
            std::abs((merged.back().sourceStart + (merged.back().endBeat - merged.back().startBeat)) -
                     region.sourceStart) <= kMinTakeRegionBeats) {
            merged.back().endBeat = region.endBeat;
            continue;
        }
        merged.push_back(region);
    }
    regions = std::move(merged);
}

void replaceCompRegion(SampleClip& clip,
                       const std::string& takeId,
                       double startBeat,
                       double endBeat,
                       double sourceStart) {
    const double start = std::clamp(startBeat, 0.0, clip.lengthBeats);
    const double end = std::clamp(endBeat, start, clip.lengthBeats);
    if (end <= start + 0.001) {
        return;
    }

    std::vector<SampleClipTakeRegion> next;
    next.reserve(clip.activeTakeRegions.size() + 2);
    for (const auto& region : clip.activeTakeRegions) {
        if (region.endBeat <= start || region.startBeat >= end) {
            next.push_back(region);
            continue;
        }
        if (region.startBeat < start) {
            auto left = region;
            left.endBeat = start;
            next.push_back(left);
        }
        if (region.endBeat > end) {
            auto right = region;
            right.startBeat = end;
            right.sourceStart += end - region.startBeat;
            next.push_back(right);
        }
    }

    SampleClipTakeRegion inserted;
    inserted.startBeat = start;
    inserted.endBeat = end;
    inserted.takeId = takeId;
    inserted.sourceStart = sourceStart;
    next.push_back(inserted);
    std::sort(next.begin(), next.end(), [](const auto& a, const auto& b) {
        return a.startBeat < b.startBeat;
    });
    clip.activeTakeRegions = std::move(next);
    normalizeCompRegions(clip);
}

} // namespace

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
    SampleClipTake take;
    take.id = clip.id + "-take-1";
    take.sampleId = sampleId;
    take.name = "Take 1";
    take.lengthBeats = clip.naturalLengthBeats;
    clip.takes.push_back(take);
    SampleClipTakeRegion region;
    region.startBeat = 0.0;
    region.endBeat = clip.lengthBeats;
    region.takeId = take.id;
    clip.activeTakeRegions.push_back(region);

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
    if (!clip->takes.empty()) {
        clip->takes.front().lengthBeats = len;
    }
    if (!clip->activeTakeRegions.empty()) {
        clip->activeTakeRegions.front().startBeat = 0.0;
        clip->activeTakeRegions.front().endBeat = len;
        if (clip->activeTakeRegions.front().takeId.empty() && !clip->takes.empty()) {
            clip->activeTakeRegions.front().takeId = clip->takes.front().id;
        }
    }
    return true;
}

bool ClipRepository::addSampleClipTake(const std::string& clipId,
                                       const std::string& sampleId,
                                       const std::string& name,
                                       double startBeatOffset,
                                       double lengthBeats) {
    auto* clip = findSampleClip(clipId);
    if (clip == nullptr || sampleId.empty()) {
        return false;
    }
    const double offset = std::clamp(startBeatOffset, 0.0, clip->lengthBeats);
    const double len = lengthBeats < kMinClipLengthBeats ? kMinClipLengthBeats : lengthBeats;
    SampleClipTake take;
    take.id = clip->id + "-take-" + std::to_string(clip->takes.size() + 1);
    take.sampleId = sampleId;
    take.name = name.empty() ? ("Take " + std::to_string(clip->takes.size() + 1)) : name;
    take.startBeatOffset = offset;
    take.lengthBeats = len;
    clip->takes.push_back(take);

    replaceCompRegion(*clip, take.id, offset, offset + len, 0.0);
    return true;
}

bool ClipRepository::updateSampleClipRecordedTakeLength(const std::string& clipId,
                                                        const std::string& sampleId,
                                                        double lengthBeats) {
    auto* clip = findSampleClip(clipId);
    if (clip == nullptr || sampleId.empty()) {
        return false;
    }
    const double len = lengthBeats < kMinClipLengthBeats ? kMinClipLengthBeats : lengthBeats;
    if (clip->sampleId == sampleId) {
        return updateSampleClipRecordedLength(clipId, len);
    }
    for (auto& take : clip->takes) {
        if (take.sampleId != sampleId) {
            continue;
        }
        take.lengthBeats = len;
        replaceCompRegion(*clip, take.id, take.startBeatOffset,
                          take.startBeatOffset + len, 0.0);
        return true;
    }
    return false;
}

bool ClipRepository::removeSampleClipTake(const std::string& clipId,
                                          const std::string& sampleId) {
    auto* clip = findSampleClip(clipId);
    if (clip == nullptr || sampleId.empty() || clip->sampleId == sampleId) {
        return false;
    }
    std::string takeId;
    std::string fallbackTakeId;
    if (!clip->takes.empty()) {
        fallbackTakeId = clip->takes.front().id;
    }
    for (auto it = clip->takes.begin(); it != clip->takes.end(); ++it) {
        if (it->sampleId == sampleId) {
            takeId = it->id;
            clip->takes.erase(it);
            break;
        }
    }
    if (takeId.empty()) {
        return false;
    }
    std::vector<SampleClipTakeRegion> removedRegions;
    for (const auto& region : clip->activeTakeRegions) {
        if (region.takeId == takeId) {
            removedRegions.push_back(region);
        }
    }
    clip->activeTakeRegions.erase(
        std::remove_if(clip->activeTakeRegions.begin(), clip->activeTakeRegions.end(),
                       [&](const SampleClipTakeRegion& region) { return region.takeId == takeId; }),
        clip->activeTakeRegions.end());
    if (!fallbackTakeId.empty()) {
        for (const auto& region : removedRegions) {
            replaceCompRegion(*clip, fallbackTakeId, region.startBeat, region.endBeat,
                              region.startBeat);
        }
    }
    return true;
}

bool ClipRepository::setSampleClipTakeRegionTake(const std::string& clipId,
                                                 int regionIndex,
                                                 const std::string& takeId) {
    auto* clip = findSampleClip(clipId);
    if (clip == nullptr || regionIndex < 0 ||
        regionIndex >= static_cast<int>(clip->activeTakeRegions.size())) {
        return false;
    }
    const auto take = std::find_if(clip->takes.begin(), clip->takes.end(),
                                   [&](const SampleClipTake& candidate) {
                                       return candidate.id == takeId;
                                   });
    if (take == clip->takes.end()) {
        return false;
    }
    auto& region = clip->activeTakeRegions[static_cast<size_t>(regionIndex)];
    region.takeId = takeId;
    region.sourceStart = std::max(0.0, region.startBeat - take->startBeatOffset);
    if (take->lengthBeats > 0.0) {
        region.sourceStart = std::min(region.sourceStart, take->lengthBeats);
    }
    normalizeCompRegions(*clip);
    return true;
}

bool ClipRepository::setSampleClipTakeAtBeat(const std::string& clipId,
                                             double beat,
                                             const std::string& takeId) {
    auto* clip = findSampleClip(clipId);
    if (clip == nullptr || takeId.empty()) {
        return false;
    }
    const auto take = std::find_if(clip->takes.begin(), clip->takes.end(),
                                   [&](const SampleClipTake& candidate) {
                                       return candidate.id == takeId;
                                   });
    if (take == clip->takes.end()) {
        return false;
    }
    const double localBeat = std::clamp(beat, 0.0, clip->lengthBeats);
    for (auto it = clip->activeTakeRegions.begin(); it != clip->activeTakeRegions.end(); ++it) {
        if (localBeat < it->startBeat || localBeat >= it->endBeat) {
            continue;
        }
        if (takeId == it->takeId && localBeat <= it->startBeat + 0.001) {
            return true;
        }
        const auto oldRegion = *it;
        const auto insertIndex = static_cast<size_t>(std::distance(clip->activeTakeRegions.begin(), it));
        if (localBeat <= oldRegion.startBeat + 0.001) {
            clip->activeTakeRegions[insertIndex].takeId = takeId;
            clip->activeTakeRegions[insertIndex].sourceStart =
                std::clamp(localBeat - take->startBeatOffset, 0.0, take->lengthBeats);
            normalizeCompRegions(*clip);
            return true;
        }
        SampleClipTakeRegion right = oldRegion;
        right.startBeat = localBeat;
        right.takeId = takeId;
        right.sourceStart = std::clamp(localBeat - take->startBeatOffset, 0.0, take->lengthBeats);
        clip->activeTakeRegions[insertIndex].endBeat = localBeat;
        clip->activeTakeRegions.insert(clip->activeTakeRegions.begin() +
                                           static_cast<std::ptrdiff_t>(insertIndex + 1),
                                       right);
        normalizeCompRegions(*clip);
        return true;
    }
    replaceCompRegion(*clip, takeId, localBeat, clip->lengthBeats,
                      std::clamp(localBeat - take->startBeatOffset, 0.0, take->lengthBeats));
    return true;
}

bool ClipRepository::splitSampleClipTakeRegionAtBeat(const std::string& clipId,
                                                     double beat) {
    auto* clip = findSampleClip(clipId);
    if (clip == nullptr) {
        return false;
    }
    const double localBeat = std::clamp(beat, 0.0, clip->lengthBeats);
    for (auto it = clip->activeTakeRegions.begin(); it != clip->activeTakeRegions.end(); ++it) {
        if (localBeat <= it->startBeat + kMinTakeRegionBeats ||
            localBeat >= it->endBeat - kMinTakeRegionBeats) {
            continue;
        }
        const auto insertIndex = static_cast<size_t>(std::distance(clip->activeTakeRegions.begin(), it));
        SampleClipTakeRegion right = *it;
        right.startBeat = localBeat;
        right.sourceStart += localBeat - it->startBeat;
        clip->activeTakeRegions[insertIndex].endBeat = localBeat;
        clip->activeTakeRegions.insert(clip->activeTakeRegions.begin() +
                                           static_cast<std::ptrdiff_t>(insertIndex + 1),
                                       right);
        return true;
    }
    return false;
}

bool ClipRepository::moveSampleClipTakeMarker(const std::string& clipId,
                                              int markerIndex,
                                              double beat) {
    auto* clip = findSampleClip(clipId);
    const int rightIndex = markerIndex + 1;
    if (clip == nullptr || markerIndex < 0 ||
        rightIndex >= static_cast<int>(clip->activeTakeRegions.size())) {
        return false;
    }
    auto& left = clip->activeTakeRegions[static_cast<size_t>(markerIndex)];
    auto& right = clip->activeTakeRegions[static_cast<size_t>(rightIndex)];
    const double minimum = left.startBeat + kMinTakeRegionBeats;
    const double maximum = right.endBeat - kMinTakeRegionBeats;
    if (maximum <= minimum) {
        return false;
    }
    const double oldRightStart = right.startBeat;
    const double nextBeat = std::clamp(beat, minimum, maximum);
    left.endBeat = nextBeat;
    right.startBeat = nextBeat;
    right.sourceStart += nextBeat - oldRightStart;
    return true;
}

bool ClipRepository::deleteSampleClipTakeMarker(const std::string& clipId,
                                                int markerIndex) {
    auto* clip = findSampleClip(clipId);
    const int rightIndex = markerIndex + 1;
    if (clip == nullptr || markerIndex < 0 ||
        rightIndex >= static_cast<int>(clip->activeTakeRegions.size())) {
        return false;
    }
    auto& left = clip->activeTakeRegions[static_cast<size_t>(markerIndex)];
    const auto& right = clip->activeTakeRegions[static_cast<size_t>(rightIndex)];
    left.endBeat = right.endBeat;
    clip->activeTakeRegions.erase(clip->activeTakeRegions.begin() + rightIndex);
    normalizeCompRegions(*clip);
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
