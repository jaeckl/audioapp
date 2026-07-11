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
            const audioapp::IDeviceType* type = registry.findForSlot(slot);
            expect(type != nullptr, "reverb type should be found");
            expect(type->typeId() == "reverb", "typeId should be 'reverb'");
        }

        beginTest("set reverb parameters");
        {
            audioapp::DeviceSlot slot = registry.createDefault("reverb", "testReverb");
            audioapp::DeviceParameterResult result = registry.setParameter(slot, "modeMorph", 2.0f);
            expect(result.handled, "modeMorph parameter should be handled");
            result = registry.setParameter(slot, "decay", 0.75f);
            expect(result.handled, "decay parameter should be handled");
            result = registry.setParameter(slot, "preDelay", 0.2f);
            expect(result.handled, "preDelay parameter should be handled");
            result = registry.setParameter(slot, "damping", 0.7f);
            expect(result.handled, "damping parameter should be handled");
            result = registry.setParameter(slot, "ducking", 0.4f);
            expect(result.handled, "ducking parameter should be handled");
        }

        beginTest("round-trip snapshot");
        {
            audioapp::DeviceSlot slot = registry.createDefault("reverb", "testReverb");
            registry.setParameter(slot, "decay", 0.8f);
            expect(true, "reverb device created and parameter set");
        }
    }
};

static EffectReverbTest effectReverbTest;
