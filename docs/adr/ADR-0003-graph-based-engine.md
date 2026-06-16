# ADR-0003: Graph-Based Audio Engine

## Status

Accepted

## Context

Tracks need device chains, effects, and future send/receive routing. A fixed pipeline would require rework.

## Decision

- Audio engine is **graph-based** from the start.
- MVP implements a **minimal linear chain** per track (instrument → optional effects → output).
- Graph mutations use snapshots/double-buffering; audio thread reads immutable state.

## Consequences

**Easier:** Extensible routing, consistent device model, offline render reuses same graph.

**Harder:** More upfront design than a single oscillator hack; must avoid overengineering early graph.

**Risks:** Complexity creep; mitigate with vertical slices and minimal MVP topology.
