// RestoreFxTest — registry, params, descriptors, JSON roundtrip for all five.
#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/devices/IDeviceType.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/AutomationTypes.hpp"
#include "audioapp/effects/DcOffsetParams.hpp"
#include "audioapp/effects/DeCracklerParams.hpp"
#include "audioapp/effects/DeEsserParams.hpp"
#include "audioapp/effects/DeHumParams.hpp"
#include "audioapp/effects/DeNoiseParams.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/ProjectJson.hpp"

#include <algorithm>
#include <string>
#include <string_view>
#include <vector>

namespace {

bool hasParam(const audioapp::IDeviceType& type, const char* name) {
    for (const auto& d : type.paramDescriptors())
        if (d.stableName != nullptr && std::string_view(d.stableName) == name)
            return true;
    return false;
}

bool isModulatable(const audioapp::IDeviceType& type, const char* name) {
    for (const auto p : type.modulatableParams())
        if (p == name)
            return true;
    return false;
}

bool jsonHasKeys(const juce::var& parsed, std::initializer_list<const char*> keys) {
    const auto* root = parsed.getDynamicObject();
    if (root == nullptr) return false;
    const auto* p = root->getProperty("parameters").getDynamicObject();
    if (p == nullptr) return false;
    for (const char* k : keys)
        if (!p->hasProperty(k))
            return false;
    return true;
}

} // namespace

class RestoreFxTest : public juce::UnitTest {
public:
    RestoreFxTest() : juce::UnitTest("RestoreFxSuite", "RestoreFx") {}

    void runTest() override {
        const audioapp::DeviceRegistry registry = audioapp::DeviceRegistry::createBuiltIn();

        beginTest("registry knows all restore fx types");
        {
            expect(registry.isKnownType(audioapp::device_types::kDcOffset));
            expect(registry.isKnownType(audioapp::device_types::kDeCrackler));
            expect(registry.isKnownType(audioapp::device_types::kDeEsser));
            expect(registry.isKnownType(audioapp::device_types::kDeHum));
            expect(registry.isKnownType(audioapp::device_types::kDeNoise));
        }

        beginTest("param descriptors and modulatable lists");
        {
            const auto* dc = registry.find(audioapp::device_types::kDcOffset);
            const auto* cr = registry.find(audioapp::device_types::kDeCrackler);
            const auto* de = registry.find(audioapp::device_types::kDeEsser);
            const auto* hum = registry.find(audioapp::device_types::kDeHum);
            const auto* dn = registry.find(audioapp::device_types::kDeNoise);
            expect(dc && cr && de && hum && dn, "types resolve");
            if (!dc || !cr || !de || !hum || !dn) return;

            expect(hasParam(*dc, "dcMode") && hasParam(*dc, "dcAmount") && hasParam(*dc, "dcCutoff"));
            expect(isModulatable(*dc, "dcMode") && isModulatable(*dc, "dcAmount"));

            expect(hasParam(*cr, "crackSense") && hasParam(*cr, "crackStrength") && hasParam(*cr, "crackWidth"));
            expect(isModulatable(*cr, "crackSense"));

            expect(hasParam(*de, "deFreq") && hasParam(*de, "deThresh") && hasParam(*de, "deAmount")
                   && hasParam(*de, "deListen"));
            expect(isModulatable(*de, "deAmount") && !isModulatable(*de, "deListen"));

            expect(hasParam(*hum, "humMains") && hasParam(*hum, "humDepth") && hasParam(*hum, "humHarmonics"));
            expect(isModulatable(*hum, "humMains") && isModulatable(*hum, "humDepth"));

            expect(hasParam(*dn, "dnThresh") && hasParam(*dn, "dnReduce") && hasParam(*dn, "dnSmooth"));
            expect(isModulatable(*dn, "dnReduce"));

            // Discrete update rate on mode switches
            for (const auto& d : dc->paramDescriptors())
                if (std::string_view(d.stableName) == "dcMode")
                    expect(d.updateRate == audioapp::ParameterUpdateRate::Discrete, "dcMode Discrete");
            for (const auto& d : hum->paramDescriptors())
                if (std::string_view(d.stableName) == "humMains")
                    expect(d.updateRate == audioapp::ParameterUpdateRate::Discrete, "humMains Discrete");
        }

        beginTest("dc_offset defaults set clamp unknown");
        {
            auto slot = registry.createDefault(audioapp::device_types::kDcOffset, "dc");
            const auto& inst = std::get<audioapp::DcOffsetParams>(slot.config.instance);
            expectWithinAbsoluteError(static_cast<float>(inst.mode), 1.0f, 0.001f);
            expectWithinAbsoluteError(static_cast<float>(inst.amount), 1.0f, 0.001f);
            expectWithinAbsoluteError(static_cast<float>(inst.cutoff), 0.3f, 0.001f);
            expect(registry.setParameter(slot, "dcMode", 0.0f).handled);
            expect(registry.setParameter(slot, "dcAmount", 0.6f).handled);
            expect(registry.setParameter(slot, "dcCutoff", 5.0f).handled);
            const auto& u = std::get<audioapp::DcOffsetParams>(slot.config.instance);
            expectWithinAbsoluteError(static_cast<float>(u.mode), 0.0f, 0.001f);
            expectWithinAbsoluteError(static_cast<float>(u.amount), 0.6f, 0.001f);
            expectWithinAbsoluteError(static_cast<float>(u.cutoff), 1.0f, 0.001f);
            expect(!registry.setParameter(slot, "nope", 0.1f).handled);
        }

        beginTest("de_crackler defaults and all params");
        {
            auto slot = registry.createDefault(audioapp::device_types::kDeCrackler, "cr");
            const auto& inst = std::get<audioapp::DeCracklerParams>(slot.config.instance);
            expectWithinAbsoluteError(static_cast<float>(inst.sensitivity), 0.5f, 0.001f);
            expectWithinAbsoluteError(static_cast<float>(inst.strength), 0.6f, 0.001f);
            expectWithinAbsoluteError(static_cast<float>(inst.width), 0.4f, 0.001f);
            expect(registry.setParameter(slot, "crackSense", 0.1f).handled);
            expect(registry.setParameter(slot, "crackStrength", 0.9f).handled);
            expect(registry.setParameter(slot, "crackWidth", -1.0f).handled);
            const auto& u = std::get<audioapp::DeCracklerParams>(slot.config.instance);
            expectWithinAbsoluteError(static_cast<float>(u.sensitivity), 0.1f, 0.001f);
            expectWithinAbsoluteError(static_cast<float>(u.strength), 0.9f, 0.001f);
            expectWithinAbsoluteError(static_cast<float>(u.width), 0.0f, 0.001f);
        }

        beginTest("de_esser defaults and all params");
        {
            auto slot = registry.createDefault(audioapp::device_types::kDeEsser, "de");
            const auto& inst = std::get<audioapp::DeEsserParams>(slot.config.instance);
            expectWithinAbsoluteError(static_cast<float>(inst.freq), 0.55f, 0.001f);
            expectWithinAbsoluteError(static_cast<float>(inst.threshold), 0.45f, 0.001f);
            expectWithinAbsoluteError(static_cast<float>(inst.amount), 0.5f, 0.001f);
            expectWithinAbsoluteError(static_cast<float>(inst.listen), 0.0f, 0.001f);
            expect(registry.setParameter(slot, "deFreq", 0.2f).handled);
            expect(registry.setParameter(slot, "deThresh", 0.8f).handled);
            expect(registry.setParameter(slot, "deAmount", 0.1f).handled);
            expect(registry.setParameter(slot, "deListen", 1.0f).handled);
            const auto& u = std::get<audioapp::DeEsserParams>(slot.config.instance);
            expectWithinAbsoluteError(static_cast<float>(u.freq), 0.2f, 0.001f);
            expectWithinAbsoluteError(static_cast<float>(u.threshold), 0.8f, 0.001f);
            expectWithinAbsoluteError(static_cast<float>(u.amount), 0.1f, 0.001f);
            expectWithinAbsoluteError(static_cast<float>(u.listen), 1.0f, 0.001f);
        }

        beginTest("de_hum defaults and all params");
        {
            auto slot = registry.createDefault(audioapp::device_types::kDeHum, "hum");
            const auto& inst = std::get<audioapp::DeHumParams>(slot.config.instance);
            expectWithinAbsoluteError(static_cast<float>(inst.mainsFreq), 0.0f, 0.001f);
            expectWithinAbsoluteError(static_cast<float>(inst.depth), 0.7f, 0.001f);
            expectWithinAbsoluteError(static_cast<float>(inst.harmonics), 0.4f, 0.001f);
            expect(registry.setParameter(slot, "humMains", 1.0f).handled);
            expect(registry.setParameter(slot, "humDepth", 0.2f).handled);
            expect(registry.setParameter(slot, "humHarmonics", 1.0f).handled);
            const auto& u = std::get<audioapp::DeHumParams>(slot.config.instance);
            expectWithinAbsoluteError(static_cast<float>(u.mainsFreq), 1.0f, 0.001f);
            expectWithinAbsoluteError(static_cast<float>(u.depth), 0.2f, 0.001f);
            expectWithinAbsoluteError(static_cast<float>(u.harmonics), 1.0f, 0.001f);
        }

        beginTest("de_noise defaults and all params");
        {
            auto slot = registry.createDefault(audioapp::device_types::kDeNoise, "dn");
            const auto& inst = std::get<audioapp::DeNoiseParams>(slot.config.instance);
            expectWithinAbsoluteError(static_cast<float>(inst.threshold), 0.35f, 0.001f);
            expectWithinAbsoluteError(static_cast<float>(inst.reduction), 0.5f, 0.001f);
            expectWithinAbsoluteError(static_cast<float>(inst.smoothing), 0.4f, 0.001f);
            expect(registry.setParameter(slot, "dnThresh", 0.9f).handled);
            expect(registry.setParameter(slot, "dnReduce", 0.1f).handled);
            expect(registry.setParameter(slot, "dnSmooth", 0.0f).handled);
            const auto& u = std::get<audioapp::DeNoiseParams>(slot.config.instance);
            expectWithinAbsoluteError(static_cast<float>(u.threshold), 0.9f, 0.001f);
            expectWithinAbsoluteError(static_cast<float>(u.reduction), 0.1f, 0.001f);
            expectWithinAbsoluteError(static_cast<float>(u.smoothing), 0.0f, 0.001f);
        }

        beginTest("playback node kinds and param passthrough");
        {
            auto check = [&](const char* type, audioapp::DeviceNodeKind kind) {
                auto slot = registry.createDefault(type, "k");
                audioapp::DeviceNodePlayback out;
                registry.buildPlaybackNode(slot, audioapp::PlaybackBuildContext{}, out);
                expect(out.kind == kind, type);
            };
            check(audioapp::device_types::kDcOffset, audioapp::DeviceNodeKind::DcOffset);
            check(audioapp::device_types::kDeCrackler, audioapp::DeviceNodeKind::DeCrackler);
            check(audioapp::device_types::kDeEsser, audioapp::DeviceNodeKind::DeEsser);
            check(audioapp::device_types::kDeHum, audioapp::DeviceNodeKind::DeHum);
            check(audioapp::device_types::kDeNoise, audioapp::DeviceNodeKind::DeNoise);

            auto slot = registry.createDefault(audioapp::device_types::kDeHum, "hum-pt");
            std::get<audioapp::DeHumParams>(slot.config.instance).depth = 0.33;
            std::get<audioapp::DeHumParams>(slot.config.instance).mainsFreq = 1.0;
            audioapp::DeviceNodePlayback out;
            registry.buildPlaybackNode(slot, audioapp::PlaybackBuildContext{}, out);
            const auto& p = std::get<audioapp::DeHumParamsPlayback>(out.params);
            expectWithinAbsoluteError(p.depth, 0.33f, 0.001f);
            expectWithinAbsoluteError(p.mainsFreq, 1.0f, 0.001f);
        }

        beginTest("JSON roundtrip all restore devices");
        {
            auto roundtrip = [&](const char* typeId, auto mutate, auto verify) {
                auto slot = registry.createDefault(typeId, std::string("rt-") + typeId);
                mutate(slot);
                const std::string json = audioapp::deviceSlotToVar(slot, registry);
                auto restored = audioapp::deviceVarToSlot(json, registry);
                expect(restored.id == slot.id, typeId);
                expect(restored.config.bypassed == slot.config.bypassed, typeId);
                verify(restored);
                const auto parsed = juce::JSON::parse(juce::String(json));
                expect(!parsed.isVoid(), typeId);
            };

            roundtrip(audioapp::device_types::kDcOffset,
                [](auto& s) {
                    auto& i = std::get<audioapp::DcOffsetParams>(s.config.instance);
                    i.mode = 0.0; i.amount = 0.42; i.cutoff = 0.77;
                    s.config.bypassed = true;
                },
                [&](const auto& s) {
                    const auto& i = std::get<audioapp::DcOffsetParams>(s.config.instance);
                    expectWithinAbsoluteError(static_cast<float>(i.mode), 0.0f, 0.001f);
                    expectWithinAbsoluteError(static_cast<float>(i.amount), 0.42f, 0.001f);
                    expectWithinAbsoluteError(static_cast<float>(i.cutoff), 0.77f, 0.001f);
                });

            roundtrip(audioapp::device_types::kDeCrackler,
                [](auto& s) {
                    auto& i = std::get<audioapp::DeCracklerParams>(s.config.instance);
                    i.sensitivity = 0.11; i.strength = 0.22; i.width = 0.33;
                },
                [&](const auto& s) {
                    const auto& i = std::get<audioapp::DeCracklerParams>(s.config.instance);
                    expectWithinAbsoluteError(static_cast<float>(i.sensitivity), 0.11f, 0.001f);
                    expectWithinAbsoluteError(static_cast<float>(i.strength), 0.22f, 0.001f);
                    expectWithinAbsoluteError(static_cast<float>(i.width), 0.33f, 0.001f);
                });

            roundtrip(audioapp::device_types::kDeEsser,
                [](auto& s) {
                    auto& i = std::get<audioapp::DeEsserParams>(s.config.instance);
                    i.freq = 0.1; i.threshold = 0.2; i.amount = 0.3; i.listen = 1.0;
                },
                [&](const auto& s) {
                    const auto& i = std::get<audioapp::DeEsserParams>(s.config.instance);
                    expectWithinAbsoluteError(static_cast<float>(i.freq), 0.1f, 0.001f);
                    expectWithinAbsoluteError(static_cast<float>(i.listen), 1.0f, 0.001f);
                });

            roundtrip(audioapp::device_types::kDeHum,
                [](auto& s) {
                    auto& i = std::get<audioapp::DeHumParams>(s.config.instance);
                    i.mainsFreq = 1.0; i.depth = 0.55; i.harmonics = 0.66;
                },
                [&](const auto& s) {
                    const auto& i = std::get<audioapp::DeHumParams>(s.config.instance);
                    expectWithinAbsoluteError(static_cast<float>(i.mainsFreq), 1.0f, 0.001f);
                    expectWithinAbsoluteError(static_cast<float>(i.depth), 0.55f, 0.001f);
                    expectWithinAbsoluteError(static_cast<float>(i.harmonics), 0.66f, 0.001f);
                });

            roundtrip(audioapp::device_types::kDeNoise,
                [](auto& s) {
                    auto& i = std::get<audioapp::DeNoiseParams>(s.config.instance);
                    i.threshold = 0.12; i.reduction = 0.34; i.smoothing = 0.56;
                },
                [&](const auto& s) {
                    const auto& i = std::get<audioapp::DeNoiseParams>(s.config.instance);
                    expectWithinAbsoluteError(static_cast<float>(i.threshold), 0.12f, 0.001f);
                    expectWithinAbsoluteError(static_cast<float>(i.reduction), 0.34f, 0.001f);
                    expectWithinAbsoluteError(static_cast<float>(i.smoothing), 0.56f, 0.001f);
                });
        }

        beginTest("JSON parameter key shapes");
        {
            auto shape = [&](const char* type, std::initializer_list<const char*> keys) {
                auto slot = registry.createDefault(type, "shape");
                const auto json = audioapp::deviceSlotToVar(slot, registry);
                const auto parsed = juce::JSON::parse(juce::String(json));
                expect(jsonHasKeys(parsed, keys), type);
            };
            shape(audioapp::device_types::kDcOffset, {"mode", "amount", "cutoff"});
            shape(audioapp::device_types::kDeCrackler, {"sensitivity", "strength", "width"});
            shape(audioapp::device_types::kDeEsser, {"freq", "threshold", "amount", "listen"});
            shape(audioapp::device_types::kDeHum, {"mainsFreq", "depth", "harmonics"});
            shape(audioapp::device_types::kDeNoise, {"threshold", "reduction", "smoothing"});
        }
    }
};

static RestoreFxTest restoreFxTest;
