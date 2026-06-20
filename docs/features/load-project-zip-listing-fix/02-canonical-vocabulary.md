# Canonical Vocabulary

These names are **binding** for the implementation. Implementation
agents must not invent synonyms, alternative names, or
abbreviations. Every concept has exactly one canonical name across
all layers (Kotlin, XML, Gradle).

## Core names

| Concept | Canonical name | Type / file | Notes |
|---------|----------------|-------------|-------|
| The vendor MIME type for our archive | `application/vnd.audioapp.project+zip` | `ProjectArchiveStore.PROJECT_MIME_TYPE` (`const val`) | RFC 6838 §4.2 vendor tree + RFC 6839 §3.6 `+zip` structured-syntax suffix. Validated per RFC: `vnd.` prefix for vendor; `+zip` suffix indicates the file's underlying representation follows the ZIP format. |
| The MIME filter array for the load picker | `OPEN_ARCHIVE_MIME_FILTER` | `ProjectArchiveStore.OPEN_ARCHIVE_MIME_FILTER` (`val`, `Array<String>`) | `arrayOf("application/vnd.audioapp.project+zip", "application/zip")`. Vendor MIME first so providers that know it lead with our files; `application/zip` second as a generic-zip fallback so older Files apps still work. |
| The MIME used for the save picker (UNCHANGED) | `ARCHIVE_MIME_TYPE` | `ProjectArchiveStore.ARCHIVE_MIME_TYPE` (`const val`) | Already exists. **Stays `application/zip`.** We keep the save MIME as the well-known type so the system can produce a real zip file the user can open anywhere. |
| The Intent extra key for the initial folder/document hint | `DocumentsContract.EXTRA_INITIAL_URI` | Java SDK constant (no new constant) | The system-defined string `android.provider.extra.INITIAL_URI`. The Android docs say: *"Location should specify a document URI or a tree URI with document ID. If this URI identifies a non-directory, document navigator will attempt to use the parent of the document as the initial location."* Our `last_document_uri` is exactly such a document URI. |
| The Intent extra key for the MIME-type array | `EXTRA_MIME_TYPES` (alias `Intent.EXTRA_MIME_TYPES`) | Java SDK constant (no new constant) | The system-defined string `android.intent.extra.MIME_TYPES`. Populated automatically by `ActivityResultContracts.OpenDocument(arrayOf(...))`. |
| The ActivityResultContract for opening a project | `OpenProjectDocument` | **Internal** nested class inside `MainActivity` | Subclass of `ActivityResultContracts.OpenDocument()`. Its only purpose is to attach `EXTRA_INITIAL_URI` after `super.createIntent(...)`. `internal` (not `private`) so the same-package Kotlin unit tests in `src/test/` can reference it. |
| The URI helper that returns the last project URI (or null) | `deriveInitialUri(context)` | `ProjectArchiveStore.deriveInitialUri(Context): Uri?` | Thin wrapper over `ProjectUriStore.loadLastDocumentUri(context)`. Returns null when no URI has been persisted. Decoupling this from `MainActivity` is what makes the helper unit-testable. |
| Last project URI (UNCHANGED) | `last_document_uri` | `ProjectUriStore.KEY_LAST_DOCUMENT_URI` (`const val`, already exists) | The string key under `SharedPreferences("audioapp_project_store")`. |
| The Manifest MIME declaration | `<data android:mimeType="application/vnd.audioapp.project+zip" />` | `AndroidManifest.xml` `<intent-filter>` inside `<activity android:name=".MainActivity">` | Matches the Kotlin constant exactly. Adding this `<intent-filter>` makes the system treat the app as a recognized handler for the MIME — useful when the user opens a `.audioapp.zip` from another app. |
| The Gradle test option | `testOptions.unitTests.isReturnDefaultValues` | `app_flutter/android/app/build.gradle.kts` (`android { ... }` block) | Standard Android Gradle DSL option. Setting it to `true` lets unit tests reference Android framework classes (like `Uri`) that are normally stubbed out. |
| The Kotlin test dependency | `junit:junit:4.13.2` | `app_flutter/android/app/build.gradle.kts` `dependencies { ... }` block | Standard JUnit 4. The repo currently has zero Kotlin unit-test infrastructure; this is the minimum addition. |

## Reserved / Forbidden Names

These are explicitly off-limits:

- **`vnd.audioapp.audioapp`** — redundant. We use
  `vnd.audioapp.project` (project is the artifact, not the
  vendor). The vendor is "audioapp"; the product is
  "project" (an audioapp project).
- **`audioapp/zip`**, **`audioapp-project`** — non-RFC.
  These do not follow the vendor-tree prefix and would
  not be recognized as MIME types by Android.
- **`audio/x-audioapp`**, **`application/x-audioapp`** — the
  `x-` prefix is deprecated (RFC 6838 §4.1.2 notes the
  vendor tree supersedes it). Do not introduce.
- **`RecentProject`**, **`ProjectListEntry`**,
  **`filesDir/projects/`**, **`listProjects`**,
  **`loadProjectByPath`** — these were part of the
  previous (rejected) contract. **Do not reintroduce.**
- **Editing `MainActivity.openProjectArchive` to the
  default `OpenDocument()` contract** — that would lose
  the `EXTRA_INITIAL_URI` plumbing. The
  `OpenProjectDocument` subclass must be used.

## Cross-Layer Identity

The new MIME type appears in exactly three places, all with
the **exact same string literal**:

1. Kotlin: `ProjectArchiveStore.PROJECT_MIME_TYPE`
2. Kotlin: `ProjectArchiveStore.OPEN_ARCHIVE_MIME_FILTER[0]`
3. XML: `<data android:mimeType="application/vnd.audioapp.project+zip" />`

A typo in any one of them breaks the filter. The contract
reviewer must grep all three.

The `EXTRA_INITIAL_URI` plumbing appears in exactly two
places, both in `MainActivity.kt`:

1. The `OpenProjectDocument.createIntent` override (where
   we `putExtra(...)`).
2. The call site `ProjectArchiveStore.deriveInitialUri(this)`
   that produces the value.

`ProjectUriStore` is the **single source of truth** for the
persisted URI. `deriveInitialUri` is the only function that
reads it from outside `ProjectUriStore`. No other code may
call `getSharedPreferences("audioapp_project_store", ...)`
directly.

## MIME type decision (rationale, recorded)

The user proposed `application/vnd.audioapp.project+zip`.
**The architect confirms this MIME is correct** per:

- **RFC 6838 §4.2.8:** *"Vendor-tree registrations will be
  distinguished by the leading facet `vnd.`."* ✔ Our
  subtype starts with `vnd.`.
- **RFC 6838 §4.2.8 (continued):** *"That may be followed,
  at the discretion of the registrant, by either a subtype
  name from a well-known producer (e.g., `vnd.mudpie`) or
  by an IANA-approved designation of the producer's name
  that is followed by a media type or product designation
  (e.g., `vnd.bigcompany.funnypictures`)."* ✔ Our
  `vnd.audioapp.project` matches the second form.
- **RFC 6839 §3.6:** *"The suffix `+zip` MAY be used with
  any media type whose representation follows that
  established for `application/zip`."* ✔ Our `.audioapp.zip`
  file IS a zip file. The suffix is valid.

The MIME type decision is **committed**. The architect does
not need to revisit it. The one nuance — that
`ACTION_CREATE_DOCUMENT` should still use
`application/zip` (not our vendor MIME) so the system's
save dialog produces a real, universally-readable zip — is
documented in `01-architecture.md` §"Why keep the save MIME
as `application/zip`."

## `EXTRA_INITIAL_URI` decision (rationale, recorded)

The Android docs (`DocumentsContract.EXTRA_INITIAL_URI`)
state:

> *"Sets the desired initial location visible to user when
> file chooser is shown.... Location should specify a
> document URI or a tree URI with document ID. If this
> URI identifies a non-directory, document navigator will
> attempt to use the parent of the document as the initial
> location."*

The URI we have in `ProjectUriStore.last_document_uri` is
a **document URI returned from `ACTION_OPEN_DOCUMENT` /
`ACTION_CREATE_DOCUMENT`** — the system explicitly
guarantees this when we receive a result. The system
also explicitly handles the "URI is a non-directory" case
by **falling back to the parent folder**. This is exactly
the behavior we want: the picker opens at the folder
containing the user's last saved/loaded project.

**Conclusion: the document URI from `ProjectUriStore` is
the correct `EXTRA_INITIAL_URI` value.** No
`ACTION_OPEN_DOCUMENT_TREE` flow is needed. No
`Downloads` collection fallback is needed. The architect
does not need to revisit this.

**Edge cases:**

- If `last_document_uri` is `null` (fresh install, or
  user cleared app data), we omit the extra. The picker
  opens at SAF default. Correct.
- If the URI has been revoked (user deleted the file
  from Files app), the system silently ignores the
  extra and opens at SAF default. Correct.
- If the URI points to a deleted directory, the system
  ignores the extra. Correct.

The behavior is graceful in every edge case without any
extra logic in our code.
