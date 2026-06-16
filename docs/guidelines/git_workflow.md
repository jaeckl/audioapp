# Git Workflow

## Branching

- Single `main` branch for MVP
- Short-lived feature branches optional for larger changes

## Commits

- Small, vertical slices
- Message format: imperative summary (`Add oscillator device skeleton`)

## Tickets

- Work is planned in `tickets/milestone-XX/`
- Complete tickets update relevant docs

## Pull requests

- Not required for solo MVP; use when collaborating
- Must pass build + tests listed in ticket

## Do not commit

- `.env`, API keys, local `JUCE_PATH` overrides
- CMake `build/` directories
- Android `.gradle` caches

See root `.gitignore`.
