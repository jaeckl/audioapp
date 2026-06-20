# Feature Brief: Make the SAF "Open Project" Picker List Saved `.audioapp.zip` Files

## User-Reported Bug

> "the load project widget of android does not list any saved zip files that this
> project could read."

The user clarified:

- **Save location is "embedded/0/<anywhere>":** the `.audioapp.zip` files
  end up at whatever directory the user picked via SAF `ACTION_CREATE_DOCUMENT`.
- **Desired fix direction: "Keep SAF, point it at a browseable folder."**
  They **do not** want a new in-app "Recent projects" list UI. They want
  the existing SAF "Open project" picker to actually show their saved
  files when they open it.

## User-Visible Goal

On Android, when the user taps **Settings → Open project**, the SAF
`ACTION_OPEN_DOCUMENT` picker must:

1. **Open at the folder where the user most recently saved or loaded a
   project** (not at SAF's default root). The user already saved a
   project there; the picker should land them in the same place.
2. **Filter the visible files** so the picker shows **only**
   `.audioapp.zip` files (plus any file a SAF provider happens to
   tag with our project's MIME type). Generic zip noise
   (Photos exports, Office docs, etc.) must not bury the user's
   project.

No new UI, no new Flutter widget, no new C++ code. The fix is
contained to `MainActivity.kt`, `ProjectArchiveStore.kt`, and
`AndroidManifest.xml`.

## Observed vs Expected

| Scenario                                                                                       | Observed today                                                                                                       | Expected after fix                                                                                                |
|------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------|
| User has saved a project to `Downloads/AudioApp/`, then taps Settings → Open project           | SAF picker opens at SAF root with no folder hint. Visible files include every zip on the device (Photos, Office…). | SAF picker opens at `Downloads/AudioApp/`. The visible list is filtered to only `.audioapp.zip` (and any file matching our declared MIME). |
| User has never saved a project (first run)                                                     | Same as above                                                                                                        | Same as today: picker opens at SAF default. Filter still applies. (User must navigate to a file; that's fine.)     |
| User picks a file from the picker                                                              | Project loads as today                                                                                                | Same as today. The picked URI is saved to `ProjectUriStore.last_document_uri` for the next load.                  |
| User cancels the picker                                                                         | Existing "cancelled" response is returned                                                                            | Same as today.                                                                                                    |
| Save flow                                                                                       | Works, writes to SAF-picked URI. URI stored.                                                                          | Works **unchanged** as `application/zip` so the system can write a real zip. URI stored.                          |

## Root Cause (verified, in code)

`MainActivity.kt` lines 34–36, 51–58, plus
`ProjectArchiveStore.kt` lines 25–30:

1. **No `EXTRA_INITIAL_URI`** is attached to the launch `Intent`. The
   picker opens at SAF's default location with no hint of where the
   user last saved a project. Even though `ProjectUriStore` persists
   the last document URI, it is never fed back to the picker.
2. **MIME filter is too broad.** `openArchiveMimeFilter` =
   `["application/zip", "application/octet-stream"]`. The first
   matches every zip on the device; the second matches everything.
   The user sees their `.audioapp.zip` mixed in with photos exports,
   Office docs, APK payloads, etc.
3. **`OpenDocument` does not natively filter by file extension**, so
   we cannot drop the MIME filter entirely. We must declare a
   project-specific MIME type for our archive (RFC 6838 vendor tree
   + `+zip` structured-syntax suffix) and pass it in
   `EXTRA_MIME_TYPES`, while keeping `application/zip` as the
   well-known fallback so the picker still works in providers that
   do not know our vendor MIME.
4. **`ActivityResultContracts.OpenDocument()`** (the default
   contract) **does not let us pass `EXTRA_INITIAL_URI`** — its
   `createIntent` only honors the mime-types array. We must
   **subclass it** to add the extra. (Per the AndroidX API reference:
   "This can be extended to override `createIntent` if you wish to
   pass additional extras.")

## Fix in One Paragraph

In `ProjectArchiveStore.kt`:
- Add a new constant `PROJECT_MIME_TYPE = "application/vnd.audioapp.project+zip"`.
- Add `OPEN_ARCHIVE_MIME_FILTER: Array<String> = arrayOf("application/vnd.audioapp.project+zip", "application/zip")`
  (declared MIME first so SAF providers that know it lead with our files;
  generic `application/zip` second as a fallback).
- Add a pure helper `deriveInitialUri(context: Context): Uri?` that
  returns `ProjectUriStore.loadLastDocumentUri(context)`. (Decoupling
  this from `MainActivity` is what lets us unit-test the URI derivation.)

In `MainActivity.kt`:
- Add a private nested `OpenProjectDocument` contract that extends
  `ActivityResultContracts.OpenDocument` and overrides `createIntent`
  to attach `DocumentsContract.EXTRA_INITIAL_URI` from
  `ProjectArchiveStore.deriveInitialUri(this)`.
- Change the existing `openProjectArchive` to use that contract and
  pass `OPEN_ARCHIVE_MIME_FILTER`.
- **No change** to `onSaveArchivePicked`, `onLoadArchivePicked`,
  `createProjectArchive`, or the existing `loadProject` /
  `saveProject` MethodChannel handlers. The save flow keeps writing
  as `application/zip` (so SAF's save dialog can produce a real
  zip file the system can write), and the user-picked URI is still
  saved to `ProjectUriStore`.

In `AndroidManifest.xml`:
- Add an `<intent-filter>` on `MainActivity` advertising the new
  vendor MIME type, so SAF treats our app as a recognized handler
  and (on providers that honor the declaration) routes picks of
  `.audioapp.zip` files here. This is purely additive; it does not
  make `MainActivity` an exported handler for our own private flow.

In `app_flutter/android/app/build.gradle.kts`:
- Enable the Kotlin unit-test target (`testOptions.unitTests.isReturnDefaultValues = true`
  and a `testImplementation("junit:junit:4.13.2")`). This is the one
  Gradle change required so we can run `gradlew :app:testDebugUnitTest`
  on the cloud VM.

## Acceptance Criteria

- [ ] After a successful `saveProject`, tapping **Settings → Open
      project** opens the SAF picker at the **same directory** the
      user just saved into (verified by visual inspection).
- [ ] The picker lists only `.audioapp.zip` files (and any other
      file the device's SAF provider happens to tag with our
      declared MIME type). Generic zips unrelated to the app are
      not shown. (Verified by visual inspection against a folder
      containing a mix of zips.)
- [ ] On a fresh install (no prior save), the picker opens at SAF
      default. The filter still applies.
- [ ] Picking a file loads the project via the existing
      `loadProject` flow. UI refreshes, status snackbar updates.
- [ ] Cancelling the picker returns the existing
      `cancelled: true` response; no regression.
- [ ] The save flow still writes a valid `.audioapp.zip` and
      records the URI to `ProjectUriStore`.
- [ ] `flutter test` and `flutter analyze` pass with 0 errors
      (no Flutter changes — should already pass).
- [ ] `gradlew :app:testDebugUnitTest` passes with the new Kotlin
      unit tests for `deriveInitialUri` and the
      `OpenProjectDocument.createIntent` behavior.
- [ ] No Flutter, Dart, JNI, or C++ file is modified. No
      `pubspec.yaml` change.

## Wow Moment (per PROJECT-SPEC.md §2.7)

A PO saves a project to **Downloads/AudioApp/My Beat.audioapp.zip**,
kills the app, relaunches, taps **Settings → Open project**, sees
the SAF picker already open inside **Downloads/AudioApp/** with
**only** `My Beat.audioapp.zip` listed, taps it, and the
arrangement re-renders with the loaded project. One pass, no
follow-up "add a folder picker" or "add file extension filter"
amendment.

## Non-Goals (re-stated)

- **No new "Recent projects" in-app list.** The user explicitly
  rejected this direction. The fix is purely a SAF picker
  improvement.
- **No engine (C++) changes.** `engine_juce/` is untouched.
- **No JNI changes.** `native_bridge/` and `jni_bridge.cpp` are
  untouched.
- **No Dart / Flutter changes.** No `settings_screen.dart` edits,
  no `engine_bridge.dart` edits, no `daw_shell.dart` edits.
- **No `pubspec.yaml` change.**
- **No new Dart methods on `EngineBridge`.**
- **No new runtime permissions.** SAF handles everything via its
  URI grants; we use `takePersistableUriPermission` (already in
  `ProjectArchiveStore.persistDocumentUri`).
- **No new UI strings, no new widget tests** (the slice touches
  zero Dart UI; the Kotlin unit tests are the new tests).
- **No iOS work.** (Android-only bug.)

## Companion Sub-Stories (PROJECT-SPEC.md §14.1)

None. Per the orchestrator rule, a "user-facing" feature requires
`US-XX-YY-ux-ui.md` and `US-XX-YY-interaction.md` companions. This
slice has **no new UI** — it changes the parameters of an existing
system picker. The companions are therefore not applicable.

## Realtime / Performance Notes

- SAF launches happen on the main thread; the picker UI is owned
  by the system. Our code only builds the `Intent`. No
  realtime-safety concerns.
- `ProjectUriStore.loadLastDocumentUri` is a single
  `SharedPreferences` read. Sub-millisecond.
- The `OpenProjectDocument.createIntent` override is called once
  per picker launch; no hot path.

## Migration / Compatibility

- **No migration.** Existing saved projects continue to work. The
  next time the user taps **Open project**, the picker opens at
  their last folder.
- **Files saved before this fix** still have valid URIs in
  `ProjectUriStore.last_document_uri` (we have been writing them
  on save and load for some time). The fix takes effect
  immediately on the next app launch.
- **minSdk** is already 26 (`build.gradle.kts:23`). The
  `OpenDocument(array)` variant and `EXTRA_INITIAL_URI` are
  available on all supported API levels; the array-variant
  `EXTRA_MIME_TYPES` is available since API 19. No
  `Build.VERSION.SDK_INT` guard needed.
