# Data Contracts

This file pins the **literal data shapes** that the
implementation must produce. The shapes are intentionally
minimal: one MIME literal, one URI shape, one Intent
extras shape, one Manifest snippet.

The MethodChannel JSON wire format is **unchanged** — no
new commands, no new fields. The cross-language bridge
between Flutter and Kotlin does not change in this slice.

---

## 1. MIME type literal (canonical)

| Layer | Literal | Where |
|-------|---------|-------|
| Kotlin constant | `"application/vnd.audioapp.project+zip"` | `ProjectArchiveStore.PROJECT_MIME_TYPE` (`const val`) |
| Kotlin array element | same string | `ProjectArchiveStore.OPEN_ARCHIVE_MIME_FILTER[0]` |
| Android Manifest | same string | `<data android:mimeType="application/vnd.audioapp.project+zip" />` |
| Intent extra | same string | Implicit; appears in `EXTRA_MIME_TYPES` String[] passed to `OpenDocument` |

**Validation:**

- Must be exactly `application/vnd.audioapp.project+zip`.
  Case-sensitive. No trailing whitespace.
- Must be a valid RFC 6838 vendor-tree MIME
  (`vnd.` prefix + producer name + product name).
- Must have the RFC 6839 §3.6 `+zip` structured-syntax
  suffix (since `.audioapp.zip` is a zip file).
- Must not be one of the deprecated forms
  (`x-audioapp`, `audioapp/zip`, etc.).

A reviewer-side grep across all three files is the
correctness check.

---

## 2. MIME filter array (canonical)

```kotlin
// ProjectArchiveStore.kt
val OPEN_ARCHIVE_MIME_FILTER: Array<String> = arrayOf(
    "application/vnd.audioapp.project+zip",
    "application/zip",
)
```

| Index | Value | Purpose |
|-------|-------|---------|
| 0 | `application/vnd.audioapp.project+zip` | Primary filter. SAF providers that know the vendor MIME (after our manifest declaration) lead with our files. |
| 1 | `application/zip` | Fallback. Older SAF providers and providers that don't honor vendor MIMEs still tag `.zip` files with this, so our picker still finds them. |

**Ordering:** vendor MIME first, generic fallback second.
Do not invert. AndroidX `OpenDocument(arrayOf(...))`
sets `EXTRA_MIME_TYPES = String[]` from this array in
order; the system's filter UI generally shows the most
specific type first.

**Size:** exactly 2 elements. Do not add `*/*` (matches
everything; defeats the filter). Do not add
`application/octet-stream` (the previous bad filter
included it; it matched every file and was useless).

**Nullability:** the array is non-null. The launcher
argument must be a non-null `Array<String>`. The Kotlin
code uses `arrayOf(...)` which is non-null.

---

## 3. URI shape passed as `EXTRA_INITIAL_URI`

| Aspect | Value |
|--------|-------|
| Source | `ProjectUriStore.loadLastDocumentUri(this)` |
| Type | `android.net.Uri?` |
| Nullability | Nullable. When null, the extra is omitted entirely (not put as `null`). |
| Form | The full `Uri.toString()` of a document URI previously returned by `ACTION_OPEN_DOCUMENT` or `ACTION_CREATE_DOCUMENT`. |
| Example | `content://com.android.externalstorage.documents/tree/primary%3ADownloads%2FAudioApp/document/primary%3ADownloads%2FAudioApp%2FMy%20Beat.audioapp.zip` |

**System behavior** (per Android docs):

- *"If this URI identifies a non-directory, document
  navigator will attempt to use the parent of the
  document as the initial location."*
- For our use case, the URI is always a document (file),
  never a directory, so the system falls back to the
  parent folder. That is exactly what we want.

**No canonicalization** is applied. Whatever URI is in
`SharedPreferences` is forwarded as-is. We do **not**
parse the URI, do **not** check that the path is under
`/storage/emulated/0/...`, do **not** validate the
extension. The system handles invalid/revoked URIs
silently.

**Lifetime:** the URI in `last_document_uri` may have
been saved days or weeks ago. If the user has since
deleted the file from their Files app, the SAF grant
is revoked and the system ignores the extra. The
picker opens at SAF default. No error in our code.

---

## 4. Intent shape for `ACTION_OPEN_DOCUMENT`

Built by `OpenProjectDocument.createIntent(context, input)`
plus the superclass. The final Intent has:

| Extra | Value | Set by |
|-------|-------|--------|
| `Intent.ACTION_OPEN_DOCUMENT` | `android.intent.action.OPEN_DOCUMENT` | `super.createIntent` |
| `EXTRA_MIME_TYPES` | `["application/vnd.audioapp.project+zip", "application/zip"]` | `super.createIntent` (from `input` arg) |
| `EXTRA_INITIAL_URI` | the user's last document URI, **or absent** if none | our `createIntent` override |

The `Intent.setType(...)` is **not** called by our code
because we use the array variant (`EXTRA_MIME_TYPES`).
Per AndroidX `OpenDocument.createIntent` source, when
the input array has more than one element, it sets
`EXTRA_MIME_TYPES` and does not call `setType`.

`CATEGORY_OPENABLE` is added by `super.createIntent`
(implicit, via the contract). We do not change this.

**Flags:** none added. `FLAG_GRANT_READ_URI_PERMISSION`
is granted **to us** by the system when the user picks
a file (not the other way around). Our existing
`ProjectArchiveStore.persistDocumentUri` already calls
`takePersistableUriPermission` on the picked URI; we do
not need to do anything new here.

---

## 5. Intent shape for `ACTION_CREATE_DOCUMENT` (UNCHANGED)

The save Intent is **not modified**. For reference:

| Extra | Value | Set by |
|-------|-------|--------|
| `Intent.ACTION_CREATE_DOCUMENT` | `android.intent.action.CREATE_DOCUMENT` | `ActivityResultContracts.CreateDocument` |
| `EXTRA_TITLE` | `"project.audioapp.zip"` | `launch(DEFAULT_ARCHIVE_NAME)` |
| (no `setType` call; the type is passed to the contract constructor) | `application/zip` | `CreateDocument(ARCHIVE_MIME_TYPE)` |

The contract reviewer must verify that
`createProjectArchive` registration and
`launchSaveArchivePicker` are **byte-for-byte identical**
before and after the fix.

---

## 6. `AndroidManifest.xml` diff

### Before (existing relevant block)

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:taskAffinity=""
    android:theme="@style/LaunchTheme"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize">
    <meta-data
      android:name="io.flutter.embedding.android.NormalTheme"
      android:resource="@style/NormalTheme"
      />
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
</activity>
```

### After (only the `<intent-filter>` block changes)

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:taskAffinity=""
    android:theme="@style/LaunchTheme"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize">
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

**Whitespace:** the new filter block is indented with the
existing filter block (4-space indent inside the
`<activity>`). No trailing whitespace.

**No other manifest changes.** The contract reviewer must
verify the diff is +5 lines (the `<intent-filter>` block
plus one blank line separator) and zero lines changed.

---

## 7. `build.gradle.kts` diff

### Before (existing relevant block)

```kotlin
android {
    namespace = "com.audioapp.daw"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // ... unchanged ...
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.activity:activity-ktx:1.9.3")
}
```

### After (additions only — no other lines change)

```kotlin
android {
    namespace = "com.audioapp.daw"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // NEW: enable JVM unit tests for the Kotlin layer.
    testOptions {
        unitTests.isReturnDefaultValues = true
    }

    defaultConfig {
        // ... unchanged ...
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.activity:activity-ktx:1.9.3")
    // NEW: JUnit 4 for Kotlin unit tests.
    testImplementation("junit:junit:4.13.2")
}
```

**Two additions only:**

1. `testOptions { unitTests.isReturnDefaultValues = true }`
   inside the `android { }` block, after `kotlinOptions`.
2. `testImplementation("junit:junit:4.13.2")` inside the
   `dependencies { }` block, after the existing
   `implementation(...)` line.

The contract reviewer must verify the diff is **+5 lines
total** (3 for `testOptions`, 1 for the
`testImplementation` line, plus one blank line inside
the `dependencies` block for readability).

---

## 8. Wire format (MethodChannel) — UNCHANGED

The MethodChannel surface between Flutter and Kotlin is
**not changed**. The `loadProject` and `saveProject`
commands keep their existing request/response JSON
shapes.

For the record (no changes):

- `saveProject` request: `null`
- `saveProject` success response:
  `{ "ok": true, "uri": "...", "cancelled": false }`
- `saveProject` cancelled response:
  `{ "ok": false, "cancelled": true }`
- `saveProject` error codes: `"busy"`, `"save_failed"`,
  `"engine_error"`
- `loadProject` request: `null`
- `loadProject` success response:
  `{ "ok": true, "snapshot": { ... }, "uri": "...",
     "cancelled": false }`
- `loadProject` cancelled response:
  `{ "ok": false, "cancelled": true }`
- `loadProject` error codes: `"busy"`, `"load_failed"`,
  `"engine_error"`

All existing Flutter widget tests and `engine_bridge_test`
mocks continue to apply without modification.

---

## 9. What we are NOT shipping in this slice

- **No new MethodChannel methods.** `listProjects`,
  `loadProjectByPath` (from the rejected previous
  contract) are **not** part of this slice.
- **No `application/octet-stream` in the filter.** The
  old filter matched every file; we removed it.
- **No MIME on the save flow.** Save stays
  `application/zip`. (See `01-architecture.md`
  §"Why keep the save MIME as `application/zip`" for
  rationale.)
- **No new UI strings.** Zero Flutter / Dart changes.
- **No new permissions in the manifest.** The
  `<uses-permission>` block (INTERNET, WAKE_LOCK) is
  unchanged.
