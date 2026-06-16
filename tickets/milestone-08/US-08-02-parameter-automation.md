# US-08-02: Parameter automation

## Type

Feature

## Milestone

Milestone 08 — Effects & automation

## User story

As a **user**, I can assign simple automation to a device parameter so playback changes the sound over time.

## Goal

Automation architecture in project model; at least one automatable parameter lane or clip.

## Background

- AGENT.md §8 Automation
- [project_model.md](../../docs/architecture/project_model.md)

## Scope

- Automation target IDs on parameters
- Automation clip or lane representation (simple curve/step OK for MVP)
- Evaluation on playback / offline path
- Serializable automation data

## Out of scope

- Complex curve editor UI
- Tempo-synced exotic curves

## Acceptance criteria

- [ ] Automation data targets a device parameter by ID
- [ ] Playback applies automation values
- [ ] Automation survives save/load
- [ ] C++ tests for automation evaluation
- [ ] Document automation model in architecture docs

## Tests required

- [ ] C++ automation evaluation tests
- [ ] Serialization tests

## User-visible result

Filter cutoff (or similar) moves during playback.

## Depends on

US-08-01

## Status

**Todo**
