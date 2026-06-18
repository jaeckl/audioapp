#pragma once

#include "audioapp/MidiClipPlayback.hpp"
#include "audioapp/SampleBank.hpp"
#include "audioapp/TimelineClipTypes.hpp"
#include "audioapp/model/TrackRepository.hpp"

#include <string>
#include <vector>

namespace audioapp {

class ClipRepository {
public:
    explicit ClipRepository(TrackRepository& tracks);

    std::string createMidiClip(const std::string& trackId, double startBeat, double lengthBeats);
    bool setMidiClipNotes(const std::string& clipId, const std::vector<MidiNoteState>& notes);
    std::string createSampleClip(const std::string& trackId,
                                 const std::string& sampleId,
                                 double startBeat,
                                 double lengthBeats,
                                 const SampleBank* sampleBank,
                                 int bpm);
    bool moveClip(const std::string& clipId,
                  const std::string& targetTrackId,
                  double startBeat);
    bool setClipLength(const std::string& clipId, double lengthBeats);
    bool deleteClip(const std::string& clipId);
    bool duplicateClip(const std::string& clipId);

    MidiClip* findMidiClip(const std::string& clipId);
    SampleClip* findSampleClip(const std::string& clipId);

    void recomputeIdCounters();
    void clear();

private:
    TrackRepository& tracks_;
    int nextClipNum_ = 1;
    int nextSampleClipNum_ = 1;
};

} // namespace audioapp
