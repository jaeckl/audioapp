# File Ownership

Every row is **binding**. Implementation agents may only
edit files listed under "Allowed changes" in this table.
Everything else is explicitly off-limits.

This slice is intentionally **tight**. It is a one-PR fix.
The whole diff is roughly:

- `ProjectArchiveStore.kt`: +10 lines (constants + helper)
- `MainActivity.kt`: +15 lines (nested contract) / 2 lines
  modified (existing registration + launch site)
- `AndroidManifest.xml`: +5 lines (one `<intent-filter>`)
- `build.gradle.kts`: +5 lines (testOptions + JUnit dep)
- `app/src/test/.../ProjectArchiveMimeTest.kt`: +60 lines
  (new — see `07-test-contract.md`)
- `app/src/test/.../OpenProjectDocumentTest.kt`: +80 lines
  (new)

Total diff: under 200 lines across 6 files. No Flutter,
no Dart, no C++.

---

## Android — Kotlin

| File | Owner work package | Allowed changes | Forbidden changes |
|------|-------------------|-----------------|-------------------|
| `app_flutter/android/app/src/main/kotlin/com/audioapp/daw/ProjectArchiveStore.kt` | **VP-1** | Add `const val PROJECT_MIME_TYPE`. Add `val OPEN_ARCHIVE_MIME_FILTER`. **Delete** the old `openArchiveMimeFilter` constant. Add `fun deriveInitialUri(context: Context): Uri?`. | Do **not** change `buildArchiveBytes`, `extractProjectJson`, `writeProjectArchive`, `readProjectArchive`, `persistDocumentUri`. Do **not** change the existing `ARCHIVE_MIME_TYPE` constant (save MIME stays `application/zip`). |
| `app_flutter/android/app/src/main/kotlin/com/audioapp/daw/MainActivity.kt` | **VP-1** | Add the private nested class `OpenProjectDocument` (lines 17–18 of this class file). Change the registration of `openProjectArchive` to use the new contract class. Change the `.launch(...)` argument in `launchLoadArchivePicker` to use the new filter array. Add the `import android.provider.DocumentsContract` line if not already present. | Do **not** modify `createProjectArchive`, `launchSaveArchivePicker`, `onSaveArchivePicked`, `onLoadArchivePicked`, `launchImportSamplePicker`, `launchExportMixPicker`, `onExportWavPicked`, `acquirePlaybackWakeLock`, `releasePlaybackWakeLock`, or any of the `configureFlutterEngine` `when` cases. Do **not** modify any `native*` JNI declaration. Do **not** modify `jsonToMap` / `mapToJson` / `jsonValue` / `mapValueToJson`. Do **not** add a new MethodChannel handler. |
| `app_flutter/android/app/src/main/kotlin/com/audioapp/daw/ProjectUriStore.kt` | (none) | — | **No changes.** The `loadLastDocumentUri` / `saveLastDocumentUri` API is reused unchanged. |
| `app_flutter/android/app/src/main/kotlin/com/audioapp/daw/WavEncoder.kt` | (none) | — | **No changes.** |
| `app_flutter/android/app/src/main/AndroidManifest.xml` | **VP-1** | Add exactly one `<intent-filter>` block (5 lines) inside `<activity android:name=".MainActivity">`, after the existing `MAIN`/`LAUNCHER` filter. See `04-data-contracts.md` §6 for the exact diff. | Do **not** change any existing attribute on `<activity>` or `<application>`. Do **not** add new `<uses-permission>` entries. Do **not** change the `<meta-data>` for `flutterEmbedding`. |
| `app_flutter/android/app/build.gradle.kts` | **VP-1** | Add `testOptions { unitTests.isReturnDefaultValues = true }` inside the `android { }` block (3 lines). Add `testImplementation("junit:junit:4.13.2")` inside `dependencies { }` (1 line). See `04-data-contracts.md` §7 for the exact diff. | Do **not** change `compileSdk`, `minSdk`, `targetSdk`, `ndkVersion`, `applicationId`, or `abiFilters`. Do **not** change `compileOptions`, `kotlinOptions`, `defaultConfig`, `externalNativeBuild`, or `buildTypes`. Do **not** change the `flutter { source = "../.." }` line. |
| `app_flutter/android/app/src/test/kotlin/com/audioapp/daw/ProjectArchiveMimeTest.kt` | **VP-2** (new file) | New file. JUnit 4 tests for `ProjectArchiveStore.PROJECT_MIME_TYPE`, `OPEN_ARCHIVE_MIME_FILTER` shape, and `deriveInitialUri`. See `07-test-contract.md` §"T1–T5" for the exact test cases. | Do **not** place the file under `androidTest/` (instrumented). Do **not** use Robolectric. |
| `app_flutter/android/app/src/test/kotlin/com/audioapp/daw/OpenProjectDocumentTest.kt` | **VP-2** (new file) | New file. JUnit 4 tests for the `OpenProjectDocument.createIntent` behavior. See `07-test-contract.md` §"T6–T9" for the exact test cases. | Do **not** depend on `androidx.test` (no Robolectric). Use the JVM-only `Intent` inspection helpers from `org.robolectric.shadows.ShadowApplication` only if absolutely needed; otherwise test via the `Intent` extras map reflection-free (using `Intent.hasExtra(...)` and `Intent.getStringExtra(...)`, which are stubbed but readable on the JVM with `isReturnDefaultValues = true`). |

## Flutter — Dart (UNCHANGED)

| File | Owner work package | Allowed changes | Forbidden changes |
|------|-------------------|-----------------|-------------------|
| `app_flutter/lib/features/settings/settings_screen.dart` | (none) | — | **No changes.** |
| `app_flutter/lib/bridge/engine_bridge.dart` | (none) | — | **No changes.** |
| `app_flutter/lib/bridge/project_snapshot.dart` | (none) | — | **No changes.** |
| `app_flutter/lib/app/daw_shell.dart` | (none) | — | **No changes.** |
| `app_flutter/lib/features/automation/**` (any other UI) | (none) | — | **No changes.** |
| `app_flutter/lib/**` (anything else) | (none) | — | **No changes.** |
| `app_flutter/pubspec.yaml` | (none) | — | **No changes.** |

## Engine — C++ (UNCHANGED)

| File | Owner work package | Allowed changes | Forbidden changes |
|------|-------------------|-----------------|-------------------|
| `engine_juce/**` | (none) | — | **No changes.** No engine rebuild required. |
| `engine_juce/tests/**` | (none) | — | **No changes.** |
| `native_bridge/**` | (none) | — | **No changes.** |
| `app_flutter/android/app/src/main/cpp/jni_bridge.cpp` | (none) | — | **No changes.** No new JNI exports. |

## Tests — Flutter (UNCHANGED)

| File | Owner work package | Allowed changes | Forbidden changes |
|------|-------------------|-----------------|-------------------|
| `app_flutter/test/load_project_list_test.dart` (proposed in the rejected previous contract) | (none) | — | **Do not create.** The rejected previous contract proposed Flutter widget tests for an in-app list UI; that UI is not part of this slice. |
| `app_flutter/test/widget_test.dart` | (none) | — | **No changes.** |
| `app_flutter/test/engine_bridge_test.dart` | (none) | — | **No changes.** |
| `app_flutter/test/automation_editor_pinch_zoom_test.dart` (existing) | (none) | — | **No changes.** |

## Documentation

| File | Owner work package | Allowed changes | Forbidden changes |
|------|-------------------|-----------------|-------------------|
| `docs/features/load-project-zip-listing-fix/**` (this folder) | architect only | — | Implementation agents must not modify these docs. |
| `docs/features/filter-automation-modulation-fix/**` | (none) | — | **No changes.** Unrelated feature. |
| `docs/bridge/**` | (none) | — | **No changes.** (The MethodChannel surface is unchanged.) |
| `PROJECT-SPEC.md`, `AGENTS.md`, `.cursor/rules/**` | (none) | — | **No changes.** |

---

## Shared files requiring special care

**There are no shared files in this slice.** Each
modified file is owned by exactly one work package
(VP-1 for production code, VP-2 for tests). The
two test files are independent of each other.

`build.gradle.kts` is touched once by VP-1 (production
code). VP-2 does not edit it; VP-2 only adds files
under `src/test/`.

`AndroidManifest.xml` is touched once by VP-1.
VP-2 does not touch the manifest.

If two work packages both needed to edit the same
file (they don't here), they would have to be
merged into a single work package.
