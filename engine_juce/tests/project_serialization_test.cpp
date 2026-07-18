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

        beginTest("modulators remain scoped to their owning device");
        {
            audioapp::EngineHost scoped;
            scoped.createProject();
            const auto scopedTrack = scoped.addTrack("Scoped Modulation");
            const auto owner = scoped.addDeviceToTrack(
                scopedTrack, audioapp::device_types::kDistortion);
            const auto other = scoped.addDeviceToTrack(
                scopedTrack, audioapp::device_types::kDistortion);
            const int lfo = scoped.createLfo(0, owner);

            expect(lfo > 0, "should create a device-owned modulator");
            expect(scoped.assignModulation(lfo, owner, "drive", 0.5f),
                   "owner device should accept its modulator");
            expect(!scoped.assignModulation(lfo, other, "drive", 0.5f),
                   "another device should reject the owned modulator");

            const auto projectJson = scoped.getProjectFileJson();
            expect(projectJson.find("\"ownerDeviceId\"") != std::string::npos &&
                       projectJson.find(owner) != std::string::npos,
                   "project file should persist modulator ownership");

            audioapp::EngineHost restored;
            restored.createProject();
            expect(restored.loadProjectFileJson(projectJson),
                   "should restore a project with owned modulators");
            expect(restored.getProjectSnapshotJson().find(owner) !=
                       std::string::npos,
                   "snapshot should publish restored modulator ownership");

            expect(restored.removeDeviceFromTrack(owner),
                   "should remove the modulator owner");
            const auto afterRemoval = restored.getProjectFileJson();
            audioapp::ProjectFileData parsedAfterRemoval;
            expect(audioapp::test::parseProjectJsonInto(
                       afterRemoval, parsedAfterRemoval),
                   "should parse the project after owner removal");
            expect(parsedAfterRemoval.lfos.empty(),
                   "removing a device should remove its owned modulators");
        }

        beginTest("percussion pitch controls survive project round-trip");
        {
            audioapp::EngineHost percussion;
            percussion.createProject();
            const auto track = percussion.addTrack("Percussion Pitch");
            const auto snare = percussion.addDeviceToTrack(
                track, audioapp::device_types::kSnareGenerator);
            const auto clap = percussion.addDeviceToTrack(
                track, audioapp::device_types::kClapGenerator);
            const auto hihat = percussion.addDeviceToTrack(
                track, audioapp::device_types::kHihatGenerator);
            const auto ride = percussion.addDeviceToTrack(
                track, audioapp::device_types::kRideGenerator);
            const auto tom = percussion.addDeviceToTrack(
                track, audioapp::device_types::kTomGenerator);
            const auto rimshot = percussion.addDeviceToTrack(
                track, audioapp::device_types::kRimshotGenerator);
            const auto crash = percussion.addDeviceToTrack(
                track, audioapp::device_types::kCrashGenerator);
            expect(percussion.setDeviceParameter(snare, "snareKeyTrack", 0.0f) &&
                       percussion.setDeviceParameter(clap, "clapPitch", 0.25f) &&
                       percussion.setDeviceParameter(clap, "clapKeyTrack", 0.0f) &&
                       percussion.setDeviceParameter(hihat, "hihatPitch", 0.75f) &&
                       percussion.setDeviceParameter(ride, "rideBell", 0.64f) &&
                       percussion.setDeviceParameter(tom, "tomBend", 0.70f) &&
                       percussion.setDeviceParameter(rimshot, "rimshotSnap", 0.84f) &&
                       percussion.setDeviceParameter(crash, "crashPitch", 0.80f),
                   "should update every percussion pitch contract");

            audioapp::EngineHost restored;
            restored.createProject();
            expect(restored.loadProjectFileJson(percussion.getProjectFileJson()),
                   "should reload percussion pitch controls");
            const auto snapshot = restored.getProjectSnapshotJson();
            expect(snapshot.find("snareKeyTrack") != std::string::npos &&
                       snapshot.find("clapPitch") != std::string::npos &&
                       snapshot.find("hihatPitch") != std::string::npos &&
                       snapshot.find("rideBell") != std::string::npos &&
                       snapshot.find("tomBend") != std::string::npos &&
                       snapshot.find("rimshotSnap") != std::string::npos &&
                       snapshot.find("crashPitch") != std::string::npos,
                   "restored snapshot should publish percussion pitch controls");
        }

        beginTest("project v1 migrates cymbal devices and targets to v2");
        {
            const std::string v1 = R"json({
              "project_format_version":1,"name":"v1","bpm":120,
              "selectedTrackId":"t1","tracks":[{"id":"t1","name":"Drums",
              "devices":[{"id":"old-cym","type":"cymbal_generator",
              "parameters":{"gain":0.7,"bypass":0,"cymbalPitch":0.73,
              "cymbalColor":0.61,"cymbalDecay":0.22,"cymbalWidth":0.3,
              "cymbalVelocity":0.9,"cymbalKeyTrack":1}}]}],
              "modEdges":[{"lfoId":0,"deviceId":"old-cym","paramId":"cymbalPitch","amount":0.2}],
              "automationClips":[{"id":"a1","deviceId":"old-cym","paramId":"cymbalDecay","points":[]}]
            })json";
            audioapp::ProjectFileData migrated;
            expect(audioapp::test::parseProjectJsonInto(v1, migrated),
                   "v1 project should migrate");
            expect(migrated.projectFormatVersion == 2);
            expect(migrated.tracks.size() == 1 && !migrated.tracks[0].devices.empty());
            if (migrated.tracks.size() == 1 && !migrated.tracks[0].devices.empty()) {
                const auto& slot = migrated.tracks[0].devices[0];
                expect(slot.config.typeId == audioapp::device_types::kHihatGenerator);
                expectWithinAbsoluteError(std::get<audioapp::HihatGeneratorParams>(
                    slot.config.instance).hihatPitch, 0.73f, 0.001f);
            }
            expect(migrated.modEdges.size() == 1 && migrated.modEdges[0].paramId == "hihatPitch");
            expect(migrated.automationClips.size() == 1 &&
                   migrated.automationClips[0].paramId == "hihatDecay");
        }

        beginTest("project v1 migrates cymbal devices nested in drum pads");
        {
            const std::string v1 = R"json({
              "project_format_version":1,"name":"nested","bpm":120,
              "selectedTrackId":"t1","tracks":[{"id":"t1","name":"Drums",
              "devices":[{"id":"dm","type":"drum_machine","bypass":false,
              "pads":[{"note":42,"name":"Hat","gain":1.0,"pan":0.5,
              "muted":false,"solo":false,"chokeGroup":1,"devices":[{
              "id":"nested-cym","type":"cymbal_generator","parameters":{
              "gain":0.8,"bypass":0,"cymbalPitch":0.42,"cymbalColor":0.7,
              "cymbalDecay":0.18,"cymbalWidth":0.2,"cymbalVelocity":1.0,
              "cymbalKeyTrack":0}}]}]}]}],"modEdges":[],"automationClips":[]
            })json";
            audioapp::ProjectFileData migrated;
            expect(audioapp::test::parseProjectJsonInto(v1, migrated),
                   "nested v1 device should migrate");
            expect(migrated.tracks.size() == 1 && !migrated.tracks[0].devices.empty());
            if (migrated.tracks.size() == 1 && !migrated.tracks[0].devices.empty()) {
                const auto& machine = std::get<audioapp::DrumMachineModel>(
                    migrated.tracks[0].devices[0].config.instance);
                expect(machine.pads[42].devices.size() == 1);
                if (machine.pads[42].devices.size() == 1) {
                    expect(machine.pads[42].devices[0]->config.typeId ==
                           audioapp::device_types::kHihatGenerator);
                }
            }
        }

        beginTest("unknown future project format is rejected");
        {
            audioapp::ProjectFileData project;
            expect(!audioapp::test::parseProjectJsonInto(
                       R"json({"project_format_version":3,"tracks":[]})json", project),
                   "version 3 must not be parsed by a version 2 engine");
        }
    }
};

static ProjectSerializationTest projectSerializationTest;
