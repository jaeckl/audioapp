#pragma once

#include <string>
#include <string_view>

#include <juce_core/juce_core.h>

#include "audioapp/modulation/ModulatorParams.hpp"
#include "audioapp/modulation/IModulator.hpp"
#include "audioapp/modulation/ModulatorArena.hpp"

namespace audioapp {

/// Control-thread modulator type descriptor.
/// One instance per built-in modulator kind (LFO, ADSR, ADR).
class IModulatorType {
public:
    virtual ~IModulatorType() = default;

    /// Canonical type identifier (e.g. "lfo", "adsr", "adr").
    virtual std::string typeId() const = 0;

    /// Returns the ModulatorType enum value for this type.
    virtual int modulatorTypeValue() const = 0;

    /// Create a default parameter set for this modulator kind.
    virtual ModulatorParams createDefault() const = 0;

    /// Set a parameter on the given ModulatorParams.
    /// @return true if the parameter was handled.
    virtual bool setParameter(ModulatorParams& params,
                              std::string_view paramId, float value) const = 0;

    /// Create a new IModulator instance in the given arena, initialized with the given params.
    virtual IModulator* createModulator(ModulatorArena& arena,
                                        const ModulatorParams& params) const = 0;

    /// Serialize ModulatorParams to juce::var for JSON output.
    virtual juce::var paramsToVar(const ModulatorParams& params) const = 0;

    /// Deserialize ModulatorParams from a juce::var.
    virtual ModulatorParams varToParams(const juce::var& obj) const = 0;
};

} // namespace audioapp