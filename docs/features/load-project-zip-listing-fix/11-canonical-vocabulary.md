# Canonical Vocabulary (VP-4)

These names are **binding** for the implementation. Implementation
agents must not invent synonyms, alternative names, or abbreviations.
Every concept has exactly one canonical name across all layers (Kotlin,
XML, Gradle, Dart).

## Core names

| Concept | Canonical name | Type / file | Notes |
|---------|----------------|-------------|-------|
| Canonical filename suffix that identifies an audioapp project archive | `PROJECT_FILE_SUFFIX` | `ProjectArchiveStore.PROJECT_FILE_SUFFIX` (`const val`) | `.audioapp.zip` (lowercase, includes leading dot). Used by `listAudioAppZipsIn` for case-insensitive `endsWith` filtering. The same string the save flow writes as `DEFAULT_ARCHIVE_NAME = "project.audioapp.zip"` minus the `project.` prefix. |
| The Kotlin data class describing one row of the in-app listing dialog | `LoadFolderEntry` | `ProjectArchiveStore.LoadFolderEntry` (`data class`) | Fields: `documentUri: Uri`, `displayName: String`, `sizeBytes: Long`, `lastModifiedMillis: Long`. Immutable. Used both as the return type of `listAudioAppZipsIn` and the argument to `showLoadFolderDialog`. |
| The new SAF folder-picker ActivityResultContract | `OpenProjectFolder` | **Internal** nested class inside `MainActivity` | Subclass of `ActivityResultContracts.OpenDocumentTree()`. Its only purpose is to attach `EXTRA_INITIAL_URI` from `ProjectUriStore.loadLastFolderUri(context)`. `internal` (not `private`) so the same-package Kotlin unit tests in VP-4.2 can reference it. **Replaces** `OpenProjectDocument` (which is deleted). |
| The ActivityResultLauncher registration for the new folder picker | `openProjectFolder` | `MainActivity.openProjectFolder` (`private val`, `registerForActivityResult`) | **Replaces** `openProjectArchive`. |
| The folder picker callback | `onFolderPicked(uri: Uri?)` | `MainActivity.onFolderPicked` (`private fun`) | **Replaces** the picker launch site in `launchLoadArchivePicker`. Persists `last_folder_uri`, takes persistable permission, enumerates children, shows the in-app dialog. |
| The in-app dialog that lists matching files | `showLoadFolderDialog(entries: List<LoadFolderEntry>)` | `MainActivity.showLoadFolderDialog` (`private fun`) | Builds a `MaterialAlertDialogBuilder.setSingleChoiceItems(...)`. The user taps an entry; the dialog dismisses and `onLoadArchivePicked(uri)` is called. |
| The in-app empty-state dialog | `showEmptyLoadFolderDialog()` | `MainActivity.showEmptyLoadFolderDialog` (`private fun`) | "No .audioapp.zip files in this folder" with a "Pick a different folder" button that re-launches the folder picker. Does not resolve the pending `MethodChannel.Result`. |
| Folder enumeration helper | `listAudioAppZipsIn(context, treeUri): List<LoadFolderEntry>` | `ProjectArchiveStore.listAudioAppZipsIn` (`fun`) | Queries `DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, "root")` for `Document.COLUMN_*` columns; filters rows by `displayName.endsWith(PROJECT_FILE_SUFFIX, ignoreCase = true)`. Returns an empty list when no matches. |
| Persistable-permission helper for tree URIs | `takeFolderUriPermission(context, treeUri)` | `ProjectArchiveStore.takeFolderUriPermission` (`fun`) | Calls `contentResolver.takePersistableUriPermission(treeUri, Intent.FLAG_GRANT_READ_URI_PERMISSION)`. Catches `SecurityException` silently (matches the existing `persistDocumentUri` pattern). |
| SharedPreferences key for the last folder URI | `last_folder_uri` | `ProjectUriStore.KEY_LAST_FOLDER_URI` (`private const val`) | Stored under the same `audioapp_project_store` SharedPreferences as `last_document_uri`. The string key is `"last_folder_uri"`. |
| Folder URI read helper | `loadLastFolderUri(context): Uri?` | `ProjectUriStore.loadLastFolderUri` (`fun`) | Returns the persisted tree URI or null. |
| Folder URI write helper | `saveLastFolderUri(context, folderUri)` | `ProjectUriStore.saveLastFolderUri` (`fun`) | Stores the tree URI string under `KEY_LAST_FOLDER_URI`. |
| Tree-URI initial-folder hint for the folder picker | `EXTRA_INITIAL_URI` | Java SDK constant (`DocumentsContract.EXTRA_INITIAL_URI`) | Same string extra as in VP-1. Works with both `ACTION_OPEN_DOCUMENT` and `ACTION_OPEN_DOCUMENT_TREE` — the system handles tree URIs by landing directly on the chosen folder. |
| The MethodChannel method for loading a project (UNCHANGED) | `loadProject` | `MainActivity.configureFlutterEngine` `when` branch | The wire format is unchanged. The handler body now calls `launchLoadArchivePicker` → `openProjectFolder.launch(...)` instead of `openProjectArchive.launch(...)`. The Dart-side call site is unchanged. |
| The save MIME (UNCHANGED) | `ARCHIVE_MIME_TYPE` | `ProjectArchiveStore.ARCHIVE_MIME_TYPE` (`const val`) | Still `"application/zip"`. The save flow is unchanged. |
| The vendor MIME constant (UNCHANGED, unused on load after VP-4) | `PROJECT_MIME_TYPE` | `ProjectArchiveStore.PROJECT_MIME_TYPE` (`const val`) | Still `"application/vnd.audioapp.project+zip"`. Still declared in `AndroidManifest.xml` (VP-1's filter). No production code reads it after VP-4; it is preserved for the inbound-`ACTION_VIEW` follow-up and for any future slice that needs it. |

## Reserved / forbidden names

These are explicitly off-limits:

- **`OpenProjectDocument`** — deleted. Do not reintroduce. The file
  picker is gone for the load flow.
- **`openProjectArchive`** — deleted. Do not reintroduce. The
  ActivityResultLauncher registration is `openProjectFolder` now.
- **`OPEN_ARCHIVE_MIME_FILTER`** — deleted. The tree picker does not
  take a MIME filter; the array has no caller.
- **`OPEN_PROJECT_MIME_FILTER`** — alternative name sometimes used
  in other codebases; do not introduce.
- **`openArchiveMimeFilter`** — already deleted in VP-1. Already
  forbidden.
- **`ProjectListing`**, **`FolderListing`**, **`AudioAppProjectListing`**
  — alternative names for `LoadFolderEntry`. Use `LoadFolderEntry`.
- **`ProjectFileEntry`**, **`ProjectFile`** — alternative names. Use
  `LoadFolderEntry`.
- **`recentFolders`** — the user explicitly rejected any "recent
  projects / folders" history. We persist **only** the most recent
  single folder URI. Do not introduce a list.
- **Editing `MainActivity.configureFlutterEngine` to add a new
  MethodChannel method** — the wire format must stay identical.
- **Modifying any Dart / Flutter file** — out of scope.

## Cross-layer identity

The `PROJECT_FILE_SUFFIX` literal appears in exactly **two** places in
the codebase:

1. `ProjectArchiveStore.PROJECT_FILE_SUFFIX` (the `const val`).
2. The test file `LoadFolderListingTest.kt` references it as
   `ProjectArchiveStore.PROJECT_FILE_SUFFIX`.

The `last_folder_uri` string key appears in exactly **two** places:

1. `ProjectUriStore.KEY_LAST_FOLDER_URI` (the `private const val`).
2. The test file `ProjectUriStoreTest.kt` references it via the helper
   functions `saveLastFolderUri` / `loadLastFolderUri`.

`LoadFolderEntry` is referenced in exactly **three** places:

1. `ProjectArchiveStore.listAudioAppZipsIn` (return type).
2. `MainActivity.showLoadFolderDialog` (parameter type).
3. `MainActivity.onFolderPicked` (intermediate variable type).

A typo in any one place breaks compilation of the rest. The contract
reviewer must grep.

## The "what about MIME for the load flow?" question (recorded)

VP-1/VP-2/VP-3 added `PROJECT_MIME_TYPE` and `OPEN_ARCHIVE_MIME_FILTER`
on the load side. VP-4 deletes `OPEN_ARCHIVE_MIME_FILTER` and stops
using `PROJECT_MIME_TYPE` in the load path. The constant itself is
**preserved** (not deleted) because:

1. The `<intent-filter>` in `AndroidManifest.xml` still declares it
   (VP-1's manifest diff is preserved unchanged). If we deleted the
   Kotlin constant, the manifest would reference a string with no
   Kotlin-side peer; the contract says "the MIME literal must be
   identical in Kotlin and XML."
2. A follow-up slice will handle inbound `ACTION_VIEW` with the vendor
   MIME (see `01-architecture.md` §"Out-of-scope follow-ups" in the
   VP-1 contract); that slice needs the constant.
3. Removing it is a delete that crosses file boundaries (Kotlin +
   manifest); the architectural review is cleaner if we keep the
   constant and add a `// (Reserved for inbound ACTION_VIEW follow-up;
   no production load-path reader after VP-4)` comment.

## The "filter by filename vs by MIME" question (recorded)

The user might wonder: why not keep the MIME filter and add
`mime_type IS NULL OR mime_type = 'application/octet-stream'` to it?
Answer: the tree picker is **not** a MediaProvider query. The columns
returned by `DocumentsContract.getChildDocuments` come from the local
DocumentsProvider, not from MediaStore. The MIME column is populated
by the provider on a best-effort basis but is **not authoritative** for
our use case. Some providers leave it `NULL`; some populate it. The
authoritative filter is the filename, which is always populated.

This is the load-bearing observation: **filename is stable, MIME is
not**. The contract commits to filename filtering.

## `takeFolderUriPermission` vs `persistDocumentUri` (recorded)

The existing `ProjectArchiveStore.persistDocumentUri` is for
**document** URIs (single files). The new
`ProjectArchiveStore.takeFolderUriPermission` is for **tree** URIs
(folders). They look similar (both call `takePersistableUriPermission`)
but operate on different URI shapes and must not be merged. The
document helper passes `FLAG_GRANT_READ_URI_PERMISSION` (and optionally
`FLAG_GRANT_WRITE_URI_PERMISSION` for save); the folder helper always
passes only `FLAG_GRANT_READ_URI_PERMISSION` because we only ever
**read** the folder's contents.
