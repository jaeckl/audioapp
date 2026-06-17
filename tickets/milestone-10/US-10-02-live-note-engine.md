# US-10-02: Live noteOn/noteOff engine

## User story

As a **user**, tapping pads or keys sends **live MIDI** through the selected track's sampler or oscillator while transport is stopped.

## Acceptance criteria

- [x] `noteOn` / `noteOff` / `allNotesOff` bridge (no snapshot per touch)
- [x] RT-safe voice pool mixed in audio callback
- [x] Sampler uses ADSR/filter chain (not previewSample)
- [x] C++ test: note produces non-silent buffer

## Status

Done
