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
            result = registry.setParameter(slot, "waveform", 2.0f);
            expect(result.handled, "waveform parameter should be handled");
            result = registry.setParameter(slot, "stereoPhase", 0.75f);
            expect(result.handled, "stereo phase parameter should be handled");
            result = registry.setParameter(slot, "stages", 10.0f);
            expect(result.handled, "stages parameter should be handled");
        }

        beginTest("round-trip snapshot");
        {
            audioapp::DeviceSlot slot = registry.createDefault("phaser", "testPhaser");
            registry.setParameter(slot, "waveShape", 0.7f);
            registry.setParameter(slot, "rateMode", 3.0f);
            const audioapp::IDeviceType* type = registry.findForSlot(slot);
            const auto restored = type->varToSlot(type->slotToVar(slot));
            const auto& params = std::get<audioapp::PhaserParams>(restored.config.instance);
            expectWithinAbsoluteError(params.waveShape, 0.7, 1.0e-6,
                                      "wave shape should survive serialization");
            expectWithinAbsoluteError(params.rateMode, 3.0, 1.0e-6,
                                      "rate mode should survive serialization");
            expectWithinAbsoluteError(params.stages, 8.0, 1.0e-6,
                                      "default stage count should survive serialization");
        }
    }
};

static EffectPhaserTest effectPhaserTest;
