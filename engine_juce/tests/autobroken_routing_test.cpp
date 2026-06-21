/// Regression test for the "autobroken" routing bug.
///
/// Symptom: a user creates a subtractive synth on track-1, an empty track-2,
/// then drops an automation clip on track-2 *while* targeting the
/// filterCutoff of the synth on track-1, and assigns an LFO modulation edge
/// to that same device. The UI happily accepted this state (the
/// `assignAutomationTarget` path did not re-home the clip, and the
/// `rebuildTrackPlaybackLocked` resolver only scanned clips stored on the
/// current track). Result: at play time, no automation clip and no
/// modulation edge reached the synth. Manual knob changes still worked
/// because those go through a different (per-frame) path.
///
/// This test reproduces the exact layout from `autobroken.audioapp.zip`:
///
///   track-1: subtractive_synth (dev-2), track_gain (dev-1), midi clip
///   track-2: track_gain (dev-3) + automation clip targeting dev-2
///   project: LFO modulating dev-2.filterCutoff
///
/// It also covers the "as loaded" scenario via
/// `loadFromProjectFileData` (i.e. the project JSON the user has on disk),
/// so the engine must self-heal on load AND on `assignAutomationTarget`.
///
/// If the fix is in place, both offline renders must show the filter
/// sweeping (visible as varying high-frequency energy across windows).

#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/EngineHost.hpp"
#include "audioapp/ProjectEngine.hpp"
#include "audioapp/ProjectJson.hpp"

#include <cmath>
#include <limits>
#include <memory>
#include <string>
#include <vector>

namespace {

bool buildBrokenProjectFromApi(audioapp::EngineHost& host) {
    host.createProject();
    const std::string track1 = host.addTrack("Track 1");
    if (track1.empty()) return false;
    host.selectTrack(track1);
    const std::string synthId = host.addDeviceToTrack(track1, "subtractive_synth");
    if (synthId.empty()) return false;

    const std::string midiClipId = host.createMidiClip(track1, 0.0, 16.0);
    if (midiClipId.empty()) return false;
    std::vector<audioapp::MidiNoteState> notes = {
        {50, 0.0, 8.0, 75.0f},
        {53, 0.0, 8.0, 75.0f},
        {57, 0.0, 8.0, 75.0f},
        {48, 8.0, 8.0, 73.0f},
        {52, 8.0, 8.0, 73.0f},
        {55, 8.0, 8.0, 73.0f},
    };
    if (!host.setMidiClipNotes(midiClipId, notes)) return false;

    const std::string track2 = host.addTrack("Track 2");
    if (track2.empty()) return false;
    const std::string aclipId = host.createAutomationClip(track2, 0.0, 8.0);
    if (aclipId.empty()) return false;
    if (!host.assignAutomationTarget(aclipId, synthId, "filterCutoff")) return false;
    std::vector<audioapp::AutomationPointState> points = {
        {0.0, 1.0f},
        {8.0, 0.2f},
    };
    if (!host.setAutomationPoints(aclipId, points)) return false;

    const int lfoId = host.createLfo(0);
    if (lfoId <= 0) return false;
    if (!host.updateLfoParam(lfoId, "waveform", 0.0f)) return false;
    if (!host.updateLfoParam(lfoId, "rate", 4.0f)) return false;
    if (!host.updateLfoParam(lfoId, "syncDivision", 0.0f)) return false;
    if (!host.assignModulation(lfoId, synthId, "filterCutoff", -0.43f)) return false;
    return true;
}

} // namespace

class AutobrokenRoutingTest : public juce::UnitTest {
public:
    AutobrokenRoutingTest() : juce::UnitTest("AutobrokenRouting", "Regression") {}
    void runTest() override {
        using namespace audioapp::test;

        beginTest("build broken project via API and detect filter sweep");
        {
            audioapp::EngineHost host;
            expect(buildBrokenProjectFromApi(host), "build broken project");
            host.setPlaying(true);
            const std::vector<float> block = host.renderOffline(8.0, 48000.0);
            expect(block.size() >= 192000, "enough audio frames");
            expect(rms(block, 1000, 4000) >= 1.0e-4f, "audible output");
            expect(filterSweepDetected(block, 8, 2.0f),
                   "filter sweep detected from API-built project");
        }

        beginTest("load autobroken JSON and detect filter sweep");
        {
            static const char* kAutobrokenJson = R"({
  "project_format_version": 1,
  "name": "Untitled",
  "bpm": 120,
  "selectedTrackId": "track-1",
  "master": {"id": "master", "name": "Master", "gain": 1.0},
  "samples": [],
  "tracks": [
    {
      "id": "track-1",
      "name": "Track 1",
      "devices": [
        {
          "id": "dev-2",
          "type": "subtractive_synth",
          "parameters": {
            "gain": 1.0, "pan": 0.5,
            "attack": 0.02, "decay": 0.25, "sustain": 0.75, "release": 0.35,
            "filterCutoff": 0.75, "filterQ": 0.2, "filterEnvAmount": 0.5,
            "filterAttack": 0.05, "filterDecay": 0.35, "filterSustain": 0.4, "filterRelease": 0.45,
            "osc1Shape": 0.5, "osc2Shape": 0.5, "osc1Octave": 0.5, "osc1Semi": 0.0, "osc1Detune": 0.5,
            "osc2Octave": 0.5, "osc2Semi": 0.0, "osc2Detune": 0.5, "oscMix": 0.37,
            "osc1Sync": 0.0, "osc2Sync": 0.0, "filterMode": 0, "noiseLevel": 0.0,
            "oscMixMode": 0, "unisonVoices": 0.0, "unisonDetune": 0.35, "glideMs": 0.0,
            "velocitySensitivity": 1.0, "preHpCutoff": 0.0, "preHpRes": 0.2, "preDrive": 0.0,
            "mixFeedback": 0.0, "globalPitch": 0.5, "filterKeyTrack": 0.0, "filterDrive": 0.0,
            "filterShaper": 0.0, "filterFm": 0.0, "filterShaperMode": 1, "synthLegato": 0.0,
            "synthMono": 0.0, "bypass": 0.0
          }
        },
        {"id": "dev-1", "type": "track_gain", "parameters": {"gain": 1.0, "bypass": 0.0}}
      ],
      "midiClips": [
        {
          "id": "clip-1", "startBeat": 0.0, "lengthBeats": 16.0,
          "notes": [
            {"pitch": 50, "startBeat": 0.0, "durationBeats": 8.0, "velocity": 75.0},
            {"pitch": 53, "startBeat": 0.0, "durationBeats": 8.0, "velocity": 75.0},
            {"pitch": 57, "startBeat": 0.0, "durationBeats": 8.0, "velocity": 75.0},
            {"pitch": 48, "startBeat": 8.0, "durationBeats": 8.0, "velocity": 73.0},
            {"pitch": 52, "startBeat": 8.0, "durationBeats": 8.0, "velocity": 73.0},
            {"pitch": 55, "startBeat": 8.0, "durationBeats": 8.0, "velocity": 73.0}
          ]
        }
      ],
      "sampleClips": [],
      "automationClips": []
    },
    {
      "id": "track-2",
      "name": "Track 2",
      "devices": [
        {"id": "dev-3", "type": "track_gain", "parameters": {"gain": 1.0, "bypass": 0.0}}
      ],
      "midiClips": [],
      "sampleClips": [],
      "automationClips": []
    }
  ],
  "automationClips": [
    {
      "id": "aclip-1", "startBeat": 0.0, "lengthBeats": 8.0,
      "deviceId": "dev-2", "paramId": "filterCutoff",
      "points": [
        {"beat": 0.0, "value": 1.0},
        {"beat": 8.0, "value": 0.2}
      ]
    }
  ],
  "lfos": [
    {
      "id": 2, "modulatorType": 0, "retrigger": 1, "waveform": 0,
      "rate": 4.0, "syncDivision": 0, "phase": 0.0, "polarity": 0,
      "attack": 0.1, "decay": 0.25, "sustain": 0.7, "release": 0.35
    }
  ],
  "modEdges": [
    {"lfoId": 2, "deviceId": "dev-2", "paramId": "filterCutoff", "amount": -0.43}
  ]
})";

            audioapp::ProjectFileData data;
            expect(audioapp::test::parseProjectJsonInto(kAutobrokenJson, data),
                   "parse autobroken JSON");
            auto engine = std::make_unique<audioapp::ProjectEngine>();
            expect(engine->loadFromProjectFileData(data),
                   "load from project data");

            engine->setPlaying(true);
            const std::vector<float> block = engine->renderOffline(8.0, 48000.0);
            expect(block.size() >= 192000, "enough audio frames");
            expect(rms(block, 1000, 4000) >= 1.0e-4f, "audible output");
            expect(filterSweepDetected(block, 8, 2.0f),
                   "filter sweep detected from loaded JSON");
        }
    }
};
static AutobrokenRoutingTest autobrokenRoutingTest;