# Integration Plan (VP-4)

## Order of operations

The slice is small enough to land in a single PR. The recommended
order is:

```text
0. Architect (this document, done)
        │
1. VP-4.1: Production Kotlin                         ┐
   (ProjectArchiveStore + MainActivity)               ├─ both in same PR
2. VP-4.2: ProjectUriStore + tests                   ┘  by one worker
        │
3. Reviewer subagent (after 1+2)
        │
4. Local developer: on-device manual script (after 3)
        │
5. PR ready to merge
```

## Step 0 — Architect (this document)

- **Done** in this conversation.
- Output: the six new docs in
  `docs/features/load-project-zip-listing-fix/`:
  `09-feature-brief.md`, `10-architecture.md`,
  `11-canonical-vocabulary.md`, `12-api-and-data-contracts.md`,
  `13-vertical-work-packages-and-tests.md`,
  `14-integration-plan.md`.
- Side effect: none — no source files were modified.
- Key design decisions committed:
  - Use `ACTION_OPEN_DOCUMENT_TREE` instead of
    `ACTION_OPEN_DOCUMENT`; bypass MediaStore's `mime_type=NULL`
    exclusion entirely.
  - List children via
    `DocumentsContract.buildChildDocumentsUriUsingTree` and filter
    by filename suffix `PROJECT_FILE_SUFFIX = ".audioapp.zip"`
    (case-insensitive), ignoring the MIME column.
  - Show the listing inside a native `MaterialAlertDialog`; do not
    add any Dart UI.
  - Persist the last folder URI in a new
    `ProjectUriStore.last_folder_uri` SharedPreferences key (the
    existing `last_document_uri` key is preserved unchanged).
  - Delete `OPEN_ARCHIVE_MIME_FILTER` (no caller) and
    `OpenProjectDocument` (replaced by `OpenProjectFolder`).
  - Keep `PROJECT_MIME_TYPE` and `ARCHIVE_MIME_TYPE` constants
    (preserved for the inbound `ACTION_VIEW` follow-up and the save
    flow respectively).
  - Keep `MediaScannerConnection.scanFile` on save (VP-3 hygiene is
    preserved, even though it is no longer load-path-critical).
  - No Flutter / Dart / C++ / JNI / Gradle / manifest changes
    (unless `com.google.android.material:material` fails to
    resolve, in which case one `implementation(...)` line is added
    to `build.gradle.kts`).

## Step 1 + 2 — VP-4.1 + VP-4.2 (production + uri-store + tests)

**Single implementation worker** runs both packages in one PR. The
worker reads `09-feature-brief.md` through
`13-vertical-work-packages-and-tests.md` and obeys canonical names
exactly. It touches:

| File | Allowed change |
|------|----------------|
| `app_flutter/android/app/src/main/kotlin/com/audioapp/daw/ProjectArchiveStore.kt` | Add `PROJECT_FILE_SUFFIX`, `LoadFolderEntry`, `listAudioAppZipsIn`, `takeFolderUriPermission`. Delete `OPEN_ARCHIVE_MIME_FILTER`. |
| `app_flutter/android/app/src/main/kotlin/com/audioapp/daw/MainActivity.kt` | Delete `OpenProjectDocument`. Add `OpenProjectFolder`, `onFolderPicked`, `showLoadFolderDialog`, `showEmptyLoadFolderDialog`. Replace `openProjectArchive` registration with `openProjectFolder`. Update `launchLoadArchivePicker`'s launch line. |
| `app_flutter/android/app/src/main/kotlin/com/audioapp/daw/ProjectUriStore.kt` | Add `KEY_LAST_FOLDER_URI`, `saveLastFolderUri`, `loadLastFolderUri`. |
| `app_flutter/android/app/src/test/kotlin/com/audioapp/daw/LoadFolderListingTest.kt` (new) | 4 tests (T12a–d). |
| `app_flutter/android/app/src/test/kotlin/com/audioapp/daw/ProjectUriStoreTest.kt` (new) | 3 tests (T13a–c). |
| `app_flutter/android/app/src/test/kotlin/com/audioapp/daw/OpenProjectFolderTest.kt` (new) | 2 tests (T14a–b). |
| `app_flutter/android/app/src/test/kotlin/com/audioapp/daw/ProjectArchiveMimeTest.kt` (delete) | Whole file. |
| `app_flutter/android/app/src/test/kotlin/com/audioapp/daw/OpenProjectDocumentTest.kt` (delete) | Whole file. |
| `app_flutter/android/app/build.gradle.kts` (only if `material` import fails to resolve) | Add one `implementation("com.google.android.material:material:1.12.0")` line. No other changes. |
| `app_flutter/android/app/src/main/AndroidManifest.xml` | **No changes.** |
| All Flutter / Dart files | **No changes.** |
| All C++ / JNI files | **No changes.** |

The worker reports back with:

- A diff summary (lines changed per file; lines deleted per file).
- Confirmation that the 9 new tests exist at the named paths.
- Confirmation that the 2 obsolete test files are deleted.
- Confirmation that `OPEN_ARCHIVE_MIME_FILTER` and `OpenProjectDocument`
  do not appear anywhere in the diff (or in the resulting tree).
- Confirmation that `MaterialAlertDialogBuilder` resolves at compile
  time (either via the transitive `material` dep from
  `androidx.activity:activity-ktx`, or via the new
  `implementation(...)` line if added).
- Confirmation that `flutter analyze` and `flutter test` still pass
  with 0 errors.
- `./gradlew :app:testDebugUnitTest` output: BUILD SUCCESSFUL, 9
  tests pass.

If any test fails, the worker does **not** paper over it. It reports
the failure to the orchestrator with the full Gradle output. The
orchestrator decides whether to amend the contract or fix the
production code.

## Step 3 — Reviewer

A single reviewer subagent runs after VP-4.1 + VP-4.2. The reviewer
checks the diff against the contract:

- [ ] `PROJECT_FILE_SUFFIX = ".audioapp.zip"` exists in
      `ProjectArchiveStore.kt` and is the exact literal.
- [ ] `LoadFolderEntry` data class exists with the four fields
      (`documentUri`, `displayName`, `sizeBytes`, `lastModifiedMillis`).
- [ ] `listAudioAppZipsIn(context, treeUri)` is implemented per
      `12-api-and-data-contracts.md` §3 (build child docs URI, query
      columns, filter by suffix, return list).
- [ ] `takeFolderUriPermission(context, treeUri)` exists and catches
      `SecurityException`.
- [ ] `OPEN_ARCHIVE_MIME_FILTER` is **deleted** (no occurrences
      remain).
- [ ] `PROJECT_MIME_TYPE` and `ARCHIVE_MIME_TYPE` constants are
      preserved.
- [ ] `MainActivity.OpenProjectDocument` is **deleted** (no
      occurrences remain).
- [ ] `MainActivity.OpenProjectFolder` exists and is `internal` (not
      `private`).
- [ ] `MainActivity.openProjectFolder` ActivityResultLauncher is
      registered and calls `onFolderPicked`.
- [ ] `MainActivity.launchLoadArchivePicker` calls
      `openProjectFolder.launch(loadLastFolderUri(this))` (and **not**
      `openProjectArchive.launch(...)`).
- [ ] `MainActivity.onFolderPicked(uri)` exists and matches
      `12-api-and-data-contracts.md` §8 (null → cancelled; non-null
      → save + takePermission + list + show dialog).
- [ ] `MainActivity.showLoadFolderDialog(entries)` and
      `showEmptyLoadFolderDialog()` exist.
- [ ] `ProjectUriStore.KEY_LAST_FOLDER_URI = "last_folder_uri"` is
      added.
- [ ] `ProjectUriStore.saveLastFolderUri` and `loadLastFolderUri`
      exist.
- [ ] `ProjectUriStore.KEY_LAST_DOCUMENT_URI`,
      `saveLastDocumentUri`, `loadLastDocumentUri` are **byte-for-byte
      unchanged**.
- [ ] Save flow is **byte-for-byte unchanged**:
      `createProjectArchive` registration,
      `launchSaveArchivePicker`, `onSaveArchivePicked`,
      `ARCHIVE_MIME_TYPE = "application/zip"`,
      `MediaScannerConnection.scanFile` call.
- [ ] `configureFlutterEngine`'s `when (call.method)` branches are
      **byte-for-byte unchanged**.
- [ ] JNI declarations are **byte-for-byte unchanged**.
- [ ] `jsonToMap` / `mapToJson` / `jsonValue` / `mapValueToJson` are
      unchanged.
- [ ] `AndroidManifest.xml` is **byte-for-byte unchanged** from
      VP-3.
- [ ] `build.gradle.kts` is unchanged **unless** `material` import
      fails to resolve (then exactly one `implementation(...)` line
      is added).
- [ ] No Flutter / Dart / C++ / JNI file is modified.
- [ ] No new `<uses-permission>` entry.
- [ ] No `pubspec.yaml` change.
- [ ] No new `MethodChannel` method on `EngineBridge`.
- [ ] `LoadFolderListingTest.kt`, `ProjectUriStoreTest.kt`,
      `OpenProjectFolderTest.kt` exist at the expected paths with the
      named tests (T12a–d, T13a–c, T14a–b).
- [ ] `ProjectArchiveMimeTest.kt` and `OpenProjectDocumentTest.kt`
      are deleted.
- [ ] `flutter test` and `flutter analyze` pass with no new failures.
- [ ] `./gradlew :app:testDebugUnitTest` passes with 9 tests.

The reviewer may block on any contract deviation. The orchestrator
resolves review feedback by spawning a follow-up implementation
worker.

## Step 4 — On-device manual script (local developer)

The cloud VM cannot run an Android emulator. The local developer
runs the 6-step on-device script in
`13-vertical-work-packages-and-tests.md` §"On-device manual script"
on a physical device or a host-managed emulator.

The local developer reports back with:

- Which of the 6 tests passed.
- For any test that failed: a screenshot or logcat snippet showing
  the actual behavior.
- The Android version and device model used (must include a Moto g86
  Power 5G Android 16 result, because that is the device where the
  bug was reproduced in VP-1/VP-2/VP-3).

This step is **not optional** per `PROJECT-SPEC.md` §2.7 and §17.

## Step 5 — Merge

Once the cloud-VM tests pass (Steps 1–3) and the on-device script
passes (Step 4), the PR is ready to merge.

## Risks and mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| `MaterialAlertDialogBuilder` is not on the classpath (Flutter's `androidx.activity:activity-ktx` may not transitively pull `com.google.android.material:material` in all Gradle versions) | Medium | Low | If the import fails to resolve during implementation, add exactly one `implementation("com.google.android.material:material:1.12.0")` line to `build.gradle.kts`. The contract permits this single line; no other Gradle changes. |
| `DocumentsContract.buildChildDocumentsUriUsingTree` throws on some OEM tree URIs | Medium | Low | The helper catches and returns an empty list. The empty-state dialog then offers "Pick a different folder." |
| `takePersistableUriPermission` throws `SecurityException` because the OEM provider doesn't support persistable tree grants | Low | Low | Existing pattern: catch and ignore. The session grant is sufficient for the immediate `getChildDocuments` call; the worst case is that the next launch lands at the system default rather than the last folder. |
| The user picks a folder, sees the in-app dialog, taps "Cancel" — the load is treated as cancelled, but they expected to come back to the dialog | Low | Low | The dialog has both "Pick a different folder" (re-launches picker) and "Cancel" (clears `pendingLoadResult`) buttons. The UX is explicit. |
| `MainActivity.openProjectFolder.launch(loadLastFolderUri(this))` passes a tree URI to `OpenDocumentTree.createIntent`'s `input: Uri?` parameter, but our override also sets `EXTRA_INITIAL_URI` — duplicate plumbing | Very low | None | The superclass of `OpenDocumentTree` honors `input` as the initial location; the system reads `EXTRA_INITIAL_URI` if `input` is null. Setting both is harmless (the system picks one). The test T14b covers the no-throw case. |
| Pre-VP-4 saves (whose URIs are in `last_document_uri` but who have `mime_type=NULL` in MediaStore) cannot be re-loaded without going through the folder picker | High | Low | This is by design. The user opens the folder picker, navigates to the folder that contains their old saves, and picks from the in-app list. The pre-VP-4 URI is still loadable — it just requires one more navigation step. |
| The case-insensitive match picks up `Foo.AUDIOAPP.ZIP.bak` (file ends with `.bak`) | Very low | Very low | `endsWith(".audioapp.zip", ignoreCase = true)` matches strings ending in the literal `.audioapp.zip` (including the leading dot). `Foo.AUDIOAPP.ZIP.bak` does not end in `.audioapp.zip`. False-positive impossible. |

## Definition of Done (VP-4)

Per `PROJECT-SPEC.md` §17, all of:

- [ ] VP-4.1's diff matches the file ownership above exactly.
- [ ] VP-4.2's 9 tests pass under
      `./gradlew :app:testDebugUnitTest` on the cloud VM.
- [ ] `cd app_flutter && flutter analyze` exits 0 (no new errors;
      Flutter is unchanged so this should already pass).
- [ ] `cd app_flutter && flutter test` exits 0 (no new Flutter
      tests; existing tests still pass).
- [ ] No file outside the table in Step 1 + 2 is modified.
- [ ] No new `<uses-permission>` is added to `AndroidManifest.xml`.
- [ ] No new package is added to `pubspec.yaml`.
- [ ] The 6-step on-device manual script passes on a physical Android
      device (including a Moto g86 Power 5G Android 16).
- [ ] The "wow moment" works: tap **Settings → Open project**, see
      the folder picker open at the last folder, pick the folder,
      see the in-app dialog list matching `.audioapp.zip` files,
      tap one, the arrangement updates.

## Open questions for the orchestrator

These are flagged but do **not** block implementation. The contract
commits to a default; the orchestrator can override before kicking
off the implementation worker.

1. **Should the empty-state dialog have a "Create new project"
   button?** No. The save flow already has its own button. Adding
   one here confuses the load vs save semantics. **Default: no.**
2. **Should we support `last_folder_uri` for **tree** URIs and
   `last_document_uri` for **document** URIs in a single picker,
   so the picker can pre-fill with the most-recently-used of
   either?** No. The picker is folder-only now; we only need
   `last_folder_uri`. The `last_document_uri` key is preserved for
   potential future "open recent" UI but is not used in the load
   path. **Default: do not unify.**
3. **Should `MainActivity.showLoadFolderDialog` use a custom
   `RecyclerView` adapter to show size + lastModified, or just the
   display name?** The contract uses `setSingleChoiceItems(labels, ...)`
   with display names only. A richer adapter is a follow-up.
   **Default: display names only.**
4. **Should the dialog auto-dismiss on rotation?** `MaterialAlertDialog`
   handles configuration changes by default; the underlying Android
   dialog framework restores it from `onSaveInstanceState`. No code
   needed in our slice. **Default: rely on framework behavior.**

## Out-of-scope follow-ups (NOT part of this PR)

These are flagged for the orchestrator's awareness. They are **not**
in the current bug fix.

- **Handle inbound `ACTION_VIEW` with the vendor MIME in
  `MainActivity.configureFlutterEngine`.** The manifest already
  declares we handle `application/vnd.audioapp.project+zip` (from
  VP-1). Once we route inbound `ACTION_VIEW` to
  `launchLoadArchivePicker`, the user can open `.audioapp.zip`
  attachments from email / Files app directly into the load flow.
  This is a ~10-line `configureFlutterEngine` change.
- **Add a Kotlin integration test that exercises the full
  folder-pick + listing + load round-trip on an emulator.** Out of
  scope for this slice; the on-device manual script covers it.
- **Sort the in-app dialog rows by `lastModifiedMillis` descending.**
  Trivial `entries.sortedByDescending { it.lastModifiedMillis }` in
  `onFolderPicked`. Follow-up.
- **Show file size and last-modified in the dialog rows.** Requires
  a custom adapter instead of `setSingleChoiceItems`. Follow-up.
- **Bulk-select + delete or share from the dialog.** Way out of
  scope.
- **Localize the in-app dialog strings.** The dialog uses English
  literals ("Open project", "No .audioapp.zip files", "Cancel",
  "Pick a different folder"). The rest of the app is already
  English; localization is orthogonal to this fix.
- **Audit and delete `ProjectArchiveStore.deriveInitialUri`** (added
  in VP-1, now unreferenced). Trivial follow-up; not part of this
  PR.

## Why the orchestrator should run VP-4.1 + VP-4.2 in one PR

The two packages:

- Edit disjoint files (`ProjectArchiveStore.kt` + `MainActivity.kt`
  vs. `ProjectUriStore.kt` + test files).
- Are linearly orderable: the tests in VP-4.2 reference symbols
  defined in VP-4.1; running them as a single worker eliminates the
  merge-conflict surface.
- Together produce the smallest possible diff that demonstrates the
  end-to-end behavior. Splitting them across two PRs would require
  an interim state where the folder picker is wired but the
  `last_folder_uri` persistence is missing — which would compile and
  pass tests, but provide no demonstrable improvement to the user.

The orchestrator's "single worker" recommendation matches `PROJECT-SPEC.md`
§2.5 ("don't reinvent the wheel") and §2.7 ("the slice must be
demo-able once on device").
