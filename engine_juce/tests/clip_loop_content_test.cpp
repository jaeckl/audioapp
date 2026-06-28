#include <juce_core/juce_core.h>

#include "TestHelpers.h"

#include "audioapp/AutomationPlayback.hpp"

#include "audioapp/ClipContentPlayback.hpp"

#include "audioapp/MidiClipPlayback.hpp"

#include "audioapp/ProjectEngine.hpp"



class ClipLoopContentTest : public juce::UnitTest {

public:

    ClipLoopContentTest() : juce::UnitTest("ClipLoopContent", "Project") {}



    void runTest() override

    {

        beginTest("setClipLoopContent toggles snapshot field");

        {

            auto project = std::make_unique<audioapp::ProjectEngine>();

            project->createProject();



            const std::string trackId = project->addTrack("Keys");

            project->createMidiClip(trackId, 0.0, 8.0);



            const auto snap = project->snapshot();

            expect(!snap.tracks.empty(), "should have tracks");

            if (snap.tracks.empty()) return;

            expect(!snap.tracks[0].midiClips.empty(), "track should have MIDI clips");

            if (snap.tracks[0].midiClips.empty()) return;



            const std::string clipId = snap.tracks[0].midiClips[0].id;

            expect(!snap.tracks[0].midiClips[0].loopContent,

                   "loop content defaults to false");



            expect(project->setClipLoopContent(clipId, true),

                   "setClipLoopContent should succeed");

            expect(project->snapshot().tracks[0].midiClips[0].loopContent,

                   "loop content should be true in snapshot");



            expect(project->setClipLoopContent(clipId, false),

                   "disable loop should succeed");

            expect(!project->snapshot().tracks[0].midiClips[0].loopContent,

                   "loop content should be false again");

        }



        beginTest("looping repeats MIDI content inside longer clip");

        {

            auto project = std::make_unique<audioapp::ProjectEngine>();

            project->createProject();



            const std::string trackId = project->addTrack("Keys");

            project->createMidiClip(trackId, 0.0, 4.0);



            const std::string clipId = project->snapshot().tracks[0].midiClips[0].id;

            std::vector<audioapp::MidiNoteState> notes;

            notes.push_back(audioapp::MidiNoteState{60, 0.0, 4.0, 100.0f});

            expect(project->setMidiClipNotes(clipId, notes), "set notes");

            expect(project->setClipLoopContent(clipId, true), "enable loop");

            expect(project->setClipLength(clipId, 8.0, audioapp::ClipLengthTarget::Arrangement),

                   "extend arrangement past four-beat content");



            audioapp::MidiClipState clipState = project->snapshot().tracks[0].midiClips[0];

            expectEquals(audioapp::activeMidiPitchAtBeat(6.0, clipState), 60,

                         "beat 6 should wrap to active C4 when loop enabled");

            expectEquals(audioapp::activeMidiPitchAtBeat(5.0, clipState), 60,

                         "beat 5 should wrap when loop enabled");

            clipState.loopContent = false;

            expectEquals(audioapp::activeMidiPitchAtBeat(5.0, clipState), -1,

                         "beat 5 should be silent when loop disabled");

        }



        beginTest("editor content length drives loop period after enable");

        {

            auto project = std::make_unique<audioapp::ProjectEngine>();

            project->createProject();



            const std::string trackId = project->addTrack("Keys");

            project->createMidiClip(trackId, 0.0, 4.0);



            const std::string clipId = project->snapshot().tracks[0].midiClips[0].id;

            std::vector<audioapp::MidiNoteState> notes;

            notes.push_back(audioapp::MidiNoteState{60, 0.0, 4.0, 100.0f});

            notes.push_back(audioapp::MidiNoteState{60, 4.0, 4.0, 100.0f});

            expect(project->setMidiClipNotes(clipId, notes), "set two-bar notes");

            expect(project->setClipLength(clipId, 8.0, audioapp::ClipLengthTarget::Content),

                   "editor sets 8-beat loop period");

            expect(project->setClipLoopContent(clipId, true), "enable loop");

            expect(project->setClipLength(clipId, 20.0, audioapp::ClipLengthTarget::Arrangement),

                   "extend arrangement container");



            audioapp::MidiClipState clipState = project->snapshot().tracks[0].midiClips[0];

            expectEquals(clipState.naturalLengthBeats, 8.0,

                         "loop period stays at editor content length");

            expectEquals(clipState.lengthBeats, 20.0,

                         "arrangement span extended separately");

            expectEquals(audioapp::activeMidiPitchAtBeat(12.0, clipState), 60,

                         "beat 12 should repeat bar-1 content when loop enabled");

            expectEquals(audioapp::activeMidiPitchAtBeat(16.0, clipState), 60,

                         "beat 16 should repeat bar-1 content when loop enabled");

        }



        beginTest("five-beat editor content loops from bar six onward");

        {

            auto project = std::make_unique<audioapp::ProjectEngine>();

            project->createProject();



            const std::string trackId = project->addTrack("Keys");

            project->createMidiClip(trackId, 0.0, 4.0);



            const std::string clipId = project->snapshot().tracks[0].midiClips[0].id;

            std::vector<audioapp::MidiNoteState> notes;

            notes.push_back(audioapp::MidiNoteState{60, 0.0, 4.0, 100.0f});

            expect(project->setMidiClipNotes(clipId, notes), "four bars of notes");

            expect(project->setClipLength(clipId, 5.0, audioapp::ClipLengthTarget::Content),

                   "editor extends content to five bars");

            expect(project->setClipLoopContent(clipId, true), "enable loop");

            expect(project->setClipLength(clipId, 10.0, audioapp::ClipLengthTarget::Arrangement),

                   "arrangement longer than content");



            audioapp::MidiClipState clipState = project->snapshot().tracks[0].midiClips[0];

            expectEquals(clipState.naturalLengthBeats, 5.0,

                         "loop period matches editor range slider");

            expectEquals(audioapp::activeMidiPitchAtBeat(4.0, clipState), -1,

                         "beat 4 is silent tail before wrap");

            expectEquals(audioapp::activeMidiPitchAtBeat(5.0, clipState), 60,

                         "beat 5 repeats from start of loop period");

        }



        beginTest("non-loop arrangement resize keeps content length");

        {

            auto project = std::make_unique<audioapp::ProjectEngine>();

            project->createProject();

            const std::string trackId = project->addTrack("Keys");

            project->createMidiClip(trackId, 0.0, 4.0);

            const std::string clipId = project->snapshot().tracks[0].midiClips[0].id;



            expect(project->setClipLength(clipId, 6.0), "extend arrangement clip");

            const auto snap = project->snapshot().tracks[0].midiClips[0];

            expectEquals(snap.lengthBeats, 6.0, "arrangement length updated");

            expectEquals(snap.naturalLengthBeats, 4.0,

                         "content length unchanged by arrangement resize");

            expect(!snap.loopContent, "still one-shot");

        }



        beginTest("loop resize changes arrangement span only");

        {

            auto project = std::make_unique<audioapp::ProjectEngine>();

            project->createProject();

            const std::string trackId = project->addTrack("Keys");

            project->createMidiClip(trackId, 0.0, 4.0);

            const std::string clipId = project->snapshot().tracks[0].midiClips[0].id;



            std::vector<audioapp::MidiNoteState> notes;

            notes.push_back(audioapp::MidiNoteState{60, 0.0, 4.0, 100.0f});

            expect(project->setMidiClipNotes(clipId, notes), "set notes");

            expect(project->setClipLoopContent(clipId, true), "enable loop");



            expect(project->setClipLength(clipId, 12.0), "extend loop container");

            const auto snap = project->snapshot().tracks[0].midiClips[0];

            expectEquals(snap.lengthBeats, 12.0, "arrangement span grows");

            expectEquals(snap.naturalLengthBeats, 4.0,

                         "loop content length unchanged by arrangement resize");

        }



        beginTest("automation clip loop toggles and wraps envelope");

        {

            auto project = std::make_unique<audioapp::ProjectEngine>();

            project->createProject();

            const std::string trackId = project->addTrack("FX");

            const std::string clipId =

                project->createAutomationClip(trackId, 0.0, 4.0);

            expect(project->setClipLoopContent(clipId, true), "enable auto loop");

            expect(project->setClipLength(clipId, 8.0), "extend automation clip");



            const auto snap = project->snapshot();

            expect(!snap.automationClips.empty(), "automation clip in snapshot");

            if (snap.automationClips.empty()) return;

            expect(snap.automationClips[0].loopContent, "loop flag in snapshot");



            audioapp::AutomationClip clipModel;

            clipModel.id = snap.automationClips[0].id;

            clipModel.homeTrackId = snap.automationClips[0].homeTrackId;

            clipModel.startBeat = snap.automationClips[0].startBeat;

            clipModel.lengthBeats = snap.automationClips[0].lengthBeats;

            clipModel.naturalLengthBeats = snap.automationClips[0].naturalLengthBeats;

            clipModel.loopContent = snap.automationClips[0].loopContent;

            for (const auto& point : snap.automationClips[0].points) {

                clipModel.points.push_back(

                    audioapp::AutomationPoint{point.beat, point.value});

            }



            audioapp::AutomationClipPlayback pb{};

            expect(audioapp::automationClipPlaybackFromClip(clipModel, pb),

                   "build playback clip");

            float beatInClip = 0.0f;

            expect(audioapp::automationBeatInClip(pb, 6.0, beatInClip),

                   "beat 6 inside extended loop clip");

            expectEquals(beatInClip, 2.0f, "beat 6 wraps to beat 2 in 4-beat loop");

        }



        beginTest("loopContent round-trips through project file JSON");

        {

            auto project = std::make_unique<audioapp::ProjectEngine>();

            project->createProject();

            const std::string trackId = project->addTrack("Keys");

            project->createMidiClip(trackId, 0.0, 4.0);

            const std::string clipId = project->snapshot().tracks[0].midiClips[0].id;

            expect(project->setClipLoopContent(clipId, true), "enable midi loop");



            const auto fileData = project->toProjectFileData();

            auto loaded = std::make_unique<audioapp::ProjectEngine>();

            expect(loaded->loadFromProjectFileData(fileData), "reload project");

            expect(loaded->snapshot().tracks[0].midiClips[0].loopContent,

                   "midi loopContent survives save/load");

        }



        beginTest("unknown clip id returns false");

        {

            auto project = std::make_unique<audioapp::ProjectEngine>();

            project->createProject();

            expect(!project->setClipLoopContent("missing-clip", true),

                   "unknown clip should fail");

        }

    }

};



static ClipLoopContentTest clipLoopContentTest;


