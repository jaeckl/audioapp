#!/usr/bin/env python3
"""Generate assets/example_projects/festival_boom.json — festival trap/EDM demo."""

from __future__ import annotations

import json
from pathlib import Path

# --- timing (4/4, 64 bars = 256 beats) ---
INTRO = (0.0, 32.0)
BUILD1 = (32.0, 64.0)
DROP1 = (64.0, 128.0)
BREAK = (128.0, 160.0)
BUILD2 = (160.0, 192.0)
DROP2 = (192.0, 240.0)
OUTRO = (240.0, 256.0)
TOTAL = 256.0

# Drum pad notes
KICK, RIM, SNARE, CLAP, CHH, OHH, CRASH = 36, 37, 38, 39, 42, 46, 49

# F minor melodic pitches
F4, Ab4, Bb4, C5, Eb4 = 65, 68, 70, 72, 63
F3, Ab3, C4 = 53, 56, 60
# 808 (bassOctave -2 → sounding ~2 oct lower)
B_F, B_Ab, B_Bb, B_C, B_Eb = 53, 56, 58, 60, 51


def note(pitch: int, start: float, dur: float, vel: float) -> dict:
    return {
        "pitch": pitch,
        "startBeat": round(start, 6),
        "durationBeats": round(dur, 6),
        "velocity": float(vel),
    }


def clip(
    cid: str,
    start: float,
    length: float,
    notes: list[dict],
    *,
    natural: float | None = None,
    loop: bool = False,
) -> dict:
    nat = natural if natural is not None else length
    return {
        "id": cid,
        "startBeat": float(start),
        "lengthBeats": float(length),
        "naturalLengthBeats": float(nat),
        "loopContent": loop,
        "notes": notes,
    }


def auto_clip(
    cid: str,
    track: str,
    device: str,
    param: str,
    start: float,
    length: float,
    points: list[tuple[float, float]],
    *,
    natural: float | None = None,
    loop: bool = False,
) -> dict:
    nat = natural if natural is not None else length
    return {
        "id": cid,
        "homeTrackId": track,
        "startBeat": float(start),
        "lengthBeats": float(length),
        "naturalLengthBeats": float(nat),
        "loopContent": loop,
        "deviceId": device,
        "paramId": param,
        "points": [{"beat": float(b), "value": float(v)} for b, v in points],
    }


def pad(note_n: int, name: str, device: dict, *, gain: float = 1.0, choke: int = 0) -> dict:
    return {
        "note": note_n,
        "name": name,
        "gain": gain,
        "pan": 0.5,
        "muted": False,
        "solo": False,
        "chokeGroup": choke,
        "devices": [device],
    }


def perc(did: str, dtype: str, params: dict) -> dict:
    p = dict(params)
    p.setdefault("bypass", 0.0)
    return {"id": did, "type": dtype, "parameters": p}


def gain_dev(did: str, g: float) -> dict:
    return {"id": did, "type": "track_gain", "parameters": {"gain": g, "bypass": 0.0}}


def auto_home_track(tid: str, name: str, *, parent: str = "group-auto") -> dict:
    """Empty lane used only to lay out automation clips (deviceId targets instruments)."""
    return {
        "id": tid,
        "name": name,
        "parentGroupId": parent,
        "devices": [gain_dev(f"{tid}-gain", 1.0)],
        "midiClips": [],
        "sampleClips": [],
    }


# --- drum patterns ---

def hats_8th(vel: float = 78.0, bars: int = 2) -> list[dict]:
    out = []
    for i in range(bars * 8):
        out.append(note(CHH, i * 0.5, 0.12, vel - (6 if i % 2 else 0)))
    return out


def kick_4otf(bars: int = 2, vel: float = 118.0) -> list[dict]:
    return [note(KICK, float(b), 0.1, vel if b % 4 == 0 else vel - 8) for b in range(bars * 4)]


def kick_halftime(bars: int = 2, vel: float = 110.0) -> list[dict]:
    out = []
    for bar in range(bars):
        out.append(note(KICK, bar * 4.0, 0.1, vel))
        if bars >= 2 and bar % 2 == 1:
            out.append(note(KICK, bar * 4.0 + 2.5, 0.08, vel - 18))
    return out


def clap_snare_on_3(bars: int = 2, vel: float = 112.0) -> list[dict]:
    out = []
    for bar in range(bars):
        t = bar * 4.0 + 2.0
        out.append(note(CLAP, t, 0.12, vel))
        out.append(note(SNARE, t, 0.1, vel - 14))
    return out


def hat_roll(start: float, count: int = 8, step: float = 0.125, vel0: float = 70.0) -> list[dict]:
    return [
        note(CHH, start + i * step, 0.08, min(120.0, vel0 + i * 4))
        for i in range(count)
    ]


def drop_drums(extra_ghost: bool = False) -> list[dict]:
    """8-beat drop loop: 4otf + clap/snare + hats + end roll."""
    notes = []
    notes += kick_4otf(2, 120.0)
    if extra_ghost:
        notes.append(note(KICK, 1.75, 0.08, 88.0))
        notes.append(note(KICK, 5.75, 0.08, 90.0))
    notes += clap_snare_on_3(2, 114.0)
    notes += hats_8th(82.0, 2)
    notes.append(note(OHH, 3.5, 0.25, 72.0))
    notes.append(note(OHH, 7.5, 0.25, 78.0))
    notes += hat_roll(6.0, 8, 0.125, 74.0)
    return notes


def build_drums_a() -> list[dict]:
    """16 beats: half-time then denser into 4otf."""
    notes = kick_halftime(3, 108.0)  # kicks in bars 0-2
    notes = [n for n in notes if n["startBeat"] < 12.0]
    notes += hats_8th(70.0, 2)
    for i in range(8):
        notes.append(note(RIM, 4.0 + i * 0.5, 0.08, 55 + i * 3))
    notes += hat_roll(12.0, 16, 0.125, 68.0)
    for b in range(12, 16):
        notes.append(note(KICK, float(b), 0.1, 114.0))
    notes.append(note(CLAP, 14.0, 0.12, 100.0))
    notes.append(note(SNARE, 14.0, 0.1, 88.0))
    return notes


def build_drums_b() -> list[dict]:
    """16 beats: early 4otf + big snare roll into drop."""
    notes = kick_4otf(3, 116.0)
    notes += clap_snare_on_3(3, 108.0)
    notes += hats_8th(78.0, 3)
    notes += hat_roll(10.0, 16, 0.125, 72.0)
    # snare roll last 2 beats
    for i in range(16):
        notes.append(note(SNARE, 14.0 + i * 0.125, 0.08, 70 + i * 2))
        if i % 2 == 0:
            notes.append(note(CLAP, 14.0 + i * 0.125, 0.08, 60 + i))
    return notes


def intro_drums() -> list[dict]:
    notes = hats_8th(62.0, 2)
    notes.append(note(OHH, 3.5, 0.3, 55.0))
    notes.append(note(OHH, 7.5, 0.3, 58.0))
    return notes


def break_drums() -> list[dict]:
    notes = []
    for bar in range(2):
        notes.append(note(CLAP, bar * 4.0 + 2.0, 0.12, 78.0))
        notes.append(note(CHH, bar * 4.0 + 0.0, 0.12, 50.0))
        notes.append(note(CHH, bar * 4.0 + 1.0, 0.12, 48.0))
        notes.append(note(CHH, bar * 4.0 + 3.0, 0.12, 52.0))
    return notes


def outro_drums() -> list[dict]:
    notes = hats_8th(58.0, 2)
    notes.append(note(CRASH, 0.0, 0.5, 100.0))
    notes.append(note(CLAP, 2.0, 0.12, 70.0))
    return notes


# --- melodic patterns ---

def lead_motif(octave_double: bool = False, vel: float = 100.0) -> list[dict]:
    """4-beat festival call in Fm."""
    hits = [
        (0.0, F4, 0.4, vel),
        (0.75, Ab4, 0.28, vel - 6),
        (1.5, Bb4, 0.35, vel - 2),
        (2.25, C5, 0.45, vel + 4),
        (3.0, Bb4, 0.22, vel - 8),
        (3.5, Ab4, 0.35, vel - 4),
    ]
    out = []
    for st, p, d, v in hits:
        out.append(note(p, st, d, v))
        if octave_double:
            out.append(note(p - 12, st, d, max(40.0, v - 28)))
    return out


def lead_motif_long() -> list[dict]:
    """16-beat phrase = 4 calls with variation on last bar."""
    out = []
    for rep in range(3):
        for n in lead_motif(False, 96.0 + rep * 4):
            nn = dict(n)
            nn["startBeat"] = n["startBeat"] + rep * 4.0
            out.append(nn)
    # bar 4: hold + resolve
    out.append(note(C5, 12.0, 1.5, 108.0))
    out.append(note(Bb4, 13.75, 0.4, 92.0))
    out.append(note(Ab4, 14.5, 0.35, 88.0))
    out.append(note(F4, 15.0, 0.9, 100.0))
    out.append(note(F3, 15.0, 0.9, 70.0))
    return out


def lead_intro() -> list[dict]:
    """Sparse filtered call."""
    return [
        note(F4, 0.0, 1.5, 62.0),
        note(Ab4, 4.0, 1.2, 58.0),
        note(Bb4, 8.0, 1.5, 64.0),
        note(C5, 12.0, 2.0, 68.0),
    ]


def stab_pattern() -> list[dict]:
    """Offbeat Fm triad stabs, 8 beats."""
    out = []
    for bar in range(2):
        for off in (0.5, 2.5):
            t = bar * 4.0 + off
            for p, v in ((F3, 86), (Ab3, 82), (C4, 80)):
                out.append(note(p, t, 0.22, float(v)))
    return out


def bass_drop() -> list[dict]:
    """8-beat 808 with overlaps for glide."""
    return [
        note(B_F, 0.0, 1.6, 118.0),
        note(B_Ab, 1.35, 0.9, 100.0),
        note(B_F, 2.0, 1.3, 114.0),
        note(B_C, 3.1, 1.1, 108.0),
        note(B_F, 4.0, 1.5, 120.0),
        note(B_Bb, 5.25, 0.95, 102.0),
        note(B_F, 6.0, 1.2, 116.0),
        note(B_Eb, 7.15, 1.0, 106.0),
    ]


def bass_build() -> list[dict]:
    return [
        note(B_F, 0.0, 2.0, 70.0),
        note(B_F, 4.0, 1.5, 78.0),
        note(B_Ab, 8.0, 1.2, 85.0),
        note(B_F, 12.0, 1.8, 95.0),
        note(B_C, 14.0, 1.5, 100.0),
    ]


def pad_notes(length: float = 16.0) -> list[dict]:
    out = []
    t = 0.0
    while t < length:
        out += [
            note(F3, t, 7.5, 58.0),
            note(Ab3, t, 7.5, 54.0),
            note(C4, t, 7.5, 52.0),
        ]
        t += 8.0
        if t < length:
            out += [
                note(51, t, 7.5, 56.0),  # Eb3
                note(Ab3, t, 7.5, 52.0),
                note(58, t, 7.5, 50.0),  # Bb3
            ]
            t += 8.0
    return out


def riser_notes() -> list[dict]:
    """Chromatic / rising noise-ish pitch climb over 8 beats."""
    out = []
    # long held notes climbing
    for i, p in enumerate(range(48, 84, 2)):
        out.append(note(p, i * 0.35, 2.0, 40 + i * 2))
    return out


def main() -> None:
    drum_clips = [
        clip("fb-drm-intro", INTRO[0], 32.0, intro_drums(), natural=8.0, loop=True),
        clip("fb-drm-build1", BUILD1[0], 32.0, build_drums_a(), natural=16.0, loop=True),
        clip("fb-drm-drop1", DROP1[0], 64.0, drop_drums(False), natural=8.0, loop=True),
        clip("fb-drm-crash1", DROP1[0], 0.5, [note(CRASH, 0.0, 0.45, 118.0)]),
        clip("fb-drm-break", BREAK[0], 32.0, break_drums(), natural=8.0, loop=True),
        clip("fb-drm-build2", BUILD2[0], 32.0, build_drums_b(), natural=16.0, loop=True),
        clip("fb-drm-drop2", DROP2[0], 48.0, drop_drums(True), natural=8.0, loop=True),
        clip("fb-drm-crash2", DROP2[0], 0.5, [note(CRASH, 0.0, 0.45, 122.0)]),
        clip("fb-drm-outro", OUTRO[0], 16.0, outro_drums(), natural=8.0, loop=True),
    ]

    lead_clips = [
        clip("fb-lead-intro", INTRO[0], 32.0, lead_intro(), natural=16.0, loop=True),
        clip("fb-lead-build1", BUILD1[0], 32.0, lead_motif_long(), natural=16.0, loop=True),
        clip(
            "fb-lead-drop1",
            DROP1[0],
            64.0,
            [
                *(
                    {**n, "startBeat": n["startBeat"] + rep * 4.0}
                    for rep in range(2)
                    for n in lead_motif(True, 108.0)
                )
            ],
            natural=8.0,
            loop=True,
        ),
        clip(
            "fb-lead-break",
            BREAK[0],
            32.0,
            [
                note(F4, 0.0, 2.0, 70.0),
                note(Ab4, 4.0, 2.0, 66.0),
                note(Bb4, 8.0, 2.5, 72.0),
                note(C5, 12.0, 3.0, 68.0),
            ],
            natural=16.0,
            loop=True,
        ),
        clip("fb-lead-build2", BUILD2[0], 32.0, lead_motif_long(), natural=16.0, loop=True),
        clip(
            "fb-lead-drop2",
            DROP2[0],
            48.0,
            [
                *(
                    {**n, "startBeat": n["startBeat"] + rep * 4.0}
                    for rep in range(2)
                    for n in lead_motif(True, 114.0)
                )
            ],
            natural=8.0,
            loop=True,
        ),
        clip(
            "fb-lead-outro",
            OUTRO[0],
            16.0,
            [note(F4, 0.0, 4.0, 72.0), note(Ab4, 4.0, 4.0, 64.0), note(F4, 8.0, 6.0, 58.0)],
        ),
    ]

    stab_clips = [
        clip("fb-stab-drop1", DROP1[0], 64.0, stab_pattern(), natural=8.0, loop=True),
        clip("fb-stab-drop2", DROP2[0], 48.0, stab_pattern(), natural=8.0, loop=True),
        clip(
            "fb-stab-build2",
            BUILD2[0] + 16.0,
            16.0,
            stab_pattern(),
            natural=8.0,
            loop=True,
        ),
    ]

    bass_clips = [
        clip("fb-808-build1", BUILD1[0] + 16.0, 16.0, bass_build(), natural=16.0, loop=False),
        clip("fb-808-drop1", DROP1[0], 64.0, bass_drop(), natural=8.0, loop=True),
        clip("fb-808-build2", BUILD2[0], 32.0, bass_build(), natural=16.0, loop=True),
        clip("fb-808-drop2", DROP2[0], 48.0, bass_drop(), natural=8.0, loop=True),
    ]

    pad_clips = [
        clip("fb-pad-intro", INTRO[0], 32.0, pad_notes(16.0), natural=16.0, loop=True),
        clip("fb-pad-break", BREAK[0], 32.0, pad_notes(16.0), natural=16.0, loop=True),
        clip("fb-pad-outro", OUTRO[0], 16.0, pad_notes(16.0), natural=16.0, loop=False),
    ]

    riser_clips = [
        clip("fb-riser-b1", BUILD1[0] + 24.0, 8.0, riser_notes()),
        clip("fb-riser-b2", BUILD2[0] + 24.0, 8.0, riser_notes()),
    ]

    automation = [
        # Lead filter section arcs
        auto_clip(
            "fb-auto-lead-cut-intro",
            "track-auto-lead",
            "fb-lead",
            "filterCutoff",
            INTRO[0],
            32.0,
            [(0.0, 0.22), (32.0, 0.24)],
        ),
        auto_clip(
            "fb-auto-lead-cut-build1",
            "track-auto-lead",
            "fb-lead",
            "filterCutoff",
            BUILD1[0],
            32.0,
            [(0.0, 0.24), (32.0, 0.86)],
        ),
        auto_clip(
            "fb-auto-lead-cut-drop1",
            "track-auto-lead",
            "fb-lead",
            "filterCutoff",
            DROP1[0],
            64.0,
            [(0.0, 0.88), (64.0, 0.9)],
        ),
        auto_clip(
            "fb-auto-lead-cut-break",
            "track-auto-lead",
            "fb-lead",
            "filterCutoff",
            BREAK[0],
            32.0,
            [(0.0, 0.88), (2.0, 0.18), (24.0, 0.35), (32.0, 0.28)],
        ),
        auto_clip(
            "fb-auto-lead-cut-build2",
            "track-auto-lead",
            "fb-lead",
            "filterCutoff",
            BUILD2[0],
            28.0,
            [(0.0, 0.28), (28.0, 0.88)],
        ),
        auto_clip(
            "fb-auto-lead-cut-drop2",
            "track-auto-lead",
            "fb-lead",
            "filterCutoff",
            DROP2[0],
            48.0,
            [(0.0, 0.95), (48.0, 0.96)],
        ),
        auto_clip(
            "fb-auto-lead-cut-outro",
            "track-auto-lead",
            "fb-lead",
            "filterCutoff",
            OUTRO[0],
            16.0,
            [(0.0, 0.9), (16.0, 0.08)],
        ),
        auto_clip(
            "fb-auto-lead-gain-outro",
            "track-auto-lead-gain",
            "fb-lead-gain",
            "gain",
            OUTRO[0],
            16.0,
            [(0.0, 0.72), (16.0, 0.12)],
        ),
        # Detune widen into drops
        auto_clip(
            "fb-auto-lead-det-build1",
            "track-auto-width",
            "fb-lead",
            "wtDetune",
            BUILD1[0],
            32.0,
            [(0.0, 0.42), (32.0, 0.72)],
        ),
        auto_clip(
            "fb-auto-lead-det-drop1",
            "track-auto-width",
            "fb-lead",
            "wtDetune",
            DROP1[0],
            64.0,
            [(0.0, 0.72), (64.0, 0.74)],
        ),
        auto_clip(
            "fb-auto-lead-det-build2",
            "track-auto-width",
            "fb-lead",
            "wtDetune",
            BUILD2[0],
            32.0,
            [(0.0, 0.45), (32.0, 0.8)],
        ),
        auto_clip(
            "fb-auto-lead-det-drop2",
            "track-auto-width",
            "fb-lead",
            "wtDetune",
            DROP2[0],
            48.0,
            [(0.0, 0.8), (48.0, 0.82)],
        ),
        # Build2 one-bar flutter stutter
        auto_clip(
            "fb-auto-lead-flutter",
            "track-auto-lead",
            "fb-lead",
            "filterCutoff",
            BUILD2[0] + 28.0,
            4.0,
            [
                (0.0, 0.2),
                (0.25, 1.0),
                (0.25, 0.15),
                (0.5, 1.0),
                (0.5, 0.15),
                (0.75, 1.0),
                (0.75, 0.1),
                (1.0, 0.95),
                (1.0, 0.1),
                (1.25, 1.0),
                (1.25, 0.1),
                (1.5, 1.0),
                (1.5, 0.1),
                (1.75, 1.0),
                (1.75, 0.1),
                (2.0, 1.0),
                (2.0, 0.08),
                (2.25, 1.0),
                (2.25, 0.08),
                (2.5, 1.0),
                (2.5, 0.08),
                (2.75, 1.0),
                (2.75, 0.05),
                (3.0, 1.0),
                (3.0, 0.05),
                (3.25, 1.0),
                (3.25, 0.05),
                (3.5, 1.0),
                (3.5, 0.05),
                (3.75, 1.0),
                (4.0, 0.95),
            ],
            natural=4.0,
            loop=False,
        ),
        # Riser gain+cutoff
        auto_clip(
            "fb-auto-riser-g1",
            "track-auto-riser",
            "fb-riser",
            "gain",
            BUILD1[0] + 24.0,
            8.0,
            [(0.0, 0.05), (8.0, 0.85)],
        ),
        auto_clip(
            "fb-auto-riser-c1",
            "track-auto-riser-tone",
            "fb-riser",
            "filterCutoff",
            BUILD1[0] + 24.0,
            8.0,
            [(0.0, 0.15), (8.0, 0.95)],
        ),
        auto_clip(
            "fb-auto-riser-g2",
            "track-auto-riser",
            "fb-riser",
            "gain",
            BUILD2[0] + 24.0,
            8.0,
            [(0.0, 0.05), (8.0, 0.9)],
        ),
        auto_clip(
            "fb-auto-riser-c2",
            "track-auto-riser-tone",
            "fb-riser",
            "filterCutoff",
            BUILD2[0] + 24.0,
            8.0,
            [(0.0, 0.12), (8.0, 0.98)],
        ),
        # 808 section gain
        auto_clip(
            "fb-auto-808-drop1",
            "track-auto-808",
            "fb-808-gain",
            "gain",
            DROP1[0],
            64.0,
            [(0.0, 0.88), (64.0, 0.88)],
        ),
        auto_clip(
            "fb-auto-808-break",
            "track-auto-808",
            "fb-808-gain",
            "gain",
            BREAK[0],
            32.0,
            [(0.0, 0.2), (32.0, 0.2)],
        ),
        auto_clip(
            "fb-auto-808-drop2",
            "track-auto-808",
            "fb-808-gain",
            "gain",
            DROP2[0],
            48.0,
            [(0.0, 0.92), (48.0, 0.92)],
        ),
        # Drum track gain contrast
        auto_clip(
            "fb-auto-drm-break",
            "track-auto-drums",
            "fb-drm-gain",
            "gain",
            BREAK[0],
            32.0,
            [(0.0, 0.55), (32.0, 0.55)],
        ),
        auto_clip(
            "fb-auto-drm-drop1",
            "track-auto-drums",
            "fb-drm-gain",
            "gain",
            DROP1[0],
            64.0,
            [(0.0, 0.92), (64.0, 0.92)],
        ),
        auto_clip(
            "fb-auto-drm-drop2",
            "track-auto-drums",
            "fb-drm-gain",
            "gain",
            DROP2[0],
            48.0,
            [(0.0, 0.95), (48.0, 0.95)],
        ),
        # Pad filter
        auto_clip(
            "fb-auto-pad-intro",
            "track-auto-pad",
            "fb-pad",
            "filterCutoff",
            INTRO[0],
            32.0,
            [(0.0, 0.28), (32.0, 0.45)],
        ),
        auto_clip(
            "fb-auto-pad-break",
            "track-auto-pad",
            "fb-pad",
            "filterCutoff",
            BREAK[0],
            32.0,
            [(0.0, 0.35), (32.0, 0.55)],
        ),
    ]

    project = {
        "project_format_version": 2,
        "name": "Festival Boom",
        "bpm": 135,
        "selectedTrackId": "track-lead",
        "loopEnabled": True,
        "loopRegionStartBeat": 0.0,
        "loopRegionEndBeat": TOTAL,
        "master": {"id": "master", "name": "Master", "gain": 0.84},
        "samples": [],
        "tracks": [
            {
                "id": "track-drums",
                "name": "Drums - boom kit",
                "devices": [
                    {
                        "id": "fb-drm",
                        "type": "drum_machine",
                        "bypass": False,
                        "pads": [
                            pad(
                                KICK,
                                "Kick",
                                perc(
                                    "fb-pad-kick",
                                    "kick_generator",
                                    {
                                        "kickModel": 0.22,
                                        "kickPitch": 0.48,
                                        "kickPunch": 0.9,
                                        "kickDecay": 0.3,
                                        "kickClick": 0.62,
                                        "kickTone": 0.55,
                                        "kickVelocity": 1.0,
                                        "kickKeyTrack": 0.0,
                                        "gain": 0.96,
                                    },
                                ),
                                gain=1.0,
                            ),
                            pad(
                                SNARE,
                                "Snare",
                                perc(
                                    "fb-pad-snare",
                                    "snare_generator",
                                    {
                                        "snareModel": 0.35,
                                        "snareBody": 0.55,
                                        "snareRing": 0.4,
                                        "snareTune": 0.5,
                                        "snareSnares": 0.65,
                                        "snareSnap": 0.78,
                                        "snareDecay": 0.32,
                                        "snareVelocity": 1.0,
                                        "snareKeyTrack": 0.0,
                                        "gain": 0.88,
                                    },
                                ),
                                gain=0.92,
                            ),
                            pad(
                                CLAP,
                                "Clap",
                                perc(
                                    "fb-pad-clap",
                                    "clap_generator",
                                    {
                                        "clapBursts": 0.62,
                                        "clapSpread": 0.55,
                                        "clapTone": 0.58,
                                        "clapRoom": 0.45,
                                        "clapDecay": 0.4,
                                        "clapVelocity": 1.0,
                                        "clapPitch": 0.5,
                                        "clapKeyTrack": 0.0,
                                        "gain": 0.9,
                                    },
                                ),
                                gain=0.95,
                            ),
                            pad(
                                CHH,
                                "CHH",
                                perc(
                                    "fb-pad-chh",
                                    "hihat_generator",
                                    {
                                        "hihatPitch": 0.52,
                                        "hihatColor": 0.62,
                                        "hihatDecay": 0.18,
                                        "hihatTightness": 0.78,
                                        "hihatNoise": 0.3,
                                        "hihatWidth": 0.22,
                                        "hihatVelocity": 1.0,
                                        "hihatKeyTrack": 0.0,
                                        "gain": 0.78,
                                    },
                                ),
                                gain=0.85,
                                choke=1,
                            ),
                            pad(
                                OHH,
                                "OHH",
                                perc(
                                    "fb-pad-ohh",
                                    "hihat_generator",
                                    {
                                        "hihatPitch": 0.48,
                                        "hihatColor": 0.58,
                                        "hihatDecay": 0.62,
                                        "hihatTightness": 0.35,
                                        "hihatNoise": 0.28,
                                        "hihatWidth": 0.4,
                                        "hihatVelocity": 1.0,
                                        "hihatKeyTrack": 0.0,
                                        "gain": 0.72,
                                    },
                                ),
                                gain=0.8,
                                choke=1,
                            ),
                            pad(
                                CRASH,
                                "Crash",
                                perc(
                                    "fb-pad-crash",
                                    "crash_generator",
                                    {
                                        "crashModel": 0.4,
                                        "crashColor": 0.55,
                                        "crashSpread": 0.65,
                                        "crashDecay": 0.72,
                                        "crashVelocity": 1.0,
                                        "crashPitch": 0.5,
                                        "crashKeyTrack": 0.0,
                                        "gain": 0.82,
                                    },
                                ),
                                gain=0.9,
                            ),
                            pad(
                                RIM,
                                "Rim",
                                perc(
                                    "fb-pad-rim",
                                    "rimshot_generator",
                                    {
                                        "rimshotPitch": 0.52,
                                        "rimshotDecay": 0.25,
                                        "rimshotTone": 0.58,
                                        "rimshotSnap": 0.72,
                                        "rimshotBody": 0.4,
                                        "rimshotVelocity": 1.0,
                                        "rimshotKeyTrack": 0.0,
                                        "gain": 0.7,
                                    },
                                ),
                                gain=0.75,
                            ),
                        ],
                    },
                    gain_dev("fb-drm-gain", 0.9),
                ],
                "midiClips": drum_clips,
                "sampleClips": [],
            },
            {
                "id": "track-808",
                "name": "808 - trap glide",
                "devices": [
                    {
                        "id": "fb-808",
                        "type": "bass_synth",
                        "parameters": {
                            "bassOscShape": 0.35,
                            "bassSubMix": 0.72,
                            "bassSubOctave": 1.0,
                            "bassNoise": 0.02,
                            "attack": 0.02,
                            "sustain": 0.92,
                            "release": 0.45,
                            "bassOctave": 2.0,
                            "filterCutoff": 0.42,
                            "bassFilterResonance": 0.22,
                            "filterEnvAmount": 0.35,
                            "filterDecay": 0.4,
                            "bassDrive": 0.28,
                            "bassSquash": 0.35,
                            "glideMs": 0.55,
                            "bassVelocitySense": 0.85,
                            "gain": 0.9,
                            "bypass": 0.0,
                        },
                    },
                    gain_dev("fb-808-gain", 0.86),
                ],
                "midiClips": bass_clips,
                "sampleClips": [],
            },
            {
                "id": "track-lead",
                "name": "Lead - supersaw wall",
                "devices": [
                    {
                        "id": "fb-lead",
                        "type": "wavetable_synth",
                        "parameters": {
                            "wavetableId": "digital_64",
                            "attack": 0.012,
                            "decay": 0.28,
                            "sustain": 0.82,
                            "release": 0.42,
                            "filterCutoff": 0.35,
                            "filterResonance": 0.32,
                            "filterEnvAmount": 0.12,
                            "filterAttack": 0.02,
                            "filterDecay": 0.2,
                            "filterSustain": 0.4,
                            "filterRelease": 0.28,
                            "filterMode": 0,
                            "wtPosition": 0.52,
                            "wtOctave": 0.62,
                            "wtSemitone": 0.5,
                            "wtFine": 0.5,
                            "wtUnison": 0.95,
                            "wtDetune": 0.55,
                            "gain": 0.7,
                            "pan": 0.5,
                            "bypass": 0.0,
                        },
                    },
                    gain_dev("fb-lead-gain", 0.72),
                ],
                "midiClips": lead_clips,
                "sampleClips": [],
            },
            {
                "id": "track-stab",
                "name": "Stab - mid offbeat",
                "devices": [
                    {
                        "id": "fb-stab",
                        "type": "wavetable_synth",
                        "parameters": {
                            "wavetableId": "digital_64",
                            "attack": 0.005,
                            "decay": 0.18,
                            "sustain": 0.35,
                            "release": 0.22,
                            "filterCutoff": 0.55,
                            "filterResonance": 0.28,
                            "filterEnvAmount": 0.4,
                            "filterAttack": 0.01,
                            "filterDecay": 0.15,
                            "filterSustain": 0.2,
                            "filterRelease": 0.18,
                            "filterMode": 0,
                            "wtPosition": 0.4,
                            "wtOctave": 0.5,
                            "wtSemitone": 0.5,
                            "wtFine": 0.5,
                            "wtUnison": 0.55,
                            "wtDetune": 0.35,
                            "gain": 0.55,
                            "pan": 0.5,
                            "bypass": 0.0,
                        },
                    },
                    gain_dev("fb-stab-gain", 0.62),
                ],
                "midiClips": stab_clips,
                "sampleClips": [],
            },
            {
                "id": "track-pad",
                "name": "Pad - festival wash",
                "devices": [
                    {
                        "id": "fb-pad",
                        "type": "wavetable_synth",
                        "parameters": {
                            "wavetableId": "digital_64",
                            "attack": 0.45,
                            "decay": 0.4,
                            "sustain": 0.85,
                            "release": 0.7,
                            "filterCutoff": 0.35,
                            "filterResonance": 0.18,
                            "filterEnvAmount": 0.05,
                            "filterAttack": 0.3,
                            "filterDecay": 0.4,
                            "filterSustain": 0.7,
                            "filterRelease": 0.5,
                            "filterMode": 0,
                            "wtPosition": 0.3,
                            "wtOctave": 0.5,
                            "wtSemitone": 0.5,
                            "wtFine": 0.5,
                            "wtUnison": 0.7,
                            "wtDetune": 0.4,
                            "gain": 0.42,
                            "pan": 0.5,
                            "bypass": 0.0,
                        },
                    },
                    gain_dev("fb-pad-gain", 0.55),
                ],
                "midiClips": pad_clips,
                "sampleClips": [],
            },
            {
                "id": "track-riser",
                "name": "Riser - build FX",
                "devices": [
                    {
                        "id": "fb-riser",
                        "type": "wavetable_synth",
                        "parameters": {
                            "wavetableId": "digital_64",
                            "attack": 0.05,
                            "decay": 0.5,
                            "sustain": 0.9,
                            "release": 0.35,
                            "filterCutoff": 0.2,
                            "filterResonance": 0.45,
                            "filterEnvAmount": 0.1,
                            "filterAttack": 0.1,
                            "filterDecay": 0.3,
                            "filterSustain": 0.6,
                            "filterRelease": 0.3,
                            "filterMode": 0,
                            "wtPosition": 0.7,
                            "wtOctave": 0.55,
                            "wtSemitone": 0.5,
                            "wtFine": 0.5,
                            "wtUnison": 0.85,
                            "wtDetune": 0.65,
                            "gain": 0.08,
                            "pan": 0.5,
                            "bypass": 0.0,
                        },
                    },
                    gain_dev("fb-riser-gain", 0.7),
                ],
                "midiClips": riser_clips,
                "sampleClips": [],
            },
            {
                "id": "group-auto",
                "name": "Automation",
                "iconKey": "folder",
                "isGroup": True,
                "devices": [gain_dev("group-auto-gain", 1.0)],
                "midiClips": [],
                "sampleClips": [],
            },
            auto_home_track("track-auto-lead", "Auto - lead cutoff"),
            auto_home_track("track-auto-lead-gain", "Auto - lead gain"),
            auto_home_track("track-auto-width", "Auto - lead width"),
            auto_home_track("track-auto-drums", "Auto - drums gain"),
            auto_home_track("track-auto-808", "Auto - 808 gain"),
            auto_home_track("track-auto-pad", "Auto - pad filter"),
            auto_home_track("track-auto-riser", "Auto - riser gain"),
            auto_home_track("track-auto-riser-tone", "Auto - riser tone"),
        ],
        "lfos": [
            {
                "id": 1,
                "type": "lfo",
                "ownerDeviceId": "fb-lead",
                "waveform": 2,
                "rate": 0.5,
                "syncDivision": 3,
                "retrigger": 1,
                "phase": 0.0,
                "polarity": 1,
                "attack": 0.05,
                "decay": 0.2,
                "sustain": 0.5,
                "release": 0.2,
                "morph": 0.5,
                "spread": 0.35,
                "analogMode": 0,
            },
            {
                "id": 2,
                "type": "lfo",
                "ownerDeviceId": "fb-pad",
                "waveform": 0,
                "rate": 0.25,
                "syncDivision": 1,
                "retrigger": 1,
                "phase": 0.0,
                "polarity": 0,
                "attack": 0.1,
                "decay": 0.25,
                "sustain": 0.7,
                "release": 0.35,
                "morph": 0.0,
                "spread": 0.5,
                "analogMode": 0,
            },
        ],
        "modEdges": [
            {"lfoId": 1, "deviceId": "fb-lead", "paramId": "gain", "amount": -0.24},
            {
                "lfoId": 1,
                "deviceId": "fb-lead",
                "paramId": "filterCutoff",
                "amount": -0.08,
            },
            {
                "lfoId": 2,
                "deviceId": "fb-pad",
                "paramId": "filterCutoff",
                "amount": 0.12,
            },
        ],
        "automationClips": automation,
    }

    out = (
        Path(__file__).resolve().parents[1]
        / "app_flutter"
        / "assets"
        / "example_projects"
        / "festival_boom.json"
    )
    out.write_text(json.dumps(project, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {out} ({out.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
