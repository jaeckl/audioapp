# US-06-04: MIDI triggers sample

## Type

Feature

## Milestone

Milestone 06 — Sample library & sampler

## User story

As a **user**, I press **Play** and hear my **sampler sample** triggered by MIDI clip notes — a simple sample-based loop.

## Goal

M06 **wow moment:** drum loop from sampler + MIDI clip + save/load round-trip.

## Background

- US-03-03 MIDI scheduling — extend to sampler voices
- AGENT.md §2.8 investor quality

## UX flow

1. Track with sampler + assigned sample + MIDI clip (notes on grid).
2. Play → sample triggers on note onsets (one-shot per note for MVP).
3. Stop → silence.
4. Save → kill app → Load → Play → same loop.

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | No underruns on Moto-class device for 4-voice drum loop |

## Scope

- Sampler voice pool in audio path
- MIDI note → trigger sample with pitch policy documented (e.g. 1:1 or fixed)
- Reference sample by ID in project file
- Offline decode before play if needed

## Out of scope

- Polyphonic choke groups, round-robin
- Time-stretch / pitch-shift

## Acceptance criteria

- [ ] MIDI notes trigger assigned sample audibly
- [ ] Multiple notes in clip produce correct pattern
- [ ] Save/load preserves sample ref + clip + triggers correctly
- [ ] C++ golden or RMS test for known pattern
- [ ] No alloc per note in RT callback
- [ ] Demo script passes on device

## Demo script (on-device, ~60s)

1. Sampler + kick assigned → MIDI clip 4-on-floor → Play → hear loop.
2. Save → force-stop → Load → Play → same loop.

## Tests required

- [ ] C++ sampler trigger + archive round-trip
- [ ] Golden/offline render test
- [ ] Manual on device

## User-visible result

**Wow:** first sample-based beat on mobile.

## Realtime/performance notes

Voice pool preallocated; sample data read-only on audio thread.

## Depends on

US-06-03, US-03-03


## Companion stories

- [UX/UI](US-06-04-ux-ui.md)
- [Interaction](US-06-04-interaction.md)

## Status

**Todo**
