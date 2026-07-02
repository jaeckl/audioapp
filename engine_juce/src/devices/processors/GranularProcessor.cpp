#include "audioapp/devices/processors/GranularProcessor.hpp"
#include "audioapp/ClipContentPlayback.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {
void GranularProcessor::resetPlaybackState() noexcept {
    for (auto& channel : z1_) for (auto& value : channel) value = 0.0f;
    for (auto& channel : z2_) for (auto& value : channel) value = 0.0f;
}

void GranularProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (ctx.suppressInstruments || !ctx.modulatedParams) return;
    const auto& p = std::get<GranularParams>(*ctx.modulatedParams);
    if (!p.pcm || p.frameCount < 4 || ctx.noteCount <= 0) return;

    static constexpr float vowels[6][3] = {
        {800,1150,2900},{400,1700,2600},{350,2000,2800},
        {450,800,2830},{325,700,2530},{500,1200,2400}};
    constexpr float pi = 3.14159265358979323846f;
    constexpr int maxGrainsPerVoice = 8;
    static constexpr float points[6][2] = {
        {.5f,.05f},{.88f,.25f},{.88f,.75f},{.12f,.25f},{.12f,.75f},{.5f,.95f}};
    float blendedFormants[3]{};
    float weightSum=0.0f;
    for(int voice=0;voice<6;++voice){const float dx=p.formX-points[voice][0];const float dy=p.formY-points[voice][1];const float weight=std::exp(-(dx*dx+dy*dy)/.075f);weightSum+=weight;for(int band=0;band<3;++band)blendedFormants[band]+=vowels[voice][band]*weight;}
    for(auto& frequency:blendedFormants)frequency/=std::max(weightSum,.0001f);
    const float shift = std::pow(2.0f,(p.formant-.5f)*2.0f);
    const float density = 5.0f+p.density*39.0f;
    const float grainSeconds = .012f+p.size*.18f;
    const float attackSeconds = .002f+p.attack*p.attack*1.5f;
    const float releaseSeconds = .015f+p.release*p.release*2.0f;
    const double beatsPerFrame = static_cast<double>(std::max(ctx.bpm,1))/60.0/ctx.sampleRate;
    const double regionStart = std::clamp(static_cast<double>(p.regionStart),0.0,.98);
    const double regionEnd = std::clamp(static_cast<double>(p.regionEnd),regionStart+.02,1.0);
    const double regionLength = regionEnd-regionStart;

    for (int frame=0;frame<block.numSamples;++frame) {
        float left=0.0f,right=0.0f;
        const double beat=ctx.playheadBeat+frame*beatsPerFrame;
        int voices=0;
        for (int noteIndex=0;noteIndex<ctx.noteCount && voices<4;++noteIndex) {
            const auto& note=ctx.notes[noteIndex];
            const double local=beatWithinClipContent(beat,note.clipStartBeat,
                note.clipLengthBeats,note.contentLengthBeats,note.loopContent);
            if (local<note.noteStartBeat) continue;
            const double elapsed=(local-note.noteStartBeat)*60.0/std::max(ctx.bpm,1);
            const double duration=note.noteDurationBeats*60.0/std::max(ctx.bpm,1);
            if (elapsed>duration+releaseSeconds) continue;
            const float amp=elapsed<attackSeconds
                ? static_cast<float>(elapsed/attackSeconds)
                : (elapsed<=duration ? 1.0f
                    : std::max(0.0f,1.0f-static_cast<float>((elapsed-duration)/releaseSeconds)));
            const double semitones=(note.pitch-60)+(p.pitch-.5f)*48.0f;
            const double ratio=std::pow(2.0,semitones/12.0)*p.pcmRate/ctx.sampleRate;
            float voiceLeft=0.0f,voiceRight=0.0f;
            int activeGrains=0;
            const auto newestGrain=static_cast<int64_t>(std::floor(elapsed*density));
            for (int grain=0;grain<maxGrainsPerVoice;++grain) {
                const int64_t grainNumber=newestGrain-grain;
                if(grainNumber<0) continue;
                const double spawnTime=grainNumber/density;
                const double age=elapsed-spawnTime;
                if(age<0.0||age>=grainSeconds) continue;
                const double grainPhase=age/grainSeconds;
                const double random=std::sin((grainNumber+note.pitch*17.0)*12.9898);
                const double scan=regionStart+regionLength*std::fmod(
                    p.position+spawnTime*(p.scan-.5f)*.35+4.0,1.0);
                const double jitter=random*p.spray*regionLength*.14;
                const double start=std::clamp(scan+jitter,regionStart,regionEnd)*p.frameCount;
                double position=start+grainPhase*grainSeconds*ctx.sampleRate*ratio;
                const double first=regionStart*(p.frameCount-1);
                const double span=std::max(2.0,regionLength*(p.frameCount-1));
                position=first+std::fmod(std::max(0.0,position-first),span);
                const int index=std::min(static_cast<int>(position),p.frameCount-2);
                const float fraction=static_cast<float>(position-index);
                const float sample=p.pcm[index]*(1.0f-fraction)+p.pcm[index+1]*fraction;
                const float window=.5f-.5f*std::cos(static_cast<float>(grainPhase)*2.0f*pi);
                const float value=sample*window*amp*(note.velocity/127.0f);
                const float pan=std::clamp(.5f+static_cast<float>(random)*p.spread*.48f,0.0f,1.0f);
                voiceLeft+=value*std::sqrt(1.0f-pan);
                voiceRight+=value*std::sqrt(pan);
                ++activeGrains;
            }
            const float grainGain=activeGrains>0?.7f/std::sqrt(static_cast<float>(activeGrains)):0.0f;
            left+=voiceLeft*grainGain;
            right+=voiceRight*grainGain;
            ++voices;
        }

        float shaped[2]{};
        const float input[2]={left,right};
        for (int channel=0;channel<2;++channel) {
            for (int band=0;band<3;++band) {
                const float hz=std::min(blendedFormants[band]*shift,static_cast<float>(ctx.sampleRate)*.42f);
                const float radius=.94f+p.character*.045f;
                const float coefficient=2.0f*radius*std::cos(2.0f*pi*hz/static_cast<float>(ctx.sampleRate));
                const float value=(1.0f-radius)*input[channel]+coefficient*z1_[channel][band]
                    -radius*radius*z2_[channel][band];
                z2_[channel][band]=z1_[channel][band];
                z1_[channel][band]=value;
                shaped[channel]+=value;
            }
        }
        const float wet=std::sqrt(std::clamp(p.character,0.0f,1.0f));
        block.channelL[frame]+=(left*(1-wet)+shaped[0]*wet*2.1f)*.36f;
        block.channelR[frame]+=(right*(1-wet)+shaped[1]*wet*2.1f)*.36f;
    }
}
} // namespace audioapp
