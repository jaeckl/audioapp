#include "audioapp/MidiClipPlayback.hpp"
#include "audioapp/ProjectEngine.hpp"

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
                                                LiveInstrumentSnapshot& out) const {
    const PlaybackBuildContext context{sampleBank_};
    for (const auto& device : track.devices) {
        if (deviceRegistry_.buildLiveInstrument(device, context, out)) {
            return true;
        }
    }
    return false;
}

double ProjectEngine::sampleTimeToCaptureBeat(uint64_t sampleTime) const {
    if (!captureActive_ || sampleTime < captureStartSample_) {
        return 0.0;
    }
    const double seconds =
        static_cast<double>(sampleTime - captureStartSample_) / 48000.0;
    return seconds * static_cast<double>(bpm_) / 60.0;
}

bool ProjectEngine::setRecordArmed(bool armed) {
    std::lock_guard<std::mutex> lock(mutex_);
    recordArmed_ = armed;
    if (!armed) {
        captureActive_ = false;
        captureEvents_.clear();
    }
    return true;
}

bool ProjectEngine::noteOn(int pitch, float velocity) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (selectedTrackId_.empty()) {
        return false;
    }
    Track* track = findTrackLocked(selectedTrackId_);
    if (track == nullptr) {
        return false;
    }

    LiveInstrumentSnapshot instrument{};
    if (!buildLiveInstrumentForTrack(*track, instrument)) {
        return false;
    }

    liveMixer_.noteOn(instrument, pitch, velocity);

    if (recordArmed_) {
        const uint64_t now = liveMixer_.sampleClock();
        if (!captureActive_) {
            captureActive_ = true;
            captureStartSample_ = now;
            captureEvents_.clear();
        }
        captureEvents_.push_back(
            CaptureEvent{CaptureEvent::Type::NoteOn, pitch, velocity, now});
    }
    return true;
}

bool ProjectEngine::noteOff(int pitch) {
    std::lock_guard<std::mutex> lock(mutex_);
    liveMixer_.noteOff(pitch);
    if (recordArmed_ && captureActive_) {
        captureEvents_.push_back(CaptureEvent{
            CaptureEvent::Type::NoteOff,
            pitch,
            0.0f,
            liveMixer_.sampleClock(),
        });
    }
    return true;
}

void ProjectEngine::allNotesOff() {
    std::lock_guard<std::mutex> lock(mutex_);
    liveMixer_.allNotesOff();
}

void ProjectEngine::setLivePitchBend(float bend) noexcept {
    livePitchBend_.store(bend, std::memory_order_relaxed);
}

void ProjectEngine::setLiveModulation(float mod) noexcept {
    liveModulation_.store(mod, std::memory_order_relaxed);
}

void ProjectEngine::clearCapture() {
    std::lock_guard<std::mutex> lock(mutex_);
    captureEvents_.clear();
    captureActive_ = false;
}

bool ProjectEngine::commitCapture() {
    std::string trackId;
    double clipStart = 0.0;
    double clipLength = 4.0;
    std::vector<MidiNoteState> committed;

    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!captureActive_ || captureEvents_.empty() || selectedTrackId_.empty()) {
            return false;
        }

        struct OpenNote {
            int pitch = 60;
            float velocity = 100.0f;
            double startBeat = 0.0;
        };
        std::vector<OpenNote> open;

        for (const auto& event : captureEvents_) {
            const double beat = quantizeCaptureBeat(sampleTimeToCaptureBeat(event.sampleTime));
            if (event.type == CaptureEvent::Type::NoteOn) {
                open.push_back(OpenNote{event.pitch, event.velocity, beat});
            } else {
                for (auto it = open.begin(); it != open.end(); ++it) {
                    if (it->pitch != event.pitch) {
                        continue;
                    }
                    const double endBeat =
                        quantizeCaptureBeat(sampleTimeToCaptureBeat(event.sampleTime));
                    double duration = endBeat - it->startBeat;
                    if (duration < 0.25) {
                        duration = 0.25;
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
            committed.push_back(MidiNoteState{note.pitch, note.startBeat, 0.5, note.velocity});
        }

        if (committed.empty()) {
            captureEvents_.clear();
            captureActive_ = false;
            return false;
        }

        double maxEnd = 0.0;
        for (const auto& note : committed) {
            maxEnd = std::max(maxEnd, note.startBeat + note.durationBeats);
        }
        clipLength = std::max(4.0, std::ceil(maxEnd / 4.0) * 4.0);
        clipStart = playheadBeats_;
        trackId = selectedTrackId_;

        captureEvents_.clear();
        captureActive_ = false;
    }

    const std::string clipId = createMidiClip(trackId, clipStart, clipLength);
    if (clipId.empty()) {
        return false;
    }
    return setMidiClipNotes(clipId, committed);
}

void ProjectEngine::readLiveMix(float* monoOut, int numFrames, double sampleRate) noexcept {
    liveMixer_.readMix(monoOut, numFrames, sampleRate);
    liveMixer_.advanceSampleClock(numFrames);
}

} // namespace audioapp
