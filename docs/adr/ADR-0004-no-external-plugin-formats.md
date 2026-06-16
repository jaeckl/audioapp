# ADR-0004: No External Plugin Formats

## Status

Accepted

## Context

Mobile apps cannot load desktop VST/AU plugins safely or consistently. App store and sandbox constraints favor built-in devices.

## Decision

- **No** VST, VST3, LV2, CLAP, AAX, or desktop AudioUnit hosting.
- All sound-producing and processing units are **internal devices** shipped with the app.
- Future monetization via in-app purchase of device packs, not runtime native library downloads.

## Consequences

**Easier:** Predictable RT safety, simpler QA, no plugin crash surface.

**Harder:** Must implement desired DSP in-house or license statically linked modules.

**Risks:** Feature parity vs desktop DAWs; acceptable for mobile MVP scope.
