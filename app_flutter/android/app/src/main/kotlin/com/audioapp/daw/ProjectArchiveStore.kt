package com.audioapp.daw

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.util.Log
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
import java.util.zip.ZipOutputStream

/**
 * Android OS-bridge: `.audioapp.zip` archives (ADR-0005 / ADR-0006).
 *
 * Archive layout:
 * - project.json
 * - assets/samples/
 * - metadata/
 *
 * C++ owns JSON schema; this class builds/opens zip bytes via SAF document URIs.
 */
object ProjectArchiveStore {
    const val PROJECT_JSON_ENTRY = "project.json"
    const val DEFAULT_ARCHIVE_NAME = "project.audioapp.zip"
    const val ARCHIVE_MIME_TYPE = "application/zip"
    const val PROJECT_MIME_TYPE = "application/vnd.audioapp.project+zip"
    // (Reserved for inbound ACTION_VIEW follow-up;
    // no production load-path reader after VP-4)
    const val PROJECT_FILE_SUFFIX = ".audioapp.zip"

    data class LoadFolderEntry(
        val documentUri: Uri,
        val displayName: String,
        val sizeBytes: Long,
        val lastModifiedMillis: Long,
    )

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
        // Deviation from contract §3: COLUMN_DOCUMENT_URI does not exist on
        // DocumentsContract.Document in any Android SDK (verified against
        // android-35 and android-36). The actual constant is COLUMN_DOCUMENT_ID;
        // the document URI is reconstructed via buildDocumentUriUsingTree(treeUri,
        // documentId). The LoadFolderEntry shape and the suffix filter logic
        // are unchanged. See VP-4 final-summary "contract deviations".
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_SIZE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
        )
        val out = mutableListOf<LoadFolderEntry>()
        return try {
            resolver.query(childrenUri, projection, null, null, null)?.use { cursor ->
                val idIdx = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
                val nameIdx = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
                val sizeIdx = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_SIZE)
                val modIdx = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_LAST_MODIFIED)
                while (cursor.moveToNext()) {
                    val name = if (nameIdx >= 0) cursor.getString(nameIdx) else null
                    if (name != null && name.endsWith(PROJECT_FILE_SUFFIX, ignoreCase = true)) {
                        val docUri = if (idIdx >= 0) {
                            val documentId = cursor.getString(idIdx)
                            if (documentId != null) {
                                DocumentsContract.buildDocumentUriUsingTree(treeUri, documentId)
                            } else continue
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

    fun buildArchiveBytes(projectJson: String): ByteArray {
        ByteArrayOutputStream().use { buffer ->
            ZipOutputStream(buffer).use { zip ->
                zip.putNextEntry(ZipEntry(PROJECT_JSON_ENTRY))
                zip.write(projectJson.toByteArray(Charsets.UTF_8))
                zip.closeEntry()

                zip.putNextEntry(ZipEntry("assets/samples/"))
                zip.closeEntry()

                zip.putNextEntry(ZipEntry("metadata/"))
                zip.closeEntry()
            }
            return buffer.toByteArray()
        }
    }

    fun extractProjectJson(archiveBytes: ByteArray): String {
        ZipInputStream(archiveBytes.inputStream()).use { zip ->
            while (true) {
                val entry = zip.nextEntry ?: break
                if (entry.name == PROJECT_JSON_ENTRY || entry.name.endsWith("/$PROJECT_JSON_ENTRY")) {
                    val json = zip.readBytes().toString(Charsets.UTF_8)
                    if (json.isBlank()) {
                        throw IOException("project.json is empty in archive")
                    }
                    return json
                }
                zip.closeEntry()
            }
        }
        throw IOException("project.json not found in archive")
    }

    fun persistDocumentUri(context: Context, documentUri: Uri, writable: Boolean) {
        var flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
        if (writable) {
            flags = flags or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        }
        try {
            context.contentResolver.takePersistableUriPermission(documentUri, flags)
        } catch (_: SecurityException) {
            // Session grant is sufficient for one-shot create/open.
        }
    }

    @Throws(IOException::class)
    fun writeProjectArchive(context: Context, documentUri: Uri, projectJson: String) {
        persistDocumentUri(context, documentUri, writable = true)
        val bytes = buildArchiveBytes(projectJson)
        context.contentResolver.openOutputStream(documentUri)?.use { stream ->
            stream.write(bytes)
        } ?: throw IOException("Could not open archive for writing")
    }

    @Throws(IOException::class)
    fun readProjectArchive(context: Context, documentUri: Uri): String {
        persistDocumentUri(context, documentUri, writable = false)
        val bytes = context.contentResolver.openInputStream(documentUri)?.use { stream ->
            stream.readBytes()
        } ?: throw IOException("Could not open archive for reading")
        if (bytes.isEmpty()) {
            throw IOException("Archive is empty")
        }
        return extractProjectJson(bytes)
    }
}
