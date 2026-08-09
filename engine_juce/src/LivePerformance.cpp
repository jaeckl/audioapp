#include "audioapp/LivePerformance.hpp"

#include "audioapp/MasterMix.hpp"
#include "audioapp/MidiUtils.hpp"
#include "audioapp/SamplePlaybackAlgorithm.hpp"
#include "audioapp/SamplerFilter.hpp"
#include "audioapp/KickAlgorithm.hpp"
#include "audioapp/SnareAlgorithm.hpp"
#include "audioapp/ClapAlgorithm.hpp"
#include "audioapp/DedicatedPercussionAlgorithm.hpp"
#include "audioapp/CrashAlgorithm.hpp"
#include "audioapp/SubtractiveSynthAlgorithm.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/GranularAlgorithm.hpp"
#include "audioapp/instruments/PerNoteModulation.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

namespace {

void initSubtractiveVoice(SubtractiveVoiceRuntime& voice, int pitch, float velocity) noexcept {
    voice.active = 1;
    voice.pitch = pitch;
    voice.velocity = velocity;
    voice.targetHz = subtractiveOscPitchHz(pitch, 0.5f, 0.0f, 0.5f);
    voice.currentHz = voice.targetHz;
    voice.noiseSeed = 0.2f + static_cast<float>(pitch) * 0.003f;
    voice.pitchCacheValid = 0;
    voice.controlPitchValid = false;
    voice.cachedKeyTrackAmount = -1.0f;
}

} // namespace

void LivePerformanceMixer::reset() noexcept {
    allNotesOff();
    sampleClock_.store(0, std::memory_order_release);
}

void LivePerformanceMixer::advanceSampleClock(int numFrames) noexcept {
    if (numFrames <= 0) {
        return;
    }
    sampleClock_.fetch_add(static_cast<uint64_t>(numFrames), std::memory_order_relaxed);
}

uint64_t LivePerformanceMixer::sampleClock() const noexcept {
    return sampleClock_.load(std::memory_order_acquire);
}

bool LivePerformanceMixer::hasActiveVoices() const noexcept {
    for (const auto& voice : voices_) {
        if (voice.active.load(std::memory_order_acquire) != 0) {
            return true;
        }
    }
    return false;
}

void LivePerformanceMixer::releaseVoice(LiveVoiceSlot& voice, uint64_t now) noexcept {
    if (voice.active.load(std::memory_order_acquire) == 0) {
        return;
    }
    if (!voice.releasing) {
        voice.releasing = true;
        voice.releaseSample = now;
        if (voice.instrument.kind == LiveInstrumentKind::SubtractiveSynth ||
            voice.instrument.kind == LiveInstrumentKind::BassSynth) {
            voice.subtractiveReleaseSec = static_cast<double>(now) / 48000.0;
        }
        if (voice.instrument.kind == LiveInstrumentKind::PhaseModSynth) {
            voice.phaseMod.releaseBeat = static_cast<double>(now) / 48000.0;
        }
    }
}

int LivePerformanceMixer::noteOn(const LiveInstrumentSnapshot& instrument, int pitch, float velocity) noexcept {
    if (instrument.kind == LiveInstrumentKind::None) {
        return -1;
    }
    const uint64_t now = sampleClock();
    const bool bassMono = instrument.kind == LiveInstrumentKind::BassSynth;

    // Bass is hard-mono live (same as arrangement synthMono). Steal any other
    // bass voice immediately so envelopes never overlap — keeps CPU at 1 voice.
    float bassGlideFromHz = -1.0f;
    if (bassMono) {
        for (auto& voice : voices_) {
            if (voice.active.load(std::memory_order_acquire) == 0) {
                continue;
            }
            if (voice.instrument.kind != LiveInstrumentKind::BassSynth) {
                continue;
            }
            if (bassGlideFromHz < 0.0f) {
                bassGlideFromHz = voice.subtractive.currentHz;
            }
            voice.active.store(0, std::memory_order_release);
            voice.releasing = false;
        }
    }

    for (auto& voice : voices_) {
        if (voice.active.load(std::memory_order_acquire) != 0 && voice.pitch == pitch && !voice.releasing) {
            releaseVoice(voice, now);
        }
    }

    for (int i = 0; i < kLiveMaxVoices; ++i) {
        auto& voice = voices_[i];
        if (voice.active.load(std::memory_order_acquire) != 0) {
            continue;
        }
        voice.instrument = instrument;
        voice.pitch = pitch;
        voice.velocity = std::clamp(velocity, 1.0f, 127.0f);
        voice.startSample = now;
        voice.releaseSample = 0;
        voice.releasing = false;
        voice.oscillatorPhase = 0.0f;
        voice.filterState = BiquadState{};
        voice.filterState2 = BiquadState{};
        voice.wavetableFilterCoeffs = BiquadCoeffs{};
        voice.subtractive = SubtractiveVoiceRuntime{};
        voice.wavetable = WavetableVoiceRuntime{};
        voice.phaseMod = PhaseModSynthVoiceRuntime{};
        voice.kick = KickVoiceRuntime{};
        voice.snare = SnareVoiceRuntime{};
        voice.clap = ClapVoiceRuntime{};
        voice.hihat = HihatVoiceRuntime{};
        voice.ride = RideVoiceRuntime{};
        voice.tom = TomVoiceRuntime{};
        voice.rimshot = RimshotVoiceRuntime{};
        voice.crash = CrashVoiceRuntime{};
        voice.subtractiveStartSec = static_cast<double>(now) / 48000.0;
        voice.subtractiveReleaseSec = -1.0;
        voice.noteModCache.reset();
        if (instrument.kind == LiveInstrumentKind::SubtractiveSynth ||
                instrument.kind == LiveInstrumentKind::BassSynth) {
            initSubtractiveVoice(voice.subtractive, pitch, voice.velocity);
            if (bassMono && bassGlideFromHz > 0.0f && instrument.subtractive.glideMs > 0.0f) {
                voice.subtractive.currentHz = bassGlideFromHz;
            }
        } else if (instrument.kind == LiveInstrumentKind::KickGenerator) {
            triggerKickVoice(voice.kick, pitch, voice.velocity);
        } else if (instrument.kind == LiveInstrumentKind::SnareGenerator) {
            triggerSnareVoice(voice.snare, pitch, voice.velocity);
            configureSnareVoice(voice.snare, instrument.snare, 48000.0f);
        } else if (instrument.kind == LiveInstrumentKind::ClapGenerator) {
            triggerClapVoice(voice.clap, voice.pitch, voice.velocity, instrument.clap);
        } else if (instrument.kind == LiveInstrumentKind::HihatGenerator) {
            triggerHihatVoice(voice.hihat, pitch, voice.velocity);
        } else if (instrument.kind == LiveInstrumentKind::RideGenerator) {
            triggerRideVoice(voice.ride, pitch, voice.velocity);
        } else if (instrument.kind == LiveInstrumentKind::TomGenerator) {
            triggerTomVoice(voice.tom, pitch, voice.velocity);
        } else if (instrument.kind == LiveInstrumentKind::RimshotGenerator) {
            triggerRimshotVoice(voice.rimshot, pitch, voice.velocity);
        } else if (instrument.kind == LiveInstrumentKind::CrashGenerator) {
            triggerCrashVoice(voice.crash, pitch, voice.velocity);
        } else if (instrument.kind == LiveInstrumentKind::PhaseModSynth) {
            voice.phaseMod.active = 1;
            voice.phaseMod.pitch = pitch;
            voice.phaseMod.velocity = voice.velocity;
            voice.phaseMod.startBeat = static_cast<double>(now) / 48000.0;
            voice.phaseMod.releaseBeat = -1.0;
            voice.phaseMod.targetHz = midiNoteToHz(pitch);
            voice.phaseMod.currentHz = voice.phaseMod.targetHz;
        } else if (instrument.kind == LiveInstrumentKind::WavetableSynth) {
            voice.wavetable = WavetableVoiceRuntime{};
            voice.wavetable.pitch = pitch;
            voice.wavetable.velocity = voice.velocity;
            voice.wavetable.noiseSeed =
                0xA341316Cu ^ static_cast<uint32_t>(pitch * 2654435761u);
        }
        voice.active.store(1, std::memory_order_release);
        return i;
    }

    auto& steal = voices_[0];
    steal.active.store(0, std::memory_order_release);
    steal.instrument = instrument;
    steal.pitch = pitch;
    steal.velocity = std::clamp(velocity, 1.0f, 127.0f);
    steal.startSample = now;
    steal.releaseSample = 0;
    steal.releasing = false;
    steal.oscillatorPhase = 0.0f;
    steal.filterState = BiquadState{};
    steal.filterState2 = BiquadState{};
    steal.wavetableFilterCoeffs = BiquadCoeffs{};
    steal.subtractive = SubtractiveVoiceRuntime{};
    steal.wavetable = WavetableVoiceRuntime{};
    steal.phaseMod = PhaseModSynthVoiceRuntime{};
    steal.kick = KickVoiceRuntime{};
    steal.snare = SnareVoiceRuntime{};
    steal.clap = ClapVoiceRuntime{};
    steal.hihat = HihatVoiceRuntime{};
    steal.ride = RideVoiceRuntime{};
    steal.tom = TomVoiceRuntime{};
    steal.rimshot = RimshotVoiceRuntime{};
    steal.crash = CrashVoiceRuntime{};
    steal.subtractiveStartSec = static_cast<double>(now) / 48000.0;
    steal.subtractiveReleaseSec = -1.0;
    if (instrument.kind == LiveInstrumentKind::SubtractiveSynth ||
                instrument.kind == LiveInstrumentKind::BassSynth) {
        initSubtractiveVoice(steal.subtractive, pitch, steal.velocity);
        if (bassMono && bassGlideFromHz > 0.0f && instrument.subtractive.glideMs > 0.0f) {
            steal.subtractive.currentHz = bassGlideFromHz;
        }
    } else if (instrument.kind == LiveInstrumentKind::KickGenerator) {
        triggerKickVoice(steal.kick, pitch, steal.velocity);
    } else if (instrument.kind == LiveInstrumentKind::SnareGenerator) {
        triggerSnareVoice(steal.snare, pitch, steal.velocity);
        configureSnareVoice(steal.snare, instrument.snare, 48000.0f);
    } else if (instrument.kind == LiveInstrumentKind::ClapGenerator) {
        triggerClapVoice(steal.clap, steal.pitch, steal.velocity, instrument.clap);
    } else if (instrument.kind == LiveInstrumentKind::HihatGenerator) {
        triggerHihatVoice(steal.hihat, pitch, steal.velocity);
    } else if (instrument.kind == LiveInstrumentKind::RideGenerator) {
        triggerRideVoice(steal.ride, pitch, steal.velocity);
    } else if (instrument.kind == LiveInstrumentKind::TomGenerator) {
        triggerTomVoice(steal.tom, pitch, steal.velocity);
    } else if (instrument.kind == LiveInstrumentKind::RimshotGenerator) {
        triggerRimshotVoice(steal.rimshot, pitch, steal.velocity);
    } else if (instrument.kind == LiveInstrumentKind::CrashGenerator) {
        triggerCrashVoice(steal.crash, pitch, steal.velocity);
    } else if (instrument.kind == LiveInstrumentKind::PhaseModSynth) {
        steal.phaseMod.active = 1;
        steal.phaseMod.pitch = pitch;
        steal.phaseMod.velocity = steal.velocity;
        steal.phaseMod.startBeat = static_cast<double>(now) / 48000.0;
        steal.phaseMod.releaseBeat = -1.0;
        steal.phaseMod.targetHz = midiNoteToHz(pitch);
        steal.phaseMod.currentHz = steal.phaseMod.targetHz;
    } else if (instrument.kind == LiveInstrumentKind::WavetableSynth) {
        steal.wavetable = WavetableVoiceRuntime{};
        steal.wavetable.pitch = pitch;
        steal.wavetable.velocity = steal.velocity;
        steal.wavetable.noiseSeed =
            0xA341316Cu ^ static_cast<uint32_t>(pitch * 2654435761u);
    }
    steal.active.store(1, std::memory_order_release);
    return 0;
}

void LivePerformanceMixer::noteOff(int pitch) noexcept {
    const uint64_t now = sampleClock();
    for (auto& voice : voices_) {
        if (voice.active.load(std::memory_order_acquire) == 0) {
            continue;
        }
        if (voice.pitch == pitch && !voice.releasing) {
            releaseVoice(voice, now);
        }
    }
}

void LivePerformanceMixer::allNotesOff() noexcept {
    const uint64_t now = sampleClock();
    for (auto& voice : voices_) {
        releaseVoice(voice, now);
    }
}

void LivePerformanceMixer::readMix(float* monoOut, int numFrames, double sampleRate,
                                   IModulator* const* modulators,
                                   int modulatorCount,
                                   int bpm) noexcept {
    if (monoOut == nullptr || numFrames <= 0 || sampleRate <= 0.0) {
        return;
    }

    const uint64_t blockStart = sampleClock();

    for (int frame = 0; frame < numFrames; ++frame) {
        const uint64_t sampleIndex = blockStart + static_cast<uint64_t>(frame);
        float mix = 0.0f;

        for (auto& voice : voices_) {
            if (voice.active.load(std::memory_order_acquire) == 0) {
                continue;
            }

            const auto& inst = voice.instrument;
            const double perNoteElapsed =
                static_cast<double>(sampleIndex - voice.startSample) / sampleRate;
            const NoteModKey noteKey{voice.pitch,
                                     static_cast<double>(voice.startSample), 0.0};
            InstrumentModulationContext modCtx{};
            modCtx.lfoCount = modulatorCount;
            modCtx.modEdges = inst.modEdges;
            modCtx.modEdgeCount = inst.modEdgeCount;
            modCtx.deviceIndex = inst.deviceIndex;
            modCtx.modulators = modulators;
            modCtx.playheadStartBeat = 0.0;
            modCtx.bpm = bpm;
            modCtx.sampleRate = sampleRate;
            modCtx.noteCache = &voice.noteModCache;
            ModulationEvalContext evalCtx{};
            evalCtx.bpm = bpm;
            evalCtx.sampleRate = sampleRate;
            evalCtx.playheadSeconds = static_cast<double>(sampleIndex) / sampleRate;
            evalCtx.frameIndex = frame;
            evalCtx.numFrames = numFrames;
            double perNoteDuration = 3600.0;
            if (voice.releasing && voice.releaseSample > voice.startSample) {
                perNoteDuration =
                    static_cast<double>(voice.releaseSample - voice.startSample) / sampleRate;
            }
            float perNoteGain = applyPerNoteCommonGain(
                inst.gain, inst.deviceIndex, perNoteElapsed, perNoteDuration,
                noteKey, evalCtx, modCtx);

            if (inst.kind == LiveInstrumentKind::KickGenerator) {
                auto& kv = voice.kick;
                const double elapsedSec =
                    static_cast<double>(sampleIndex - voice.startSample) / sampleRate;
                if (elapsedSec < 0.0) {
                    continue;
                }
                if (kv.active == 0) {
                    triggerKickVoice(kv, voice.pitch, voice.velocity);
                }
                kv.elapsedSec = elapsedSec;
                const float vel = std::clamp(voice.velocity / 127.0f, 0.0f, 1.0f);
                const float velGain = 1.0f - inst.kick.kickVelocity * (1.0f - vel);
                mix += kickGeneratorSample(kv, inst.kick, sampleRate, velGain);
                if (kv.active == 0) {
                    voice.active.store(0, std::memory_order_release);
                }
                continue;
            }

            if (inst.kind == LiveInstrumentKind::SnareGenerator) {
                auto& sv = voice.snare;
                const double elapsedSec =
                    static_cast<double>(sampleIndex - voice.startSample) / sampleRate;
                if (elapsedSec < 0.0) {
                    continue;
                }
                if (sv.active == 0) {
                    triggerSnareVoice(sv, voice.pitch, voice.velocity);
                    configureSnareVoice(sv, inst.snare, static_cast<float>(sampleRate));
                }
                sv.elapsedSec = elapsedSec;
                const float vel = std::clamp(voice.velocity / 127.0f, 0.0f, 1.0f);
                const float velGain = 1.0f - inst.snare.snareVelocity * (1.0f - vel);
                mix += snareGeneratorSample(sv, inst.snare, sampleRate, velGain);
                if (sv.active == 0) {
                    voice.active.store(0, std::memory_order_release);
                }
                continue;
            }

            if (inst.kind == LiveInstrumentKind::ClapGenerator) {
                auto& cv = voice.clap;
                const double elapsedSec =
                    static_cast<double>(sampleIndex - voice.startSample) / sampleRate;
                if (elapsedSec < 0.0) {
                    continue;
                }
                if (cv.active == 0) {
                    triggerClapVoice(cv, voice.pitch, voice.velocity, inst.clap);
                }
                cv.elapsedSec = elapsedSec;
                const float vel = std::clamp(voice.velocity / 127.0f, 0.0f, 1.0f);
                const float velGain = 0.5f + vel * 0.5f;
                mix += clapGeneratorSample(cv, inst.clap, sampleRate, velGain);
                if (cv.active == 0) {
                    voice.active.store(0, std::memory_order_release);
                }
                continue;
            }

            if (inst.kind == LiveInstrumentKind::HihatGenerator) {
                auto& cyv = voice.hihat;
                const double elapsedSec =
                    static_cast<double>(sampleIndex - voice.startSample) / sampleRate;
                if (elapsedSec < 0.0) {
                    continue;
                }
                if (cyv.active == 0) {
                    triggerHihatVoice(cyv, voice.pitch, voice.velocity);
                }
                cyv.elapsedSec = elapsedSec;
                const float vel = std::clamp(voice.velocity / 127.0f, 0.0f, 1.0f);
                const float velGain = 1.0f - inst.hihat.hihatVelocity * (1.0f - vel);
                mix += (hihatSampleL(cyv, inst.hihat, sampleRate, velGain) +
                        hihatSampleR(cyv, inst.hihat, sampleRate, velGain)) * 0.5f;
                if (cyv.active == 0) {
                    voice.active.store(0, std::memory_order_release);
                }
                continue;
            }

            if (inst.kind == LiveInstrumentKind::RideGenerator) {
                auto& v = voice.ride; const double t = static_cast<double>(sampleIndex - voice.startSample) / sampleRate;
                if (v.active == 0) triggerRideVoice(v, voice.pitch, voice.velocity); v.elapsedSec = t;
                const float vel = std::clamp(voice.velocity / 127.0f, 0.0f, 1.0f);
                const float vg = 1.0f - inst.ride.rideVelocity * (1.0f - vel);
                mix += (rideSampleL(v, inst.ride, sampleRate, vg) + rideSampleR(v, inst.ride, sampleRate, vg)) * .5f;
                if (v.active == 0) voice.active.store(0, std::memory_order_release); continue;
            }
            if (inst.kind == LiveInstrumentKind::TomGenerator) {
                auto& v = voice.tom; const double t = static_cast<double>(sampleIndex - voice.startSample) / sampleRate;
                if (v.active == 0) triggerTomVoice(v, voice.pitch, voice.velocity); v.elapsedSec = t;
                const float vel = std::clamp(voice.velocity / 127.0f, 0.0f, 1.0f);
                const float vg = 1.0f - inst.tom.tomVelocity * (1.0f - vel);
                mix += tomSampleL(v, inst.tom, sampleRate, vg);
                if (v.active == 0) voice.active.store(0, std::memory_order_release); continue;
            }
            if (inst.kind == LiveInstrumentKind::RimshotGenerator) {
                auto& v = voice.rimshot; const double t = static_cast<double>(sampleIndex - voice.startSample) / sampleRate;
                if (v.active == 0) triggerRimshotVoice(v, voice.pitch, voice.velocity); v.elapsedSec = t;
                const float vel = std::clamp(voice.velocity / 127.0f, 0.0f, 1.0f);
                const float vg = 1.0f - inst.rimshot.rimshotVelocity * (1.0f - vel);
                mix += rimshotSampleL(v, inst.rimshot, sampleRate, vg);
                if (v.active == 0) voice.active.store(0, std::memory_order_release); continue;
            }

            if (inst.kind == LiveInstrumentKind::CrashGenerator) {
                auto& crv = voice.crash;
                const double elapsedSec =
                    static_cast<double>(sampleIndex - voice.startSample) / sampleRate;
                if (elapsedSec < 0.0) {
                    continue;
                }
                if (crv.active == 0) {
                    triggerCrashVoice(crv, voice.pitch, voice.velocity);
                }
                crv.elapsedSec = elapsedSec;
                const float vel = std::clamp(voice.velocity / 127.0f, 0.0f, 1.0f);
                const float velGain = 1.0f - inst.crash.crashVelocity * (1.0f - vel);
                mix += (crashGeneratorSampleL(crv, inst.crash, sampleRate, velGain) +
                        crashGeneratorSampleR(crv, inst.crash, sampleRate, velGain)) * 0.5f;
                if (crv.active == 0) {
                    voice.active.store(0, std::memory_order_release);
                }
                continue;
            }

            if (inst.kind == LiveInstrumentKind::PhaseModSynth) {
                auto& pmv = voice.phaseMod;
                const uint64_t now = sampleIndex;
                const double secElapsed =
                    static_cast<double>(now - voice.startSample) / sampleRate;
                if (secElapsed < 0.0) {
                    continue;
                }
                double noteDurSec = 3600.0;
                if (voice.releasing && voice.releaseSample > voice.startSample) {
                    noteDurSec = static_cast<double>(voice.releaseSample - voice.startSample) / sampleRate;
                }
                auto baseParams = inst.phaseMod;
                baseParams.gain = 1.0f;
                DeviceVariantParams variant = baseParams;
                applyPerNoteDspModulation(variant, DeviceNodeKind::PhaseModSynth,
                                          inst.deviceIndex, secElapsed, perNoteDuration, noteKey,
                                          evalCtx, modCtx);
                const auto params = std::get<PhaseModSynthParams>(variant);
                float voiceMix = 0.0f;
                renderPhaseModLiveVoice(voiceMix, pmv, params,
                                        sampleRate, secElapsed, noteDurSec);
                mix += voiceMix * perNoteGain;
                if (pmv.active == 0) {
                    voice.active.store(0, std::memory_order_release);
                }
                continue;
            }

            if (inst.kind == LiveInstrumentKind::WavetableSynth) {
                if (inst.wavetablePcm == nullptr || inst.wavetablePcmFrameCount <= 0) {
                    voice.active.store(0, std::memory_order_release);
                    continue;
                }
                const double elapsedSec =
                    static_cast<double>(sampleIndex - voice.startSample) / sampleRate;
                if (elapsedSec < 0.0) {
                    continue;
                }

                auto baseParams = wavetableRealtimeParams(inst.wavetable);
                baseParams.gain = 1.0f;
                DeviceVariantParams variant = baseParams;
                applyPerNoteDspModulation(variant, DeviceNodeKind::WavetableSynth,
                                          inst.deviceIndex, elapsedSec, perNoteDuration, noteKey,
                                          evalCtx, modCtx);
                const auto params = std::get<WavetableSynthParamsPlayback>(variant);
                const float ampAttackSec = adsrNormalizedToSeconds(params.ampAttack, 2.0f);
                const float ampDecaySec = adsrNormalizedToSeconds(params.ampDecay, 2.0f);
                const float ampReleaseSec = adsrNormalizedToSeconds(params.ampRelease, 3.0f);
                const float ampSustain = std::clamp(params.ampSustain, 0.0f, 1.0f);

                const float filterAttackSec = adsrNormalizedToSeconds(params.filterAttack, 2.0f);
                const float filterDecaySec = adsrNormalizedToSeconds(params.filterDecay, 2.0f);
                const float filterReleaseSec = adsrNormalizedToSeconds(params.filterRelease, 3.0f);
                const float filterSustain = std::clamp(params.filterSustain, 0.0f, 1.0f);

                float noteDurationSec = 3600.0f;
                if (voice.releasing && voice.releaseSample >= voice.startSample) {
                    noteDurationSec = static_cast<float>(
                        static_cast<double>(voice.releaseSample - voice.startSample) / sampleRate);
                }

                const float ampGain = samplerAdsrGain(static_cast<float>(elapsedSec),
                                                      noteDurationSec,
                                                      ampAttackSec, ampDecaySec,
                                                      ampSustain, ampReleaseSec);
                if (ampGain <= 0.0f) {
                    if (voice.releasing) {
                        voice.active.store(0, std::memory_order_release);
                    }
                    continue;
                }

                const float filterGain = samplerAdsrGain(static_cast<float>(elapsedSec),
                                                         noteDurationSec,
                                                         filterAttackSec, filterDecaySec,
                                                         filterSustain, filterReleaseSec);

                const float wtPos = params.wtPosition *
                    static_cast<float>(std::max(inst.wavetablePcmFrameCount - 1, 1));
                const float vel = std::clamp(voice.velocity / 127.0f, 0.0f, 1.0f);
                voice.wavetable.pitch = voice.pitch;

                mix += wavetableVoiceSample(params,
                                            inst.wavetablePcm,
                                            inst.wavetablePcmFrameCount,
                                            inst.wavetablePcmFrameLength,
                                            voice.wavetable,
                                            wtPos,
                                            sampleRate,
                                            ampGain * vel,
                                            filterGain,
                                            voice.wavetableFilterCoeffs,
                                            voice.filterState,
                                            voice.filterState2,
                                            params.filterMode,
                                            params.filterResonance) *
                       perNoteGain * kInstrumentOutputGain;
                continue;
            }

            if (inst.kind == LiveInstrumentKind::Granular) {
                const double elapsed =
                    static_cast<double>(sampleIndex - voice.startSample) / sampleRate;
                if (elapsed < 0.0) continue;
                auto params = inst.granular;
                DeviceVariantParams variant = params;
                applyPerNoteDspModulation(variant, DeviceNodeKind::Granular,
                                          inst.deviceIndex, elapsed, perNoteDuration, noteKey,
                                          evalCtx, modCtx);
                params = std::get<GranularParams>(variant);
                params.pcm = inst.granular.pcm;
                params.frameCount = inst.granular.frameCount;
                params.pcmRate = inst.granular.pcmRate;
                if (params.pcm == nullptr || params.frameCount < 4) {
                    voice.active.store(0, std::memory_order_release);
                    continue;
                }
                double noteDuration = 3600.0;
                if (voice.releasing && voice.releaseSample >= voice.startSample) {
                    noteDuration = static_cast<double>(voice.releaseSample - voice.startSample) /
                                   sampleRate;
                }
                const float attackSec = 0.002f + params.attack * params.attack * 1.5f;
                const float releaseSec = 0.015f + params.release * params.release * 2.0f;
                if (elapsed > noteDuration + releaseSec) {
                    if (voice.releasing) voice.active.store(0, std::memory_order_release);
                    continue;
                }
                if (elapsed >= attackSec && elapsed > noteDuration) {
                    const float envTail = 1.0f - static_cast<float>((elapsed - noteDuration) / releaseSec);
                    if (envTail <= 0.0f) {
                        if (voice.releasing) voice.active.store(0, std::memory_order_release);
                        continue;
                    }
                }
                mix += granularLiveVoiceSample(params,
                                               voice.pitch,
                                               voice.velocity,
                                               elapsed,
                                               noteDuration,
                                               sampleRate,
                                               voice.granularZ1,
                                               voice.granularZ2) *
                       perNoteGain;
                continue;
            }

            const double elapsedSec =
                static_cast<double>(sampleIndex - voice.startSample) / sampleRate;
            if (elapsedSec < 0.0) {
                continue;
            }

            const float attackSec = adsrNormalizedToSeconds(inst.attack, 2.0f);
            const float decaySec = adsrNormalizedToSeconds(inst.decay, 2.0f);
            const float releaseSec = adsrNormalizedToSeconds(inst.release, 3.0f);
            const float sustainLevel = std::clamp(inst.sustain, 0.0f, 1.0f);

            float noteDurationSec = 3600.0f;
            if (voice.releasing && voice.releaseSample >= voice.startSample) {
                noteDurationSec = static_cast<float>(
                    static_cast<double>(voice.releaseSample - voice.startSample) / sampleRate);
            }

            const float envGain = samplerAdsrGain(elapsedSec,
                                                  noteDurationSec,
                                                  attackSec,
                                                  decaySec,
                                                  sustainLevel,
                                                  releaseSec);
            if (envGain <= 0.0f) {
                if (voice.releasing) {
                    voice.active.store(0, std::memory_order_release);
                }
                continue;
            }

            const float velGain = (voice.velocity / 100.0f) * inst.gain * kInstrumentOutputGain;

            if (inst.kind == LiveInstrumentKind::SubtractiveSynth ||
                inst.kind == LiveInstrumentKind::BassSynth) {
                auto baseParams = inst.subtractive;
                baseParams.gain = 1.0f;
                DeviceVariantParams variant = baseParams;
                applyPerNoteDspModulation(variant,
                                          inst.kind == LiveInstrumentKind::BassSynth
                                              ? DeviceNodeKind::BassSynth
                                              : DeviceNodeKind::SubtractiveSynth,
                                          inst.deviceIndex, perNoteElapsed, perNoteDuration, noteKey,
                                          evalCtx, modCtx);
                auto params = std::get<SubtractiveSynthParams>(variant);
                // Live keyboard path: lean caps for small realtime callbacks.
                int voiceCap = kSubtractiveMaxVoices;
                applySubtractiveRealtimeCaps(params, numFrames, voiceCap);
                (void)voiceCap;

                auto& sv = voice.subtractive;
                const uint64_t localSample = sampleIndex - voice.startSample;
                const bool refreshControl =
                    (localSample % static_cast<uint64_t>(kSubtractiveControlSubBlockFrames)) == 0 ||
                    !sv.controlPitchValid;
                if (refreshControl) {
                    refreshSubtractiveControlCaches(sv, params, sampleRate);
                }

                const double voiceElapsed =
                    static_cast<double>(sampleIndex - voice.startSample) / sampleRate;
                float noteDurationSec = 3600.0f;
                if (voice.releasing && voice.releaseSample >= voice.startSample) {
                    noteDurationSec = static_cast<float>(
                        static_cast<double>(voice.releaseSample - voice.startSample) / sampleRate);
                }

                const float ampGain = samplerAdsrGain(static_cast<float>(voiceElapsed),
                                                      noteDurationSec,
                                                      sv.cachedAmpAttackSec,
                                                      sv.cachedAmpDecaySec,
                                                      sv.cachedAmpSustain,
                                                      sv.cachedAmpReleaseSec);
                if (ampGain <= 0.0f) {
                    if (voice.releasing) {
                        voice.active.store(0, std::memory_order_release);
                    }
                    continue;
                }

                const float filterGain = samplerAdsrGain(static_cast<float>(voiceElapsed),
                                                         noteDurationSec,
                                                         sv.cachedFilterAttackSec,
                                                         sv.cachedFilterDecaySec,
                                                         sv.cachedFilterSustain,
                                                         sv.cachedFilterReleaseSec);
                const float vel = std::clamp(voice.velocity / 127.0f, 0.0f, 1.0f);
                const float velAmount =
                    1.0f - params.velocitySensitivity * (1.0f - vel);

                sv.pitch = voice.pitch;
                sv.velocity = voice.velocity;
                mix += subtractiveVoiceSample(sv,
                                                params,
                                                ampGain * velAmount,
                                                filterGain,
                                                sampleRate,
                                                sv.cachedGlideCoeff,
                                                refreshControl) *
                        perNoteGain * kInstrumentOutputGain;
            } else if (inst.kind == LiveInstrumentKind::Oscillator) {
                const float hz = midiNoteToHz(voice.pitch);
                const float phaseInc = static_cast<float>(2.0 * 3.14159265358979323846 * hz / sampleRate);
                const float sample = std::sin(voice.oscillatorPhase) * envGain * velGain;
                voice.oscillatorPhase += phaseInc;
                if (voice.oscillatorPhase > 6.28318530718f) {
                    voice.oscillatorPhase -= 6.28318530718f;
                }
                mix += sample * perNoteGain;
            } else if (inst.kind == LiveInstrumentKind::Sampler && inst.samplerPcm != nullptr &&
                       inst.samplerFrameCount > 1) {
                const float filterAttackSec = adsrNormalizedToSeconds(inst.filterAttack, 2.0f);
                const float filterDecaySec = adsrNormalizedToSeconds(inst.filterDecay, 2.0f);
                const float filterReleaseSec = adsrNormalizedToSeconds(inst.filterRelease, 3.0f);
                const float filterSustainLevel = std::clamp(inst.filterSustain, 0.0f, 1.0f);

                float noteDurationSec = 3600.0f;
                if (voice.releasing && voice.releaseSample >= voice.startSample) {
                    noteDurationSec = static_cast<float>(
                        static_cast<double>(voice.releaseSample - voice.startSample) / sampleRate);
                }

                const float filterGain = samplerAdsrGain(elapsedSec,
                                                         noteDurationSec,
                                                         filterAttackSec,
                                                         filterDecaySec,
                                                         filterSustainLevel,
                                                         filterReleaseSec);

                const int startFrame = inst.trimStartFrame;
                const int endFrame =
                    inst.trimEndFrame > startFrame ? inst.trimEndFrame : inst.samplerFrameCount;
                if (endFrame - startFrame <= 1) {
                    continue;
                }

                const double pitchRatio =
                    samplerPitchRatio(voice.pitch, inst.rootPitch, inst.rootFineTune);

                double readPos = 0.0;
                if (!computeSamplerReadPosition(inst.playbackMode,
                                                startFrame,
                                                endFrame,
                                                inst.regionStartFrame,
                                                inst.regionEndFrame,
                                                elapsedSec,
                                                inst.samplerPcmSampleRate,
                                                pitchRatio,
                                                readPos)) {
                    if (voice.releasing && elapsedSec > noteDurationSec + releaseSec) {
                        voice.active.store(0, std::memory_order_release);
                    }
                    continue;
                }
                const int index = static_cast<int>(readPos);
                const float frac = static_cast<float>(readPos - static_cast<double>(index));
                const int next = std::min(index + 1, inst.samplerFrameCount - 1);
                float sample = inst.samplerPcm[index] * (1.0f - frac) + inst.samplerPcm[next] * frac;
                sample = processSamplerFilteredSample(sample,
                                                      voice.filterState,
                                                      inst.filterMode,
                                                      static_cast<float>(sampleRate),
                                                      inst.filterCutoff,
                                                      inst.filterQ,
                                                      filterGain,
                                                      inst.filterEnvAmount);
                mix += sample * envGain * velGain * perNoteGain;
            }
        }

        monoOut[frame] += mix;
    }
}

} // namespace audioapp
