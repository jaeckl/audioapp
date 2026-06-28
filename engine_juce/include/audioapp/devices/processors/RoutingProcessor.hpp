#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"

namespace audioapp {

class RoutingProcessor final : public DeviceProcessor {
public:
    explicit RoutingProcessor(DeviceNodeKind nodeKind) noexcept : nodeKind_(nodeKind) {}

    void process(AudioBlock&, ProcessContext&) noexcept override {}
    DeviceNodeKind kind() const noexcept override { return nodeKind_; }

private:
    DeviceNodeKind nodeKind_;
};

} // namespace audioapp
