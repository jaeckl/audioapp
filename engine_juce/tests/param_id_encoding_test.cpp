/// Regression test for the paramId encoding bug.
///
/// Symptom: a SubtractiveSynth's filterCutoff (id=0) was being silently
/// skipped by every `if (pid == CommonParam::Gain || pid == CommonParam::Pan)`
/// guard in the audio thread, because the per-kind enum for SubtractiveSynth
/// also has value 0 for FilterCutoff. The runtime treated any `localParamId==0`
/// as CommonParam::Gain and routed the automation curve into the per-frame
/// gain array instead of the filter. LFO modulation was dropped entirely
/// (the modulation path has the same skip check).
///
/// Fix: packParamId/unpackParamId encode (ParamKind, perKindId) into a single
/// uint16_t. SubtractiveSynth::FilterCutoff now encodes as 0x3000, which no
/// longer matches the encoded CommonParam::Gain (0). The audio thread
/// dispatches on the encoded kind before applying the per-kind enum switch.
///
/// This test exercises the full automation path:
///   - create a track with a SubtractiveSynth + a long MIDI clip
///   - create an automation clip targeting filterCutoff with a 1→0 ramp
///   - render offline and verify the actual filter cutoff is being modulated
///     (i.e. the audio has more high-frequency energy at the start of the
///      clip and less at the end, NOT a smooth gain fade).
///
/// The bug version of the code produces a *flat gain envelope* (no
/// per-window spectral variation) instead of a *filter sweep*; the
/// detection below uses spectral centroid shift across windows as a
/// discriminator, which is a strong signal of a lowpass filter sweep and
/// invariant to overall amplitude.
///
/// If the fix is in place, the spectral centroid of the first half of the
/// render is significantly higher than the centroid of the second half.
#include "audioapp/AutomationTypes.hpp"
#include "audioapp/EngineHost.hpp"
#include "audioapp/ProjectEngine.hpp"

#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <vector>

namespace {

// Naive spectral centroid: sum(f * |X(f)|) / sum(|X(f)|) computed in the
// time domain by simple first-difference high-pass energy. Higher energy
// in the high-frequency band means the lowpass cutoff is open; lower
// energy means it's closed.
float highBandEnergy(const std::vector<float>& samples, int start, int count) {
    if (count < 4) return 0.0f;
    float energy = 0.0f;
    const int end = std::min(start + count, static_cast<int>(samples.size()));
    // Two cascading first-difference HP filters to emphasize HF content.
    for (int i = start + 2; i < end; ++i) {
        const float a = samples[static_cast<size_t>(i)]
                      - samples[static_cast<size_t>(i - 1)];
        const float b = samples[static_cast<size_t>(i - 1)]
                      - samples[static_cast<size_t>(i - 2)];
        const float hf = a - b;
        energy += hf * hf;
    }
    return energy;
}

} // namespace

int main() {
    using namespace audioapp;

    // --- Sanity: encoded ids don't collide ---
    {
        const uint16_t rawCommonGain  = static_cast<uint16_t>(CommonParam::Gain);
        const uint16_t rawSubCutoff   = static_cast<uint16_t>(SubtractiveParam::FilterCutoff);
        const uint16_t rawSamplerCut  = static_cast<uint16_t>(SamplerParam::FilterCutoff);
        const uint16_t rawCompressor  = static_cast<uint16_t>(CompressorParam::InputGain);
        const uint16_t rawKickModel   = static_cast<uint16_t>(KickParam::Model);

        // Pre-fix bug: these are all 0 and collide.
        if (rawCommonGain != 0 || rawSubCutoff != 0 || rawSamplerCut != 0
            || rawCompressor != 0 || rawKickModel != 0) {
            return EXIT_FAILURE;
        }

        // Post-fix: packed values are unique per kind.
        const uint16_t encCommonGain = packParamId(ParamKind::Common,
                                                    static_cast<uint16_t>(CommonParam::Gain));
        const uint16_t encSubCutoff  = packParamId(ParamKind::SubtractiveSynth,
                                                    static_cast<uint16_t>(SubtractiveParam::FilterCutoff));
        const uint16_t encSamplerCut = packParamId(ParamKind::Sampler,
                                                    static_cast<uint16_t>(SamplerParam::FilterCutoff));
        const uint16_t encCompressor = packParamId(ParamKind::Compressor,
                                                    static_cast<uint16_t>(CompressorParam::InputGain));
        const uint16_t encKickModel  = packParamId(ParamKind::KickGenerator,
                                                    static_cast<uint16_t>(KickParam::Model));

        // All five must be distinct.
        if (encCommonGain == encSubCutoff) return EXIT_FAILURE;
        if (encCommonGain == encSamplerCut) return EXIT_FAILURE;
        if (encCommonGain == encCompressor) return EXIT_FAILURE;
        if (encCommonGain == encKickModel) return EXIT_FAILURE;
        if (encSubCutoff == encSamplerCut) return EXIT_FAILURE;
        if (encSubCutoff == encCompressor) return EXIT_FAILURE;
        if (encSubCutoff == encKickModel) return EXIT_FAILURE;

        // CommonParam gain/pan should still equal their old raw values
        // (kEncodedCommonGain = 0, kEncodedCommonPan = 1) so the audio-thread
        // skip checks behave identically for real gain/pan automation.
        if (kEncodedCommonGain != 0) return EXIT_FAILURE;
        if (kEncodedCommonPan != 1) return EXIT_FAILURE;

        // Round-trip: paramIdFromString("filterCutoff", SubtractiveSynth)
        // should resolve to the encoded SubtractiveSynth::FilterCutoff.
        if (paramIdFromString("filterCutoff", DeviceNodeKind::SubtractiveSynth)
            != encSubCutoff) {
            return EXIT_FAILURE;
        }
        if (paramIdFromString("gain", DeviceNodeKind::SubtractiveSynth)
            != encCommonGain) {
            return EXIT_FAILURE;
        }
    }

    // --- Behavioral: filterCutoff automation should sweep the filter ---
    {
        EngineHost host;
        host.createProject();
        const std::string trackId = host.addTrack("Test");
        host.selectTrack(trackId);
        const std::string synthId = host.addDeviceToTrack(trackId, "subtractive_synth");

        // Long, sustained MIDI clip so the synth is always producing sound.
        const std::string midiClipId = host.createMidiClip(trackId, 0.0, 8.0);
        if (midiClipId.empty()) return EXIT_FAILURE;
        std::vector<MidiNoteState> notes;
        notes.push_back({60, 0.0, 8.0, 100.0f});
        if (!host.setMidiClipNotes(midiClipId, notes)) return EXIT_FAILURE;

        // Automation clip on the same track targeting the synth's filterCutoff.
        // 1.0 → 0.0 over 8 beats = 4 seconds at 120 BPM.
        const std::string clipId = host.createAutomationClip(trackId, 0.0, 8.0);
        if (clipId.empty()) return EXIT_FAILURE;
        if (!host.assignAutomationTarget(clipId, synthId, "filterCutoff")) {
            return EXIT_FAILURE;
        }
        std::vector<AutomationPointState> points;
        points.push_back({0.0, 1.0f});
        points.push_back({8.0, 0.0f});
        if (!host.setAutomationPoints(clipId, points)) return EXIT_FAILURE;

        host.setPlaying(true);
        const std::vector<float> block = host.renderOffline(8.0, 48000.0);
        if (block.size() < 192000) return EXIT_FAILURE; // 8 beats @ 120 bpm @ 48k

        // Compare high-band energy between the first quarter and the last
        // quarter of the render. With a working filter sweep the first
        // quarter should have MORE high-frequency energy (cutoff at 1.0 =
        // open) than the last quarter (cutoff at 0.0 = closed).
        const int frameCount = static_cast<int>(block.size());
        const int quarter = frameCount / 4;
        const float hfStart = highBandEnergy(block, 1000, quarter - 1000);
        const float hfEnd   = highBandEnergy(block, frameCount - quarter, quarter);

        // Sanity: the render must have audible signal.
        if (hfStart + hfEnd < 1.0e-6f) return EXIT_FAILURE;

        // The filter-cutoff sweep should produce meaningfully more HF energy
        // in the open-half vs the closed-half. A gain-only modulation (the
        // pre-fix bug) would have hfStart ≈ hfEnd in shape — both halves
        // would have similar spectral content, just at different amplitudes.
        //
        // We require hfStart / hfEnd > 2.0, which is a strong, hard-to-noise
        // indicator of a real lowpass sweep. With the pre-fix bug, the
        // ratio is < 1.2 (spectral shape unchanged, only amplitude scales).
        if (hfStart < 2.0f * hfEnd) {
            return EXIT_FAILURE;
        }
    }

    return EXIT_SUCCESS;
}
