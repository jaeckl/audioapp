#pragma once

namespace audioapp {

class SampleBank;

struct SampleClipPlaybackRegion {
    double clipStartBeat = 0.0;
    double clipLengthBeats = 4.0;
    const float* pcm = nullptr;
    int frameCount = 0;
    double sampleRate = 48000.0;
};

struct SamplerMidiNoteRegion {
    int pitch = 60;
    double clipStartBeat = 0.0;
    double clipLengthBeats = 4.0;
    double noteStartBeat = 0.0;
    double noteDurationBeats = 1.0;
    float velocity = 100.0f;
};

struct SamplerInstrumentPlayback {
    const float* pcm = nullptr;
    int frameCount = 0;
    double pcmSampleRate = 48000.0;
    float gain = 1.0f;
    int rootPitch = 60;
};

void mixSamplerMidiNotesBlock(float* monoOut,
                              int numFrames,
                              double sampleRate,
                              int bpm,
                              double playheadStartBeat,
                              const SamplerMidiNoteRegion* notes,
                              int noteCount,
                              const SamplerInstrumentPlayback& sampler);

void mixSampleRegionsBlock(float* monoOut,
                           int numFrames,
                           double sampleRate,
                           int bpm,
                           double playheadStartBeat,
                           const SampleClipPlaybackRegion* regions,
                           int regionCount);

} // namespace audioapp
