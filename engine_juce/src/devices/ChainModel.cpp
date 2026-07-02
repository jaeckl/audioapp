#include "audioapp/devices/instances/ChainModel.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
namespace audioapp { ChainModel::ChainModel(const ChainModel& o){*this=o;} ChainModel& ChainModel::operator=(const ChainModel& o){if(this==&o)return *this;mix=o.mix;gain=o.gain;devices.clear();for(const auto& d:o.devices)devices.push_back(d?std::make_shared<DeviceSlot>(*d):nullptr);return *this;} }
