#include <juce_core/juce_core.h>
#include "TestHelpers.h"

#include "audioapp/EngineHost.hpp"
#include "audioapp/ProjectJson.hpp"

#include <cmath>
#include <string>

class LfoModulationTest : public juce::UnitTest {
public:
    LfoModulationTest()
        : juce::UnitTest("LFO Modulation", "Modulation") {}

    void runTest() override {
        using namespace audioapp;

        beginTest("LFO waveform output values");
        {
            float v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Sine, 0.25f);
            expectWithinAbsoluteError(v, 1.0f, 0.001f);

            v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Sine, 0.75f);
            expectWithinAbsoluteError(v, -1.0f, 0.001f);

            v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Tri, 0.0f);
            expectWithinAbsoluteError(v, -1.0f, 0.001f);

            v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Tri, 0.5f);
            expectWithinAbsoluteError(v, 1.0f, 0.001f);

            v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Tri, 0.25f);
            expectWithinAbsoluteError(v, 0.0f, 0.001f);

            v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Saw, 0.0f);
            expectWithinAbsoluteError(v, -1.0f, 0.001f);

            v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Saw, 0.5f);
            expectWithinAbsoluteError(v, 0.0f, 0.001f);

            v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Saw, 0.999f);
            expect(v >= 0.9f, "Saw near 1.0 should be high");

            v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Square, 0.25f);
            expectWithinAbsoluteError(v, 1.0f, 0.001f);

            v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Square, 0.75f);
            expectWithinAbsoluteError(v, -1.0f, 0.001f);

            v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Ramp, 0.0f);
            expectWithinAbsoluteError(v, 1.0f, 0.001f);

            v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Ramp, 0.5f);
            expectWithinAbsoluteError(v, 0.0f, 0.001f);

            v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Ramp, 0.75f);
            expectWithinAbsoluteError(v, -0.5f, 0.001f);
        }

        beginTest("LFO morph/spread evaluation");
        {
            // morph=0 → pure sine
            float v = audioapp::lfoEvaluateMorph(0.0f, 0.5f, 0.25f);
            expectWithinAbsoluteError(v, 1.0f, 0.001f);
            v = audioapp::lfoEvaluateMorph(0.0f, 0.5f, 0.75f);
            expectWithinAbsoluteError(v, -1.0f, 0.001f);

            // morph=1.0 → pure ramp
            v = audioapp::lfoEvaluateMorph(1.0f, 0.5f, 0.0f);
            expectWithinAbsoluteError(v, 1.0f, 0.001f);
            v = audioapp::lfoEvaluateMorph(1.0f, 0.5f, 0.5f);
            expectWithinAbsoluteError(v, 0.0f, 0.001f);

            // morph=0.5 → saw (blend of tri+saw → should be saw at exact 0.5)
            v = audioapp::lfoEvaluateMorph(0.5f, 0.5f, 0.25f);
            expectWithinAbsoluteError(v, -0.5f, 0.001f);
            v = audioapp::lfoEvaluateMorph(0.5f, 0.5f, 0.0f);
            expectWithinAbsoluteError(v, -1.0f, 0.001f);

            // morph midpoint between sine (0) and tri (0.25): morph=0.125
            // At phase=0.25: sine=1.0, tri=0.0 → blend=0.5
            v = audioapp::lfoEvaluateMorph(0.125f, 0.5f, 0.25f);
            expectWithinAbsoluteError(v, 0.5f, 0.05f);

            // spread skew
            // spread=0: phase remapped to [0.5, 1.0) → phase=0.25 maps to 0.625
            v = audioapp::lfoApplySpread(0.25f, 0.0f);
            expectWithinAbsoluteError(v, 0.625f, 0.001f);
            // spread=1: [0,0.5) maps linearly to [0,1), [0.5,1) clamped to 1
            v = audioapp::lfoApplySpread(0.25f, 1.0f);
            expectWithinAbsoluteError(v, 0.5f, 0.001f);
        }

        beginTest("LFO sync beats");
        {
            expectEquals(audioapp::lfoSyncBeats(0), 0.0);
            expectEquals(audioapp::lfoSyncBeats(1), 1.0);
            expectEquals(audioapp::lfoSyncBeats(2), 0.5);
            expectEquals(audioapp::lfoSyncBeats(3), 0.25);
            expectEquals(audioapp::lfoSyncBeats(4), 0.125);
            expectEquals(audioapp::lfoSyncBeats(5), 0.0625);
        }

        beginTest("Modulation edge CRUD via EngineHost");
        {
            audioapp::EngineHost host;
            host.createProject();
            host.addTrack("Test");

            const int lfoId1 = host.createLfo();
            const int lfoId2 = host.createLfo();
            expect(lfoId1 >= 0 && lfoId2 >= 0, "LFO creation");

            auto snapshot = audioapp::test::readProjectData(host);
            expectEquals(static_cast<int>(snapshot.lfos.size()), 2);

            bool found1 = false;
            bool found2 = false;
            for (const auto& lfo : snapshot.lfos) {
                if (lfo.id == lfoId1) found1 = true;
                if (lfo.id == lfoId2) found2 = true;
            }
            expect(found1 && found2, "Both LFOs found in snapshot");

            expect(host.updateLfoParam(lfoId1, "waveform",
                                       static_cast<float>(static_cast<int>(audioapp::LfoWaveform::Square))));
            expect(host.updateLfoParam(lfoId1, "rate", 2.0f));

            snapshot = audioapp::test::readProjectData(host);
            for (const auto& lfo : snapshot.lfos) {
                if (lfo.id == lfoId1) {
                    expectEquals(lfo.waveform, static_cast<int>(audioapp::LfoWaveform::Square));
                    expectWithinAbsoluteError(lfo.rate, 2.0f, 0.001f);
                }
            }

            const auto snapDevices = audioapp::test::readProjectData(host);
            expect(!snapDevices.tracks.empty() && !snapDevices.tracks[0].devices.empty());
            const std::string deviceId = snapDevices.tracks[0].devices[0].id;

            expect(host.assignModulation(lfoId1, deviceId, "gain", 0.5f));
            expect(host.assignModulation(lfoId2, deviceId, "gain", -0.75f));

            snapshot = audioapp::test::readProjectData(host);
            expectEquals(static_cast<int>(snapshot.modEdges.size()), 2);

            int edgeCount = 0;
            for (const auto& edge : snapshot.modEdges) {
                if (edge.lfoId == lfoId1 && edge.deviceId == deviceId && edge.paramId == "gain") {
                    expectWithinAbsoluteError(edge.amount, 0.5f, 0.001f);
                    ++edgeCount;
                }
                if (edge.lfoId == lfoId2 && edge.deviceId == deviceId && edge.paramId == "gain") {
                    expectWithinAbsoluteError(edge.amount, -0.75f, 0.001f);
                    ++edgeCount;
                }
            }
            expectEquals(edgeCount, 2);

            expect(host.removeModulation(lfoId1, "gain"));

            snapshot = audioapp::test::readProjectData(host);
            expectEquals(static_cast<int>(snapshot.modEdges.size()), 1);
            expectEquals(snapshot.modEdges[0].lfoId, lfoId2);

            expect(host.removeLfo(lfoId2));

            snapshot = audioapp::test::readProjectData(host);
            expectEquals(static_cast<int>(snapshot.lfos.size()), 1);
            expectEquals(static_cast<int>(snapshot.modEdges.size()), 0);
            expectEquals(snapshot.lfos[0].id, lfoId1);
        }

        beginTest("LFO/modulation serialization roundtrip");
        {
            audioapp::EngineHost host;
            host.createProject();
            host.addTrack("Test");

            const int lfoId = host.createLfo();
            expect(lfoId >= 0);

            host.updateLfoParam(lfoId, "waveform", static_cast<float>(static_cast<int>(audioapp::LfoWaveform::Tri)));
            host.updateLfoParam(lfoId, "rate", 3.5f);

            const auto snapDevices = audioapp::test::readProjectData(host);
            expect(!snapDevices.tracks.empty() && !snapDevices.tracks[0].devices.empty());
            const std::string deviceId = snapDevices.tracks[0].devices[0].id;

            host.assignModulation(lfoId, deviceId, "pan", 0.25f);

            const std::string json = host.getProjectFileJson();
            audioapp::ProjectFileData parsed;
            expect(audioapp::test::parseProjectJsonInto(json, parsed));

            expectEquals(static_cast<int>(parsed.lfos.size()), 1);
            expect(parsed.lfos[0].id == lfoId);
            expectEquals(parsed.lfos[0].waveform, static_cast<int>(audioapp::LfoWaveform::Tri));
            expectWithinAbsoluteError(parsed.lfos[0].rate, 3.5f, 0.001f);

            expectEquals(static_cast<int>(parsed.modEdges.size()), 1);
            expectEquals(parsed.modEdges[0].lfoId, lfoId);
            expect(parsed.modEdges[0].paramId == "pan");
            expectWithinAbsoluteError(parsed.modEdges[0].amount, 0.25f, 0.001f);

            audioapp::EngineHost loaded;
            loaded.createProject();
            expect(loaded.loadProjectFileJson(json));

            const auto reloadedSnapshot = audioapp::test::readProjectData(loaded);
            expectEquals(static_cast<int>(reloadedSnapshot.lfos.size()), 1);
            expectEquals(static_cast<int>(reloadedSnapshot.modEdges.size()), 1);
        }
    }
};

static LfoModulationTest lfoModulationTest;