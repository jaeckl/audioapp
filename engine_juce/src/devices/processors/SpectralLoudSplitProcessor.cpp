#include "audioapp/devices/processors/SpectralLoudSplitProcessor.hpp"

#include "audioapp/DeviceChainOrchestrator.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/devices/instances/SpectralLoudSplitModel.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <span>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

namespace audioapp {

namespace {

inline void readBin(const float* freq, int bin, int fftSize, float& re, float& im) noexcept {
    if (bin == 0) {
        re = freq[0];
        im = 0.0f;
    } else if (bin == fftSize / 2) {
        re = freq[1];
        im = 0.0f;
    } else {
        re = freq[2 * bin];
        im = freq[2 * bin + 1];
    }
}

inline void writeBin(float* freq, int bin, int fftSize, float re, float im) noexcept {
    if (bin == 0) {
        freq[0] = re;
    } else if (bin == fftSize / 2) {
        freq[1] = re;
    } else {
        freq[2 * bin] = re;
        freq[2 * bin + 1] = im;
    }
}

inline float binMagSq(const float* freq, int bin, int fftSize) noexcept {
    float re = 0.0f, im = 0.0f;
    readBin(freq, bin, fftSize, re, im);
    return re * re + im * im;
}

} // namespace

SpectralLoudSplitProcessor::SpectralLoudSplitProcessor() noexcept {
    stft_.reset(new (std::nothrow) StftState());
    if (stft_ == nullptr) return;
    // Periodic √Hann analysis+synthesis: product = Hann, COLA-flat at 50% hop.
    // (Plain Hann×Hann at 50% is NOT COLA → hop-rate AM / "raspy" buzz.)
    for (int i = 0; i < kFftSize; ++i) {
        const float hann =
            0.5f - 0.5f * std::cos(2.0f * static_cast<float>(M_PI) *
                                   static_cast<float>(i) /
                                   static_cast<float>(kFftSize));
        stft_->window[i] = std::sqrt(std::max(hann, 0.0f));
    }
}

SpectralLoudSplitProcessor::~SpectralLoudSplitProcessor() {
    if (bufferArena_ != nullptr)
        bufferArena_->release(outL_, outR_);
}

bool SpectralLoudSplitProcessor::ensureBuffers(ProcessContext& ctx) noexcept {
    if (outL_ != nullptr) return true;
    auto [oL, oR] = ctx.scratch.ringBufferArena.allocate();
    if (oL == nullptr) {
        ctx.scratch.ringBufferArena.release(oL, oR);
        return false;
    }
    outL_ = oL;
    outR_ = oR;
    bufferArena_ = &ctx.scratch.ringBufferArena;
    return true;
}

float SpectralLoudSplitProcessor::softAboveLin(float mag, float lo, float hi) noexcept {
    if (mag <= lo) return 0.0f;
    if (mag >= hi) return 1.0f;
    const float t = (mag - lo) / (hi - lo);
    return t * t * (3.0f - 2.0f * t);
}

bool SpectralLoudSplitProcessor::bandHasFx(int bandIndex) const noexcept {
    if (playback_ == nullptr || bandIndex < 0 || bandIndex >= kSpectralLoudBands)
        return false;
    return playback_->bands[bandIndex].deviceCount > 0;
}

void SpectralLoudSplitProcessor::runChain(ChainRuntime& runtime, float* left, float* right,
                                          int numSamples, ProcessContext& ctx) noexcept {
    if (!runtime.arena || !runtime.executionOrder.valid()) return;
    DeviceChainOrchestrator::Context sub(*runtime.arena, ctx.scratch);
    sub.trackLeft = left;
    sub.trackRight = right;
    sub.numFrames = numSamples;
    sub.sampleRate = ctx.sampleRate;
    sub.bpm = ctx.bpm;
    sub.playheadStartBeat = ctx.playheadBeat;
    sub.notes = ctx.notes;
    sub.noteCount = ctx.noteCount;
    sub.wavetableBank = ctx.wavetableBank;
    sub.suppressInstruments = ctx.suppressInstruments;
    sub.lfoValues = ctx.lfoValues;
    sub.lfoCount = ctx.lfoCount;
    sub.modulators = ctx.modulators;
    sub.retriggerGeneration = ctx.retriggerGeneration;
    sub.tapGraph = ctx.tapGraph;
    sub.graphTapRuntimes = ctx.graphTapRuntimes;
    sub.graphTapRuntimeCount = ctx.graphTapRuntimeCount;
    sub.compiledDeviceOrder = runtime.executionOrder.deviceIndices.data();
    sub.compiledDeviceOrderCount = runtime.executionOrder.count;
    sub.automationClips = ctx.automationClips;
    sub.automationClipCount = ctx.automationClipCount;
    sub.modEdges = ctx.modEdges;
    sub.modEdgeCount = ctx.modEdgeCount;
    sub.deviceMeters = ctx.deviceMeters;
    sub.maxDeviceMeters = ctx.maxDeviceMeters;
    sub.meterSlotSubscribed = ctx.meterSlotSubscribed;
    DeviceChainScratchGuard scratchGuard(ctx.scratch, numSamples);
    DeviceChainOrchestrator::processChain(sub);
}

void SpectralLoudSplitProcessor::refreshPreviewBinMap(float sampleRate) noexcept {
    if (stft_ == nullptr) return;
    auto& st = *stft_;
    if (std::abs(sampleRate - st.cachedSr) < 0.5f) return;
    st.cachedSr = sampleRate;
    constexpr float kMinHz = 20.0f;
    const float maxHz = std::min(20000.0f, sampleRate * 0.5f);
    const float logRange = std::log(maxHz / kMinHz);
    for (int band = 0; band < kPreviewBands; ++band) {
        const float low =
            kMinHz * std::exp(logRange * static_cast<float>(band) / kPreviewBands);
        const float high =
            kMinHz * std::exp(logRange * static_cast<float>(band + 1) / kPreviewBands);
        const int first = std::max(
            1, static_cast<int>(std::ceil(low * static_cast<float>(kFftSize) / sampleRate)));
        const int last = std::min(
            kFftSize / 2,
            std::max(first, static_cast<int>(
                                std::floor(high * static_cast<float>(kFftSize) / sampleRate))));
        st.previewFirstBin[band] = first;
        st.previewLastBin[band] = last;
    }
}

void SpectralLoudSplitProcessor::fillWindowed(const float* fifo, float* dest) noexcept {
    const auto& st = *stft_;
    for (int i = 0; i < kFftSize; ++i) {
        const int idx = (fifoWrite_ + i) & (kFftSize - 1);
        dest[i] = fifo[idx] * st.window[i];
    }
    std::memset(dest + kFftSize, 0, sizeof(float) * static_cast<size_t>(kFftSize));
}

void SpectralLoudSplitProcessor::ifftMasked(const float* srcFreq, const float* mask,
                                            float* ola) noexcept {
    auto& st = *stft_;
    std::memcpy(st.fftWork, srcFreq, sizeof(float) * static_cast<size_t>(kFftSize * 2));
    for (int bin = 0; bin < kBins; ++bin) {
        float re = 0.0f, im = 0.0f;
        readBin(st.fftWork, bin, kFftSize, re, im);
        writeBin(st.fftWork, bin, kFftSize, re * mask[bin], im * mask[bin]);
    }
    fft_.inverseRealOnly(st.fftWork);
    // √Hann × √Hann = Hann; Hann is COLA at hop=N/2 → scale 1.
    for (int i = 0; i < kFftSize; ++i) {
        const int olaIdx = (fifoWrite_ + i) & (kFftSize - 1);
        ola[olaIdx] += st.fftWork[i] * st.window[i];
    }
}

void SpectralLoudSplitProcessor::buildMasksLinear() noexcept {
    auto& st = *stft_;
    const float highDb = playback_->highDb;
    const float lowDb = std::min(playback_->lowDb, highDb - 6.0f);
    // Linear mag thresholds (mag already scaled); avoid per-bin log10.
    const float high = std::pow(10.0f, highDb / 20.0f);
    const float low = std::pow(10.0f, lowDb / 20.0f);
    const float knee = std::pow(10.0f, kKneeDb / 20.0f);
    const float highLo = high / knee;
    const float highHi = high * knee;
    const float lowLo = low / knee;
    const float lowHi = low * knee;
    // Temporal smooth before split — quiet residual flicker = hop-rate rasp.
    constexpr float kMagSmooth = 0.28f;

    for (int bin = 0; bin < kBins; ++bin) {
        st.magSmooth[bin] += kMagSmooth * (st.mag[bin] - st.magSmooth[bin]);
        const float mag = st.magSmooth[bin];
        float loud = softAboveLin(mag, highLo, highHi);
        float quiet = 1.0f - softAboveLin(mag, lowLo, lowHi);
        float mid = std::max(0.0f, 1.0f - loud - quiet);
        const float sum = loud + mid + quiet;
        if (sum > 1.0e-6f) {
            loud /= sum;
            mid /= sum;
            quiet /= sum;
        }
        st.maskLoud[bin] = loud;
        st.maskMid[bin] = mid;
        st.maskQuiet[bin] = quiet;
    }
}

void SpectralLoudSplitProcessor::processHop(float sampleRate, bool updatePreview) noexcept {
    if (playback_ == nullptr || stft_ == nullptr) return;
    auto& st = *stft_;
    const float magScale = 4.0f / static_cast<float>(kFftSize);

    fillWindowed(st.inputFifoL, st.freqL);
    fillWindowed(st.inputFifoR, st.freqR);
    fft_.forwardRealOnly(st.freqL);
    fft_.forwardRealOnly(st.freqR);

    for (int bin = 0; bin < kBins; ++bin) {
        const float magSq =
            0.5f * (binMagSq(st.freqL, bin, kFftSize) + binMagSq(st.freqR, bin, kFftSize));
        st.mag[bin] = std::sqrt(magSq) * magScale;
    }
    buildMasksLinear();

    if (updatePreview) {
        refreshPreviewBinMap(sampleRate);
        for (int band = 0; band < kPreviewBands; ++band) {
            float peak = 1.0e-8f;
            for (int bin = st.previewFirstBin[band]; bin <= st.previewLastBin[band]; ++bin)
                peak = std::max(peak, st.mag[bin]);
            const float db = 20.0f * std::log10(peak);
            st.previewSpectrum[band] = std::clamp((db + 80.0f) / 80.0f, 0.0f, 1.0f);
        }
    }

    // Always three band streams; gain/solo applied in process() after optional nest FX.
    const float* masks[3] = {st.maskLoud, st.maskMid, st.maskQuiet};
    for (int b = 0; b < kSpectralLoudBands; ++b) {
        ifftMasked(st.freqL, masks[b], st.olaL[b]);
        ifftMasked(st.freqR, masks[b], st.olaR[b]);
    }
}

void SpectralLoudSplitProcessor::initParams(const DeviceVariantParams& params) noexcept {
    DeviceProcessor::initParams(params);
    preFx_ = ChainRuntime{};
    postFx_ = ChainRuntime{};
    for (auto& b : bands_) b = ChainRuntime{};
    playback_ = std::get<SpectralLoudSplitParams>(params).playback;
    if (playback_ == nullptr) return;

    DeviceNodePlayback root;
    root.kind = kind();
    root.deviceId = deviceId();
    root.params = params;
    schedule_ = compileDeviceSubgraphTree(buildDeviceSubgraphTree(root));
    if (!schedule_.valid()) return;

    auto initBranch = [&](const SplitBranchPlayback& branch, ChainRuntime& runtime) {
        if (branch.deviceCount <= 0) return;
        auto order = compileFusedChildExecutionOrder(
            schedule_,
            std::span<const DeviceNodePlayback>(branch.devices,
                                                static_cast<size_t>(branch.deviceCount)));
        if (!order.valid()) return;
        runtime.executionOrder = order;
        runtime.arena = std::make_unique<ProcessorArena>(branch.deviceCount);
        buildProcessorChain(branch.devices, branch.deviceCount, *runtime.arena);
    };

    try {
        initBranch(playback_->preFx, preFx_);
        initBranch(playback_->postFx, postFx_);
        for (int b = 0; b < kSpectralLoudBands; ++b)
            initBranch(playback_->bands[b], bands_[b]);
    } catch (...) {
        preFx_ = ChainRuntime{};
        postFx_ = ChainRuntime{};
        for (auto& b : bands_) b = ChainRuntime{};
    }
}

bool SpectralLoudSplitProcessor::updateNestedDevice(const DeviceNodePlayback& node,
                                                    bool paramsChanged) noexcept {
    if (playback_ == nullptr) return false;
    auto tryBranch = [&](const SplitBranchPlayback& branch, ChainRuntime& runtime) -> bool {
        if (!runtime.arena) return false;
        for (int child = 0; child < branch.deviceCount; ++child) {
            auto* processor = runtime.arena->get(child);
            if (branch.devices[child].deviceId == node.deviceId) {
                if (processor == nullptr) return false;
                if (paramsChanged) processor->applyPlaybackNode(node);
                else {
                    processor->bypassed = node.bypassed;
                    processor->gain = node.gain;
                    processor->pan = node.pan;
                    processor->outputMix = node.outputMix;
                    processor->outputWidth = node.outputWidth;
                }
                return true;
            }
            if (processor != nullptr && processor->updateNestedDevice(node, paramsChanged))
                return true;
        }
        return false;
    };
    if (tryBranch(playback_->preFx, preFx_)) return true;
    if (tryBranch(playback_->postFx, postFx_)) return true;
    for (int b = 0; b < kSpectralLoudBands; ++b)
        if (tryBranch(playback_->bands[b], bands_[b])) return true;
    return false;
}

bool SpectralLoudSplitProcessor::setNestedCompiledParameter(
    uint64_t processorNodeId, uint16_t parameterId, float value, ParameterUpdateRate rate,
    float startValue) noexcept {
    if (playback_ == nullptr) return false;
    auto tryBranch = [&](const SplitBranchPlayback& branch, ChainRuntime& runtime) -> bool {
        if (!runtime.arena) return false;
        for (int child = 0; child < branch.deviceCount; ++child) {
            auto* processor = runtime.arena->get(child);
            if (processor == nullptr) continue;
            if (processor->stableProcessorNodeId == processorNodeId)
                return processor->setCompiledParameter(parameterId, value, rate, startValue);
            if (processor->setNestedCompiledParameter(processorNodeId, parameterId, value, rate,
                                                      startValue))
                return true;
        }
        return false;
    };
    if (tryBranch(playback_->preFx, preFx_)) return true;
    if (tryBranch(playback_->postFx, postFx_)) return true;
    for (int b = 0; b < kSpectralLoudBands; ++b)
        if (tryBranch(playback_->bands[b], bands_[b])) return true;
    return false;
}

bool SpectralLoudSplitProcessor::setNestedResolvedAsset(
    uint64_t processorNodeId, const ResolvedAssetUpdate& update) noexcept {
    if (playback_ == nullptr) return false;
    auto tryBranch = [&](const SplitBranchPlayback& branch, ChainRuntime& runtime) -> bool {
        if (!runtime.arena) return false;
        for (int child = 0; child < branch.deviceCount; ++child) {
            auto* processor = runtime.arena->get(child);
            if (processor == nullptr) continue;
            if (processor->stableProcessorNodeId == processorNodeId)
                return processor->applyResolvedAsset(update);
            if (processor->setNestedResolvedAsset(processorNodeId, update)) return true;
        }
        return false;
    };
    if (tryBranch(playback_->preFx, preFx_)) return true;
    if (tryBranch(playback_->postFx, postFx_)) return true;
    for (int b = 0; b < kSpectralLoudBands; ++b)
        if (tryBranch(playback_->bands[b], bands_[b])) return true;
    return false;
}

bool SpectralLoudSplitProcessor::readNestedEffectiveParameter(
    uint64_t processorNodeId, uint16_t parameterId, float& value,
    float* automationBase) const noexcept {
    if (playback_ == nullptr) return false;
    auto tryBranch = [&](const SplitBranchPlayback& branch,
                         const ChainRuntime& runtime) -> bool {
        if (!runtime.arena) return false;
        for (int child = 0; child < branch.deviceCount; ++child) {
            const auto* processor = runtime.arena->get(child);
            if (processor == nullptr) continue;
            if (processor->stableProcessorNodeId == processorNodeId)
                return processor->readEffectiveParameter(parameterId, value, automationBase);
            if (processor->readNestedEffectiveParameter(processorNodeId, parameterId, value,
                                                        automationBase))
                return true;
        }
        return false;
    };
    if (tryBranch(playback_->preFx, preFx_)) return true;
    if (tryBranch(playback_->postFx, postFx_)) return true;
    for (int b = 0; b < kSpectralLoudBands; ++b)
        if (tryBranch(playback_->bands[b], bands_[b])) return true;
    return false;
}

void SpectralLoudSplitProcessor::bindCompiledParameterSpans(
    const AutomationClipPlayback* clips, int clipCount, const ModulationEdgePlayback* edges,
    int edgeCount) noexcept {
    DeviceProcessor::bindCompiledParameterSpans(clips, clipCount, edges, edgeCount);
    if (playback_ == nullptr) return;
    auto bindBranch = [&](const SplitBranchPlayback& branch, ChainRuntime& runtime) {
        if (!runtime.arena) return;
        for (int child = 0; child < branch.deviceCount; ++child)
            if (auto* processor = runtime.arena->get(child))
                processor->bindCompiledParameterSpans(clips, clipCount, edges, edgeCount);
    };
    bindBranch(playback_->preFx, preFx_);
    bindBranch(playback_->postFx, postFx_);
    for (int b = 0; b < kSpectralLoudBands; ++b)
        bindBranch(playback_->bands[b], bands_[b]);
}

void SpectralLoudSplitProcessor::resetPlaybackState() noexcept {
    if (preFx_.arena) resetPlaybackStateInArena(*preFx_.arena);
    if (postFx_.arena) resetPlaybackStateInArena(*postFx_.arena);
    for (auto& runtime : bands_)
        if (runtime.arena) resetPlaybackStateInArena(*runtime.arena);
    if (stft_ != nullptr) {
        std::memset(stft_->inputFifoL, 0, sizeof(stft_->inputFifoL));
        std::memset(stft_->inputFifoR, 0, sizeof(stft_->inputFifoR));
        std::memset(stft_->olaL, 0, sizeof(stft_->olaL));
        std::memset(stft_->olaR, 0, sizeof(stft_->olaR));
        std::memset(stft_->magSmooth, 0, sizeof(stft_->magSmooth));
        stft_->cachedSr = 0.0f;
    }
    fifoWrite_ = 0;
    hopCounter_ = 0;
    samplesUntilSpectrumPublish_ = 0;
}

void SpectralLoudSplitProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (playback_ == nullptr || stft_ == nullptr || block.numSamples <= 0 ||
        block.numSamples > kScratchFrames)
        return;
    if (!ensureBuffers(ctx)) return;

    auto& st = *stft_;
    const int n = block.numSamples;
    const size_t bytes = static_cast<size_t>(n) * sizeof(float);
    const bool metersOn = ctx.deviceMeters != nullptr && meterSlot >= 0 &&
                          meterSlot < ctx.maxDeviceMeters &&
                          isMeterSlotSubscribed(ctx, meterSlot);

    std::memcpy(st.workL, block.channelL, bytes);
    std::memcpy(st.workR, block.channelR, bytes);
    runChain(preFx_, st.workL, st.workR, n, ctx);

    float prePeak = 0.0f;
    for (int s = 0; s < n; ++s)
        prePeak = std::max(prePeak, std::max(std::abs(st.workL[s]), std::abs(st.workR[s])));
    if (prePeak < 1.0e-5f) {
        runChain(postFx_, st.workL, st.workR, n, ctx);
        std::memcpy(block.channelL, st.workL, bytes);
        std::memcpy(block.channelR, st.workR, bytes);
        if (metersOn) {
            auto& meter = ctx.deviceMeters[meterSlot];
            meter.waveform[0].store(0.0f, std::memory_order_relaxed);
            meter.waveform[1].store(0.0f, std::memory_order_relaxed);
            meter.waveform[2].store(0.0f, std::memory_order_relaxed);
        }
        return;
    }

    for (int b = 0; b < kSpectralLoudBands; ++b) {
        std::memset(st.bandBlockL[b], 0, bytes);
        std::memset(st.bandBlockR[b], 0, bytes);
    }

    bool wantPreviewThisBlock = false;
    if (metersOn) {
        samplesUntilSpectrumPublish_ -= n;
        if (samplesUntilSpectrumPublish_ <= 0) {
            wantPreviewThisBlock = true;
            samplesUntilSpectrumPublish_ =
                std::max(1, static_cast<int>(ctx.sampleRate / 30.0));
        }
    }

    bool previewDone = false;
    const float sr =
        ctx.sampleRate > 0.0 ? static_cast<float>(ctx.sampleRate) : 48000.0f;

    for (int s = 0; s < n; ++s) {
        st.inputFifoL[fifoWrite_] = st.workL[s];
        st.inputFifoR[fifoWrite_] = st.workR[s];
        for (int b = 0; b < kSpectralLoudBands; ++b) {
            st.bandBlockL[b][s] = st.olaL[b][fifoWrite_];
            st.bandBlockR[b][s] = st.olaR[b][fifoWrite_];
            st.olaL[b][fifoWrite_] = 0.0f;
            st.olaR[b][fifoWrite_] = 0.0f;
        }
        fifoWrite_ = (fifoWrite_ + 1) & (kFftSize - 1);
        ++hopCounter_;
        if (hopCounter_ >= kHop) {
            hopCounter_ = 0;
            const bool updatePreview = wantPreviewThisBlock && !previewDone;
            processHop(sr, updatePreview);
            if (updatePreview) previewDone = true;
        }
    }

    bool anySolo = false;
    for (int b = 0; b < kSpectralLoudBands; ++b)
        if (playback_->bandSolo[b] >= 0.5f) anySolo = true;

    float peaks[kSpectralLoudBands]{};
    std::memset(outL_, 0, bytes);
    std::memset(outR_, 0, bytes);

    for (int b = 0; b < kSpectralLoudBands; ++b) {
        if (anySolo && playback_->bandSolo[b] < 0.5f) continue;
        if (bandHasFx(b))
            runChain(bands_[b], st.bandBlockL[b], st.bandBlockR[b], n, ctx);
        const float gain = playback_->bandGain[b];
        for (int s = 0; s < n; ++s) {
            const float l = st.bandBlockL[b][s] * gain;
            const float r = st.bandBlockR[b][s] * gain;
            outL_[s] += l;
            outR_[s] += r;
            peaks[b] = std::max(peaks[b], std::max(std::abs(l), std::abs(r)));
        }
    }

    runChain(postFx_, outL_, outR_, n, ctx);
    std::memcpy(block.channelL, outL_, bytes);
    std::memcpy(block.channelR, outR_, bytes);

    if (!metersOn) return;

    auto& meter = ctx.deviceMeters[meterSlot];
    meter.waveform[0].store(peaks[0], std::memory_order_relaxed);
    meter.waveform[1].store(peaks[1], std::memory_order_relaxed);
    meter.waveform[2].store(peaks[2], std::memory_order_relaxed);
    meter.inputPeakL.store(peaks[0], std::memory_order_relaxed);
    meter.inputPeakR.store(peaks[2], std::memory_order_relaxed);
    meter.inputPeak.store(std::max(peaks[0], std::max(peaks[1], peaks[2])),
                          std::memory_order_relaxed);
    if (previewDone) {
        for (int band = 0; band < kPreviewBands; ++band)
            meter.spectrum[band].store(st.previewSpectrum[band], std::memory_order_relaxed);
    }
}

} // namespace audioapp
