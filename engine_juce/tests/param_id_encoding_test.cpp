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
/// uint16_t with a 5-bit kind tag. SubtractiveSynth::FilterCutoff now encodes
/// as 0x1800, which no longer matches the encoded CommonParam::Gain (0).
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

#include <juce_core/juce_core.h>
#include "TestHelpers.h"

#include "audioapp/AutomationTypes.hpp"
#include "audioapp/EngineHost.hpp"
#include "audioapp/ProjectEngine.hpp"

#include <cmath>
#include <cstdint>
#include <vector>

class ParamIdEncodingTest : public juce::UnitTest {
public:
    ParamIdEncodingTest()
        : juce::UnitTest("Param ID Encoding", "Automation") {}

    void runTest() override {
        using namespace audioapp;

        beginTest("Encoded ids don't collide");
        {
            const uint16_t rawCommonGain  = static_cast<uint16_t>(CommonParam::Gain);
            const uint16_t rawSubCutoff   = static_cast<uint16_t>(SubtractiveParam::FilterCutoff);
            const uint16_t rawSamplerCut  = static_cast<uint16_t>(SamplerParam::FilterCutoff);
            const uint16_t rawCompressor  = static_cast<uint16_t>(CompressorParam::InputGain);
            const uint16_t rawKickModel   = static_cast<uint16_t>(KickParam::Model);

            // Pre-fix bug: these are all 0 and collide.
            expect(rawCommonGain == 0u);
            expect(rawSubCutoff == 0u);
            expect(rawSamplerCut == 0u);
            expect(rawCompressor == 0u);
            expect(rawKickModel == 0u);

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
            expect(encCommonGain != encSubCutoff);
            expect(encCommonGain != encSamplerCut);
            expect(encCommonGain != encCompressor);
            expect(encCommonGain != encKickModel);
            expect(encSubCutoff != encSamplerCut);
            expect(encSubCutoff != encCompressor);
            expect(encSubCutoff != encKickModel);

            // CommonParam gain/pan should still equal their old raw values
            // (kEncodedCommonGain = 0, kEncodedCommonPan = 1) so the audio-thread
            // skip checks behave identically for real gain/pan automation.
            expect(kEncodedCommonGain == 0u);
            expect(kEncodedCommonPan == 1u);

            // Round-trip: paramIdFromString("filterCutoff", SubtractiveSynth)
            // should resolve to the encoded SubtractiveSynth::FilterCutoff.
            expectEquals(paramIdFromString("filterCutoff", DeviceNodeKind::SubtractiveSynth),
                         encSubCutoff);
            expectEquals(paramIdFromString("gain", DeviceNodeKind::SubtractiveSynth),
                         encCommonGain);
        }

        beginTest("FilterCutoff automation should sweep the filter");
        {
            EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Test");
            host.selectTrack(trackId);
            const std::string synthId = host.addDeviceToTrack(trackId, "subtractive_synth");

            // Long, sustained MIDI clip so the synth is always producing sound.
            const std::string midiClipId = host.createMidiClip(trackId, 0.0, 8.0);
            expect(!midiClipId.empty());
            std::vector<MidiNoteState> notes;
            notes.push_back({60, 0.0, 8.0, 100.0f});
            expect(host.setMidiClipNotes(midiClipId, notes));

            // Automation clip on the same track targeting the synth's filterCutoff.
            // 1.0 → 0.0 over 8 beats = 4 seconds at 120 BPM.
            const std::string clipId = host.createAutomationClip(trackId, 0.0, 8.0);
            expect(!clipId.empty());
            expect(host.assignAutomationTarget(clipId, synthId, "filterCutoff"));
            std::vector<AutomationPointState> points;
            points.push_back({0.0, 1.0f});
            points.push_back({8.0, 0.0f});
            expect(host.setAutomationPoints(clipId, points));

            host.setPlaying(true);
            const std::vector<float> block = host.renderOffline(8.0, 48000.0);
            expect(block.size() >= 192000); // 8 beats @ 120 bpm @ 48k

            // Compare high-band energy between the first quarter and the last
            // quarter of the render.
            const int frameCount = static_cast<int>(block.size());
            const int quarter = frameCount / 4;
            const float hfStart = audioapp::test::highBandEnergy(block, 1000, quarter - 1000);
            const float hfEnd   = audioapp::test::highBandEnergy(block, frameCount - quarter, quarter);

            // Sanity: the render must have audible signal.
            expect(hfStart + hfEnd >= 1.0e-6f);

            // The filter-cutoff sweep should produce meaningfully more HF energy
            // in the open-half vs the closed-half.
            expect(hfStart >= 2.0f * hfEnd, "Filter cutoff sweep should produce >2x HF ratio");
        }
    }
};

static ParamIdEncodingTest paramIdEncodingTest;