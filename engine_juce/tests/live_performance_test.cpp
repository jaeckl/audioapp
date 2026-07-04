#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/EngineHost.hpp"
#include "audioapp/SampleBank.hpp"

class LivePerformanceTest : public juce::UnitTest {
public:
    LivePerformanceTest() : juce::UnitTest("LivePerformance", "Engine") {}

    static juce::var firstMidiClipVar(const audioapp::EngineHost& host) {
        auto root = juce::JSON::parse(host.getProjectSnapshotJson());
        auto* rootObj = root.getDynamicObject();
        if (rootObj == nullptr) return {};
        auto tracks = rootObj->getProperty("tracks");
        auto* tracksArray = tracks.getArray();
        if (tracksArray == nullptr || tracksArray->isEmpty()) return {};
        auto* trackObj = tracksArray->getReference(0).getDynamicObject();
        if (trackObj == nullptr) return {};
        auto clips = trackObj->getProperty("midiClips");
        auto* clipsArray = clips.getArray();
        if (clipsArray == nullptr || clipsArray->isEmpty()) return {};
        return clipsArray->getReference(0);
    }

    void runTest() override {
        beginTest("note on produces audio");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Live");
            host.selectTrack(trackId);
            // addTrack auto-creates a track_gain device at dev-1; add a sampler
            // and use the returned id so setDeviceStringParameter hits the right slot.
            const std::string samplerId = host.addDeviceToTrack(trackId, "simple_sampler");
            expect(!samplerId.empty(), "sampler added");
            expect(host.setDeviceStringParameter(samplerId, "sampleId", "sample_kick"),
                   "set sampleId");
            host.setRecordArmed(false);

            host.enterPlayMode();
            const bool noteStarted = host.noteOn(60, 110.0f);
            expect(noteStarted, "noteOn should start");

            std::vector<float> buffer(2048, 0.0f);
            host.readLiveMix(buffer.data(), static_cast<int>(buffer.size()), 48000.0);
            expect(audioapp::test::hasNonZeroSample(buffer),
                   "live mix should contain audio");

            host.noteOff(60);
            host.allNotesOff();
        }

        beginTest("per-note envelope does not cut overlapping live voice");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Live synth");
            host.selectTrack(trackId);
            const std::string synthId = host.addDeviceToTrack(trackId, "subtractive_synth");
            expect(!synthId.empty(), "synth added");
            expect(host.setDeviceParameter(synthId, "gain", 0.0f), "base gain at zero");
            const int envelopeId = host.createLfo(1);
            host.updateLfoParam(envelopeId, "curveType", 2.0f);
            host.updateLfoParam(envelopeId, "attack", 0.01f);
            host.updateLfoParam(envelopeId, "decay", 0.5f);
            host.updateLfoParam(envelopeId, "release", 0.1f);
            expect(host.assignModulation(envelopeId, synthId, "gain", 1.0f),
                   "envelope assigned to gain");

            host.enterPlayMode();
            expect(host.noteOn(60, 110.0f), "first note starts");
            std::vector<float> warmup(1024, 0.0f);
            host.readLiveMix(warmup.data(), static_cast<int>(warmup.size()), 48000.0);
            expect(host.noteOn(67, 110.0f), "second note starts");
            host.noteOff(60);

            std::vector<float> overlap(2048, 0.0f);
            host.readLiveMix(overlap.data(), static_cast<int>(overlap.size()), 48000.0);
            expect(audioapp::test::hasNonZeroSample(overlap),
                   "second voice remains audible after first note-off");
            host.allNotesOff();
        }

        beginTest("transport MIDI session commits at explicit beat span");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Recorded MIDI");
            host.selectTrack(trackId);
            const std::string synthId = host.addDeviceToTrack(trackId, "subtractive_synth");
            expect(!synthId.empty(), "synth added");

            expect(host.beginMidiRecordingSession(trackId, 2.0, 0.25),
                   "midi recording session starts");
            expect(host.noteOn(60, 100.0f), "note starts");
            std::vector<float> oneBeat(24000, 0.0f);
            host.readLiveMix(oneBeat.data(), static_cast<int>(oneBeat.size()), 48000.0);
            expect(host.noteOff(60), "note off accepted");
            expect(host.finishMidiRecordingSession(4.0),
                   "midi recording session commits");

            auto clip = firstMidiClipVar(host);
            auto* clipObj = clip.getDynamicObject();
            expect(clipObj != nullptr, "snapshot has recorded MIDI clip");
            if (clipObj == nullptr) return;
            expectWithinAbsoluteError(static_cast<double>(clipObj->getProperty("startBeat")),
                                      2.0, 0.001, "clip starts at session start");
            expectWithinAbsoluteError(static_cast<double>(clipObj->getProperty("lengthBeats")),
                                      2.0, 0.001, "clip length uses explicit end beat");
            auto notes = clipObj->getProperty("notes");
            auto* notesArray = notes.getArray();
            expect(notesArray != nullptr && notesArray->size() == 1,
                   "clip has one recorded note");
            if (notesArray == nullptr || notesArray->isEmpty()) return;
            auto* noteObj = notesArray->getReference(0).getDynamicObject();
            expect(noteObj != nullptr, "note object exists");
            if (noteObj == nullptr) return;
            expectEquals(static_cast<int>(noteObj->getProperty("pitch")), 60);
            expectWithinAbsoluteError(static_cast<double>(noteObj->getProperty("startBeat")),
                                      0.0, 0.001, "note is clip-relative");
            expectWithinAbsoluteError(static_cast<double>(noteObj->getProperty("durationBeats")),
                                      1.0, 0.001, "note duration follows sample clock");

            audioapp::EngineHost restored;
            restored.createProject();
            expect(restored.loadProjectFileJson(host.getProjectFileJson()),
                   "recorded MIDI project reloads");
            expect(firstMidiClipVar(restored).getDynamicObject() != nullptr,
                   "recorded MIDI survives project-file roundtrip");
        }

        beginTest("empty MIDI session discards predictably");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Empty MIDI");
            host.selectTrack(trackId);
            expect(host.beginMidiRecordingSession(trackId, 1.0, 0.25),
                   "empty session starts");
            expect(!host.finishMidiRecordingSession(2.0),
                   "empty session reports no recorded clip");
            expect(firstMidiClipVar(host).getDynamicObject() == nullptr,
                   "empty session creates no MIDI clip");
        }
    }
};
static LivePerformanceTest livePerformanceTest;
