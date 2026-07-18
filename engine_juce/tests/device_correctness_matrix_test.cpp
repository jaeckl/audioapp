#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/dsp/AudioBlock.hpp"
#include "audioapp/dsp/ProcessContext.hpp"
#include "audioapp/dsp/ProcessorArena.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <cmath>
#include <cstdlib>
#include <iostream>
#include <limits>
#include <memory>
#include <new>
#include <set>
#include <string>

namespace allocation_audit {
thread_local bool enabled = false;
thread_local std::uint64_t count = 0;
}

void* operator new(std::size_t size) {
    if (allocation_audit::enabled) ++allocation_audit::count;
    if (void* result = std::malloc(size)) return result;
    throw std::bad_alloc{};
}

void* operator new[](std::size_t size) { return ::operator new(size); }
void operator delete(void* pointer) noexcept { std::free(pointer); }
void operator delete[](void* pointer) noexcept { std::free(pointer); }
void operator delete(void* pointer, std::size_t) noexcept { std::free(pointer); }
void operator delete[](void* pointer, std::size_t) noexcept { std::free(pointer); }

namespace {

int failures = 0;

void expect(bool condition, const std::string& message) {
    if (condition) return;
    ++failures;
    std::cerr << "FAIL: " << message << '\n';
}

bool finiteAndReasonable(const float* left, const float* right, int frames) {
    for (int frame = 0; frame < frames; ++frame) {
        if (!std::isfinite(left[frame]) || !std::isfinite(right[frame]) ||
            std::abs(left[frame]) > 1.0e6f || std::abs(right[frame]) > 1.0e6f) {
            return false;
        }
    }
    return true;
}

void fillRepresentativeSignal(float* left, float* right, int frames,
                              double sampleRate) {
    for (int frame = 0; frame < frames; ++frame) {
        const float phase = static_cast<float>(
            2.0 * 3.14159265358979323846 * 220.0 * frame / sampleRate);
        left[frame] = 0.15f * std::sin(phase);
        right[frame] = 0.12f * std::cos(phase);
    }
}

} // namespace

int main() {
    using namespace audioapp;

    const auto registry = DeviceRegistry::createBuiltIn();
    const auto knownTypes = registry.knownTypes();
    expect(!knownTypes.empty(), "built-in registry is not empty");

    auto scratch = std::make_unique<DeviceChainScratch>();
    constexpr int kMaxFrames = 4096;
    auto left = std::make_unique<float[]>(kMaxFrames);
    auto right = std::make_unique<float[]>(kMaxFrames);
    const std::array<int, 4> blockSizes{1, 17, 257, kMaxFrames};
    const std::array<double, 3> sampleRates{44100.0, 48000.0, 96000.0};
    const MidiPlaybackNote note{60, 0.0, 4.0, 0.0, 2.0, 100.0f, false, 4.0};

    int processorsExercised = 0;
    int callbacksExercised = 0;
    for (const auto typeId : knownTypes) {
        const auto label = std::string(typeId);
        std::cout << "Matrix device: " << label << std::endl;
        const auto* type = registry.find(typeId);
        expect(type != nullptr, label + ": registry lookup succeeds");
        if (type == nullptr) continue;

        auto slot = registry.createDefault(typeId, "matrix-" + label);
        expect(slot.config.typeId == typeId, label + ": default preserves type ID");

        std::set<std::string> descriptorNames;
        for (const auto& descriptor : type->paramDescriptors()) {
            const std::string parameter = descriptor.stableName != nullptr
                ? descriptor.stableName : "";
            expect(!parameter.empty(), label + ": parameter has a stable name");
            expect(descriptorNames.insert(parameter).second,
                   label + ": parameter names are unique: " + parameter);
            expect(std::isfinite(descriptor.defaultValue) &&
                   std::isfinite(descriptor.minValue) &&
                   std::isfinite(descriptor.maxValue) &&
                   descriptor.minValue <= descriptor.defaultValue &&
                   descriptor.defaultValue <= descriptor.maxValue,
                   label + ": descriptor range is valid: " + parameter);
            expect(type->paramIdFromString(parameter) != 0xffff,
                   label + ": stable name resolves to an ID: " + parameter);

            auto minimumSlot = slot;
            auto maximumSlot = slot;
            expect(registry.setParameter(
                       minimumSlot, parameter, descriptor.minValue).handled,
                   label + ": minimum is accepted: " + parameter);
            expect(registry.setParameter(
                       maximumSlot, parameter, descriptor.maxValue).handled,
                   label + ": maximum is accepted: " + parameter);
            auto invalidSlot = slot;
            expect(!registry.setParameter(invalidSlot, parameter,
                                          std::numeric_limits<float>::quiet_NaN()).handled,
                   label + ": NaN is rejected: " + parameter);
            expect(!registry.setParameter(invalidSlot, parameter,
                                          std::numeric_limits<float>::infinity()).handled,
                   label + ": infinity is rejected: " + parameter);
        }

        PlaybackBuildContext buildContext{};
        buildContext.deviceRegistry = &registry;
        DeviceNodePlayback node{};
        registry.buildPlaybackNode(slot, buildContext, node);
        expect(node.kind != DeviceNodeKind::Unknown,
               label + ": builds a concrete playback node");

        ProcessorArena arena(1);
        auto* processor = type->createProcessor(arena);
        expect(processor != nullptr, label + ": creates a processor");
        if (processor == nullptr) continue;
        processor->applyPlaybackNode(node);
        ++processorsExercised;

        for (const double sampleRate : sampleRates) {
            for (const int blockSize : blockSizes) {
                fillRepresentativeSignal(left.get(), right.get(), blockSize, sampleRate);
                ProcessContext context(*scratch);
                context.sampleRate = sampleRate;
                context.bpm = 120;
                context.playheadBeat = 0.0;
                context.notes = &note;
                context.noteCount = 1;
                context.numFrames = blockSize;
                context.modulatedParams = &node.params;
                AudioBlock block{left.get(), right.get(), blockSize};
                processor->process(block, context);
                expect(finiteAndReasonable(left.get(), right.get(), blockSize),
                       label + ": finite output at " +
                           std::to_string(static_cast<int>(sampleRate)) + " Hz / " +
                           std::to_string(blockSize) + " frames");
                ++callbacksExercised;
            }
        }

        processor->resetPlaybackState();
        fillRepresentativeSignal(left.get(), right.get(), 257, 48000.0);
        ProcessContext warmContext(*scratch);
        warmContext.sampleRate = 48000.0;
        warmContext.bpm = 120;
        warmContext.notes = &note;
        warmContext.noteCount = 1;
        warmContext.numFrames = 257;
        warmContext.modulatedParams = &node.params;
        AudioBlock warmBlock{left.get(), right.get(), 257};
        processor->process(warmBlock, warmContext);

        fillRepresentativeSignal(left.get(), right.get(), 257, 48000.0);
        allocation_audit::count = 0;
        allocation_audit::enabled = true;
        processor->process(warmBlock, warmContext);
        allocation_audit::enabled = false;
        if (allocation_audit::count != 0) {
            std::cerr << "Allocation count for " << label << ": "
                      << allocation_audit::count << '\n';
        }
        expect(allocation_audit::count == 0,
               label + ": warmed callback performs no heap allocations");
        expect(finiteAndReasonable(left.get(), right.get(), 257),
               label + ": finite output after reset and warmup");
    }

    std::cout << "Device correctness matrix: " << knownTypes.size()
              << " registered types, " << processorsExercised
              << " processors, " << callbacksExercised << " callbacks, "
              << failures << " failures\n";
    return failures == 0 ? 0 : 1;
}
