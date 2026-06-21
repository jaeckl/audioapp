#include <juce_core/juce_core.h>
#include <cstdio>
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

    const char* filter = argc > 1 ? argv[1] : nullptr;
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
            // Print failure messages
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