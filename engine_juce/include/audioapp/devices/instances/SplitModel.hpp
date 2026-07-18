#pragma once
#include <memory>
#include <vector>
#include "audioapp/devices/SplitMode.hpp"
namespace audioapp { struct DeviceSlot; struct SplitModel {
 SplitMode mode = SplitMode::Lr;
 float branch0Gain = 1.0f;
 float branch1Gain = 1.0f;
 bool branch0Solo = false;
 bool branch1Solo = false;
 std::vector<std::shared_ptr<DeviceSlot>> branch0; // L or Mid
 std::vector<std::shared_ptr<DeviceSlot>> branch1; // R or Side
 SplitModel()=default; SplitModel(const SplitModel&); SplitModel& operator=(const SplitModel&);
}; }
