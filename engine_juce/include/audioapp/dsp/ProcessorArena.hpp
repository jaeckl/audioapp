#pragma once

#include <cstddef>
#include <cstdint>
#include <array>
#include <algorithm>
#include <memory>
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
    explicit ProcessorArena(int maxDevices = kMaxDevicesPerTrack)
        : storage_(std::make_shared<Storage>(maxDevices)) {}

    // Snapshots may share an arena when their complete device topology and
    // playback nodes are unchanged. The Storage object owns destruction, so
    // the old audio snapshot remains valid until its reader releases it.
    ProcessorArena(const ProcessorArena&) noexcept = default;
    ProcessorArena& operator=(const ProcessorArena&) noexcept = default;
    ProcessorArena(ProcessorArena&&) noexcept = default;
    ProcessorArena& operator=(ProcessorArena&&) noexcept = default;
    ~ProcessorArena() = default;

    template<typename T, typename... Args>
    T* emplace(Args&&... args) noexcept {
        return emplaceAt<T>(storage_->size, std::forward<Args>(args)...);
    }

    template<typename T, typename... Args>
    T* emplaceAt(int index, Args&&... args) noexcept {
        static_assert(sizeof(T) <= kMaxProcessorSize,
                      "Processor subclass exceeds kMaxProcessorSize");
        static_assert(std::is_base_of_v<DeviceProcessor, T>,
                      "T must derive from DeviceProcessor");
        if (index < 0 || index >= storage_->capacity ||
            storage_->slots[index] != nullptr || index > storage_->size) {
            return nullptr;
        }
        auto slot = std::make_shared<Slot>();
        void* ptr = slot->bytes.data();
        auto* proc = ::new (ptr) T(std::forward<Args>(args)...);
        slot->destructor = [](void* object) noexcept {
            static_cast<DeviceProcessor*>(static_cast<T*>(object))->~DeviceProcessor();
        };
        storage_->slots[index] = std::move(slot);
        storage_->size = std::max(storage_->size, index + 1);
        return proc;
    }

    /// Reference one compatible processor slot from another immutable
    /// snapshot. The slot's lifetime is now shared, while both arenas retain
    /// their own device-index layout.
    bool reuseSlotAt(int destinationIndex, const ProcessorArena& source,
                     int sourceIndex) noexcept {
        if (destinationIndex < 0 || destinationIndex >= storage_->capacity ||
            sourceIndex < 0 || sourceIndex >= source.storage_->size ||
            storage_->slots[destinationIndex] != nullptr ||
            source.storage_->slots[sourceIndex] == nullptr ||
            destinationIndex > storage_->size) {
            return false;
        }
        storage_->slots[destinationIndex] = source.storage_->slots[sourceIndex];
        storage_->size = std::max(storage_->size, destinationIndex + 1);
        return true;
    }

    DeviceProcessor* get(int index) const noexcept {
        if (index < 0 || index >= storage_->size ||
            storage_->slots[index] == nullptr) return nullptr;
        return reinterpret_cast<DeviceProcessor*>(storage_->slots[index]->bytes.data());
    }

    int size() const noexcept { return storage_->size; }
    int capacity() const noexcept { return storage_->capacity; }

    bool sharesStorageWith(const ProcessorArena& other) const noexcept {
        return storage_ == other.storage_;
    }

    bool sharesSlotWith(int index, const ProcessorArena& other,
                        int otherIndex) const noexcept {
        return index >= 0 && index < storage_->size &&
               otherIndex >= 0 && otherIndex < other.storage_->size &&
               storage_->slots[index] != nullptr &&
               storage_->slots[index] == other.storage_->slots[otherIndex];
    }

    void reset() noexcept {
        // Never clear processors owned by an active snapshot. Detach instead;
        // Storage is reclaimed only after its final snapshot reference dies.
        if (storage_.use_count() != 1) {
            storage_ = std::make_shared<Storage>(storage_->capacity);
            return;
        }
        storage_->clear();
    }

private:
    using Destructor = void (*)(void*) noexcept;
    struct Slot {
        ~Slot() {
            if (destructor != nullptr) destructor(bytes.data());
        }

        std::array<std::byte, kMaxProcessorSize> bytes{};
        Destructor destructor = nullptr;
    };

    struct Storage {
        explicit Storage(int maxDevices)
            : capacity(std::clamp(maxDevices, 1, kMaxDevicesPerTrack)) {}

        void clear() noexcept { slots.fill(nullptr); size = 0; }

        int capacity = kMaxDevicesPerTrack;
        std::array<std::shared_ptr<Slot>, kMaxDevicesPerTrack> slots{};
        int size = 0;
    };

    std::shared_ptr<Storage> storage_;
};

} // namespace audioapp
