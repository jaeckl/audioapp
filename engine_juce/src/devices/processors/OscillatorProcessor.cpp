#include "audioapp/devices/processors/OscillatorProcessor.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/DeviceChainAutomationModulation.hpp"
#include "audioapp/MidiUtils.hpp"
#include "audioapp/MasterMix.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include "audioapp/devices/DevicePanelTypes.hpp"
#include <algorithm>
#include <cstring>
#include <cmath>

namespace audioapp {

void OscillatorProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (ctx.suppressInstruments) {
        return;
    }

    const double beatsPerFrame = (static_cast<double>(std::max(ctx.bpm, 1)) / 60.0) / ctx.sampleRate;

    auto midiActiveFrequencyHz = [&](float idleFrequencyHz) noexcept {
        auto noteActive = [](const MidiPlaybackNote& note, double beat) {
            if (beat < note.clipStartBeat || beat >= note.clipStartBeat + note.clipLengthBeats) {
                return false;
            }
            const double posInClip = beat - note.clipStartBeat;
            const double loopedBeat = std::fmod(posInClip, note.clipLengthBeats);
            const double noteEnd = std::min(note.noteStartBeat + note.noteDurationBeats, note.clipLengthBeats);
            return loopedBeat >= note.noteStartBeat && loopedBeat < noteEnd;
        };
        int pitch = -1;
        for (int i = 0; i < ctx.noteCount; ++i) {
            if (!noteActive(ctx.notes[i], ctx.playheadBeat)) continue;
            pitch = ctx.notes[i].pitch;
        }
        if (pitch >= 0) {
            // MIDI note active: apply modulation offset on top of MIDI note pitch.
            // idleFrequencyHz already includes LFO/automation modulation from
            // dspParamsAtFrame. Compute the offset from the base frequency.
            const float baseHz = std::get<OscillatorParams>(storedParams()).frequencyHz;
            const float modOffset = idleFrequencyHz - baseHz;
            return std::max(20.0f, midiNoteToHz(pitch) + modOffset);
        }
        return idleFrequencyHz;
    };

    std::memset(ctx.scratch.scratch, 0, static_cast<size_t>(block.numSamples) * sizeof(float));

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
            auto p = std::get<OscillatorParams>(subParams);
            p.frequencyHz = midiActiveFrequencyHz(p.frequencyHz);
            if (p.frequencyHz > 0.0f) {
                addSineBlock(ctx.scratch.scratch + sub, subLen, ctx.sampleRate, p.frequencyHz,
                             oscillatorPhase_, kInstrumentOutputGain);
            }
        }
    } else {
        auto p = std::get<OscillatorParams>(*ctx.modulatedParams);
        p.frequencyHz = midiActiveFrequencyHz(p.frequencyHz);
        if (p.frequencyHz > 0.0f) {
            addSineBlock(ctx.scratch.scratch, block.numSamples, ctx.sampleRate, p.frequencyHz,
                         oscillatorPhase_, kInstrumentOutputGain);
        }
    }

    StereoOutputPanel::applyFromScratch(ctx.scratch.scratch, block, block.numSamples,
                                         ctx.scratch.perFrameGain, ctx.scratch.perFramePan);
}

} // namespace audioapp