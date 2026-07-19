#!/usr/bin/env python3
"""Generate drum family DevicePresetStore maps + manifest entries."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "app_flutter" / "assets" / "content_library" / "manifest.json"
STORE_DIR = ROOT / "app_flutter" / "lib" / "features" / "device_strip"
DOC = ROOT / "docs" / "design" / "drum_device_family_presets.md"

# (family, display, genre_tags, voices: list of (voice_slug, voice_label, deviceType, params))
# voice_slug used in id: preset:{family}-{voice_slug}

def kick(**kw):
    base = {
        "kickModel": 0.0,
        "kickPitch": 0.55,
        "kickPunch": 0.55,
        "kickDecay": 0.45,
        "kickClick": 0.35,
        "kickTone": 0.5,
        "kickVelocity": 1.0,
        "kickKeyTrack": 0.0,
    }
    base.update(kw)
    return base


def snare(**kw):
    base = {
        "snareModel": 0.0,
        "snareBody": 0.55,
        "snareRing": 0.4,
        "snareTune": 0.5,
        "snareSnares": 0.55,
        "snareSnap": 0.5,
        "snareDecay": 0.4,
        "snareVelocity": 1.0,
        "snareKeyTrack": 0.0,
    }
    base.update(kw)
    return base


def clap(**kw):
    base = {
        "clapBursts": 0.5,
        "clapSpread": 0.45,
        "clapTone": 0.55,
        "clapRoom": 0.4,
        "clapDecay": 0.45,
        "clapPitch": 0.5,
        "clapVelocity": 1.0,
        "clapKeyTrack": 0.0,
    }
    base.update(kw)
    return base


def hat(**kw):
    base = {
        "hihatPitch": 0.55,
        "hihatColor": 0.5,
        "hihatDecay": 0.35,
        "hihatTightness": 0.7,
        "hihatNoise": 0.55,
        "hihatWidth": 0.35,
        "hihatVelocity": 1.0,
        "hihatKeyTrack": 0.0,
    }
    base.update(kw)
    return base


def rim(**kw):
    base = {
        "rimshotPitch": 0.55,
        "rimshotDecay": 0.3,
        "rimshotTone": 0.5,
        "rimshotSnap": 0.65,
        "rimshotBody": 0.35,
        "rimshotVelocity": 1.0,
        "rimshotKeyTrack": 0.0,
    }
    base.update(kw)
    return base


def tom(**kw):
    base = {
        "tomPitch": 0.5,
        "tomDecay": 0.45,
        "tomBend": 0.4,
        "tomBody": 0.55,
        "tomAttack": 0.45,
        "tomNoise": 0.25,
        "tomVelocity": 1.0,
        "tomKeyTrack": 0.0,
    }
    base.update(kw)
    return base


def ride(**kw):
    base = {
        "ridePitch": 0.5,
        "rideBrightness": 0.55,
        "rideDecay": 0.55,
        "rideBell": 0.35,
        "rideDamping": 0.4,
        "rideWidth": 0.45,
        "rideVelocity": 1.0,
        "rideKeyTrack": 0.0,
    }
    base.update(kw)
    return base


def crash(**kw):
    base = {
        "crashModel": 0.0,
        "crashColor": 0.62,
        "crashSpread": 0.5,
        "crashDecay": 0.55,
        "crashPitch": 0.5,
        "crashVelocity": 1.0,
        "crashKeyTrack": 0.0,
    }
    base.update(kw)
    return base


ROLE_TAG = {
    "kick": "kick",
    "snare": "snare",
    "clap": "fx",
    "chh": "fx",
    "ohh": "fx",
    "rim": "snare",
    "tomlo": "kick",
    "tommid": "kick",
    "tomhi": "kick",
    "ride": "fx",
    "crash": "fx",
}

DEVICE = {
    "kick": "kick_generator",
    "snare": "snare_generator",
    "clap": "clap_generator",
    "chh": "hihat_generator",
    "ohh": "hihat_generator",
    "rim": "rimshot_generator",
    "tomlo": "tom_generator",
    "tommid": "tom_generator",
    "tomhi": "tom_generator",
    "ride": "ride_generator",
    "crash": "crash_generator",
}

LABEL = {
    "kick": "Kick",
    "snare": "Snare",
    "clap": "Clap",
    "chh": "Closed Hat",
    "ohh": "Open Hat",
    "rim": "Rim",
    "tomlo": "Tom Lo",
    "tommid": "Tom Mid",
    "tomhi": "Tom Hi",
    "ride": "Ride",
    "crash": "Crash",
}


def V(voice: str, params: dict):
    return (voice, LABEL[voice], DEVICE[voice], params)


FAMILIES: list[tuple[str, str, list[str], list]] = [
    (
        "808",
        "808",
        ["edm", "electro"],
        [
            V("kick", kick(kickModel=0.0, kickPitch=0.42, kickPunch=0.7, kickDecay=0.72, kickClick=0.25, kickTone=0.35)),
            V("snare", snare(snareModel=0.0, snareBody=0.35, snareRing=0.25, snareTune=0.55, snareSnares=0.35, snareSnap=0.7, snareDecay=0.35)),
            V("clap", clap(clapBursts=0.55, clapSpread=0.5, clapTone=0.6, clapRoom=0.25, clapDecay=0.4)),
            V("chh", hat(hihatDecay=0.22, hihatTightness=0.85, hihatNoise=0.65, hihatColor=0.55)),
            V("ohh", hat(hihatDecay=0.7, hihatTightness=0.25, hihatNoise=0.55, hihatColor=0.5, hihatWidth=0.45)),
            V("rim", rim(rimshotPitch=0.6, rimshotSnap=0.8, rimshotBody=0.2, rimshotDecay=0.22)),
            V("tomlo", tom(tomPitch=0.28, tomDecay=0.55, tomBody=0.65, tomBend=0.45)),
            V("tommid", tom(tomPitch=0.5, tomDecay=0.48, tomBody=0.55, tomBend=0.4)),
            V("tomhi", tom(tomPitch=0.72, tomDecay=0.4, tomBody=0.45, tomBend=0.35)),
            V("crash", crash(crashModel=0.0, crashColor=0.55, crashDecay=0.65, crashSpread=0.55)),
        ],
    ),
    (
        "909",
        "909",
        ["house", "techno"],
        [
            V("kick", kick(kickModel=0.5, kickPitch=0.5, kickPunch=0.75, kickDecay=0.4, kickClick=0.55, kickTone=0.45)),
            V("snare", snare(snareModel=0.5, snareBody=0.45, snareRing=0.35, snareTune=0.48, snareSnares=0.7, snareSnap=0.65, snareDecay=0.38)),
            V("clap", clap(clapBursts=0.6, clapSpread=0.55, clapTone=0.5, clapRoom=0.35, clapDecay=0.42)),
            V("chh", hat(hihatDecay=0.2, hihatTightness=0.88, hihatNoise=0.7, hihatColor=0.6, hihatPitch=0.58)),
            V("ohh", hat(hihatDecay=0.62, hihatTightness=0.3, hihatNoise=0.6, hihatColor=0.55, hihatWidth=0.5)),
            V("rim", rim(rimshotPitch=0.52, rimshotSnap=0.7, rimshotTone=0.55, rimshotDecay=0.28)),
            V("tomlo", tom(tomPitch=0.3, tomDecay=0.5, tomBody=0.6, tomAttack=0.5)),
            V("tommid", tom(tomPitch=0.52, tomDecay=0.45, tomBody=0.5)),
            V("tomhi", tom(tomPitch=0.74, tomDecay=0.38, tomBody=0.4)),
            V("ride", ride(rideBrightness=0.6, rideDecay=0.5, rideBell=0.25, rideDamping=0.45)),
            V("crash", crash(crashModel=0.5, crashColor=0.65, crashDecay=0.6, crashSpread=0.6)),
        ],
    ),
    (
        "electro",
        "Electro",
        ["electro"],
        [
            V("kick", kick(kickModel=0.0, kickPitch=0.48, kickPunch=0.65, kickDecay=0.5, kickClick=0.45, kickTone=0.4)),
            V("snare", snare(snareModel=0.0, snareBody=0.3, snareRing=0.2, snareTune=0.6, snareSnares=0.25, snareSnap=0.75, snareDecay=0.3)),
            V("clap", clap(clapBursts=0.45, clapSpread=0.4, clapTone=0.65, clapRoom=0.2, clapDecay=0.35)),
            V("chh", hat(hihatDecay=0.18, hihatTightness=0.9, hihatNoise=0.75, hihatColor=0.65, hihatPitch=0.62)),
            V("ohh", hat(hihatDecay=0.55, hihatTightness=0.35, hihatNoise=0.65, hihatWidth=0.4)),
            V("rim", rim(rimshotPitch=0.65, rimshotSnap=0.85, rimshotBody=0.15, rimshotDecay=0.18)),
            V("tommid", tom(tomPitch=0.55, tomDecay=0.35, tomNoise=0.4, tomBody=0.4)),
            V("crash", crash(crashModel=0.0, crashColor=0.7, crashDecay=0.5, crashPitch=0.55)),
        ],
    ),
    (
        "trap",
        "Trap",
        ["trap"],
        [
            V("kick", kick(kickModel=0.0, kickPitch=0.35, kickPunch=0.8, kickDecay=0.78, kickClick=0.2, kickTone=0.3)),
            V("snare", snare(snareModel=0.0, snareBody=0.25, snareRing=0.15, snareTune=0.62, snareSnares=0.2, snareSnap=0.85, snareDecay=0.28)),
            V("clap", clap(clapBursts=0.65, clapSpread=0.6, clapTone=0.55, clapRoom=0.45, clapDecay=0.5)),
            V("chh", hat(hihatDecay=0.15, hihatTightness=0.92, hihatNoise=0.8, hihatPitch=0.65, hihatColor=0.6)),
            V("ohh", hat(hihatDecay=0.75, hihatTightness=0.2, hihatNoise=0.5, hihatWidth=0.55)),
            V("rim", rim(rimshotPitch=0.7, rimshotSnap=0.9, rimshotBody=0.1, rimshotDecay=0.15)),
            V("tomlo", tom(tomPitch=0.22, tomDecay=0.6, tomBody=0.7, tomBend=0.5)),
        ],
    ),
    (
        "boombap",
        "Boom Bap",
        ["hiphop", "lofi"],
        [
            V("kick", kick(kickModel=0.5, kickPitch=0.45, kickPunch=0.55, kickDecay=0.5, kickClick=0.3, kickTone=0.4)),
            V("snare", snare(snareModel=0.5, snareBody=0.6, snareRing=0.45, snareTune=0.42, snareSnares=0.6, snareSnap=0.45, snareDecay=0.48)),
            V("rim", rim(rimshotPitch=0.48, rimshotSnap=0.55, rimshotBody=0.45, rimshotTone=0.45, rimshotDecay=0.32)),
            V("chh", hat(hihatDecay=0.28, hihatTightness=0.65, hihatNoise=0.45, hihatColor=0.4, hihatPitch=0.48)),
            V("ohh", hat(hihatDecay=0.58, hihatTightness=0.35, hihatNoise=0.4, hihatWidth=0.35)),
            V("tomlo", tom(tomPitch=0.32, tomDecay=0.55, tomBody=0.65, tomNoise=0.2)),
            V("tommid", tom(tomPitch=0.5, tomDecay=0.5, tomBody=0.55)),
        ],
    ),
    (
        "house",
        "House",
        ["house"],
        [
            V("kick", kick(kickModel=0.5, kickPitch=0.52, kickPunch=0.7, kickDecay=0.38, kickClick=0.5, kickTone=0.5)),
            V("snare", snare(snareModel=0.5, snareBody=0.4, snareRing=0.3, snareTune=0.5, snareSnares=0.55, snareSnap=0.6, snareDecay=0.35)),
            V("clap", clap(clapBursts=0.7, clapSpread=0.55, clapTone=0.5, clapRoom=0.4, clapDecay=0.45)),
            V("chh", hat(hihatDecay=0.2, hihatTightness=0.85, hihatNoise=0.6, hihatColor=0.55)),
            V("ohh", hat(hihatDecay=0.6, hihatTightness=0.3, hihatNoise=0.55, hihatWidth=0.5)),
            V("ride", ride(rideBrightness=0.55, rideDecay=0.48, rideBell=0.2, rideDamping=0.5)),
            V("crash", crash(crashModel=0.5, crashColor=0.6, crashDecay=0.58, crashSpread=0.55)),
        ],
    ),
    (
        "techno",
        "Techno",
        ["techno", "dark"],
        [
            V("kick", kick(kickModel=0.5, kickPitch=0.48, kickPunch=0.85, kickDecay=0.35, kickClick=0.65, kickTone=0.35)),
            V("snare", snare(snareModel=0.5, snareBody=0.3, snareRing=0.2, snareTune=0.55, snareSnares=0.4, snareSnap=0.75, snareDecay=0.28)),
            V("chh", hat(hihatDecay=0.16, hihatTightness=0.9, hihatNoise=0.7, hihatColor=0.45, hihatPitch=0.6)),
            V("ohh", hat(hihatDecay=0.5, hihatTightness=0.35, hihatNoise=0.55, hihatWidth=0.4)),
            V("rim", rim(rimshotPitch=0.58, rimshotSnap=0.8, rimshotBody=0.2, rimshotDecay=0.2)),
            V("ride", ride(rideBrightness=0.45, rideDecay=0.55, rideBell=0.15, rideDamping=0.55, ridePitch=0.48)),
            V("crash", crash(crashModel=0.5, crashColor=0.45, crashDecay=0.7, crashSpread=0.65)),
        ],
    ),
    (
        "pop",
        "Pop",
        ["pop", "clean"],
        [
            V("kick", kick(kickModel=0.5, kickPitch=0.5, kickPunch=0.6, kickDecay=0.42, kickClick=0.4, kickTone=0.55)),
            V("snare", snare(snareModel=0.5, snareBody=0.5, snareRing=0.4, snareTune=0.5, snareSnares=0.5, snareSnap=0.55, snareDecay=0.4)),
            V("clap", clap(clapBursts=0.5, clapSpread=0.45, clapTone=0.55, clapRoom=0.35, clapDecay=0.4)),
            V("chh", hat(hihatDecay=0.25, hihatTightness=0.75, hihatNoise=0.5, hihatColor=0.5)),
            V("ohh", hat(hihatDecay=0.55, hihatTightness=0.35, hihatNoise=0.45, hihatWidth=0.4)),
            V("rim", rim(rimshotPitch=0.5, rimshotSnap=0.6, rimshotBody=0.4, rimshotDecay=0.28)),
            V("tommid", tom(tomPitch=0.52, tomDecay=0.45, tomBody=0.55)),
            V("crash", crash(crashModel=0.0, crashColor=0.6, crashDecay=0.55, crashSpread=0.5)),
        ],
    ),
    (
        "rnb",
        "R&B",
        ["rnb"],
        [
            V("kick", kick(kickModel=0.0, kickPitch=0.4, kickPunch=0.55, kickDecay=0.6, kickClick=0.25, kickTone=0.4)),
            V("snare", snare(snareModel=0.5, snareBody=0.55, snareRing=0.5, snareTune=0.45, snareSnares=0.45, snareSnap=0.4, snareDecay=0.5)),
            V("rim", rim(rimshotPitch=0.45, rimshotSnap=0.45, rimshotBody=0.55, rimshotTone=0.5, rimshotDecay=0.35)),
            V("chh", hat(hihatDecay=0.3, hihatTightness=0.6, hihatNoise=0.4, hihatColor=0.4, hihatPitch=0.5)),
            V("ohh", hat(hihatDecay=0.65, hihatTightness=0.3, hihatNoise=0.35, hihatWidth=0.45)),
            V("clap", clap(clapBursts=0.4, clapSpread=0.5, clapTone=0.45, clapRoom=0.5, clapDecay=0.48)),
            V("tomlo", tom(tomPitch=0.3, tomDecay=0.55, tomBody=0.65, tomBend=0.35)),
        ],
    ),
    (
        "reggae",
        "Reggae",
        ["reggae"],
        [
            V("kick", kick(kickModel=0.5, kickPitch=0.48, kickPunch=0.45, kickDecay=0.45, kickClick=0.25, kickTone=0.45)),
            V("snare", snare(snareModel=0.5, snareBody=0.5, snareRing=0.35, snareTune=0.48, snareSnares=0.5, snareSnap=0.4, snareDecay=0.4)),
            V("rim", rim(rimshotPitch=0.5, rimshotSnap=0.5, rimshotBody=0.5, rimshotTone=0.55, rimshotDecay=0.3)),
            V("chh", hat(hihatDecay=0.22, hihatTightness=0.8, hihatNoise=0.45, hihatColor=0.45)),
            V("ohh", hat(hihatDecay=0.5, hihatTightness=0.35, hihatNoise=0.4, hihatWidth=0.35)),
        ],
    ),
    (
        "rock",
        "Rock",
        ["rock"],
        [
            V("kick", kick(kickModel=0.5, kickPitch=0.5, kickPunch=0.65, kickDecay=0.4, kickClick=0.45, kickTone=0.5)),
            V("snare", snare(snareModel=0.5, snareBody=0.65, snareRing=0.55, snareTune=0.48, snareSnares=0.65, snareSnap=0.55, snareDecay=0.45)),
            V("rim", rim(rimshotPitch=0.52, rimshotSnap=0.6, rimshotBody=0.45, rimshotDecay=0.3)),
            V("chh", hat(hihatDecay=0.28, hihatTightness=0.7, hihatNoise=0.4, hihatColor=0.45)),
            V("ohh", hat(hihatDecay=0.6, hihatTightness=0.3, hihatNoise=0.4, hihatWidth=0.4)),
            V("tomlo", tom(tomPitch=0.28, tomDecay=0.55, tomBody=0.7, tomBend=0.45, tomAttack=0.5)),
            V("tommid", tom(tomPitch=0.5, tomDecay=0.5, tomBody=0.6, tomBend=0.4)),
            V("tomhi", tom(tomPitch=0.72, tomDecay=0.42, tomBody=0.5, tomBend=0.35)),
            V("ride", ride(rideBrightness=0.5, rideDecay=0.6, rideBell=0.4, rideDamping=0.35)),
            V("crash", crash(crashModel=0.5, crashColor=0.65, crashDecay=0.7, crashSpread=0.6)),
        ],
    ),
    (
        "breakbeat",
        "Breakbeat",
        ["breakbeat"],
        [
            V("kick", kick(kickModel=0.5, kickPitch=0.48, kickPunch=0.6, kickDecay=0.42, kickClick=0.4, kickTone=0.45)),
            V("snare", snare(snareModel=0.5, snareBody=0.55, snareRing=0.5, snareTune=0.5, snareSnares=0.7, snareSnap=0.6, snareDecay=0.42)),
            V("rim", rim(rimshotPitch=0.55, rimshotSnap=0.7, rimshotBody=0.35, rimshotDecay=0.25)),
            V("chh", hat(hihatDecay=0.22, hihatTightness=0.78, hihatNoise=0.55, hihatColor=0.5)),
            V("ohh", hat(hihatDecay=0.55, hihatTightness=0.32, hihatNoise=0.5, hihatWidth=0.45)),
            V("tomlo", tom(tomPitch=0.3, tomDecay=0.5, tomBody=0.6, tomBend=0.5)),
            V("tomhi", tom(tomPitch=0.7, tomDecay=0.38, tomBody=0.45, tomBend=0.4)),
            V("crash", crash(crashModel=0.0, crashColor=0.55, crashDecay=0.55, crashSpread=0.5)),
        ],
    ),
    (
        "disco",
        "Disco",
        ["disco", "funk"],
        [
            V("kick", kick(kickModel=0.5, kickPitch=0.52, kickPunch=0.6, kickDecay=0.36, kickClick=0.45, kickTone=0.55)),
            V("snare", snare(snareModel=0.5, snareBody=0.45, snareRing=0.35, snareTune=0.52, snareSnares=0.5, snareSnap=0.55, snareDecay=0.35)),
            V("clap", clap(clapBursts=0.55, clapSpread=0.5, clapTone=0.55, clapRoom=0.3, clapDecay=0.4)),
            V("chh", hat(hihatDecay=0.2, hihatTightness=0.85, hihatNoise=0.55, hihatColor=0.55, hihatPitch=0.58)),
            V("ohh", hat(hihatDecay=0.58, hihatTightness=0.3, hihatNoise=0.5, hihatWidth=0.5)),
            V("ride", ride(rideBrightness=0.65, rideDecay=0.45, rideBell=0.35, rideDamping=0.4)),
        ],
    ),
    (
        "dnb",
        "DnB",
        ["dnb"],
        [
            V("kick", kick(kickModel=0.5, kickPitch=0.45, kickPunch=0.75, kickDecay=0.32, kickClick=0.55, kickTone=0.4)),
            V("snare", snare(snareModel=0.5, snareBody=0.4, snareRing=0.45, snareTune=0.55, snareSnares=0.75, snareSnap=0.7, snareDecay=0.35)),
            V("chh", hat(hihatDecay=0.14, hihatTightness=0.92, hihatNoise=0.75, hihatColor=0.55, hihatPitch=0.62)),
            V("ohh", hat(hihatDecay=0.48, hihatTightness=0.3, hihatNoise=0.6, hihatWidth=0.45)),
            V("rim", rim(rimshotPitch=0.6, rimshotSnap=0.85, rimshotBody=0.2, rimshotDecay=0.18)),
            V("crash", crash(crashModel=0.5, crashColor=0.7, crashDecay=0.55, crashSpread=0.65, crashPitch=0.55)),
        ],
    ),
    (
        "ambient",
        "Ambient",
        ["ambient"],
        [
            V("kick", kick(kickModel=0.0, kickPitch=0.4, kickPunch=0.3, kickDecay=0.7, kickClick=0.1, kickTone=0.35)),
            V("snare", snare(snareModel=0.0, snareBody=0.35, snareRing=0.55, snareTune=0.4, snareSnares=0.25, snareSnap=0.25, snareDecay=0.6)),
            V("chh", hat(hihatDecay=0.4, hihatTightness=0.45, hihatNoise=0.3, hihatColor=0.35, hihatPitch=0.45, hihatWidth=0.5)),
            V("ohh", hat(hihatDecay=0.8, hihatTightness=0.2, hihatNoise=0.25, hihatWidth=0.65, hihatColor=0.35)),
            V("rim", rim(rimshotPitch=0.4, rimshotSnap=0.3, rimshotBody=0.5, rimshotTone=0.4, rimshotDecay=0.4)),
        ],
    ),
]


def dart_map(params: dict) -> str:
    parts = [f"'{k}': {v:g}" for k, v in params.items()]
    return "{" + ", ".join(parts) + "}"


def emit_store_part(device_type: str, entries: list[tuple[str, dict]]) -> str:
    var = {
        "kick_generator": "_kick",
        "snare_generator": "_snare",
        "clap_generator": "_clap",
        "hihat_generator": "_hihat",
        "rimshot_generator": "_rimshot",
        "tom_generator": "_tom",
        "ride_generator": "_ride",
        "crash_generator": "_crash",
    }[device_type]
    lines = [
        "part of 'device_preset_store.dart';",
        "",
        f"const Map<String, DevicePreset> {var} = {{",
    ]
    for pid, params in entries:
        lines.append(f"  '{pid}': DevicePreset(params: {dart_map(params)}),")
    lines.append("};")
    lines.append("")
    return "\n".join(lines)


def kit_manifest_entries() -> list[dict]:
    """15 drum_machine kits; pad trees use presetRef in Flutter FactoryPresetJson."""
    entries = []
    for slug, display, genres, _voices in FAMILIES:
        tags = ["factory", "drums", slug, *genres]
        seen: set[str] = set()
        tags = [t for t in tags if not (t in seen or seen.add(t))]
        entries.append(
            {
                "id": f"preset:kit-{slug}",
                "title": f"{display} · Kit",
                "subtitle": f"{display} drum machine · family voices",
                "deviceType": "drum_machine",
                "tags": tags,
            }
        )
    return entries


def write_doc(presets: list[dict]) -> None:
    lines = [
        "# Drum device family presets",
        "",
        "**Status:** Voice presets + 15 `drum_machine` kits via `presetRef`",
        "",
        "Fifteen stylistic families. Each voice is a `DevicePresetStore` leaf +",
        "`manifest.json` entry. Kits are `drum_machine` presets whose pads",
        "reference voice presets (`presetRef`) and resolve in Flutter",
        "(`FactoryPresetJson`) before `applyDevicePreset`.",
        "",
        "## Constraints",
        "",
        "- CHH / OHH = two presets on `hihat_generator` (decay / tightness).",
        "- Tom Lo / Mid / Hi = three presets on `tom_generator` (`tomPitch`).",
        "- No cowbell / shaker / conga synth devices — omitted.",
        "- Rock / reggae / ambient are synthesized approximations.",
        "- Kit pads: notes 36–51 (Kick/Snare/CHH/OHH/…); hats share chokeGroup 1.",
        "",
        "## Families",
        "",
        "| Family | Slug | Voices | Genre tags |",
        "|--------|------|--------|------------|",
    ]
    for slug, display, genres, voices in FAMILIES:
        vnames = ", ".join(LABEL[v[0]] for v in voices)
        lines.append(
            f"| {display} | `{slug}` | {vnames} | {', '.join(genres)} |"
        )
    lines += [
        "",
        f"**Voice presets:** {len(presets)}",
        f"**Kit presets:** {len(FAMILIES)} (`preset:kit-{{family}}`)",
        "",
        "## IDs",
        "",
        "- Voice: `preset:{family}-{voice}` e.g. `preset:808-kick`",
        "- Kit: `preset:kit-{family}` e.g. `preset:kit-808`",
        "",
        "## Regenerating",
        "",
        "```powershell",
        "python tools/generate_drum_family_presets.py",
        "```",
        "",
        "Updates Dart maps under `device_preset_store_drums_*.dart` and appends",
        "drum family + kit rows in `manifest.json` (keeps non-drum presets).",
        "Kit pad JSON lives in `factory_preset_kits.dart`.",
        "",
    ]
    DOC.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    presets: list[dict] = []
    by_device: dict[str, list[tuple[str, dict]]] = {
        "kick_generator": [],
        "snare_generator": [],
        "clap_generator": [],
        "hihat_generator": [],
        "rimshot_generator": [],
        "tom_generator": [],
        "ride_generator": [],
        "crash_generator": [],
    }

    for slug, display, genres, voices in FAMILIES:
        for voice, label, dtype, params in voices:
            pid = f"preset:{slug}-{voice}"
            tags = ["factory", ROLE_TAG[voice], slug, *genres]
            # dedupe
            seen = set()
            tags = [t for t in tags if not (t in seen or seen.add(t))]
            presets.append(
                {
                    "id": pid,
                    "title": f"{display} · {label}",
                    "subtitle": f"{display} family · {label}",
                    "deviceType": dtype,
                    "tags": tags,
                    "family": slug,
                    "voice": voice,
                }
            )
            by_device[dtype].append((pid, params))

    file_map = {
        "kick_generator": "device_preset_store_drums_kick.dart",
        "snare_generator": "device_preset_store_drums_snare.dart",
        "clap_generator": "device_preset_store_drums_clap.dart",
        "hihat_generator": "device_preset_store_drums_hihat.dart",
        "rimshot_generator": "device_preset_store_drums_rimshot.dart",
        "tom_generator": "device_preset_store_drums_tom.dart",
        "ride_generator": "device_preset_store_drums_ride.dart",
        "crash_generator": "device_preset_store_drums_crash.dart",
    }
    for dtype, fname in file_map.items():
        path = STORE_DIR / fname
        path.write_text(emit_store_part(dtype, by_device[dtype]), encoding="utf-8")
        print(f"wrote {fname} ({len(by_device[dtype])})")

    # Manifest: keep non drum-family / non-kit presets
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    family_slugs = {f[0] for f in FAMILIES}
    existing = []
    for e in manifest.get("presets", []):
        tags = e.get("tags") or []
        eid = str(e.get("id", ""))
        if eid.startswith("preset:kit-"):
            continue
        if any(s in tags for s in family_slugs) and eid.startswith("preset:"):
            # drop prior family voice presets
            voice_part = eid.split(":")[-1]
            if "-" in voice_part and voice_part.split("-", 1)[0] in family_slugs:
                continue
        if eid.startswith("preset:") and any(
            eid.startswith(f"preset:{s}-") for s in family_slugs
        ):
            continue
        existing.append(e)

    voice_entries = [
        {
            "id": p["id"],
            "title": p["title"],
            "subtitle": p["subtitle"],
            "deviceType": p["deviceType"],
            "tags": p["tags"],
        }
        for p in presets
    ]
    kit_entries = kit_manifest_entries()
    manifest["presets"] = existing + voice_entries + kit_entries
    MANIFEST.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(
        f"manifest presets: {len(existing)} other + "
        f"{len(voice_entries)} drum family + {len(kit_entries)} kits"
    )

    write_doc(presets)
    print(f"wrote {DOC.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
