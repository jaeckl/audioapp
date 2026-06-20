#!/usr/bin/env python3
"""Compare external crash reference vs our crash generator render."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
import soundfile as sf
from scipy.signal import stft, find_peaks

ROOT = Path(__file__).resolve().parents[1]
REF_PATH = ROOT / "crash.wav"
GEN_PATH = ROOT / "build" / "crash_generator_render.wav"
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
    out = []
    for idx in order:
        f = float(freqs[peaks[idx]])
        h = float(props["peak_heights"][idx])
        out.append({"hz": round(f, 1), "mag": round(h, 4)})
    return out


def tonality_score(x: np.ndarray, sr: int) -> float:
    """Higher = more tonal (narrow peaks dominate). Lower = noisier wash."""
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


def save_spectrogram_png(x: np.ndarray, sr: int, path: Path, title: str) -> None:
    import matplotlib.pyplot as plt

    f, t, z = stft(x, fs=sr, nperseg=1024, noverlap=768)
    db = 20 * np.log10(np.abs(z) + 1e-9)
    plt.figure(figsize=(10, 4))
    plt.pcolormesh(t, f, db, shading="gouraud", cmap="magma")
    plt.ylim(0, min(16000, sr * 0.45))
    plt.ylabel("Hz")
    plt.xlabel("s")
    plt.title(title)
    plt.colorbar(label="dB")
    plt.tight_layout()
    plt.savefig(path, dpi=120)
    plt.close()


def main() -> int:
    if not REF_PATH.exists():
        print(f"Missing reference: {REF_PATH}", file=sys.stderr)
        return 1
    if not GEN_PATH.exists():
        print(f"Missing render: {GEN_PATH}", file=sys.stderr)
        return 1

    ref, ref_sr = load_mono(REF_PATH)
    gen, gen_sr = load_mono(GEN_PATH)

    ref = trim_silence(ref)
    gen = trim_silence(gen)

    report = {
        "reference": str(REF_PATH),
        "generator": str(GEN_PATH),
        "reference_sr": ref_sr,
        "generator_sr": gen_sr,
        "reference_duration_sec": round(len(ref) / ref_sr, 3),
        "generator_duration_sec": round(len(gen) / gen_sr, 3),
        "windows": {
            "reference": {
                "attack_0_50ms": window_stats(ref, ref_sr, 0, 50),
                "early_50_200ms": window_stats(ref, ref_sr, 50, 200),
                "wash_200_1500ms": window_stats(ref, ref_sr, 200, 1500),
                "tail_1500_3000ms": window_stats(ref, ref_sr, 1500, 3000),
            },
            "generator": {
                "attack_0_50ms": window_stats(gen, gen_sr, 0, 50),
                "early_50_200ms": window_stats(gen, gen_sr, 50, 200),
                "wash_200_1500ms": window_stats(gen, gen_sr, 200, 1500),
                "tail_1500_3000ms": window_stats(gen, gen_sr, 1500, 3000),
            },
        },
        "full_signal": {
            "reference_tonality": round(tonality_score(ref, ref_sr), 4),
            "generator_tonality": round(tonality_score(gen, gen_sr), 4),
            "reference_top_peaks": spectral_peaks(ref, ref_sr),
            "generator_top_peaks": spectral_peaks(gen, gen_sr),
        },
    }

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    try:
        spec_ref = OUT_DIR / "crash_compare_ref_spec.png"
        spec_gen = OUT_DIR / "crash_compare_gen_spec.png"
        save_spectrogram_png(ref, ref_sr, spec_ref, "External crash (reference)")
        save_spectrogram_png(gen, gen_sr, spec_gen, "Our crash generator")
        print(f"Wrote {spec_ref}")
        print(f"Wrote {spec_gen}")
    except ImportError:
        print("matplotlib not installed — skipping spectrogram PNGs")

    out_json = OUT_DIR / "crash_compare_report.json"
    out_json.write_text(json.dumps(report, indent=2), encoding="utf-8")

    print(json.dumps(report, indent=2))
    print(f"\nWrote {out_json}")

    ref_t = report["full_signal"]["reference_tonality"]
    gen_t = report["full_signal"]["generator_tonality"]
    if gen_t > ref_t * 1.5:
        print(
            f"\nDIAGNOSIS: Generator tonality {gen_t:.3f} >> reference {ref_t:.3f} "
            "(narrow resonant peaks / pling)"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
