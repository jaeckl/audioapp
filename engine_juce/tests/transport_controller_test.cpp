#include "audioapp/transport/TransportController.hpp"

#include <cmath>
#include <cstdlib>

int main() {
    audioapp::TransportController transport;

    if (transport.setBpm(30) || !transport.setBpm(120) || transport.setBpm(400)) {
        return EXIT_FAILURE;
    }
    if (transport.bpm() != 120) {
        return EXIT_FAILURE;
    }

    if (transport.setLoopLengthBeats(0.5) || !transport.setLoopLengthBeats(4.0)) {
        return EXIT_FAILURE;
    }

    transport.setLoopEnabled(true);
    transport.setPlaying(true);
    transport.setPlayheadBeats(3.5);
    transport.advancePlayhead(48000, 48000.0);
    if (std::abs(transport.playheadBeats() - 1.5) > 0.001) {
        return EXIT_FAILURE;
    }

    if (!transport.setLoopRegion(4.0, 8.0)) {
        return EXIT_FAILURE;
    }
    transport.setPlayheadBeats(7.5);
    transport.advancePlayhead(48000, 48000.0);
    if (std::abs(transport.playheadBeats() - 4.5) > 0.001) {
        return EXIT_FAILURE;
    }

    transport.reset();
    if (transport.isPlaying() || transport.playheadBeats() != 0.0 || transport.bpm() != 120) {
        return EXIT_FAILURE;
    }

    transport.setPlaying(true);
    transport.setPlayheadBeats(2.0);
    transport.setLoopEnabled(false);
    transport.advancePlayhead(24000, 48000.0);
    if (std::abs(transport.playheadBeats() - 3.0) > 0.001) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
