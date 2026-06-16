#pragma once

#include "audioapp/ProjectEngine.hpp"

#include <memory>
#include <string>

namespace audioapp {

class EngineHost {
public:
    EngineHost();
    ~EngineHost();

    EngineHost(const EngineHost&) = delete;
    EngineHost& operator=(const EngineHost&) = delete;

    std::string ping() const;
    void setPlaying(bool shouldPlay);
    bool isPlaying() const noexcept;

    void createProject();
    std::string addTrack(const std::string& name);
    bool selectTrack(const std::string& trackId);
    std::string addDeviceToTrack(const std::string& trackId, const std::string& deviceType);
    bool setDeviceParameter(const std::string& deviceId,
                            const std::string& parameterId,
                            float value);
    std::string createMidiClip(const std::string& trackId,
                               double startBeat,
                               double lengthBeats);
    bool setMidiClipNotes(const std::string& clipId, const std::vector<MidiNoteState>& notes);

    /// Desktop / tests: `.audioapp.zip` I/O via ProjectArchive.cpp (ADR-0006).
    bool saveProject(const std::string& archivePath);
    bool loadProject(const std::string& archivePath);

    /// All platforms: serialize in-memory project to `project.json` text.
    std::string getProjectFileJson() const;
    /// All platforms: restore project from `project.json` text.
    bool loadProjectFileJson(const std::string& json);

    std::string getProjectSnapshotJson() const;

    void advancePlayheadForBlock(int numFrames, double sampleRate) noexcept;
    float activeOscillatorFrequencyHz() const;

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
    ProjectEngine project_;
};

} // namespace audioapp
