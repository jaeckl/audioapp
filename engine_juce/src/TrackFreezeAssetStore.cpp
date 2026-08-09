#include "audioapp/TrackFreezeAssetStore.hpp"

#include <algorithm>
#include <utility>

namespace audioapp {

FreezeAssetRef TrackFreezeAssetStore::find(const std::string& id) const {
    if (id.empty()) {
        return nullptr;
    }
    const juce::ScopedLock lock(mutex_);
    for (const auto& asset : assets_) {
        if (asset != nullptr && asset->id == id) {
            return asset;
        }
    }
    return nullptr;
}

bool TrackFreezeAssetStore::upsert(FreezeAsset asset) {
    if (asset.id.empty() || asset.pcmL.empty() || asset.pcmR.empty()) {
        return false;
    }
    auto shared = std::make_shared<const FreezeAsset>(std::move(asset));
    const juce::ScopedLock lock(mutex_);
    for (auto& existing : assets_) {
        if (existing != nullptr && existing->id == shared->id) {
            existing = std::move(shared);
            return true;
        }
    }
    assets_.push_back(std::move(shared));
    return true;
}

void TrackFreezeAssetStore::remove(const std::string& id) {
    if (id.empty()) {
        return;
    }
    const juce::ScopedLock lock(mutex_);
    assets_.erase(std::remove_if(assets_.begin(),
                                 assets_.end(),
                                 [&](const FreezeAssetRef& asset) {
                                     return asset == nullptr || asset->id == id;
                                 }),
                  assets_.end());
}

void TrackFreezeAssetStore::clear() {
    const juce::ScopedLock lock(mutex_);
    assets_.clear();
}

std::vector<FreezeAssetRef> TrackFreezeAssetStore::listAssets() const {
    const juce::ScopedLock lock(mutex_);
    return assets_;
}

} // namespace audioapp
