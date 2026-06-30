#include "audioapp/instruments/PerNoteModulation.hpp"

#include <algorithm>
#include <cmath>

#include "audioapp/DeviceChainAutomationModulation.hpp"
#include "audioapp/modulation/CurveModulator.hpp"
#include "audioapp/modulation/EnvelopeModulator.hpp"
#include "audioapp/modulation/LfoModulator.hpp"
#include "audioapp/modulation/RandomGeneratorModulator.hpp"
#include "audioapp/modulation/SequencerModulator.hpp"

namespace audioapp {

PerNoteModEntry* PerNoteModCache::findOrAlloc(const NoteModKey& key) noexcept {
    PerNoteModEntry* freeSlot = nullptr;
    for (auto& entry : entries) {
        if (entry.inUse && entry.key == key) {
            return &entry;
        }
        if (!entry.inUse && freeSlot == nullptr) {
            freeSlot = &entry;
        }
    }
    if (freeSlot == nullptr) {
        freeSlot = &entries[0];
    }
    freeSlot->key = key;
    freeSlot->inUse = true;
    return freeSlot;
}

ModulationEvalContext InstrumentModulationContext::evalContextForFrame(int frameIndex) const noexcept {
    const double samplePeriod = 1.0 / std::max(sampleRate, 1.0);
    const double secondsWithinBlock = static_cast<double>(frameIndex) * samplePeriod;
    return ModulationEvalContext{
        playheadStartBeat + secondsWithinBlock * (static_cast<double>(std::max(bpm, 1)) / 60.0),
        bpm,
        sampleRate,
        playheadStartBeat * 60.0 / static_cast<double>(std::max(bpm, 1)),
        frameIndex,
        lfoStride,
        retriggerGeneration,
    };
}

bool modulatorUsesPerNoteClock(const IModulator* mod) noexcept {
    return mod != nullptr && mod->usesPerNoteClock();
}

bool deviceHasPerNoteModEdges(uint16_t deviceIndex,
                              const ModulationEdgePlayback* modEdges,
                              int modEdgeCount,
                              IModulator* const* modulators,
                              int modulatorCount) noexcept {
    if (modEdges == nullptr || modEdgeCount <= 0 || modulators == nullptr || modulatorCount <= 0) {
        return false;
    }
    for (int e = 0; e < modEdgeCount; ++e) {
        const auto& edge = modEdges[e];
        if (edge.deviceIndex != deviceIndex) {
            continue;
        }
        if (edge.lfoId >= static_cast<uint16_t>(modulatorCount)) {
            continue;
        }
        if (modulatorUsesPerNoteClock(modulators[edge.lfoId])) {
            return true;
        }
    }
    return false;
}

float evaluateGlobalModulator(IModulator* mod,
                              int modPlaybackIndex,
                              const ModulationEvalContext& ctx,
                              const float* lfoValues,
                              int lfoStride) noexcept {
    if (mod == nullptr) {
        return 0.0f;
    }
    if (lfoValues != nullptr && lfoStride > 0 && modPlaybackIndex >= 0) {
        return lfoValues[static_cast<size_t>(modPlaybackIndex) * static_cast<size_t>(lfoStride)
                         + static_cast<size_t>(ctx.frameIndex)];
    }
    const double samplePeriod = 1.0 / std::max(ctx.sampleRate, 1.0);
    const double secondsWithinBlock = static_cast<double>(ctx.frameIndex) * samplePeriod;
    return mod->evaluate(ctx.playheadBeat,
                         ctx.bpm,
                         secondsWithinBlock,
                         ctx.playheadSeconds,
                         ctx.retriggerGeneration,
                         -1.0);
}

float evaluateModulatorForNote(IModulator* mod,
                               int modPlaybackIndex,
                               const NoteModKey& key,
                               double noteElapsedSeconds,
                               const ModulationEvalContext& ctx,
                               PerNoteModCache& cache) noexcept {
    if (mod == nullptr || noteElapsedSeconds < 0.0) {
        return 0.0f;
    }
    if (!mod->usesPerNoteClock()) {
        return evaluateGlobalModulator(mod, modPlaybackIndex, ctx, nullptr, 0);
    }

    switch (static_cast<ModulatorType>(mod->modulatorType())) {
    case ModulatorType::Envelope:
        return static_cast<EnvelopeModulator*>(mod)->evaluateOnNoteElapsed(noteElapsedSeconds);
    case ModulatorType::Lfo:
        return static_cast<LfoModulator*>(mod)->evaluateOnNoteElapsed(noteElapsedSeconds);
    case ModulatorType::Curve:
        return static_cast<CurveModulator*>(mod)->evaluateOnNoteElapsed(noteElapsedSeconds);
    case ModulatorType::RandomGenerator: {
        PerNoteModEntry* entry = cache.findOrAlloc(key);
        if (entry == nullptr) {
            return 0.0f;
        }
        return static_cast<RandomGeneratorModulator*>(mod)->evaluateForNote(
            noteElapsedSeconds, entry->random[modPlaybackIndex]);
    }
    case ModulatorType::Sequencer: {
        PerNoteModEntry* entry = cache.findOrAlloc(key);
        if (entry == nullptr) {
            return 0.0f;
        }
        return static_cast<SequencerModulator*>(mod)->evaluateForNote(
            noteElapsedSeconds, ctx.bpm, entry->sequencer[modPlaybackIndex]);
    }
    default:
        break;
    }
    return 0.0f;
}

float applyPerNoteCommonGain(float baseGain,
                             uint16_t deviceIndex,
                             double noteElapsedSeconds,
                             const NoteModKey& key,
                             const ModulationEvalContext& ctx,
                             const InstrumentModulationContext& modCtx) noexcept {
    float gain = baseGain;
    if (modCtx.modEdges == nullptr || modCtx.modulators == nullptr) {
        return gain;
    }
    for (int e = 0; e < modCtx.modEdgeCount; ++e) {
        const auto& edge = modCtx.modEdges[e];
        if (edge.deviceIndex != deviceIndex || edge.localParamId != kEncodedCommonGain) {
            continue;
        }
        if (edge.lfoId >= static_cast<uint16_t>(modCtx.lfoCount)) {
            continue;
        }
        auto* mod = modCtx.modulators[edge.lfoId];
        if (!modulatorUsesPerNoteClock(mod)) {
            continue;
        }
        const float lfoOut = evaluateModulatorForNote(
            mod, edge.lfoId, key, noteElapsedSeconds, ctx, *modCtx.noteCache);
        gain = std::clamp(gain + edge.amount * lfoOut, 0.0f, 1.0f);
    }
    return gain;
}

float applyPerNoteCommonPan(float basePan,
                            uint16_t deviceIndex,
                            double noteElapsedSeconds,
                            const NoteModKey& key,
                            const ModulationEvalContext& ctx,
                            const InstrumentModulationContext& modCtx) noexcept {
    float pan = basePan;
    if (modCtx.modEdges == nullptr || modCtx.modulators == nullptr) {
        return pan;
    }
    for (int e = 0; e < modCtx.modEdgeCount; ++e) {
        const auto& edge = modCtx.modEdges[e];
        if (edge.deviceIndex != deviceIndex || edge.localParamId != kEncodedCommonPan) {
            continue;
        }
        if (edge.lfoId >= static_cast<uint16_t>(modCtx.lfoCount)) {
            continue;
        }
        auto* mod = modCtx.modulators[edge.lfoId];
        if (!modulatorUsesPerNoteClock(mod)) {
            continue;
        }
        const float lfoOut = evaluateModulatorForNote(
            mod, edge.lfoId, key, noteElapsedSeconds, ctx, *modCtx.noteCache);
        pan = std::clamp(pan + edge.amount * lfoOut, 0.0f, 1.0f);
    }
    return pan;
}

void applyGlobalDspModulationAtFrame(DeviceVariantParams& params,
                                     DeviceNodeKind kind,
                                     uint16_t deviceIndex,
                                     int lfoFrame,
                                     int framesToProcess,
                                     const InstrumentModulationContext& modCtx) noexcept {
    if (modCtx.lfoValues == nullptr || modCtx.modEdges == nullptr || modCtx.modulators == nullptr) {
        return;
    }
    for (int e = 0; e < modCtx.modEdgeCount; ++e) {
        const auto& edge = modCtx.modEdges[e];
        if (edge.deviceIndex != deviceIndex) {
            continue;
        }
        if (edge.lfoId >= static_cast<uint16_t>(modCtx.lfoCount)) {
            continue;
        }
        const uint16_t pid = edge.localParamId;
        if (pid == kEncodedCommonGain || pid == kEncodedCommonPan) {
            continue;
        }
        if (modulatorUsesPerNoteClock(modCtx.modulators[edge.lfoId])) {
            continue;
        }
        const float lfoOut =
            modCtx.lfoValues[edge.lfoId * framesToProcess + lfoFrame];
        const float modAmount = edge.amount * lfoOut;
        std::visit([&](auto& p) { DeviceChainAutomationModulation::applyModulation(p, modAmount, pid); },
                   params);
    }
}

void applyPerNoteDspModulation(DeviceVariantParams& params,
                               DeviceNodeKind kind,
                               uint16_t deviceIndex,
                               double noteElapsedSeconds,
                               const NoteModKey& key,
                               const ModulationEvalContext& ctx,
                               const InstrumentModulationContext& modCtx) noexcept {
    if (modCtx.modEdges == nullptr || modCtx.modulators == nullptr || modCtx.noteCache == nullptr) {
        return;
    }
    for (int e = 0; e < modCtx.modEdgeCount; ++e) {
        const auto& edge = modCtx.modEdges[e];
        if (edge.deviceIndex != deviceIndex) {
            continue;
        }
        if (edge.lfoId >= static_cast<uint16_t>(modCtx.lfoCount)) {
            continue;
        }
        const uint16_t pid = edge.localParamId;
        if (pid == kEncodedCommonGain || pid == kEncodedCommonPan) {
            continue;
        }
        auto* mod = modCtx.modulators[edge.lfoId];
        if (!modulatorUsesPerNoteClock(mod)) {
            continue;
        }
        const float lfoOut = evaluateModulatorForNote(
            mod, edge.lfoId, key, noteElapsedSeconds, ctx, *modCtx.noteCache);
        const float modAmount = edge.amount * lfoOut;
        std::visit([&](auto& p) { DeviceChainAutomationModulation::applyModulation(p, modAmount, pid); },
                   params);
    }
}

} // namespace audioapp
