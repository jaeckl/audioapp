# Project format v2: dedicated percussion devices

## Status

Accepted and implemented.

## Context

Project format v1 stored the generic `cymbal_generator`. Its model selector mixed
different instrument identities into one device contract. This made the DSP, UI,
automation vocabulary, and future algorithm evolution unnecessarily coupled.

## Decision

Project format version 2 removes `cymbal_generator` and adds four canonical device
types: `hihat_generator`, `ride_generator`, `tom_generator`, and
`rimshot_generator`. Crash remains the separate `crash_generator` device.

Every device owns one stable parameter vocabulary and one dedicated processor.
The implementations do not recognize old type IDs or parameter aliases.

Version-1 JSON is upgraded before normal project parsing. Migration walks track
devices, chains, synth note/audio child slots, and drum-machine pad devices. It
maps the former Cymbal device to Hi-Hat, rewrites its parameters, preserves gain
in the output panel, and rewrites matching automation and modulation targets.
The migrated in-memory project is version 2 and is saved only in version-2 form.

Unknown future format versions are rejected rather than interpreted partially.

## Consequences

- Existing projects remain loadable through an explicit, testable file migration.
- Device DSP and UI remain free of backward-compatibility branches.
- Migration may change the sound; exact legacy rendering is not a requirement.
- A future incompatible device algorithm should use a new type/versioned device
  identity when preserving the previous sound is important.
