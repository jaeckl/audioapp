#!/usr/bin/env python3
"""Compare external drum reference WAVs vs our generator renders."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
import soundfile as sf
from scipy.signal import find_peaks

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "build"


def load_mono(path: Path) -> tuple[np.ndarray, int]:
    data, sr = sf.read(path, always_2d=False)
    if data.ndim > 1:
        data = data.mean(axis=1)
    return data.astype(np.float64), sr


def trim_silence(x: np.ndarray, threshold: float = 1e-4) -> np.ndarray:
    mask = np.abs(x) > threshold
    if not mask.any():
        return x
    start = int(np.argmax(mask))
    end = len(x) - int(np.argmax(mask[::-1]))
    return x[start:end]


def band_energy(x: np.ndarray, sr: int, lo: float, hi: float) -> float:
    n = len(x)
    if n < 8:
        return 0.0
    freqs = np.fft.rfftfreq(n, 1.0 / sr)
    spec = np.abs(np.fft.rfft(x * np.hanning(n)))
    band = (freqs >= lo) & (freqs < hi)
    return float(np.sum(spec[band] ** 2))


def spectral_peaks(x: np.ndarray, sr: int, top_n: int = 12) -> list[dict]:
    n = min(len(x), sr * 2)
    seg = x[:n] * np.hanning(n)
    freqs = np.fft.rfftfreq(n, 1.0 / sr)
    mag = np.abs(np.fft.rfft(seg))
    peaks, props = find_peaks(mag, height=np.max(mag) * 0.02, distance=8)
    order = np.argsort(props["peak_heights"])[::-1][:top_n]
    return [
        {"hz": round(float(freqs[peaks[idx]]), 1), "mag": round(float(props["peak_heights"][idx]), 4)}
        for idx in order
    ]


def tonality_score(x: np.ndarray, sr: int) -> float:
    n = min(len(x), sr)
    seg = x[:n] * np.hanning(n)
    mag = np.abs(np.fft.rfft(seg))
    mag = mag / (np.max(mag) + 1e-12)
    peaks, props = find_peaks(mag, height=0.05, distance=6)
    if len(peaks) == 0:
        return 0.0
    peak_energy = float(np.sum(props["peak_heights"] ** 2))
    total_energy = float(np.sum(mag ** 2))
    return peak_energy / (total_energy + 1e-12)


def window_stats(x: np.ndarray, sr: int, start_ms: float, end_ms: float) -> dict:
    s0 = int(start_ms * 0.001 * sr)
    s1 = int(end_ms * 0.001 * sr)
    seg = x[s0:s1]
    if len(seg) < 64:
        return {}
    return {
        "rms_db": round(20 * np.log10(np.sqrt(np.mean(seg ** 2)) + 1e-12), 2),
        "tonality": round(tonality_score(seg, sr), 4),
        "peaks_hz": [p["hz"] for p in spectral_peaks(seg, sr, 8)],
        "bands": {
            "sub_500": round(band_energy(seg, sr, 20, 500), 2),
            "mid_500_4k": round(band_energy(seg, sr, 500, 4000), 2),
            "high_4k_12k": round(band_energy(seg, sr, 4000, 12000), 2),
            "air_12k+": round(band_energy(seg, sr, 12000, sr * 0.45), 2),
        },
    }


def compare_pair(name: str, ref_path: Path, gen_path: Path) -> dict:
    ref, ref_sr = load_mono(ref_path)
    gen, gen_sr = load_mono(gen_path)
    ref = trim_silence(ref)
    gen = trim_silence(gen)
    tail_end = min(3000.0, len(ref) / ref_sr * 1000.0 * 0.9)
    return {
        "name": name,
        "reference": str(ref_path),
        "generator": str(gen_path),
        "reference_duration_sec": round(len(ref) / ref_sr, 3),
        "generator_duration_sec": round(len(gen) / gen_sr, 3),
        "reference_tonality": round(tonality_score(ref, ref_sr), 4),
        "generator_tonality": round(tonality_score(gen, gen_sr), 4),
        "reference_top_peaks": spectral_peaks(ref, ref_sr),
        "generator_top_peaks": spectral_peaks(gen, gen_sr),
        "windows": {
            "reference": {
                "attack_0_50ms": window_stats(ref, ref_sr, 0, 50),
                "early_50_200ms": window_stats(ref, ref_sr, 50, 200),
                "wash_200_800ms": window_stats(ref, ref_sr, 200, 800),
            },
            "generator": {
                "attack_0_50ms": window_stats(gen, gen_sr, 0, 50),
                "early_50_200ms": window_stats(gen, gen_sr, 50, 200),
                "wash_200_800ms": window_stats(gen, gen_sr, 200, 800),
            },
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--kind", choices=["crash", "cymbal", "both"], default="both")
    args = parser.parse_args()

    pairs = []
    if args.kind in ("crash", "both"):
        pairs.append(("crash", ROOT / "crash.wav", OUT_DIR / "crash_generator_render.wav"))
    if args.kind in ("cymbal", "both"):
        pairs.append(("cymbal", ROOT / "cymbal.wav", OUT_DIR / "cymbal_generator_render.wav"))

    report = {"comparisons": []}
    for name, ref, gen in pairs:
        if not ref.exists():
            print(f"Missing reference: {ref}", file=sys.stderr)
            return 1
        if not gen.exists():
            print(f"Missing render: {gen}", file=sys.stderr)
            return 1
        report["comparisons"].append(compare_pair(name, ref, gen))

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out_json = OUT_DIR / "drum_compare_report.json"
    out_json.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))
    print(f"\nWrote {out_json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
