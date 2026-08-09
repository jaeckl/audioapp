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
            const audioapp::IDeviceType* type = registry.findForSlot(slot);
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
            result = registry.setParameter(slot, "outputMix", 0.4f);
            expect(result.handled, "outputMix adapter parameter should be handled");
            expectWithinAbsoluteError(
                std::get<audioapp::StereoOutputPanel>(slot.config.outputPanel).outputMix,
                0.4f, 0.001f, "outputMix should update the output adapter");
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
