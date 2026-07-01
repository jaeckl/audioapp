#pragma once

#include <cstdint>
#include <string>
#include <vector>

namespace audioapp {

class ProjectEngine;
class TrackFreezeAssetStore;

/// Desktop / test I/O: `.audioapp.zip` archive containing `project.json` + layout entries.
/// On Android, Kotlin builds/opens the same archive via SAF. See ADR-0005 / ADR-0006.
std::vector<uint8_t> buildProjectArchiveBytes(const ProjectEngine& engine,
                                              const TrackFreezeAssetStore& freezeAssets);
bool loadProjectFromArchiveBytes(ProjectEngine& engine,
                                 TrackFreezeAssetStore& freezeAssets,
                                 const std::vector<uint8_t>& archiveBytes);
bool saveProjectToArchive(const ProjectEngine& engine,
                          const TrackFreezeAssetStore& freezeAssets,
                          const std::string& archivePath);
bool loadProjectFromArchive(ProjectEngine& engine,
                            TrackFreezeAssetStore& freezeAssets,
                            const std::string& archivePath);

constexpr const char* kProjectArchiveExtension = ".audioapp.zip";
constexpr const char* kProjectJsonEntryPath = "project.json";

} // namespace audioapp
