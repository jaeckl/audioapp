#!/usr/bin/env python3
"""Generate Restore FX Params, DeviceType, Processor stubs."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INC = ROOT / "engine_juce/include/audioapp"
SRC = ROOT / "engine_juce/src"

DEVICES = [
    {
        "name": "DcOffset",
        "kind": "DcOffset",
        "type_id": "dc_offset",
        "k_const": "kDcOffset",
        "fields": [
            ("mode", 1.0),
            ("amount", 1.0),
            ("cutoff", 0.3),
        ],
        "param_enum": [("Mode", "dcMode", "mode"), ("Amount", "dcAmount", "amount"), ("Cutoff", "dcCutoff", "cutoff")],
        "mod": ["dcAmount", "dcCutoff"],
    },
    {
        "name": "DeCrackler",
        "kind": "DeCrackler",
        "type_id": "de_crackler",
        "k_const": "kDeCrackler",
        "fields": [
            ("sensitivity", 0.5),
            ("strength", 0.6),
            ("width", 0.4),
        ],
        "param_enum": [
            ("Sense", "crackSense", "sensitivity"),
            ("Strength", "crackStrength", "strength"),
            ("Width", "crackWidth", "width"),
        ],
        "mod": ["crackSense", "crackStrength", "crackWidth"],
    },
    {
        "name": "DeEsser",
        "kind": "DeEsser",
        "type_id": "de_esser",
        "k_const": "kDeEsser",
        "fields": [
            ("freq", 0.55),
            ("threshold", 0.45),
            ("amount", 0.5),
            ("listen", 0.0),
        ],
        "param_enum": [
            ("Freq", "deFreq", "freq"),
            ("Thresh", "deThresh", "threshold"),
            ("Amount", "deAmount", "amount"),
            ("Listen", "deListen", "listen"),
        ],
        "mod": ["deFreq", "deThresh", "deAmount"],
    },
    {
        "name": "DeHum",
        "kind": "DeHum",
        "type_id": "de_hum",
        "k_const": "kDeHum",
        "fields": [
            ("mainsFreq", 0.0),
            ("depth", 0.7),
            ("harmonics", 0.4),
        ],
        "param_enum": [
            ("Mains", "humMains", "mainsFreq"),
            ("Depth", "humDepth", "depth"),
            ("Harmonics", "humHarmonics", "harmonics"),
        ],
        "mod": ["humDepth", "humHarmonics"],
    },
    {
        "name": "DeNoise",
        "kind": "DeNoise",
        "type_id": "de_noise",
        "k_const": "kDeNoise",
        "fields": [
            ("threshold", 0.35),
            ("reduction", 0.5),
            ("smoothing", 0.4),
        ],
        "param_enum": [
            ("Thresh", "dnThresh", "threshold"),
            ("Reduce", "dnReduce", "reduction"),
            ("Smooth", "dnSmooth", "smoothing"),
        ],
        "mod": ["dnThresh", "dnReduce", "dnSmooth"],
    },
]


def write_params(d):
    name = d["name"]
    lines = [
        "#pragma once",
        "",
        "#include <juce_core/juce_core.h>",
        "",
        "namespace audioapp {",
        "",
        f"struct {name}Params {{",
    ]
    for f, default in d["fields"]:
        lines.append(f"    double {f} = {default};")
    lines += ["", "    void clamp() {"]
    for f, _ in d["fields"]:
        lines.append(f"        {f} = juce::jlimit(0.0, 1.0, {f});")
    lines += [
        "    }",
        "",
        "    juce::var toJson() const {",
        "        juce::DynamicObject* obj = new juce::DynamicObject();",
    ]
    for f, _ in d["fields"]:
        lines.append(f'        obj->setProperty("{f}", {f});')
    lines += [
        "        return juce::var(obj);",
        "    }",
        "",
        f"    static {name}Params fromJson(const juce::var& v) {{",
        f"        {name}Params p;",
        "        if (v.isObject()) {",
        "            const auto* obj = v.getDynamicObject();",
    ]
    for f, _ in d["fields"]:
        lines.append(
            f'            p.{f} = obj->getProperty("{f}").toString().getDoubleValue();'
        )
    lines += [
        "            p.clamp();",
        "        }",
        "        return p;",
        "    }",
        "};",
        "",
        "} // namespace audioapp",
        "",
    ]
    path = INC / "effects" / f"{name}Params.hpp"
    path.write_text("\n".join(lines), encoding="utf-8")
    print("wrote", path.relative_to(ROOT))


def write_device_type_hpp(d):
    name = d["name"]
    lines = f"""#pragma once

#include "audioapp/devices/IDeviceType.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/effects/{name}Params.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include <span>

namespace audioapp {{

class {name}DeviceType final : public IDeviceType {{
public:
    std::string typeId() const override {{ return device_types::{d['k_const']}; }}
    DeviceSlot createDefault(const std::string& deviceId) const override;
    DeviceParameterResult setParameter(DeviceSlot& slot, std::string_view parameterId, float value) const override;
    bool setStringParameter(DeviceSlot& slot, std::string_view parameterId, const std::string& value, const PlaybackBuildContext& context) const override;
    std::vector<std::string_view> modulatableParams() const override;
    void buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext& context, DeviceNodePlayback& out) const override;
    bool buildLiveInstrument(const DeviceSlot& slot, const PlaybackBuildContext& context, LiveInstrumentSnapshot& out) const override;
    juce::var slotToVar(const DeviceSlot& slot) const override;
    DeviceSlot varToSlot(const juce::var& obj) const override;
    DeviceProcessor* createProcessor(ProcessorArena& arena) const override;
    DeviceNodeKind kind() const noexcept override;
    uint16_t paramIdFromString(std::string_view name) const noexcept override;
    std::string_view paramIdToString(uint16_t localId) const noexcept override;
    std::span<const ParamDescriptor> paramDescriptors() const noexcept override;
    bool usesDspAutomationSubBlocks() const noexcept override;
}};

}} // namespace audioapp
"""
    path = INC / "effects" / f"{name}DeviceType.hpp"
    path.write_text(lines, encoding="utf-8")
    print("wrote", path.relative_to(ROOT))


def write_device_type_cpp(d):
    name = d["name"]
    kind = d["kind"]
    enum = f"{name}Param"
    pb = f"{name}ParamsPlayback"

    set_cases = []
    for enum_name, _, field in d["param_enum"]:
        set_cases.append(
            f"    case {enum}::{enum_name}:\n"
            f"        instance.{field} = juce::jlimit(0.0, 1.0, static_cast<double>(value));\n"
            f"        break;"
        )

    from_str = []
    to_str = []
    desc = []
    build_assign = []
    json_set = []
    json_get = []
    for enum_name, pid, field in d["param_enum"]:
        default = next(v for f, v in d["fields"] if f == field)
        from_str.append(f'    if (name == "{pid}") return static_cast<uint16_t>({enum}::{enum_name});')
        to_str.append(f'    case {enum}::{enum_name}: return "{pid}";')
        desc.append(
            f'        {{static_cast<uint16_t>({enum}::{enum_name}), "{pid}", "{enum_name}", '
            f'{default}f, 0.0f, 1.0f, true, true}},'
        )
        build_assign.append(f"    p.{field} = static_cast<float>(inst.{field});")
        json_set.append(f'    parameters->setProperty("{field}", inst.{field});')
        json_get.append(f"            inst.{field} = p->getProperty(\"{field}\").toString().getDoubleValue();")

    mod_list = ", ".join(f'"{m}"' for m in (["gain", "pan"] + d["mod"]))

    create_fields = "\n".join(f"    instance.{f} = {v};" for f, v in d["fields"])

    lines = f"""#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/effects/{name}DeviceType.hpp"
#include "audioapp/effects/{name}Params.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/devices/processors/{name}Processor.hpp"
#include "audioapp/AutomationTypes.hpp"

namespace audioapp {{

DeviceSlot {name}DeviceType::createDefault(const std::string& deviceId) const {{
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    {name}Params instance;
{create_fields}
    slot.config.instance = std::move(instance);
    slot.config.inputPanel = EmptyPanel{{}};
    slot.config.outputPanel = StereoOutputPanel{{}};
    slot.config.bypassed = false;
    return slot;
}}

DeviceParameterResult {name}DeviceType::setParameter(DeviceSlot& slot,
                                                      std::string_view parameterId,
                                                      float value) const {{
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {{
        result.handled = true;
        return result;
    }}
    auto& instance = std::get<{name}Params>(slot.config.instance);
    const uint16_t id = paramIdFromString(parameterId);
    if (id == static_cast<uint16_t>(-1))
        return result;
    const auto localId = static_cast<{enum}>(id);
    switch (localId) {{
{chr(10).join(set_cases)}
    default:
        return result;
    }}
    result.handled = true;
    return result;
}}

bool {name}DeviceType::setStringParameter(DeviceSlot&, std::string_view, const std::string&, const PlaybackBuildContext&) const {{ return false; }}

std::vector<std::string_view> {name}DeviceType::modulatableParams() const {{
    return {{{mod_list}}};
}}

void {name}DeviceType::buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext&, DeviceNodePlayback& out) const {{
    out.kind = DeviceNodeKind::{kind};
    const auto& inst = std::get<{name}Params>(slot.config.instance);
    {pb} p;
{chr(10).join(build_assign)}
    p.inputGain = 1.0f;
    out.params = p;
}}

bool {name}DeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&, LiveInstrumentSnapshot&) const {{ return false; }}

juce::var {name}DeviceType::slotToVar(const DeviceSlot& slot) const {{
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<{name}Params>(slot.config.instance);
{chr(10).join(json_set)}

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));

    auto* outObj = new juce::DynamicObject();
    const auto& panel = std::get<StereoOutputPanel>(slot.config.outputPanel);
    outObj->setProperty("type", "stereo");
    outObj->setProperty("gain", static_cast<double>(panel.gain));
    outObj->setProperty("pan", static_cast<double>(panel.pan));
    outObj->setProperty("outputMix", static_cast<double>(panel.outputMix));
    outObj->setProperty("outputWidth", static_cast<double>(panel.outputWidth));
    object->setProperty("outputPanel", juce::var(outObj));

    auto* inObj = new juce::DynamicObject();
    inObj->setProperty("type", "empty");
    object->setProperty("inputPanel", juce::var(inObj));

    object->setProperty("bypass", slot.config.bypassed ? 1.0 : 0.0);
    object->setProperty("parameters", juce::var(parameters));

    auto* meters = new juce::DynamicObject();
    meters->setProperty("gainReductionDb", 0.0);
    meters->setProperty("inputLevel", 0.0);
    object->setProperty("meters", juce::var(meters));

    return juce::var(object);
}}

DeviceSlot {name}DeviceType::varToSlot(const juce::var& obj) const {{
    DeviceSlot slot;
    if (const auto* object = obj.getDynamicObject()) {{
        slot.id = object->getProperty("id").toString().toStdString();
        slot.config.typeId = object->getProperty("type").toString().toStdString();

        const auto outputPanelVar = object->getProperty("outputPanel");
        bool hasPanel = outputPanelVar.isObject();
        if (hasPanel) {{
            const auto* panel = outputPanelVar.getDynamicObject();
            auto readPanel = [&](const char* key, float fallback) -> float {{
                const auto v = panel->getProperty(key);
                if (v.isDouble() || v.isInt() || v.isInt64())
                    return static_cast<float>(static_cast<double>(v));
                return fallback;
            }};
            StereoOutputPanel sp;
            sp.gain = readPanel("gain", 1.0f);
            sp.pan = readPanel("pan", 0.5f);
            sp.outputMix = readPanel("outputMix", 1.0f);
            sp.outputWidth = readPanel("outputWidth", 1.0f);
            slot.config.outputPanel = sp;
        }}

        slot.config.bypassed = object->getProperty("bypass").isDouble()
            ? (static_cast<float>(static_cast<double>(object->getProperty("bypass"))) >= 0.5f)
            : false;

        const auto params = object->getProperty("parameters");
        if (const auto* p = params.getDynamicObject()) {{
            auto readFloat = [&](const char* key, float fallback) -> float {{
                const auto v = p->getProperty(key);
                if (v.isDouble() || v.isInt() || v.isInt64())
                    return static_cast<float>(static_cast<double>(v));
                return fallback;
            }};

            if (!hasPanel) {{
                StereoOutputPanel sp;
                sp.gain = readFloat("gain", 1.0f);
                sp.pan = readFloat("pan", 0.5f);
                sp.outputMix = readFloat("outputMix", 1.0f);
                sp.outputWidth = readFloat("outputWidth", 1.0f);
                slot.config.outputPanel = sp;
                slot.config.bypassed = readFloat("bypass", 0.0f) >= 0.5f;
            }}

            {name}Params inst;
{chr(10).join(json_get)}
            inst.clamp();
            slot.config.instance = inst;
        }}
    }}
    return slot;
}}

DeviceProcessor* {name}DeviceType::createProcessor(ProcessorArena& arena) const {{
    return arena.template emplace<{name}Processor>();
}}

DeviceNodeKind {name}DeviceType::kind() const noexcept {{ return DeviceNodeKind::{kind}; }}

uint16_t {name}DeviceType::paramIdFromString(std::string_view name) const noexcept {{
{chr(10).join(from_str)}
    return static_cast<uint16_t>(-1);
}}

std::string_view {name}DeviceType::paramIdToString(uint16_t localId) const noexcept {{
    switch (static_cast<{enum}>(localId)) {{
{chr(10).join(to_str)}
    default: return "";
    }}
}}

std::span<const ParamDescriptor> {name}DeviceType::paramDescriptors() const noexcept {{
    static constexpr ParamDescriptor kParams[] = {{
{chr(10).join(desc)}
    }};
    return kParams;
}}

bool {name}DeviceType::usesDspAutomationSubBlocks() const noexcept {{ return false; }}

}} // namespace audioapp
"""
    path = SRC / "effects" / f"{name}DeviceType.cpp"
    path.write_text(lines, encoding="utf-8")
    print("wrote", path.relative_to(ROOT))


def write_processor_hpp(d):
    name = d["name"]
    lines = f"""#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"

namespace audioapp {{

class {name}Processor : public DeviceProcessor {{
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;

private:
    float stateA_ = 0.0f;
    float stateB_ = 0.0f;
    float stateC_ = 0.0f;
    float prevL_ = 0.0f;
    float prevR_ = 0.0f;
    int repairLeft_ = 0;
    float repairStartL_ = 0.0f;
    float repairStartR_ = 0.0f;
    float repairEndL_ = 0.0f;
    float repairEndR_ = 0.0f;
    float z1L_[8] = {{}};
    float z2L_[8] = {{}};
    float z1R_[8] = {{}};
    float z2R_[8] = {{}};
}};

}} // namespace audioapp
"""
    path = INC / "devices/processors" / f"{name}Processor.hpp"
    path.write_text(lines, encoding="utf-8")
    print("wrote", path.relative_to(ROOT))


DSP_BODIES = {
    "DcOffset": r'''
    auto p = std::get<DcOffsetParamsPlayback>(*ctx.modulatedParams);
    applyStereoScalarGain(block.channelL, block.channelR, block.numSamples,
                          std::clamp(p.inputGain, 0.0f, 1.0f));
    const float amount = std::clamp(p.amount, 0.0f, 1.0f);
    const float cutoff = std::clamp(p.cutoff, 0.0f, 1.0f);
    const bool hpf = p.mode >= 0.5f;
    const float sr = static_cast<float>(std::max(ctx.sampleRate, 1.0));
    if (hpf) {
        const float hz = 20.0f + cutoff * 180.0f;
        const float x = std::exp(-2.0f * 3.14159265f * hz / sr);
        for (int i = 0; i < block.numSamples; ++i) {
            const float inL = block.channelL[i];
            const float inR = block.channelR[i];
            stateA_ = x * (stateA_ + inL - prevL_);
            stateB_ = x * (stateB_ + inR - prevR_);
            prevL_ = inL;
            prevR_ = inR;
            block.channelL[i] = inL + (stateA_ - inL) * amount;
            block.channelR[i] = inR + (stateB_ - inR) * amount;
        }
    } else {
        const float a = 0.001f;
        for (int i = 0; i < block.numSamples; ++i) {
            const float mid = 0.5f * (block.channelL[i] + block.channelR[i]);
            stateC_ += a * (mid - stateC_);
            block.channelL[i] -= stateC_ * amount;
            block.channelR[i] -= stateC_ * amount;
        }
    }
''',
    "DeCrackler": r'''
    auto p = std::get<DeCracklerParamsPlayback>(*ctx.modulatedParams);
    applyStereoScalarGain(block.channelL, block.channelR, block.numSamples,
                          std::clamp(p.inputGain, 0.0f, 1.0f));
    const float sense = 0.02f + std::clamp(p.sensitivity, 0.0f, 1.0f) * 0.35f;
    const float strength = std::clamp(p.strength, 0.0f, 1.0f);
    const int width = 2 + static_cast<int>(std::clamp(p.width, 0.0f, 1.0f) * 30.0f);
    for (int i = 0; i < block.numSamples; ++i) {
        float l = block.channelL[i];
        float r = block.channelR[i];
        if (repairLeft_ > 0) {
            const float t = 1.0f - static_cast<float>(repairLeft_) / static_cast<float>(width);
            const float il = repairStartL_ + (repairEndL_ - repairStartL_) * t;
            const float ir = repairStartR_ + (repairEndR_ - repairStartR_) * t;
            l = l + (il - l) * strength;
            r = r + (ir - r) * strength;
            --repairLeft_;
        } else {
            const float dL = std::abs(l - prevL_);
            const float dR = std::abs(r - prevR_);
            if (dL > sense || dR > sense) {
                repairLeft_ = width;
                repairStartL_ = prevL_;
                repairStartR_ = prevR_;
                const int look = std::min(width, block.numSamples - i - 1);
                repairEndL_ = block.channelL[i + look];
                repairEndR_ = block.channelR[i + look];
            }
        }
        prevL_ = block.channelL[i];
        prevR_ = block.channelR[i];
        block.channelL[i] = l;
        block.channelR[i] = r;
    }
''',
    "DeEsser": r'''
    auto p = std::get<DeEsserParamsPlayback>(*ctx.modulatedParams);
    applyStereoScalarGain(block.channelL, block.channelR, block.numSamples,
                          std::clamp(p.inputGain, 0.0f, 1.0f));
    const float freq = 2000.0f + std::clamp(p.freq, 0.0f, 1.0f) * 10000.0f;
    const float thresh = std::clamp(p.threshold, 0.0f, 1.0f) * 0.4f;
    const float amount = std::clamp(p.amount, 0.0f, 1.0f);
    const bool listen = p.listen >= 0.5f;
    const float sr = static_cast<float>(std::max(ctx.sampleRate, 1.0));
    const float w = 2.0f * 3.14159265f * freq / sr;
    const float cosw = std::cos(w);
    const float alpha = std::sin(w) * 0.5f;
    const float b0 = alpha, b1 = 0.0f, b2 = -alpha;
    const float a0 = 1.0f + alpha, a1 = -2.0f * cosw, a2 = 1.0f - alpha;
    const float invA0 = 1.0f / a0;
    for (int i = 0; i < block.numSamples; ++i) {
        const float inL = block.channelL[i];
        const float inR = block.channelR[i];
        const float bandL = (b0 * inL + b1 * z1L_[0] + b2 * z2L_[0] - a1 * z1L_[1] - a2 * z2L_[1]) * invA0;
        z2L_[0] = z1L_[0]; z1L_[0] = inL; z2L_[1] = z1L_[1]; z1L_[1] = bandL;
        const float bandR = (b0 * inR + b1 * z1R_[0] + b2 * z2R_[0] - a1 * z1R_[1] - a2 * z2R_[1]) * invA0;
        z2R_[0] = z1R_[0]; z1R_[0] = inR; z2R_[1] = z1R_[1]; z1R_[1] = bandR;
        const float envIn = 0.5f * (std::abs(bandL) + std::abs(bandR));
        stateC_ = stateC_ * 0.95f + envIn * 0.05f;
        float gr = 1.0f;
        if (stateC_ > thresh)
            gr = 1.0f - amount * std::min(1.0f, (stateC_ - thresh) / 0.3f);
        if (listen) {
            block.channelL[i] = bandL;
            block.channelR[i] = bandR;
        } else {
            block.channelL[i] = inL - bandL * (1.0f - gr);
            block.channelR[i] = inR - bandR * (1.0f - gr);
        }
    }
''',
    "DeHum": r'''
    auto p = std::get<DeHumParamsPlayback>(*ctx.modulatedParams);
    applyStereoScalarGain(block.channelL, block.channelR, block.numSamples,
                          std::clamp(p.inputGain, 0.0f, 1.0f));
    const float mains = p.mainsFreq >= 0.5f ? 60.0f : 50.0f;
    const float depth = std::clamp(p.depth, 0.0f, 1.0f);
    const int nHarm = 1 + static_cast<int>(std::clamp(p.harmonics, 0.0f, 1.0f) * 7.0f);
    const float sr = static_cast<float>(std::max(ctx.sampleRate, 1.0));
    for (int h = 0; h < nHarm; ++h) {
        const float hz = mains * static_cast<float>(h + 1);
        if (hz > sr * 0.45f) break;
        const float w = 2.0f * 3.14159265f * hz / sr;
        const float bw = 0.5f + depth * 4.0f;
        const float alpha = std::sin(w) / (2.0f * bw);
        const float b0 = 1.0f, b1 = -2.0f * std::cos(w), b2 = 1.0f;
        const float a0 = 1.0f + alpha, a1 = -2.0f * std::cos(w), a2 = 1.0f - alpha;
        const float invA0 = 1.0f / a0;
        const float mix = depth;
        for (int i = 0; i < block.numSamples; ++i) {
            float inL = block.channelL[i];
            float yL = (b0 * inL + b1 * z1L_[h] + b2 * z2L_[h] - a1 * stateA_ - a2 * stateB_) * invA0;
            // reuse per-harmonic delay via z arrays; simplified state per harm index
            z2L_[h] = z1L_[h];
            z1L_[h] = inL;
            // secondary states shared — acceptable simple notch cascade
            const float outL = inL + (yL - inL) * mix;
            block.channelL[i] = outL;

            float inR = block.channelR[i];
            float yR = (b0 * inR + b1 * z1R_[h] + b2 * z2R_[h] - a1 * prevL_ - a2 * prevR_) * invA0;
            z2R_[h] = z1R_[h];
            z1R_[h] = inR;
            block.channelR[i] = inR + (yR - inR) * mix;
        }
        stateA_ = z1L_[h];
        stateB_ = z2L_[h];
        prevL_ = z1R_[h];
        prevR_ = z2R_[h];
    }
''',
    "DeNoise": r'''
    auto p = std::get<DeNoiseParamsPlayback>(*ctx.modulatedParams);
    applyStereoScalarGain(block.channelL, block.channelR, block.numSamples,
                          std::clamp(p.inputGain, 0.0f, 1.0f));
    const float thresh = std::clamp(p.threshold, 0.0f, 1.0f) * 0.25f;
    const float reduce = std::clamp(p.reduction, 0.0f, 1.0f);
    const float smooth = 0.05f + std::clamp(p.smoothing, 0.0f, 1.0f) * 0.9f;
    const float sr = static_cast<float>(std::max(ctx.sampleRate, 1.0));
    const float hp = std::exp(-2.0f * 3.14159265f * 3000.0f / sr);
    for (int i = 0; i < block.numSamples; ++i) {
        const float inL = block.channelL[i];
        const float inR = block.channelR[i];
        stateA_ = hp * (stateA_ + inL - prevL_);
        stateB_ = hp * (stateB_ + inR - prevR_);
        prevL_ = inL;
        prevR_ = inR;
        const float noise = 0.5f * (std::abs(stateA_) + std::abs(stateB_));
        float target = 1.0f;
        if (noise < thresh)
            target = 1.0f - reduce * (1.0f - noise / std::max(thresh, 1.0e-6f));
        stateC_ = stateC_ * smooth + target * (1.0f - smooth);
        block.channelL[i] = inL * stateC_;
        block.channelR[i] = inR * stateC_;
    }
''',
}


def write_processor_cpp(d):
    name = d["name"]
    body = DSP_BODIES[name]
    lines = f"""#include "audioapp/devices/processors/{name}Processor.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include <cmath>
#include <algorithm>

namespace audioapp {{

void {name}Processor::process(AudioBlock& block, ProcessContext& ctx) noexcept {{
{body}
    if (ctx.deviceMeters != nullptr && meterSlot >= 0 && meterSlot < ctx.maxDeviceMeters) {{
        float inputPeak = stereoBlockPeak(block.channelL, block.channelR, block.numSamples);
        ctx.deviceMeters[meterSlot].gainReductionDb.store(0.0f, std::memory_order_relaxed);
        ctx.deviceMeters[meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
    }}
}}

}} // namespace audioapp
"""
    path = SRC / "devices/processors" / f"{name}Processor.cpp"
    path.write_text(lines, encoding="utf-8")
    print("wrote", path.relative_to(ROOT))


def write_registration():
    hpp = INC / "effects/RestoreEffectRegistration.hpp"
    hpp.write_text(
        """#pragma once

namespace audioapp {

class DeviceRegistry;

void registerRestoreEffects(DeviceRegistry& registry);

} // namespace audioapp
""",
        encoding="utf-8",
    )
    includes = "\n".join(
        f'#include "audioapp/effects/{d["name"]}DeviceType.hpp"' for d in DEVICES
    )
    regs = "\n".join(
        f"    registry.registerType(std::make_unique<{d['name']}DeviceType>());"
        for d in DEVICES
    )
    cpp = SRC / "effects/RestoreEffectRegistration.cpp"
    cpp.write_text(
        f"""#include "audioapp/effects/RestoreEffectRegistration.hpp"
#include "audioapp/devices/DeviceRegistry.hpp"
{includes}

namespace audioapp {{

void registerRestoreEffects(DeviceRegistry& registry) {{
{regs}
}}

}} // namespace audioapp
""",
        encoding="utf-8",
    )
    print("wrote registration")


def main():
    for d in DEVICES:
        write_params(d)
        write_device_type_hpp(d)
        write_device_type_cpp(d)
        write_processor_hpp(d)
        write_processor_cpp(d)
    write_registration()
    print("done")


if __name__ == "__main__":
    main()
