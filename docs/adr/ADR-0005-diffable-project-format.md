# ADR-0005: Diffable Project Format

## Status

Accepted

## Context

Users and developers need inspectable, version-control-friendly project files. Binary blobs hinder diffing and debugging.

## Decision

- Folder-based projects with human-readable **`project.json`**.
- Stable string IDs for all entities.
- **`project_format_version`** field from first save implementation.
- Audio samples referenced by ID/path; copied into export bundles on share.
- No large binary inside JSON.

## Consequences

**Easier:** Git-friendly projects, manual repair, migration testing.

**Harder:** Must design schema carefully; migrations required over time.

**Risks:** JSON size for large projects; may add binary snapshots later for cache only, not source of truth.
