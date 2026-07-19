# Audio profile lab

Measure **Low latency**, **Balanced**, and **Safe** on a connected Android phone. Outputs JSON + markdown under `runs/<timestamp>/`.

Default device serial: **ZY32MCWDJ6** (moto g86).

## Quick start (Windows lab)

```powershell
# Phone plugged in, USB debugging on
.\tools\audio_profile_lab\measure_audio_profiles.ps1

# Heavier built-in workload + fresh APK
.\tools\audio_profile_lab\measure_audio_profiles.ps1 -Scenario parallel -PlaySeconds 30 -Deploy

# Your real project: capture native XRUN lines while you play by hand
.\tools\audio_profile_lab\measure_audio_profiles.ps1 -Manual -PlaySeconds 60
```

Linux / cloud VM:

```bash
chmod +x tools/audio_profile_lab/measure_audio_profiles.sh
tools/audio_profile_lab/measure_audio_profiles.sh -s parallel -p 30
```

## What gets measured

| Source | Metrics |
|--------|---------|
| Integration test (`audio_profile_lab_test.dart`) | Per-profile `xRunCount`, `callbackOverruns`, `maxCallbackMicros`, deadline headroom, buffer sizes |
| `adb logcat` (`audioapp_engine`) | Native `XRUN: callback took … us (deadline … us)` lines |

Reference buffer targets: `profile_reference.json`. Built-in workloads: `scenarios.json`.

### Scenarios

| Name | Workload |
|------|----------|
| `light` | 1× oscillator, sustained note |
| `parallel` | 4× independent oscillator tracks |
| `serial_chain` | Oscillator → distortion → filter → reverb |
| `subtractive` | Subtractive synth, short chord |

Override with `-Scenario` (PowerShell) or `-s` (bash), or dart-defines when calling `flutter test` directly.

## Manual workflow (real project)

Use when built-in scenarios are too light:

1. `measure_audio_profiles.ps1 -Manual`
2. On phone: load your project
3. Settings → Audio engine → each profile
4. Play ≥ 20 s per profile
5. Press Enter in the terminal to stop logcat capture
6. Open `runs/<timestamp>/summary.md`

Diagnostics also visible in-app: Settings → **AAudio XRuns**, **DSP deadline misses**.

## Files

| File | Role |
|------|------|
| `measure_audio_profiles.ps1` | Windows entry point |
| `measure_audio_profiles.sh` | Bash entry point |
| `parse_lab_output.py` | Merge flutter log + logcat → summary |
| `profile_reference.json` | Expected AAudio profile parameters |
| `scenarios.json` | Scenario catalog |
| `app_flutter/integration_test/audio_profile_lab_test.dart` | On-device automated benchmark |

## Direct flutter test

```bash
cd app_flutter
flutter test integration_test/audio_profile_lab_test.dart -d ZY32MCWDJ6 \
  --dart-define=LAB_SCENARIO=parallel \
  --dart-define=LAB_PLAY_SECONDS=30
```

Look for `@@AUDIO_PROFILE_LAB@@{...}` in stdout, or run the wrapper script to parse automatically.

---

## Related: adaptive background freeze (design notes)

**Goal:** Lower CPU by freezing idle tracks to PCM, like bounce-in-place, but automatically in the background.

**Constraint (same family as parallel DSP):** Tracks are not isolated islands. Audio/MIDI **sends and receives**, sidechain, group buses, and **live-modulated** upstream devices mean a “frozen” track may still need its **sources kept warm**:

| Relationship | Why full unload fails |
|--------------|----------------------|
| Another track receives this track’s audio | Receiver needs correct signal or silence with correct latency |
| MIDI routed into a live synth on another track | Source phrase/phase irrelevant, but mod sources on the frozen chain may still affect live neighbors |
| Modulation from a device on a frozen track | Target on a live track still needs current mod signal |
| Send → return / feedback edge | Frozen block must stay time-aligned; feedback paths need previous-block state |

**Implication:** Adaptive freeze is not “stop processing this track entirely.” It is a **tiered playback mode**:

1. **Full realtime** — audible now, or feeding a live downstream path
2. **Shadow / warm standby** — not heard, but still advances LFOs, envelope tails, oscillator phase, delay lines when anything downstream or mod-linked is live (cheap subset of DSP)
3. **Frozen PCM** — offline-rendered loop; only valid when graph compiler proves **no live edges** depend on realtime state from that subtree

The existing manual **Freeze track** path already swaps clip playback for PCM when enabled. Adaptive freeze extends that with a **graph reachability pass** (similar to `buildProcessorGraph` topo + edge scan):

- If track T is in the live cone of any audible/output/modulated node → tier 1 or 2
- If T is muted, not soloed, no taps, no outgoing edges to live nodes → candidate for tier 3 background bounce
- On un-solo / un-mute / route change → promote back to tier 1 instantly (PCM + warm state handoff)

**Instant takeover** needs a short crossfade or aligned phase match when promoting frozen → live; warm-standby tier avoids audible jumps for modulated sources.

This lab tooling helps validate profiles **before** adaptive freeze: know which scenarios already exceed deadline at Balanced, so freeze tiers target the right tracks.
