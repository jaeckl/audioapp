#include "audioapp/devices/ChainDeviceType.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/devices/processors/ChainProcessor.hpp"
#include <algorithm>
namespace audioapp {
std::string ChainDeviceType::typeId()const{return device_types::kChain;}
DeviceSlot ChainDeviceType::createDefault(const std::string&id)const{DeviceSlot s;s.id=id;s.config.typeId=typeId();s.config.instance=ChainModel{};s.config.inputPanel=EmptyPanel{};s.config.outputPanel=EmptyPanel{};return s;}
DeviceParameterResult ChainDeviceType::setParameter(DeviceSlot&s,std::string_view id,float v)const{auto&m=std::get<ChainModel>(s.config.instance);if(id=="chainMix")m.mix=std::clamp(v,0.f,1.f);else if(id=="chainGain")m.gain=std::clamp(v,0.f,2.f);else return {};return {.handled=true};}
bool ChainDeviceType::setStringParameter(DeviceSlot&,std::string_view,const std::string&,const PlaybackBuildContext&)const{return false;}
std::vector<std::string_view> ChainDeviceType::modulatableParams()const{return {"chainMix","chainGain"};}
void ChainDeviceType::buildPlaybackNode(const DeviceSlot&s,const PlaybackBuildContext&c,DeviceNodePlayback&o)const{auto p=std::make_shared<ChainPlayback>();const auto&m=std::get<ChainModel>(s.config.instance);p->mix=m.mix;p->gain=m.gain;if(c.deviceRegistry)for(const auto&child:m.devices){if(!child||child->config.typeId==device_types::kChain||p->deviceCount>=8)continue;auto&n=p->devices[p->deviceCount++];n.deviceId=child->id;n.bypassed=child->config.bypassed;c.deviceRegistry->buildPlaybackNode(*child,c,n);}o.kind=DeviceNodeKind::Chain;o.params=ChainParams{p};}
bool ChainDeviceType::buildLiveInstrument(const DeviceSlot&,const PlaybackBuildContext&,LiveInstrumentSnapshot&)const{return false;}
juce::var ChainDeviceType::slotToVar(const DeviceSlot&s)const{const auto&m=std::get<ChainModel>(s.config.instance);auto*p=new juce::DynamicObject();p->setProperty("chainMix",m.mix);p->setProperty("chainGain",m.gain);auto*o=new juce::DynamicObject();o->setProperty("id",juce::String(s.id));o->setProperty("type",juce::String(typeId()));o->setProperty("bypass",s.config.bypassed);o->setProperty("parameters",juce::var(p));return juce::var(o);}
DeviceSlot ChainDeviceType::varToSlot(const juce::var&v)const{auto s=createDefault("");if(auto*o=v.getDynamicObject()){s.id=o->getProperty("id").toString().toStdString();if(auto*p=o->getProperty("parameters").getDynamicObject()){auto&m=std::get<ChainModel>(s.config.instance);m.mix=static_cast<float>(static_cast<double>(p->getProperty("chainMix")));m.gain=static_cast<float>(static_cast<double>(p->getProperty("chainGain")));}}return s;}
DeviceProcessor* ChainDeviceType::createProcessor(ProcessorArena&a)const{return a.emplace<ChainProcessor>();} DeviceNodeKind ChainDeviceType::kind()const noexcept{return DeviceNodeKind::Chain;}
uint16_t ChainDeviceType::paramIdFromString(std::string_view n)const noexcept{return n=="chainMix"?0:n=="chainGain"?1:static_cast<uint16_t>(-1);} std::string_view ChainDeviceType::paramIdToString(uint16_t i)const noexcept{return i==0?"chainMix":i==1?"chainGain":"";}
std::span<const ParamDescriptor> ChainDeviceType::paramDescriptors()const noexcept{static constexpr ParamDescriptor p[]={{0,"chainMix","Mix",1,0,1,true,true},{1,"chainGain","Gain",1,0,2,true,true}};return p;}
}
