#pragma once

#include "audioapp/DeviceState.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"

namespace audioapp {

struct SamplerInstance {
    std::string sampleId;
    float attack = 0.01f;
    float decay = 0.3f;
    float sustain = 0.7f;
    float release = 0.4f;
    float filterCutoff = 1.0f;
    float filterQ = 0.35f;
    int filterMode = 0;
    float trimStartSec = 0.0f;
    float trimEndSec = 0.0f;
    float regionStartSec = 0.0f;
    float regionEndSec = 0.0f;

    static SamplerInstance fromState(const DeviceState& state) {
        SamplerInstance instance;
        instance.sampleId = state.sampleId;
        instance.attack = state.attack;
        instance.decay = state.decay;
        instance.sustain = state.sustain;
        instance.release = state.release;
        instance.filterCutoff = state.filterCutoff;
        instance.filterQ = state.filterQ;
        instance.filterMode = state.filterMode;
        instance.trimStartSec = state.trimStartSec;
        instance.trimEndSec = state.trimEndSec;
        instance.regionStartSec = state.regionStartSec;
        instance.regionEndSec = state.regionEndSec;
        return instance;
    }

    void applyTo(DeviceState& state) const {
        state.type = device_types::kSampler;
        state.sampleId = sampleId;
        state.attack = attack;
        state.decay = decay;
        state.sustain = sustain;
        state.release = release;
        state.filterCutoff = filterCutoff;
        state.filterQ = filterQ;
        state.filterMode = filterMode;
        state.trimStartSec = trimStartSec;
        state.trimEndSec = trimEndSec;
        state.regionStartSec = regionStartSec;
        state.regionEndSec = regionEndSec;
    }
};

} // namespace audioapp
