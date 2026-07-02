#include "audioapp/devices/processors/ChainProcessor.hpp"
#include "audioapp/DeviceChainOrchestrator.hpp"
#include <algorithm>
#include <cstring>
namespace audioapp {
void ChainProcessor::initParams(const DeviceVariantParams& p) noexcept {DeviceProcessor::initParams(p);playback_=std::get<ChainParams>(p).playback;try{arena_=std::make_unique<ProcessorArena>();if(playback_)buildProcessorChain(playback_->devices,playback_->deviceCount,*arena_);}catch(...){arena_.reset();}}
void ChainProcessor::resetPlaybackState() noexcept {if(arena_)resetPlaybackStateInArena(*arena_);}
void ChainProcessor::process(AudioBlock& b,ProcessContext& c) noexcept {if(!playback_||!arena_||b.numSamples>kScratchFrames)return;std::memcpy(dryL_,b.channelL,b.numSamples*sizeof(float));std::memcpy(dryR_,b.channelR,b.numSamples*sizeof(float));DeviceChainOrchestrator::Context sub(*arena_,c.scratch);sub.trackLeft=b.channelL;sub.trackRight=b.channelR;sub.numFrames=b.numSamples;sub.sampleRate=c.sampleRate;sub.bpm=c.bpm;sub.playheadStartBeat=c.playheadBeat;sub.notes=c.notes;sub.noteCount=c.noteCount;sub.wavetableBank=c.wavetableBank;AutomationClipPlayback clips[16]{};int count=0;if(c.automationClips)for(int a=0;a<c.automationClipCount&&count<16;++a)for(int child=0;child<playback_->deviceCount;++child)if(c.automationClips[a].deviceIndex==playback_->devices[child].automationTargetIndex){clips[count]=c.automationClips[a];clips[count++].deviceIndex=static_cast<uint16_t>(child);break;}sub.automationClips=count?clips:nullptr;sub.automationClipCount=count;DeviceChainOrchestrator::processChain(sub);const float m=std::clamp(playback_->mix,0.f,1.f),g=std::clamp(playback_->gain,0.f,2.f);for(int i=0;i<b.numSamples;++i){b.channelL[i]=(dryL_[i]*(1-m)+b.channelL[i]*m)*g;b.channelR[i]=(dryR_[i]*(1-m)+b.channelR[i]*m)*g;}}
}
