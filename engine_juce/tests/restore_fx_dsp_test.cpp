// Restore FX DSP correctness — AudioBlock process() for all five devices.
#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/dsp/AudioBlock.hpp"
#include "audioapp/dsp/ProcessContext.hpp"
#include "audioapp/devices/processors/DcOffsetProcessor.hpp"
#include "audioapp/devices/processors/DeCracklerProcessor.hpp"
#include "audioapp/devices/processors/DeEsserProcessor.hpp"
#include "audioapp/devices/processors/DeHumProcessor.hpp"
#include "audioapp/devices/processors/DeNoiseProcessor.hpp"

#include <algorithm>
#include <cmath>
#include <memory>
#include <vector>

namespace {

constexpr double kSr = 48000.0;
constexpr int kN = 8192;

float meanAbs(const float* x, int n, int start) {
    double acc = 0.0;
    int c = 0;
    for (int i = start; i < n; ++i) {
        acc += static_cast<double>(x[i]);
        ++c;
    }
    return c > 0 ? static_cast<float>(acc / c) : 0.0f;
}

float rmsRange(const float* x, int n, int start) {
    double acc = 0.0;
    int c = 0;
    for (int i = start; i < n; ++i) {
        acc += static_cast<double>(x[i]) * x[i];
        ++c;
    }
    return c > 0 ? static_cast<float>(std::sqrt(acc / c)) : 0.0f;
}

bool allFinite(const float* l, const float* r, int n) {
    for (int i = 0; i < n; ++i)
        if (!std::isfinite(l[i]) || !std::isfinite(r[i]))
            return false;
    return true;
}

void fillSine(float* l, float* r, int n, float hz, float amp, float dc = 0.0f,
              double sr = kSr) {
    const float w = static_cast<float>(2.0 * juce::MathConstants<double>::pi * hz / sr);
    for (int i = 0; i < n; ++i) {
        const float s = dc + amp * std::sin(w * static_cast<float>(i));
        l[i] = s;
        r[i] = s;
    }
}

float windowDiffEnergy(const float* x, int start, int len) {
    float e = 0.0f;
    const int end = start + len;
    for (int i = start + 1; i < end; ++i) {
        const float d = x[i] - x[i - 1];
        e += d * d;
    }
    return e;
}

void fillClicks(float* l, float* r, int n, float toneAmp, float clickAmp, int every) {
    fillSine(l, r, n, 440.0f, toneAmp);
    for (int i = every; i < n; i += every) {
        l[i] += clickAmp;
        r[i] += clickAmp;
    }
}

void fillNoise(float* l, float* r, int n, float amp) {
    juce::Random rng(0xC0FFEEu);
    for (int i = 0; i < n; ++i) {
        const float s = amp * (rng.nextFloat() * 2.0f - 1.0f);
        l[i] = s;
        r[i] = s;
    }
}

template <typename Proc, typename Params>
void runProcess(Proc& proc, Params params, float* l, float* r, int n,
                double sr = kSr) {
    auto scratch = std::make_unique<audioapp::DeviceChainScratch>();
    audioapp::DeviceVariantParams variant = params;
    audioapp::ProcessContext ctx(*scratch);
    ctx.sampleRate = sr;
    ctx.bpm = 120.0;
    ctx.numFrames = n;
    ctx.modulatedParams = &variant;
    audioapp::AudioBlock block{l, r, n};
    proc.process(block, ctx);
}

} // namespace

class RestoreFxDspTest : public juce::UnitTest {
public:
    RestoreFxDspTest() : juce::UnitTest("RestoreFxDsp", "RestoreFx") {}

    void runTest() override {
        beginTest("dc_offset mean mode removes DC bias");
        {
            std::vector<float> l(kN), r(kN);
            fillSine(l.data(), r.data(), kN, 200.0f, 0.2f, 0.35f);
            const float inMean = meanAbs(l.data(), kN, kN / 2);
            audioapp::DcOffsetParamsPlayback p;
            p.mode = 0.0f;
            p.amount = 1.0f;
            p.cutoff = 0.3f;
            p.inputGain = 1.0f;
            audioapp::DcOffsetProcessor proc;
            runProcess(proc, p, l.data(), r.data(), kN);
            expect(allFinite(l.data(), r.data(), kN), "dc mean finite");
            const float outMean = std::abs(meanAbs(l.data(), kN, kN / 2));
            expect(outMean < std::abs(inMean) * 0.25f, "mean mode lowers DC");
        }

        beginTest("dc_offset amount=0 is near passthrough");
        {
            std::vector<float> l(kN), r(kN), dryL(kN);
            fillSine(l.data(), r.data(), kN, 440.0f, 0.3f, 0.2f);
            dryL = l;
            audioapp::DcOffsetParamsPlayback p;
            p.mode = 0.0f;
            p.amount = 0.0f;
            p.inputGain = 1.0f;
            audioapp::DcOffsetProcessor proc;
            runProcess(proc, p, l.data(), r.data(), kN);
            float err = 0.0f;
            for (int i = 0; i < kN; ++i)
                err = std::max(err, std::abs(l[static_cast<size_t>(i)] - dryL[static_cast<size_t>(i)]));
            expect(err < 1.0e-4f, "amount=0 passthrough");
        }

        beginTest("dc_offset HPF attenuates near-DC vs dry");
        {
            std::vector<float> wetL(kN), wetR(kN), dryL(kN), dryR(kN);
            fillSine(wetL.data(), wetR.data(), kN, 8.0f, 0.5f);
            dryL = wetL;
            dryR = wetR;
            audioapp::DcOffsetParamsPlayback p;
            p.mode = 1.0f;
            p.amount = 1.0f;
            p.cutoff = 1.0f; // ~200 Hz
            p.inputGain = 1.0f;
            audioapp::DcOffsetProcessor proc;
            runProcess(proc, p, wetL.data(), wetR.data(), kN);
            const float dryRms = rmsRange(dryL.data(), kN, kN / 2);
            const float wetRms = rmsRange(wetL.data(), kN, kN / 2);
            expect(wetRms < dryRms * 0.7f, "HPF reduces 8 Hz energy");
        }

        beginTest("de_crackler mutates samples after detected clicks");
        {
            // Hit sample itself is kept; following `width` samples are blended.
            std::vector<float> l(kN), r(kN), dry(kN);
            fillClicks(l.data(), r.data(), kN, 0.15f, 1.0f, 160);
            dry = l;
            audioapp::DeCracklerParamsPlayback p;
            p.sensitivity = 1.0f;
            p.strength = 1.0f;
            p.width = 1.0f;
            p.inputGain = 1.0f;
            audioapp::DeCracklerProcessor proc;
            runProcess(proc, p, l.data(), r.data(), kN);
            expect(allFinite(l.data(), r.data(), kN), "crackler finite");
            float maxDiff = 0.0f;
            for (int i = 0; i < kN; ++i)
                maxDiff = std::max(maxDiff,
                    std::abs(l[static_cast<size_t>(i)] - dry[static_cast<size_t>(i)]));
            expect(maxDiff > 0.05f, "crackler alters post-click samples");
        }

        beginTest("de_crackler lowers post-click derivative energy");
        {
            constexpr int kEvery = 160;
            constexpr int kWin = 32; // width param 1.0 → 2+30
            std::vector<float> l(kN), r(kN), dry(kN);
            fillClicks(l.data(), r.data(), kN, 0.15f, 1.0f, kEvery);
            dry = l;
            audioapp::DeCracklerParamsPlayback p;
            p.sensitivity = 1.0f;
            p.strength = 1.0f;
            p.width = 1.0f;
            p.inputGain = 1.0f;
            audioapp::DeCracklerProcessor proc;
            runProcess(proc, p, l.data(), r.data(), kN);
            float before = 0.0f, after = 0.0f;
            for (int c = kEvery; c + kWin < kN; c += kEvery) {
                before += windowDiffEnergy(dry.data(), c + 1, kWin);
                after += windowDiffEnergy(l.data(), c + 1, kWin);
            }
            expect(before > 0.0f, "post-click windows have energy");
            expect(after < before * 0.9f, "repair window smoother than dry");
        }

        beginTest("de_crackler strength=0 passthrough on clicks");
        {
            std::vector<float> l(kN), r(kN), dry(kN);
            fillClicks(l.data(), r.data(), kN, 0.15f, 1.0f, 160);
            dry = l;
            audioapp::DeCracklerParamsPlayback p;
            p.sensitivity = 1.0f;
            p.strength = 0.0f;
            p.width = 1.0f;
            p.inputGain = 1.0f;
            audioapp::DeCracklerProcessor proc;
            runProcess(proc, p, l.data(), r.data(), kN);
            float err = 0.0f;
            for (int i = 0; i < kN; ++i)
                err = std::max(err,
                    std::abs(l[static_cast<size_t>(i)] - dry[static_cast<size_t>(i)]));
            expect(err < 1.0e-5f, "strength=0 leaves clicks untouched");
        }

        beginTest("de_crackler leaves clean tone intact");
        {
            std::vector<float> l(kN), r(kN), dry(kN);
            fillSine(l.data(), r.data(), kN, 440.0f, 0.4f);
            dry = l;
            audioapp::DeCracklerParamsPlayback p;
            p.sensitivity = 0.2f;
            p.strength = 1.0f;
            p.width = 0.4f;
            p.inputGain = 1.0f;
            audioapp::DeCracklerProcessor proc;
            runProcess(proc, p, l.data(), r.data(), kN);
            const float dryRms = rmsRange(dry.data(), kN, 0);
            const float wetRms = rmsRange(l.data(), kN, 0);
            expect(std::abs(wetRms - dryRms) / dryRms < 0.05f, "clean tone preserved");
        }

        beginTest("de_esser reduces HF burst energy");
        {
            std::vector<float> l(kN), r(kN), dry(kN);
            fillSine(l.data(), r.data(), kN, 7000.0f, 0.55f);
            dry = l;
            audioapp::DeEsserParamsPlayback p;
            p.freq = 0.5f; // ~7 kHz
            p.threshold = 0.05f;
            p.amount = 1.0f;
            p.listen = 0.0f;
            p.inputGain = 1.0f;
            audioapp::DeEsserProcessor proc;
            runProcess(proc, p, l.data(), r.data(), kN);
            expect(allFinite(l.data(), r.data(), kN), "de-esser finite");
            const float dryHf = audioapp::test::highFrequencyEnergy(dry, 0, kN);
            const float wetHf = audioapp::test::highFrequencyEnergy(l, 0, kN);
            expect(wetHf < dryHf * 0.9f, "de-esser lowers HF energy");
        }

        beginTest("de_esser listen isolates detection band");
        {
            std::vector<float> band(kN), full(kN), r(kN);
            fillSine(full.data(), r.data(), kN, 400.0f, 0.4f);
            // Mix in HF
            for (int i = 0; i < kN; ++i) {
                const float hf = 0.3f * std::sin(static_cast<float>(
                    2.0 * juce::MathConstants<double>::pi * 7000.0 * i / kSr));
                full[static_cast<size_t>(i)] += hf;
                r[static_cast<size_t>(i)] = full[static_cast<size_t>(i)];
            }
            band = full;
            audioapp::DeEsserParamsPlayback p;
            p.freq = 0.5f;
            p.threshold = 1.0f; // no GR
            p.amount = 0.0f;
            p.listen = 1.0f;
            p.inputGain = 1.0f;
            audioapp::DeEsserProcessor proc;
            runProcess(proc, p, band.data(), r.data(), kN);
            // Listen bandpass should attenuate 400 Hz relative to dry mid
            const float dryMid = rmsRange(full.data(), kN, kN / 2);
            const float listenRms = rmsRange(band.data(), kN, kN / 2);
            expect(listenRms < dryMid * 0.85f, "listen is not full-band passthrough");
        }

        beginTest("de_hum attenuates 50 Hz tone");
        {
            std::vector<float> l(kN), r(kN), dry(kN);
            fillSine(l.data(), r.data(), kN, 50.0f, 0.5f);
            dry = l;
            audioapp::DeHumParamsPlayback p;
            p.mainsFreq = 0.0f; // 50 Hz
            p.depth = 1.0f;
            p.harmonics = 0.0f; // fundamental only
            p.inputGain = 1.0f;
            audioapp::DeHumProcessor proc;
            runProcess(proc, p, l.data(), r.data(), kN);
            expect(allFinite(l.data(), r.data(), kN), "de-hum finite");
            const float dryRms = rmsRange(dry.data(), kN, kN / 2);
            const float wetRms = rmsRange(l.data(), kN, kN / 2);
            expect(wetRms < dryRms * 0.85f, "50 Hz attenuated");
        }

        beginTest("de_hum spares 1 kHz more than 50 Hz");
        {
            std::vector<float> humL(kN), humR(kN), midL(kN), midR(kN);
            fillSine(humL.data(), humR.data(), kN, 50.0f, 0.5f);
            fillSine(midL.data(), midR.data(), kN, 1000.0f, 0.5f);
            const float humDry = rmsRange(humL.data(), kN, kN / 2);
            const float midDry = rmsRange(midL.data(), kN, kN / 2);
            audioapp::DeHumParamsPlayback p;
            p.mainsFreq = 0.0f;
            p.depth = 1.0f;
            p.harmonics = 0.3f;
            p.inputGain = 1.0f;
            audioapp::DeHumProcessor humProc;
            audioapp::DeHumProcessor midProc;
            runProcess(humProc, p, humL.data(), humR.data(), kN);
            runProcess(midProc, p, midL.data(), midR.data(), kN);
            const float humRatio = rmsRange(humL.data(), kN, kN / 2) / humDry;
            const float midRatio = rmsRange(midL.data(), kN, kN / 2) / midDry;
            expect(humRatio < midRatio, "hum cut harder than 1 kHz");
        }

        beginTest("de_noise reduces quiet hiss");
        {
            std::vector<float> l(kN), r(kN), dry(kN);
            fillNoise(l.data(), r.data(), kN, 0.02f);
            dry = l;
            audioapp::DeNoiseParamsPlayback p;
            p.threshold = 0.8f;
            p.reduction = 1.0f;
            p.smoothing = 0.2f;
            p.inputGain = 1.0f;
            audioapp::DeNoiseProcessor proc;
            runProcess(proc, p, l.data(), r.data(), kN);
            expect(allFinite(l.data(), r.data(), kN), "de-noise finite");
            const float dryRms = rmsRange(dry.data(), kN, kN / 2);
            const float wetRms = rmsRange(l.data(), kN, kN / 2);
            expect(wetRms < dryRms * 0.75f, "quiet noise reduced");
        }

        beginTest("de_noise reduction=0 near passthrough");
        {
            std::vector<float> l(kN), r(kN), dry(kN);
            fillNoise(l.data(), r.data(), kN, 0.05f);
            dry = l;
            audioapp::DeNoiseParamsPlayback p;
            p.threshold = 0.8f;
            p.reduction = 0.0f;
            p.smoothing = 0.4f;
            p.inputGain = 1.0f;
            audioapp::DeNoiseProcessor proc;
            runProcess(proc, p, l.data(), r.data(), kN);
            float err = 0.0f;
            for (int i = kN / 4; i < kN; ++i)
                err = std::max(err, std::abs(l[static_cast<size_t>(i)] - dry[static_cast<size_t>(i)]));
            expect(err < 1.0e-3f, "reduction=0 passthrough");
        }

        beginTest("de_esser amount sweep and high threshold");
        {
            std::vector<float> a0(kN), a1(kN), hi(kN), r(kN);
            fillSine(a0.data(), r.data(), kN, 7000.0f, 0.55f);
            a1 = a0;
            hi = a0;
            audioapp::DeEsserParamsPlayback soft;
            soft.freq = 0.5f;
            soft.threshold = 0.05f;
            soft.amount = 0.0f;
            soft.inputGain = 1.0f;
            audioapp::DeEsserParamsPlayback hard = soft;
            hard.amount = 1.0f;
            audioapp::DeEsserParamsPlayback gated = hard;
            gated.threshold = 1.0f; // above env → little GR
            audioapp::DeEsserProcessor p0, p1, pHi;
            runProcess(p0, soft, a0.data(), r.data(), kN);
            r.assign(a1.begin(), a1.end());
            runProcess(p1, hard, a1.data(), r.data(), kN);
            r.assign(hi.begin(), hi.end());
            runProcess(pHi, gated, hi.data(), r.data(), kN);
            const float e0 = audioapp::test::highFrequencyEnergy(a0, 0, kN);
            const float e1 = audioapp::test::highFrequencyEnergy(a1, 0, kN);
            const float eHi = audioapp::test::highFrequencyEnergy(hi, 0, kN);
            expect(e1 < e0 * 0.95f, "amount=1 cuts more HF than amount=0");
            expect(eHi > e1, "high threshold ducks less than low threshold");
        }

        beginTest("de_hum 60 Hz path and harmonics");
        {
            std::vector<float> l60(kN), r60(kN), dry60(kN);
            fillSine(l60.data(), r60.data(), kN, 60.0f, 0.5f);
            dry60 = l60;
            audioapp::DeHumParamsPlayback p60;
            p60.mainsFreq = 1.0f;
            p60.depth = 1.0f;
            p60.harmonics = 0.0f;
            p60.inputGain = 1.0f;
            audioapp::DeHumProcessor proc60;
            runProcess(proc60, p60, l60.data(), r60.data(), kN);
            expect(rmsRange(l60.data(), kN, kN / 2)
                       < rmsRange(dry60.data(), kN, kN / 2) * 0.85f,
                   "60 Hz attenuated");

            // 150 Hz = 3rd harmonic of 50 Hz — deeper harmonics should cut more.
            std::vector<float> h0(kN), h1(kN), rh(kN);
            fillSine(h0.data(), rh.data(), kN, 150.0f, 0.5f);
            h1 = h0;
            audioapp::DeHumParamsPlayback shallow;
            shallow.mainsFreq = 0.0f;
            shallow.depth = 1.0f;
            shallow.harmonics = 0.0f; // fundamental only → 150 Hz spared more
            shallow.inputGain = 1.0f;
            audioapp::DeHumParamsPlayback deep = shallow;
            deep.harmonics = 1.0f; // up to 8 harmonics
            audioapp::DeHumProcessor ps, pd;
            runProcess(ps, shallow, h0.data(), rh.data(), kN);
            rh.assign(h1.begin(), h1.end());
            runProcess(pd, deep, h1.data(), rh.data(), kN);
            expect(rmsRange(h1.data(), kN, kN / 2) < rmsRange(h0.data(), kN, kN / 2),
                   "more harmonics → stronger 150 Hz cut");
        }

        beginTest("de_noise loud bright tone survives");
        {
            // Detector is a 3 kHz HPF — mid-only tones look like "quiet noise".
            // Bright content keeps HF energy above threshold and should pass.
            std::vector<float> l(kN), r(kN), dry(kN);
            fillSine(l.data(), r.data(), kN, 8000.0f, 0.5f);
            dry = l;
            audioapp::DeNoiseParamsPlayback p;
            p.threshold = 0.35f;
            p.reduction = 1.0f;
            p.smoothing = 0.3f;
            p.inputGain = 1.0f;
            audioapp::DeNoiseProcessor proc;
            runProcess(proc, p, l.data(), r.data(), kN);
            const float dryRms = rmsRange(dry.data(), kN, kN / 2);
            const float wetRms = rmsRange(l.data(), kN, kN / 2);
            expect(wetRms > dryRms * 0.85f, "loud bright tone not heavily ducked");
        }

        beginTest("dc_offset multi sample-rate mean mode");
        {
            for (const double sr : {44100.0, 48000.0, 96000.0}) {
                std::vector<float> l(kN), r(kN);
                fillSine(l.data(), r.data(), kN, 200.0f, 0.2f, 0.35f, sr);
                const float inMean = std::abs(meanAbs(l.data(), kN, kN / 2));
                audioapp::DcOffsetParamsPlayback p;
                p.mode = 0.0f;
                p.amount = 1.0f;
                p.inputGain = 1.0f;
                audioapp::DcOffsetProcessor proc;
                runProcess(proc, p, l.data(), r.data(), kN, sr);
                expect(allFinite(l.data(), r.data(), kN), "finite @ SR");
                expect(std::abs(meanAbs(l.data(), kN, kN / 2)) < inMean * 0.3f,
                       "DC reduced @ SR");
            }
        }

        beginTest("dc_offset chunked vs one-shot mean");
        {
            std::vector<float> one(kN), rOne(kN), chunk(kN), rChunk(kN);
            fillSine(one.data(), rOne.data(), kN, 200.0f, 0.2f, 0.35f);
            chunk = one;
            rChunk = rOne;
            audioapp::DcOffsetParamsPlayback p;
            p.mode = 0.0f;
            p.amount = 1.0f;
            p.inputGain = 1.0f;
            audioapp::DcOffsetProcessor procOne, procChunk;
            runProcess(procOne, p, one.data(), rOne.data(), kN);
            constexpr int sizes[] = {1, 17, 257, 512};
            int offset = 0;
            int si = 0;
            while (offset < kN) {
                const int n = std::min(sizes[si % 4], kN - offset);
                runProcess(procChunk, p, chunk.data() + offset, rChunk.data() + offset, n);
                offset += n;
                ++si;
            }
            const float a = rmsRange(one.data(), kN, kN / 2);
            const float b = rmsRange(chunk.data(), kN, kN / 2);
            expect(std::abs(a - b) / std::max(a, 1.0e-6f) < 0.15f,
                   "chunked mean ≈ one-shot RMS");
        }

        beginTest("all restore processors stay finite on loud input");
        {
            auto loud = [](auto& proc, auto params) {
                std::vector<float> l(kN), r(kN);
                fillSine(l.data(), r.data(), kN, 1000.0f, 0.99f);
                params.inputGain = 1.0f;
                runProcess(proc, params, l.data(), r.data(), kN);
                return allFinite(l.data(), r.data(), kN);
            };
            audioapp::DcOffsetProcessor dc;
            audioapp::DeCracklerProcessor cr;
            audioapp::DeEsserProcessor de;
            audioapp::DeHumProcessor hum;
            audioapp::DeNoiseProcessor dn;
            expect(loud(dc, audioapp::DcOffsetParamsPlayback{}), "dc loud finite");
            expect(loud(cr, audioapp::DeCracklerParamsPlayback{}), "crack loud finite");
            expect(loud(de, audioapp::DeEsserParamsPlayback{}), "esser loud finite");
            expect(loud(hum, audioapp::DeHumParamsPlayback{}), "hum loud finite");
            expect(loud(dn, audioapp::DeNoiseParamsPlayback{}), "noise loud finite");
        }
    }
};

static RestoreFxDspTest restoreFxDspTest;
