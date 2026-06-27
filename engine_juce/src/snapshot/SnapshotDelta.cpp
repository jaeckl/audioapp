#include "audioapp/snapshot/SnapshotDelta.hpp"

#include <juce_core/juce_core.h>

namespace audioapp::snapshot {

/// Build an attribute name string from a bool property key.
/// Returns the key as-is (bool attributes are "1" or absent in XmlElement).
static void setBoolAttr(juce::XmlElement& elem, const char* name, bool value)
{
    if (value)
        elem.setAttribute(name, 1);
}

std::string SnapshotDelta::toXml() const
{
    if (fullRefresh)
    {
        auto delta = std::make_unique<juce::XmlElement>("delta");
        delta->setAttribute("fullRefresh", 1);
        // fullRefresh is a rare path (project load/undo) — keep the full
        // snapshot as a JSON string attribute rather than building a tree.
        delta->setAttribute("fullSnapshot",
            juce::JSON::toString(fullSnapshot, false));
        return delta->toString(juce::XmlElement::TextFormat().withoutHeader()).toStdString();
    }

    auto root = std::make_unique<juce::XmlElement>("delta");

    // ── Track deltas ──────────────────────────────────────────
    if (!tracks.empty())
    {
        auto* tracksElem = root->createNewChildElement("tracks");
        for (const auto& td : tracks)
        {
            auto* trackElem = tracksElem->createNewChildElement("track");
            trackElem->setAttribute("trackId", td.trackId);
            setBoolAttr(*trackElem, "trackAdded", td.trackAdded);
            setBoolAttr(*trackElem, "trackRemoved", td.trackRemoved);
            setBoolAttr(*trackElem, "trackSelected", td.trackSelected);

            if (!td.devices.empty())
            {
                auto* devsElem = trackElem->createNewChildElement("devices");
                for (const auto& dd : td.devices)
                {
                    auto* devElem = devsElem->createNewChildElement("device");
                    devElem->setAttribute("deviceId", dd.deviceId);
                    setBoolAttr(*devElem, "deviceAdded", dd.deviceAdded);
                    setBoolAttr(*devElem, "deviceRemoved", dd.deviceRemoved);

                    if (!dd.params.empty())
                    {
                        auto* paramsElem = devElem->createNewChildElement("params");
                        for (const auto& pd : dd.params)
                        {
                            auto* pElem = paramsElem->createNewChildElement("param");
                            pElem->setAttribute("paramId", pd.paramId);
                            pElem->setAttribute("newValue", static_cast<double>(pd.newValue));
                        }
                    }
                }
            }
        }
    }

    // ── Modulator deltas ──────────────────────────────────────
    if (!modulators.empty())
    {
        auto* modsElem = root->createNewChildElement("modulators");
        for (const auto& md : modulators)
        {
            auto* modElem = modsElem->createNewChildElement("modulator");
            modElem->setAttribute("lfoId", md.lfoId);
            setBoolAttr(*modElem, "modulatorAdded", md.modulatorAdded);
            setBoolAttr(*modElem, "modulatorRemoved", md.modulatorRemoved);

            if (!md.params.empty())
            {
                auto* paramsElem = modElem->createNewChildElement("params");
                for (const auto& pd : md.params)
                {
                    auto* pElem = paramsElem->createNewChildElement("param");
                    pElem->setAttribute("param", pd.param);
                    pElem->setAttribute("newValue", static_cast<double>(pd.newValue));
                }
            }
        }
    }

    // ── Transport delta ───────────────────────────────────────
    if (transport.has_value())
    {
        auto* tElem = root->createNewChildElement("transport");
        const auto& t = transport.value();
        if (t.bpmChanged)
        {
            tElem->setAttribute("bpmChanged", 1);
            tElem->setAttribute("newBpm", t.newBpm);
        }
        if (t.playingChanged)
        {
            tElem->setAttribute("playingChanged", 1);
            tElem->setAttribute("newPlaying", t.newPlaying ? 1 : 0);
        }
        if (t.loopEnabledChanged)
        {
            tElem->setAttribute("loopEnabledChanged", 1);
            tElem->setAttribute("newLoopEnabled", t.newLoopEnabled ? 1 : 0);
        }
        if (t.loopStartChanged)
        {
            tElem->setAttribute("loopRegionStartChanged", 1);
            tElem->setAttribute("newLoopRegionStart", t.newLoopStart);
        }
        if (t.loopEndChanged)
        {
            tElem->setAttribute("loopRegionEndChanged", 1);
            tElem->setAttribute("newLoopRegionEnd", t.newLoopEnd);
        }
        if (t.playheadChanged)
        {
            tElem->setAttribute("playheadChanged", 1);
            tElem->setAttribute("newPlayhead", t.newPlayhead);
        }
        if (t.recordArmedChanged)
        {
            tElem->setAttribute("recordArmedChanged", 1);
            tElem->setAttribute("newRecordArmed", t.newRecordArmed ? 1 : 0);
        }
    }

    return root->toString(juce::XmlElement::TextFormat().withoutHeader()).toStdString();
}

SnapshotDelta SnapshotDelta::fullRefreshDelta(juce::var snapshot) {
    SnapshotDelta d;
    d.fullRefresh = true;
    d.fullSnapshot = std::move(snapshot);
    return d;
}

} // namespace audioapp::snapshot