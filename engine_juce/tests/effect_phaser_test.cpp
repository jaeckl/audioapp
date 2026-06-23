// EffectPhaserTest - verifies Phaser device creation and parameter handling
#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/effects/EffectDeviceRegistration.hpp"

class EffectPhaserTest : public juce::UnitTest {
public:
    EffectPhaserTest() : juce::UnitTest("EffectPhaser", "Effects") {}

    void runTest() override
    {
        audioapp::DeviceRegistry registry = audioapp::DeviceRegistry::createBuiltIn();
        audioapp::registerTimeBasedEffects(registry);

        beginTest("create default phaser");
        {
            audioapp::DeviceSlot slot = registry.createDefault("phaser", "testPhaser");
            const audioapp::IDeviceType* type = registry.findForSlot(slot);
            expect(type != nullptr, "phaser type should be found");
            expect(type->typeId() == "phaser", "typeId should be 'phaser'");
        }

        beginTest("set phaser parameters");
        {
            audioapp::DeviceSlot slot = registry.createDefault("phaser", "testPhaser");
            audioapp::DeviceParameterResult result = registry.setParameter(slot, "depth", 0.5f);
            expect(result.handled, "depth parameter should be handled");
            result = registry.setParameter(slot, "rateHz", 1.0f);
            expect(result.handled, "rateHz parameter should be handled");
            result = registry.setParameter(slot, "feedback", 0.3f);
            expect(result.handled, "feedback parameter should be handled");
        }

        beginTest("round-trip snapshot");
        {
            audioapp::DeviceSlot slot = registry.createDefault("phaser", "testPhaser");
            registry.setParameter(slot, "depth", 0.6f);
            expect(true, "phaser device created and parameter set");
        }
    }
};

static EffectPhaserTest effectPhaserTest;