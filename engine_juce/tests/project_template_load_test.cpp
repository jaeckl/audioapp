#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/EngineHost.hpp"

#include <fstream>
#include <sstream>
#include <string>
#include <vector>

class ProjectTemplateLoadTest : public juce::UnitTest {
public:
    ProjectTemplateLoadTest() : juce::UnitTest("ProjectTemplateLoad", "Project") {}

    void runTest() override {
        const std::vector<std::string> templates = {
            "app_flutter/assets/project_templates/session_mix_bus.json",
            "app_flutter/assets/project_templates/ms_mastering.json",
            "app_flutter/assets/project_templates/stereo_synth_bus.json",
            "app_flutter/assets/project_templates/beat_lab.json",
        };

        for (const auto& relativePath : templates) {
            beginTest("load " + relativePath);
            const juce::File file = juce::File::getCurrentWorkingDirectory()
                                        .getChildFile(relativePath);
            expect(file.existsAsFile(), "template file exists: " + relativePath);
            if (!file.existsAsFile()) {
                continue;
            }

            std::ifstream in(file.getFullPathName().toStdString());
            std::stringstream buffer;
            buffer << in.rdbuf();
            const std::string json = buffer.str();
            expect(!json.empty(), "template JSON is non-empty");

            audioapp::EngineHost host;
            host.createProject();
            expect(host.loadProjectFileJson(json),
                   "loadProjectFileJson succeeds for " + relativePath);

            const std::string snapshot = host.getProjectSnapshotJson();
            expect(snapshot.find("\"tracks\"") != std::string::npos,
                   "snapshot contains tracks after load");

            const float peak = host.renderOffline(0.25, 48000.0f);
            expect(std::isfinite(peak), "offline render returns finite peak");
        }

        beginTest("minimal limiter JSON installs dynamics panels");
        {
            const std::string json = R"({
              "project_format_version": 2,
              "name": "Limiter Load",
              "bpm": 120,
              "master": {
                "id": "master",
                "name": "Master",
                "gain": 0.8,
                "devices": [{
                  "id": "lim-1",
                  "type": "limiter",
                  "parameters": {
                    "limitCeiling": 0.64,
                    "limitRelease": 0.32,
                    "bypass": 0.0
                  }
                }]
              },
              "tracks": [{
                "id": "t1",
                "name": "Kick",
                "devices": [{
                  "id": "kick-1",
                  "type": "kick_generator",
                  "parameters": { "gain": 0.9, "bypass": 0.0 }
                }]
              }]
            })";

            audioapp::EngineHost host;
            host.createProject();
            expect(host.loadProjectFileJson(json),
                   "minimal limiter project loads without aborting");
            const float peak = host.renderOffline(0.1, 48000.0f);
            expect(std::isfinite(peak), "render after minimal limiter is finite");
        }
    }
};

static ProjectTemplateLoadTest projectTemplateLoadTest;
