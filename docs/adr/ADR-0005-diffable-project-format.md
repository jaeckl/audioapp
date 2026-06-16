# ADR-0005: Diffable Project Format

## Status

Accepted (amended: zip archive container)

## Context

Users and developers need inspectable, version-control-friendly project files. Binary blobs hinder diffing and debugging.

## Decision

- Projects are **`.audioapp.zip` archives** (ZIP container, stored compression).
- Inside the archive:
  - **`project.json`** — human-readable, diffable, versioned (source of truth for structure)
  - **`assets/samples/`** — sample binaries (M06+)
  - **`metadata/`** — sidecar data
- Stable string IDs for all entities.
- **`project_format_version`** field in `project.json` from first save implementation.
- Audio samples referenced by ID/path inside the archive; not embedded in JSON.
- No large binary inside `project.json`.

Unpacking the zip for inspection (e.g. `unzip project.audioapp.zip`) yields the same layout as the internal structure.

## Consequences

**Easier:** Single file to share; git-friendly `project.json` when unzipped; manual repair.

**Harder:** Must design schema carefully; migrations required over time.

**Risks:** JSON size for large projects; zip is transport format, not a second source of truth.
