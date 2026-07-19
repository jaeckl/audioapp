#!/usr/bin/env python3
"""Generate Dart MIDI pattern groups + manifest entries from drum_beat_catalog.yaml."""

from __future__ import annotations

import json
from collections import defaultdict
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "docs" / "design" / "drum_beat_catalog.yaml"
MANIFEST = ROOT / "app_flutter" / "assets" / "content_library" / "manifest.json"
DART_DIR = ROOT / "app_flutter" / "lib" / "features" / "content_library"

PAD_MAP = {
    "kick": 36,
    "snare": 37,
    "chh": 38,
    "ohh": 39,
    "clap": 40,
    "rim": 40,
    "tom_lo": 41,
    "tom_mid": 42,
    "tom_hi": 43,
    "perc": 44,
    "ride": 46,
    "crash": 47,
}

GENRE_TAG = {
    "Electro": "electro",
    "Pop": "pop",
    "House": "house",
    "R&B": "rnb",
    "Reggae": "reggae",
    "Rock": "rock",
    "Breakbeat": "breakbeat",
    "Trap": "trap",
    "Techno": "techno",
    "Hip-hop": "hiphop",
    "DnB": "dnb",
    "Disco": "disco",
    "Funk": "funk",
    "Latin": "latin",
    "Ambient": "ambient",
}

SWING_DELAY = {
    "none": 0.0,
    "light": 0.03,
    "medium": 0.055,
    "heavy": 0.08,
}

# Split generated Dart maps to keep files under ~250 LOC.
GENRE_FILES = [
    ("electro_pop_house", {"Electro", "Pop", "House"}),
    ("rnb_reggae_rock", {"R&B", "Reggae", "Rock"}),
    ("breakbeat_trap", {"Breakbeat", "Trap"}),
    ("extras", {"Techno", "Hip-hop", "DnB", "Disco", "Funk", "Latin", "Ambient"}),
]


def dart_string(s: str) -> str:
    return json.dumps(s)


def normalize_pattern(pat: str, steps: int) -> str:
    pat = pat.replace(" ", "")
    if len(pat) < steps:
        pat = pat + ("-" * (steps - len(pat)))
    return pat[:steps]


def voices_to_dart_map(voices: dict, steps: int) -> str:
    """Build Dart map literal: pitch -> pattern string."""
    entries: list[tuple[int, str]] = []
    has_ohh = "ohh" in voices
    for role, pat in voices.items():
        if role not in PAD_MAP:
            continue
        pitch = PAD_MAP[role]
        p = normalize_pattern(str(pat), steps)
        # 'o' on chh lane → open hat when no dedicated ohh voice
        if role == "chh" and not has_ohh and "o" in p:
            chh = "".join("-" if c == "o" else c for c in p)
            ohh = "".join("x" if c == "o" else "-" for c in p)
            entries.append((38, chh))
            entries.append((39, ohh))
        else:
            p = p.replace("o", "x")
            entries.append((pitch, p))
    # Merge duplicate pitches (clap+rim both 40)
    merged: dict[int, str] = {}
    for pitch, p in entries:
        if pitch not in merged:
            merged[pitch] = p
            continue
        a, b = merged[pitch], p
        out = []
        for i in range(steps):
            ca, cb = a[i], b[i]
            if ca == "-" and cb == "-":
                out.append("-")
            elif "X" in (ca, cb):
                out.append("X")
            elif "." in (ca, cb) and "x" not in (ca, cb) and "X" not in (ca, cb):
                out.append(".")
            else:
                out.append("x")
        merged[pitch] = "".join(out)
    parts = [f"{pitch}: {dart_string(pat)}" for pitch, pat in sorted(merged.items())]
    return "{" + ", ".join(parts) + "}"


def manifest_tags(pattern: dict) -> list[str]:
    genre = pattern["genre"]
    tags = ["drums", "factory", GENRE_TAG[genre]]
    # Character hints from catalog tags (only controlled vocab)
    raw = pattern.get("tags") or []
    extras = {
        "groovy",
        "aggressive",
        "dark",
        "lofi",
        "edm",
        "dnb",
        "progressive",
        "warm",
        "bright",
        "clean",
    }
    for t in raw:
        key = str(t).lower().replace("&", "").replace(" ", "").replace("-", "")
        if key in ("808",):
            continue
        if str(t).lower() in extras:
            tags.append(str(t).lower())
        if key in ("halftime", "half-time"):
            tags.append("groovy")
    # Dedupe preserve order
    seen = set()
    out = []
    for t in tags:
        if t not in seen:
            seen.add(t)
            out.append(t)
    return out


def subtitle(pattern: dict) -> str:
    genre = pattern["genre"]
    bpm = pattern.get("bpm", 120)
    bars = pattern.get("bars", 1)
    swing = pattern.get("swing", "none")
    swing_bit = "" if swing == "none" else f" - {swing} swing"
    return f"{genre} - {bpm} BPM - {bars} bar{'' if bars == 1 else 's'}{swing_bit}"


def emit_dart_group(name: str, patterns: list[dict]) -> str:
    var_name = f"_library_midi_patternsGroupDrums_{name}"
    lines = [
        "part of 'library_midi_patterns.dart';",
        "",
        f"/// Factory drum beats — {name.replace('_', ' / ')}.",
        f"final Map<String, LibraryMidiPattern> {var_name} = {{",
    ]
    for p in patterns:
        steps = int(p.get("steps") or (int(p.get("bars", 1)) * 16))
        bars = int(p.get("bars") or max(1, steps // 16))
        swing = str(p.get("swing") or "none")
        delay = SWING_DELAY.get(swing, 0.0)
        voices = p.get("voices") or {}
        voice_map = voices_to_dart_map(voices, steps)
        pid = p["id"]
        lines.append(
            f"  {dart_string(pid)}: LibraryMidiPatterns._drumBeat("
            f"bars: {bars}, swingDelay: {delay}, voices: {voice_map}),"
        )
    lines.append("};")
    lines.append("")
    return "\n".join(lines)


def main() -> None:
    data = yaml.safe_load(CATALOG.read_text(encoding="utf-8"))
    patterns: list[dict] = data["patterns"]
    by_genre: dict[str, list[dict]] = defaultdict(list)
    for p in patterns:
        by_genre[p["genre"]].append(p)

    # Write Dart groups
    group_vars = []
    for file_key, genres in GENRE_FILES:
        chunk = []
        for g in genres:
            chunk.extend(by_genre.get(g, []))
        chunk.sort(key=lambda x: x["id"])
        path = DART_DIR / f"library_midi_patterns_library_midi_patterns_group_drums_{file_key}.dart"
        path.write_text(emit_dart_group(file_key, chunk), encoding="utf-8")
        group_vars.append(f"_library_midi_patternsGroupDrums_{file_key}")
        print(f"wrote {path.name} ({len(chunk)} patterns)")

    # Manifest: keep melodic factory clips; replace only drum beat entries.
    # (library_midi_patterns.dart part directives / _drumBeat helper are hand-maintained.)
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    existing = [
        e
        for e in manifest.get("midiClips", [])
        if "drums" not in e.get("tags", [])
        and not str(e.get("id", "")).startswith("midi:drum-")
    ]

    new_entries = []
    for p in sorted(patterns, key=lambda x: x["id"]):
        pid = p["id"]
        mid = f"midi:drum-{pid}"
        new_entries.append(
            {
                "id": mid,
                "title": p["name"],
                "subtitle": subtitle(p),
                "patternId": pid,
                "tags": manifest_tags(p),
            }
        )
    manifest["midiClips"] = existing + new_entries
    MANIFEST.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"manifest midiClips: {len(existing)} melodic + {len(new_entries)} drum = {len(manifest['midiClips'])}")


if __name__ == "__main__":
    main()
