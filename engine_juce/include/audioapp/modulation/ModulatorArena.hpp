#pragma once

#include <cstddef>
#include <cstdint>
#include <new>
#include <type_traits>

#include "audioapp/modulation/IModulator.hpp"

namespace audioapp {

/// Maximum size of any single Modulator subclass.
static constexpr size_t kMaxModulatorSize = 1024;
/// Maximum alignment for modulator storage.
static constexpr size_t kModulatorAlignment = alignof(std::max_align_t);
/// Maximum number of modulators per project.
static constexpr int kMaxModulators = 16;

/// Fixed-size arena for placement-new construction of IModulator instances.
/// Used on the control thread to build modulators, atomically published to audio thread.
class ModulatorArena {
public:
    ModulatorArena() noexcept = default;

    template<typename T, typename... Args>
    T* emplace(Args&&... args) noexcept {
        static_assert(sizeof(T) <= kMaxModulatorSize,
                      "Modulator subclass exceeds kMaxModulatorSize");
        static_assert(std::is_base_of_v<IModulator, T>,
                      "T must derive from IModulator");
        if (size_ >= kMaxModulators) return nullptr;
        void* ptr = storage_ + size_ * kMaxModulatorSize;
        auto* mod = ::new (ptr) T(std::forward<Args>(args)...);
        ++size_;
        return mod;
    }

    IModulator* get(int index) const noexcept {
        if (index < 0 || index >= size_) return nullptr;
        return reinterpret_cast<IModulator*>(
            const_cast<char*>(storage_) + index * kMaxModulatorSize);
    }

    int size() const noexcept { return size_; }
    void reset() noexcept { size_ = 0; }

private:
    alignas(kModulatorAlignment) char storage_[kMaxModulators * kMaxModulatorSize]{};
    int size_ = 0;
};

} // namespace audioapp