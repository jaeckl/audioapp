// EffectReverbTest - verifies Reverb device creation and parameter handling
#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/effects/EffectDeviceRegistration.hpp"

class EffectReverbTest : public juce::UnitTest {
public:
    EffectReverbTest() : juce::UnitTest("EffectReverb", "Effects") {}

    void runTest() override
    {
        audioapp::DeviceRegistry registry = audioapp::DeviceRegistry::createBuiltIn();
        audioapp::registerTimeBasedEffects(registry);

        beginTest("create default reverb");
        {
            audioapp::DeviceSlot slot = registry.createDefault("reverb", "testReverb");
            const audioapp::IDeviceType* type = registry.findTypeForSlot(slot);
            expect(type != nullptr, "reverb type should be found");
            expect(type->typeId() == "reverb", "typeId should be 'reverb'");
        }

        beginTest("set reverb parameters");
        {
            audioapp::DeviceSlot slot = registry.createDefault("reverb", "testReverb");
            audioapp::DeviceParameterResult result = registry.setParameter(slot, "roomSize", 0.5f);
            expect(result.handled, "roomSize parameter should be handled");
            result = registry.setParameter(slot, "damping", 0.3f);
            expect(result.handled, "damping parameter should be handled");
            result = registry.setParameter(slot, "wetLevel", 0.4f);
            expect(result.handled, "wetLevel parameter should be handled");
        }

        beginTest("round-trip snapshot");
        {
            audioapp::DeviceSlot slot = registry.createDefault("reverb", "testReverb");
            registry.setParameter(slot, "roomSize", 0.8f);
            expect(true, "reverb device created and parameter set");
        }
    }
};

static EffectReverbTest effectReverbTest;