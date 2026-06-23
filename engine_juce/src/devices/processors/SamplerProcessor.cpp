#include "audioapp/devices/processors/SamplerProcessor.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/DeviceChainAutomationModulation.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include "audioapp/devices/DevicePanelTypes.hpp"
#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

namespace {

static inline float safe_clamp(float v, float lo, float hi) noexcept {
    if (!std::isfinite(v)) return lo;
    return std::clamp(v, lo, hi);
}

double beatAtFrame(double playheadStartBeat, int frameIndex, double sampleRate, int bpm) {
    const double seconds = static_cast<double>(frameIndex) / sampleRate;
    return playheadStartBeat + seconds * static_cast<double>(bpm) / 60.0;
}

bool isSamplerMidiNoteAudible(const SamplerMidiNoteRegion& note,
                              double beat,
                              int bpm,
                              float releaseSec,
                              double& elapsedSecondsOut) noexcept {
    if (beat < note.clipStartBeat || beat >= note.clipStartBeat + note.clipLengthBeats || bpm <= 0) {
        return false;
    }

    const double posInClip = beat - note.clipStartBeat;
    const double loopedBeat = std::fmod(posInClip, note.clipLengthBeats);
    const double noteStart = note.noteStartBeat;
    const double noteEnd = note.noteStartBeat + note.noteDurationBeats;
    const double releaseBeats =
        static_cast<double>(releaseSec) * static_cast<double>(bpm) / 60.0;

    if (loopedBeat < noteStart) {
        return false;
    }

    const double elapsedBeats = loopedBeat - noteStart;
    elapsedSecondsOut = elapsedBeats * 60.0 / static_cast<double>(bpm);

    if (loopedBeat < noteEnd) {
        return true;
    }
    return loopedBeat < noteEnd + releaseBeats;
}

} // anonymous namespace

// mixSamplerMidiNotesBlock is at audioapp namespace scope (NOT in anonymous
// namespace) because it is called from EngineHost_commands.cpp in a different
// translation unit (the preset-preview renderer).

void mixSamplerMidiNotesBlock(float* monoOut,
                              int numFrames,
                              double sampleRate,
                              int bpm,
                              double playheadStartBeat,
                              const SamplerMidiNoteRegion* notes,
                              int noteCount,
                              const SamplerInstrumentPlayback& sampler) {
    if (monoOut == nullptr || numFrames <= 0 || notes == nullptr || noteCount <= 0 || bpm <= 0) {
        return;
    }
    if (sampler.pcm == nullptr || sampler.frameCount <= 0 || sampler.pcmSampleRate <= 0.0) {
        return;
    }

    const float attackSec = adsrNormalizedToSeconds(sampler.attack, 2.0f);
    const float decaySec = adsrNormalizedToSeconds(sampler.decay, 2.0f);
    const float releaseSec = adsrNormalizedToSeconds(sampler.release, 3.0f);
    const float sustainLevel = safe_clamp(sampler.sustain, 0.0f, 1.0f);
    const float filterAttackSec = adsrNormalizedToSeconds(sampler.filterAttack, 2.0f);
    const float filterDecaySec = adsrNormalizedToSeconds(sampler.filterDecay, 2.0f);
    const float filterReleaseSec = adsrNormalizedToSeconds(sampler.filterRelease, 3.0f);
    const float filterSustainLevel = safe_clamp(sampler.filterSustain, 0.0f, 1.0f);
    const bool usePerNoteFilter =
        sampler.noteFilterStates != nullptr && sampler.noteFilterStateCount > 0;

    for (int frame = 0; frame < numFrames; ++frame) {
        const double beat = beatAtFrame(playheadStartBeat, frame, sampleRate, bpm);
        float mix = 0.0f;
        for (int noteIndex = 0; noteIndex < noteCount; ++noteIndex) {
            const auto& note = notes[noteIndex];
            double elapsedSeconds = 0.0;
            if (!isSamplerMidiNoteAudible(note, beat, bpm, releaseSec, elapsedSeconds)) {
                continue;
            }

            const float noteDurationSec =
                static_cast<float>(note.noteDurationBeats * 60.0 / static_cast<double>(bpm));
            const float envGain = samplerAdsrGain(elapsedSeconds,
                                                  noteDurationSec,
                                                  attackSec,
                                                  decaySec,
                                                  sustainLevel,
                                                  releaseSec);
            if (envGain <= 0.0f) {
                continue;
            }

            const int startFrame = sampler.trimStartFrame;
            const int endFrame =
                sampler.trimEndFrame > startFrame ? sampler.trimEndFrame : sampler.frameCount;
            if (endFrame - startFrame <= 1) {
                continue;
            }

            const double pitchRatio =
                samplerPitchRatio(note.pitch, sampler.rootPitch, sampler.rootFineTune);

            double readPos = 0.0;
            if (!computeSamplerReadPosition(sampler.playbackMode,
                                            startFrame,
                                            endFrame,
                                            sampler.regionStartFrame,
                                            sampler.regionEndFrame,
                                            elapsedSeconds,
                                            sampler.pcmSampleRate,
                                            pitchRatio,
                                            readPos)) {
                continue;
            }
            const int index = static_cast<int>(readPos);
            const float frac = static_cast<float>(readPos - static_cast<double>(index));
            const int next = std::min(index + 1, sampler.frameCount - 1);
            const float sample =
                sampler.pcm[index] * (1.0f - frac) + sampler.pcm[next] * frac;
            float noteSample = sample * (note.velocity / 100.0f) * envGain;

            if (usePerNoteFilter) {
                const float filterGain = samplerAdsrGain(elapsedSeconds,
                                                         noteDurationSec,
                                                         filterAttackSec,
                                                         filterDecaySec,
                                                         filterSustainLevel,
                                                         filterReleaseSec);
                auto& noteFilter = sampler.noteFilterStates[noteIndex];
                noteSample = processSamplerFilteredSample(noteSample,
                                                          noteFilter,
                                                          sampler.filterMode,
                                                          static_cast<float>(sampleRate),
                                                          sampler.filterCutoff,
                                                          sampler.filterQ,
                                                          filterGain,
                                                          sampler.filterEnvAmount);
            }
            mix += noteSample;
        }
        if (!usePerNoteFilter && sampler.filterState != nullptr) {
            const float targetCutoffHz = normalizedCutoffToHz(sampler.filterCutoff);
            if (sampler.filterState->lastCutoffHz <= 0.0f) {
                sampler.filterState->lastCutoffHz = targetCutoffHz;
            } else {
                sampler.filterState->lastCutoffHz += (targetCutoffHz - sampler.filterState->lastCutoffHz) * 0.05f;
            }
            BiquadCoeffs filterCoeffs{};
            cookSamplerBiquad(filterCoeffs,
                              sampler.filterMode,
                              static_cast<float>(sampleRate),
                              sampler.filterState->lastCutoffHz,
                              normalizedQToValue(sampler.filterQ));
            mix = processBiquadSample(mix, filterCoeffs, *sampler.filterState);
        }
        monoOut[frame] += mix * sampler.gain;
    }
}

void SamplerProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (ctx.suppressInstruments) {
        return;
    }

    const auto& baseParams = std::get<SamplerParams>(*ctx.modulatedParams);
    if (baseParams.samplerPcm == nullptr || ctx.noteCount <= 0) {
        return;
    }

    const double beatsPerFrame = (static_cast<double>(std::max(ctx.bpm, 1)) / 60.0) / ctx.sampleRate;

    const int regionCount = ctx.noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : ctx.noteCount;
    for (int i = 0; i < regionCount; ++i) {
        const MidiPlaybackNote& note = ctx.notes[i];
        ctx.scratch.samplerRegions[i] = SamplerMidiNoteRegion{
            note.pitch, note.clipStartBeat, note.clipLengthBeats,
            note.noteStartBeat, note.noteDurationBeats, note.velocity,
        };
    }

    std::memset(ctx.scratch.scratch, 0, static_cast<size_t>(block.numSamples) * sizeof(float));

    std::memset(ctx.scratch.samplerNoteFilterStates, 0, sizeof(ctx.scratch.samplerNoteFilterStates));
    BiquadState* effectiveNoteFilters = samplerFilterStates_;

    const auto render = [&](int sub, int subLen, double subBeat, const SamplerParams& p) {
        mixSamplerMidiNotesBlock(ctx.scratch.scratch + sub, subLen, ctx.sampleRate, ctx.bpm, subBeat,
            ctx.scratch.samplerRegions, regionCount, SamplerInstrumentPlayback{
                p.samplerPcm, p.samplerFrameCount, p.samplerPcmSampleRate,
                kInstrumentOutputGain, p.rootPitch, p.rootFineTune,
                p.attack, p.decay, p.sustain, p.release,
                p.filterCutoff, p.filterQ, p.filterMode,
                p.filterEnvAmount, p.filterAttack, p.filterDecay, p.filterSustain, p.filterRelease,
                p.trimStartFrame, p.trimEndFrame, p.regionStartFrame, p.regionEndFrame,
                p.playbackMode, nullptr, effectiveNoteFilters, regionCount,
            });
    };

    if (ctx.needsSubBlocks) {
        DeviceNodePlayback tmpNode;
        tmpNode.params = *ctx.modulatedParams;
        tmpNode.kind = kind();
        for (int sub = 0; sub < block.numSamples; sub += kAutomationSubBlockFrames) {
            const int subLen = std::min(kAutomationSubBlockFrames, block.numSamples - sub);
            const double subBeat = ctx.playheadBeat + static_cast<double>(sub) * beatsPerFrame;
            auto subParams = DeviceChainAutomationModulation::dspParamsAtFrame(
                tmpNode, ctx.deviceIndex, subBeat, sub, block.numSamples,
                ctx.automationClips, ctx.automationClipCount, ctx.lfoValues, ctx.lfoCount,
                ctx.modEdges, ctx.modEdgeCount);
            const auto p = std::get<SamplerParams>(subParams);
            render(sub, subLen, subBeat, p);
        }
    } else {
        render(0, block.numSamples, ctx.playheadBeat, baseParams);
    }

    StereoOutputPanel::applyFromScratch(ctx.scratch.scratch, block, block.numSamples,
                                         ctx.scratch.perFrameGain, ctx.scratch.perFramePan);
}

} // namespace audioapp