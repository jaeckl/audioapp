#include "audioapp/effects/EffectSnapshot.hpp"

#include "audioapp/effects/DelayParams.hpp"
#include "audioapp/effects/ReverbParams.hpp"
#include "audioapp/effects/ChorusParams.hpp"
#include "audioapp/effects/PhaserParams.hpp"

namespace audioapp {

juce::var EffectSnapshot::toJson() const {
    juce::DynamicObject* obj = new juce::DynamicObject();
    obj->setProperty("type", juce::String(type));

    juce::var paramsVar; // will hold JSON of concrete params
    std::visit([&paramsVar](auto&& arg) {
        using T = std::decay_t<decltype(arg)>;
        if constexpr (!std::is_same_v<T, std::monostate>) {
            paramsVar = arg.toJson();
        } else {
            paramsVar = juce::var(); // empty/undefined
        }
    }, params);

    obj->setProperty("params", paramsVar);
    return juce::var(obj);
}

EffectSnapshot EffectSnapshot::fromJson(const juce::var& v) {
    EffectSnapshot snap;
    if (!v.isObject())
        return snap;

    const auto* obj = v.getDynamicObject();
    snap.type = obj->getProperty("type").toString().toStdString();
    juce::var paramsVar = obj->getProperty("params");

    if (snap.type == "delay") {
        snap.params = DelayParams::fromJson(paramsVar);
    } else if (snap.type == "reverb") {
        snap.params = ReverbParams::fromJson(paramsVar);
    } else if (snap.type == "chorus") {
        snap.params = ChorusParams::fromJson(paramsVar);
    } else if (snap.type == "phaser") {
        snap.params = PhaserParams::fromJson(paramsVar);
    } else {
        // unknown type – leave params as monostate
        snap.params = std::monostate{};
    }
    return snap;
}

} // namespace audioapp
