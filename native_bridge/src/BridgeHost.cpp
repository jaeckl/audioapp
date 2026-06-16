#include "audioapp/bridge/BridgeHost.hpp"

#include "audioapp/EngineHost.hpp"

namespace audioapp::bridge {

std::string BridgeHost::handleCommand(const std::string& method, const std::string& /*argumentsJson*/) {
    static EngineHost engine;

    if (method == "ping") {
        return R"({"ok":true,"message":")" + engine.ping() + R"("})";
    }
    if (method == "play") {
        playing_ = true;
        engine.setPlaying(true);
        return R"({"ok":true,"playing":true})";
    }
    if (method == "stop") {
        playing_ = false;
        engine.setPlaying(false);
        return R"({"ok":true,"playing":false})";
    }
    return R"({"ok":false,"error":"unknown_command"})";
}

} // namespace audioapp::bridge
