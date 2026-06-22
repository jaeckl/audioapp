#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/ProjectJson.hpp"

#include <cmath>
#include <string>
#include <string_view>

// Helper: read a float from a juce::var JSON tree at a given path.
static float readJsonFloat(const juce::var& root, std::string_view paramKey, float fallback)
{
    if (const auto* obj = root.getDynamicObject()) {
        const auto params = obj->getProperty("parameters");
        if (const auto* p = params.getDynamicObject()) {
            const auto v = p->getProperty(juce::Identifier(juce::String(paramKey.data(), static_cast<int>(paramKey.size()))));
            if (v.isDouble() || v.isInt() || v.isInt64())
                return static_cast<float>(static_cast<double>(v));
        }
    }
    return fallback;
}

static bool hasJsonParameter(const juce::var& root, std::string_view paramKey)
{
    if (const auto* obj = root.getDynamicObject()) {
        const auto params = obj->getProperty("parameters");
        if (const auto* p = params.getDynamicObject()) {
            return p->hasProperty(juce::Identifier(juce::String(paramKey.data(), static_cast<int>(paramKey.size()))));
        }
    }
    return false;
}

static int readJsonInt(const juce::var& root, std::string_view paramKey, int fallback)
{
    if (const auto* obj = root.getDynamicObject()) {
        const auto params = obj->getProperty("parameters");
        if (const auto* p = params.getDynamicObject()) {
            const auto v = p->getProperty(juce::Identifier(juce::String(paramKey.data(), static_cast<int>(paramKey.size()))));
            if (v.isInt() || v.isInt64()) return static_cast<int>(v);
            if (v.isDouble()) return static_cast<int>(static_cast<double>(v));
        }
    }
    return fallback;
}

static bool hasMeters(const juce::var& root)
{
    if (const auto* obj = root.getDynamicObject()) {
        return obj->hasProperty("meters");
    }
    return false;
}

class DeviceSlotSerializationTest : public juce::UnitTest {
public:
    DeviceSlotSerializationTest() : juce::UnitTest("DeviceSlotSerialization", "Devices") {}

    void runTest() override
    {
        const audioapp::DeviceRegistry registry = audioapp::DeviceRegistry::createBuiltIn();
        const auto types = registry.knownTypes();

        beginTest("round-trip all device types");
        {
            int tested = 0;
            for (const auto& typeId : types) {
                audioapp::DeviceSlot original = registry.createDefault(typeId, "test-device");
                if (original.id.empty()) {
                    expect(false, "createDefault returned empty slot for type " + std::string(typeId));
                    continue;
                }

                // Basic round-trip
                const std::string json = audioapp::deviceSlotToVar(original, registry);
                audioapp::DeviceSlot restored = audioapp::deviceVarToSlot(json, registry);

                expect(restored.id == original.id, "id mismatch for " + std::string(typeId));
                expectWithinAbsoluteError(restored.gain, original.gain, 0.001f);
                expectWithinAbsoluteError(restored.pan, original.pan, 0.001f);
                expect(restored.bypassed == original.bypassed, "bypass mismatch for " + std::string(typeId));

                // Parameter modification round-trip (if modulatable params exist)
                auto modulatable = registry.modulatableParams(typeId);
                if (!modulatable.empty()) {
                    audioapp::DeviceSlot modified = original;
                    modified.gain = 0.5f;
                    modified.pan = 0.8f;
                    modified.bypassed = true;

                    const std::string json2 = audioapp::deviceSlotToVar(modified, registry);
                    audioapp::DeviceSlot restored2 = audioapp::deviceVarToSlot(json2, registry);

                    expectWithinAbsoluteError(restored2.gain, 0.5f, 0.001f,
                                              "modified gain not preserved for " + std::string(typeId));
                    expectWithinAbsoluteError(restored2.pan, 0.8f, 0.001f,
                                              "modified pan not preserved for " + std::string(typeId));
                    expect(restored2.bypassed, "modified bypass not preserved for " + std::string(typeId));
                }

                ++tested;
            }
            expect(tested > 0, "at least one device type was tested");
        }

        beginTest("device-specific parameters");
        {
            // Oscillator: verify frequencyHz round-trip
            {
                const auto typeId = audioapp::device_types::kOscillator;
                audioapp::DeviceSlot slot = registry.createDefault(typeId, "osc-test");
                const auto json = audioapp::deviceSlotToVar(slot, registry);
                const auto parsed = juce::JSON::parse(juce::String(json));
                const float freq = readJsonFloat(parsed, "frequency", -1.0f);
                expectWithinAbsoluteError(freq, 440.0f, 0.001f,
                                          "oscillator frequencyHz default should be 440.0");

                // Verify it round-trips through registry-aware overload
                const auto parsed2 = juce::JSON::parse(juce::String(audioapp::deviceSlotToVar(slot, registry)));
                const audioapp::DeviceSlot restoredSlot = audioapp::deviceFromVar(parsed2, registry);
                expectWithinAbsoluteError(
                    std::get<audioapp::OscillatorParams>(restoredSlot.instance).frequencyHz,
                    440.0f, 0.001f,
                    "oscillator registry-aware round-trip failed");
            }

            // Dynamics devices: verify meters sub-object present
            for (const auto* dynType : {audioapp::device_types::kGate, audioapp::device_types::kCompressor,
                                        audioapp::device_types::kExpander, audioapp::device_types::kLimiter}) {
                audioapp::DeviceSlot slot = registry.createDefault(dynType, "dyn-test");
                const auto json = audioapp::deviceSlotToVar(slot, registry);
                const auto parsed = juce::JSON::parse(juce::String(json));
                expect(hasMeters(parsed), juce::String(dynType) + " missing meters sub-object");
            }

            // TrackGain: verify no pan/bypass in output
            {
                audioapp::DeviceSlot slot = registry.createDefault(audioapp::device_types::kTrackGain, "tg-test");
                const auto json = audioapp::deviceSlotToVar(slot, registry);
                const auto parsed = juce::JSON::parse(juce::String(json));
                expect(!hasJsonParameter(parsed, "pan"), "track_gain should not write pan parameter");
            }
        }

        beginTest("legacy rename: osc1Wave -> osc1Shape");
        {
            auto* root = new juce::DynamicObject();
            root->setProperty("id", "legacy-sub");
            root->setProperty("type", juce::String(audioapp::device_types::kSubtractiveSynth));
            auto* params = new juce::DynamicObject();
            params->setProperty("gain", 1.0);
            params->setProperty("pan", 0.5);
            params->setProperty("bypass", 0.0);
            params->setProperty("osc1Wave", 3);   // legacy: int 3 -> shape = 3/4 = 0.75f
            params->setProperty("osc2Wave", 1);   // legacy: int 1 -> shape = 1/4 = 0.25f
            root->setProperty("parameters", juce::var(params));
            const auto legacyJson = juce::JSON::toString(juce::var(root), false);

            const audioapp::DeviceSlot restored =
                audioapp::deviceVarToSlot(legacyJson.toStdString(), registry);
            expect(restored.id == "legacy-sub", "legacy osc1Wave round-trip id mismatch");

            // Re-serialize and check osc1Shape is now the primary key
            const auto reserialized = audioapp::deviceSlotToVar(restored, registry);
            const auto parsed = juce::JSON::parse(juce::String(reserialized));

            const float shape1 = readJsonFloat(parsed, "osc1Shape", -1.0f);
            expectWithinAbsoluteError(shape1, 0.75f, 0.001f,
                                      "osc1Wave->osc1Shape expected 0.75");

            const float shape2 = readJsonFloat(parsed, "osc2Shape", -1.0f);
            expectWithinAbsoluteError(shape2, 0.25f, 0.001f,
                                      "osc2Wave->osc2Shape expected 0.25");
        }

        beginTest("legacy rename: osc1Level+osc2Level -> oscMix");
        {
            auto* root = new juce::DynamicObject();
            root->setProperty("id", "legacy-mix");
            root->setProperty("type", juce::String(audioapp::device_types::kSubtractiveSynth));
            auto* params = new juce::DynamicObject();
            params->setProperty("gain", 1.0);
            params->setProperty("pan", 0.5);
            params->setProperty("bypass", 0.0);
            params->setProperty("osc1Level", 0.8);
            params->setProperty("osc2Level", 0.2);
            root->setProperty("parameters", juce::var(params));
            const auto legacyJson = juce::JSON::toString(juce::var(root), false);

            const audioapp::DeviceSlot restored =
                audioapp::deviceVarToSlot(legacyJson.toStdString(), registry);
            const auto reserialized = audioapp::deviceSlotToVar(restored, registry);
            const auto parsed = juce::JSON::parse(juce::String(reserialized));
            const float mix = readJsonFloat(parsed, "oscMix", -1.0f);
            // Expected: sum=1.0, oscMix = 0.2/1.0 = 0.2f
            expectWithinAbsoluteError(mix, 0.2f, 0.005f,
                                      "osc1Level+osc2Level->oscMix expected ~0.2");
        }

        beginTest("legacy rename: cymbalMetal+cymbalBrightness -> cymbalColor");
        {
            auto* root = new juce::DynamicObject();
            root->setProperty("id", "legacy-cym");
            root->setProperty("type", juce::String(audioapp::device_types::kCymbalGenerator));
            auto* params = new juce::DynamicObject();
            params->setProperty("gain", 1.0);
            params->setProperty("pan", 0.5);
            params->setProperty("bypass", 0.0);
            params->setProperty("cymbalMetal", 0.6f);
            params->setProperty("cymbalBrightness", 0.8f);
            root->setProperty("parameters", juce::var(params));
            const auto legacyJson = juce::JSON::toString(juce::var(root), false);

            const audioapp::DeviceSlot restored =
                audioapp::deviceVarToSlot(legacyJson.toStdString(), registry);
            const auto reserialized = audioapp::deviceSlotToVar(restored, registry);
            const auto parsed = juce::JSON::parse(juce::String(reserialized));
            const float color = readJsonFloat(parsed, "cymbalColor", -1.0f);
            // Expected: (0.6 + 0.8) * 0.5 = 0.7
            expectWithinAbsoluteError(color, 0.7f, 0.005f,
                                      "cymbalMetal+bright->cymbalColor expected ~0.7");
        }

        beginTest("legacy rename: crashWash+crashBright -> crashColor");
        {
            auto* root = new juce::DynamicObject();
            root->setProperty("id", "legacy-crash");
            root->setProperty("type", juce::String(audioapp::device_types::kCrashGenerator));
            auto* params = new juce::DynamicObject();
            params->setProperty("gain", 1.0);
            params->setProperty("pan", 0.5);
            params->setProperty("bypass", 0.0);
            params->setProperty("crashWash", 0.7f);
            params->setProperty("crashBright", 0.5f);
            root->setProperty("parameters", juce::var(params));
            const auto legacyJson = juce::JSON::toString(juce::var(root), false);

            const audioapp::DeviceSlot restored =
                audioapp::deviceVarToSlot(legacyJson.toStdString(), registry);
            const auto reserialized = audioapp::deviceSlotToVar(restored, registry);
            const auto parsed = juce::JSON::parse(juce::String(reserialized));
            const float color = readJsonFloat(parsed, "crashColor", -1.0f);
            // Expected: (0.7 + 0.5) * 0.5 = 0.6
            expectWithinAbsoluteError(color, 0.6f, 0.005f,
                                      "crashWash+bright->crashColor expected ~0.6");
        }

        beginTest("error handling");
        {
            // Unknown type returns empty slot
            {
                const audioapp::DeviceSlot result = audioapp::deviceVarToSlot(
                    "{\"id\":\"x\",\"type\":\"unknown_device\",\"parameters\":{\"gain\":1.0}}",
                    registry);
                expect(result.id.empty(), "unknown device type should return empty slot");
            }

            // Missing type field returns empty slot
            {
                const audioapp::DeviceSlot result = audioapp::deviceVarToSlot(
                    "{\"id\":\"x\",\"parameters\":{\"gain\":1.0}}", registry);
                expect(result.id.empty(), "missing type should return empty slot");
            }

            // Empty JSON returns empty slot
            {
                const audioapp::DeviceSlot result = audioapp::deviceVarToSlot("", registry);
                expect(result.id.empty(), "empty JSON should return empty slot");
            }

            // deviceToVar with unknown registry type returns empty var (should not crash)
            {
                audioapp::DeviceSlot unknownSlot;
                unknownSlot.id = "x";
                const auto result = audioapp::deviceToVar(unknownSlot, registry);
                // Should not crash; result could be empty or partial
            }
        }
    }
};

static DeviceSlotSerializationTest deviceSlotSerializationTest;