#pragma once

#include <string>

namespace audioapp {

class ProjectEngine;

/// Desktop / test I/O: `.audioapp.zip` archive containing `project.json` + layout entries.
/// On Android, Kotlin builds/opens the same archive via SAF. See ADR-0005 / ADR-0006.
bool saveProjectToArchive(const ProjectEngine& engine, const std::string& archivePath);
bool loadProjectFromArchive(ProjectEngine& engine, const std::string& archivePath);

constexpr const char* kProjectArchiveExtension = ".audioapp.zip";
constexpr const char* kProjectJsonEntryPath = "project.json";

} // namespace audioapp
