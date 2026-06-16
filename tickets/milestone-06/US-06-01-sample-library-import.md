# US-06-01: Sample library import

## Type

Feature

## Milestone

Milestone 06 — Sample library & sampler

## User story

As a **user**, I can browse a sample library and import or reference a local audio file for use in my project.

## Goal

Sample library UI + library index in engine; file references with stable sample IDs.

## Background

- AGENT.md §7 Sample Library

## Scope

- Sample library view in Flutter
- Import/reference from device storage (Android SAF or path)
- Sample metadata (name, path, id) in project engine
- List/browse UI

## Out of scope

- Sampler playback (US-06-02)
- Time-stretch, pitch-shift, slicing

## Acceptance criteria

- [ ] User can open sample library
- [ ] User can import/select a local audio file
- [ ] Sample appears in library list with stable ID
- [ ] Missing file handling documented

## Tests required

- [ ] C++ sample ref tests
- [ ] Widget tests for library UI
- [ ] Manual import smoke

## User-visible result

Library shows imported samples.

## Depends on

US-05-02

## Status

**Todo**
