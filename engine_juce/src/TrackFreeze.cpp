#include "audioapp/TrackFreeze.hpp"

#include "audioapp/ClipContentPlayback.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/devices/DevicePanelTypes.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/playback/Clip.hpp"
#include "audioapp/SampleBank.hpp"
#include "audioapp/TrackFreezeAssetStore.hpp"
#include "audioapp/WavLoader.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <type_traits>

namespace audioapp {
namespace {

constexpr int kMinFreezeWaveformBins = 128;
constexpr int kMaxFreezeWaveformBins = 4096;

uint64_t fnvMix(uint64_t hash, uint64_t value) noexcept {
    hash ^= value;
    return hash * 1099511628211ull;
}

uint64_t floatBits(float value) noexcept {
    uint32_t bits = 0;
    std::memcpy(&bits, &value, sizeof(bits));
    return static_cast<uint64_t>(bits);
}

void hashOutputPanel(uint64_t& hash, const OutputPanelParams& panel) noexcept {
    std::visit([&](const auto& params) {
        using T = std::decay_t<decltype(params)>;
        if constexpr (std::is_same_v<T, MonoOutputPanel>) {
            hash = fnvMix(hash, floatBits(params.gain));
        } else if constexpr (std::is_same_v<T, StereoOutputPanel>) {
            hash = fnvMix(hash, floatBits(params.gain));
            hash = fnvMix(hash, floatBits(params.pan));
            hash = fnvMix(hash, floatBits(params.outputMix));
            hash = fnvMix(hash, floatBits(params.outputWidth));
        }
    }, panel);
}

} // namespace

int freezeWaveformBinCount(int frameCount, double lengthBeats) noexcept {
    const int byBeat = static_cast<int>(std::ceil(std::max(lengthBeats, 0.0) * 8.0));
    const int byFrames = std::max(1, frameCount / 192);
    return std::clamp(std::max({kMinFreezeWaveformBins, byBeat, byFrames}),
                      kMinFreezeWaveformBins,
                      kMaxFreezeWaveformBins);
}

uint64_t computeTrackFreezeSignature(const Track& track, int bpm) noexcept {
    uint64_t hash = 14695981039346656037ull;
    hash = fnvMix(hash, static_cast<uint64_t>(std::max(bpm, 1)));
    const int gainIdx = findTrackGainDeviceIndex(track.devices);
    const int preGainCount = gainIdx < 0 ? static_cast<int>(track.devices.size()) : gainIdx;
    hash = fnvMix(hash, static_cast<uint64_t>(preGainCount));
    for (int i = 0; i < preGainCount; ++i) {
        const auto& device = track.devices[static_cast<size_t>(i)];
        for (unsigned char c : device.config.typeId) {
            hash = fnvMix(hash, static_cast<uint64_t>(c));
        }
        hash = fnvMix(hash, device.config.bypassed ? 1ull : 0ull);
        hashOutputPanel(hash, device.config.outputPanel);
    }
    for (const auto& clip : track.midiClips) {
        hash = fnvMix(hash, static_cast<uint64_t>(clip.startBeat * 1000.0));
        hash = fnvMix(hash, static_cast<uint64_t>(clip.lengthBeats * 1000.0));
        hash = fnvMix(hash, static_cast<uint64_t>(clip.notes.size()));
        for (const auto& note : clip.notes) {
            hash = fnvMix(hash, static_cast<uint64_t>(note.pitch));
            hash = fnvMix(hash, static_cast<uint64_t>(note.startBeat * 1000.0));
            hash = fnvMix(hash, static_cast<uint64_t>(note.durationBeats * 1000.0));
        }
    }
    for (const auto& clip : track.sampleClips) {
        hash = fnvMix(hash, static_cast<uint64_t>(clip.startBeat * 1000.0));
        hash = fnvMix(hash, static_cast<uint64_t>(clip.lengthBeats * 1000.0));
        for (unsigned char c : clip.sampleId) {
            hash = fnvMix(hash, static_cast<uint64_t>(c));
        }
    }
    return hash;
}

double trackContentEndBeat(const Track& track) noexcept {
    double endBeat = 0.0;
    bool hasContent = false;
    for (const auto& clip : track.midiClips) {
        endBeat = std::max(endBeat, clip.startBeat + clip.lengthBeats);
        hasContent = true;
    }
    for (const auto& clip : track.sampleClips) {
        endBeat = std::max(endBeat, clip.startBeat + clip.lengthBeats);
        hasContent = true;
    }
    return hasContent ? endBeat : 0.0;
}

int findTrackGainDeviceIndex(const std::vector<DeviceSlot>& devices) noexcept {
    for (int i = 0; i < static_cast<int>(devices.size()); ++i) {
        if (deviceNodeKindFromTypeId(devices[i].config.typeId) == DeviceNodeKind::TrackGain) {
            return i;
        }
    }
    return -1;
}

bool trackHasRoutingReceivers(const Track& track) noexcept {
    for (const auto& device : track.devices) {
        const auto kind = deviceNodeKindFromTypeId(device.config.typeId);
        if (kind == DeviceNodeKind::AudioReceiver || kind == DeviceNodeKind::MidiReceiver) {
            return true;
        }
    }
    return false;
}

namespace {

double beatAtFrame(double playheadStartBeat, int frame, double sampleRate, int bpm) noexcept {
    return playheadStartBeat +
           static_cast<double>(frame) * (static_cast<double>(std::max(bpm, 1)) / 60.0) / sampleRate;
}

} // namespace

void mixFreezeStereoBlock(float* leftOut,
                          float* rightOut,
                          int numFrames,
                          double sampleRate,
                          int bpm,
                          double playheadStartBeat,
                          const FreezePlaybackRegion& region) noexcept {
    if (leftOut == nullptr || rightOut == nullptr || numFrames <= 0 || bpm <= 0 ||
        region.pcmL == nullptr || region.pcmR == nullptr || region.frameCount <= 0 ||
        region.pcmSampleRate <= 0.0 || region.lengthBeats <= 0.0) {
        return;
    }

    const playback::AudioClip clip{region.startBeat,
                                   region.lengthBeats,
                                   region.lengthBeats,
                                   false};

    for (int frame = 0; frame < numFrames; ++frame) {
        const double beat = beatAtFrame(playheadStartBeat, frame, sampleRate, bpm);
        bool active = false;
        const double progress = clip.progressAt(beat, active);
        if (!active) {
            continue;
        }
        const double readPos = progress * static_cast<double>(region.frameCount);
        const int index = static_cast<int>(readPos);
        const float frac = static_cast<float>(readPos - static_cast<double>(index));
        const int next = std::min(index + 1, region.frameCount - 1);
        const float l = region.pcmL[index] * (1.0f - frac) + region.pcmL[next] * frac;
        const float r = region.pcmR[index] * (1.0f - frac) + region.pcmR[next] * frac;
        leftOut[frame] += l;
        rightOut[frame] += r;
    }
}

std::vector<float> computeFreezeWaveformPeaks(const float* pcmL,
                                              const float* pcmR,
                                              int frameCount,
                                              int binCount) {
    if (pcmL == nullptr || pcmR == nullptr || frameCount <= 0 || binCount <= 0) {
        return {};
    }
    std::vector<float> mono(static_cast<size_t>(frameCount), 0.0f);
    for (int i = 0; i < frameCount; ++i) {
        mono[static_cast<size_t>(i)] =
            std::max(std::abs(pcmL[i]), std::abs(pcmR[i]));
    }
    return SampleBank::computePeaks(mono.data(), frameCount, binCount);
}

std::string freezeWavArchivePath(const std::string& assetId) {
    return "assets/freeze/" + assetId + ".wav";
}

bool loadFreezeAssetFromWavBytes(const std::string& assetId,
                                 const std::vector<uint8_t>& wavBytes,
                                 FreezeAsset& out) {
    WavStereoPcmData pcm;
    if (!decodeWavStereoFloat(wavBytes, pcm) || pcm.left.empty()) {
        return false;
    }
    out.id = assetId;
    out.pcmL = std::move(pcm.left);
    out.pcmR = std::move(pcm.right);
    if (out.pcmR.size() != out.pcmL.size()) {
        out.pcmR.resize(out.pcmL.size(), 0.0f);
    }
    out.sampleRate = pcm.sampleRate;
    const int frameCount = static_cast<int>(out.pcmL.size());
    out.peaks = computeFreezeWaveformPeaks(
        out.pcmL.data(),
        out.pcmR.data(),
        frameCount,
        freezeWaveformBinCount(frameCount, 1.0));
    return true;
}

std::vector<uint8_t> encodeFreezeAssetWav(const FreezeAsset& asset) {
    if (asset.pcmL.empty() || asset.pcmR.empty()) {
        return {};
    }
    const int frameCount = static_cast<int>(std::min(asset.pcmL.size(), asset.pcmR.size()));
    return encodeStereoWavFloat32(
        asset.pcmL.data(), asset.pcmR.data(), frameCount, asset.sampleRate);
}

} // namespace audioapp
