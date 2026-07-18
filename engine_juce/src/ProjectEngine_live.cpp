#include "audioapp/MidiClipPlayback.hpp"
#include "audioapp/ProjectEngine.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {

namespace {

double quantizeCaptureBeat(double beat, double grid = 0.25) {
    if (grid <= 0.0) {
        return beat;
    }
    return std::round(beat / grid) * grid;
}

} // namespace

bool ProjectEngine::buildLiveInstrumentForTrack(const Track& track,
                                                int pitch,
                                                LiveInstrumentSnapshot& out) const {
    PlaybackBuildContext context{sampleBank_};
    context.wavetableBank = wavetableBank_;
    uint16_t deviceIndex = 0;
    for (const auto& device : track.devices) {
        if (device.config.typeId == device_types::kDrumMachine &&
            pitch >= 0 && pitch < DrumMachineModel::kMidiNoteCount) {
            const auto& machine = std::get<DrumMachineModel>(device.config.instance);
            const auto& pad = machine.pads[static_cast<size_t>(pitch)];
            for (const auto& child : pad.devices) {
                if (child != nullptr && deviceRegistry_.buildLiveInstrument(*child, context, out)) {
                    if (out.kind == LiveInstrumentKind::Sampler) out.rootPitch = pitch;
                    out.deviceIndex = deviceIndex;
                    return true;
                }
            }
        }
        if (deviceRegistry_.buildLiveInstrument(device, context, out)) {
            out.deviceIndex = deviceIndex;
            return true;
        }
        ++deviceIndex;
    }
    return false;
}

double ProjectEngine::sampleTimeToCaptureBeat(uint64_t sampleTime) const {
    if (!captureActive_ || sampleTime < captureStartSample_) {
        return 0.0;
    }
    const double seconds =
        static_cast<double>(sampleTime - captureStartSample_) / 48000.0;
    return seconds * static_cast<double>(transport_.bpm()) / 60.0;
}

bool ProjectEngine::setRecordArmed(bool armed) {
    const juce::ScopedWriteLock lock(mutex_);
    if (armed) {
        Track* track = trackRepo_.findTrack(trackRepo_.selectedTrackId());
        if (track != nullptr && track->freeze.enabled) {
            return false;
        }
    }
    recordArmed_ = armed;
    if (!armed) {
        captureActive_ = false;
        captureEventHead_ = 0;
        captureEventCount_ = 0;
        captureTrackId_.clear();
    }
    return true;
}

bool ProjectEngine::noteOn(int pitch, float velocity) {
    const juce::ScopedWriteLock lock(mutex_);
    if (trackRepo_.selectedTrackId().empty()) {
        return false;
    }
    Track* track = trackRepo_.findTrack(trackRepo_.selectedTrackId());
    if (track == nullptr || track->freeze.enabled) {
        return false;
    }

    LiveInstrumentSnapshot instrument{};
    if (!buildLiveInstrumentForTrack(*track, pitch, instrument)) {
        return false;
    }

    rebuildTrackPlaybackLocked();
    for (int ti = 0; ti < trackPlaybackCount_.load(std::memory_order_acquire); ++ti) {
        const auto& playback = trackPlayback_[ti];
        if (playback.trackId != track->id) continue;
        instrument.modEdgeCount = std::min(playback.modEdgeCount, 16);
        std::copy(playback.modEdges,
                  playback.modEdges + instrument.modEdgeCount,
                  instrument.modEdges);
        break;
    }

    // A Sampler with no loaded sample is silent — treat as no playable instrument
    if (instrument.kind == LiveInstrumentKind::Sampler &&
        (instrument.samplerPcm == nullptr || instrument.samplerFrameCount <= 0)) {
        return false;
    }

    liveMixer_.noteOn(instrument, pitch, velocity);
    // Don't call retriggerOnNote() — live pad input shares the global
    // retrigger generation with the arrangement LFO render path, causing
    // unwanted envelope resets on arrangement LFOs (staccato/gate artifacts).

    // An explicit recording session is already armed by its own API and must
    // capture even when the transport-wide record-arm flag is false.
    if ((recordArmed_ || captureActive_) &&
        countInRemainingBeats_.load(std::memory_order_acquire) <= 0.0) {
        const uint64_t now = liveMixer_.sampleClock();
        if (!captureActive_) {
            captureActive_ = true;
            captureStartSample_ = now;
            captureStartPlayheadBeat_ = transport_.playheadBeats();
            captureQuantizeStep_ = 0.25;
            captureTrackId_ = track->id;
            captureEventHead_ = 0;
            captureEventCount_ = 0;
        }
        if (captureEventCount_ < kMaxCaptureEvents) {
            const int idx = (captureEventHead_ + captureEventCount_) % kMaxCaptureEvents;
            captureEvents_[idx] = CaptureEvent{CaptureEvent::Type::NoteOn, pitch, velocity, now};
            ++captureEventCount_;
        }
    }
    return true;
}

bool ProjectEngine::noteOff(int pitch) {
    const juce::ScopedWriteLock lock(mutex_);
    liveMixer_.noteOff(pitch);
    if (captureActive_) {
        if (captureEventCount_ < kMaxCaptureEvents) {
            const int idx = (captureEventHead_ + captureEventCount_) % kMaxCaptureEvents;
            captureEvents_[idx] = CaptureEvent{
                CaptureEvent::Type::NoteOff,
                pitch,
                0.0f,
                liveMixer_.sampleClock(),
            };
            ++captureEventCount_;
        }
    }
    return true;
}

void ProjectEngine::allNotesOff() {
    const juce::ScopedWriteLock lock(mutex_);
    liveMixer_.allNotesOff();
}

void ProjectEngine::setLivePitchBend(float bend) noexcept {
    livePitchBend_.store(bend, std::memory_order_relaxed);
}

void ProjectEngine::setLiveModulation(float mod) noexcept {
    liveModulation_.store(mod, std::memory_order_relaxed);
}

void ProjectEngine::clearCapture() {
    const juce::ScopedWriteLock lock(mutex_);
    captureEventHead_ = 0;
    captureEventCount_ = 0;
    captureActive_ = false;
    captureTrackId_.clear();
}

bool ProjectEngine::beginMidiRecordingSession(const std::string& trackId,
                                              double startBeat,
                                              double quantizeStep) {
    const juce::ScopedWriteLock lock(mutex_);
    Track* track = trackRepo_.findTrack(trackId);
    if (track == nullptr || track->isGroup || track->freeze.enabled) {
        return false;
    }
    captureActive_ = true;
    captureStartSample_ = liveMixer_.sampleClock();
    captureStartPlayheadBeat_ = startBeat < 0.0 ? 0.0 : startBeat;
    captureQuantizeStep_ = quantizeStep < 0.0 ? 0.0 : quantizeStep;
    captureTrackId_ = trackId;
    captureEventHead_ = 0;
    captureEventCount_ = 0;
    return true;
}

void ProjectEngine::cancelMidiRecordingSession() {
    clearCapture();
}

bool ProjectEngine::finishMidiRecordingSession(double endBeat) {
    std::string trackId;
    double clipStart = 0.0;
    double clipLength = 4.0;
    std::vector<MidiNoteState> committed;

    {
        const juce::ScopedWriteLock lock(mutex_);
        if (!captureActive_ || captureEventCount_ == 0) {
            captureEventHead_ = 0;
            captureEventCount_ = 0;
            captureActive_ = false;
            captureTrackId_.clear();
            return false;
        }
        const bool hasExplicitEnd = endBeat >= captureStartPlayheadBeat_;
        const double explicitEndBeat = hasExplicitEnd
            ? quantizeCaptureBeat(endBeat - captureStartPlayheadBeat_, captureQuantizeStep_)
            : -1.0;

        struct OpenNote {
            int pitch = 60;
            float velocity = 100.0f;
            double startBeat = 0.0;
        };
        std::vector<OpenNote> open;

        for (int i = 0; i < captureEventCount_; ++i) {
            const int idx = (captureEventHead_ + i) % kMaxCaptureEvents;
            const auto& event = captureEvents_[idx];
            double beat = quantizeCaptureBeat(
                sampleTimeToCaptureBeat(event.sampleTime), captureQuantizeStep_);
            if (hasExplicitEnd) {
                beat = std::clamp(beat, 0.0, explicitEndBeat);
            }
            if (event.type == CaptureEvent::Type::NoteOn) {
                if (hasExplicitEnd && beat >= explicitEndBeat) {
                    continue;
                }
                open.push_back(OpenNote{event.pitch, event.velocity, beat});
            } else {
                for (auto it = open.begin(); it != open.end(); ++it) {
                    if (it->pitch != event.pitch) {
                        continue;
                    }
                    double noteEndBeat =
                        quantizeCaptureBeat(
                            sampleTimeToCaptureBeat(event.sampleTime), captureQuantizeStep_);
                    if (hasExplicitEnd) {
                        noteEndBeat = std::clamp(noteEndBeat, 0.0, explicitEndBeat);
                    }
                    double duration = noteEndBeat - it->startBeat;
                    const double minDuration = captureQuantizeStep_ > 0.0 ? captureQuantizeStep_ : 0.05;
                    if (duration < minDuration) {
                        duration = minDuration;
                    }
                    committed.push_back(MidiNoteState{
                        it->pitch,
                        it->startBeat,
                        duration,
                        it->velocity,
                    });
                    open.erase(it);
                    break;
                }
            }
        }

        for (const auto& note : open) {
            const double fallbackEnd = hasExplicitEnd
                ? explicitEndBeat
                : note.startBeat + 0.5;
            double duration = fallbackEnd - note.startBeat;
            const double minDuration = captureQuantizeStep_ > 0.0 ? captureQuantizeStep_ : 0.05;
            if (duration < minDuration) {
                duration = minDuration;
            }
            committed.push_back(MidiNoteState{note.pitch, note.startBeat, duration, note.velocity});
        }

        if (committed.empty()) {
            captureEventHead_ = 0;
            captureEventCount_ = 0;
            captureActive_ = false;
            captureTrackId_.clear();
            return false;
        }

        double maxEnd = 0.0;
        for (const auto& note : committed) {
            maxEnd = std::max(maxEnd, note.startBeat + note.durationBeats);
        }
        if (hasExplicitEnd) {
            clipLength = std::max(0.25, explicitEndBeat);
        } else {
            clipLength = std::max(4.0, std::ceil(maxEnd / 4.0) * 4.0);
        }
        // Use the playhead position at capture start, not at commit time,
        // so the recorded clip aligns correctly with the timeline.
        clipStart = captureStartPlayheadBeat_;
        trackId = captureTrackId_.empty() ? trackRepo_.selectedTrackId() : captureTrackId_;
        if (trackId.empty()) {
            captureEventHead_ = 0;
            captureEventCount_ = 0;
            captureActive_ = false;
            captureTrackId_.clear();
            return false;
        }

        captureEventHead_ = 0;
        captureEventCount_ = 0;
        captureActive_ = false;
        captureTrackId_.clear();
    }

    const std::string clipId = createMidiClip(trackId, clipStart, clipLength);
    if (clipId.empty()) {
        return false;
    }
    return setMidiClipNotes(clipId, committed);
}

bool ProjectEngine::commitCapture() {
    return finishMidiRecordingSession(-1.0);
}

void ProjectEngine::readLiveMix(float* monoOut, int numFrames, double sampleRate) noexcept {
    IModulator* modulators[ModulationGraph::kMaxLfos]{};
    const int count = modulationGraph_.lfoPlaybackCount();
    for (int i = 0; i < count; ++i) modulators[i] = modulationGraph_.modulator(i);
    liveMixer_.readMix(monoOut, numFrames, sampleRate, modulators, count, transport_.bpm());
    liveMixer_.advanceSampleClock(numFrames);
}

bool ProjectEngine::hasLiveVoices() const noexcept {
    return liveMixer_.hasActiveVoices();
}

} // namespace audioapp
