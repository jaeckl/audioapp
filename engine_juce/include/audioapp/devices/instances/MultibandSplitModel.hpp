#pragma once

#include <memory>
#include <vector>

namespace audioapp {

struct DeviceSlot;

static constexpr int kMaxMbBands = 4;

struct MultibandSplitModel {
    int bandCount = 2; // 2..4
    float crossoverHz[3]{};
    float bandGain[4]{1.0f, 1.0f, 1.0f, 1.0f}; // 0..2
    std::vector<std::shared_ptr<DeviceSlot>> bands[kMaxMbBands];

    MultibandSplitModel() = default;
    MultibandSplitModel(const MultibandSplitModel&);
    MultibandSplitModel& operator=(const MultibandSplitModel&);

    static MultibandSplitModel withDefaults(int bandCount) noexcept;
};

} // namespace audioapp
