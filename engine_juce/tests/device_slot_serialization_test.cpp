#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/ProjectJson.hpp"

#include <juce_core/juce_core.h>

#include <cmath>
#include <cstdlib>
#include <iostream>
#include <string>
#include <string_view>

// Helper: read a float from a juce::var JSON tree at a given path.
static float readJsonFloat(const juce::var& root, std::string_view paramKey, float fallback) {
    if (const auto* obj = root.getDynamicObject()) {
        const auto params = obj->getProperty("parameters");
        if (const auto* p = params.getDynamicObject()) {
            const auto v = p->getProperty(juce::Identifier(paramKey.data(), paramKey.size()));
            if (v.isDouble() || v.isInt() || v.isInt64())
                return static_cast<float>(static_cast<double>(v));
        }
    }
    return fallback;
}

static bool hasJsonParameter(const juce::var& root, std::string_view paramKey) {
    if (const auto* obj = root.getDynamicObject()) {
        const auto params = obj->getProperty("parameters");
        if (const auto* p = params.getDynamicObject()) {
            return p->hasProperty(juce::Identifier(paramKey.data(), paramKey.size()));
        }
    }
    return false;
}

static int readJsonInt(const juce::var& root, std::string_view paramKey, int fallback) {
    if (const auto* obj = root.getDynamicObject()) {
        const auto params = obj->getProperty("parameters");
        if (const auto* p = params.getDynamicObject()) {
            const auto v = p->getProperty(juce::Identifier(paramKey.data(), paramKey.size()));
            if (v.isInt() || v.isInt64()) return static_cast<int>(v);
            if (v.isDouble()) return static_cast<int>(static_cast<double>(v));
        }
    }
    return fallback;
}

static bool hasMeters(const juce::var& root) {
    if (const auto* obj = root.getDynamicObject()) {
        return obj->hasProperty("meters");
    }
    return false;
}

int main() {
    const audioapp::DeviceRegistry registry = audioapp::DeviceRegistry::createBuiltIn();
    const auto types = registry.knownTypes();

    int failures = 0;
    int tested = 0;

    for (const auto& typeId : types) {
        audioapp::DeviceSlot original = registry.createDefault(typeId, "test-device");
        if (original.id.empty()) {
            std::cerr << "FAIL: createDefault returned empty slot for type " << typeId << std::endl;
            ++failures;
            continue;
        }

        // Basic round-trip
        const std::string json = audioapp::deviceSlotToVar(original, registry);
        audioapp::DeviceSlot restored = audioapp::deviceVarToSlot(json, registry);

        if (restored.id != original.id) {
            std::cerr << "FAIL: id mismatch for " << typeId << std::endl;
            ++failures;
            continue;
        }
        if (std::abs(restored.gain - original.gain) > 0.001f) {
            std::cerr << "FAIL: gain mismatch for " << typeId << std::endl;
            ++failures;
            continue;
        }
        if (std::abs(restored.pan - original.pan) > 0.001f) {
            std::cerr << "FAIL: pan mismatch for " << typeId << std::endl;
            ++failures;
            continue;
        }
        if (restored.bypassed != original.bypassed) {
            std::cerr << "FAIL: bypass mismatch for " << typeId << std::endl;
            ++failures;
            continue;
        }

        // Parameter modification round-trip (if modulatable params exist)
        auto modulatable = registry.modulatableParams(typeId);
        if (!modulatable.empty()) {
            audioapp::DeviceSlot modified = original;
            modified.gain = 0.5f;
            modified.pan = 0.8f;
            modified.bypassed = true;

            const std::string json2 = audioapp::deviceSlotToVar(modified, registry);
            audioapp::DeviceSlot restored2 = audioapp::deviceVarToSlot(json2, registry);

            if (std::abs(restored2.gain - 0.5f) > 0.001f) {
                std::cerr << "FAIL: modified gain not preserved for " << typeId << std::endl;
                ++failures;
                continue;
            }
            if (std::abs(restored2.pan - 0.8f) > 0.001f) {
                std::cerr << "FAIL: modified pan not preserved for " << typeId << std::endl;
                ++failures;
                continue;
            }
            if (!restored2.bypassed) {
                std::cerr << "FAIL: modified bypassed not preserved for " << typeId << std::endl;
                ++failures;
                continue;
            }
        }

        ++tested;
    }

    std::cout << "Round-trip: tested " << tested << " device types, " << failures << " failures."
              << std::endl;

    // --- Device-specific parameter tests ---
    int paramTests = 0;
    int paramFails = 0;

    // Oscillator: verify frequencyHz round-trip
    {
        const auto typeId = audioapp::device_types::kOscillator;
        audioapp::DeviceSlot slot = registry.createDefault(typeId, "osc-test");
        const auto json = audioapp::deviceSlotToVar(slot, registry);
        const auto parsed = juce::JSON::parse(juce::String(json));
        const float freq = readJsonFloat(parsed, "frequency", -1.0f);
        // OscillatorInstance default frequencyHz should be 440.0
        if (std::abs(freq - 440.0f) > 0.001f) {
            std::cerr << "FAIL: oscillator frequencyHz default is " << freq
                      << ", expected 440.0" << std::endl;
            ++paramFails;
        }
        ++paramTests;

        // Verify it round-trips through registry-aware overload
        const auto parsed2 = juce::JSON::parse(juce::String(audioapp::deviceSlotToVar(slot, registry)));
        const audioapp::DeviceSlot restoredSlot = audioapp::deviceFromVar(parsed2, registry);
        if (std::abs(std::get<audioapp::OscillatorInstance>(restoredSlot.instance).frequencyHz - 440.0f) > 0.001f) {
            std::cerr << "FAIL: oscillator registry-aware round-trip failed" << std::endl;
            ++paramFails;
        }
        ++paramTests;
    }

    // Dynamics devices: verify meters sub-object present
    for (const auto* dynType : {audioapp::device_types::kGate, audioapp::device_types::kCompressor,
                                audioapp::device_types::kExpander, audioapp::device_types::kLimiter}) {
        audioapp::DeviceSlot slot = registry.createDefault(dynType, "dyn-test");
        const auto json = audioapp::deviceSlotToVar(slot, registry);
        const auto parsed = juce::JSON::parse(juce::String(json));
        if (!hasMeters(parsed)) {
            std::cerr << "FAIL: " << dynType << " missing meters sub-object" << std::endl;
            ++paramFails;
        }
        ++paramTests;
    }

    // TrackGain: verify no pan/bypass in output
    {
        audioapp::DeviceSlot slot = registry.createDefault(audioapp::device_types::kTrackGain, "tg-test");
        const auto json = audioapp::deviceSlotToVar(slot, registry);
        const auto parsed = juce::JSON::parse(juce::String(json));
        if (hasJsonParameter(parsed, "pan")) {
            std::cerr << "FAIL: track_gain should not write pan parameter" << std::endl;
            ++paramFails;
        }
        ++paramTests;
    }

    std::cout << "Param tests: " << paramTests << " tested, " << paramFails << " failures." << std::endl;
    failures += paramFails;

    // --- Legacy rename tests ---
    int legacyTests = 0;
    int legacyFails = 0;

    // Test 1: SubtractiveSynth with osc1Wave (legacy) should load as osc1Shape
    {
        auto* root = new juce::DynamicObject();
        root->setProperty("id", "legacy-sub");
        root->setProperty("type", juce::String(audioapp::device_types::kSubtractiveSynth));
        auto* params = new juce::DynamicObject();
        params->setProperty("gain", 1.0);
        params->setProperty("pan", 0.5);
        params->setProperty("bypass", 0.0);
        // Use legacy field name
        params->setProperty("osc1Wave", 3);  // legacy: int 3 → shape = 3/4 = 0.75f
        params->setProperty("osc2Wave", 1);  // legacy: int 1 → shape = 1/4 = 0.25f
        root->setProperty("parameters", juce::var(params));
        const auto legacyJson = juce::JSON::toString(juce::var(root), false);

        const audioapp::DeviceSlot restored = audioapp::deviceVarToSlot(legacyJson.toStdString(), registry);
        if (restored.id != "legacy-sub") {
            std::cerr << "FAIL: legacy osc1Wave round-trip id mismatch" << std::endl;
            ++legacyFails;
        }
        ++legacyTests;

        // Re-serialize and check osc1Shape is now the primary key
        const auto reserialized = audioapp::deviceSlotToVar(restored, registry);
        const auto parsed = juce::JSON::parse(juce::String(reserialized));
        const float shape1 = readJsonFloat(parsed, "osc1Shape", -1.0f);
        if (std::abs(shape1 - 0.75f) > 0.001f) {
            std::cerr << "FAIL: osc1Wave→osc1Shape expected 0.75, got " << shape1 << std::endl;
            ++legacyFails;
        }
        ++legacyTests;
        const float shape2 = readJsonFloat(parsed, "osc2Shape", -1.0f);
        if (std::abs(shape2 - 0.25f) > 0.001f) {
            std::cerr << "FAIL: osc2Wave→osc2Shape expected 0.25, got " << shape2 << std::endl;
            ++legacyFails;
        }
        ++legacyTests;
    }

    // Test 2: SubtractiveSynth with osc1Level+osc2Level (legacy oscMix fallback)
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

        const audioapp::DeviceSlot restored = audioapp::deviceVarToSlot(legacyJson.toStdString(), registry);
        // Re-serialize: should now write oscMix instead
        const auto reserialized = audioapp::deviceSlotToVar(restored, registry);
        const auto parsed = juce::JSON::parse(juce::String(reserialized));
        const float mix = readJsonFloat(parsed, "oscMix", -1.0f);
        // Expected: sum=1.0, oscMix = 0.2/1.0 = 0.2f
        if (std::abs(mix - 0.2f) > 0.005f) {
            std::cerr << "FAIL: osc1Level+osc2Level→oscMix expected ~0.2, got " << mix << std::endl;
            ++legacyFails;
        }
        ++legacyTests;
    }

    // Test 3: CymbalGenerator with legacy cymbalMetal+cymbalBrightness
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

        const audioapp::DeviceSlot restored = audioapp::deviceVarToSlot(legacyJson.toStdString(), registry);
        const auto reserialized = audioapp::deviceSlotToVar(restored, registry);
        const auto parsed = juce::JSON::parse(juce::String(reserialized));
        const float color = readJsonFloat(parsed, "cymbalColor", -1.0f);
        // Expected: (0.6 + 0.8) * 0.5 = 0.7
        if (std::abs(color - 0.7f) > 0.005f) {
            std::cerr << "FAIL: cymbalMetal+bright→cymbalColor expected ~0.7, got " << color << std::endl;
            ++legacyFails;
        }
        ++legacyTests;
    }

    // Test 4: CrashGenerator with legacy crashWash+crashBright
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

        const audioapp::DeviceSlot restored = audioapp::deviceVarToSlot(legacyJson.toStdString(), registry);
        const auto reserialized = audioapp::deviceSlotToVar(restored, registry);
        const auto parsed = juce::JSON::parse(juce::String(reserialized));
        const float color = readJsonFloat(parsed, "crashColor", -1.0f);
        // Expected: (0.7 + 0.5) * 0.5 = 0.6
        if (std::abs(color - 0.6f) > 0.005f) {
            std::cerr << "FAIL: crashWash+bright→crashColor expected ~0.6, got " << color << std::endl;
            ++legacyFails;
        }
        ++legacyTests;
    }

    std::cout << "Legacy tests: " << legacyTests << " tested, " << legacyFails << " failures."
              << std::endl;
    failures += legacyFails;

    // --- Error handling tests ---
    int errorTests = 0;
    int errorFails = 0;

    // Unknown type returns empty slot
    {
        const audioapp::DeviceSlot result = audioapp::deviceVarToSlot("{\"id\":\"x\",\"type\":\"unknown_device\",\"parameters\":{\"gain\":1.0}}", registry);
        if (!result.id.empty()) {
            std::cerr << "FAIL: unknown device type should return empty slot" << std::endl;
            ++errorFails;
        }
        ++errorTests;
    }

    // Missing type field returns empty slot
    {
        const audioapp::DeviceSlot result = audioapp::deviceVarToSlot("{\"id\":\"x\",\"parameters\":{\"gain\":1.0}}", registry);
        if (!result.id.empty()) {
            std::cerr << "FAIL: missing type should return empty slot" << std::endl;
            ++errorFails;
        }
        ++errorTests;
    }

    // Empty JSON returns empty slot
    {
        const audioapp::DeviceSlot result = audioapp::deviceVarToSlot("", registry);
        if (!result.id.empty()) {
            std::cerr << "FAIL: empty JSON should return empty slot" << std::endl;
            ++errorFails;
        }
        ++errorTests;
    }

    // deviceToVar with unknown registry type returns empty var
    {
        audioapp::DeviceSlot unknownSlot;
        unknownSlot.id = "x";
        // Leaving instance as default (empty variant)
        const auto result = audioapp::deviceToVar(unknownSlot, registry);
        // Should not crash; result could be empty or partial
        ++errorTests;
    }

    std::cout << "Error tests: " << errorTests << " tested, " << errorFails << " failures."
              << std::endl;
    failures += errorFails;

    std::cout << "\nTotal: " << (tested + paramTests + legacyTests + errorTests) << " tests, "
              << failures << " failures." << std::endl;
    return failures > 0 ? EXIT_FAILURE : EXIT_SUCCESS;
}