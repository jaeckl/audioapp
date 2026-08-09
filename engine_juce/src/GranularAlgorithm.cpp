#include "audioapp/GranularAlgorithm.hpp"
#include "audioapp/GranularGrainSimd.hpp"
#include "audioapp/ClipContentPlayback.hpp"
#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/DeviceChainAutomationModulation.hpp"
#include "audioapp/instruments/PerNoteModulation.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {
namespace {

constexpr float kPi = 3.14159265358979323846f;

static constexpr float kVowels[6][3] = {
    {800, 1150, 2900}, {400, 1700, 2600}, {350, 2000, 2800},
    {450, 800, 2830}, {325, 700, 2530}, {500, 1200, 2400}};
static constexpr float kFormPoints[6][2] = {
    {0.5f, 0.05f}, {0.88f, 0.25f}, {0.88f, 0.75f},
    {0.12f, 0.25f}, {0.12f, 0.75f}, {0.5f, 0.95f}};

static inline float safe_clamp(float v, float lo, float hi) noexcept {
    if (!std::isfinite(v)) return lo;
    return std::clamp(v, lo, hi);
}

static float beatAtFrame(double playheadStartBeat, int frameIndex, double sampleRate, int bpm) {
    const double seconds = static_cast<double>(frameIndex) / sampleRate;
    return static_cast<float>(playheadStartBeat + seconds * static_cast<double>(bpm) / 60.0);
}

static GranularParams heldGranularParamsAtFrame(
    const GranularParams& base,
    int heldFrame,
    double blockStartBeat,
    double sampleRate,
    int bpm,
    bool useAutomation,
    const AutomationClipPlayback* automationClips,
    int automationClipCount,
    const uint16_t* automationDeviceIndex,
    uint64_t automationTargetNodeId,
    bool useModulation,
    const float* lfoValues,
    int lfoCount,
    int lfoStride,
    const ModulationEdgePlayback* modEdges,
    int modEdgeCount,
    const uint16_t* modulationDeviceIndex,
    const InstrumentModulationContext* instMod) noexcept {
    GranularParams held = base;
    const double beat = beatAtFrame(blockStartBeat, heldFrame, sampleRate, bpm);
    if (useAutomation) {
        DeviceVariantParams variant = held;
        applyDspAutomationAtBeat(variant,
                                 DeviceNodeKind::Granular,
                                 automationTargetNodeId,
                                 *automationDeviceIndex,
                                 beat,
                                 automationClips,
                                 automationClipCount);
        if (const auto* automated = std::get_if<GranularParams>(&variant)) {
            held = *automated;
            held.pcm = base.pcm;
            held.frameCount = base.frameCount;
            held.pcmRate = base.pcmRate;
        }
    }
    if (useModulation && instMod != nullptr) {
        DeviceVariantParams variant = held;
        applyGlobalDspModulationAtFrame(variant,
                                        DeviceNodeKind::Granular,
                                        instMod->deviceIndex,
                                        heldFrame,
                                        lfoStride,
                                        *instMod);
        if (const auto* modulated = std::get_if<GranularParams>(&variant)) {
            held = *modulated;
            held.pcm = base.pcm;
            held.frameCount = base.frameCount;
            held.pcmRate = base.pcmRate;
        }
    } else if (useModulation) {
        for (int e = 0; e < modEdgeCount; ++e) {
            const ModulationEdgePlayback& edge = modEdges[e];
            if (edge.deviceIndex != *modulationDeviceIndex) continue;
            if (edge.lfoId >= static_cast<uint16_t>(lfoCount)) continue;
            const uint16_t pid = edge.localParamId;
            if (pid == kEncodedCommonGain || pid == kEncodedCommonPan ||
                pid == kEncodedCommonBypass) {
                continue;
            }
            const float lfoOut = lfoValues[static_cast<size_t>(edge.lfoId) *
                                              static_cast<size_t>(lfoStride) +
                                              static_cast<size_t>(heldFrame)];
            DeviceChainAutomationModulation::applyModulation(held, edge.amount * lfoOut, pid);
        }
    }
    return held;
}

} // namespace

void granularVowelFormPoint(int vowel, float& formX, float& formY) noexcept {
    const int idx = std::clamp(vowel, 0, 5);
    formX = kFormPoints[idx][0];
    formY = kFormPoints[idx][1];
}

void granularBlendFormants(float formX, float formY, float outHz[3]) noexcept {
    float weightSum = 0.0f;
    outHz[0] = outHz[1] = outHz[2] = 0.0f;
    for (int voice = 0; voice < 6; ++voice) {
        const float dx = formX - kFormPoints[voice][0];
        const float dy = formY - kFormPoints[voice][1];
        const float weight = std::exp(-(dx * dx + dy * dy) / 0.075f);
        weightSum += weight;
        for (int band = 0; band < 3; ++band) {
            outHz[band] += kVowels[voice][band] * weight;
        }
    }
    const float inv = 1.0f / std::max(weightSum, 0.0001f);
    for (int band = 0; band < 3; ++band) {
        outHz[band] *= inv;
    }
}

void granularCookFormantControl(float formX,
                                float formY,
                                float formantNorm,
                                float character,
                                float sampleRate,
                                GranularFormantControl& out) noexcept {
    granularBlendFormants(formX, formY, out.blendedHz);
    out.shift = std::pow(2.0f, (formantNorm - 0.5f) * 2.0f);
    out.radius = 0.94f + character * 0.045f;
    const float sr = std::max(sampleRate, 1.0f);
    for (int band = 0; band < 3; ++band) {
        const float hz = std::min(out.blendedHz[band] * out.shift, sr * 0.42f);
        out.coefficients[band] = 2.0f * out.radius * std::cos(2.0f * kPi * hz / sr);
    }
}

void granularRenderVoiceGrains(const GranularParams& params,
                               int pitch,
                               float velocity,
                               double elapsedSec,
                               double noteDurationSec,
                               float attackSec,
                               float releaseSec,
                               double sampleRate,
                               bool stereoSpread,
                               float& leftOut,
                               float& rightOut) noexcept {
    leftOut = 0.0f;
    rightOut = 0.0f;
    if (params.pcm == nullptr || params.frameCount < 4 || elapsedSec < 0.0) {
        return;
    }

    const float amp = elapsedSec < attackSec
        ? static_cast<float>(elapsedSec / attackSec)
        : (elapsedSec <= noteDurationSec
               ? 1.0f
               : std::max(0.0f, 1.0f - static_cast<float>(
                                            (elapsedSec - noteDurationSec) / releaseSec)));
    if (amp <= 0.0f) {
        return;
    }

    const float density = 5.0f + params.density * 39.0f;
    const float grainSeconds = 0.012f + params.size * 0.18f;
    const double regionStart = std::clamp(static_cast<double>(params.regionStart), 0.0, 0.98);
    const double regionEnd =
        std::clamp(static_cast<double>(params.regionEnd), regionStart + 0.02, 1.0);
    const double regionLength = regionEnd - regionStart;
    const double semitones = (pitch - 60) + (params.pitch - 0.5f) * 48.0f;
    const double ratio = std::pow(2.0, semitones / 12.0) * params.pcmRate / sampleRate;
    const auto newestGrain = static_cast<int64_t>(std::floor(elapsedSec * density));

    float phases[kGranularMaxGrains]{};
    float positions[kGranularMaxGrains]{};
    float pans[kGranularMaxGrains]{};
    int active = 0;

    for (int grain = 0; grain < kGranularMaxGrains; ++grain) {
        const int64_t grainNumber = newestGrain - grain;
        if (grainNumber < 0) continue;
        const double spawnTime = static_cast<double>(grainNumber) / density;
        const double age = elapsedSec - spawnTime;
        if (age < 0.0 || age >= grainSeconds) continue;

        const double grainPhase = age / grainSeconds;
        const double random = std::sin((static_cast<double>(grainNumber) + pitch * 17.0) * 12.9898);
        const double scan = regionStart + regionLength * std::fmod(
            params.position + spawnTime * (params.scan - 0.5f) * 0.35 + 4.0, 1.0);
        const double jitter = random * params.spray * regionLength * 0.14;
        const double start = std::clamp(scan + jitter, regionStart, regionEnd) * params.frameCount;
        double position = start + grainPhase * grainSeconds * sampleRate * ratio;
        const double first = regionStart * (params.frameCount - 1);
        const double span = std::max(2.0, regionLength * (params.frameCount - 1));
        position = first + std::fmod(std::max(0.0, position - first), span);

        phases[active] = static_cast<float>(grainPhase);
        positions[active] = static_cast<float>(position);
        pans[active] = safe_clamp(0.5f + static_cast<float>(random) * params.spread * 0.48f, 0.0f, 1.0f);
        ++active;
    }

    if (active <= 0) {
        return;
    }

    const float vel = velocity / 127.0f;
    const float grainAmp = amp * vel;
    float left = 0.0f;
    float right = 0.0f;
    if (!renderGranularGrainBankSimd(params.pcm,
                                     params.frameCount,
                                     phases,
                                     positions,
                                     pans,
                                     active,
                                     grainAmp,
                                     left,
                                     right,
                                     stereoSpread)) {
        for (int i = 0; i < active; ++i) {
            const float window = 0.5f - 0.5f * std::cos(phases[i] * 2.0f * kPi);
            const int index = std::min(static_cast<int>(positions[i]), params.frameCount - 2);
            const float fraction = positions[i] - static_cast<float>(index);
            const float sample =
                params.pcm[index] * (1.0f - fraction) + params.pcm[index + 1] * fraction;
            const float value = sample * window * grainAmp;
            if (stereoSpread) {
                left += value * std::sqrt(1.0f - pans[i]);
                right += value * std::sqrt(pans[i]);
            } else {
                left += value;
            }
        }
        if (!stereoSpread) {
            right = left;
        }
    }

    const float grainGain = 0.7f / std::sqrt(static_cast<float>(active));
    leftOut = left * grainGain;
    rightOut = right * grainGain;
}

void granularProcessFormantStereo(float leftIn,
                                  float rightIn,
                                  const GranularFormantControl& ctrl,
                                  GranularFormantFilterState& state,
                                  float& leftOut,
                                  float& rightOut) noexcept {
    const float input[2] = {leftIn, rightIn};
    float shaped[2]{};
    for (int channel = 0; channel < 2; ++channel) {
        for (int band = 0; band < 3; ++band) {
            const float value = (1.0f - ctrl.radius) * input[channel] +
                                ctrl.coefficients[band] * state.z1[channel][band] -
                                ctrl.radius * ctrl.radius * state.z2[channel][band];
            state.z2[channel][band] = state.z1[channel][band];
            state.z1[channel][band] = value;
            shaped[channel] += value;
        }
    }
    leftOut = shaped[0];
    rightOut = shaped[1];
}

float granularProcessFormantMono(float input,
                                 const GranularFormantControl& ctrl,
                                 float z1[3],
                                 float z2[3]) noexcept {
    float shaped = 0.0f;
    for (int band = 0; band < 3; ++band) {
        const float value = (1.0f - ctrl.radius) * input +
                            ctrl.coefficients[band] * z1[band] -
                            ctrl.radius * ctrl.radius * z2[band];
        z2[band] = z1[band];
        z1[band] = value;
        shaped += value;
    }
    return shaped;
}

float granularLiveVoiceSample(const GranularParams& params,
                              int pitch,
                              float velocity,
                              double elapsedSec,
                              double noteDurationSec,
                              double sampleRate,
                              float z1[3],
                              float z2[3]) noexcept {
    const float attackSec = 0.002f + params.attack * params.attack * 1.5f;
    const float releaseSec = 0.015f + params.release * params.release * 2.0f;
    float left = 0.0f;
    float right = 0.0f;
    granularRenderVoiceGrains(params,
                              pitch,
                              velocity,
                              elapsedSec,
                              noteDurationSec,
                              attackSec,
                              releaseSec,
                              sampleRate,
                              false,
                              left,
                              right);
    if (left == 0.0f && right == 0.0f) {
        return 0.0f;
    }

    GranularFormantControl ctrl{};
    granularCookFormantControl(params.formX,
                               params.formY,
                               params.formant,
                               params.character,
                               static_cast<float>(sampleRate),
                               ctrl);
    const float shaped = granularProcessFormantMono(left, ctrl, z1, z2);
    const float wet = std::sqrt(safe_clamp(params.character, 0.0f, 1.0f));
    return (left * (1.0f - wet) + shaped * wet * 2.1f) * 0.36f;
}

void mixGranularMidiNotesBlock(float* leftOut,
                               float* rightOut,
                               int numFrames,
                               double sampleRate,
                               int bpm,
                               double playheadStartBeat,
                               const MidiPlaybackNote* notes,
                               int noteCount,
                               const GranularParams& params,
                               GranularFormantFilterState& formantState,
                               const AutomationClipPlayback* automationClips,
                               int automationClipCount,
                               const uint16_t* automationDeviceIndex,
                               const float* lfoValues,
                               int lfoCount,
                               int lfoStride,
                               const ModulationEdgePlayback* modEdges,
                               int modEdgeCount,
                               const uint16_t* modulationDeviceIndex,
                               const InstrumentModulationContext* instMod,
                                const CommonControlBlock* commonControls,
                                uint64_t automationTargetNodeId) noexcept {
    if (leftOut == nullptr || rightOut == nullptr || numFrames <= 0 || notes == nullptr ||
        noteCount <= 0 || bpm <= 0 || params.pcm == nullptr || params.frameCount < 4) {
        return;
    }

    const bool useAutomation = automationClips != nullptr && automationClipCount > 0 &&
                               automationDeviceIndex != nullptr;
    const bool useModulation = lfoValues != nullptr && lfoCount > 0 && lfoStride > 0 &&
                               modEdges != nullptr && modEdgeCount > 0 &&
                               modulationDeviceIndex != nullptr;
    const bool needsHeldParams = useAutomation || useModulation;
    const double blockStartBeat = playheadStartBeat;
    const double beatsPerFrame =
        static_cast<double>(std::max(bpm, 1)) / 60.0 / sampleRate;

    auto renderFrame = [&](int frame, const GranularParams& held,
                           const GranularFormantControl& formant) {
        float left = 0.0f;
        float right = 0.0f;
        const double beat = blockStartBeat + frame * beatsPerFrame;
        const float attackSec = 0.002f + held.attack * held.attack * 1.5f;
        const float releaseSec = 0.015f + held.release * held.release * 2.0f;
        int voices = 0;

        for (int noteIndex = 0; noteIndex < noteCount && voices < kGranularMaxClipVoices;
             ++noteIndex) {
            const auto& note = notes[noteIndex];
            const double local = beatWithinClipContent(beat,
                                                       note.clipStartBeat,
                                                       note.clipLengthBeats,
                                                       note.contentLengthBeats,
                                                       note.loopContent);
            if (local < note.noteStartBeat) continue;
            const double elapsed = (local - note.noteStartBeat) * 60.0 / std::max(bpm, 1);
            const double duration = note.noteDurationBeats * 60.0 / std::max(bpm, 1);
            if (elapsed > duration + releaseSec) continue;

            GranularParams voiceParams = held;
            if (instMod != nullptr) {
                const NoteModKey key =
                    noteModKeyFromRegion(note.pitch, note.clipStartBeat, note.noteStartBeat);
                const ModulationEvalContext evalCtx = instMod->evalContextForFrame(frame);
                DeviceVariantParams variant = voiceParams;
                applyPerNoteDspModulation(variant,
                                          DeviceNodeKind::Granular,
                                          instMod->deviceIndex,
                                          elapsed,
                                          duration,
                                          key,
                                          evalCtx,
                                          *instMod);
                if (const auto* modulated = std::get_if<GranularParams>(&variant)) {
                    voiceParams = *modulated;
                    voiceParams.pcm = held.pcm;
                    voiceParams.frameCount = held.frameCount;
                    voiceParams.pcmRate = held.pcmRate;
                }
            }

            float voiceLeft = 0.0f;
            float voiceRight = 0.0f;
            granularRenderVoiceGrains(voiceParams,
                                      note.pitch,
                                      note.velocity,
                                      elapsed,
                                      duration,
                                      attackSec,
                                      releaseSec,
                                      sampleRate,
                                      true,
                                      voiceLeft,
                                      voiceRight);
            left += voiceLeft;
            right += voiceRight;
            ++voices;
        }

        float shapedL = 0.0f;
        float shapedR = 0.0f;
        granularProcessFormantStereo(left, right, formant, formantState, shapedL, shapedR);
        const float wet = std::sqrt(safe_clamp(held.character, 0.0f, 1.0f));
        const float commonGain = commonControls != nullptr ? commonControls->gainAt(frame) : 1.0f;
        const float panAngle =
            safe_clamp(commonControls != nullptr ? commonControls->panAt(frame) : 0.5f, 0.0f, 1.0f) *
            kPi * 0.5f;
        constexpr float centerCompensation = 1.41421356237f;
        leftOut[frame] += (left * (1.0f - wet) + shapedL * wet * 2.1f) * 0.36f * commonGain *
                          std::cos(panAngle) * centerCompensation;
        rightOut[frame] += (right * (1.0f - wet) + shapedR * wet * 2.1f) * 0.36f * commonGain *
                           std::sin(panAngle) * centerCompensation;
    };

    auto cookHeld = [&](const GranularParams& held) {
        GranularFormantControl formant{};
        granularCookFormantControl(held.formX,
                                   held.formY,
                                   held.formant,
                                   held.character,
                                   static_cast<float>(sampleRate),
                                   formant);
        return formant;
    };

    if (!needsHeldParams) {
        const GranularFormantControl formant = cookHeld(params);
        for (int frame = 0; frame < numFrames; ++frame) {
            renderFrame(frame, params, formant);
        }
        return;
    }

    for (int sub = 0; sub < numFrames; sub += kGranularControlSubBlockFrames) {
        const GranularParams held = heldGranularParamsAtFrame(
            params,
            sub,
            blockStartBeat,
            sampleRate,
            bpm,
            useAutomation,
            automationClips,
            automationClipCount,
            automationDeviceIndex,
            automationTargetNodeId,
            useModulation,
            lfoValues,
            lfoCount,
            lfoStride,
            modEdges,
            modEdgeCount,
            modulationDeviceIndex,
            instMod);
        const GranularFormantControl formant = cookHeld(held);
        const int subLen = std::min(kGranularControlSubBlockFrames, numFrames - sub);
        for (int frame = sub; frame < sub + subLen; ++frame) {
            renderFrame(frame, held, formant);
        }
    }
}

} // namespace audioapp
