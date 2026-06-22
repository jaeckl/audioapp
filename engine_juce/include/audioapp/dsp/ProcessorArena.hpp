#pragma once

#include <cstddef>
#include <cstdint>
#include <new>
#include <type_traits>

#include "audioapp/DeviceChain.hpp"
#include "audioapp/dsp/DeviceProcessor.hpp"

namespace audioapp {

/// Worst-case processor object size (for arena sizing).
/// Must be >= sizeof(largest concrete processor subclass).
static constexpr size_t kMaxProcessorSize = 65536;
static constexpr size_t kProcessorAlignment = alignof(std::max_align_t);
static constexpr size_t kMaxDeviceStorage = kMaxDevicesPerTrack * kMaxProcessorSize;

class ProcessorArena {
public:
    ProcessorArena() noexcept = default;

    template<typename T, typename... Args>
    T* emplace(Args&&... args) noexcept {
        static_assert(sizeof(T) <= kMaxProcessorSize,
                      "Processor subclass exceeds kMaxProcessorSize");
        static_assert(std::is_base_of_v<DeviceProcessor, T>,
                      "T must derive from DeviceProcessor");
        if (size_ >= kMaxDevicesPerTrack) return nullptr;
        void* ptr = storage_ + size_ * kMaxProcessorSize;
        auto* proc = ::new (ptr) T(std::forward<Args>(args)...);
        ++size_;
        return proc;
    }

    DeviceProcessor* get(int index) const noexcept {
        if (index < 0 || index >= size_) return nullptr;
        return reinterpret_cast<DeviceProcessor*>(
            const_cast<char*>(storage_) + index * kMaxProcessorSize);
    }

    int size() const noexcept { return size_; }

    void reset() noexcept { size_ = 0; }

private:
    alignas(kProcessorAlignment) char storage_[kMaxDeviceStorage]{};
    int size_ = 0;
};

} // namespace audioapp