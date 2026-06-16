#include "audioapp/SampleBank.hpp"

#include <cstdlib>

int main() {
    audioapp::SampleBank bank;
    bank.registerBundledDefaults();
    const auto samples = bank.listSamples();
    if (samples.size() < 4) {
        return EXIT_FAILURE;
    }
    if (bank.findSample("sample_kick") == nullptr) {
        return EXIT_FAILURE;
    }
    if (bank.beatsForSample("sample_kick", 120) <= 0.0) {
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}
