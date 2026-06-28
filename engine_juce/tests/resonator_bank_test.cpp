#include "audioapp/ProjectJson.hpp"
#include "audioapp/ResonatorBank.hpp"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/ResonatorBankModel.hpp"

#include <algorithm>
#include <cmath>
#include <iostream>
#include <string>
#include <vector>

namespace {

int failures = 0;

void expect(bool condition, const char* message) {
    if (condition) return;
    ++failures;
    std::cerr << "FAIL: " << message << '\n';
}

bool near(float a, float b, float tolerance = 1.0e-5f) {
    return std::abs(a - b) <= tolerance;
}

float coefficientFrequency(const audioapp::ResonatorBandCoefficients& c, float sampleRate) {
    const float radius = std::sqrt(std::max(0.0f, -c.a2));
    return std::acos(std::clamp(c.a1 / (2.0f * radius), -1.0f, 1.0f)) * sampleRate /
           (2.0f * 3.14159265358979323846f);
}

} // namespace

int main() {
    constexpr int frames = 256;
    constexpr float sampleRate = 48000.0f;
    std::vector<float> left(frames, 0.0f);
    std::vector<float> right(frames, 0.0f);
    left[0] = right[0] = 1.0f;

    audioapp::ResonatorBankParams params;
    params.rootHz = 110.0f;
    params.spread = 1.0f;
    params.decaySeconds = 2.0f;
    params.damping = 0.7f;
    params.colorDbPerOctave = 0.0f;
    params.width = 1.0f;
    params.mix = 1.0f;
    audioapp::ResonatorBankRuntime runtime;
    audioapp::processResonatorBankStereoBlock(
        left.data(), right.data(), frames, sampleRate, params, runtime);

    for (int band = 0; band < audioapp::kResonatorBandCount; ++band) {
        const float expectedFrequency = 110.0f * static_cast<float>(band + 1);
        const float actualFrequency = coefficientFrequency(runtime.coefficients[band], sampleRate);
        expect(std::abs(actualFrequency - expectedFrequency) < 0.5f,
               "modal frequencies follow harmonic spread");
        if (band > 0) {
            expect(runtime.coefficients[band].a2 > runtime.coefficients[band - 1].a2,
                   "damping shortens higher modal decay");
        }
    }
    expect(!near(runtime.coefficients[0].gainL, runtime.coefficients[0].gainR),
           "width pans alternating modes");
    expect(std::any_of(left.begin(), left.end(), [](float v) { return std::abs(v) > 1.0e-8f; }),
           "impulse excites resonator output");
    const float wetPeak = *std::max_element(left.begin(), left.end(),
        [](float a, float b) { return std::abs(a) < std::abs(b); });
    expect(std::abs(wetPeak) >= 0.01f,
           "fully wet resonator output remains audible");
    expect(std::all_of(left.begin(), left.end(), [](float v) { return std::isfinite(v); }),
           "resonator output stays finite");

    std::vector<float> dryL = {0.25f, -0.5f, 0.75f, -1.0f};
    std::vector<float> dryR = {-0.125f, 0.25f, -0.375f, 0.5f};
    const auto expectedL = dryL;
    const auto expectedR = dryR;
    params.mix = 0.0f;
    audioapp::ResonatorBankRuntime dryRuntime;
    audioapp::processResonatorBankStereoBlock(
        dryL.data(), dryR.data(), static_cast<int>(dryL.size()), sampleRate, params, dryRuntime);
    expect(dryL == expectedL && dryR == expectedR, "zero mix is sample-transparent");

    auto registry = audioapp::DeviceRegistry::createBuiltIn();
    expect(registry.isKnownType(audioapp::device_types::kResonatorBank),
           "registry exposes resonator bank");
    auto slot = registry.createDefault(audioapp::device_types::kResonatorBank, "res-test");
    expect(registry.setParameter(slot, "resDecay", 0.8f).handled,
           "registry handles resonator parameters");
    expect(registry.setParameter(slot, "resWidth", 2.0f).handled,
           "registry clamps resonator parameters");
    const auto& model = std::get<audioapp::ResonatorBankModel>(slot.config.instance);
    expect(near(model.resDecay, 0.8f), "decay parameter updates model");
    expect(near(model.resWidth, 1.0f), "width parameter clamps to one");

    const std::string json = audioapp::deviceSlotToVar(slot, registry);
    auto restored = audioapp::deviceVarToSlot(json, registry);
    const auto& restoredModel = std::get<audioapp::ResonatorBankModel>(restored.config.instance);
    expect(restored.id == "res-test", "serialization preserves device id");
    expect(near(restoredModel.resDecay, 0.8f) && near(restoredModel.resWidth, 1.0f),
           "serialization preserves resonator parameters");

    if (failures != 0) {
        std::cerr << failures << " resonator test(s) failed\n";
        return 1;
    }
    std::cout << "All resonator bank tests passed\n";
    return 0;
}
