#pragma once

#include "audioapp/AutomationTypes.hpp"
#include "audioapp/MidiClipPlayback.hpp"
#include "audioapp/SampleBank.hpp"
#include "audioapp/SampleTypes.hpp"
#include "audioapp/TimelineClipTypes.hpp"
#include "audioapp/model/TrackModel.hpp"
#include "audioapp/model/TrackRepository.hpp"

#include <string>
#include <vector>

namespace audioapp {

/// Owns MIDI and sample clip CRUD per track. Automation clips live in
/// `AutomationClipStore` (project-global) since they are device-targeted.
class ClipRepository {
public:
    explicit ClipRepository(TrackRepository& tracks);

    std::string createMidiClip(const std::string& trackId, double startBeat, double lengthBeats);
    bool setMidiClipNotes(const std::string& clipId, const std::vector<MidiNoteState>& notes);
    bool addMidiClipTake(const std::string& clipId,
                         const std::string& name,
                         double startBeatOffset,
                         double lengthBeats,
                         const std::vector<MidiNoteState>& notes);
    bool setMidiClipTakeRegionTake(const std::string& clipId,
                                   int regionIndex,
                                   const std::string& takeId);
    bool setMidiClipTakeAtBeat(const std::string& clipId,
                               double beat,
                               const std::string& takeId);
    bool splitMidiClipTakeRegionAtBeat(const std::string& clipId,
                                       double beat);
    bool moveMidiClipTakeMarker(const std::string& clipId,
                                int markerIndex,
                                double beat);
    bool setMidiClipTakeMarkerMode(const std::string& clipId,
                                   int markerIndex,
                                   bool holdPrevious);
    bool deleteMidiClipTakeMarker(const std::string& clipId,
                                  int markerIndex);
    bool flattenMidiComp(const std::string& clipId);
    bool reopenMidiComp(const std::string& clipId);
    bool setMidiClipEditorScale(const std::string& clipId,
                                int root,
                                const std::string& scaleId,
                                bool highlight,
                                bool snap,
                                const std::string& chordQuality);
    std::string createSampleClip(const std::string& trackId,
                                 const std::string& sampleId,
                                 double startBeat,
                                 double lengthBeats,
                                 const SampleBank* sampleBank,
                                 int bpm);

    bool moveClip(const std::string& clipId, const std::string& targetTrackId, double startBeat);
    bool setClipLength(const std::string& clipId,
                       double lengthBeats,
                       ClipLengthTarget target = ClipLengthTarget::Arrangement);
    bool setClipLoopContent(const std::string& clipId, bool loopContent);
    bool setSampleClipProperties(const std::string& clipId, float sourceStart,
                                 float sourceEnd, float gain, float fadeIn,
                                 float fadeOut, float fadeInCurve,
                                 float fadeOutCurve, bool reversed);
    bool setSampleClipWarp(const std::string& clipId, bool warpRepitch);
    bool setSampleClipSlices(const std::string& clipId, const std::vector<float>& markers);
    bool updateSampleClipRecordedLength(const std::string& clipId, double lengthBeats);
    bool addSampleClipTake(const std::string& clipId,
                           const std::string& sampleId,
                           const std::string& name,
                           double startBeatOffset,
                           double lengthBeats);
    bool updateSampleClipRecordedTakeLength(const std::string& clipId,
                                            const std::string& sampleId,
                                            double lengthBeats);
    bool removeSampleClipTake(const std::string& clipId, const std::string& sampleId);
    bool setSampleClipTakeRegionTake(const std::string& clipId,
                                     int regionIndex,
                                     const std::string& takeId);
    bool setSampleClipTakeAtBeat(const std::string& clipId,
                                 double beat,
                                 const std::string& takeId);
    bool splitSampleClipTakeRegionAtBeat(const std::string& clipId,
                                         double beat);
    bool moveSampleClipTakeMarker(const std::string& clipId,
                                  int markerIndex,
                                  double beat);
    bool deleteSampleClipTakeMarker(const std::string& clipId,
                                    int markerIndex);
    bool deleteClip(const std::string& clipId);
    bool duplicateClip(const std::string& clipId);

    MidiClip* findMidiClip(const std::string& clipId);
    SampleClip* findSampleClip(const std::string& clipId);

    /// Virtual master bus clips (id "master") — not in TrackRepository.
    std::vector<MidiClip>& masterMidiClips() { return masterMidiClips_; }
    std::vector<SampleClip>& masterSampleClips() { return masterSampleClips_; }
    const std::vector<MidiClip>& masterMidiClips() const { return masterMidiClips_; }
    const std::vector<SampleClip>& masterSampleClips() const {
        return masterSampleClips_;
    }

    void recomputeIdCounters();
    void clear();

private:
    TrackRepository& tracks_;
    std::vector<MidiClip> masterMidiClips_;
    std::vector<SampleClip> masterSampleClips_;
    int nextClipNum_ = 1;
    int nextSampleClipNum_ = 1;
};

} // namespace audioapp
