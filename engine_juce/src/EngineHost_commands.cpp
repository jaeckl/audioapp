#include "audioapp/EngineHost.hpp"
#include "audioapp/MasterMix.hpp"
#include "audioapp/MidiUtils.hpp"
#include "audioapp/ProjectJson.hpp"
#include "audioapp/ProjectArchive.hpp"
#include "audioapp/commands/CommandHandler.hpp"
#include "audioapp/snapshot/SnapshotDelta.hpp"
#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/DeviceChain.hpp"

#include <cmath>
#include <cstdio>
#include <memory>
#include <span>
#include <unordered_map>

#if defined(__ANDROID__)
#include <android/log.h>
#define AUDIOAPP_LOG(...) __android_log_print(ANDROID_LOG_INFO, "audioapp_engine", __VA_ARGS__)
#else
#define AUDIOAPP_LOG(...) std::fprintf(stderr, "[audioapp] " __VA_ARGS__)
#endif

namespace audioapp {

void EngineHost::ensureSampleBankReady() {
    sampleBank_.registerBundledDefaults();
    project_->setSampleBank(&sampleBank_);
    project_->setWavetableBank(&wavetableBank_);
}

void EngineHost::createProject() {
    ensureSampleBankReady();
    project_->createProject();
}

std::string EngineHost::addTrack(const std::string& name) {
    return project_->addTrack(name);
}

std::string EngineHost::addGroupTrack(const std::string& name) {
    return project_->addGroupTrack(name);
}

bool EngineHost::setTrackGroup(const std::string& trackId,
                               const std::string& groupTrackId) {
    return project_->setTrackGroup(trackId, groupTrackId);
}

bool EngineHost::moveTrack(const std::string& trackId,
                           const std::string& parentGroupId,
                           const std::string& beforeTrackId) {
    return project_->moveTrack(trackId, parentGroupId, beforeTrackId);
}

bool EngineHost::setTrackMuted(const std::string& trackId, bool muted) {
    return project_->setTrackMuted(trackId, muted);
}

bool EngineHost::setTrackSoloed(const std::string& trackId, bool soloed) {
    return project_->setTrackSoloed(trackId, soloed);
}

bool EngineHost::selectTrack(const std::string& trackId) {
    return project_->selectTrack(trackId);
}

std::string EngineHost::addDeviceToTrack(const std::string& trackId,
                                         const std::string& deviceType,
                                         int insertIndex) {
    return project_->addDeviceToTrack(trackId, deviceType, insertIndex);
}

bool EngineHost::removeDeviceFromTrack(const std::string& deviceId) {
    return project_->removeDeviceFromTrack(deviceId);
}

bool EngineHost::setDeviceParameter(const std::string& deviceId,
                                    const std::string& parameterId,
                                    float value) {
    return project_->setDeviceParameter(deviceId, parameterId, value);
}

bool EngineHost::setDeviceStringParameter(const std::string& deviceId,
                                          const std::string& parameterId,
                                          const std::string& value) {
    return project_->setDeviceStringParameter(deviceId, parameterId, value);
}

bool EngineHost::setMasterGain(float gain) {
    return project_->setMasterGain(gain);
}

std::string EngineHost::getProjectSnapshotJson() const {
    return snapshotToJson(project_->snapshot(), project_->deviceRegistry(),
                          project_->modulatorTypes());
}

std::string EngineHost::getDeviceConfigsJson(const std::vector<std::string>& deviceIds) const {
    auto snap = project_->snapshot();
    auto* obj = new juce::DynamicObject();
    auto* devicesObj = new juce::DynamicObject();

    // Build device map: deviceId → (DeviceSlot*, TrackState*)
    std::unordered_map<std::string, std::pair<const DeviceSlot*, const TrackState*>> deviceMap;
    for (const auto& track : snap.tracks) {
        for (const auto& device : track.devices) {
            deviceMap[device.id] = {&device, &track};
        }
    }

    for (const auto& deviceId : deviceIds) {
        auto it = deviceMap.find(deviceId);
        if (it == deviceMap.end()) continue;
        const auto& [slot, track] = it->second;

        // Serialize via registry dispatch (no round-trip)
        juce::var deviceVar = audioapp::deviceToVar(*slot, project_->deviceRegistry());

        // Inject meters from this track's deviceMeters
        for (const auto& meter : track->deviceMeters) {
            if (meter.deviceId == deviceId) {
                if (auto* devObj = deviceVar.getDynamicObject()) {
                    auto* metersObj = new juce::DynamicObject();
                    metersObj->setProperty("gainReductionDb",
                        static_cast<double>(meter.gainReductionDb));
                    metersObj->setProperty("inputLevel",
                        static_cast<double>(meter.inputLevel));
                    devObj->setProperty("meters", juce::var(metersObj));
                }
                break;
            }
        }
        devicesObj->setProperty(juce::String::fromUTF8(deviceId.c_str()), deviceVar);
    }

    obj->setProperty("ok", true);
    obj->setProperty("devices", juce::var(devicesObj));
    return juce::JSON::toString(juce::var(obj), false).toStdString();
}

std::string EngineHost::getTransportStateJson() const {
    return buildBridgeOkTransportState(project_->transportState());
}

float EngineHost::activeOscillatorFrequencyHz() const {
    return project_->activeOscillatorFrequencyHz();
}

double EngineHost::playheadBeats() const noexcept {
    return project_->playheadBeats();
}

void EngineHost::setPlayheadBeats(double beats) noexcept {
    project_->setPlayheadBeats(beats);
}

void EngineHost::readMasterMix(float* monoOut,
                               int numFrames,
                               double sampleRate,
                               double playheadStartBeat) noexcept {
    project_->readMasterMix(monoOut, numFrames, sampleRate, playheadStartBeat);
}

void EngineHost::readMasterMixStereo(float* leftOut,
                                     float* rightOut,
                                     int numFrames,
                                     double sampleRate,
                                     double playheadStartBeat) noexcept {
    project_->readMasterMixStereo(leftOut, rightOut, numFrames, sampleRate, playheadStartBeat);
}

void EngineHost::readPreviewMix(float* leftOut, float* rightOut, int numFrames, double sampleRate) noexcept {
    if (leftOut == nullptr || rightOut == nullptr || numFrames <= 0) {
        return;
    }

    // Local mono scratch: the instrument renderers (mixSubtractiveMidiNotesBlock,
    // mixSamplerMidiNotesBlock, addSineBlock, fallbackOsc mono path) are mono.
    // We render into monoScratch and then duplicate to L+R at the end of the
    // function unless the active renderer is the fallback oscillator's stereo
    // path, which writes directly to L+R.
    //
    // The scratch must live on the stack / thread-local — never heap-alloc
    // on the audio thread (allocator lock contention = stutter / dropouts).
    constexpr int kPreviewScratchMax = 4096;
    if (numFrames > kPreviewScratchMax) {
        // Should never happen (Android caps at 4096, JUCE at 2048), but be
        // safe: bail out and let the next block try again.
        return;
    }
    thread_local float monoScratch[kPreviewScratchMax];
    float* monoOut = monoScratch;
    std::memset(monoOut, 0, static_cast<size_t>(numFrames) * sizeof(float));

    // Sample preview voice
    const bool sampleActive = previewVoice_.active.load(std::memory_order_acquire);
    if (sampleActive) {
        const float* pcm = previewVoice_.pcmData;
        const int pcmSize = previewVoice_.pcmSize;
        if (pcm == nullptr || pcmSize <= 0) {
            previewVoice_.active.store(false, std::memory_order_release);
        } else {
            int position = previewVoice_.position.load(std::memory_order_relaxed);
            for (int frame = 0; frame < numFrames; ++frame) {
                if (position >= pcmSize) {
                    previewVoice_.active.store(false, std::memory_order_release);
                    for (int rest = frame; rest < numFrames; ++rest) {
                        monoOut[rest] = 0.0f;
                    }
                    previewVoice_.position.store(position, std::memory_order_release);
                    goto duplicateMonoToStereo;
                }
                monoOut[frame] += pcm[static_cast<size_t>(position++)];
            }
            previewVoice_.position.store(position, std::memory_order_release);
        }
    }

    // MIDI or Preset preview
    if (previewMidi_.active.load(std::memory_order_acquire)) {
        if (!previewMidi_.notes.empty()) {
            const double beatsPerBlock = (previewMidi_.bpm / 60.0)
                * (static_cast<double>(numFrames) / sampleRate);
            double ph = previewMidi_.playheadBeats.load(std::memory_order_relaxed);
            double newPh = ph + beatsPerBlock;
            bool didWrap = false;
            double wrappedNewPh = newPh;

            // Non-looping preview: when the playhead crosses the end, stop everything.
            if (!previewMidi_.loop && previewMidi_.lengthBeats > 0.0
                && newPh >= previewMidi_.lengthBeats) {
                previewMidi_.active.store(false, std::memory_order_release);
                previewMixer_.allNotesOff();
                fallbackOsc_.allNotesOff();
                project_->allNotesOff();
                std::memset(monoOut, 0, static_cast<size_t>(numFrames) * sizeof(float));
                goto duplicateMonoToStereo;
            }

            if (previewMidi_.lengthBeats > 0.0 && newPh >= previewMidi_.lengthBeats) {
                didWrap = true;
                wrappedNewPh = std::fmod(newPh, previewMidi_.lengthBeats);
            }

            if (previewMidi_.isPresetPreview) {
                // Direct-renderer path. Mirrors how the arrangement playback calls
                // mix*MidiNotesBlock for the selected device kind, but driven by the
                // preview playhead instead of the arrangement playhead. No voice
                // allocator + noteOn/noteOff — the playhead position is the source
                // of truth and notes are audible iff they straddle the playhead.
                const auto kind = previewMidi_.renderKind.load(std::memory_order_acquire);
                const int noteCount = static_cast<int>(previewMidi_.playbackNotes.size());
                const MidiPlaybackNote* notes = previewMidi_.playbackNotes.data();
                const double playheadStartBeat = ph;
                const double beatsPerFrame = beatsPerBlock / static_cast<double>(numFrames);

                switch (kind) {
                    case PreviewMidiState::PresetRenderKind::SubtractiveSynth: {
                        // Convert MidiPlaybackNote → SubtractiveMidiNoteRegion
                        // (SubtractiveMidiNoteRegion has an extra noteKey field).
                        const int n = noteCount > kSubtractiveMaxVoices
                                      ? kSubtractiveMaxVoices : noteCount;
                        SubtractiveMidiNoteRegion regions[kSubtractiveMaxVoices];
                        for (int i = 0; i < n; ++i) {
                            regions[i] = SubtractiveMidiNoteRegion{
                                notes[i].pitch,
                                /* noteKey */         i,
                                notes[i].clipStartBeat, notes[i].clipLengthBeats,
                                notes[i].noteStartBeat, notes[i].noteDurationBeats,
                                notes[i].velocity,
                            };
                        }
                        // Preview-mode params: clamp release tails so a chord
                        // at the end of the loop doesn't bleed into the first
                        // chord of the next iteration. The actual arrangement
                        // playback keeps the long release (it's how synths
                        // sound), but for a loop preview we want the chords
                        // to clearly end before the loop wraps.
                        SubtractiveSynthParams previewParams = previewMidi_.subtractiveParams;
                        previewParams.ampRelease = std::min(previewParams.ampRelease, 0.10f);
                        previewParams.filterRelease = std::min(previewParams.filterRelease, 0.10f);
                        mixSubtractiveMidiNotesBlock(monoOut, numFrames, sampleRate,
                                                     previewMidi_.bpm, playheadStartBeat,
                                                     regions, n,
                                                     previewParams,
                                                     previewMidi_.subtractiveRuntime);
                        break;
                    }
                    case PreviewMidiState::PresetRenderKind::Oscillator: {
                        const float gain = previewMidi_.instrument.gain * kInstrumentOutputGain;
                        for (int frame = 0; frame < numFrames; ++frame) {
                            const double beat = playheadStartBeat
                                              + static_cast<double>(frame) * beatsPerFrame;
                            int activePitch = -1;
                            for (int i = 0; i < noteCount; ++i) {
                                const auto& n = notes[i];
                                if (beat < n.clipStartBeat ||
                                    beat >= n.clipStartBeat + n.clipLengthBeats) {
                                    continue;
                                }
                                const double loopedBeat = std::fmod(
                                    beat - n.clipStartBeat, n.clipLengthBeats);
                                const double noteEnd = std::min(
                                    n.noteStartBeat + n.noteDurationBeats, n.clipLengthBeats);
                                if (loopedBeat >= n.noteStartBeat && loopedBeat < noteEnd) {
                                    activePitch = n.pitch;
                                }
                            }
                            if (activePitch >= 0) {
                                addSineBlock(monoOut + frame, 1, sampleRate,
                                             midiNoteToHz(activePitch),
                                             previewMidi_.oscillatorPhase, gain);
                            }
                        }
                        break;
                    }
                    case PreviewMidiState::PresetRenderKind::Sampler: {
                        if (previewMidi_.samplerHasPcm) {
                            const int regionCount = noteCount > kMaxInstrumentRegions
                                                    ? kMaxInstrumentRegions : noteCount;
                            SamplerMidiNoteRegion regions[kMaxInstrumentRegions];
                            for (int i = 0; i < regionCount; ++i) {
                                const auto& src = notes[i];
                                regions[i] = SamplerMidiNoteRegion{
                                    src.pitch,
                                    src.clipStartBeat, src.clipLengthBeats,
                                    src.noteStartBeat, src.noteDurationBeats,
                                    src.velocity,
                                };
                            }
                            mixSamplerMidiNotesBlock(monoOut, numFrames, sampleRate,
                                                      previewMidi_.bpm, playheadStartBeat,
                                                      regions, regionCount,
                                                      previewMidi_.samplerParams);
                        }
                        break;
                    }
                    case PreviewMidiState::PresetRenderKind::None:
                    default:
                        break;
                }
            } else {
                // Live-keyboard MIDI preview: drive the existing mixer/fallback
                // path (voice allocator with noteOn/noteOff triggers). The
                // fallback oscillator writes directly to L/R with per-voice
                // panning so chords have actual stereo width.
                for (size_t i = 0; i < previewMidi_.notes.size(); ++i) {
                    const auto& note = previewMidi_.notes[i];
                    const double endBeat = note.startBeat + note.durationBeats;

                    bool startTriggered = false;
                    if (!didWrap) {
                        if (note.startBeat >= ph && note.startBeat < newPh) {
                            startTriggered = true;
                        }
                    } else {
                        if ((note.startBeat >= ph && note.startBeat < previewMidi_.lengthBeats) ||
                            (note.startBeat >= 0.0 && note.startBeat < wrappedNewPh)) {
                            startTriggered = true;
                        }
                    }

                    if (startTriggered) {
                        bool playedOnInstrument = project_->noteOn(note.pitch, note.velocity);
                        if (i < previewMidi_.noteUsingInstrument.size()) {
                            previewMidi_.noteUsingInstrument[i] = playedOnInstrument;
                        }
                        if (!playedOnInstrument) {
                            fallbackOsc_.noteOn(note.pitch, note.velocity,
                                                note.startBeat, note.durationBeats);
                        }
                    }

                    bool endTriggered = false;
                    if (!didWrap) {
                        if (endBeat >= ph && endBeat < newPh) {
                            endTriggered = true;
                        }
                    } else {
                        // The block spans the loop boundary. A note ending
                        // anywhere in [ph, lengthBeats) has its endBeat
                        // crossed by the block (the block reaches the end of
                        // the loop). Notes ending in [0, wrappedNewPh) also
                        // have their endBeat crossed (the block reaches
                        // them after wrapping).
                        //
                        // Critically: a note whose endBeat equals lengthBeats
                        // exactly (the last beat of the loop) must fire
                        // noteOff here too — otherwise the chord bleeds into
                        // the next iteration. The previous condition missed
                        // this because (endBeat < wrappedNewPh) is false when
                        // endBeat == lengthBeats and wrappedNewPh is small.
                        if ((endBeat >= ph && endBeat <= previewMidi_.lengthBeats) ||
                            (endBeat >= 0.0 && endBeat < wrappedNewPh)) {
                            endTriggered = true;
                        }
                    }

                    if (endTriggered) {
                        bool wasOnInstrument = false;
                        if (i < previewMidi_.noteUsingInstrument.size()) {
                            wasOnInstrument = previewMidi_.noteUsingInstrument[i];
                        }
                        if (wasOnInstrument) {
                            project_->noteOff(note.pitch);
                        } else {
                            fallbackOsc_.noteOff(note.pitch);
                        }
                    }
                }

                previewMixer_.advanceSampleClock(numFrames);
                // Write the fallback oscillator directly to L/R with per-voice
                // panning, bypassing the mono scratch.
                fallbackOsc_.processBlockStereo(leftOut, rightOut, numFrames, sampleRate, ph);
                // CRITICAL: still advance the playhead so the next block's
                // noteOn/noteOff triggers don't refire the same notes (which
                // would cause a stutter fest).
                const double wrappedPhLive = previewMidi_.lengthBeats > 0.0
                    ? std::fmod(newPh, previewMidi_.lengthBeats) : newPh;
                previewMidi_.playheadBeats.store(wrappedPhLive, std::memory_order_release);
                // Skip the mono-to-stereo duplication (we already wrote L/R).
                return;
            }

            const double wrappedPh = previewMidi_.lengthBeats > 0.0
                ? std::fmod(newPh, previewMidi_.lengthBeats) : newPh;
            previewMidi_.playheadBeats.store(wrappedPh, std::memory_order_release);
        }
    }

duplicateMonoToStereo:
    // Duplicate the mono scratch into L and R. The instrument renderers
    // (subtractive, sampler, oscillator) are mono by design — preview-only,
    // so we don't pay the cost of running two instances. The fallback
    // oscillator's stereo path returns early above.
    for (int i = 0; i < numFrames; ++i) {
        leftOut[i] += monoOut[i];
        rightOut[i] += monoOut[i];
    }
}

void EngineHost::readLiveMix(float* monoOut, int numFrames, double sampleRate) noexcept {
    project_->readLiveMix(monoOut, numFrames, sampleRate);
}

std::string EngineHost::createMidiClip(const std::string& trackId, double startBeat, double lengthBeats) {
    return project_->createMidiClip(trackId, startBeat, lengthBeats);
}

bool EngineHost::setMidiClipNotes(const std::string& clipId, const std::vector<MidiNoteState>& notes) {
    return project_->setMidiClipNotes(clipId, notes);
}

std::string EngineHost::createSampleClip(const std::string& trackId,
                                         const std::string& sampleId,
                                         double startBeat,
                                         double lengthBeats) {
    ensureSampleBankReady();
    return project_->createSampleClip(trackId, sampleId, startBeat, lengthBeats);
}

bool EngineHost::moveClip(const std::string& clipId,
                          const std::string& targetTrackId,
                          double startBeat) {
    return project_->moveClip(clipId, targetTrackId, startBeat);
}

bool EngineHost::setClipLength(const std::string& clipId,
                               double lengthBeats,
                               ClipLengthTarget target) {
    return project_->setClipLength(clipId, lengthBeats, target);
}

bool EngineHost::setClipLoopContent(const std::string& clipId, bool loopContent) {
    return project_->setClipLoopContent(clipId, loopContent);
}

std::string EngineHost::createAutomationClip(const std::string& trackId,
                                             double startBeat,
                                             double lengthBeats) {
    return project_->createAutomationClip(trackId, startBeat, lengthBeats);
}

bool EngineHost::assignAutomationTarget(const std::string& clipId,
                                          const std::string& deviceId,
                                          const std::string& paramId) {
    return project_->assignAutomationTarget(clipId, deviceId, paramId);
}

bool EngineHost::setAutomationPoints(const std::string& clipId,
                                     const std::vector<AutomationPointState>& points) {
    return project_->setAutomationPoints(clipId, points);
}

bool EngineHost::setBpm(int bpm) {
    return project_->setBpm(bpm);
}

bool EngineHost::deleteTrack(const std::string& trackId) {
    return project_->deleteTrack(trackId);
}

bool EngineHost::deleteClip(const std::string& clipId) {
    return project_->deleteClip(clipId);
}

bool EngineHost::duplicateClip(const std::string& clipId) {
    return project_->duplicateClip(clipId);
}

bool EngineHost::setLoopEnabled(bool enabled) {
    return project_->setLoopEnabled(enabled);
}

bool EngineHost::setLoopLengthBeats(double lengthBeats) {
    return project_->setLoopLengthBeats(lengthBeats);
}

bool EngineHost::setLoopRegion(double startBeat, double endBeat) {
    return project_->setLoopRegion(startBeat, endBeat);
}

bool EngineHost::setRecordArmed(bool armed) {
    return project_->setRecordArmed(armed);
}

bool EngineHost::undo() {
    return project_->undo();
}

bool EngineHost::redo() {
    return project_->redo();
}

int EngineHost::createLfo(int modulatorType) {
    return project_->createLfo(modulatorType);
}

bool EngineHost::removeLfo(int lfoId) {
    return project_->removeLfo(lfoId);
}

bool EngineHost::updateLfoParam(int lfoId, const std::string& param, float value) {
    return project_->updateLfoParam(lfoId, param, value);
}

bool EngineHost::batchUpdateLfoParams(int lfoId, const std::vector<std::pair<std::string, float>>& params) {
    return project_->batchUpdateLfoParams(lfoId, params);
}

bool EngineHost::assignModulation(int lfoId, const std::string& deviceId, const std::string& paramId, float amount) {
    return project_->assignModulation(lfoId, deviceId, paramId, amount);
}

bool EngineHost::removeModulation(int lfoId, const std::string& paramId) {
    return project_->removeModulation(lfoId, paramId);
}

bool EngineHost::applySubtractiveSynthPreset(
    const std::string& deviceId,
    const std::vector<std::pair<std::string, float>>& params,
    const std::vector<ProjectEngine::SubtractivePresetLfoSpec>& lfos,
    const std::vector<ProjectEngine::SubtractivePresetModSpec>& mods) {
    return project_->applySubtractiveSynthPreset(deviceId, params, lfos, mods);
}

bool EngineHost::noteOn(int pitch, float velocity) {
    ensureAudioOutput();
    return project_->noteOn(pitch, velocity);
}

bool EngineHost::noteOff(int pitch) {
    return project_->noteOff(pitch);
}

void EngineHost::allNotesOff() {
    project_->allNotesOff();
    previewMixer_.allNotesOff();
}

void EngineHost::clearCapture() {
    project_->clearCapture();
}

bool EngineHost::commitCapture() {
    return project_->commitCapture();
}

void EngineHost::enterPlayMode() {
    ensureAudioOutput();
}

void EngineHost::setPitchBend(float bend) noexcept {
    project_->setLivePitchBend(bend);
}

void EngineHost::setModulation(float mod) noexcept {
    project_->setLiveModulation(mod);
}

std::vector<float> EngineHost::renderOffline(double lengthBeats, double sampleRate) {
    return project_->renderOffline(lengthBeats, sampleRate);
}

std::string EngineHost::importWavSample(const std::string& displayName,
                                        const std::vector<uint8_t>& wavBytes) {
    ensureSampleBankReady();
    const std::string id = "sample_import_" + std::to_string(nextImportSampleNum_++);
    const std::string name = displayName.empty() ? "Imported sample" : displayName;
    if (!sampleBank_.loadFromWavBytes(id, name, "imported", wavBytes, 120)) {
        return {};
    }
    return id;
}

std::string EngineHost::importWavetable(const std::string& name,
                                        const std::vector<uint8_t>& wavBytes) {
    AUDIOAPP_LOG("importWavetable name=%s bytes=%zu", name.c_str(), wavBytes.size());
    if (wavBytes.empty()) {
        AUDIOAPP_LOG("importWavetable -> empty bytes");
        return {};
    }
    const int index = wavetableBank_.loadFromBytes(name, wavBytes.data(), wavBytes.size());
    AUDIOAPP_LOG("importWavetable name=%s loadFromBytes -> index=%d bankSize=%d", name.c_str(), index, wavetableBank_.size());
    if (index < 0) return {};
    return name;
}

void EngineHost::previewSample(const std::string& sampleId) {
    const auto* sample = sampleBank_.findSample(sampleId);
    if (sample == nullptr || sample->pcm.empty()) {
        return;
    }
    // Atomically swap in a new shared_ptr so the audio thread never reads freed memory.
    auto buf = std::make_shared<const std::vector<float>>(sample->pcm);
    previewVoice_.pcmData = buf->data();
    previewVoice_.pcmSize = static_cast<int>(buf->size());
    previewVoice_.sampleRate.store(sample->sampleRate, std::memory_order_release);
    previewVoice_.position.store(0, std::memory_order_release);
    previewVoice_.active.store(true, std::memory_order_release);
    std::atomic_store(&previewBuffer_, std::move(buf));
    ensureAudioOutput();
}

void EngineHost::previewMidi(const std::vector<MidiNoteState>& notes, double lengthBeats, int bpm, double startBeat, bool loop) {
    // Stop any previous preview
    allNotesOff();
    fallbackOsc_.allNotesOff();

    // Store MIDI state
    previewMidi_.notes = notes;
    previewMidi_.noteUsingInstrument.assign(notes.size(), false);
    previewMidi_.lengthBeats = lengthBeats;
    previewMidi_.bpm = bpm;
    previewMidi_.playheadBeats.store(startBeat, std::memory_order_release);
    previewMidi_.isPresetPreview = false;
    previewMidi_.loop = loop;
    previewMidi_.active.store(true, std::memory_order_release);

    ensureAudioOutput();
}

void EngineHost::previewPreset(const std::string& deviceType, const std::vector<std::pair<std::string, float>>& params, const std::vector<MidiNoteState>& notes, double lengthBeats, int bpm, double startBeat, bool loop) {
    // Stop any previous preview
    allNotesOff();
    fallbackOsc_.allNotesOff();

    AUDIOAPP_LOG(
        "previewPreset[ctrl] deviceType=%s params=%zu notes=%zu length=%.2f bpm=%d start=%.2f loop=%d",
        deviceType.c_str(), params.size(), notes.size(), lengthBeats, bpm, startBeat,
        loop ? 1 : 0);

    // Store MIDI state (shared with live-keyboard preview path).
    previewMidi_.notes = notes;
    previewMidi_.noteUsingInstrument.assign(notes.size(), false);
    previewMidi_.lengthBeats = lengthBeats;
    previewMidi_.bpm = bpm;
    previewMidi_.playheadBeats.store(startBeat, std::memory_order_release);
    previewMidi_.isPresetPreview = true;
    previewMidi_.loop = loop;

    // --- Build a virtual device slot via DeviceRegistry ---
    DeviceSlot slot = project_->deviceRegistry().createDefault(deviceType, "dummy-preview");
    for (const auto& [paramId, value] : params) {
        project_->deviceRegistry().setParameter(slot, paramId, value);
    }

    // Keep the legacy LiveInstrumentSnapshot path for symmetry (unused by the
    // preset-preview renderer; kept so callers inspecting the snapshot still see data).
    PlaybackBuildContext context{nullptr};
    project_->deviceRegistry().buildLiveInstrument(slot, context, previewMidi_.instrument);

    // --- Direct renderer setup ---
    // Project every note onto a single "virtual clip" at beat 0 with length
    // lengthBeats. This matches the contract expected by mix*MidiNotesBlock
    // (clipStartBeat / clipLengthBeats / noteStartBeat relative to clip).
    previewMidi_.playbackNotes.clear();
    previewMidi_.playbackNotes.reserve(notes.size());
    for (size_t i = 0; i < notes.size(); ++i) {
        const auto& n = notes[i];
        previewMidi_.playbackNotes.push_back(MidiPlaybackNote{
            /* pitch */            n.pitch,
            /* clipStartBeat */    0.0,
            /* clipLengthBeats */  lengthBeats,
            /* noteStartBeat */    n.startBeat,
            /* noteDurationBeats*/ n.durationBeats,
            /* velocity */         n.velocity,
        });
    }

    // Reset runtimes on every new preview so voices don't leak across presets.
    std::memset(previewMidi_.subtractiveRuntime.voices, 0, sizeof(previewMidi_.subtractiveRuntime.voices));
    previewMidi_.subtractiveRuntime.stealIndex = 0;
    previewMidi_.subtractiveParams = SubtractiveSynthParams{};
    previewMidi_.oscillatorPhase = 0.0f;
    std::memset(previewMidi_.samplerFilterStates, 0, sizeof(previewMidi_.samplerFilterStates));
    previewMidi_.samplerParams = SamplerInstrumentPlayback{};
    previewMidi_.samplerHasPcm = false;

    // Map the device slot → direct-renderer kind + params.
    using Kind = PreviewMidiState::PresetRenderKind;
    const auto kind = deviceNodeKindFromTypeId(slot.config.typeId);
    if (kind == DeviceNodeKind::SubtractiveSynth) {
        const auto& inst = std::get<SubtractiveSynthParams>(slot.config.instance);
        previewMidi_.subtractiveParams = inst;
        previewMidi_.subtractiveParams.gain = std::get<StereoOutputPanel>(slot.config.outputPanel).gain;
        previewMidi_.renderKind.store(Kind::SubtractiveSynth, std::memory_order_release);
        AUDIOAPP_LOG(
            "previewPreset[ctrl] -> SubtractiveSynth outputGain=%.3f inst.gain=%.3f "
            "ampSustain=%.3f ampRelease=%.3f filterCutoff=%.3f",
            std::get<StereoOutputPanel>(slot.config.outputPanel).gain, inst.gain, inst.ampSustain, inst.ampRelease, inst.filterCutoff);
    } else if (kind == DeviceNodeKind::Oscillator) {
        const auto& inst = std::get<OscillatorParams>(slot.config.instance);
        // Mirror the oscillator arrangement path: a sine at the active note's pitch,
        // gain = output-panel gain. The OscillatorParams.frequencyHz is overridden per-frame
        // by midiActiveFrequencyHz(notes, noteCount, playhead, idleHz).
        (void)inst; // oscillator is a single-voice sine — no per-param shape to apply.
        previewMidi_.renderKind.store(Kind::Oscillator, std::memory_order_release);
        AUDIOAPP_LOG("previewPreset[ctrl] -> Oscillator outputGain=%.3f",
                     std::get<StereoOutputPanel>(slot.config.outputPanel).gain);
    } else if (kind == DeviceNodeKind::Sampler) {
        const auto& inst = std::get<SamplerModel>(slot.config.instance);
        previewMidi_.samplerParams.pcm = previewMidi_.instrument.samplerPcm;
        previewMidi_.samplerParams.frameCount = previewMidi_.instrument.samplerFrameCount;
        previewMidi_.samplerParams.pcmSampleRate = previewMidi_.instrument.samplerPcmSampleRate;
        previewMidi_.samplerParams.gain = std::get<StereoOutputPanel>(slot.config.outputPanel).gain * kInstrumentOutputGain;
        previewMidi_.samplerParams.rootPitch = previewMidi_.instrument.rootPitch;
        previewMidi_.samplerParams.rootFineTune = previewMidi_.instrument.rootFineTune;
        previewMidi_.samplerParams.attack = inst.attack;
        previewMidi_.samplerParams.decay = inst.decay;
        previewMidi_.samplerParams.sustain = inst.sustain;
        previewMidi_.samplerParams.release = inst.release;
        previewMidi_.samplerParams.filterCutoff = inst.filterCutoff;
        previewMidi_.samplerParams.filterQ = inst.filterQ;
        previewMidi_.samplerParams.filterMode = inst.filterMode;
        previewMidi_.samplerParams.filterEnvAmount = inst.filterEnvAmount;
        previewMidi_.samplerParams.filterAttack = inst.filterAttack;
        previewMidi_.samplerParams.filterDecay = inst.filterDecay;
        previewMidi_.samplerParams.filterSustain = inst.filterSustain;
        previewMidi_.samplerParams.filterRelease = inst.filterRelease;
        previewMidi_.samplerParams.trimStartFrame = previewMidi_.instrument.trimStartFrame;
        previewMidi_.samplerParams.trimEndFrame = previewMidi_.instrument.trimEndFrame;
        previewMidi_.samplerParams.regionStartFrame = previewMidi_.instrument.regionStartFrame;
        previewMidi_.samplerParams.regionEndFrame = previewMidi_.instrument.regionEndFrame;
        previewMidi_.samplerParams.playbackMode = inst.playbackMode;
        previewMidi_.samplerParams.filterState = nullptr;
        previewMidi_.samplerParams.noteFilterStates = previewMidi_.samplerFilterStates;
        previewMidi_.samplerParams.noteFilterStateCount = kMaxInstrumentRegions;
        previewMidi_.samplerHasPcm = previewMidi_.samplerParams.pcm != nullptr
                                    && previewMidi_.samplerParams.frameCount > 1;
        previewMidi_.renderKind.store(
            previewMidi_.samplerHasPcm ? Kind::Sampler : Kind::None,
            std::memory_order_release);
        AUDIOAPP_LOG(
            "previewPreset[ctrl] -> Sampler hasPcm=%d frameCount=%d pcmSampleRate=%.0f "
            "rootPitch=%d outputGain=%.3f",
            previewMidi_.samplerHasPcm ? 1 : 0,
            previewMidi_.samplerParams.frameCount,
            previewMidi_.samplerParams.pcmSampleRate,
            previewMidi_.samplerParams.rootPitch,
            std::get<StereoOutputPanel>(slot.config.outputPanel).gain);
    } else {
        // Effects (delay, reverb, …) and unknown devices don't have an instrument
        // renderer — silent is the correct fallback for preset preview.
        previewMidi_.renderKind.store(Kind::None, std::memory_order_release);
        AUDIOAPP_LOG("previewPreset[ctrl] -> None (no instrument renderer for %s)",
                     deviceType.c_str());
    }

    previewMidi_.active.store(true, std::memory_order_release);
    ensureAudioOutput();
    AUDIOAPP_LOG("previewPreset[ctrl] done. active=true ensureAudioOutput done");
}

void EngineHost::stopPreview() {
    previewMidi_.active.store(false, std::memory_order_release);
    fallbackOsc_.allNotesOff();
    allNotesOff();
}

bool EngineHost::saveProject(const std::string& archivePath) {
    return saveProjectToArchive(*project_, archivePath);
}

bool EngineHost::loadProject(const std::string& archivePath) {
    ensureSampleBankReady();
    return loadProjectFromArchive(*project_, archivePath);
}

std::string EngineHost::getProjectFileJson() const {
    return projectFileToJson(project_->toProjectFileData(),
                             project_->deviceRegistry(),
                             project_->modulatorTypes());
}

bool EngineHost::loadProjectFileJson(const std::string& json) {
    ProjectFileData data;
    if (!parseProjectFileJson(json, data, project_->deviceRegistry(), project_->modulatorTypes())) {
        return false;
    }
    ensureSampleBankReady();
    sampleBank_.clearImported();
    sampleBank_.restoreMetadata(data.sampleLibrary, data.bpm > 0 ? data.bpm : 120);
    if (!project_->loadFromProjectFileData(data)) {
        return false;
    }
    return true;
}

void EngineHost::advancePlayheadForBlock(int numFrames, double sampleRate) noexcept {
    project_->advancePlayhead(numFrames, sampleRate);
}

std::string EngineHost::getParamDescriptorsJson(const std::string& deviceType) const {
    const auto kind = deviceNodeKindFromTypeId(deviceType);
    if (kind == DeviceNodeKind::Unknown) {
        return R"({"ok":false,"error":"unknown_device_type","protocolVersion":1})";
    }

    const auto* type = project_->deviceRegistry().findByKind(kind);
    const auto descriptors = type ? type->paramDescriptors() : std::span<const ParamDescriptor>{};

    // Build JSON string directly — avoids juce::var Array<var>* constructor
    // issues in JUCE 8.
    std::string json = R"({"ok":true,"deviceType":")";
    json += deviceType;
    json += R"(","protocolVersion":1,"params":[)";

    if (!descriptors.empty()) {
        for (size_t i = 0; i < descriptors.size(); ++i) {
            if (i > 0) json += ",";
            const auto& d = descriptors[i];
            json += R"({"stableName":")";
            json += d.stableName;
            json += R"(","displayName":")";
            json += d.displayName;
            json += R"(","defaultValue":)";
            json += std::to_string(d.defaultValue);
            json += R"(,"min":)";
            json += std::to_string(d.minValue);
            json += R"(,"max":)";
            json += std::to_string(d.maxValue);
            json += R"(,"automatable":)";
            json += (d.automatable ? "true" : "false");
            json += R"(,"modulatable":)";
            json += (d.modulatable ? "true" : "false");
            json += "}";
        }
    }
    json += "]}";
    return json;
}

std::string EngineHost::getDeviceMetersJson() {
    return project_->getDeviceMetersJson();
}

namespace {

/// Convert any populated SnapshotDelta into a delta CommandResult.
commands::CommandResult deltaResult(snapshot::SnapshotDelta sd) {
    // Build JSON envelope with XML delta payload.
    // Format: {"ok": true, "deltaXml": "<delta>...</delta>"}
    auto* obj = new juce::DynamicObject();
    obj->setProperty("ok", true);
    obj->setProperty("deltaXml", juce::String(sd.toXml()));
    return commands::rawResult(juce::JSON::toString(juce::var(obj), false).toStdString());
}

/// Build a transport-only delta juce::var from a setter lambda.
template <typename Fn>
commands::CommandResult transportDeltaResult(Fn&& configure) {
    snapshot::SnapshotDelta sd;
    snapshot::TransportDelta td;
    configure(td);
    sd.transport = std::move(td);
    return deltaResult(std::move(sd));
}

/// Build a single-modulator-param delta (high-frequency LFO slider changes).
commands::CommandResult modulatorParamDelta(
    int lfoId, const std::string& param, float newValue)
{
    snapshot::SnapshotDelta sd;
    snapshot::ModulatorDelta md;
    md.lfoId = lfoId;
    md.params.push_back({param, newValue});
    sd.modulators.push_back(std::move(md));
    return deltaResult(std::move(sd));
}

/// Build a batch-modulator-param delta.
commands::CommandResult batchModulatorParamDelta(
    int lfoId,
    const std::vector<std::pair<std::string, float>>& params)
{
    snapshot::SnapshotDelta sd;
    snapshot::ModulatorDelta md;
    md.lfoId = lfoId;
    for (const auto& [p, v] : params)
        md.params.push_back({p, v});
    sd.modulators.push_back(std::move(md));
    return deltaResult(std::move(sd));
}

/// Build a track-selected delta (changes selectedTrackId in project).
commands::CommandResult selectTrackDelta(const std::string& trackId) {
    snapshot::SnapshotDelta sd;
    snapshot::TrackDelta td;
    td.trackId = trackId;
    td.trackSelected = true;
    sd.tracks.push_back(std::move(td));
    return deltaResult(std::move(sd));
}

} // namespace

void EngineHost::registerAllCommands() {
    auto& reg = commandRegistry_;

    reg.registerCommand("ping", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        return commands::okWithVar(juce::var(ctx.engine.ping()));
    });

    reg.registerCommand("play", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        ctx.engine.setPlaying(true);
        return commands::okResult();
    });

    reg.registerCommand("stop", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        ctx.engine.setPlaying(false);
        return commands::okResult();
    });

    reg.registerCommand("createProject", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        ctx.engine.createProject();
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("getProjectSnapshot", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("getTransportState", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        return commands::rawResult(ctx.engine.getTransportStateJson());
    });

    reg.registerCommand("addTrack", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto name = ctx.args["name"].toString().toStdString();
        ctx.engine.addTrack(name);
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("addGroupTrack", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto name = ctx.args["name"].toString().toStdString();
        ctx.engine.addGroupTrack(name);
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("setTrackGroup", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto trackId = ctx.args["trackId"].toString().toStdString();
        const auto groupTrackId = ctx.args["groupTrackId"].toString().toStdString();
        if (!ctx.engine.setTrackGroup(trackId, groupTrackId))
            return commands::errorResult("invalid_group_assignment");
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("moveTrack", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto trackId = ctx.args["trackId"].toString().toStdString();
        const auto parentGroupId = ctx.args["parentGroupId"].toString().toStdString();
        const auto beforeTrackId = ctx.args["beforeTrackId"].toString().toStdString();
        if (!ctx.engine.moveTrack(trackId, parentGroupId, beforeTrackId))
            return commands::errorResult("invalid_track_move");
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("setTrackMuted", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto trackId = ctx.args["trackId"].toString().toStdString();
        const bool muted = static_cast<bool>(ctx.args["muted"]);
        if (!ctx.engine.setTrackMuted(trackId, muted))
            return commands::errorResult("invalid_track");
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("setTrackSoloed", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto trackId = ctx.args["trackId"].toString().toStdString();
        const bool soloed = static_cast<bool>(ctx.args["soloed"]);
        if (!ctx.engine.setTrackSoloed(trackId, soloed))
            return commands::errorResult("invalid_track");
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("selectTrack", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto trackId = ctx.args["trackId"].toString().toStdString();
        if (!ctx.engine.selectTrack(trackId))
            return commands::errorResult("track_not_found");
        return selectTrackDelta(trackId);
    });

    reg.registerCommand("addDeviceToTrack", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto trackId = ctx.args["trackId"].toString().toStdString();
        const auto deviceType = ctx.args["deviceType"].toString().toStdString();
        const int insertIndex = ctx.args.hasProperty("insertIndex")
            ? static_cast<int>(static_cast<double>(ctx.args["insertIndex"])) : -1;
        if (ctx.engine.addDeviceToTrack(trackId, deviceType, insertIndex).empty())
            return commands::errorResult("track_not_found");
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("removeDeviceFromTrack", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto deviceId = ctx.args["deviceId"].toString().toStdString();
        if (!ctx.engine.removeDeviceFromTrack(deviceId))
            return commands::errorResult("device_not_removable");
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("setDeviceParameter", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto deviceId = ctx.args["deviceId"].toString().toStdString();
        const auto parameterId = ctx.args["parameterId"].toString().toStdString();
        const float value = static_cast<float>(static_cast<double>(ctx.args["value"]));
        if (!ctx.engine.setDeviceParameter(deviceId, parameterId, value))
            return commands::errorResult("invalid_parameter");
        return commands::okResult();
    });

    reg.registerCommand("setMasterGain", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const float gain = static_cast<float>(static_cast<double>(ctx.args["gain"]));
        if (!ctx.engine.setMasterGain(gain))
            return commands::errorResult("invalid_gain");
        return commands::okResult();
    });

    reg.registerCommand("setDeviceStringParameter", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto deviceId = ctx.args["deviceId"].toString().toStdString();
        const auto parameterId = ctx.args["parameterId"].toString().toStdString();
        const auto value = ctx.args["value"].toString().toStdString();
        if (!ctx.engine.setDeviceStringParameter(deviceId, parameterId, value))
            return commands::errorResult("invalid_parameter");
        return commands::okResult();
    });

    reg.registerCommand("setPlayheadBeats", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const double beats = static_cast<double>(ctx.args["playheadBeats"]);
        ctx.engine.setPlayheadBeats(beats);
        return transportDeltaResult([&](snapshot::TransportDelta& td) {
            td.playheadChanged = true;
            td.newPlayhead = beats;
        });
    });

    reg.registerCommand("createMidiClip", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto trackId = ctx.args["trackId"].toString().toStdString();
        const double startBeat = static_cast<double>(ctx.args["startBeat"]);
        const double lengthBeats = static_cast<double>(ctx.args["lengthBeats"]);
        if (ctx.engine.createMidiClip(trackId, startBeat, lengthBeats).empty())
            return commands::errorResult("track_not_found");
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("setMidiClipNotes", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto clipId = ctx.args["clipId"].toString().toStdString();
        // Parse notes from args
        const auto& notesVar = ctx.args["notes"];
        std::vector<MidiNoteState> notes;
        if (auto* arr = notesVar.getArray()) {
            for (const auto& item : *arr) {
                if (auto* obj = item.getDynamicObject()) {
                    MidiNoteState note;
                    note.pitch = static_cast<int>(static_cast<double>(obj->getProperty("pitch")));
                    note.startBeat = static_cast<double>(obj->getProperty("startBeat"));
                    note.durationBeats = static_cast<double>(obj->getProperty("durationBeats"));
                    note.velocity = static_cast<float>(static_cast<double>(obj->getProperty("velocity")));
                    notes.push_back(note);
                }
            }
        }
        if (!ctx.engine.setMidiClipNotes(clipId, notes))
            return commands::errorResult("clip_not_found");
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("createSampleClip", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto trackId = ctx.args["trackId"].toString().toStdString();
        const auto sampleId = ctx.args["sampleId"].toString().toStdString();
        const double startBeat = static_cast<double>(ctx.args["startBeat"]);
        const double lengthBeats = static_cast<double>(ctx.args["lengthBeats"]);
        if (ctx.engine.createSampleClip(trackId, sampleId, startBeat, lengthBeats).empty())
            return commands::errorResult("sample_clip_failed");
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("createAutomationClip", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto trackId = ctx.args["trackId"].toString().toStdString();
        const double startBeat = static_cast<double>(ctx.args["startBeat"]);
        const double lengthBeats = static_cast<double>(ctx.args["lengthBeats"]);
        if (ctx.engine.createAutomationClip(trackId, startBeat, lengthBeats).empty())
            return commands::errorResult("automation_clip_failed");
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("assignAutomationTarget", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto clipId = ctx.args["clipId"].toString().toStdString();
        const auto deviceId = ctx.args["deviceId"].toString().toStdString();
        const auto paramId = ctx.args["paramId"].toString().toStdString();
        if (!ctx.engine.assignAutomationTarget(clipId, deviceId, paramId))
            return commands::errorResult("assign_automation_failed");
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("setAutomationPoints", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto clipId = ctx.args["clipId"].toString().toStdString();
        const auto& pointsVar = ctx.args["points"];
        std::vector<AutomationPointState> points;
        if (auto* arr = pointsVar.getArray()) {
            for (const auto& item : *arr) {
                if (auto* obj = item.getDynamicObject()) {
                    AutomationPointState pt;
                    pt.beat = static_cast<double>(obj->getProperty("beat"));
                    pt.value = static_cast<float>(static_cast<double>(obj->getProperty("value")));
                    points.push_back(pt);
                }
            }
        }
        if (!ctx.engine.setAutomationPoints(clipId, points))
            return commands::errorResult("automation_points_failed");
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("moveClip", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto clipId = ctx.args["clipId"].toString().toStdString();
        const auto trackId = ctx.args["trackId"].toString().toStdString();
        const double startBeat = static_cast<double>(ctx.args["startBeat"]);
        if (!ctx.engine.moveClip(clipId, trackId, startBeat))
            return commands::errorResult("move_clip_failed");
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("setClipLength", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto clipId = ctx.args["clipId"].toString().toStdString();
        const double lengthBeats = static_cast<double>(ctx.args["lengthBeats"]);
        const auto target = clipLengthTargetFromString(
            ctx.args["target"].toString().toStdString());
        if (!ctx.engine.setClipLength(clipId, lengthBeats, target))
            return commands::errorResult("clip_not_found");
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("setClipLoopContent", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto clipId = ctx.args["clipId"].toString().toStdString();
        const auto& loopVar = ctx.args["loopContent"];
        const bool loopContent = loopVar.isBool() ? static_cast<bool>(loopVar)
            : (loopVar.isInt() ? static_cast<int>(loopVar) != 0 : false);
        if (!ctx.engine.setClipLoopContent(clipId, loopContent))
            return commands::errorResult("clip_not_found");
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("setBpm", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const int bpm = static_cast<int>(static_cast<double>(ctx.args["bpm"]));
        if (!ctx.engine.setBpm(bpm))
            return commands::errorResult("invalid_bpm");
        return transportDeltaResult([&](snapshot::TransportDelta& td) {
            td.bpmChanged = true;
            td.newBpm = bpm;
        });
    });

    reg.registerCommand("deleteTrack", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto trackId = ctx.args["trackId"].toString().toStdString();
        if (!ctx.engine.deleteTrack(trackId))
            return commands::errorResult("delete_track_failed");
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("deleteClip", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto clipId = ctx.args["clipId"].toString().toStdString();
        if (!ctx.engine.deleteClip(clipId))
            return commands::errorResult("delete_clip_failed");
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("duplicateClip", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto clipId = ctx.args["clipId"].toString().toStdString();
        if (!ctx.engine.duplicateClip(clipId))
            return commands::errorResult("duplicate_clip_failed");
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("setLoopEnabled", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const bool enabled = static_cast<bool>(ctx.args["enabled"]);
        ctx.engine.setLoopEnabled(enabled);
        return transportDeltaResult([&](snapshot::TransportDelta& td) {
            td.loopEnabledChanged = true;
            td.newLoopEnabled = enabled;
        });
    });

    reg.registerCommand("setLoopLengthBeats", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const double length = static_cast<double>(ctx.args["lengthBeats"]);
        if (!ctx.engine.setLoopLengthBeats(length))
            return commands::errorResult("invalid_loop_length");
        return transportDeltaResult([&](snapshot::TransportDelta& td) {
            td.loopEndChanged = true;
            td.newLoopEnd = length;
        });
    });

    reg.registerCommand("setLoopRegion", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const double startBeat = static_cast<double>(ctx.args["startBeat"]);
        const double endBeat = static_cast<double>(ctx.args["endBeat"]);
        if (!ctx.engine.setLoopRegion(startBeat, endBeat))
            return commands::errorResult("invalid_loop_region");
        return transportDeltaResult([&](snapshot::TransportDelta& td) {
            td.loopStartChanged = true;
            td.newLoopStart = startBeat;
            td.loopEndChanged = true;
            td.newLoopEnd = endBeat;
        });
    });

    reg.registerCommand("setRecordArmed", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const bool armed = static_cast<bool>(ctx.args["armed"]);
        ctx.engine.setRecordArmed(armed);
        return transportDeltaResult([&](snapshot::TransportDelta& td) {
            td.recordArmedChanged = true;
            td.newRecordArmed = armed;
        });
    });

    reg.registerCommand("noteOn", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const int pitch = static_cast<int>(static_cast<double>(ctx.args["pitch"]));
        const float velocity = static_cast<float>(static_cast<double>(ctx.args["velocity"]));
        if (!ctx.engine.noteOn(pitch, velocity))
            return commands::errorResult("note_on_failed");
        return commands::okResult();
    });

    reg.registerCommand("noteOff", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const int pitch = static_cast<int>(static_cast<double>(ctx.args["pitch"]));
        ctx.engine.noteOff(pitch);
        return commands::okResult();
    });

    reg.registerCommand("allNotesOff", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        ctx.engine.allNotesOff();
        return commands::okResult();
    });

    reg.registerCommand("setPitchBend", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const float bend = static_cast<float>(static_cast<double>(ctx.args["bend"]));
        ctx.engine.setPitchBend(bend);
        return commands::okResult();
    });

    reg.registerCommand("setModulation", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const float mod = static_cast<float>(static_cast<double>(ctx.args["mod"]));
        ctx.engine.setModulation(mod);
        return commands::okResult();
    });

    reg.registerCommand("clearCapture", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        ctx.engine.clearCapture();
        return commands::okResult();
    });

    reg.registerCommand("commitCapture", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        if (!ctx.engine.commitCapture())
            return commands::errorResult("capture_failed");
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("createLfo", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const int modType = static_cast<int>(static_cast<double>(ctx.args["modulatorType"]));
        ctx.engine.createLfo(modType);
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("removeLfo", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const int lfoId = static_cast<int>(static_cast<double>(ctx.args["lfoId"]));
        if (!ctx.engine.removeLfo(lfoId))
            return commands::errorResult("lfo_not_found");
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("updateLfoParam", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const int lfoId = static_cast<int>(static_cast<double>(ctx.args["lfoId"]));
        const auto param = ctx.args["param"].toString().toStdString();
        const float value = static_cast<float>(static_cast<double>(ctx.args["value"]));
        if (!ctx.engine.updateLfoParam(lfoId, param, value))
            return commands::errorResult("lfo_param_failed");
        return modulatorParamDelta(lfoId, param, value);
    });

    reg.registerCommand("batchUpdateLfoParams", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const int lfoId = static_cast<int>(static_cast<double>(ctx.args["lfoId"]));
        const auto& paramsVar = ctx.args["params"];
        std::vector<std::pair<std::string, float>> params;
        if (auto* arr = paramsVar.getArray()) {
            for (const auto& item : *arr) {
                if (auto* obj = item.getDynamicObject()) {
                    const auto p = obj->getProperty("param").toString().toStdString();
                    const float v = static_cast<float>(static_cast<double>(obj->getProperty("value")));
                    params.emplace_back(p, v);
                }
            }
        }
        if (!ctx.engine.batchUpdateLfoParams(lfoId, params))
            return commands::errorResult("lfo_param_failed");
        return batchModulatorParamDelta(lfoId, params);
    });

    reg.registerCommand("assignModulation", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const int lfoId = static_cast<int>(static_cast<double>(ctx.args["lfoId"]));
        const auto deviceId = ctx.args["deviceId"].toString().toStdString();
        const auto paramId = ctx.args["paramId"].toString().toStdString();
        const float amount = static_cast<float>(static_cast<double>(ctx.args["amount"]));
        if (!ctx.engine.assignModulation(lfoId, deviceId, paramId, amount))
            return commands::errorResult("modulation_failed");
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("removeModulation", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const int lfoId = static_cast<int>(static_cast<double>(ctx.args["lfoId"]));
        const auto paramId = ctx.args["paramId"].toString().toStdString();
        if (!ctx.engine.removeModulation(lfoId, paramId))
            return commands::errorResult("modulation_remove_failed");
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("applySubtractiveSynthPreset", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        // Parse preset args from JSON
        const auto deviceId = ctx.args["deviceId"].toString().toStdString();
        std::vector<std::pair<std::string, float>> params;
        if (auto* paramsObj = ctx.args["params"].getDynamicObject()) {
            for (const auto& prop : paramsObj->getProperties()) {
                const float v = static_cast<float>(static_cast<double>(prop.value));
                params.emplace_back(prop.name.toString().toStdString(), v);
            }
        }
        std::vector<ProjectEngine::SubtractivePresetLfoSpec> lfos;
        std::vector<ProjectEngine::SubtractivePresetModSpec> mods;
        // (Parse from ctx.args["lfos"] and ctx.args["mods"] — simplified for brevity)
        if (!ctx.engine.applySubtractiveSynthPreset(deviceId, params, lfos, mods))
            return commands::errorResult("preset_apply_failed");
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("enterPlayMode", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        ctx.engine.enterPlayMode();
        return commands::okResult();
    });

    reg.registerCommand("previewSample", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto sampleId = ctx.args["sampleId"].toString().toStdString();
        if (sampleId.empty())
            return commands::errorResult("sample_not_found");
        ctx.engine.previewSample(sampleId);
        return commands::okResult();
    });

    reg.registerCommand("previewMidi", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto& notesVar = ctx.args["notes"];
        std::vector<MidiNoteState> notes;
        if (auto* arr = notesVar.getArray()) {
            for (const auto& item : *arr) {
                if (auto* obj = item.getDynamicObject()) {
                    MidiNoteState n;
                    n.pitch = static_cast<int>(static_cast<double>(obj->getProperty("pitch")));
                    n.startBeat = static_cast<double>(obj->getProperty("startBeat"));
                    n.durationBeats = static_cast<double>(obj->getProperty("durationBeats"));
                    n.velocity = static_cast<float>(static_cast<double>(obj->getProperty("velocity")));
                    notes.push_back(n);
                }
            }
        }
        const double lengthBeats = static_cast<double>(ctx.args["lengthBeats"]);
        const int bpm = static_cast<int>(static_cast<double>(ctx.args["bpm"]));
        const double startBeat = static_cast<double>(ctx.args["startBeat"]);
        const bool loop = static_cast<bool>(ctx.args["loop"]);
        if (notes.empty())
            return commands::okResult();
        ctx.engine.previewMidi(notes, lengthBeats, bpm, startBeat, loop);
        return commands::okResult();
    });

    reg.registerCommand("previewPreset", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto deviceType = ctx.args["deviceType"].toString().toStdString();
        if (deviceType.empty())
            return commands::errorResult("missing_device_type");
        // Parse params from JSON object
        std::vector<std::pair<std::string, float>> params;
        if (auto* paramsObj = ctx.args["params"].getDynamicObject()) {
            for (const auto& prop : paramsObj->getProperties()) {
                const float v = static_cast<float>(static_cast<double>(prop.value));
                params.emplace_back(prop.name.toString().toStdString(), v);
            }
        }
        const auto& notesVar = ctx.args["notes"];
        std::vector<MidiNoteState> notes;
        if (auto* arr = notesVar.getArray()) {
            for (const auto& item : *arr) {
                if (auto* obj = item.getDynamicObject()) {
                    MidiNoteState n;
                    n.pitch = static_cast<int>(static_cast<double>(obj->getProperty("pitch")));
                    n.startBeat = static_cast<double>(obj->getProperty("startBeat"));
                    n.durationBeats = static_cast<double>(obj->getProperty("durationBeats"));
                    n.velocity = static_cast<float>(static_cast<double>(obj->getProperty("velocity")));
                    notes.push_back(n);
                }
            }
        }
        ctx.engine.previewPreset(deviceType, params, notes,
            static_cast<double>(ctx.args["lengthBeats"]),
            static_cast<int>(static_cast<double>(ctx.args["bpm"])),
            static_cast<double>(ctx.args["startBeat"]),
            static_cast<bool>(ctx.args["loop"]));
        return commands::okResult();
    });

    reg.registerCommand("stopPreview", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        ctx.engine.stopPreview();
        return commands::okResult();
    });

    reg.registerCommand("getDeviceStates", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        const auto& idsVar = ctx.args["deviceIds"];
        std::vector<std::string> deviceIds;
        if (auto* arr = idsVar.getArray()) {
            for (const auto& idVar : *arr) {
                deviceIds.push_back(idVar.toString().toStdString());
            }
        }
        return commands::rawResult(ctx.engine.getDeviceConfigsJson(deviceIds));
    });

    reg.registerCommand("getDeviceMeters", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        return commands::rawResult(ctx.engine.getDeviceMetersJson());
    });

    // ── Undo / Redo ──────────────────────────────────────
    reg.registerCommand("undo", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        ctx.engine.undo();
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });

    reg.registerCommand("redo", [](const commands::CommandContext& ctx) -> commands::CommandResult {
        ctx.engine.redo();
        auto snap = juce::JSON::parse(ctx.engine.getProjectSnapshotJson());
        return commands::okWithFullRefresh(snap);
    });
}

} // namespace audioapp
