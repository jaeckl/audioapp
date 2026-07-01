#pragma once

#include <juce_core/juce_core.h>

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

class TrackFreezeAssetStore {
public:
    const FreezeAsset* find(const std::string& id) const;
    bool upsert(FreezeAsset asset);
    void remove(const std::string& id);
    void clear();

private:
    mutable juce::CriticalSection mutex_;
    std::vector<FreezeAsset> assets_;
};

} // namespace audioapp
