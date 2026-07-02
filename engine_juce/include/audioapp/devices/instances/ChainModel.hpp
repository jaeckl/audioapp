#pragma once
#include <memory>
#include <vector>
namespace audioapp { struct DeviceSlot; struct ChainModel {
 float mix=1.0f; float gain=1.0f;
 std::vector<std::shared_ptr<DeviceSlot>> devices;
 ChainModel()=default; ChainModel(const ChainModel&); ChainModel& operator=(const ChainModel&);
}; }
