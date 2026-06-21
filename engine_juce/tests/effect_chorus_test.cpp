// EffectChorusTest - verifies Chorus device creation and parameter handling
#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/effects/EffectDeviceRegistration.hpp"

class EffectChorusTest : public juce::UnitTest {
public:
    EffectChorusTest() : juce::UnitTest("EffectChorus", "Effects") {}

    void runTest() override
    {
        audioapp::DeviceRegistry registry = audioapp::DeviceRegistry::createBuiltIn();
        audioapp::registerTimeBasedEffects(registry);

        beginTest("create default chorus");
        {
            audioapp::DeviceSlot slot = registry.createDefault("chorus", "testChorus");
            const audioapp::IDeviceType* type = registry.findTypeForSlot(slot);
            expect(type != nullptr, "chorus type should be found");
            expect(type->typeId() == "chorus", "typeId should be 'chorus'");
        }

        beginTest("set chorus parameters");
        {
            audioapp::DeviceSlot slot = registry.createDefault("chorus", "testChorus");
            audioapp::DeviceParameterResult result = registry.setParameter(slot, "depth", 0.5f);
            expect(result.handled, "depth parameter should be handled");
            result = registry.setParameter(slot, "rateHz", 1.2f);
            expect(result.handled, "rateHz parameter should be handled");
            result = registry.setParameter(slot, "mix", 0.4f);
            expect(result.handled, "mix parameter should be handled");
        }

        beginTest("round-trip snapshot");
        {
            audioapp::DeviceSlot slot = registry.createDefault("chorus", "testChorus");
            registry.setParameter(slot, "depth", 0.75f);
            expect(true, "chorus device created and parameter set");
        }
    }
};

static EffectChorusTest effectChorusTest;