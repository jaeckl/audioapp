#include "audioapp/LivePerformance.hpp"

#include "audioapp/MasterMix.hpp"
#include "audioapp/MidiUtils.hpp"
#include "audioapp/SamplePlaybackAlgorithm.hpp"
#include "audioapp/SamplerFilter.hpp"
#include "audioapp/KickAlgorithm.hpp"
#include "audioapp/SnareAlgorithm.hpp"
#include "audioapp/ClapAlgorithm.hpp"
#include "audioapp/CymbalAlgorithm.hpp"
#include "audioapp/CrashAlgorithm.hpp"
#include "audioapp/SubtractiveSynthAlgorithm.hpp"
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
    const bool subtractive = instrument.kind == LiveInstrumentKind::SubtractiveSynth ||
                             instrument.kind == LiveInstrumentKind::BassSynth;

    // Live keyboard stays polyphonic; synthMono only affects clip/arrangement playback.
    (void)subtractive;

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
        voice.phaseMod = PhaseModSynthVoiceRuntime{};
        voice.kick = KickVoiceRuntime{};
        voice.snare = SnareVoiceRuntime{};
        voice.clap = ClapVoiceRuntime{};
        voice.cymbal = CymbalVoiceRuntime{};
        voice.crash = CrashVoiceRuntime{};
        voice.subtractiveStartSec = static_cast<double>(now) / 48000.0;
        voice.subtractiveReleaseSec = -1.0;
        voice.noteModCache.reset();
        if (instrument.kind == LiveInstrumentKind::SubtractiveSynth ||
                instrument.kind == LiveInstrumentKind::BassSynth) {
            initSubtractiveVoice(voice.subtractive, pitch, voice.velocity);
        } else if (instrument.kind == LiveInstrumentKind::KickGenerator) {
            triggerKickVoice(voice.kick, pitch, voice.velocity);
        } else if (instrument.kind == LiveInstrumentKind::SnareGenerator) {
            triggerSnareVoice(voice.snare, pitch, voice.velocity);
            configureSnareVoice(voice.snare, instrument.snare, 48000.0f);
        } else if (instrument.kind == LiveInstrumentKind::ClapGenerator) {
            triggerClapVoice(voice.clap, voice.velocity, instrument.clap);
        } else if (instrument.kind == LiveInstrumentKind::CymbalGenerator) {
            triggerCymbalVoice(voice.cymbal, pitch, voice.velocity);
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
    steal.phaseMod = PhaseModSynthVoiceRuntime{};
    steal.kick = KickVoiceRuntime{};
    steal.snare = SnareVoiceRuntime{};
    steal.clap = ClapVoiceRuntime{};
    steal.cymbal = CymbalVoiceRuntime{};
    steal.crash = CrashVoiceRuntime{};
    steal.subtractiveStartSec = static_cast<double>(now) / 48000.0;
    steal.subtractiveReleaseSec = -1.0;
    if (instrument.kind == LiveInstrumentKind::SubtractiveSynth ||
                instrument.kind == LiveInstrumentKind::BassSynth) {
        initSubtractiveVoice(steal.subtractive, pitch, steal.velocity);
    } else if (instrument.kind == LiveInstrumentKind::KickGenerator) {
        triggerKickVoice(steal.kick, pitch, steal.velocity);
    } else if (instrument.kind == LiveInstrumentKind::SnareGenerator) {
        triggerSnareVoice(steal.snare, pitch, steal.velocity);
        configureSnareVoice(steal.snare, instrument.snare, 48000.0f);
    } else if (instrument.kind == LiveInstrumentKind::ClapGenerator) {
        triggerClapVoice(steal.clap, steal.velocity, instrument.clap);
    } else if (instrument.kind == LiveInstrumentKind::CymbalGenerator) {
        triggerCymbalVoice(steal.cymbal, pitch, steal.velocity);
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
            float perNoteGain = applyPerNoteCommonGain(
                inst.gain, inst.deviceIndex, perNoteElapsed, noteKey, evalCtx, modCtx);

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
                    triggerClapVoice(cv, voice.velocity, inst.clap);
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

            if (inst.kind == LiveInstrumentKind::CymbalGenerator) {
                auto& cyv = voice.cymbal;
                const double elapsedSec =
                    static_cast<double>(sampleIndex - voice.startSample) / sampleRate;
                if (elapsedSec < 0.0) {
                    continue;
                }
                if (cyv.active == 0) {
                    triggerCymbalVoice(cyv, voice.pitch, voice.velocity);
                }
                cyv.elapsedSec = elapsedSec;
                const float vel = std::clamp(voice.velocity / 127.0f, 0.0f, 1.0f);
                const float velGain = 1.0f - inst.cymbal.cymbalVelocity * (1.0f - vel);
                mix += (cymbalGeneratorSampleL(cyv, inst.cymbal, sampleRate, velGain) +
                        cymbalGeneratorSampleR(cyv, inst.cymbal, sampleRate, velGain)) * 0.5f;
                if (cyv.active == 0) {
                    voice.active.store(0, std::memory_order_release);
                }
                continue;
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
                                          inst.deviceIndex, secElapsed, noteKey,
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

                auto baseParams = inst.wavetable;
                baseParams.gain = 1.0f;
                DeviceVariantParams variant = baseParams;
                applyPerNoteDspModulation(variant, DeviceNodeKind::WavetableSynth,
                                          inst.deviceIndex, elapsedSec, noteKey,
                                          evalCtx, modCtx);
                const auto params = std::get<WavetableSynthParams>(variant);
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

                const float hz = midiNoteToHz(voice.pitch);
                const float wtPos = params.wtPosition *
                    static_cast<float>(std::max(inst.wavetablePcmFrameCount - 1, 1));
                const float vel = std::clamp(voice.velocity / 127.0f, 0.0f, 1.0f);

                mix += wavetableVoiceSample(params,
                                            inst.wavetablePcm,
                                            inst.wavetablePcmFrameCount,
                                            inst.wavetablePcmFrameLength,
                                            voice.oscillatorPhase,
                                            wtPos, hz,
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
                                          inst.deviceIndex, elapsed, noteKey,
                                          evalCtx, modCtx);
                params = std::get<GranularParams>(variant);
                if (params.pcm == nullptr || params.frameCount < 4) {
                    voice.active.store(0, std::memory_order_release);
                    continue;
                }
                double noteDuration = 3600.0;
                if (voice.releasing && voice.releaseSample >= voice.startSample) {
                    noteDuration = static_cast<double>(voice.releaseSample - voice.startSample) /
                                   sampleRate;
                }
                const float attackSec = .002f + params.attack * params.attack * 1.5f;
                const float releaseSec = .015f + params.release * params.release * 2.0f;
                const float envelope = elapsed < attackSec
                    ? static_cast<float>(elapsed / attackSec)
                    : (elapsed <= noteDuration ? 1.0f
                       : std::max(0.0f, 1.0f - static_cast<float>((elapsed-noteDuration)/releaseSec)));
                if (envelope <= 0.0f) {
                    if (voice.releasing) voice.active.store(0, std::memory_order_release);
                    continue;
                }
                constexpr float pi = 3.14159265358979323846f;
                constexpr float vowels[6][3] = {
                    {800,1150,2900},{400,1700,2600},{350,2000,2800},
                    {450,800,2830},{325,700,2530},{500,1200,2400}};
                constexpr float formPoints[6][2] = {
                    {.5f,.05f},{.88f,.25f},{.88f,.75f},{.12f,.25f},{.12f,.75f},{.5f,.95f}};
                float blendedFormants[3]{};
                float formWeightSum=0.0f;
                for(int form=0;form<6;++form){const float dx=params.formX-formPoints[form][0];const float dy=params.formY-formPoints[form][1];const float weight=std::exp(-(dx*dx+dy*dy)/.075f);formWeightSum+=weight;for(int band=0;band<3;++band)blendedFormants[band]+=vowels[form][band]*weight;}
                for(auto& frequency:blendedFormants)frequency/=std::max(formWeightSum,.0001f);
                const double regionStart = std::clamp(static_cast<double>(params.regionStart),0.0,.98);
                const double regionEnd = std::clamp(static_cast<double>(params.regionEnd),regionStart+.02,1.0);
                const double regionLength = regionEnd-regionStart;
                const float density = 5.0f+params.density*39.0f;
                const float grainSec = .012f+params.size*.18f;
                const double ratio = std::pow(2.0,((voice.pitch-60)+(params.pitch-.5f)*48.0f)/12.0)
                    * params.pcmRate/sampleRate;
                float source = 0.0f;
                int activeGrains = 0;
                const auto newestGrain=static_cast<int64_t>(std::floor(elapsed*density));
                for (int grain=0;grain<8;++grain) {
                    const int64_t number=newestGrain-grain;
                    if(number<0) continue;
                    const double spawnTime=number/density;
                    const double age=elapsed-spawnTime;
                    if(age<0.0||age>=grainSec) continue;
                    const double phase=age/grainSec;
                    const double random=std::sin((number+voice.pitch*17.0)*12.9898);
                    const double scan=regionStart+regionLength*std::fmod(
                        params.position+spawnTime*(params.scan-.5f)*.35+4.0,1.0);
                    const double start=std::clamp(scan+random*params.spray*regionLength*.14,
                                                  regionStart,regionEnd)*params.frameCount;
                    const double first=regionStart*(params.frameCount-1);
                    const double span=std::max(2.0,regionLength*(params.frameCount-1));
                    double pos=first+std::fmod(std::max(0.0,start+phase*grainSec*sampleRate*ratio-first),span);
                    const int index=std::min(static_cast<int>(pos),params.frameCount-2);
                    const float fraction=static_cast<float>(pos-index);
                    const float sample=params.pcm[index]*(1.0f-fraction)+params.pcm[index+1]*fraction;
                    source+=sample*(.5f-.5f*std::cos(static_cast<float>(phase)*2.0f*pi));
                    ++activeGrains;
                }
                if(activeGrains>0) source*=.7f/std::sqrt(static_cast<float>(activeGrains));
                float shaped=0.0f;
                const float shift=std::pow(2.0f,(params.formant-.5f)*2.0f);
                for (int band=0;band<3;++band) {
                    const float hz=std::min(blendedFormants[band]*shift,static_cast<float>(sampleRate)*.42f);
                    const float radius=.94f+params.character*.045f;
                    const float coefficient=2.0f*radius*std::cos(2.0f*pi*hz/static_cast<float>(sampleRate));
                    const float value=(1.0f-radius)*source+coefficient*voice.granularZ1[band]
                        -radius*radius*voice.granularZ2[band];
                    voice.granularZ2[band]=voice.granularZ1[band];
                    voice.granularZ1[band]=value;
                    shaped+=value;
                }
                const float velocity=std::clamp(voice.velocity/127.0f,0.0f,1.0f);
                const float formWet=std::sqrt(std::clamp(params.character,0.0f,1.0f));
                mix+=(source*(1-formWet)+shaped*formWet*2.1f)
                    * envelope*velocity*perNoteGain*.36f;
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
                                          inst.deviceIndex, perNoteElapsed, noteKey,
                                          evalCtx, modCtx);
                const auto params = std::get<SubtractiveSynthParams>(variant);
                const float ampAttackSec = adsrNormalizedToSeconds(params.ampAttack, 2.0f);
                const float ampDecaySec = adsrNormalizedToSeconds(params.ampDecay, 2.0f);
                const float ampReleaseSec = adsrNormalizedToSeconds(params.ampRelease, 3.0f);
                const float ampSustain = std::clamp(params.ampSustain, 0.0f, 1.0f);
                const float filterAttackSec = adsrNormalizedToSeconds(params.filterAttack, 2.0f);
                const float filterDecaySec = adsrNormalizedToSeconds(params.filterDecay, 2.0f);
                const float filterReleaseSec = adsrNormalizedToSeconds(params.filterRelease, 3.0f);
                const float filterSustain = std::clamp(params.filterSustain, 0.0f, 1.0f);

                const double voiceElapsed =
                    static_cast<double>(sampleIndex - voice.startSample) / sampleRate;
                float noteDurationSec = 3600.0f;
                if (voice.releasing && voice.releaseSample >= voice.startSample) {
                    noteDurationSec = static_cast<float>(
                        static_cast<double>(voice.releaseSample - voice.startSample) / sampleRate);
                }

                const float ampGain = samplerAdsrGain(static_cast<float>(voiceElapsed),
                                                      noteDurationSec,
                                                      ampAttackSec,
                                                      ampDecaySec,
                                                      ampSustain,
                                                      ampReleaseSec);
                if (ampGain <= 0.0f) {
                    if (voice.releasing) {
                        voice.active.store(0, std::memory_order_release);
                    }
                    continue;
                }

                const float filterGain = samplerAdsrGain(static_cast<float>(voiceElapsed),
                                                         noteDurationSec,
                                                         filterAttackSec,
                                                         filterDecaySec,
                                                         filterSustain,
                                                         filterReleaseSec);
                const float vel = std::clamp(voice.velocity / 127.0f, 0.0f, 1.0f);
                const float velAmount =
                    1.0f - params.velocitySensitivity * (1.0f - vel);
                const float glideMs = params.glideMs * 2000.0f;
                const float glideCoeff =
                    glideMs > 0.0f
                        ? 1.0f - std::exp(-1.0f / (static_cast<float>(sampleRate) * glideMs * 0.001f))
                        : 1.0f;

                auto& sv = voice.subtractive;
                sv.targetHz =
                    subtractiveOscPitchHz(voice.pitch, 0.5f, 0.0f, 0.5f);
                sv.pitch = voice.pitch;
                sv.velocity = voice.velocity;
                mix += subtractiveVoiceSample(sv,
                                                params,
                                                ampGain * velAmount,
                                                filterGain,
                                                sampleRate,
                                                glideCoeff) *
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
