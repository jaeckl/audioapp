#include "audioapp/EngineHost.hpp"

#include <juce_core/juce_core.h>
#include <cstdio>
#include <cstring>
#include <crtdbg.h>

static void invalidParamHandler(const wchar_t* expr, const wchar_t* func, const wchar_t* file, unsigned int line, uintptr_t)
{
    std::fprintf(stderr, "\nINVALID PARAM: expr=%S func=%S file=%S line=%u\n", expr, func, file, line);
    fflush(stderr);
}

int main(int argc, char** argv)
{
    _CrtSetReportMode(_CRT_ASSERT, _CRTDBG_MODE_FILE);
    _CrtSetReportFile(_CRT_ASSERT, _CRTDBG_FILE_STDERR);
    _CrtSetReportMode(_CRT_WARN, _CRTDBG_MODE_FILE);
    _CrtSetReportFile(_CRT_WARN, _CRTDBG_FILE_STDERR);
    _CrtSetReportMode(_CRT_ERROR, _CRTDBG_MODE_FILE);
    _CrtSetReportFile(_CRT_ERROR, _CRTDBG_FILE_STDERR);
    _set_invalid_parameter_handler(invalidParamHandler);

    bool enableAudioOutput = false;
    const char* filter = nullptr;
    for (int i = 1; i < argc; ++i) {
        if (std::strcmp(argv[i], "--audio-output") == 0) {
            enableAudioOutput = true;
        } else if (std::strcmp(argv[i], "--help") == 0) {
            std::fprintf(stderr,
                         "Usage: audioapp_juce_tests [--audio-output] [test-name-filter]\n"
                         "Physical audio output is disabled by default.\n");
            return 0;
        } else if (argv[i][0] == '-') {
            std::fprintf(stderr, "Unknown option: %s\n", argv[i]);
            return 2;
        } else if (filter == nullptr) {
            filter = argv[i];
        } else {
            std::fprintf(stderr, "Only one test-name filter may be specified.\n");
            return 2;
        }
    }

    audioapp::EngineHost::setAudioOutputEnabled(enableAudioOutput);
    std::fprintf(stderr, "Physical audio output: %s%s\n",
                 enableAudioOutput ? "enabled" : "disabled",
                 enableAudioOutput ? "" : " (pass --audio-output to enable)");

    const auto& allTests = juce::UnitTest::getAllTests();

    for (auto* t : allTests) {
        if (filter && std::strstr(t->getName().toRawUTF8(), filter) == nullptr)
            continue;

        std::fprintf(stderr, "RUNNING TEST RUNNER FOR: %s\n", t->getName().toRawUTF8());
        fflush(stderr);

        juce::UnitTestRunner runner;
        runner.setAssertOnFailure(false);
        runner.setPassesAreLogged(true);
        runner.runTests({t});

        int failures = 0;
        for (int i = 0; i < runner.getNumResults(); ++i) {
            failures += runner.getResult(i)->failures;
            const auto* result = runner.getResult(i);
            for (int f = 0; f < result->failures; ++f) {
                std::fprintf(stderr, "  FAIL MSG: %s\n",
                    result->messages[f].toRawUTF8());
            }
        }
        std::fprintf(stderr, "%s: %d failures\n\n", t->getName().toRawUTF8(), failures);
        fflush(stderr);
    }
    return 0;
}
