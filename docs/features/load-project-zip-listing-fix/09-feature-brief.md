# Feature Brief (VP-4): Replace `ACTION_OPEN_DOCUMENT` with `ACTION_OPEN_DOCUMENT_TREE`

## TL;DR

After three rounds of fix (VP-1 `EXTRA_INITIAL_URI` + vendor MIME,
VP-2 added `application/octet-stream`, VP-3 `MediaScannerConnection.scanFile`
on save), the user's existing `.audioapp.zip` files still do not appear in
the SAF "Open project" picker. The verified root cause is
**MediaStore has `mime_type=NULL` for those files** on Android 11+, and
the OEM DocumentsProvider on Moto g86 Power 5G (Android 16) refuses to
surface them through any `ACTION_OPEN_DOCUMENT` filter — including `*/*`.

VP-4 abandons the file-picker route. The user now picks a **folder**
(`ACTION_OPEN_DOCUMENT_TREE`), the app lists its children by **filename
suffix** (`.audioapp.zip`, case-insensitive) inside an in-app
`MaterialAlertDialog`, and the user picks one. The bytes are read with
the existing `ProjectArchiveStore.readProjectArchive`. The wire format
of `loadProject` is unchanged: Dart still gets back a snapshot.

## What failed in VP-1 / VP-2 / VP-3

| Iter | Change                                                                                       | Result on device                                                              |
|------|----------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------|
| VP-1 | `OpenProjectDocument` adds `EXTRA_INITIAL_URI` + custom `application/vnd.audioapp.project+zip` MIME | Picker opened at the right folder but the visible list was empty ("Keine Elemente"). |
| VP-2 | Added `application/octet-stream` to `OPEN_ARCHIVE_MIME_FILTER`                                | Same — the folder still rendered empty.                                       |
| VP-3 | `MediaScannerConnection.scanFile(this, ...)` on every save with the resolved display path    | New saves get a real `application/zip` MediaStore row, but **pre-existing** files remain `mime_type=NULL`; `am broadcast MEDIA_SCANNER_SCAN_FILE` for `file://` URIs is silently dropped on Android 11+. |

### The direct adb probe (from the user)

```bash
adb shell content query --uri "content://media/external/file/1000000002" \
    --projection mime_type
# Row: 0 mime_type=NULL
```

The 11 existing `.audioapp.zip` files are real zips (`PK\x03\x04` magic
verified) but their MediaStore rows have `mime_type=NULL`. On Android 11+,
`ACTION_OPEN_DOCUMENT` is backed by `com.android.providers.media`, which
excludes `mime_type=NULL` rows from any MIME filter — including `*/*`.
No amount of MIME-filter manipulation from the launching app changes this
behavior; it is a deliberate Android 11+ design.

### Why `am broadcast MEDIA_SCANNER_SCAN_FILE` does not help

Android 11+ scoped storage silently drops the broadcast for `file://`
URIs unless the calling app holds `MANAGE_EXTERNAL_STORAGE`, which we
do not (and should not) request. The only context that can re-index a
file is the app that owns the file or the system itself. From a normal
user-installed app, the only way to surface `mime_type=NULL` files in
the SAF picker is **to stop using the file picker for them**.

## The VP-4 fix (one paragraph)

Replace `openProjectArchive` (an `ACTION_OPEN_DOCUMENT` contract) with
`openProjectFolder` (an `ACTION_OPEN_DOCUMENT_TREE` contract). The user
picks a folder; `MainActivity` enumerates its children via
`DocumentsContract.getChildDocuments(...)` and filters them by the
canonical suffix `PROJECT_FILE_SUFFIX = ".audioapp.zip"` (case-insensitive
`endsWith`). The matching files are presented in an in-app
`MaterialAlertDialog` (single-choice list) with display name, last-modified
relative time, and size. When the user taps one, the chosen document URI
is passed to the existing `onLoadArchivePicked` flow, which reads bytes
via `ProjectArchiveStore.readProjectArchive` and returns the snapshot
to Dart over the unchanged MethodChannel. The folder URI is persisted
in a new `ProjectUriStore.last_folder_uri` SharedPreferences key (the
existing `last_document_uri` key is preserved unchanged for backwards
compatibility with files saved before VP-4).

## User-visible goal

On Android, when the user taps **Settings → Open project**:

1. The system SAF folder picker opens at the user's last-used folder
   (via `EXTRA_INITIAL_URI` from `last_folder_uri`).
2. The user picks a folder.
3. An in-app dialog lists every file in that folder ending in
   `.audioapp.zip` (case-insensitive). Non-matching files are not shown.
4. The user taps one. The project loads. The existing "Loaded project"
   snackbar fires.

## Non-goals

- No Dart-side UI. The listing is a native `MaterialAlertDialog`.
- No new `MethodChannel` method. The wire format is unchanged.
- No new runtime permission (`ACTION_OPEN_DOCUMENT_TREE` does not need
  any).
- No new Gradle dependency. Pure Kotlin + AndroidX.
- The save flow is unchanged. VP-3's `MediaScannerConnection.scanFile`
  on save remains.

## Acceptance criteria

- [ ] Tapping **Settings → Open project** opens the system folder picker
      (not a file picker).
- [ ] If `last_folder_uri` is non-null and the URI is still valid, the
      folder picker opens at that folder.
- [ ] If `last_folder_uri` is null or revoked, the picker opens at the
      system default.
- [ ] After picking a folder, an in-app dialog lists all files ending
      in `.audioapp.zip` (case-insensitive) with display name, modified
      time, size.
- [ ] Files that do not match the suffix do not appear.
- [ ] An empty folder or a folder with no matching files shows a clear
      "No .audioapp.zip files in this folder" message and a "Pick a
      different folder" button that re-launches the folder picker.
- [ ] Tapping a file in the list calls the existing load path and the
      project loads. The existing "Loaded project" snackbar fires.
- [ ] Cancelling the folder picker returns `cancelled: true` (unchanged).
- [ ] The chosen folder URI is persisted to `last_folder_uri` so the
      next folder picker opens there.
- [ ] Pre-VP-4 saves still work: `loadProject` on a previously saved
      URI (via `last_document_uri` after VP-4) still loads the file.
      (The user gets there by re-picking the folder and choosing the
      file from the in-app list.)
- [ ] `gradlew :app:testDebugUnitTest` passes with the new T12/T13/T14
      tests.
- [ ] `flutter test` and `flutter analyze` pass with 0 errors (no
      Flutter changes).

## Wow moment (per PROJECT-SPEC.md §2.7)

The user saves `nice.audioapp.zip` to `Projects/` (or any folder), kills
the app, relaunches, taps **Settings → Open project**, picks `Projects/`
(landed there automatically because it was the last folder), sees
`nice.audioapp.zip` in the in-app list, taps it, and the arrangement
re-renders. One pass, no follow-up.

## Companion sub-stories (PROJECT-SPEC.md §14.1)

None. The slice has no new Flutter UI (the listing is a native
`MaterialAlertDialog`), so `US-XX-YY-ux-ui.md` and
`US-XX-YY-interaction.md` companions are not applicable.
