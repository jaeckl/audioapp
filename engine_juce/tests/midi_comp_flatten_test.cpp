#include <juce_core/juce_core.h>
#include "audioapp/ProjectEngine.hpp"

#include <optional>

namespace {

const audioapp::MidiClipState* findMidiClip(const audioapp::ProjectSnapshot& snap,
                                            const std::string& clipId) {
    for (const auto& track : snap.tracks) {
        for (const auto& clip : track.midiClips) {
            if (clip.id == clipId) {
                return &clip;
            }
        }
    }
    return nullptr;
}

std::string secondTakeId(const audioapp::ProjectSnapshot& snap,
                         const std::string& clipId) {
    const auto* clip = findMidiClip(snap, clipId);
    if (clip == nullptr || clip->takes.size() < 2) {
        return {};
    }
    return clip->takes[1].id;
}

} // namespace

class MidiCompFlattenTest : public juce::UnitTest {
public:
    MidiCompFlattenTest() : juce::UnitTest("MidiCompFlatten", "Project") {}

    void runTest() override
    {
        beginTest("flatten sets compFlattened flag");
        {
            auto project = std::make_unique<audioapp::ProjectEngine>();
            project->createProject();
            const std::string trackId = project->addTrack("Keys");
            const std::string clipId = project->createMidiClip(trackId, 0.0, 8.0);

            std::vector<audioapp::MidiNoteState> take2Notes;
            take2Notes.push_back({64, 0.0, 2.0, 100.0f});
            expect(project->addMidiClipTake(clipId, "Take 2", 0.0, 8.0, take2Notes));

            expect(project->flattenMidiComp(clipId));
            const auto* clip = findMidiClip(project->snapshot(), clipId);
            expect(clip != nullptr);
            if (clip == nullptr) return;
            expect(clip->compFlattened, "flatten should set compFlattened");
        }

        beginTest("flattened comp ignores rebuild on region change");
        {
            auto project = std::make_unique<audioapp::ProjectEngine>();
            project->createProject();
            const std::string trackId = project->addTrack("Keys");
            const std::string clipId = project->createMidiClip(trackId, 0.0, 8.0);

            std::vector<audioapp::MidiNoteState> take2Notes;
            take2Notes.push_back({64, 0.0, 2.0, 100.0f});
            expect(project->addMidiClipTake(clipId, "Take 2", 0.0, 8.0, take2Notes));

            expect(project->flattenMidiComp(clipId));

            std::vector<audioapp::MidiNoteState> edited;
            edited.push_back({88, 1.0, 1.0, 100.0f});
            expect(project->setMidiClipNotes(clipId, edited));

            const auto take2Id = secondTakeId(project->snapshot(), clipId);
            expect(!take2Id.empty());
            expect(project->setMidiClipTakeRegionTake(clipId, 0, take2Id));

            const auto* clip = findMidiClip(project->snapshot(), clipId);
            expect(clip != nullptr);
            if (clip == nullptr) return;
            expectEquals(clip->notes.size(), static_cast<size_t>(1));
            expectEquals(clip->notes[0].pitch, 88, "manual edit should survive comp rebuild");
        }

        beginTest("setMidiClipNotes auto-flattens multi-take clip");
        {
            auto project = std::make_unique<audioapp::ProjectEngine>();
            project->createProject();
            const std::string trackId = project->addTrack("Keys");
            const std::string clipId = project->createMidiClip(trackId, 0.0, 8.0);

            std::vector<audioapp::MidiNoteState> take2Notes;
            take2Notes.push_back({64, 0.0, 2.0, 100.0f});
            expect(project->addMidiClipTake(clipId, "Take 2", 0.0, 8.0, take2Notes));

            std::vector<audioapp::MidiNoteState> edited;
            edited.push_back({72, 0.0, 1.0, 100.0f});
            expect(project->setMidiClipNotes(clipId, edited));

            const auto* clip = findMidiClip(project->snapshot(), clipId);
            expect(clip != nullptr);
            if (clip == nullptr) return;
            expect(clip->compFlattened, "note edit should auto-flatten multi-take clip");
        }

        beginTest("reopen re-derives comp and archives edited notes");
        {
            auto project = std::make_unique<audioapp::ProjectEngine>();
            project->createProject();
            const std::string trackId = project->addTrack("Keys");
            const std::string clipId = project->createMidiClip(trackId, 0.0, 8.0);

            std::vector<audioapp::MidiNoteState> take2Notes;
            take2Notes.push_back({64, 0.0, 2.0, 100.0f});
            expect(project->addMidiClipTake(clipId, "Take 2", 0.0, 8.0, take2Notes));

            const auto take2Id = secondTakeId(project->snapshot(), clipId);
            expect(project->setMidiClipTakeAtBeat(clipId, 4.0, take2Id));

            expect(project->flattenMidiComp(clipId));

            std::vector<audioapp::MidiNoteState> edited;
            edited.push_back({88, 0.0, 8.0, 100.0f});
            expect(project->setMidiClipNotes(clipId, edited));

            expect(project->reopenMidiComp(clipId));

            const auto* clip = findMidiClip(project->snapshot(), clipId);
            expect(clip != nullptr);
            if (clip == nullptr) return;
            expect(!clip->compFlattened, "reopen clears flattened flag");

            bool foundCompTake = false;
            for (const auto& take : clip->takes) {
                if (take.name == "Comp 1") {
                    foundCompTake = true;
                    expectEquals(take.notes.size(), static_cast<size_t>(1));
                    expectEquals(take.notes[0].pitch, 88, "archived comp take keeps edits");
                }
            }
            expect(foundCompTake, "reopen should archive edited notes as Comp 1");
            expect(clip->notes[0].pitch != 88 || clip->notes.size() != 1,
                   "playback notes should re-derive from source takes");
        }
    }
};

static MidiCompFlattenTest midiCompFlattenTest;
