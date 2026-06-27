#include "audioapp/snapshot/SnapshotDelta.hpp"

#include <juce_core/juce_core.h>

namespace audioapp::snapshot {

std::string SnapshotDelta::toJson() const {
    if (fullRefresh) {
        auto* root = new juce::DynamicObject();
        auto* delta = new juce::DynamicObject();
        delta->setProperty("fullRefresh", true);
        delta->setProperty("fullSnapshot", fullSnapshot);
        root->setProperty("delta", juce::var(delta));
        root->setProperty("ok", true);
        return juce::JSON::toString(juce::var(root), false).toStdString();
    }

    auto* root = new juce::DynamicObject();
    auto* delta = new juce::DynamicObject();
    juce::Array<juce::var> tracksArr;

    for (const auto& td : tracks) {
        auto* trackObj = new juce::DynamicObject();
        trackObj->setProperty("trackId", juce::String(td.trackId));

        juce::Array<juce::var> devicesArr;
        for (const auto& dd : td.devices) {
            auto* devObj = new juce::DynamicObject();
            devObj->setProperty("deviceId", juce::String(dd.deviceId));

            juce::Array<juce::var> paramsArr;
            for (const auto& pd : dd.params) {
                auto* paramObj = new juce::DynamicObject();
                paramObj->setProperty("paramId", juce::String(pd.paramId));
                paramObj->setProperty("newValue", static_cast<double>(pd.newValue));
                paramsArr.add(juce::var(paramObj));
            }
            devObj->setProperty("params", juce::var(paramsArr));

            if (dd.deviceAdded) devObj->setProperty("deviceAdded", true);
            if (dd.deviceRemoved) devObj->setProperty("deviceRemoved", true);

            devicesArr.add(juce::var(devObj));
        }
        trackObj->setProperty("devices", juce::var(devicesArr));

        if (td.trackAdded) trackObj->setProperty("trackAdded", true);
        if (td.trackRemoved) trackObj->setProperty("trackRemoved", true);
        if (td.trackSelected) trackObj->setProperty("trackSelected", true);

        tracksArr.add(juce::var(trackObj));
    }

    delta->setProperty("tracks", juce::var(tracksArr));

    // Modulator deltas
    juce::Array<juce::var> modsArr;
    for (const auto& md : modulators) {
        auto* modObj = new juce::DynamicObject();
        modObj->setProperty("lfoId", md.lfoId);

        juce::Array<juce::var> paramsArr;
        for (const auto& pd : md.params) {
            auto* paramObj = new juce::DynamicObject();
            paramObj->setProperty("param", juce::String(pd.param));
            paramObj->setProperty("newValue", static_cast<double>(pd.newValue));
            paramsArr.add(juce::var(paramObj));
        }
        modObj->setProperty("params", juce::var(paramsArr));

        if (md.modulatorAdded) modObj->setProperty("modulatorAdded", true);
        if (md.modulatorRemoved) modObj->setProperty("modulatorRemoved", true);

        modsArr.add(juce::var(modObj));
    }
    delta->setProperty("modulators", juce::var(modsArr));

    // Transport delta
    if (transport.has_value()) {
        auto* tObj = new juce::DynamicObject();
        const auto& t = transport.value();
        if (t.bpmChanged) {
            tObj->setProperty("bpmChanged", true);
            tObj->setProperty("newBpm", t.newBpm);
        }
        if (t.playingChanged) {
            tObj->setProperty("playingChanged", true);
            tObj->setProperty("newPlaying", t.newPlaying);
        }
        if (t.loopEnabledChanged) {
            tObj->setProperty("loopEnabledChanged", true);
            tObj->setProperty("newLoopEnabled", t.newLoopEnabled);
        }
        if (t.loopStartChanged) {
            tObj->setProperty("loopRegionStartChanged", true);
            tObj->setProperty("newLoopRegionStart", t.newLoopStart);
        }
        if (t.loopEndChanged) {
            tObj->setProperty("loopRegionEndChanged", true);
            tObj->setProperty("newLoopRegionEnd", t.newLoopEnd);
        }
        if (t.playheadChanged) {
            tObj->setProperty("playheadChanged", true);
            tObj->setProperty("newPlayhead", t.newPlayhead);
        }
        if (t.recordArmedChanged) {
            tObj->setProperty("recordArmedChanged", true);
            tObj->setProperty("newRecordArmed", t.newRecordArmed);
        }
        delta->setProperty("transport", juce::var(tObj));
    }

    root->setProperty("delta", juce::var(delta));
    root->setProperty("ok", true);
    return juce::JSON::toString(juce::var(root), false).toStdString();
}

SnapshotDelta SnapshotDelta::fullRefreshDelta(juce::var snapshot) {
    SnapshotDelta d;
    d.fullRefresh = true;
    d.fullSnapshot = std::move(snapshot);
    return d;
}

} // namespace audioapp::snapshot