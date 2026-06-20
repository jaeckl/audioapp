# Integration Plan

## Order of operations

The slice is small enough to land in a single PR. The
recommended order is:

```text
0. Architect (this document, done)
        │
1. VP-1: Production Kotlin + Manifest + Gradle     (sequential)
        │
2. VP-2: Kotlin unit tests                          (sequential)
        │
3. Reviewer subagent                                (after 2)
        │
4. Local developer: on-device manual script          (after 3)
        │
5. PR ready to merge
```

## Step 0 — Architect (this document)

- **Done** in this conversation.
- Output: the eight docs in
  `docs/features/load-project-zip-listing-fix/`,
  rewritten from scratch.
- Side effect: none — no source files were modified.
- Key design decisions committed:
  - Use `application/vnd.audioapp.project+zip` (vendor
    MIME + `+zip` suffix), valid per RFC 6838 §4.2.8
    and RFC 6839 §3.6.
  - Keep the save MIME as `application/zip` so the
    system's save dialog can produce a real zip.
  - Pass `EXTRA_INITIAL_URI` from
    `ProjectUriStore.last_document_uri` directly (it
    is a valid document URI; the system handles the
    "fall back to parent folder" behavior).
  - Subclass `ActivityResultContracts.OpenDocument`
    to add `EXTRA_INITIAL_URI` (the API explicitly
    supports subclassing for extra extras).
  - No new UI, no new Dart code, no new C++ code, no
    new permissions.

## Step 1 — VP-1 (production code)

A single implementation-worker subagent runs VP-1. It
edits the four allowed files only:

1. `ProjectArchiveStore.kt`:
   - Add `const val PROJECT_MIME_TYPE`.
   - Add `val OPEN_ARCHIVE_MIME_FILTER`.
   - Delete the old `openArchiveMimeFilter`.
   - Add `fun deriveInitialUri(context: Context): Uri?`.
2. `MainActivity.kt`:
   - Add `import android.provider.DocumentsContract`.
   - Add `internal class OpenProjectDocument` (note:
     `internal`, not `private`, so VP-2's tests can
     reference it from the same package).
   - Change `openProjectArchive` registration to use
     `OpenProjectDocument()`.
   - Change `.launch(...)` argument to
     `OPEN_ARCHIVE_MIME_FILTER`.
3. `AndroidManifest.xml`:
   - Add one `<intent-filter>` block inside the
     `MainActivity` block.
4. `build.gradle.kts`:
   - Add `testOptions { unitTests.isReturnDefaultValues = true }`.
   - Add `testImplementation("junit:junit:4.13.2")`.

The VP-1 worker reads `01-architecture.md` through
`06-vertical-work-packages.md` and obeys canonical
names exactly. It touches **only** the four files
listed above. It does **not** write tests (VP-2 does).

The VP-1 worker reports back with:

- A diff summary (lines changed per file).
- Confirmation that the MIME literal is identical
  across `ProjectArchiveStore.kt` and
  `AndroidManifest.xml`.
- Confirmation that the `OPEN_ARCHIVE_MIME_FILTER`
  array shape matches the contract (2 entries, vendor
  first, generic second).
- Confirmation that `OpenProjectDocument` is
  `internal` (not `private`) so VP-2's tests can
  reference it.
- Any deviation from the contract (should be zero).

## Step 2 — VP-2 (Kotlin unit tests)

A single test-writer subagent runs VP-2. It creates
**two new files** under
`app_flutter/android/app/src/test/kotlin/com/audioapp/daw/`:

1. `ProjectArchiveMimeTest.kt` — 5 tests (T1–T5).
2. `OpenProjectDocumentTest.kt` — 4 tests (T6–T9).

The VP-2 worker reads `07-test-contract.md` and
implements the named tests. It uses plain JUnit 4 on
the JVM (`org.junit.Test`, `org.junit.Assert.*`).
It may add Mockito as a `testImplementation` if
needed; it must not add Robolectric (the contract
commits to plain JVM).

After writing the tests, the VP-2 worker runs:

```bash
cd app_flutter/android
./gradlew :app:testDebugUnitTest
```

Expected: BUILD SUCCESSFUL, 9 tests pass. The worker
reports back with the Gradle output.

If any test fails, the worker does **not** paper over
it. It reports the failure to the orchestrator with
the full Gradle output. The orchestrator decides
whether to amend the contract or fix the production
code.

## Step 3 — Reviewer

A single reviewer subagent runs after VP-2. The
reviewer checks the diff against the contract:

- [ ] MIME literal identical in
      `ProjectArchiveStore.kt` (constant + filter
      array[0]) and `AndroidManifest.xml`.
- [ ] `OPEN_ARCHIVE_MIME_FILTER` is exactly 2 entries;
      index 0 is the vendor MIME; index 1 is
      `application/zip`.
- [ ] Old `openArchiveMimeFilter` constant is
      **deleted** (no occurrences of the old name
      remain).
- [ ] `OpenProjectDocument` is `internal`, not
      `private`.
- [ ] `OpenProjectDocument.createIntent` calls
      `super.createIntent(ctx, input)` and
      `putExtra(DocumentsContract.EXTRA_INITIAL_URI,
      uri)` only when `deriveInitialUri(context)` is
      non-null.
- [ ] `MainActivity.openProjectArchive` registration
      uses `OpenProjectDocument()` (not the bare
      `OpenDocument()`).
- [ ] `.launch(...)` argument in
      `launchLoadArchivePicker` is
      `ProjectArchiveStore.OPEN_ARCHIVE_MIME_FILTER`.
- [ ] Save flow is **byte-for-byte unchanged**:
      `createProjectArchive` registration,
      `launchSaveArchivePicker`, `onSaveArchivePicked`,
      `ARCHIVE_MIME_TYPE = "application/zip"`.
- [ ] Load callback body in `onLoadArchivePicked` is
      unchanged.
- [ ] No JNI signature changed.
- [ ] No `jsonToMap` / `mapToJson` / `jsonValue` /
      `mapValueToJson` changed.
- [ ] `AndroidManifest.xml` adds exactly one
      `<intent-filter>` block (5 lines) and changes
      nothing else.
- [ ] `build.gradle.kts` adds exactly
      `testOptions { ... }` (3 lines) and
      `testImplementation("junit:junit:4.13.2")`
      (1 line), and changes nothing else.
- [ ] No Flutter / Dart / C++ / JNI file is
      modified.
- [ ] No new `<uses-permission>` entry.
- [ ] No `pubspec.yaml` change.
- [ ] No new `MethodChannel` method on
      `EngineBridge`.
- [ ] `flutter test` and `flutter analyze` pass with
      no new failures.
- [ ] `./gradlew :app:testDebugUnitTest` passes with
      9 tests.

The reviewer may block on any contract deviation.
The orchestrator resolves review feedback by spawning
a follow-up implementation worker.

## Step 4 — On-device manual script (local developer)

The cloud VM cannot run an Android emulator. The
local developer runs the 6-step on-device script in
`07-test-contract.md` §"On-device manual script" on
a physical device or a host-managed emulator.

The local developer reports back with:

- Which of the 6 tests passed.
- For any test that failed: a screenshot or logcat
  snippet showing the actual behavior.
- The Android version and device model used.

This step is **not optional** per `PROJECT-SPEC.md` §2.7
and §17.

## Step 5 — Merge

Once the cloud-VM tests pass (Steps 1–3) and the
on-device script passes (Step 4), the PR is ready to
merge.

## Risks and mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Vendor MIME is not honored by the user's SAF provider (older Files app, custom OEM file manager) | Medium | Low | `application/zip` is in the filter array as a fallback. The picker shows our files via the fallback. Visual verification in on-device script Test 2. |
| `EXTRA_INITIAL_URI` is ignored on older Android (API 26 = our minSdk; the extra has been around since API 26 but support is patchy before API 29) | Medium | Low | On API 26–28, the picker ignores the extra and opens at SAF default. The user can still navigate; the fix is no worse than today. On API 29+ the behavior is correct. |
| The `Intent.EXTRA_INITIAL_URI` is silently dropped if the stored URI has been revoked (user deleted the file from Files app) | Medium | Low | SAF falls back to default location. No crash. User can re-save to refresh the URI. |
| `OpenProjectDocument.createIntent` is a thin subclass and could break if AndroidX `OpenDocument` changes its signature in a future version | Low | Low | We pin `androidx.activity:activity-ktx:1.9.3` (already in `build.gradle.kts`). Future updates would require re-validation, which is normal. |
| The new `<intent-filter>` makes our app a handler for `application/vnd.audioapp.project+zip`, which could be claimed by other apps in the future | Very low | Low | The vendor MIME is unique enough (`vnd.audioapp.project`) that collision is unlikely. If it ever happens, the system shows a chooser, not an error. |
| The Kotlin unit tests pass on the JVM but fail on a real device because of a JVM-vs-Dalvik difference | Low | Low | The tests are deliberately structural (asserting no-throw and intent-extra shapes). The on-device script (Step 4) is the canonical end-to-end verification. |
| The `<intent-filter>` with `ACTION_VIEW` makes our app appear in "Open with" dialogs for `.audioapp.zip` files opened from other apps, but our `MainActivity.configureFlutterEngine` does not yet handle the intent | Medium | Low | This is acceptable per the contract: the manifest declaration is additive; actual handling of inbound `ACTION_VIEW` is a follow-up. The current PR's behavior is "open from another app shows us in the chooser; tapping us does nothing yet (the app launches as a new MAIN activity)." We log a TODO. |

## Definition of Done (this feature)

Per `PROJECT-SPEC.md` §17, all of:

- [ ] VP-1's diff matches the four-file scope exactly
      (see `05-file-ownership.md`).
- [ ] VP-2's 9 tests pass under
      `./gradlew :app:testDebugUnitTest` on the cloud VM.
- [ ] `cd app_flutter && flutter analyze` exits 0 (no
      new errors; Flutter is unchanged so this should
      already pass).
- [ ] `cd app_flutter && flutter test` exits 0 (no
      new Flutter tests; existing tests still pass).
- [ ] No file outside `05-file-ownership.md`'s
      "Allowed changes" is modified.
- [ ] No new `<uses-permission>` is added to
      `AndroidManifest.xml`.
- [ ] No new package is added to `pubspec.yaml`.
- [ ] The 6-step on-device manual script passes on a
      physical Android device or a host-managed
      emulator.
- [ ] The "wow moment" works: save a project, kill the
      app, relaunch, tap **Settings → Open project**,
      see the picker open at the last folder with only
      `.audioapp.zip` files listed, tap one, arrangement
      updates.

## Open questions for the orchestrator

These are flagged but do **not** block implementation.
The contract commits to a default; the orchestrator can
override before kicking off the implementation worker.

1. **Should `OpenProjectDocument` be `internal` or
   `private`?** The contract says `internal` (so
   VP-2's tests in the same package can reference it).
   An alternative is to leave it `private` and add
   `@file:VisibleForTesting` to MainActivity.kt.
   **Default: `internal`.**

2. **Should the new `<intent-filter>` also include
   `android.intent.category.BROWSABLE`?** That would
   let a `.audioapp.zip` link in a web browser open
   our app. We do not currently advertise project files
   on the web, so this is unnecessary surface area.
   **Default: do not add.**

3. **Should we add Mockito as a `testImplementation`
   in `build.gradle.kts`?** The contract permits it
   but does not require it. VP-2's implementer decides.
   Mockito is ~2 MB; Robolectric is ~5 MB. **Default:
   add Mockito if VP-2 needs it; otherwise leave
   `build.gradle.kts` at exactly 2 additions.**

4. **Should the `ARCHIVE_MIME_TYPE` constant (used
   on the save side) also be updated?** **No.** The
   contract explicitly keeps it as `application/zip`.
   `PROJECT_MIME_TYPE` is the new constant for the
   load side; `ARCHIVE_MIME_TYPE` is unchanged.

5. **Should the on-device manual script be
   automated via `adb`?** The cloud VM has no
   emulator. Automating via `adb` would require a
   physical device or a host-managed emulator
   attached to the orchestrator. **Default: local
   developer runs the script manually and reports
   back.**

## Out-of-scope follow-ups (NOT part of this PR)

These are flagged for the orchestrator's awareness.
They are **not** in the current bug fix.

- **Handle inbound `ACTION_VIEW` with the vendor
  MIME in `MainActivity.configureFlutterEngine`.**
  Once the manifest declares the handler, the system
  will route `.audioapp.zip` opens from other apps
  here. We should `if (intent.action ==
  ACTION_VIEW && intent.type == PROJECT_MIME_TYPE)`
  and call our existing `launchLoadArchivePicker`
  with the intent's `data` URI pre-filled. This is a
  ~10-line change to `MainActivity` and a follow-up
  contract.
- **Add a Kotlin integration test that exercises the
  full save + reload round-trip on an emulator.**
  Out of scope for this slice; the on-device manual
  script covers it for now.
- **Localize the on-device manual script for
  non-English Android locales.** The script's
  expected text ("Saved project", "Open project")
  matches the existing English UI. Localization is
  orthogonal to this fix.
