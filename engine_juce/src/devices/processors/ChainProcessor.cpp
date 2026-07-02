#include "audioapp/devices/processors/ChainProcessor.hpp"
#include "audioapp/DeviceChainOrchestrator.hpp"
#include <algorithm>
#include <cstring>
namespace audioapp {
void ChainProcessor::initParams(const DeviceVariantParams& p) noexcept {DeviceProcessor::initParams(p);playback_=std::get<ChainParams>(p).playback;try{arena_=std::make_unique<ProcessorArena>();if(playback_)buildProcessorChain(playback_->devices,playback_->deviceCount,*arena_);}catch(...){arena_.reset();}}
void ChainProcessor::resetPlaybackState() noexcept {if(arena_)resetPlaybackStateInArena(*arena_);}
void ChainProcessor::process(AudioBlock& b,ProcessContext& c) noexcept {if(!playback_||!arena_||b.numSamples>kScratchFrames)return;std::memcpy(dryL_,b.channelL,b.numSamples*sizeof(float));std::memcpy(dryR_,b.channelR,b.numSamples*sizeof(float));DeviceChainOrchestrator::Context sub(*arena_,c.scratch);sub.trackLeft=b.channelL;sub.trackRight=b.channelR;sub.numFrames=b.numSamples;sub.sampleRate=c.sampleRate;sub.bpm=c.bpm;sub.playheadStartBeat=c.playheadBeat;sub.notes=c.notes;sub.noteCount=c.noteCount;sub.wavetableBank=c.wavetableBank;sub.automationClips=c.automationClips;sub.automationClipCount=c.automationClipCount;DeviceChainOrchestrator::processChain(sub);const float m=std::clamp(playback_->mix,0.f,1.f),g=std::clamp(playback_->gain,0.f,2.f);for(int i=0;i<b.numSamples;++i){b.channelL[i]=(dryL_[i]*(1-m)+b.channelL[i]*m)*g;b.channelR[i]=(dryR_[i]*(1-m)+b.channelR[i]*m)*g;}}
}
