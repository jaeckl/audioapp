#include "audioapp/ProjectArchive.hpp"

#include "audioapp/ProjectJson.hpp"
#include "audioapp/TrackFreeze.hpp"
#include "audioapp/TrackFreezeAssetStore.hpp"

#include <juce_core/juce_core.h>

#include <array>
#include <cstdint>
#include <cstring>
#include <unordered_map>
#include <vector>

namespace audioapp {
namespace {

constexpr uint32_t kZipLocalFileHeaderSignature = 0x04034b50;
constexpr uint32_t kZipCentralDirectorySignature = 0x02014b50;
constexpr uint32_t kZipEndOfCentralDirectorySignature = 0x06054b50;
constexpr uint16_t kZipCompressionStored = 0;
constexpr const char* kFreezeAssetsDir = "assets/freeze/";

uint32_t crc32Update(uint32_t crc, uint8_t byte) {
    crc ^= byte;
    for (int i = 0; i < 8; ++i) {
        const uint32_t mask = -(crc & 1u);
        crc = (crc >> 1) ^ (0xEDB88320u & mask);
    }
    return crc;
}

uint32_t crc32(const std::string& data) {
    uint32_t crc = 0xFFFFFFFFu;
    for (unsigned char c : data) {
        crc = crc32Update(crc, c);
    }
    return crc ^ 0xFFFFFFFFu;
}

void writeU16(std::vector<uint8_t>& out, uint16_t value) {
    out.push_back(static_cast<uint8_t>(value & 0xFF));
    out.push_back(static_cast<uint8_t>((value >> 8) & 0xFF));
}

void writeU32(std::vector<uint8_t>& out, uint32_t value) {
    out.push_back(static_cast<uint8_t>(value & 0xFF));
    out.push_back(static_cast<uint8_t>((value >> 8) & 0xFF));
    out.push_back(static_cast<uint8_t>((value >> 16) & 0xFF));
    out.push_back(static_cast<uint8_t>((value >> 24) & 0xFF));
}

struct ZipEntry {
    std::string name;
    std::string data;
    bool isDirectory = false;
};

void appendLocalEntry(std::vector<uint8_t>& archive, const ZipEntry& entry) {
    const auto& name = entry.name;
    const auto& data = entry.data;
    const uint32_t crc = entry.isDirectory ? 0 : crc32(data);
    const uint32_t size = entry.isDirectory ? 0 : static_cast<uint32_t>(data.size());

    writeU32(archive, kZipLocalFileHeaderSignature);
    writeU16(archive, 20);
    writeU16(archive, kZipCompressionStored);
    writeU16(archive, 0);
    writeU16(archive, 0);
    writeU32(archive, crc);
    writeU32(archive, size);
    writeU32(archive, size);
    writeU16(archive, static_cast<uint16_t>(name.size()));
    writeU16(archive, 0);
    archive.insert(archive.end(), name.begin(), name.end());
    archive.insert(archive.end(), data.begin(), data.end());
}

void appendCentralEntry(std::vector<uint8_t>& central,
                         const ZipEntry& entry,
                         uint32_t localHeaderOffset) {
    const auto& name = entry.name;
    const auto& data = entry.data;
    const uint32_t crc = entry.isDirectory ? 0 : crc32(data);
    const uint32_t size = entry.isDirectory ? 0 : static_cast<uint32_t>(data.size());

    writeU32(central, kZipCentralDirectorySignature);
    writeU16(central, 20);
    writeU16(central, 20);
    writeU16(central, kZipCompressionStored);
    writeU16(central, 0);
    writeU16(central, 0);
    writeU32(central, crc);
    writeU32(central, size);
    writeU32(central, size);
    writeU16(central, static_cast<uint16_t>(name.size()));
    writeU16(central, 0);
    writeU16(central, 0);
    writeU16(central, 0);
    writeU16(central, 0);
    writeU32(central, 0);
    writeU32(central, localHeaderOffset);
    central.insert(central.end(), name.begin(), name.end());
}

std::vector<uint8_t> buildArchiveBytes(const std::vector<ZipEntry>& entries) {
    std::vector<uint8_t> archive;
    std::vector<uint8_t> central;
    std::vector<uint32_t> localOffsets;
    archive.reserve(1024);
    central.reserve(512);

    for (const auto& entry : entries) {
        localOffsets.push_back(static_cast<uint32_t>(archive.size()));
        appendLocalEntry(archive, entry);
    }

    for (size_t i = 0; i < entries.size(); ++i) {
        appendCentralEntry(central, entries[i], localOffsets[i]);
    }

    const uint32_t centralOffset = static_cast<uint32_t>(archive.size());
    archive.insert(archive.end(), central.begin(), central.end());
    const uint32_t centralSize = static_cast<uint32_t>(central.size());

    writeU32(archive, kZipEndOfCentralDirectorySignature);
    writeU16(archive, 0);
    writeU16(archive, 0);
    writeU16(archive, static_cast<uint16_t>(entries.size()));
    writeU16(archive, static_cast<uint16_t>(entries.size()));
    writeU32(archive, centralSize);
    writeU32(archive, centralOffset);
    writeU16(archive, 0);

    return archive;
}

bool readU16(const std::vector<uint8_t>& data, size_t& pos, uint16_t& out) {
    if (pos + 2 > data.size()) {
        return false;
    }
    out = static_cast<uint16_t>(data[pos] | (data[pos + 1] << 8));
    pos += 2;
    return true;
}

bool readU32(const std::vector<uint8_t>& data, size_t& pos, uint32_t& out) {
    if (pos + 4 > data.size()) {
        return false;
    }
    out = static_cast<uint32_t>(data[pos] | (data[pos + 1] << 8) | (data[pos + 2] << 16) |
                                (data[pos + 3] << 24));
    pos += 4;
    return true;
}

std::unordered_map<std::string, std::string> extractArchiveEntries(
    const std::vector<uint8_t>& archive) {
    std::unordered_map<std::string, std::string> entries;
    size_t pos = 0;
    while (pos + 30 <= archive.size()) {
        uint32_t signature = 0;
        if (!readU32(archive, pos, signature) || signature != kZipLocalFileHeaderSignature) {
            break;
        }
        uint16_t compression = 0;
        uint16_t nameLength = 0;
        uint16_t extraLength = 0;
        uint32_t compressedSize = 0;
        pos += 2;
        if (!readU16(archive, pos, compression)) {
            break;
        }
        pos += 8;
        if (!readU32(archive, pos, compressedSize)) {
            break;
        }
        pos += 4;
        if (!readU16(archive, pos, nameLength) || !readU16(archive, pos, extraLength)) {
            break;
        }
        if (pos + nameLength > archive.size()) {
            break;
        }
        const std::string name(reinterpret_cast<const char*>(&archive[pos]), nameLength);
        pos += nameLength + extraLength;
        if (compression != kZipCompressionStored) {
            pos += compressedSize;
            continue;
        }
        if (pos + compressedSize > archive.size()) {
            break;
        }
        if (!name.empty() && name.back() != '/') {
            entries[name] = std::string(reinterpret_cast<const char*>(&archive[pos]), compressedSize);
        }
        pos += compressedSize;
    }
    return entries;
}

std::vector<uint8_t> readAllBytes(const juce::File& file) {
    juce::FileInputStream input(file);
    if (!input.openedOk()) {
        return {};
    }
    const auto size = static_cast<size_t>(input.getTotalLength());
    std::vector<uint8_t> bytes(size);
    if (size > 0) {
        input.read(bytes.data(), static_cast<int>(size));
    }
    return bytes;
}

bool writeAllBytes(const juce::File& file, const std::vector<uint8_t>& bytes) {
    juce::FileOutputStream output(file);
    if (!output.openedOk()) {
        return false;
    }
    const bool ok = output.write(bytes.data(), static_cast<int>(bytes.size()));
    output.flush();
    return ok;
}

std::vector<ZipEntry> buildProjectArchiveEntries(const std::string& projectJson,
                                                 const TrackFreezeAssetStore& freezeAssets) {
    std::vector<ZipEntry> entries;
    entries.push_back(ZipEntry{kProjectJsonEntryPath, projectJson, false});
    entries.push_back(ZipEntry{"assets/samples/", {}, true});
    entries.push_back(ZipEntry{kFreezeAssetsDir, {}, true});
    entries.push_back(ZipEntry{"metadata/", {}, true});

    for (const auto& asset : freezeAssets.listAssets()) {
        const auto wavBytes = encodeFreezeAssetWav(asset);
        if (wavBytes.empty()) {
            continue;
        }
        ZipEntry entry;
        entry.name = freezeWavArchivePath(asset.id);
        entry.data.assign(reinterpret_cast<const char*>(wavBytes.data()),
                          reinterpret_cast<const char*>(wavBytes.data() + wavBytes.size()));
        entries.push_back(std::move(entry));
    }

    return entries;
}

bool loadFreezeAssetsFromArchiveEntries(const std::unordered_map<std::string, std::string>& entries,
                                        TrackFreezeAssetStore& freezeAssets) {
    bool loadedAny = false;
    for (const auto& [name, data] : entries) {
        if (name.rfind(kFreezeAssetsDir, 0) != 0 || name.size() <= 5) {
            continue;
        }
        if (name.size() < 5 || name.substr(name.size() - 4) != ".wav") {
            continue;
        }
        const std::string assetId = name.substr(std::strlen(kFreezeAssetsDir),
                                                name.size() - std::strlen(kFreezeAssetsDir) - 4);
        if (assetId.empty()) {
            continue;
        }
        const std::vector<uint8_t> wavBytes(data.begin(), data.end());
        FreezeAsset asset;
        if (!loadFreezeAssetFromWavBytes(assetId, wavBytes, asset)) {
            continue;
        }
        if (!freezeAssets.upsert(std::move(asset))) {
            continue;
        }
        loadedAny = true;
    }
    return loadedAny;
}

} // namespace

std::vector<uint8_t> buildProjectArchiveBytes(const ProjectEngine& engine,
                                              const TrackFreezeAssetStore& freezeAssets) {
    const auto fileData = engine.toProjectFileData();
    const std::string json = projectFileToJson(fileData, engine.deviceRegistry(),
                                               engine.modulatorTypes());
    return buildArchiveBytes(buildProjectArchiveEntries(json, freezeAssets));
}

bool loadProjectFromArchiveBytes(ProjectEngine& engine,
                                 TrackFreezeAssetStore& freezeAssets,
                                 const std::vector<uint8_t>& archiveBytes) {
    if (archiveBytes.empty()) {
        return false;
    }
    const auto entries = extractArchiveEntries(archiveBytes);
    const auto jsonIt = entries.find(kProjectJsonEntryPath);
    if (jsonIt == entries.end() || jsonIt->second.empty()) {
        return false;
    }

    freezeAssets.clear();
    loadFreezeAssetsFromArchiveEntries(entries, freezeAssets);

    ProjectFileData data;
    if (!parseProjectFileJson(jsonIt->second, data, engine.deviceRegistry(), engine.modulatorTypes())) {
        return false;
    }
    if (!engine.loadFromProjectFileData(data)) {
        return false;
    }
    engine.ensureFrozenAssets(freezeAssets);
    return true;
}

bool saveProjectToArchive(const ProjectEngine& engine,
                          const TrackFreezeAssetStore& freezeAssets,
                          const std::string& archivePath) {
    if (archivePath.empty()) {
        return false;
    }
    const auto bytes = buildProjectArchiveBytes(engine, freezeAssets);
    return writeAllBytes(juce::File(archivePath), bytes);
}

bool loadProjectFromArchive(ProjectEngine& engine,
                            TrackFreezeAssetStore& freezeAssets,
                            const std::string& archivePath) {
    if (archivePath.empty()) {
        return false;
    }
    const auto bytes = readAllBytes(juce::File(archivePath));
    return loadProjectFromArchiveBytes(engine, freezeAssets, bytes);
}

} // namespace audioapp
