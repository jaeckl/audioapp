#pragma once

#include <string>

namespace audioapp {

/// Non-realtime engine host stub. Audio I/O wired in Milestone 01.
class EngineHost {
public:
    EngineHost() = default;

    std::string ping() const;
    void setPlaying(bool shouldPlay);
    bool isPlaying() const noexcept { return playing_; }

private:
    bool playing_ = false;
};

} // namespace audioapp
