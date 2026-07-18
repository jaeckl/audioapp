#include "audioapp/devices/instances/MultibandSplitModel.hpp"
#include "audioapp/devices/DeviceSlot.hpp"

#include <algorithm>
#include <cstring>

namespace audioapp {

MultibandSplitModel MultibandSplitModel::withDefaults(int bandCount) noexcept {
    MultibandSplitModel model;
    model.bandCount = std::clamp(bandCount, 2, kMaxMbBands);
    if (model.bandCount == 2) {
        model.crossoverHz[0] = 1000.0f;
    } else if (model.bandCount == 3) {
        model.crossoverHz[0] = 200.0f;
        model.crossoverHz[1] = 2000.0f;
    } else {
        model.crossoverHz[0] = 100.0f;
        model.crossoverHz[1] = 500.0f;
        model.crossoverHz[2] = 2000.0f;
    }
    return model;
}

MultibandSplitModel::MultibandSplitModel(const MultibandSplitModel& o) { *this = o; }

MultibandSplitModel& MultibandSplitModel::operator=(const MultibandSplitModel& o) {
    if (this == &o) return *this;
    bandCount = o.bandCount;
    std::memcpy(crossoverHz, o.crossoverHz, sizeof(crossoverHz));
    std::memcpy(bandGain, o.bandGain, sizeof(bandGain));
    for (int b = 0; b < kMaxMbBands; ++b) {
        bands[b].clear();
        for (const auto& d : o.bands[b])
            bands[b].push_back(d ? std::make_shared<DeviceSlot>(*d) : nullptr);
    }
    return *this;
}

} // namespace audioapp
