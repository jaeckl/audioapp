# API and Data Contracts

This file pins the **exact Kotlin code** for every new
piece, the Intent extras, the MIME type, and the
AndroidManifest snippet. Every line is binding.
Implementation agents must not deviate without an updated
contract.

The cross-layer MethodChannel surface
(`com.audioapp.daw/engine`) is **unchanged**. The `loadProject`
and `saveProject` handlers are not modified. The fix lives
entirely inside the existing `launchLoadArchivePicker` path
and its supporting helper.

---

## 1. MIME type (canonical literal)

```kotlin
// In ProjectArchiveStore.kt (top-level, next to existing constants).
const val PROJECT_MIME_TYPE = "application/vnd.audioapp.project+zip"
```

This is the **exact string**. Per `02-canonical-vocabulary.md`,
this same literal appears in `OPEN_ARCHIVE_MIME_FILTER[0]`
and in `AndroidManifest.xml`. No variations
(`+ZIP`, `vnd.audioapp+zip`, etc.) are permitted.

**RFC compliance** (verified):

- `vnd.` prefix per RFC 6838 §4.2 vendor tree.
- `audioapp.project` per RFC 6838 §4.2.8 ("IANA-approved
  designation of the producer's name followed by a media
  type or product designation").
- `+zip` structured-syntax suffix per RFC 6839 §3.6
  ("MAY be used with any media type whose representation
  follows that established for `application/zip`").

---

## 2. MIME filter array (canonical literal)

```kotlin
// In ProjectArchiveStore.kt.
val OPEN_ARCHIVE_MIME_FILTER: Array<String> = arrayOf(
    PROJECT_MIME_TYPE,        // "application/vnd.audioapp.project+zip"
    "application/zip",        // generic fallback for older providers
)
```

Order matters: vendor MIME first so providers that know
it (after we declare it in `AndroidManifest.xml`) lead
with our files; generic `application/zip` second as a
fallback for providers that don't.

The previous `openArchiveMimeFilter` constant
(`arrayOf("application/zip", "application/octet-stream")`)
is **deleted**. It is replaced by
`OPEN_ARCHIVE_MIME_FILTER`.

---

## 3. `deriveInitialUri` (new helper)

```kotlin
// In ProjectArchiveStore.kt.
import android.content.Context
import android.net.Uri

/**
 * Returns the SAF document URI of the user's most recent save or
 * load, or null if no URI has been persisted yet (first run, or the
 * user cleared app data).
 *
 * The returned URI is the exact form expected by
 * [android.provider.DocumentsContract.EXTRA_INITIAL_URI]: a document
 * URI obtained from a prior ACTION_OPEN_DOCUMENT / ACTION_CREATE_DOCUMENT
 * result. The system handles the "non-directory" case by falling back
 * to the parent folder.
 */
fun deriveInitialUri(context: Context): Uri? {
    return ProjectUriStore.loadLastDocumentUri(context)
}
```

**Inputs / outputs:**

- `context: Context` — used only for `SharedPreferences`
  access (not for resources).
- Returns `Uri?` — null when no URI has been persisted.

**Threading:** safe to call from the platform thread
(the only place it's called from). `SharedPreferences`
reads are blocking but tiny.

**Validation:** none. Whatever URI is in the
`SharedPreferences` is forwarded as-is to the system. The
system handles invalid/revoked URIs by ignoring the extra.

---

## 4. `OpenProjectDocument` (new nested contract)

```kotlin
// In MainActivity.kt (internal nested class — `internal`, not `private`,
// so the same-package Kotlin unit tests in VP-2 can reference it).
internal class OpenProjectDocument :
    ActivityResultContracts.OpenDocument() {

    override fun createIntent(context: Context, input: Array<String>): Intent {
        val intent = super.createIntent(context, input)
        ProjectArchiveStore.deriveInitialUri(context)?.let { lastUri ->
            intent.putExtra(DocumentsContract.EXTRA_INITIAL_URI, lastUri)
        }
        return intent
    }
}
```

**Inputs / outputs:**

- `context: Context` — provided by `registerForActivityResult`.
- `input: Array<String>` — the MIME filter array
  (i.e. `ProjectArchiveStore.OPEN_ARCHIVE_MIME_FILTER`).
- Returns `Intent` — the same `Intent` returned by
  `super.createIntent(...)` but with
  `EXTRA_INITIAL_URI` attached when `last_document_uri`
  is non-null.

**Threading:** called on the platform thread when the
launcher is `.launch(...)`-ed. Single call per picker
launch.

**Validation:** none beyond what `super.createIntent`
already does.

**Behavior in edge cases:**

- `deriveInitialUri(context)` returns `null`: the
  `let { ... }` block is skipped; the Intent has no
  `EXTRA_INITIAL_URI`. SAF opens at default.
- `deriveInitialUri(context)` returns a revoked URI:
  the Intent is still built; SAF ignores the extra and
  opens at default.

---

## 5. Registration of the new contract (in MainActivity)

Replace lines 34–36 of the existing
`MainActivity.kt`:

```kotlin
// OLD:
private val openProjectArchive = registerForActivityResult(
    ActivityResultContracts.OpenDocument(),
) { documentUri -> onLoadArchivePicked(documentUri) }

// NEW:
private val openProjectArchive = registerForActivityResult(
    OpenProjectDocument(),
) { documentUri -> onLoadArchivePicked(documentUri) }
```

**No change** to the lambda body
(`onLoadArchivePicked`). The contract reviewer must
verify this lambda is unchanged.

---

## 6. Launch site (in MainActivity.launchLoadArchivePicker)

Replace line 57 of the existing `MainActivity.kt`:

```kotlin
// OLD:
openProjectArchive.launch(ProjectArchiveStore.openArchiveMimeFilter)

// NEW:
openProjectArchive.launch(ProjectArchiveStore.OPEN_ARCHIVE_MIME_FILTER)
```

The `pendingLoadResult = result` line above (line 56)
and the busy-check above that (lines 52–55) are
**unchanged**. The cancellation path on line 53
("File picker already open") is unchanged.

---

## 7. Save flow — UNCHANGED (pinned for clarity)

The save flow keeps writing as `application/zip`. No
edit. For reference, here is the relevant slice of the
existing code (do not change):

```kotlin
// MainActivity.kt:30-32 (UNCHANGED)
private val createProjectArchive = registerForActivityResult(
    ActivityResultContracts.CreateDocument(ProjectArchiveStore.ARCHIVE_MIME_TYPE),
) { documentUri -> onSaveArchivePicked(documentUri) }

// MainActivity.kt:47-48 (UNCHANGED)
pendingSaveResult = result
createProjectArchive.launch(ProjectArchiveStore.DEFAULT_ARCHIVE_NAME)

// ProjectArchiveStore.kt:25 (UNCHANGED)
const val ARCHIVE_MIME_TYPE = "application/zip"
```

The contract reviewer must verify that the save flow is
**byte-for-byte identical** before and after the fix.

---

## 8. `AndroidManifest.xml` — new `<intent-filter>`

Insert this `<intent-filter>` **inside the existing
`<activity android:name=".MainActivity" ...>` block**,
after the existing `<intent-filter>` for `MAIN` /
`LAUNCHER`. Do not nest it inside the existing filter;
AndroidManifest allows multiple `<intent-filter>` blocks
per activity.

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <data android:mimeType="application/vnd.audioapp.project+zip" />
</intent-filter>
```

**Why `<action android:name="android.intent.action.VIEW" />`
and not `android.intent.action.OPEN_DOCUMENT`?** Because
the system's `OpenDocument` contract uses
`ACTION_OPEN_DOCUMENT` (which is the `OpenDocument`
launcher, not an intent that a third-party app would
broadcast). The realistic "open from elsewhere" path is
the user tapping a `.audioapp.zip` file in their email
attachment or Files app — that fires `ACTION_VIEW` with
the file's MIME type. By declaring `VIEW` + the MIME,
we make our app a recognized handler; the system will
offer "Open with AudioApp DAW" for our files.

**Side effect:** any app that calls
`startActivity(Intent(ACTION_VIEW).setDataAndType(uri,
"application/vnd.audioapp.project+zip"))` will now be
offered our app in the chooser. We do not handle that
intent in `MainActivity.configureFlutterEngine` yet;
that's a follow-up (not part of this slice). The slice
just declares the MIME so the system treats us as a
recognized type.

**Caveat:** this is purely additive. The existing
`MAIN`/`LAUNCHER` filter is unchanged. The activity
remains `android:exported="true"` (already set).

---

## 9. `AndroidManifest.xml` — final shape

For convenience, here is the relevant block of the
manifest after the change (only the
`MainActivity` block is shown; rest of file is
unchanged):

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    ...existing attributes...>
    <meta-data
      android:name="io.flutter.embedding.android.NormalTheme"
      android:resource="@style/NormalTheme"
      />
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>

    <!-- NEW: declare we handle the audioapp project MIME type -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <data android:mimeType="application/vnd.audioapp.project+zip" />
    </intent-filter>
</activity>
```

The contract reviewer must verify the diff adds **only**
this one `<intent-filter>` block and changes nothing
else in the manifest.

---

## 10. `build.gradle.kts` — enable Kotlin unit tests

Add these lines to `app_flutter/android/app/build.gradle.kts`:

```kotlin
android {
    // ... existing android { } contents ...

    // NEW: enable JVM unit tests for the Kotlin layer.
    testOptions {
        unitTests.isReturnDefaultValues = true
    }
}

dependencies {
    implementation("androidx.activity:activity-ktx:1.9.3")
    // NEW: JUnit 4 for Kotlin unit tests.
    testImplementation("junit:junit:4.13.2")
}
```

`testOptions.unitTests.isReturnDefaultValues = true` is
the standard Android Gradle DSL option that makes the
unit-test JVM return default values for any
`android.*` API calls (instead of throwing
`RuntimeException("Stub!")`). It is necessary because
`ProjectUriStore.loadLastDocumentUri` and our
`deriveInitialUri` use `android.content.Context`,
`android.net.Uri`, and `android.content.SharedPreferences`
— none of which are on the JVM classpath in a unit test
without Robolectric.

**Why not Robolectric?** Robolectric is heavier (shadows
the Android framework) and would add ~5 MB to the test
classpath and a noticeable cold-start cost. For a
helper that just delegates to `SharedPreferences`, plain
JUnit + `testOptions.unitTests.isReturnDefaultValues`
is enough. We test:

- `deriveInitialUri` returns null when no URI has been
  saved.
- `deriveInitialUri` returns the stored URI when one
  has been saved.
- `OpenProjectDocument.createIntent` attaches
  `EXTRA_INITIAL_URI` when a URI is present.
- `OpenProjectDocument.createIntent` does **not**
  attach `EXTRA_INITIAL_URI` when no URI is present.

All four can be exercised without touching the real
`SharedPreferences` or `Context` (see
`07-test-contract.md` for the test design).

---

## 11. MethodChannel surface — UNCHANGED (pinned)

For completeness, the Dart-side method call is
**unchanged**:

```dart
// Existing (unchanged) call in settings_screen.dart:
final snapshot = await widget.bridge.loadProject();
```

The Kotlin handler `launchLoadArchivePicker` (line 51 of
the existing code) is also **unchanged** in its body
except for the `.launch(filter)` argument.

**No new MethodChannel methods. No new fields on any
existing response.**

---

## 12. Versioning / compatibility

- **No bridge version bump.** The change is contained to
  the SAF `Intent` extras. Existing `saveProject` /
  `loadProject` callers see no API change.
- **No minSdk bump.** `ActivityResultContracts.OpenDocument`
  array-variant (`EXTRA_MIME_TYPES`) and `EXTRA_INITIAL_URI`
  are both available on minSdk 26 (the project's current
  min). No `Build.VERSION.SDK_INT` guards needed.
- **No migration.** Existing users keep their
  `last_document_uri` and immediately benefit from the
  fix on next launch.

---

## 13. Open questions for the orchestrator

These are flagged but do **not** block implementation.
The contract commits to a default; the orchestrator can
override before kicking off the implementation worker.

1. **Should the new `<intent-filter>` use `ACTION_VIEW`
   or also `ACTION_EDIT`?** The contract uses `VIEW`
   only. `EDIT` would be a more honest semantic for a
   "load and edit" project, but it would expose our
   app as a generic editor for the MIME — likely fine
   but more surface area than needed. **Default: VIEW
   only.**
2. **Should the manifest also declare the
   `.audioapp.zip` file extension explicitly via
   `<data android:pathPattern=".*\\.audioapp\\.zip" />`?**
   Path patterns are not honored by SAF's
   `OpenDocument` flow (which filters by MIME, not by
   path). The `OpenDocument` activity does not consume
   `pathPattern`. **Default: do not add.** (The MIME
   declaration is what matters.)
3. **Should the new `<intent-filter>` make
   `MainActivity` `android:exported="true"` in a new
   way?** It is already exported. The filter is
   purely additive. **Default: no change to
   `exported`.**
