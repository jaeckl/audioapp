#include "audioapp/TrackFreezeAssetStore.hpp"

#include <algorithm>

namespace audioapp {

const FreezeAsset* TrackFreezeAssetStore::find(const std::string& id) const {
    if (id.empty()) {
        return nullptr;
    }
    const juce::ScopedLock lock(mutex_);
    for (const auto& asset : assets_) {
        if (asset.id == id) {
            return &asset;
        }
    }
    return nullptr;
}

bool TrackFreezeAssetStore::upsert(FreezeAsset asset) {
    if (asset.id.empty() || asset.pcmL.empty() || asset.pcmR.empty()) {
        return false;
    }
    const juce::ScopedLock lock(mutex_);
    for (auto& existing : assets_) {
        if (existing.id == asset.id) {
            existing = std::move(asset);
            return true;
        }
    }
    assets_.push_back(std::move(asset));
    return true;
}

void TrackFreezeAssetStore::remove(const std::string& id) {
    if (id.empty()) {
        return;
    }
    const juce::ScopedLock lock(mutex_);
    assets_.erase(std::remove_if(assets_.begin(),
                                 assets_.end(),
                                 [&](const FreezeAsset& asset) { return asset.id == id; }),
                  assets_.end());
}

void TrackFreezeAssetStore::clear() {
    const juce::ScopedLock lock(mutex_);
    assets_.clear();
}

} // namespace audioapp
