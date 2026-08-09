/// Unit tests for flattened freeze bake-end indexing (model vs playback space).

#include "audioapp/TrackFreeze.hpp"
#include "audioapp/RoutingDevices.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/effects/DuckerParams.hpp"

#include <iostream>
#include <memory>
#include <string>
#include <vector>

namespace {

int failures = 0;

void expect(bool cond, const char* msg) {
    if (cond) {
        return;
    }
    ++failures;
    std::cerr << "FAIL: " << msg << '\n';
}

audioapp::DeviceSlot makeSlot(const std::string& id, const char* typeId) {
    audioapp::DeviceSlot slot;
    slot.id = id;
    slot.config.typeId = typeId;
    return slot;
}

std::shared_ptr<audioapp::DeviceSlot> makeSharedSlot(const std::string& id, const char* typeId) {
    return std::make_shared<audioapp::DeviceSlot>(makeSlot(id, typeId));
}

} // namespace

int main() {
    using namespace audioapp;
    using namespace audioapp::device_types;

    // Plain [osc, reverb, gain] — flatten == model.
    {
        Track track;
        track.id = "A";
        track.devices = {
            makeSlot("A.osc", kOscillator),
            makeSlot("A.rev", kReverb),
            makeSlot("A.gain", kTrackGain),
        };
        const std::vector<Track> all{track};
        expect(computeFreezeBakeEndIndex(track, all) == 2, "plain chain bakeEnd=2");
        expect(flattenedPlaybackSlotCount(track.devices[0]) == 1, "osc flat slots=1");
    }

    // Synth + noteFx + audioFx: model [synth, gain] → flat [note, synth, audio, gain].
    {
        Track track;
        track.id = "A";
        auto synth = makeSlot("A.osc", kOscillator);
        synth.noteFxDevices.push_back(makeSharedSlot("A.osc.mdelay", kMidiDelay));
        synth.audioFxDevices.push_back(makeSharedSlot("A.osc.rev", kReverb));
        track.devices = {synth, makeSlot("A.gain", kTrackGain)};
        const std::vector<Track> all{track};
        expect(flattenedPlaybackSlotCount(track.devices[0]) == 3, "synth nest flat slots=3");
        expect(computeFreezeBakeEndIndex(track, all) == 3,
               "nested synth bakeEnd=3 (note+synth+audio before gain)");
        expect(freezeBakeCoversDeviceId(track, 3, "A.osc.mdelay"), "covers noteFx");
        expect(freezeBakeCoversDeviceId(track, 3, "A.osc"), "covers synth");
        expect(freezeBakeCoversDeviceId(track, 3, "A.osc.rev"), "covers audioFx");
        expect(!freezeBakeCoversDeviceId(track, 3, "A.gain"), "excludes gain");
    }

    // Sidechain ducker at model index 1: [osc, duck, gain] → bakeEnd=1.
    {
        Track track;
        track.id = "A";
        auto duck = makeSlot("A.duck", kDucker);
        DuckerModel model;
        model.sidechainSourceId = "B.osc";
        duck.config.instance = model;
        track.devices = {
            makeSlot("A.osc", kOscillator),
            duck,
            makeSlot("A.gain", kTrackGain),
        };
        const std::vector<Track> all{track};
        expect(computeFreezeBakeEndIndex(track, all) == 1, "sidechain ducker bakeEnd=1");
    }

    // Bypassed sidechain ducker still barriers.
    {
        Track track;
        track.id = "A";
        auto duck = makeSlot("A.duck", kDucker);
        duck.config.bypassed = true;
        DuckerModel model;
        model.sidechainSourceId = "B.osc";
        duck.config.instance = model;
        track.devices = {
            makeSlot("A.osc", kOscillator),
            duck,
            makeSlot("A.gain", kTrackGain),
        };
        const std::vector<Track> all{track};
        expect(computeFreezeBakeEndIndex(track, all) == 1,
               "bypassed sidechain ducker still bakeEnd=1");
    }

    // Tapped synth with noteFx: must not bake noteFx alone (return 0).
    {
        Track a;
        a.id = "A";
        auto synth = makeSlot("A.osc", kOscillator);
        synth.noteFxDevices.push_back(makeSharedSlot("A.osc.mdelay", kMidiDelay));
        a.devices = {synth, makeSlot("A.rev", kReverb), makeSlot("A.gain", kTrackGain)};

        Track b;
        b.id = "B";
        auto recv = makeSlot("B.recv", kAudioReceiver);
        RoutingModel routing;
        routing.sourceId = "A.osc";
        recv.config.instance = routing;
        b.devices = {recv, makeSlot("B.gain", kTrackGain)};

        const std::vector<Track> all{a, b};
        expect(computeFreezeBakeEndIndex(a, all) == 0,
               "tapped nested synth bakeEnd=0 (whole group live)");
    }

    if (failures == 0) {
        std::cout << "freeze_bake_end_index_test: ok\n";
        return 0;
    }
    std::cerr << "freeze_bake_end_index_test: " << failures << " failure(s)\n";
    return 1;
}
