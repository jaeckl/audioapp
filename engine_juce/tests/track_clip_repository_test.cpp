#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/model/ClipRepository.hpp"
#include "audioapp/model/TrackRepository.hpp"

class TrackClipRepositoryTest : public juce::UnitTest {
public:
    TrackClipRepositoryTest() : juce::UnitTest("TrackClipRepository", "Engine") {}
    void runTest() override {
        beginTest("move clip between tracks");
        {
            const audioapp::DeviceRegistry registry = audioapp::DeviceRegistry::createBuiltIn();
            audioapp::TrackRepository trackRepo;
            audioapp::ClipRepository clipRepo{trackRepo};

            const std::string trackA = trackRepo.addTrack("A", registry);
            const std::string trackB = trackRepo.addTrack("B", registry);
            expect(!trackA.empty() && !trackB.empty(), "tracks created");

            const std::string clipId = clipRepo.createMidiClip(trackA, 0.0, 4.0);
            expect(!clipId.empty(), "midi clip created");

            expect(clipRepo.moveClip(clipId, trackB, 8.0), "moveClip succeeded");

            const audioapp::Track* source = trackRepo.findTrack(trackA);
            const audioapp::Track* target = trackRepo.findTrack(trackB);
            expect(source != nullptr && target != nullptr, "tracks found");

            expect(source->midiClips.empty(), "source track has no clips");
            expectEquals(target->midiClips.size(), size_t(1), "target has 1 clip");
            expectWithinAbsoluteError(target->midiClips[0].startBeat, 8.0, 0.001);
        }
        beginTest("duplicate clip");
        {
            const audioapp::DeviceRegistry registry = audioapp::DeviceRegistry::createBuiltIn();
            audioapp::TrackRepository trackRepo;
            audioapp::ClipRepository clipRepo{trackRepo};

            const std::string trackA = trackRepo.addTrack("A", registry);
            const std::string clipId = clipRepo.createMidiClip(trackA, 0.0, 4.0);
            expect(clipRepo.duplicateClip(clipId), "duplicateClip succeeded");

            const audioapp::Track* target = trackRepo.findTrack(trackA);
            expectEquals(target->midiClips.size(), size_t(2), "target has 2 clips");
            expectWithinAbsoluteError(target->midiClips[1].startBeat, 4.0, 0.001);
        }
        beginTest("set clip length");
        {
            const audioapp::DeviceRegistry registry = audioapp::DeviceRegistry::createBuiltIn();
            audioapp::TrackRepository trackRepo;
            audioapp::ClipRepository clipRepo{trackRepo};

            const std::string trackA = trackRepo.addTrack("A", registry);
            const std::string clipId = clipRepo.createMidiClip(trackA, 0.0, 4.0);

            expect(clipRepo.setClipLength(clipId, 2.0), "setClipLength succeeded");

            const audioapp::Track* target = trackRepo.findTrack(trackA);
            expectWithinAbsoluteError(target->midiClips[0].lengthBeats, 2.0, 0.001);
        }
        beginTest("delete clip");
        {
            const audioapp::DeviceRegistry registry = audioapp::DeviceRegistry::createBuiltIn();
            audioapp::TrackRepository trackRepo;
            audioapp::ClipRepository clipRepo{trackRepo};

            const std::string trackA = trackRepo.addTrack("A", registry);
            const std::string clipId = clipRepo.createMidiClip(trackA, 0.0, 4.0);
            clipRepo.duplicateClip(clipId);

            const audioapp::Track* target = trackRepo.findTrack(trackA);
            expect(clipRepo.deleteClip(target->midiClips[1].id), "deleteClip succeeded");
            expectEquals(target->midiClips.size(), size_t(1), "1 clip remains");
        }
        beginTest("move unknown clip fails");
        {
            const audioapp::DeviceRegistry registry = audioapp::DeviceRegistry::createBuiltIn();
            audioapp::TrackRepository trackRepo;
            audioapp::ClipRepository clipRepo{trackRepo};

            const std::string trackA = trackRepo.addTrack("A", registry);
            expect(!clipRepo.moveClip("missing", trackA, 0.0), "moveClip with unknown id fails");
        }
        beginTest("id counter reset");
        {
            const audioapp::DeviceRegistry registry = audioapp::DeviceRegistry::createBuiltIn();
            audioapp::TrackRepository trackRepo;
            audioapp::ClipRepository clipRepo{trackRepo};

            const std::string trackA = trackRepo.addTrack("A", registry);
            clipRepo.createMidiClip(trackA, 0.0, 4.0);

            trackRepo.recomputeIdCounters();
            clipRepo.recomputeIdCounters();
            const std::string clip2 = clipRepo.createMidiClip(trackA, 1.0, 4.0);
            expect(clip2.find("clip-") == 0, "new clip starts with clip-");
        }
    }
};
static TrackClipRepositoryTest trackClipRepositoryTest;