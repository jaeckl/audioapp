/// Effect device modulation E2E test suite.
///
/// Tests LFO modulation of dynamics processor parameters:
///   1. LFO -> Compressor threshold -> audible gain reduction variation
///   2. LFO -> Gate threshold -> periodic opening/closing
///   3. LFO -> Gate range -> partial gating variation
///   4. LFO -> Expander threshold -> amplitude variation
///   5. LFO -> Limiter ceiling -> peak limiting variation
///
/// All tests use EngineHost::renderOffline with a simple oscillator as
/// signal source followed by an effect device, exercising the complete
/// control-thread -> audio-thread modulation path.

#include "audioapp/AutomationTypes.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/EngineHost.hpp"
#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/ProjectJson.hpp"
#include "audioapp/SubtractiveSynth.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <limits>
#include <vector>

namespace {

// ---------- audio analysis helpers ----------

float rms(const std::vector<float>& samples, int start, int count) {
    double acc = 0.0;
    const int end = std::min(start + count, static_cast<int>(samples.size()));
    for (int i = start; i < end; ++i) {
        acc += static_cast<double>(samples[static_cast<size_t>(i)]) *
               static_cast<double>(samples[static_cast<size_t>(i)]);
    }
    return end > start ? static_cast<float>(std::sqrt(acc / static_cast<double>(end - start))) : 0.0f;
}

float peak(const std::vector<float>& samples, int start, int count) {
    float p = 0.0f;
    const int end = std::min(start + count, static_cast<int>(samples.size()));
    for (int i = start; i < end; ++i) {
        p = std::max(p, std::abs(samples[static_cast<size_t>(i)]));
    }
    return p;
}

/// RMS variation ratio across N windows (skips first window for attack transient).
/// Higher ratio = more amplitude variation between windows.
float rmsVariationRatio(const std::vector<float>& samples, int numWindows) {
    const int windowFrames = static_cast<int>(samples.size()) / numWindows;
    float maxRms = 0.0f;
    float minRms = std::numeric_limits<float>::infinity();
    int validWindows = 0;
    for (int w = 1; w < numWindows; ++w) {
        const int start = w * windowFrames;
        const float r = rms(samples, start, windowFrames);
        if (r <= 0.0f) continue;
        maxRms = std::max(maxRms, r);
        minRms = std::min(minRms, r);
        ++validWindows;
    }
    return (validWindows >= 2 && minRms > 0.0f && maxRms > 0.0f) ? (maxRms / minRms) : 1.0f;
}

/// Create a project with oscillator -> effect chain and a sustained MIDI note.
struct EffectTestSetup {
    audioapp::EngineHost host;
    std::string trackId;
    std::string oscId;
    std::string effectId;
    std::string midiClipId;

    EffectTestSetup(const std::string& effectType) {
        host.createProject();
        trackId = host.addTrack("Test");
        host.selectTrack(trackId);
        oscId = host.addDeviceToTrack(trackId, "simple_oscillator");
        effectId = host.addDeviceToTrack(trackId, effectType);

        midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
        std::vector<audioapp::MidiNoteState> notes;
        notes.push_back({72, 0.0, 4.0, 100.0f});
        host.setMidiClipNotes(midiClipId, notes);
    }

    int createLfo(float rate = 4.0f) {
        const int lfoId = host.createLfo(0); // 0 = LFO
        host.updateLfoParam(lfoId, "waveform", 0.0f);   // sine
        host.updateLfoParam(lfoId, "rate", rate);
        host.updateLfoParam(lfoId, "syncDivision", 0.0f); // free
        return lfoId;
    }
};

} // namespace

int main() {
    using namespace audioapp;

    constexpr double kLengthBeats = 4.0;
    constexpr double kSampleRate = 48000.0;
    constexpr int kNumWindows = 20; // 5 per beat -> avoids LFO cycle alignment

    // =====================================================================
    // Test 1: LFO -> Compressor threshold -> audible gain reduction variation
    //
    // Lower the threshold so the compressor is active on the oscillator
    // signal (~0.2 peak). The LFO sweeps the threshold above and below
    // the signal level, causing periodic compression -> no compression.
    // =====================================================================
    {
        // Unmodulated baseline
        EffectTestSetup base("compressor");
        base.host.setDeviceParameter(base.effectId, "compThreshold", 0.05f);
        base.host.setPlaying(true);
        const std::vector<float> unmod = base.host.renderOffline(kLengthBeats, kSampleRate);
        if (unmod.size() < 48000) return EXIT_FAILURE;
        const float unmodRatio = rmsVariationRatio(unmod, kNumWindows);

        // With modulation
        EffectTestSetup mod("compressor");
        mod.host.setDeviceParameter(mod.effectId, "compThreshold", 0.05f);
        const int lfoId = mod.createLfo(4.0f);
        if (!mod.host.assignModulation(lfoId, mod.effectId, "compThreshold", 0.8f)) {
            return EXIT_FAILURE;
        }
        mod.host.setPlaying(true);
        const std::vector<float> modAudio = mod.host.renderOffline(kLengthBeats, kSampleRate);
        if (modAudio.size() < 48000) return EXIT_FAILURE;
        const float modRatio = rmsVariationRatio(modAudio, kNumWindows);

        // Modulated must show more window-to-window RMS variation
        if (modRatio < 1.5f) return EXIT_FAILURE;
        if (modRatio < unmodRatio * 1.5f) return EXIT_FAILURE;
    }

    // =====================================================================
    // Test 2: LFO -> Gate threshold -> periodic opening/closing
    //
    // Set gate threshold near the oscillator signal level. The LFO sweeps
    // the threshold above and below, causing the gate to open and close
    // periodically (amplitude modulation).
    // =====================================================================
    {
        EffectTestSetup base("gate");
        base.host.setDeviceParameter(base.effectId, "gateThreshold", 0.15f);
        base.host.setPlaying(true);
        const std::vector<float> unmod = base.host.renderOffline(kLengthBeats, kSampleRate);
        if (unmod.size() < 48000) return EXIT_FAILURE;
        const float unmodRatio = rmsVariationRatio(unmod, kNumWindows);

        EffectTestSetup mod("gate");
        mod.host.setDeviceParameter(mod.effectId, "gateThreshold", 0.15f);
        const int lfoId = mod.createLfo(4.0f);
        if (!mod.host.assignModulation(lfoId, mod.effectId, "gateThreshold", 0.5f)) {
            return EXIT_FAILURE;
        }
        mod.host.setPlaying(true);
        const std::vector<float> modAudio = mod.host.renderOffline(kLengthBeats, kSampleRate);
        if (modAudio.size() < 48000) return EXIT_FAILURE;
        const float modRatio = rmsVariationRatio(modAudio, kNumWindows);

        if (modRatio < 1.5f) return EXIT_FAILURE;
        if (modRatio < unmodRatio * 1.5f) return EXIT_FAILURE;
    }

    // =====================================================================
    // Test 3: LFO -> Gate range -> partial gating
    //
    // Set gate threshold very high (always closed). Modulate gate range
    // so the amount of attenuation changes periodically, producing
    // partial gating variation.
    // =====================================================================
    {
        EffectTestSetup base("gate");
        base.host.setDeviceParameter(base.effectId, "gateThreshold", 0.99f);
        base.host.setDeviceParameter(base.effectId, "gateRange", 0.0f);
        base.host.setPlaying(true);
        const std::vector<float> unmod = base.host.renderOffline(kLengthBeats, kSampleRate);
        if (unmod.size() < 48000) return EXIT_FAILURE;
        const float unmodRatio = rmsVariationRatio(unmod, kNumWindows);

        EffectTestSetup mod("gate");
        mod.host.setDeviceParameter(mod.effectId, "gateThreshold", 0.99f);
        mod.host.setDeviceParameter(mod.effectId, "gateRange", 0.0f);
        const int lfoId = mod.createLfo(4.0f);
        if (!mod.host.assignModulation(lfoId, mod.effectId, "gateRange", 0.9f)) {
            return EXIT_FAILURE;
        }
        mod.host.setPlaying(true);
        const std::vector<float> modAudio = mod.host.renderOffline(kLengthBeats, kSampleRate);
        if (modAudio.size() < 48000) return EXIT_FAILURE;
        const float modRatio = rmsVariationRatio(modAudio, kNumWindows);

        if (modRatio < 1.5f) return EXIT_FAILURE;
        if (modRatio < unmodRatio * 1.5f) return EXIT_FAILURE;
    }

    // =====================================================================
    // Test 4: LFO -> Expander threshold -> amplitude variation
    //
    // Lower expander threshold so expansion is active on the oscillator
    // signal. Modulating the threshold changes how much downward
    // expansion occurs, producing amplitude variation.
    // =====================================================================
    {
        EffectTestSetup base("expander");
        base.host.setDeviceParameter(base.effectId, "expandThreshold", 0.05f);
        base.host.setPlaying(true);
        const std::vector<float> unmod = base.host.renderOffline(kLengthBeats, kSampleRate);
        if (unmod.size() < 48000) return EXIT_FAILURE;
        const float unmodRatio = rmsVariationRatio(unmod, kNumWindows);

        EffectTestSetup mod("expander");
        mod.host.setDeviceParameter(mod.effectId, "expandThreshold", 0.05f);
        const int lfoId = mod.createLfo(4.0f);
        if (!mod.host.assignModulation(lfoId, mod.effectId, "expandThreshold", 0.8f)) {
            return EXIT_FAILURE;
        }
        mod.host.setPlaying(true);
        const std::vector<float> modAudio = mod.host.renderOffline(kLengthBeats, kSampleRate);
        if (modAudio.size() < 48000) return EXIT_FAILURE;
        const float modRatio = rmsVariationRatio(modAudio, kNumWindows);

        if (modRatio < 1.5f) return EXIT_FAILURE;
        if (modRatio < unmodRatio * 1.5f) return EXIT_FAILURE;
    }

    // =====================================================================
    // Test 5: LFO -> Limiter ceiling -> peak limiting variation
    //
    // Lower the limiter ceiling near the oscillator signal peak.
    // Modulating the ceiling changes how much peak limiting occurs,
    // producing amplitude variation.
    // =====================================================================
    {
        EffectTestSetup base("limiter");
        base.host.setDeviceParameter(base.effectId, "limitCeiling", 0.1f);
        base.host.setPlaying(true);
        const std::vector<float> unmod = base.host.renderOffline(kLengthBeats, kSampleRate);
        if (unmod.size() < 48000) return EXIT_FAILURE;
        const float unmodRatio = rmsVariationRatio(unmod, kNumWindows);

        EffectTestSetup mod("limiter");
        mod.host.setDeviceParameter(mod.effectId, "limitCeiling", 0.1f);
        const int lfoId = mod.createLfo(4.0f);
        if (!mod.host.assignModulation(lfoId, mod.effectId, "limitCeiling", 0.6f)) {
            return EXIT_FAILURE;
        }
        mod.host.setPlaying(true);
        const std::vector<float> modAudio = mod.host.renderOffline(kLengthBeats, kSampleRate);
        if (modAudio.size() < 48000) return EXIT_FAILURE;
        const float modRatio = rmsVariationRatio(modAudio, kNumWindows);

        if (modRatio < 1.5f) return EXIT_FAILURE;
        if (modRatio < unmodRatio * 1.5f) return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}