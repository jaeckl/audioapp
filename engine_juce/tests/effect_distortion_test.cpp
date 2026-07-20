// EffectDistortionTest — Sym param + snapshot round-trip.
#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/effects/DistortionParams.hpp"

class EffectDistortionTest : public juce::UnitTest {
public:
    EffectDistortionTest() : juce::UnitTest("EffectDistortion", "Effects") {}

    void runTest() override
    {
        audioapp::DeviceRegistry registry = audioapp::DeviceRegistry::createBuiltIn();

        beginTest("create default distortion");
        {
            audioapp::DeviceSlot slot = registry.createDefault("distortion", "testDist");
            const audioapp::IDeviceType* type = registry.findForSlot(slot);
            expect(type != nullptr, "distortion type should be found");
            expect(type->typeId() == "distortion", "typeId should be 'distortion'");
            const auto& inst = std::get<audioapp::DistortionParams>(slot.config.instance);
            expectWithinAbsoluteError(static_cast<float>(inst.sym), 0.5f, 0.001f,
                                      "default sym is centered");
        }

        beginTest("set drive sym tone mix");
        {
            audioapp::DeviceSlot slot = registry.createDefault("distortion", "testDist");
            expect(registry.setParameter(slot, "distDrive", 0.8f).handled, "distDrive handled");
            expect(registry.setParameter(slot, "distSym", 0.2f).handled, "distSym handled");
            expect(registry.setParameter(slot, "distTone", 0.7f).handled, "distTone handled");
            expect(registry.setParameter(slot, "distMix", 1.0f).handled, "distMix handled");
            const auto& inst = std::get<audioapp::DistortionParams>(slot.config.instance);
            expectWithinAbsoluteError(static_cast<float>(inst.drive), 0.8f, 0.001f, "drive");
            expectWithinAbsoluteError(static_cast<float>(inst.sym), 0.2f, 0.001f, "sym");
            expectWithinAbsoluteError(static_cast<float>(inst.tone), 0.7f, 0.001f, "tone");
            expectWithinAbsoluteError(static_cast<float>(inst.mix), 1.0f, 0.001f, "mix");
        }

        beginTest("alias param names drive/sym");
        {
            audioapp::DeviceSlot slot = registry.createDefault("distortion", "testDist");
            expect(registry.setParameter(slot, "sym", 0.9f).handled, "sym alias handled");
            const auto& inst = std::get<audioapp::DistortionParams>(slot.config.instance);
            expectWithinAbsoluteError(static_cast<float>(inst.sym), 0.9f, 0.001f, "sym via alias");
        }

        beginTest("round-trip snapshot keeps sym");
        {
            audioapp::DeviceSlot slot = registry.createDefault("distortion", "testDist");
            registry.setParameter(slot, "distSym", 0.15f);
            registry.setParameter(slot, "distDrive", 0.65f);
            const audioapp::IDeviceType* type = registry.findForSlot(slot);
            const juce::var snap = type->slotToVar(slot);
            audioapp::DeviceSlot restored = type->varToSlot(snap);
            const auto& inst = std::get<audioapp::DistortionParams>(restored.config.instance);
            expectWithinAbsoluteError(static_cast<float>(inst.sym), 0.15f, 0.001f, "sym round-trip");
            expectWithinAbsoluteError(static_cast<float>(inst.drive), 0.65f, 0.001f, "drive round-trip");
        }

        beginTest("legacy snapshot missing sym defaults to 0.5");
        {
            audioapp::DeviceSlot slot = registry.createDefault("distortion", "legacy");
            const audioapp::IDeviceType* type = registry.findForSlot(slot);
            auto* parameters = new juce::DynamicObject();
            parameters->setProperty("drive", 0.4);
            parameters->setProperty("tone", 0.6);
            parameters->setProperty("mix", 0.5);
            auto* object = new juce::DynamicObject();
            object->setProperty("id", "legacy");
            object->setProperty("type", "distortion");
            object->setProperty("bypass", 0.0);
            object->setProperty("parameters", juce::var(parameters));
            auto* outObj = new juce::DynamicObject();
            outObj->setProperty("type", "stereo");
            outObj->setProperty("gain", 1.0);
            outObj->setProperty("pan", 0.5);
            outObj->setProperty("outputMix", 1.0);
            outObj->setProperty("outputWidth", 1.0);
            object->setProperty("outputPanel", juce::var(outObj));
            audioapp::DeviceSlot restored = type->varToSlot(juce::var(object));
            const auto& inst = std::get<audioapp::DistortionParams>(restored.config.instance);
            expectWithinAbsoluteError(static_cast<float>(inst.sym), 0.5f, 0.001f,
                                      "missing sym defaults centered");
            expectWithinAbsoluteError(static_cast<float>(inst.drive), 0.4f, 0.001f, "drive restored");
        }
    }
};

static EffectDistortionTest effectDistortionTest;
