# Milestone 05 — Save & load

**20 stories** — see [roadmap](roadmap.md) · [story_manifest.yaml](../../tickets/story_manifest.yaml)

| ID | Summary | Status |
|----|---------|--------|
| [US-05-01](../../tickets/milestone-05/US-05-01-save-project.md) | Save project via SAF CreateDocument (.audioapp.zip) | Done |
| [US-05-02](../../tickets/milestone-05/US-05-02-load-project.md) | Load project via SAF OpenDocument | Done |
| [US-05-03](../../tickets/milestone-05/US-05-03-projectjson-schema-v1-via-jucejson.md) | project.json schema v1 via juce::JSON | Done |
| [US-05-04](../../tickets/milestone-05/US-05-04-zip-archive-packs-json-and-sample-refs.md) | Zip archive packs JSON + sample refs | Done |
| [US-05-05](../../tickets/milestone-05/US-05-05-settings-screen-saveload-entry-points.md) | Settings screen save/load entry points | Done |
| [US-05-06](../../tickets/milestone-05/US-05-06-c-and-and-project_archive-round-trip-tests.md) | C++ project_archive round-trip tests | Done |
| [US-05-07](../../tickets/milestone-05/US-05-07-success-and-error-feedback-in-shell.md) | Success & error feedback in shell | Done |
| [US-05-08](../../tickets/milestone-05/US-05-08-cancel-saveload-leaves-project-unchanged.md) | Cancel save/load leaves project unchanged | Todo |
| [US-05-09](../../tickets/milestone-05/US-05-09-invalid-file-format-user-message.md) | Invalid file format user message | Todo |
| [US-05-10](../../tickets/milestone-05/US-05-10-new-project-discard-changes-confirm.md) | New project / discard changes confirm | Todo |
| [US-05-11](../../tickets/milestone-05/US-05-11-autosave-draft-to-app-sandbox-optional.md) | Autosave draft to app sandbox (optional) | Todo |
| [US-05-12](../../tickets/milestone-05/US-05-12-project-dirty-flag-and-unsaved-indicator.md) | Project dirty flag & unsaved indicator | Todo |
| [US-05-13](../../tickets/milestone-05/US-05-13-embed-imported-samples-in-zip-self-contained.md) | Embed imported samples in zip (self-contained) | Todo |
| [US-05-14](../../tickets/milestone-05/US-05-14-missing-sample-on-load-clear-error-and-relink-ui.md) | Missing sample on load — clear error + relink UI | Todo |
| [US-05-15](../../tickets/milestone-05/US-05-15-project-format-version-migrate-hook-stub.md) | Project format version migrate hook (stub) | Todo |
| [US-05-16](../../tickets/milestone-05/US-05-16-default-filename-from-project-name.md) | Default filename from project name | Todo |
| [US-05-17](../../tickets/milestone-05/US-05-17-save-restores-selected-track-and-playhead.md) | Save restores selected track & playhead | Todo |
| [US-05-18](../../tickets/milestone-05/US-05-18-large-project-save-progress-indicator.md) | Large project save progress indicator | Todo |
| [US-05-19](../../tickets/milestone-05/US-05-19-c-and-and-fuzz-malformed-zip-rejection.md) | C++ fuzz malformed zip rejection | Todo |
| [US-05-20](../../tickets/milestone-05/US-05-20-m05-po-demo-force-stop-reload-identical-session.md) | M05 PO demo — force-stop → reload identical session | Todo |

## PO sign-off demo

1. Add track + MIDI clip → **Save** (project.audioapp.zip)
2. Force-stop app → relaunch → **Load** same file
3. Arrangement, device strip, and Play match step 1

## Engineering notes

- C++: juce::JSON for project.json (AGENT.md §2.6)
- Android: SAF CreateDocument / OpenDocument in Kotlin (ADR-0006)
- Tests must parse real serialized output, not fixture strings only
