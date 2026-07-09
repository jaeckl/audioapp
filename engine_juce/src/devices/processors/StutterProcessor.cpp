#include "audioapp/devices/processors/StutterProcessor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

bool StutterProcessor::ensureBuffers(ProcessContext& ctx) noexcept {
    if (bufferLeft_ != nullptr) return true;
    auto [bufL, bufR] = ctx.scratch.ringBufferArena.allocate();
    if (bufL == nullptr || bufR == nullptr) return false;
    bufferLeft_ = bufL;
    bufferRight_ = bufR;
    std::memset(bufferLeft_, 0, DeviceChainScratchArena::kBufferSize * sizeof(float));
    std::memset(bufferRight_, 0, DeviceChainScratchArena::kBufferSize * sizeof(float));
    return true;
}

void StutterProcessor::captureNow() noexcept {
    capturedWriteIndex_ = writeIndex_;
    repeatPhase_ = 0;
    repeatCounter_ = 0;
}

float StutterProcessor::envelopeFor(int phase, int activeSamples, int fadeSamples) noexcept {
    if (phase < 0 || phase >= activeSamples) return 0.0f;
    if (fadeSamples <= 0) return 1.0f;
    const int releaseStart = std::max(0, activeSamples - fadeSamples);
    float env = 1.0f;
    if (phase < fadeSamples) {
        env = std::min(env, static_cast<float>(phase) / static_cast<float>(fadeSamples));
    }
    if (phase >= releaseStart) {
        env = std::min(env, static_cast<float>(activeSamples - phase) / static_cast<float>(fadeSamples));
    }
    return std::clamp(env, 0.0f, 1.0f);
}

void StutterProcessor::resetPlaybackState() noexcept {
    writeIndex_ = 0;
    capturedWriteIndex_ = 0;
    repeatPhase_ = 0;
    repeatCounter_ = 0;
    wasTriggered_ = false;
    tailPeak_ = 0.0f;
    if (bufferLeft_ != nullptr) {
        std::memset(bufferLeft_, 0, DeviceChainScratchArena::kBufferSize * sizeof(float));
    }
    if (bufferRight_ != nullptr) {
        std::memset(bufferRight_, 0, DeviceChainScratchArena::kBufferSize * sizeof(float));
    }
}

void StutterProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    auto p = std::get<StutterParamsPlayback>(*ctx.modulatedParams);
    if (!ensureBuffers(ctx)) return;

    const int maxBuffer = DeviceChainScratchArena::kBufferSize;
    const int captureSamples = std::clamp(
        static_cast<int>(std::round((std::clamp(p.captureMs, 1.0f, 4000.0f) / 1000.0f) * ctx.sampleRate)),
        1, maxBuffer - 1);
    const int rateSamples = std::max(1, static_cast<int>(
        std::round((std::clamp(p.rateMs, 1.0f, 5000.0f) / 1000.0f) * ctx.sampleRate)));
    const int windowSamples = std::clamp(
        static_cast<int>(std::round((std::clamp(p.windowMs, 1.0f, 5000.0f) / 1000.0f) * ctx.sampleRate)),
        1, captureSamples);
    const int gateSamples = std::clamp(
        static_cast<int>(std::round(rateSamples * std::clamp(p.gate, 0.0f, 1.0f))),
        0, rateSamples);
    const int fadeSamples = std::clamp(
        static_cast<int>(std::round((std::clamp(p.fadeMs, 0.0f, 250.0f) / 1000.0f) * ctx.sampleRate)),
        0, std::max(0, gateSamples / 2));
    const int positionRange = std::max(0, captureSamples - windowSamples);
    const int baseOffset = static_cast<int>(std::round(std::clamp(p.position, 0.0f, 1.0f) * positionRange));
    const int directionMode = std::clamp(static_cast<int>(std::round(p.direction)), 0, 4);
    const bool triggered = p.trigger >= 0.5f;
    const float mix = std::clamp(p.mix, 0.0f, 1.0f);
    const float duck = std::clamp(p.duck, 0.0f, 1.0f);
    const float outputGain = std::clamp(p.outputGain, 0.0f, 2.0f);

    if (triggered && !wasTriggered_) {
        captureNow();
    }
    wasTriggered_ = triggered;

    float blockPeak = 0.0f;
    for (int f = 0; f < block.numSamples; ++f) {
        const float dryL = block.channelL[f];
        const float dryR = block.channelR[f];

        if (!triggered) {
            bufferLeft_[writeIndex_] = dryL;
            bufferRight_[writeIndex_] = dryR;
            writeIndex_ = (writeIndex_ + 1) % maxBuffer;
            block.channelL[f] = dryL * outputGain;
            block.channelR[f] = dryR * outputGain;
            blockPeak = std::max(blockPeak, std::max(std::abs(block.channelL[f]), std::abs(block.channelR[f])));
            continue;
        }

        if (repeatPhase_ >= rateSamples) {
            repeatPhase_ = 0;
            ++repeatCounter_;
        }

        bool reverse = false;
        switch (directionMode) {
            case 1: reverse = true; break;
            case 2: reverse = (repeatCounter_ & 1) != 0; break;
            case 3: reverse = (repeatCounter_ & 1) != 0; break;
            case 4: reverse = (((repeatCounter_ * 1103515245u + 12345u) >> 16) & 1u) != 0u; break;
            default: break;
        }

        const int windowPhase = repeatPhase_ % windowSamples;
        const int playbackOffset = reverse
            ? baseOffset + (windowSamples - 1 - windowPhase)
            : baseOffset + windowPhase;
        const int readIndex = (capturedWriteIndex_ - captureSamples + playbackOffset + maxBuffer) % maxBuffer;
        const float env = envelopeFor(repeatPhase_, gateSamples, fadeSamples);
        const float wetL = bufferLeft_[readIndex] * env;
        const float wetR = bufferRight_[readIndex] * env;
        const float dryGain = 1.0f - mix * duck * env;

        block.channelL[f] = (dryL * dryGain * (1.0f - mix) + wetL * mix) * outputGain;
        block.channelR[f] = (dryR * dryGain * (1.0f - mix) + wetR * mix) * outputGain;
        blockPeak = std::max(blockPeak, std::max(std::abs(block.channelL[f]), std::abs(block.channelR[f])));
        ++repeatPhase_;
    }

    tailPeak_ = blockPeak;
    if (ctx.deviceMeters != nullptr && meterSlot >= 0 && meterSlot < ctx.maxDeviceMeters) {
        ctx.deviceMeters[meterSlot].gainReductionDb.store(0.0f, std::memory_order_relaxed);
        ctx.deviceMeters[meterSlot].inputPeak.store(blockPeak, std::memory_order_relaxed);
    }
}

} // namespace audioapp
