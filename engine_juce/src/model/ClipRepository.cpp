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

void normalizeMidiCompRegions(MidiClip& clip) {
    auto& regions = clip.activeTakeRegions;
    regions.erase(std::remove_if(regions.begin(), regions.end(),
                                 [](const MidiClipTakeRegion& region) {
                                     return region.endBeat <= region.startBeat + kMinTakeRegionBeats;
                                 }),
                  regions.end());
    std::sort(regions.begin(), regions.end(), [](const auto& a, const auto& b) {
        return a.startBeat < b.startBeat;
    });
}

void rebuildMidiCompNotes(MidiClip& clip) {
    // Once flattened, `notes` is authoritative and hand-editable; the comp
    // derivation must not overwrite the user's manual edits.
    if (clip.compFlattened) {
        return;
    }
    if (clip.takes.empty() || clip.activeTakeRegions.empty()) {
        return;
    }
    const auto& regions = clip.activeTakeRegions;

    // First comp-time boundary strictly after [beat] that is marked Cut.
    // A ringing note is truncated at the earliest such boundary (or clip end).
    const auto firstCutBoundaryAfter = [&](double beat) {
        double limit = clip.lengthBeats;
        for (const auto& r : regions) {
            if (r.startBeat > beat + kMinTakeRegionBeats && !r.holdPrevious) {
                limit = std::min(limit, r.startBeat);
                break;
            }
        }
        return limit;
    };

    std::vector<MidiNote> notes;
    for (const auto& region : regions) {
        const auto take = std::find_if(clip.takes.begin(), clip.takes.end(),
                                       [&](const MidiClipTake& candidate) {
                                           return candidate.id == region.takeId;
                                       });
        if (take == clip.takes.end()) {
            continue;
        }
        const double regionLength = region.endBeat - region.startBeat;
        const double srcStart = region.sourceStart;
        const double srcEnd = region.sourceStart + regionLength;
        for (const auto& note : take->notes) {
            const double noteStart = note.startBeat;
            // Onset ownership: a note belongs to the region whose source
            // window contains its onset. Prevents duplication and honors the
            // performance the user chose up to each boundary.
            if (noteStart < srcStart || noteStart >= srcEnd) {
                continue;
            }
            const double noteEnd = noteStart + note.durationBeats;
            MidiNote out = note;
            out.startBeat = region.startBeat + (noteStart - srcStart);
            const double naturalEnd = region.startBeat + (noteEnd - srcStart);
            // Cut boundary => truncate at region end; Ring => let it ring to
            // the natural end, clamped at the first subsequent Cut boundary.
            const double limit = firstCutBoundaryAfter(out.startBeat);
            const double outEnd = std::min(naturalEnd, limit);
            out.durationBeats = std::max(0.01, outEnd - out.startBeat);
            notes.push_back(out);
        }
    }

    std::sort(notes.begin(), notes.end(), [](const auto& a, const auto& b) {
        if (a.startBeat != b.startBeat) return a.startBeat < b.startBeat;
        return a.pitch < b.pitch;
    });

    // Same-pitch overlap resolution: trim an earlier note so it ends just
    // before the next note of the same pitch begins (avoids stuck notes when
    // a ringing note collides with the incoming take).
    for (size_t a = 0; a < notes.size(); ++a) {
        const double aEnd = notes[a].startBeat + notes[a].durationBeats;
        for (size_t b = a + 1; b < notes.size(); ++b) {
            if (notes[b].startBeat >= aEnd) {
                break;
            }
            if (notes[b].pitch == notes[a].pitch) {
                const double trimmed = notes[b].startBeat - 0.001;
                notes[a].durationBeats =
                    std::max(0.01, trimmed - notes[a].startBeat);
                break;
            }
        }
    }

    clip.notes = std::move(notes);
}

std::string nextCompTakeName(const MidiClip& clip) {
    int maxN = 0;
    for (const auto& take : clip.takes) {
        if (take.name.size() >= 5 && take.name.compare(0, 5, "Comp ") == 0) {
            const auto suffix = take.name.substr(5);
            char* end = nullptr;
            const long n = std::strtol(suffix.c_str(), &end, 10);
            if (end != suffix.c_str() && *end == '\0' && n > maxN) {
                maxN = static_cast<int>(n);
            }
        }
    }
    return "Comp " + std::to_string(maxN + 1);
}

void archiveFlattenedNotesAsTake(MidiClip& clip) {
    if (clip.notes.empty()) {
        return;
    }
    size_t compTakeCount = 0;
    for (const auto& take : clip.takes) {
        if (take.name.size() >= 5 && take.name.compare(0, 5, "Comp ") == 0) {
            ++compTakeCount;
        }
    }
    MidiClipTake take;
    take.id = clip.id + "-comp-" + std::to_string(compTakeCount + 1);
    take.name = nextCompTakeName(clip);
    take.lengthBeats = clip.naturalLengthBeats > 0.0
        ? clip.naturalLengthBeats : clip.lengthBeats;
    take.notes = clip.notes;
    clip.takes.push_back(std::move(take));
}

void replaceMidiCompRegion(MidiClip& clip,
                           const std::string& takeId,
                           double startBeat,
                           double endBeat,
                           double sourceStart) {
    const double start = std::clamp(startBeat, 0.0, clip.lengthBeats);
    const double end = std::clamp(endBeat, start, clip.lengthBeats);
    if (end <= start + kMinTakeRegionBeats) {
        return;
    }

    std::vector<MidiClipTakeRegion> next;
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

    MidiClipTakeRegion inserted;
    inserted.startBeat = start;
    inserted.endBeat = end;
    inserted.takeId = takeId;
    inserted.sourceStart = sourceStart;
    next.push_back(inserted);
    clip.activeTakeRegions = std::move(next);
    normalizeMidiCompRegions(clip);
    rebuildMidiCompNotes(clip);
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
    MidiClipTake take;
    take.id = clip.id + "-take-1";
    take.name = "Take 1";
    take.lengthBeats = clip.naturalLengthBeats;
    take.notes.push_back(seed);
    clip.takes.push_back(take);
    MidiClipTakeRegion region;
    region.startBeat = 0.0;
    region.endBeat = clip.lengthBeats;
    region.takeId = take.id;
    clip.activeTakeRegions.push_back(region);

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
    if (clip->takes.size() <= 1) {
        if (clip->takes.empty()) {
            MidiClipTake take;
            take.id = clip->id + "-take-1";
            take.name = "Take 1";
            clip->takes.push_back(take);
        }
        clip->takes.front().lengthBeats = clip->naturalLengthBeats;
        clip->takes.front().notes = clip->notes;
        clip->activeTakeRegions.clear();
        MidiClipTakeRegion region;
        region.startBeat = 0.0;
        region.endBeat = clip->lengthBeats;
        region.takeId = clip->takes.front().id;
        clip->activeTakeRegions.push_back(region);
    } else if (!clip->compFlattened) {
        // Hand-editing a multi-take comp is destructive; auto-flatten so later
        // comp ops cannot silently overwrite the user's notes.
        clip->compFlattened = true;
    }
    return true;
}

bool ClipRepository::addMidiClipTake(const std::string& clipId,
                                     const std::string& name,
                                     double startBeatOffset,
                                     double lengthBeats,
                                     const std::vector<MidiNoteState>& notes) {
    auto* clip = findMidiClip(clipId);
    if (clip == nullptr) {
        return false;
    }
    if (clip->takes.empty()) {
        MidiClipTake original;
        original.id = clip->id + "-take-1";
        original.name = "Take 1";
        original.lengthBeats = clip->naturalLengthBeats > 0.0
            ? clip->naturalLengthBeats : clip->lengthBeats;
        original.notes = clip->notes;
        clip->takes.push_back(original);
        MidiClipTakeRegion region;
        region.startBeat = 0.0;
        region.endBeat = clip->lengthBeats;
        region.takeId = original.id;
        clip->activeTakeRegions.push_back(region);
    }
    const double offset = std::clamp(startBeatOffset, 0.0, clip->lengthBeats);
    const double len = lengthBeats < kMinClipLengthBeats ? kMinClipLengthBeats : lengthBeats;
    if (clip->takes.size() == 1 && clip->takes.front().notes.empty()) {
        auto& firstTake = clip->takes.front();
        firstTake.name = name.empty() ? "Take 1" : name;
        firstTake.startBeatOffset = offset;
        firstTake.lengthBeats = len;
        firstTake.notes.clear();
        firstTake.notes.reserve(notes.size());
        for (const auto& note : notes) {
            MidiNote stored;
            stored.pitch = note.pitch;
            stored.startBeat = std::max(0.0, note.startBeat);
            stored.durationBeats = note.durationBeats > 0.0 ? note.durationBeats : 0.25;
            stored.velocity = note.velocity;
            firstTake.notes.push_back(stored);
        }
        replaceMidiCompRegion(*clip, firstTake.id, offset, offset + len, 0.0);
        const double takeEnd = offset + len;
        if (takeEnd > clip->naturalLengthBeats) {
            clip->naturalLengthBeats = takeEnd;
        }
        return true;
    }
    MidiClipTake take;
    take.id = clip->id + "-take-" + std::to_string(clip->takes.size() + 1);
    take.name = name.empty() ? ("Take " + std::to_string(clip->takes.size() + 1)) : name;
    take.startBeatOffset = offset;
    take.lengthBeats = len;
    take.notes.reserve(notes.size());
    for (const auto& note : notes) {
        MidiNote stored;
        stored.pitch = note.pitch;
        stored.startBeat = std::max(0.0, note.startBeat);
        stored.durationBeats = note.durationBeats > 0.0 ? note.durationBeats : 0.25;
        stored.velocity = note.velocity;
        take.notes.push_back(stored);
    }
    clip->takes.push_back(take);
    replaceMidiCompRegion(*clip, take.id, offset, offset + len, 0.0);
    const double takeEnd = offset + len;
    if (takeEnd > clip->naturalLengthBeats) {
        clip->naturalLengthBeats = takeEnd;
    }
    return true;
}

bool ClipRepository::setMidiClipTakeRegionTake(const std::string& clipId,
                                               int regionIndex,
                                               const std::string& takeId) {
    auto* clip = findMidiClip(clipId);
    if (clip == nullptr || regionIndex < 0 ||
        regionIndex >= static_cast<int>(clip->activeTakeRegions.size())) {
        return false;
    }
    const auto take = std::find_if(clip->takes.begin(), clip->takes.end(),
                                   [&](const MidiClipTake& candidate) {
                                       return candidate.id == takeId;
                                   });
    if (take == clip->takes.end()) {
        return false;
    }
    auto& region = clip->activeTakeRegions[static_cast<size_t>(regionIndex)];
    region.takeId = takeId;
    region.sourceStart = std::clamp(region.startBeat - take->startBeatOffset,
                                    0.0, take->lengthBeats);
    normalizeMidiCompRegions(*clip);
    rebuildMidiCompNotes(*clip);
    return true;
}

bool ClipRepository::setMidiClipTakeAtBeat(const std::string& clipId,
                                           double beat,
                                           const std::string& takeId) {
    auto* clip = findMidiClip(clipId);
    if (clip == nullptr || takeId.empty()) {
        return false;
    }
    const auto take = std::find_if(clip->takes.begin(), clip->takes.end(),
                                   [&](const MidiClipTake& candidate) {
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
        if (takeId == it->takeId && localBeat <= it->startBeat + kMinTakeRegionBeats) {
            return true;
        }
        const auto oldRegion = *it;
        const auto insertIndex = static_cast<size_t>(
            std::distance(clip->activeTakeRegions.begin(), it));
        if (localBeat <= oldRegion.startBeat + kMinTakeRegionBeats) {
            clip->activeTakeRegions[insertIndex].takeId = takeId;
            clip->activeTakeRegions[insertIndex].sourceStart =
                std::clamp(localBeat - take->startBeatOffset, 0.0, take->lengthBeats);
            normalizeMidiCompRegions(*clip);
            rebuildMidiCompNotes(*clip);
            return true;
        }
        MidiClipTakeRegion right = oldRegion;
        right.startBeat = localBeat;
        right.takeId = takeId;
        right.holdPrevious = true;
        right.sourceStart =
            std::clamp(localBeat - take->startBeatOffset, 0.0, take->lengthBeats);
        clip->activeTakeRegions[insertIndex].endBeat = localBeat;
        clip->activeTakeRegions.insert(clip->activeTakeRegions.begin() +
                                           static_cast<std::ptrdiff_t>(insertIndex + 1),
                                       right);
        normalizeMidiCompRegions(*clip);
        rebuildMidiCompNotes(*clip);
        return true;
    }
    replaceMidiCompRegion(*clip, takeId, localBeat, clip->lengthBeats,
                          std::clamp(localBeat - take->startBeatOffset, 0.0, take->lengthBeats));
    return true;
}

bool ClipRepository::splitMidiClipTakeRegionAtBeat(const std::string& clipId,
                                                   double beat) {
    auto* clip = findMidiClip(clipId);
    if (clip == nullptr) {
        return false;
    }
    const double localBeat = std::clamp(beat, 0.0, clip->lengthBeats);
    for (auto it = clip->activeTakeRegions.begin(); it != clip->activeTakeRegions.end(); ++it) {
        if (localBeat <= it->startBeat + kMinTakeRegionBeats ||
            localBeat >= it->endBeat - kMinTakeRegionBeats) {
            continue;
        }
        const auto insertIndex = static_cast<size_t>(
            std::distance(clip->activeTakeRegions.begin(), it));
        MidiClipTakeRegion right = *it;
        right.startBeat = localBeat;
        right.holdPrevious = true;
        right.sourceStart += localBeat - it->startBeat;
        clip->activeTakeRegions[insertIndex].endBeat = localBeat;
        clip->activeTakeRegions.insert(clip->activeTakeRegions.begin() +
                                           static_cast<std::ptrdiff_t>(insertIndex + 1),
                                       right);
        rebuildMidiCompNotes(*clip);
        return true;
    }
    return false;
}

bool ClipRepository::moveMidiClipTakeMarker(const std::string& clipId,
                                            int markerIndex,
                                            double beat) {
    auto* clip = findMidiClip(clipId);
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
    rebuildMidiCompNotes(*clip);
    return true;
}

bool ClipRepository::setMidiClipTakeMarkerMode(const std::string& clipId,
                                               int markerIndex,
                                               bool holdPrevious) {
    auto* clip = findMidiClip(clipId);
    const int rightIndex = markerIndex + 1;
    if (clip == nullptr || markerIndex < 0 ||
        rightIndex >= static_cast<int>(clip->activeTakeRegions.size())) {
        return false;
    }
    // markerIndex indexes boundaries (regions after the first); the boundary
    // is the start of the region to its right.
    clip->activeTakeRegions[static_cast<size_t>(rightIndex)].holdPrevious =
        holdPrevious;
    rebuildMidiCompNotes(*clip);
    return true;
}

bool ClipRepository::flattenMidiComp(const std::string& clipId) {
    auto* clip = findMidiClip(clipId);
    if (clip == nullptr) {
        return false;
    }
    // `clip->notes` already holds the latest comp result (rebuilt on every comp
    // edit). Freeze it as authoritative, hand-editable content; recorded takes
    // and regions are kept so the comp can be re-opened later.
    clip->compFlattened = true;
    return true;
}

bool ClipRepository::reopenMidiComp(const std::string& clipId) {
    auto* clip = findMidiClip(clipId);
    if (clip == nullptr) {
        return false;
    }
    if (clip->compFlattened) {
        // Preserve manual edits as an archived take before re-deriving.
        archiveFlattenedNotesAsTake(*clip);
    }
    clip->compFlattened = false;
    rebuildMidiCompNotes(*clip);
    return true;
}

bool ClipRepository::deleteMidiClipTakeMarker(const std::string& clipId,
                                              int markerIndex) {
    auto* clip = findMidiClip(clipId);
    const int rightIndex = markerIndex + 1;
    if (clip == nullptr || markerIndex < 0 ||
        rightIndex >= static_cast<int>(clip->activeTakeRegions.size())) {
        return false;
    }
    auto& left = clip->activeTakeRegions[static_cast<size_t>(markerIndex)];
    const auto& right = clip->activeTakeRegions[static_cast<size_t>(rightIndex)];
    left.endBeat = right.endBeat;
    clip->activeTakeRegions.erase(clip->activeTakeRegions.begin() + rightIndex);
    normalizeMidiCompRegions(*clip);
    rebuildMidiCompNotes(*clip);
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
