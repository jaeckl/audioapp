#pragma once
#include <string>
namespace audioapp { struct GranularModel {
 std::string sampleId="sample_form_source"; float position=.25f,scan=.15f,size=.35f,density=.35f;
 float spray=.1f,pitch=.5f,formant=.5f,character=.45f;
 float regionStart=0.f,regionEnd=1.f,attack=.02f,release=.25f,spread=.35f;
 float formX=.5f,formY=.05f;
 int vowel=0;
}; }
