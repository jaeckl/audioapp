#include "audioapp/EngineHost.hpp"

namespace audioapp {

std::string EngineHost::ping() const {
    return "pong";
}

void EngineHost::setPlaying(bool shouldPlay) {
    playing_ = shouldPlay;
}

} // namespace audioapp
