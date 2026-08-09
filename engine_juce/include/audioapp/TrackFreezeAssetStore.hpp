#pragma once

#include <juce_core/juce_core.h>

#include <memory>
#include <string>
#include <vector>

namespace audioapp {

struct FreezeAsset {
    std::string id;
    std::vector<float> pcmL;
    std::vector<float> pcmR;
    double sampleRate = 48000.0;
    std::vector<float> peaks;
};

using FreezeAssetRef = std::shared_ptr<const FreezeAsset>;

// Assets are handed out as shared references because the audio thread reads the
// PCM through raw pointers cached in the playback snapshot. Replacing or
// removing an entry must not free samples that a snapshot still points at, so
// the store never mutates a published asset in place.
class TrackFreezeAssetStore {
public:
    FreezeAssetRef find(const std::string& id) const;
    bool upsert(FreezeAsset asset);
    void remove(const std::string& id);
    void clear();
    std::vector<FreezeAssetRef> listAssets() const;

private:
    mutable juce::CriticalSection mutex_;
    std::vector<FreezeAssetRef> assets_;
};

} // namespace audioapp
