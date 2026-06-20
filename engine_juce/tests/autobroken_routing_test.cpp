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
#include "audioapp/EngineHost.hpp"
#include "audioapp/ProjectEngine.hpp"
#include "audioapp/ProjectJson.hpp"

#include <cmath>
#include <cstdlib>
#include <limits>
#include <string>
#include <vector>

namespace {

float highFrequencyEnergy(const std::vector<float>& samples, int start, int count) {
    float energy = 0.0f;
    for (int i = start + 1; i < start + count && i < static_cast<int>(samples.size()); ++i) {
        const float diff = samples[static_cast<size_t>(i)] - samples[static_cast<size_t>(i - 1)];
        energy += diff * diff;
    }
    return energy;
}

float rms(const std::vector<float>& samples, int start, int count) {
    double acc = 0.0;
    const int end = std::min(start + count, static_cast<int>(samples.size()));
    for (int i = start; i < end; ++i) {
        acc += static_cast<double>(samples[static_cast<size_t>(i)]) *
               static_cast<double>(samples[static_cast<size_t>(i)]);
    }
    return end > start ? static_cast<float>(std::sqrt(acc / (end - start))) : 0.0f;
}

// Returns true if HF energy varies by at least `minRatio` across the render.
bool filterSweepDetected(const std::vector<float>& block, int windows, float minRatio) {
    const int windowFrames = static_cast<int>(block.size()) / windows;
    if (windowFrames <= 1) return false;
    float brightest = 0.0f;
    float darkest = std::numeric_limits<float>::infinity();
    for (int w = 0; w < windows; ++w) {
        const int start = w * windowFrames;
        const float hf = highFrequencyEnergy(block, start, windowFrames);
        if (hf <= 0.0f) return false;
        brightest = std::max(brightest, hf);
        darkest = std::min(darkest, hf);
    }
    if (darkest <= 0.0f) return false;
    return brightest >= darkest * minRatio;
}

bool buildBrokenProjectFromApi(audioapp::EngineHost& host) {
    host.createProject();
    const std::string track1 = host.addTrack("Track 1");
    if (track1.empty()) return false;
    host.selectTrack(track1);
    const std::string synthId = host.addDeviceToTrack(track1, "subtractive_synth");
    if (synthId.empty()) return false;

    // MIDI clip sustaining two stacked notes (matches the user's file).
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

    // Empty track-2 with the automation clip *on the wrong track*.
    const std::string track2 = host.addTrack("Track 2");
    if (track2.empty()) return false;
    const std::string aclipId = host.createAutomationClip(track2, 0.0, 8.0);
    if (aclipId.empty()) return false;
    // Target the synth on track-1 from the clip living on track-2.
    if (!host.assignAutomationTarget(aclipId, synthId, "filterCutoff")) return false;
    std::vector<audioapp::AutomationPointState> points = {
        {0.0, 1.0f},
        {8.0, 0.0f},
    };
    if (!host.setAutomationPoints(aclipId, points)) return false;

    // LFO modulating the same target with a strong negative amount.
    const int lfoId = host.createLfo(0);
    if (lfoId <= 0) return false;
    if (!host.updateLfoParam(lfoId, "waveform", 0.0f)) return false;   // sine
    if (!host.updateLfoParam(lfoId, "rate", 4.0f)) return false;      // 4 Hz
    if (!host.updateLfoParam(lfoId, "syncDivision", 0.0f)) return false;
    if (!host.assignModulation(lfoId, synthId, "filterCutoff", -0.43f)) return false;
    return true;
}

} // namespace

int main() {
    // --- Case 1: build the broken project via the EngineHost API ---
    {
        audioapp::EngineHost host;
        if (!buildBrokenProjectFromApi(host)) return EXIT_FAILURE;
        host.setPlaying(true);
        const std::vector<float> block = host.renderOffline(8.0, 48000.0);
        // 8 beats at 120 BPM = 4 seconds = 192000 frames at 48 kHz.
        if (block.size() < 192000) return EXIT_FAILURE;
        if (rms(block, 1000, 4000) < 1.0e-4f) return EXIT_FAILURE;
        if (!filterSweepDetected(block, 8, 2.0f)) return EXIT_FAILURE;
    }

    // --- Case 2: load the user's actual project.json verbatim ---
    // The load path must self-heal: a clip stored on the "wrong" track must
    // be re-routed to the track that owns the target device, and the same
    // resolve must surface mod edges whose target device is on a different
    // track than the one that *seems* to host them. This is the exact
    // JSON payload that was extracted from autobroken.audioapp.zip on
    // the user's device — the sample bank definitions are abbreviated
    // to the bare minimum needed for the test, but the device/clip/LFO
    // graph is unchanged.
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
      "automationClips": [
        {
          "id": "aclip-1", "startBeat": 0.0, "lengthBeats": 8.0,
          "deviceId": "dev-2", "paramId": "filterCutoff",
          "points": [
            {"beat": 0.0, "value": 1.0},
            {"beat": 8.0, "value": 0.0}
          ]
        }
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

    {
        audioapp::ProjectEngine engine;
        audioapp::ProjectFileData data;
        if (!audioapp::parseProjectFileJson(kAutobrokenJson, data)) return EXIT_FAILURE;
        if (!engine.loadFromProjectFileData(data)) return EXIT_FAILURE;

        // 4 Hz LFO * 4 seconds = 16 cycles across the render.
        engine.setPlaying(true);
        const std::vector<float> block = engine.renderOffline(8.0, 48000.0);
        // 8 beats at 120 BPM = 4 seconds = 192000 frames at 48 kHz.
        if (block.size() < 192000) return EXIT_FAILURE;
        if (rms(block, 1000, 4000) < 1.0e-4f) return EXIT_FAILURE;
        if (!filterSweepDetected(block, 8, 2.0f)) return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
