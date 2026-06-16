# Companion sub-stories (UX/UI + Interaction)

Each user-facing feature has **three** linked tickets:

```text
US-XX-YY-feature.md       ← vertical slice (engine + bridge + UI wiring)
US-XX-YY-ux-ui.md         ← layout, states, copy, visual polish
US-XX-YY-interaction.md   ← gestures, dialogs, feedback, cancel/error
```

Defined in [AGENT.md](../AGENT.md) §14.1.

## Workflow for agents

1. **Before coding** a user-facing feature: read or create both companions; PO signs off interaction map.
2. **Implement** parent feature to satisfy all three tickets in one increment (investor bar §2.8).
3. **Mark Done** only when demo scripts pass for parent + interaction companion; visual AC for UX companion.

## Generator

Companion files are generated from `tools/gen_companion_tickets.py` so IDs stay in sync. After changing the manifest, run:

```bash
python tools/gen_companion_tickets.py
```

## Index by milestone

| Milestone | Features with companions |
|-----------|---------------------------|
| M00 | US-00-02, US-00-03 |
| M01 | US-01-01 |
| M02 | US-02-01 … US-02-03 |
| M03 | US-03-01 … US-03-03 |
| M04 | US-04-01 … US-04-03 |
| M05 | US-05-01, US-05-02 |
| M06 | US-06-01 … US-06-05 |
| M07 | US-07-01, US-07-02 |
| M08 | US-08-01 … US-08-04 |
| M09 | US-09-02 (export UI only) |

Developer-only stories (US-00-01, US-09-01) have no companions.
