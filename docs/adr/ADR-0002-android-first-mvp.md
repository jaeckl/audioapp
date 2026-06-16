# ADR-0002: Android-First MVP

## Status

Accepted

## Context

The team needs to ship a playable vertical slice without splitting effort across iOS and Android tooling. iOS requires macOS and Xcode.

## Decision

- MVP targets **Android only** (phone and tablet).
- Architecture must not prevent future iOS port (Flutter + JUCE are cross-platform).
- No iOS-specific code unless required for clean abstractions.
- Dev container excludes Xcode; documents host device workflow for Android.

## Consequences

**Easier:** Single platform QA, one store pipeline for MVP, faster iteration.

**Harder:** iOS-specific issues discovered later; must keep bridge and engine portable.

**Risks:** Android fragmentation; test on physical device and common emulator images.
