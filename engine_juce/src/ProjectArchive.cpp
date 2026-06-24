#include "audioapp/ProjectArchive.hpp"

#include "audioapp/ProjectJson.hpp"

#include <array>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <vector>
#include <cstdio>

namespace audioapp {
namespace {

constexpr uint32_t kZipLocalFileHeaderSignature = 0x04034b50;
constexpr uint32_t kZipCentralDirectorySignature = 0x02014b50;
constexpr uint32_t kZipEndOfCentralDirectorySignature = 0x06054b50;
constexpr uint16_t kZipCompressionStored = 0;

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
    writeU16(archive, 20); // version needed to extract
    writeU16(archive, kZipCompressionStored);
    writeU16(archive, 0); // mod time
    writeU16(archive, 0); // mod date
    writeU32(archive, crc);
    writeU32(archive, size);
    writeU32(archive, size);
    writeU16(archive, static_cast<uint16_t>(name.size()));
    writeU16(archive, 0); // extra length
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
    writeU16(central, 20); // version made by
    writeU16(central, 20); // version needed
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

std::vector<uint8_t> buildProjectArchiveBytes(const std::string& projectJson) {
    const std::array<ZipEntry, 3> entries = {
        ZipEntry{kProjectJsonEntryPath, projectJson, false},
        ZipEntry{"assets/samples/", {}, true},
        ZipEntry{"metadata/", {}, true},
    };

    std::vector<uint8_t> archive;
    std::vector<uint8_t> central;
    std::vector<uint32_t> localOffsets;
    archive.reserve(projectJson.size() + 512);
    central.reserve(256);

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
    writeU16(archive, 0); // disk number
    writeU16(archive, 0); // central dir disk
    writeU16(archive, static_cast<uint16_t>(entries.size()));
    writeU16(archive, static_cast<uint16_t>(entries.size()));
    writeU32(archive, centralSize);
    writeU32(archive, centralOffset);
    writeU16(archive, 0); // comment length

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

std::string extractProjectJsonFromArchiveBytes(const std::vector<uint8_t>& archive) {
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
        pos += 2; // version
        if (!readU16(archive, pos, compression)) {
            return {};
        }
        pos += 8; // time, date, crc
        if (!readU32(archive, pos, compressedSize)) {
            return {};
        }
        pos += 4; // uncompressed size
        if (!readU16(archive, pos, nameLength) || !readU16(archive, pos, extraLength)) {
            return {};
        }
        if (pos + nameLength > archive.size()) {
            return {};
        }
        const std::string name(reinterpret_cast<const char*>(&archive[pos]), nameLength);
        pos += nameLength + extraLength;
        if (compression != kZipCompressionStored) {
            pos += compressedSize;
            continue;
        }
        if (pos + compressedSize > archive.size()) {
            return {};
        }
        if (name == kProjectJsonEntryPath) {
            return std::string(reinterpret_cast<const char*>(&archive[pos]), compressedSize);
        }
        pos += compressedSize;
    }
    return {};
}

std::vector<uint8_t> readAllBytes(const std::filesystem::path& path) {
    std::ifstream input(path, std::ios::binary);
    return std::vector<uint8_t>((std::istreambuf_iterator<char>(input)), std::istreambuf_iterator<char>());
}

bool writeAllBytes(const std::filesystem::path& path, const std::vector<uint8_t>& bytes) {
    std::ofstream output(path, std::ios::binary);
    if (!output.is_open()) {
        return false;
    }
    output.write(reinterpret_cast<const char*>(bytes.data()), static_cast<std::streamsize>(bytes.size()));
    return output.good();
}

} // namespace

bool saveProjectToArchive(const ProjectEngine& engine, const std::string& archivePath) {
    if (archivePath.empty()) {
        return false;
    }
    const auto fileData = engine.toProjectFileData();
    const std::string json = projectFileToJson(fileData, engine.deviceRegistry(),
                                                 engine.modulatorTypes());
    const auto bytes = buildProjectArchiveBytes(json);
    const bool result = writeAllBytes(std::filesystem::path(archivePath), bytes);
    return result;
}

bool loadProjectFromArchive(ProjectEngine& engine, const std::string& archivePath) {
    if (archivePath.empty()) {
        return false;
    }
    const auto bytes = readAllBytes(std::filesystem::path(archivePath));
    if (bytes.empty()) {
        return false;
    }
    const std::string json = extractProjectJsonFromArchiveBytes(bytes);
    if (json.empty()) {
        return false;
    }
    ProjectFileData data;
    if (!parseProjectFileJson(json, data, engine.deviceRegistry(), engine.modulatorTypes())) {
        return false;
    }
    return engine.loadFromProjectFileData(data);
}

} // namespace audioapp