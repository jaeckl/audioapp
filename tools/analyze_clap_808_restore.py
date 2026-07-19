"""Prove restored 808 clap: multi-strike, mid-band noise, Pitch moves timbre, not bell."""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

SR = 48000.0
ROOT = Path(__file__).resolve().parents[1]
SEARCH = [ROOT / "build" / "engine-msvc", ROOT / "build" / "engine-msvc" / "Debug", ROOT]


def find(name: str) -> Path:
    for base in SEARCH:
        p = base / name
        if p.is_file():
            return p
    raise FileNotFoundError(name)


def load(name: str) -> np.ndarray:
    return np.fromfile(find(name), dtype=np.float32)


def crack_peaks_ms(x: np.ndarray) -> list[float]:
    win = int(0.002 * SR)
    env = np.convolve(np.abs(x), np.ones(win) / win, mode="same")
    n80 = int(0.080 * SR)
    thr = 0.40 * float(np.max(env[:n80]))
    gap = int(0.007 * SR)
    peaks = []
    i = 1
    while i < n80 - 1:
        if env[i] >= thr and env[i] >= env[i - 1] and env[i] >= env[i + 1]:
            if not peaks or i - peaks[-1] >= gap:
                peaks.append(i)
                i += gap
                continue
        i += 1
    return [p / SR * 1000.0 for p in peaks[:5]]


def band_stats(x: np.ndarray) -> dict:
    n = min(len(x), int(0.080 * SR))
    seg = x[:n] * np.hanning(n)
    spec = np.abs(np.fft.rfft(seg)) ** 2 + 1e-20
    freqs = np.fft.rfftfreq(n, 1.0 / SR)

    def e(lo, hi):
        m = (freqs >= lo) & (freqs < hi)
        return float(np.sum(spec[m]) / np.sum(spec))

    peak = float(freqs[int(np.argmax(spec))])
    # Narrow-bell detector: peak vs ±150 Hz neighborhood (not ±4 bins).
    i = int(np.argmax(spec[1:])) + 1
    f0 = float(freqs[i])
    neigh = (freqs >= f0 - 150.0) & (freqs <= f0 + 150.0) & (np.arange(len(freqs)) != i)
    peakiness = float(spec[i] / (np.mean(spec[neigh]) + 1e-20)) if np.any(neigh) else 0.0
    # Mid-band centroid tracks BP color without HF hiss bias.
    mid = (freqs >= 400.0) & (freqs < 3000.0)
    centroid = float(np.sum(freqs[mid] * spec[mid]) / np.sum(spec[mid]))
    return {
        "e_mid": e(400, 2500),
        "e_air": e(3500, 8000),
        "centroid": centroid,
        "fft_peak": peak,
        "peakiness": peakiness,
    }


def main() -> int:
    print("=== 808 clap restore check ===")
    ok = True
    p025 = load("clap_808_p025.f32")
    p050 = load("clap_808_p050.f32")
    p075 = load("clap_808_p075.f32")

    peaks = crack_peaks_ms(p050)
    print(f"crack peaks ms: {[round(p, 1) for p in peaks]}")
    if len(peaks) < 2:
        print("FAIL: need multi-strike crack")
        ok = False
    else:
        print("PASS: multi-strike")

    s50 = band_stats(p050)
    print(
        f"default: mid={s50['e_mid']:.3f} air={s50['e_air']:.3f} "
        f"centroid={s50['centroid']:.0f} peakiness={s50['peakiness']:.1f}"
    )
    if s50["e_mid"] < 0.45:
        print("FAIL: not enough mid clap energy")
        ok = False
    else:
        print("PASS: mid-band clap energy")
    if s50["peakiness"] > 25:
        print("FAIL: too peaky (bell/drill)")
        ok = False
    else:
        print("PASS: not a narrow bell")

    c025 = band_stats(p025)["centroid"]
    c075 = band_stats(p075)["centroid"]
    print(f"Pitch 0.25->0.75 centroid: {c025:.0f} -> {c075:.0f} Hz")
    if c075 <= c025 * 1.12:
        print("FAIL: Pitch does not move timbre")
        ok = False
    else:
        print("PASS: Pitch moves crack timbre")

    m51 = band_stats(load("clap_808_m51.f32"))
    print(f"MIDI51 fft_peak={m51['fft_peak']:.0f} air={m51['e_air']:.3f}")
    if m51["fft_peak"] > 3500 or m51["e_air"] > 0.35:
        print("FAIL: high MIDI too piercing")
        ok = False
    else:
        print("PASS: high MIDI stays clap-like")

    print()
    print("PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
