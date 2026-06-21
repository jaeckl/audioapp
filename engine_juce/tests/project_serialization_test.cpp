#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/EngineHost.hpp"
#include "audioapp/ProjectJson.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"

#include <string>

class ProjectSerializationTest : public juce::UnitTest {
public:
    ProjectSerializationTest() : juce::UnitTest("ProjectSerialization", "Project") {}

    void runTest() override
    {
        audioapp::EngineHost host;
        host.createProject();
        const std::string trackId = host.addTrack("Keys");
        host.createMidiClip(trackId, 0.0, 4.0);

        beginTest("add devices to track");
        {
            const std::string oscId =
                host.addDeviceToTrack(trackId, audioapp::device_types::kOscillator);
            const std::string samplerId =
                host.addDeviceToTrack(trackId, audioapp::device_types::kSampler);
            const std::string synthId =
                host.addDeviceToTrack(trackId, audioapp::device_types::kSubtractiveSynth);
            expect(!oscId.empty(), "should add oscillator");
            expect(!samplerId.empty(), "should add sampler");
            expect(!synthId.empty(), "should add subtractive synth");

            host.setDeviceParameter(oscId, "frequency", 523.25f);
            host.setDeviceParameter(samplerId, "attack", 0.05f);
            host.setDeviceParameter(synthId, "filterCutoff", 0.6f);
        }

        beginTest("project JSON contains expected fields");
        {
            const std::string json = host.getProjectFileJson();
            expect(json.find("\"project_format_version\"") != std::string::npos,
                   "JSON should contain project_format_version");
            expect(json.find("simple_oscillator") != std::string::npos,
                   "JSON should reference simple_oscillator");
            expect(json.find("simple_sampler") != std::string::npos,
                   "JSON should reference simple_sampler");
            expect(json.find("subtractive_synth") != std::string::npos,
                   "JSON should reference subtractive_synth");
            expect(json.find("track_gain") != std::string::npos,
                   "JSON should reference track_gain");
        }

        beginTest("parse and load project JSON");
        {
            const std::string json = host.getProjectFileJson();
            audioapp::ProjectFileData parsed;
            expect(audioapp::test::parseProjectJsonInto(json, parsed),
                   "should parse project JSON");
            expect(parsed.tracks.size() == 1, "should have one track");
            expect(parsed.tracks[0].name == "Keys", "track name should be Keys");
            expect(parsed.tracks[0].devices.size() >= 4,
                   "track should have at least 4 devices");
        }

        beginTest("load into new engine host");
        {
            const std::string json = host.getProjectFileJson();

            audioapp::EngineHost loaded;
            loaded.createProject();
            expect(loaded.loadProjectFileJson(json),
                   "should load project JSON into new host");

            const std::string snapshotJson = loaded.getProjectSnapshotJson();
            expect(snapshotJson.find("Keys") != std::string::npos,
                   "snapshot should contain track name Keys");
            expect(snapshotJson.find("523.25") != std::string::npos,
                   "snapshot should contain frequency 523.25");
        }

        beginTest("round-trip device count matches");
        {
            const std::string json = host.getProjectFileJson();
            audioapp::ProjectFileData parsed;
            expect(audioapp::test::parseProjectJsonInto(json, parsed),
                   "should parse project JSON");

            audioapp::EngineHost loaded;
            loaded.createProject();
            loaded.loadProjectFileJson(json);

            const std::string roundTripJson = loaded.getProjectFileJson();
            audioapp::ProjectFileData roundTrip;
            expect(audioapp::test::parseProjectJsonInto(roundTripJson, roundTrip),
                   "should parse round-trip JSON");
            expect(roundTrip.tracks[0].devices.size() == parsed.tracks[0].devices.size(),
                   "round-trip device count should match");
        }
    }
};

static ProjectSerializationTest projectSerializationTest;