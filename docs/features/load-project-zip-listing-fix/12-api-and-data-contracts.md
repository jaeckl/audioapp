# API and Data Contracts (VP-4)

This file pins the **exact Kotlin code** for every new piece, the
Intent extras, the SAF contracts, and the in-memory data shapes. Every
line is binding. Implementation agents must not deviate without an
updated contract.

The cross-layer MethodChannel surface
(`com.audioapp.daw/engine`) is **unchanged**. The `loadProject` and
`saveProject` handlers keep their existing request/response shapes.
The fix lives entirely in:

- `ProjectArchiveStore.kt` (new helper + new data class + deleted
  filter).
- `MainActivity.kt` (deleted `OpenProjectDocument`, new
  `OpenProjectFolder`, new `onFolderPicked`, new dialog helpers).
- `ProjectUriStore.kt` (new `KEY_LAST_FOLDER_URI` + helpers).

---

## 1. `PROJECT_FILE_SUFFIX` (new constant)

```kotlin
// In ProjectArchiveStore.kt (top-level, next to existing constants).
const val PROJECT_FILE_SUFFIX = ".audioapp.zip"
```

This is the **exact string**. Includes the leading dot. Lowercase.

Used by `listAudioAppZipsIn` for `endsWith(suffix, ignoreCase = true)`
filtering.

---

## 2. `LoadFolderEntry` (new data class)

```kotlin
// In ProjectArchiveStore.kt (top-level, same file as ProjectArchiveStore).
data class LoadFolderEntry(
    val documentUri: Uri,
    val displayName: String,
    val sizeBytes: Long,
    val lastModifiedMillis: Long,
)
```

| Field | Type | Source | Notes |
|-------|------|--------|-------|
| `documentUri` | `android.net.Uri` | `DocumentsContract.Document.COLUMN_DOCUMENT_URI` | The document URI (not tree URI) for this child. What we pass to `onLoadArchivePicked` if the user picks this entry. |
| `displayName` | `String` | `DocumentsContract.Document.COLUMN_DISPLAY_NAME` | e.g. `"nice.audioapp.zip"`. Used as the row label in the dialog. |
| `sizeBytes` | `Long` | `DocumentsContract.Document.COLUMN_SIZE` | File size in bytes. May be `0` if the provider doesn't expose size (we do not crash). |
| `lastModifiedMillis` | `Long` | `DocumentsContract.Document.COLUMN_LAST_MODIFIED` | Epoch millis. May be `0` if the provider doesn't expose it. |

This class is **immutable**. It is the return type of
`listAudioAppZipsIn` and the argument to `showLoadFolderDialog`.

---

## 3. `listAudioAppZipsIn` (new helper)

```kotlin
// In ProjectArchiveStore.kt.
import android.provider.DocumentsContract

/**
 * Enumerates the children of [treeUri] and returns those whose
 * `COLUMN_DISPLAY_NAME` ends with [PROJECT_FILE_SUFFIX]
 * (case-insensitive).
 *
 * Uses the local DocumentsProvider for [treeUri]; does NOT consult
 * MediaStore. Returns an empty list when:
 * - the tree has no children,
 * - the tree has children but none match the suffix,
 * - the provider throws (e.g. unsupported URI).
 *
 * The caller is responsible for taking persistable permission on
 * [treeUri] before calling this helper.
 */
fun listAudioAppZipsIn(context: Context, treeUri: Uri): List<LoadFolderEntry> {
    val resolver = context.contentResolver
    val childrenUri = try {
        DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, "root")
    } catch (e: Exception) {
        Log.w("audioapp_daw", "buildChildDocumentsUriUsingTree failed for $treeUri", e)
        return emptyList()
    }
    val projection = arrayOf(
        DocumentsContract.Document.COLUMN_DOCUMENT_URI,
        DocumentsContract.Document.COLUMN_DISPLAY_NAME,
        DocumentsContract.Document.COLUMN_SIZE,
        DocumentsContract.Document.COLUMN_LAST_MODIFIED,
    )
    val out = mutableListOf<LoadFolderEntry>()
    return try {
        resolver.query(childrenUri, projection, null, null, null)?.use { cursor ->
            val uriIdx = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_DOCUMENT_URI)
            val nameIdx = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
            val sizeIdx = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_SIZE)
            val modIdx = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_LAST_MODIFIED)
            while (cursor.moveToNext()) {
                val name = if (nameIdx >= 0) cursor.getString(nameIdx) else null
                if (name != null && name.endsWith(PROJECT_FILE_SUFFIX, ignoreCase = true)) {
                    val docUri = if (uriIdx >= 0) {
                        Uri.parse(cursor.getString(uriIdx))
                    } else continue
                    val size = if (sizeIdx >= 0) cursor.getLong(sizeIdx) else 0L
                    val mod = if (modIdx >= 0) cursor.getLong(modIdx) else 0L
                    out.add(LoadFolderEntry(docUri, name, size, mod))
                }
            }
        }
        out
    } catch (e: Exception) {
        Log.w("audioapp_daw", "query children failed for $treeUri", e)
        emptyList()
    }
}
```

**Inputs / outputs:**

- `context: Context` — used only for `ContentResolver` access.
- `treeUri: Uri` — the tree URI returned by the folder picker.
  Caller must have already called `takeFolderUriPermission` on it.
- Returns `List<LoadFolderEntry>` — empty list on any failure.

**Threading:** blocking. Called on the platform thread. Folder contents
are bounded; sub-100ms in practice.

**Validation:** none beyond what `DocumentsContract.buildChildDocumentsUriUsingTree`
already does.

**Behavior in edge cases:**

- Provider throws on `buildChildDocumentsUriUsingTree`: returns empty
  list. Logged.
- Provider throws on `query`: returns empty list. Logged.
- A row has `COLUMN_DOCUMENT_URI = null`: skipped (continue).
- A row has `COLUMN_DISPLAY_NAME = null`: skipped (no name to match
  the suffix against).

---

## 4. `takeFolderUriPermission` (new helper)

```kotlin
// In ProjectArchiveStore.kt.
import android.content.Intent

/**
 * Takes a persistable read grant on [treeUri]. Required so that the
 * folder URI survives process death and reboots (without persistable
 * permission, the grant is session-scoped and `getChildDocuments`
 * would throw SecurityException after the process is killed).
 *
 * Failures are silent: a session grant is sufficient for the
 * immediate folder enumeration call. Mirrors the pattern in
 * [persistDocumentUri].
 */
fun takeFolderUriPermission(context: Context, treeUri: Uri) {
    try {
        context.contentResolver.takePersistableUriPermission(
            treeUri,
            Intent.FLAG_GRANT_READ_URI_PERMISSION,
        )
    } catch (_: SecurityException) {
        // Session grant is sufficient for one-shot enumeration.
    }
}
```

**Inputs / outputs:**

- `context: Context` — used for `ContentResolver`.
- `treeUri: Uri` — the tree URI returned by the folder picker.

**Threading:** safe to call from the platform thread.

---

## 5. `OpenProjectFolder` (new nested contract, replaces `OpenProjectDocument`)

```kotlin
// In MainActivity.kt (internal nested class — `internal`, not `private`,
// so the same-package Kotlin unit tests in VP-4.2 can reference it).
internal class OpenProjectFolder :
    ActivityResultContracts.OpenDocumentTree() {

    override fun createIntent(context: Context, input: Uri?): Intent {
        val intent = super.createIntent(context, input)
        ProjectUriStore.loadLastFolderUri(context)?.let { lastFolderUri ->
            intent.putExtra(DocumentsContract.EXTRA_INITIAL_URI, lastFolderUri)
        }
        return intent
    }
}
```

**Inputs / outputs:**

- `context: Context` — provided by `registerForActivityResult`.
- `input: Uri?` — the optional initial tree URI passed to
  `.launch(input)`. We pass `ProjectUriStore.loadLastFolderUri(this)`
  so the superclass's own initial-folder hint also fires. Our
  override adds the same value as `EXTRA_INITIAL_URI` so older
  providers that only honor the extra are also covered.
- Returns `Intent` — the same `Intent` returned by
  `super.createIntent(...)` but with `EXTRA_INITIAL_URI` attached when
  `last_folder_uri` is non-null.

**Threading:** called on the platform thread when the launcher is
`.launch(...)`-ed.

**Behavior in edge cases:**

- `loadLastFolderUri(context)` returns `null`: the `let { ... }` block
  is skipped; the Intent has no `EXTRA_INITIAL_URI`. The folder
  picker opens at system default.
- `loadLastFolderUri(context)` returns a revoked URI: the Intent is
  still built; the system ignores the extra and opens at default.

---

## 6. `MainActivity` registration (REPLACES VP-3's `openProjectArchive`)

```kotlin
// MainActivity.kt:34-40 (REPLACES the old openProjectArchive block)

// OLD (VP-3, deleted):
// private val openProjectArchive = registerForActivityResult(
//     OpenProjectDocument(),
// ) { documentUri -> onLoadArchivePicked(documentUri) }

// NEW (VP-4):
private val openProjectFolder = registerForActivityResult(
    OpenProjectFolder(),
) { folderUri -> onFolderPicked(folderUri) }
```

**No change** to `createProjectArchive`, `createWavExport`,
`openAudioSample`, or any other launcher.

---

## 7. `launchLoadArchivePicker` (modified body — only the launch line changes)

```kotlin
// MainActivity.kt:55-62 (REPLACES the old launchLoadArchivePicker body)

private fun launchLoadArchivePicker(result: MethodChannel.Result) {
    if (pendingSaveResult != null || pendingLoadResult != null || pendingImportResult != null) {
        result.error("busy", "File picker already open", null)
        return
    }
    pendingLoadResult = result
    openProjectFolder.launch(ProjectUriStore.loadLastFolderUri(this))
}
```

**One line changes:** `openProjectArchive.launch(OPEN_ARCHIVE_MIME_FILTER)`
→ `openProjectFolder.loadLastFolderUri(this)`. The rest of the body
(busy-check, `pendingLoadResult = result`) is unchanged.

---

## 8. `onFolderPicked` (new callback, replaces the old picker-callback path)

```kotlin
// In MainActivity.kt (new private fun).
private fun onFolderPicked(folderUri: Uri?) {
    if (folderUri == null) {
        // User cancelled the folder picker. Same response as today.
        val result = pendingLoadResult
        pendingLoadResult = null
        if (result != null) {
            result.success(mapOf("ok" to false, "cancelled" to true))
        }
        return
    }
    // Persist the folder URI for next launch.
    ProjectUriStore.saveLastFolderUri(this, folderUri)
    // Take persistable permission so the URI survives reboots.
    ProjectArchiveStore.takeFolderUriPermission(this, folderUri)
    // Enumerate matching files.
    val entries = ProjectArchiveStore.listAudioAppZipsIn(this, folderUri)
    if (entries.isEmpty()) {
        showEmptyLoadFolderDialog()
    } else {
        showLoadFolderDialog(entries)
    }
}
```

**Threading:** called on the platform thread.

**Behavior in edge cases:**

- `folderUri == null`: returns the existing `cancelled: true`
  response. The `pendingLoadResult` is cleared.
- `folderUri != null` but `listAudioAppZipsIn` returns empty: shows the
  empty-state dialog. `pendingLoadResult` is **not** cleared; it is
  cleared when the user resolves the dialog (re-picks a folder or
  cancels).

---

## 9. `showLoadFolderDialog` (new helper, single-choice `MaterialAlertDialog`)

```kotlin
// In MainActivity.kt (new private fun).
private fun showLoadFolderDialog(entries: List<LoadFolderEntry>) {
    val labels = entries.map { it.displayName }.toTypedArray()
    val builder = MaterialAlertDialogBuilder(this)
        .setTitle("Open project")
        .setSingleChoiceItems(labels, -1) { dialog, which ->
            val picked = entries[which]
            dialog.dismiss()
            // Delegate to the existing load path. The MethodChannel
            // response is unchanged.
            onLoadArchivePicked(picked.documentUri)
        }
        .setNegativeButton("Cancel") { dialog, _ ->
            dialog.dismiss()
            val result = pendingLoadResult
            pendingLoadResult = null
            if (result != null) {
                result.success(mapOf("ok" to false, "cancelled" to true))
            }
        }
    builder.show()
}
```

**Threading:** called on the platform thread.

**Behavior in edge cases:**

- User taps a file: dialog dismisses, `onLoadArchivePicked(uri)` is
  called with that file's `documentUri`. The rest of the flow is the
  existing load path (read bytes, parse, JNI call, return snapshot).
- User taps "Cancel": same `cancelled: true` response as the system
  picker would have returned.

---

## 10. `showEmptyLoadFolderDialog` (new helper, empty-state `AlertDialog`)

```kotlin
// In MainActivity.kt (new private fun).
private fun showEmptyLoadFolderDialog() {
    val builder = MaterialAlertDialogBuilder(this)
        .setTitle("No .audioapp.zip files")
        .setMessage(
            "This folder does not contain any .audioapp.zip files. " +
                "Pick a different folder or cancel.",
        )
        .setPositiveButton("Pick a different folder") { dialog, _ ->
            dialog.dismiss()
            // Re-launch the folder picker. pendingLoadResult is
            // still held; the user gets another chance.
            openProjectFolder.launch(ProjectUriStore.loadLastFolderUri(this))
        }
        .setNegativeButton("Cancel") { dialog, _ ->
            dialog.dismiss()
            val result = pendingLoadResult
            pendingLoadResult = null
            if (result != null) {
                result.success(mapOf("ok" to false, "cancelled" to true))
            }
        }
    builder.show()
}
```

**Threading:** called on the platform thread.

**Behavior in edge cases:**

- "Pick a different folder": dismisses the dialog, re-launches the
  folder picker. The `pendingLoadResult` is preserved across both
  dialogs.
- "Cancel": same `cancelled: true` response as before.

---

## 11. `ProjectUriStore` additions (new helpers + key)

```kotlin
// In ProjectUriStore.kt.
object ProjectUriStore {
    private const val PREFS_NAME = "audioapp_project_store"
    private const val KEY_LAST_DOCUMENT_URI = "last_document_uri"
    private const val KEY_LAST_FOLDER_URI = "last_folder_uri"  // NEW

    fun saveLastDocumentUri(context: Context, documentUri: Uri) {
        // unchanged
    }

    fun loadLastDocumentUri(context: Context): Uri? {
        // unchanged
    }

    // NEW:
    fun saveLastFolderUri(context: Context, folderUri: Uri) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_LAST_FOLDER_URI, folderUri.toString())
            .apply()
    }

    // NEW:
    fun loadLastFolderUri(context: Context): Uri? {
        val raw = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_LAST_FOLDER_URI, null)
        return raw?.let { Uri.parse(it) }
    }
}
```

**Inputs / outputs:**

- `saveLastFolderUri(context, folderUri)`: persists
  `folderUri.toString()` under `KEY_LAST_FOLDER_URI`. No-op equivalent
  to today's `saveLastDocumentUri`.
- `loadLastFolderUri(context): Uri?`: returns the persisted URI or
  `null`. Equivalent to today's `loadLastDocumentUri`.

**Threading:** blocking `SharedPreferences` access. Sub-millisecond.

---

## 12. `ProjectArchiveStore.OPEN_ARCHIVE_MIME_FILTER` (DELETED)

```kotlin
// In ProjectArchiveStore.kt (THIS LINE IS REMOVED).
//
//   val OPEN_ARCHIVE_MIME_FILTER: Array<String> = arrayOf(
//       PROJECT_MIME_TYPE,
//       "application/zip",
//       "application/octet-stream",
//   )
```

**Deletion is required.** The folder picker does not take a MIME
filter. After VP-4, there are zero references to
`OPEN_ARCHIVE_MIME_FILTER` anywhere in the codebase. The contract
reviewer must grep for `OPEN_ARCHIVE_MIME_FILTER` and verify it does
not appear.

`PROJECT_MIME_TYPE` is **kept** (the constant is preserved for the
manifest declaration and the inbound-`ACTION_VIEW` follow-up).

`ARCHIVE_MIME_TYPE` is **kept** (the save flow still uses it).

---

## 13. `MainActivity.OpenProjectDocument` (DELETED)

```kotlin
// In MainActivity.kt (THIS NESTED CLASS IS REMOVED).
//
//   internal class OpenProjectDocument :
//       ActivityResultContracts.OpenDocument() {
//       override fun createIntent(context: Context, input: Array<String>): Intent {
//           val intent = super.createIntent(context, input)
//           ProjectArchiveStore.deriveInitialUri(context)?.let { lastUri ->
//               intent.putExtra(DocumentsContract.EXTRA_INITIAL_URI, lastUri)
//           }
//           return intent
//       }
//   }
```

**Deletion is required.** No production code path uses
`OpenProjectDocument` after VP-4. The contract reviewer must grep for
`OpenProjectDocument` and verify it does not appear.

The existing tests `OpenProjectDocumentTest.kt` and any references to
`OpenProjectDocument` in `ProjectArchiveMimeTest.kt` are **deleted**
together with the class. (The two new test classes
`OpenProjectFolderTest.kt` and `LoadFolderListingTest.kt` replace
them.)

`ProjectArchiveStore.deriveInitialUri(context)` is **kept** for now
(used by no production code after VP-4, but harmless; the inbound
`ACTION_VIEW` follow-up may re-use it for pre-filling the picked
document URI). If a follow-up cleans it up, fine; VP-4 does not
require deletion.

---

## 14. MethodChannel surface (UNCHANGED, pinned)

For completeness, the Dart-side call is **unchanged**:

```dart
// Existing (unchanged) call in settings_screen.dart:
final snapshot = await widget.bridge.loadProject();
```

The Kotlin handler `launchLoadArchivePicker` (line 55–62) is also
**unchanged in its wire shape**: it still responds to the
`loadProject` MethodChannel call with the same `{ok, snapshot, uri,
cancelled}` map.

**No new MethodChannel methods. No new fields on any existing
response.**

---

## 15. `AndroidManifest.xml` and `build.gradle.kts` — UNCHANGED (pinned)

- `AndroidManifest.xml` keeps VP-1's vendor-MIME `<intent-filter>`
  block (5 lines inside `<activity android:name=".MainActivity">`).
  VP-4 adds zero manifest lines.
- `build.gradle.kts` keeps VP-1's `testOptions { ... }` (3 lines) and
  `testImplementation("junit:junit:4.13.2")` (1 line). VP-4 adds zero
  Gradle lines.

---

## 16. Versioning / compatibility

- **No bridge version bump.** The change is contained to the SAF
  folder-picker flow. Existing `saveProject` / `loadProject` callers
  see no API change.
- **No minSdk bump.** `ActivityResultContracts.OpenDocumentTree` has
  been available since API 21; our minSdk is 26.
- **No new runtime permission.** `ACTION_OPEN_DOCUMENT_TREE` requires
  no permission at runtime.
- **No migration.** `last_folder_uri` is null on first launch after
  VP-4. `last_document_uri` is preserved unchanged.

---

## 17. Open questions for the orchestrator

These are flagged but do **not** block implementation. The contract
commits to a default; the orchestrator can override before kicking off
the implementation worker.

1. **Should the dialog show `lastModifiedMillis` as a relative time
   ("3 days ago") or as an absolute timestamp ("Jun 17 14:32")?**
   The contract's code example does not render the field at all (only
   `displayName`); the size and timestamp are present in
   `LoadFolderEntry` for a future richer UI but not shown today.
   **Default: display only `displayName` for now; size and timestamp
   reserved for follow-up.** A small `TextView` per row could be added
   trivially using a custom adapter, but plain `setSingleChoiceItems`
   is the MVP.
2. **Should the dialog offer "Open in another app" / "Show in Files"?**
   No. The dialog is the in-app UX; "Show in Files" would launch
   another activity and break the load flow. **Default: no.**
3. **Should `last_folder_uri` be cleared if the user picks a folder,
   it has no matches, and they hit "Cancel"?** No. The next launch
   should still land at that folder (the user might add a file there
   between sessions). **Default: do not clear on Cancel.**
4. **Should the in-app dialog be sorted (by name, by modified)?** The
   contract returns entries in cursor order (effectively insertion
   order from the provider). A sorted view is a follow-up. **Default:
   no sorting in MVP.**
