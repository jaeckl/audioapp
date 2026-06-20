# Vertical Work Packages

The fix is a **single vertical slice**. The user-visible
behavior is one: *"After saving a project, the next tap
on Settings → Open project shows the SAF picker at my
last folder, filtered to only `.audioapp.zip` files."*
That behavior requires:

1. Save flow (so a URI exists in `ProjectUriStore`),
2. URI derivation (so the picker knows where to open),
3. MIME filter (so only our files show up), and
4. MIME declaration in the manifest (so the system
   recognizes our app as a handler).

These four pieces cannot be split into independent
parallel packages: each one depends on the previous.
Splitting them would create four half-working slices.

**VP-1 = the whole fix.** VP-2 = the tests for VP-1.

That is the entire slice.

The previous (rejected) contract proposed four
parallel packages (VP-1..VP-4) for an in-app Recent
projects UI. The architect **explicitly rejects** that
structure for the rewritten contract:

- The user rejected the in-app list direction.
- The fix is small enough to ship as one PR.
- Splitting would create integration risk with no
  parallel speedup, since all four pieces touch either
  the same Kotlin file or the same AndroidManifest or
  are strictly sequential (manifest needs constants
  first, etc.).

The remaining sections describe the two packages that
**do** exist.

---

## VP-1: SAF picker shows saved `.audioapp.zip` files (the entire fix)

**User-visible or system-visible behavior:** the SAF
"Open project" picker opens at the user's last save/load
folder and lists only `.audioapp.zip` files. The user
sees their saved project immediately on the first tap.
No new UI, no new Dart code, no new engine code.

**Files (allowed):**
- `app_flutter/android/app/src/main/kotlin/com/audioapp/daw/ProjectArchiveStore.kt`
- `app_flutter/android/app/src/main/kotlin/com/audioapp/daw/MainActivity.kt`
- `app_flutter/android/app/src/main/AndroidManifest.xml`
- `app_flutter/android/app/build.gradle.kts`

**Files (forbidden):**
- All Flutter / Dart files (`app_flutter/lib/**`,
  `app_flutter/test/**`, `app_flutter/pubspec.yaml`)
- All C++ files (`engine_juce/**`,
  `app_flutter/android/app/src/main/cpp/**`)
- All native bridge files (`native_bridge/**`)
- All other Kotlin files (`ProjectUriStore.kt`,
  `WavEncoder.kt`, plus any test files)

**Canonical names used:**
`PROJECT_MIME_TYPE`, `OPEN_ARCHIVE_MIME_FILTER`,
`deriveInitialUri`, `OpenProjectDocument`,
`EXTRA_INITIAL_URI` (system constant),
`application/vnd.audioapp.project+zip` (the MIME
literal).

**API / data contracts used:**
`03-api-contracts.md` (every section, since this slice
is the entire contract), `04-data-contracts.md` (every
section).

**Dependencies:** none. Can start as soon as the
architect's contract is approved.

**Acceptance criteria:**

In `ProjectArchiveStore.kt`:

- `const val PROJECT_MIME_TYPE = "application/vnd.audioapp.project+zip"`.
- `val OPEN_ARCHIVE_MIME_FILTER: Array<String> = arrayOf(PROJECT_MIME_TYPE, "application/zip")`.
- The old `openArchiveMimeFilter` constant is **deleted**
  (no longer referenced anywhere in the codebase).
- `fun deriveInitialUri(context: Context): Uri?` is
  added and delegates to
  `ProjectUriStore.loadLastDocumentUri(context)`.
- `ARCHIVE_MIME_TYPE` remains `"application/zip"` and
  is used by the save flow unchanged.

In `MainActivity.kt`:

- `import android.provider.DocumentsContract` is added
  (if not already present).
- A private nested class `OpenProjectDocument` is added
  that extends
  `ActivityResultContracts.OpenDocument()` and overrides
  `createIntent(context, input)` to call
  `super.createIntent(...)` then `putExtra(...)` with
  `DocumentsContract.EXTRA_INITIAL_URI` if
  `ProjectArchiveStore.deriveInitialUri(context)` is
  non-null.
- The registration of `openProjectArchive` is changed
  from `ActivityResultContracts.OpenDocument()` to
  `OpenProjectDocument()`. The lambda body
  `{ documentUri -> onLoadArchivePicked(documentUri) }`
  is **unchanged**.
- The `launch(...)` call inside
  `launchLoadArchivePicker` is changed to use
  `ProjectArchiveStore.OPEN_ARCHIVE_MIME_FILTER`.
- The save flow (`launchSaveArchivePicker`,
  `onSaveArchivePicked`, `createProjectArchive`) is
  **byte-for-byte unchanged**.
- The load flow's `onLoadArchivePicked` callback body
  is **byte-for-byte unchanged** (the picker still
  passes a `Uri?` to the same handler).
- No JNI signature is changed. No `external fun` is
  added or renamed.

In `AndroidManifest.xml`:

- One new `<intent-filter>` is added inside
  `<activity android:name=".MainActivity">`, after the
  existing `MAIN`/`LAUNCHER` filter. The filter contains
  exactly:
  ```xml
  <intent-filter>
      <action android:name="android.intent.action.VIEW" />
      <category android:name="android.intent.category.DEFAULT" />
      <data android:mimeType="application/vnd.audioapp.project+zip" />
  </intent-filter>
  ```
- No other manifest line is changed.
- No new `<uses-permission>` entries.

In `build.gradle.kts`:

- `testOptions { unitTests.isReturnDefaultValues = true }`
  is added inside `android { }`, after `kotlinOptions { }`.
- `testImplementation("junit:junit:4.13.2")` is added
  inside `dependencies { }`, after the existing
  `implementation("androidx.activity:activity-ktx:1.9.3")`.
- No other Gradle line is changed.

**Required tests:** the production code in VP-1 is
covered by VP-2's tests. The contract reviewer runs
`./gradlew :app:testDebugUnitTest` (see VP-2) and
verifies VP-2's tests pass.

**Manual verification steps** (the §2.7 "wow moment"):

The local developer (who has a physical Android device
or a host-managed, KVM-accelerated emulator — the cloud
VM has none) runs the on-device script in
`07-test-contract.md` §"On-device manual script". This
includes: save a project to `Downloads/AudioApp/`, kill
the app, relaunch, tap **Settings → Open project**, and
visually verify the picker opens inside
`Downloads/AudioApp/` with only `.audioapp.zip` files
listed.

**Integration risk:** low. The slice is additive: no
existing method, no existing handler, no existing
field is removed. The single deletion is the old
`openArchiveMimeFilter` constant, which is replaced by
`OPEN_ARCHIVE_MIME_FILTER` and is referenced nowhere
else after the change.

**Parallel:** no. VP-1 is a single sequential package.

**Worker instructions:**

- Obey canonical names exactly. The MIME literal
  `application/vnd.audioapp.project+zip` must appear
  identically in Kotlin and XML. A typo in either
  place silently breaks the filter.
- Do not modify any Flutter / Dart / C++ / JNI file.
- Do not add a Kotlin unit-test target beyond the
  `testOptions` and `testImplementation` lines in
  `build.gradle.kts`. (The `src/test/...` test files
  are written by VP-2.)
- Do not introduce Robolectric or any new dependency.
  Plain JUnit 4 is enough.
- Do not modify `ProjectUriStore.kt`. The `loadLastDocumentUri`
  API is the contract.
- Do not touch `jsonToMap`, `mapToJson`, `jsonValue`,
  `mapValueToJson`. They handle the wire formats.
- Stop and report if a contract gap is found, do not guess.

---

## VP-2: Kotlin unit tests (JUnit 4, plain JVM, no Robolectric)

**User-visible or system-visible behavior:** none
directly. The slice adds automated test coverage for
the Kotlin changes in VP-1. The tests run on the cloud
VM via `./gradlew :app:testDebugUnitTest` (since the
cloud VM has no emulator but has Gradle).

**Files (allowed):**

- `app_flutter/android/app/src/test/kotlin/com/audioapp/daw/ProjectArchiveMimeTest.kt` (new)
- `app_flutter/android/app/src/test/kotlin/com/audioapp/daw/OpenProjectDocumentTest.kt` (new)

**Files (forbidden):**
- All production code (VP-1 files; VP-2 only writes tests).
- `build.gradle.kts` (already edited by VP-1; do not
  re-edit).
- All Flutter / Dart / C++ files.

**Canonical names used:**
`PROJECT_MIME_TYPE`, `OPEN_ARCHIVE_MIME_FILTER`,
`deriveInitialUri`, `OpenProjectDocument`,
`EXTRA_INITIAL_URI`. **The tests reference these
names verbatim** — they will fail to compile if VP-1
used different names, which is the point of having
the contract drive the tests.

**API / data contracts used:**
`03-api-contracts.md` §1, §2, §3, §4; `04-data-contracts.md`
§1, §2, §3.

**Dependencies:** requires VP-1 to be merged (the
production code must exist for the tests to compile
against it). The test files cannot even be added to a
green tree before VP-1, because VP-2's tests reference
`ProjectArchiveStore.PROJECT_MIME_TYPE` etc.

**Acceptance criteria:**

See `07-test-contract.md` for the **concrete test
classes and methods** (T1–T9 listed there). The
acceptance criteria for VP-2 are:

- Two new test files exist at the paths above.
- They contain **at least 9 test methods** total
  (5 in `ProjectArchiveMimeTest`, 4 in
  `OpenProjectDocumentTest`).
- All 9 pass under
  `./gradlew :app:testDebugUnitTest` on the cloud VM.
- No test depends on Robolectric, `androidx.test`, or
  any Android instrumentation.
- No test depends on a real `Context` or `SharedPreferences`
  — the tests use the `isReturnDefaultValues = true`
  trick and inspect the `Intent` via its public extras
  map.
- No test writes to the file system.

**Required tests:** the 9 named tests in
`07-test-contract.md`.

**Manual verification steps:**

```bash
cd app_flutter/android
./gradlew :app:testDebugUnitTest
```

Expected: BUILD SUCCESSFUL; 9 tests pass.

**Integration risk:** low. The tests are additive.
They cannot break production code because they only
read public API.

**Parallel:** no. Sequential after VP-1.

**Worker instructions:**

- Obey canonical names exactly. The test class and
  method names in `07-test-contract.md` are binding.
- Do not modify any production code in this slice.
- Do not add new packages to `build.gradle.kts` beyond
  the `testImplementation("junit:junit:4.13.2")` that
  VP-1 already added.
- Use `org.junit.Test`, `org.junit.Assert.*` only.
- For `OpenProjectDocumentTest`, use
  `androidx.activity.result.contract.ActivityResultContracts.OpenDocument`
  via reflection-free inspection: build an
  `OpenProjectDocument` instance, call
  `createIntent(context, arrayOf("a", "b"))`, and
  assert on the returned `Intent`'s extras via
  `intent.hasExtra(DocumentsContract.EXTRA_INITIAL_URI)`
  and `intent.getStringExtra(DocumentsContract.EXTRA_INITIAL_URI)`.
  With `unitTests.isReturnDefaultValues = true`, the
  `Context` argument can be `null` (it is only forwarded
  to `super.createIntent`, which under
  `isReturnDefaultValues` does not dereference it). If
  `super.createIntent` requires a non-null context in
  the stub JVM, use `mock(Context.class)` from
  `org.mockito.Mockito` (added as a test dependency
  if needed) or pass `null` and assert that the call
  throws NPE (which is acceptable since the contract
  never requires unit tests to run the full code path).
- Stop and report if a contract gap is found, do not guess.

---

## Recommended implementation order

```text
0. Architect (this document, done)
        │
1. VP-1: Production Kotlin + Manifest + Gradle         (sequential)
        │
2. VP-2: Kotlin unit tests                              (sequential)
        │
3. Reviewer subagent                                    (after 2)
        │
4. Local developer: on-device manual script              (after 3)
        │
5. PR ready to merge
```

The total wall time on the cloud VM is roughly:
- VP-1: ~15 minutes of editing (the diff is small).
- VP-2: ~20 minutes of editing + 5 minutes of Gradle
  test run.
- Reviewer: ~10 minutes.
- Local on-device script: ~5 minutes of human time.

## Packages that can run in parallel

**None.** The slice is small enough to be one PR.

## Packages that must be sequential

- **VP-2 after VP-1.** The tests reference the
  production code added in VP-1; they cannot compile
  against a tree where VP-1 has not landed.
- **Reviewer after VP-2.**
- **On-device manual script after Reviewer.**

## Shared files requiring care

- No two work packages share a file. VP-1 owns the
  production files; VP-2 owns the test files.
- If a future feature needs to touch the same files,
  the orchestrator must merge the work into a single
  package or serialize it carefully.

## Out of scope (intentional)

These are **not** part of this fix and must not creep in:

- An in-app Recent Projects UI (rejected by the user).
- A `filesDir/projects/` mirror directory (rejected
  with the list UI).
- A `listProjects` MethodChannel method (rejected).
- A `loadProjectByPath` MethodChannel method
  (rejected).
- Handling `ACTION_VIEW` with the vendor MIME in
  `MainActivity.configureFlutterEngine` (the manifest
  declares we handle it; the actual handling logic is
  a follow-up — the user opens the file from another
  app and we should route it to loadProject; that's a
  separate contract).
- iOS, desktop, web targets.
- New permissions (`READ_EXTERNAL_STORAGE`,
  `WRITE_EXTERNAL_STORAGE`, etc.). The fix uses only
  `SharedPreferences` and SAF URIs; no new permissions
  needed.
