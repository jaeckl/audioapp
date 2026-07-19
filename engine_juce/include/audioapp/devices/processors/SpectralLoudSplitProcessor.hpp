#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/dsp/ProcessorArena.hpp"
#include "audioapp/dsp/RealFft.hpp"
#include "audioapp/devices/instances/SpectralLoudSplitModel.hpp"
#include "audioapp/DeviceChainScratch.hpp"

#include <memory>

namespace audioapp {

struct DeviceChainScratchArena;

/// STFT loudness-mask split: PRE FX → loud/mid/quiet streams → band FX → gain → sum → POST.
/// Each band is always its own time stream so solo / gain / VU stay independent.
class SpectralLoudSplitProcessor final : public DeviceProcessor {
    struct ChainRuntime {
        std::unique_ptr<ProcessorArena> arena;
        CompiledDeviceExecutionOrder executionOrder{};
    };

    // 512-pt, 50% hop with √Hann (product = Hann = COLA) — clean + cheap.
    static constexpr int kFftOrder = 9;
    static constexpr int kFftSize = 1 << kFftOrder;
    static constexpr int kHop = kFftSize / 2;
    static constexpr int kBins = kFftSize / 2 + 1;
    static constexpr float kKneeDb = 3.0f;
    static constexpr int kPreviewBands = 24;

    struct StftState {
        float window[kFftSize]{};
        float inputFifoL[kFftSize]{};
        float inputFifoR[kFftSize]{};
        float freqL[kFftSize * 2]{};
        float freqR[kFftSize * 2]{};
        float fftWork[kFftSize * 2]{};
        float mag[kBins]{};
        float magSmooth[kBins]{};
        float maskLoud[kBins]{};
        float maskMid[kBins]{};
        float maskQuiet[kBins]{};
        float olaL[kSpectralLoudBands][kFftSize]{};
        float olaR[kSpectralLoudBands][kFftSize]{};
        float bandBlockL[kSpectralLoudBands][kScratchFrames]{};
        float bandBlockR[kSpectralLoudBands][kScratchFrames]{};
        float workL[kScratchFrames]{};
        float workR[kScratchFrames]{};
        float previewSpectrum[kPreviewBands]{};
        int previewFirstBin[kPreviewBands]{};
        int previewLastBin[kPreviewBands]{};
        float cachedSr = 0.0f;
    };

    std::shared_ptr<const SpectralLoudSplitPlayback> playback_;
    ChainRuntime preFx_;
    ChainRuntime bands_[kSpectralLoudBands];
    ChainRuntime postFx_;
    CompiledDeviceSubgraphSchedule schedule_{};

    RealFft fft_{kFftOrder};
    std::unique_ptr<StftState> stft_;
    float* outL_ = nullptr;
    float* outR_ = nullptr;
    DeviceChainScratchArena* bufferArena_ = nullptr;
    int fifoWrite_ = 0;
    int hopCounter_ = 0;
    int samplesUntilSpectrumPublish_ = 0;

    bool ensureBuffers(ProcessContext& ctx) noexcept;
    void runChain(ChainRuntime& runtime, float* left, float* right, int numSamples,
                  ProcessContext& ctx) noexcept;
    void refreshPreviewBinMap(float sampleRate) noexcept;
    void processHop(float sampleRate, bool updatePreview) noexcept;
    void fillWindowed(const float* fifo, float* dest) noexcept;
    void ifftMasked(const float* srcFreq, const float* mask, float* ola) noexcept;
    void buildMasksLinear() noexcept;
    bool bandHasFx(int bandIndex) const noexcept;
    static float softAboveLin(float mag, float lo, float hi) noexcept;

public:
    SpectralLoudSplitProcessor() noexcept;
    ~SpectralLoudSplitProcessor() override;
    void initParams(const DeviceVariantParams& params) noexcept override;
    bool updateNestedDevice(const DeviceNodePlayback& node,
                            bool paramsChanged = true) noexcept override;
    bool setNestedCompiledParameter(uint64_t processorNodeId, uint16_t parameterId,
                                    float value, ParameterUpdateRate rate,
                                    float startValue) noexcept override;
    bool setNestedResolvedAsset(uint64_t processorNodeId,
                                const ResolvedAssetUpdate& update) noexcept override;
    bool readNestedEffectiveParameter(uint64_t processorNodeId, uint16_t parameterId,
                                      float& value,
                                      float* automationBase = nullptr) const noexcept override;
    void bindCompiledParameterSpans(const AutomationClipPlayback* clips, int clipCount,
                                    const ModulationEdgePlayback* edges,
                                    int edgeCount) noexcept override;
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    void resetPlaybackState() noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::SpectralLoudSplit; }
};

} // namespace audioapp
