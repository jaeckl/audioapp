#pragma once

#include <string>

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
};

} // namespace audioapp
