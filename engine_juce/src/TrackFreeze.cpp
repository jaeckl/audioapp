#include "audioapp/TrackFreeze.hpp"

#include "audioapp/ClipContentPlayback.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/devices/DevicePanelTypes.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/DeviceTreeWalk.hpp"
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

uint64_t freezeHashBytes(uint64_t seed, const void* data, size_t size) noexcept {
    const auto* bytes = static_cast<const unsigned char*>(data);
    uint64_t hash = seed;
    for (size_t i = 0; i < size; ++i) {
        hash = fnvMix(hash, static_cast<uint64_t>(bytes[i]));
    }
    return hash;
}

uint64_t freezeHashString(uint64_t seed, std::string_view text) noexcept {
    return freezeHashBytes(seed, text.data(), text.size());
}

int flattenedPlaybackSlotCount(const DeviceSlot& device) noexcept {
    if (!device_types::isSynthType(device.config.typeId)) {
        return 1;
    }
    int slots = 1;
    for (const auto& fx : device.noteFxDevices) {
        if (fx) {
            ++slots;
        }
    }
    for (const auto& fx : device.audioFxDevices) {
        if (fx) {
            ++slots;
        }
    }
    return slots;
}

bool freezeBakeCoversDeviceId(const Track& track,
                              int flattenedBakeEnd,
                              std::string_view deviceId) noexcept {
    if (flattenedBakeEnd <= 0 || deviceId.empty()) {
        return false;
    }
    int flat = 0;
    for (const auto& device : track.devices) {
        const int slots = flattenedPlaybackSlotCount(device);
        if (flat + slots > flattenedBakeEnd) {
            return false;
        }
        bool found = false;
        walkDeviceTree(device, [&](const DeviceSlot& node) {
            if (node.id == deviceId) {
                found = true;
            }
        });
        if (found) {
            return true;
        }
        flat += slots;
    }
    return false;
}

uint64_t computeTrackFreezeSignature(const Track& track,
                                     int bpm,
                                     double renderSampleRate,
                                     int bakeEndDeviceIndex,
                                     uint64_t externalDependencyHash) noexcept {
    uint64_t hash = 14695981039346656037ull;
    hash = fnvMix(hash, static_cast<uint64_t>(std::max(bpm, 1)));
    hash = fnvMix(hash, static_cast<uint64_t>(renderSampleRate));
    hash = fnvMix(hash, static_cast<uint64_t>(bakeEndDeviceIndex));
    hash = fnvMix(hash, externalDependencyHash);
    // bakeEndDeviceIndex is flattened; only hash model devices fully inside it.
    int flat = 0;
    int bakedModelCount = 0;
    for (const auto& device : track.devices) {
        const int slots = flattenedPlaybackSlotCount(device);
        if (flat + slots > bakeEndDeviceIndex) {
            break;
        }
        walkDeviceTree(device, [&](const DeviceSlot& node) {
            hash = freezeHashString(hash, node.id);
            hash = freezeHashString(hash, node.config.typeId);
            hash = fnvMix(hash, node.config.bypassed ? 1ull : 0ull);
            hashOutputPanel(hash, node.config.outputPanel);
        });
        ++bakedModelCount;
        flat += slots;
    }
    hash = fnvMix(hash, static_cast<uint64_t>(bakedModelCount));
    for (const auto& clip : track.midiClips) {
        hash = freezeHashString(hash, clip.id);
        hash = fnvMix(hash, static_cast<uint64_t>(clip.startBeat * 1000.0));
        hash = fnvMix(hash, static_cast<uint64_t>(clip.lengthBeats * 1000.0));
        hash = fnvMix(hash, static_cast<uint64_t>(clip.naturalLengthBeats * 1000.0));
        hash = fnvMix(hash, clip.loopContent ? 1ull : 0ull);
        hash = fnvMix(hash, static_cast<uint64_t>(clip.notes.size()));
        for (const auto& note : clip.notes) {
            hash = fnvMix(hash, static_cast<uint64_t>(note.pitch));
            hash = fnvMix(hash, static_cast<uint64_t>(note.startBeat * 1000.0));
            hash = fnvMix(hash, static_cast<uint64_t>(note.durationBeats * 1000.0));
            hash = fnvMix(hash, floatBits(note.velocity));
        }
    }
    for (const auto& clip : track.sampleClips) {
        hash = freezeHashString(hash, clip.id);
        hash = freezeHashString(hash, clip.sampleId);
        hash = fnvMix(hash, static_cast<uint64_t>(clip.startBeat * 1000.0));
        hash = fnvMix(hash, static_cast<uint64_t>(clip.lengthBeats * 1000.0));
        hash = fnvMix(hash, static_cast<uint64_t>(clip.naturalLengthBeats * 1000.0));
        hash = fnvMix(hash, clip.loopContent ? 1ull : 0ull);
        hash = fnvMix(hash, floatBits(clip.sourceStart));
        hash = fnvMix(hash, floatBits(clip.sourceEnd));
        hash = fnvMix(hash, floatBits(clip.gain));
        hash = fnvMix(hash, floatBits(clip.fadeIn));
        hash = fnvMix(hash, floatBits(clip.fadeOut));
        hash = fnvMix(hash, floatBits(clip.fadeInCurve));
        hash = fnvMix(hash, floatBits(clip.fadeOutCurve));
        hash = fnvMix(hash, clip.reversed ? 1ull : 0ull);
        hash = fnvMix(hash, clip.warpRepitch ? 1ull : 0ull);
    }
    return hash;
}

int computeFreezeBakeEndIndex(const Track& track,
                              const std::vector<Track>& allTracks) noexcept {
    const int gainIndex = findTrackGainDeviceIndex(track.devices);
    if (gainIndex <= 0) {
        return 0;
    }

    // A device that another track reads from must keep running live, otherwise
    // its intermediate output is never published to the routing graph.
    const auto isTappedSource = [&](const std::string& deviceId) noexcept {
        if (deviceId.empty()) {
            return false;
        }
        for (const auto& candidate : allTracks) {
            for (const auto& device : candidate.devices) {
                if (device.config.bypassed) {
                    continue;
                }
                if (const auto* routing = std::get_if<RoutingModel>(&device.config.instance)) {
                    if (routing->sourceId == deviceId) {
                        return true;
                    }
                } else if (const auto* ducker =
                               std::get_if<DuckerModel>(&device.config.instance)) {
                    if (ducker->sidechainSourceId == deviceId) {
                        return true;
                    }
                }
            }
        }
        return false;
    };

    // Walk model devices but accumulate the flattened playback cursor so the
    // returned split matches processChain / bake arena indexing.
    int flattenedCursor = 0;
    for (int i = 0; i < gainIndex; ++i) {
        const auto& device = track.devices[static_cast<size_t>(i)];
        const auto kind = deviceNodeKindFromTypeId(device.config.typeId);
        if (kind == DeviceNodeKind::AudioReceiver || kind == DeviceNodeKind::MidiReceiver) {
            return flattenedCursor;
        }
        // Barrier even when bypassed: un-bypassing later must not leave a baked
        // stem that never saw the sidechain input.
        const auto* ducker = std::get_if<DuckerModel>(&device.config.instance);
        if (ducker != nullptr && !ducker->sidechainSourceId.empty()) {
            return flattenedCursor;
        }
        if (isTappedSource(device.id)) {
            return flattenedCursor;
        }
        flattenedCursor += flattenedPlaybackSlotCount(device);
    }
    return flattenedCursor;
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
        // The asset holds one frame per rendered frame, so frame N of the bake
        // must be read at progress N/frameCount. Scaling by frameCount-1 instead
        // would play the asset (frameCount-1)/frameCount too slow, which drifts
        // a full sample by the end and destroys null-sum transparency. `index`
        // is clamped below instead.
        const double readPos =
            std::clamp(progress, 0.0, 1.0) * static_cast<double>(region.frameCount);
        const int index = std::min(static_cast<int>(readPos), region.frameCount - 1);
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
