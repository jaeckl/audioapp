#include "audioapp/devices/instances/SpectralLoudSplitModel.hpp"
#include "audioapp/devices/DeviceSlot.hpp"

#include <algorithm>
#include <cstring>

namespace audioapp {

SpectralLoudSplitModel SpectralLoudSplitModel::withDefaults() noexcept {
    SpectralLoudSplitModel model;
    model.highDb = -18.0f;
    model.lowDb = -40.0f;
    return model;
}

SpectralLoudSplitModel::SpectralLoudSplitModel(const SpectralLoudSplitModel& o) {
    *this = o;
}

SpectralLoudSplitModel& SpectralLoudSplitModel::operator=(const SpectralLoudSplitModel& o) {
    if (this == &o) return *this;
    highDb = o.highDb;
    lowDb = o.lowDb;
    std::memcpy(bandGain, o.bandGain, sizeof(bandGain));
    std::memcpy(bandSolo, o.bandSolo, sizeof(bandSolo));
    auto cloneList = [](const std::vector<std::shared_ptr<DeviceSlot>>& src,
                        std::vector<std::shared_ptr<DeviceSlot>>& dst) {
        dst.clear();
        for (const auto& d : src)
            dst.push_back(d ? std::make_shared<DeviceSlot>(*d) : nullptr);
    };
    cloneList(o.preFxDevices, preFxDevices);
    cloneList(o.postFxDevices, postFxDevices);
    for (int b = 0; b < kSpectralLoudBands; ++b)
        cloneList(o.bands[b], bands[b]);
    return *this;
}

} // namespace audioapp
