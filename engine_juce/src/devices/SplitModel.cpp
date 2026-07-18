#include "audioapp/devices/instances/SplitModel.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
namespace audioapp {
SplitModel::SplitModel(const SplitModel& o) { *this = o; }
SplitModel& SplitModel::operator=(const SplitModel& o) {
    if (this == &o) return *this;
    mode = o.mode;
    branch0Gain = o.branch0Gain;
    branch1Gain = o.branch1Gain;
    branch0Solo = o.branch0Solo;
    branch1Solo = o.branch1Solo;
    branch0.clear();
    for (const auto& d : o.branch0) branch0.push_back(d ? std::make_shared<DeviceSlot>(*d) : nullptr);
    branch1.clear();
    for (const auto& d : o.branch1) branch1.push_back(d ? std::make_shared<DeviceSlot>(*d) : nullptr);
    return *this;
}
} // namespace audioapp
