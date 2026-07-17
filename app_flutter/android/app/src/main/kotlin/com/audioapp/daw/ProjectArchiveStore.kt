package com.audioapp.daw

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.util.Log
import java.io.ByteArrayOutputStream
import java.io.File
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
 * - assets/freeze/
 * - metadata/
 *
 * C++ owns JSON schema; this class builds/opens zip bytes via SAF document URIs.
 */
object ProjectArchiveStore {
    const val PROJECT_JSON_ENTRY = "project.json"
    const val DEFAULT_ARCHIVE_NAME = "project.audioapp.zip"
    const val ARCHIVE_MIME_TYPE = "application/zip"
    const val PROJECT_MIME_TYPE = "application/vnd.audioapp.project+zip"
    /**
     * The direct SAF Open picker deliberately has no MIME filter. Some Android
     * document providers report `.audioapp.zip` as a vendor-specific or unknown
     * MIME type, which makes a filtered picker appear empty. [readArchiveBytes]
     * and the native archive loader validate the selected content instead.
     */
    val OPEN_MIME_TYPES = arrayOf("*/*")
    // (Reserved for inbound ACTION_VIEW follow-up;
    // no production load-path reader after VP-4)
    const val PROJECT_FILE_SUFFIX = ".audioapp.zip"

    data class LoadFolderEntry(
        val documentUri: Uri,
        val displayName: String,
        val sizeBytes: Long,
        val lastModifiedMillis: Long,
    )

    data class WorkspaceEntry(
        val documentUri: Uri,
        val displayName: String,
        val isDirectory: Boolean,
    )

    private const val WORKSPACE_DIRECTORY = "projects"

    fun workspaceRootUri(context: Context): Uri = Uri.fromFile(workspaceRoot(context))

    private fun workspaceRoot(context: Context): File {
        val root = File(context.getExternalFilesDir(null) ?: context.filesDir, WORKSPACE_DIRECTORY)
        if (!root.exists() && !root.mkdirs()) {
            throw IOException("Could not create AudioApp project workspace")
        }
        return root.canonicalFile
    }

    private fun workspaceDirectory(context: Context, uri: Uri): File {
        if (uri.scheme != "file") throw IOException("Not an AudioApp workspace folder")
        val root = workspaceRoot(context)
        val directory = File(uri.path ?: throw IOException("Workspace path is missing")).canonicalFile
        val insideRoot = directory == root || directory.path.startsWith(root.path + File.separator)
        if (!insideRoot || !directory.isDirectory) throw IOException("Folder is outside the AudioApp workspace")
        return directory
    }

    fun listWorkspaceEntries(context: Context, treeUri: Uri): List<WorkspaceEntry> {
        if (treeUri.scheme == "file") {
            return workspaceDirectory(context, treeUri).listFiles().orEmpty()
                .asSequence()
                .filter { it.isDirectory || it.name.endsWith(PROJECT_FILE_SUFFIX, ignoreCase = true) }
                .map { WorkspaceEntry(Uri.fromFile(it), it.name, it.isDirectory) }
                .toList()
        }
        val documentId = try {
            DocumentsContract.getDocumentId(treeUri)
        } catch (_: Exception) {
            try {
                DocumentsContract.getTreeDocumentId(treeUri)
            } catch (_: Exception) {
                return emptyList()
            }
        }
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, documentId)
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
        )
        return try {
            context.contentResolver.query(childrenUri, projection, null, null, null)?.use { cursor ->
                buildList {
                    while (cursor.moveToNext()) {
                        val id = cursor.getString(0) ?: continue
                        val name = cursor.getString(1) ?: "Untitled"
                        val isDirectory = cursor.getString(2) == DocumentsContract.Document.MIME_TYPE_DIR
                        if (isDirectory || name.endsWith(PROJECT_FILE_SUFFIX, ignoreCase = true)) {
                            add(
                                WorkspaceEntry(
                                    DocumentsContract.buildDocumentUriUsingTree(treeUri, id),
                                    name,
                                    isDirectory,
                                ),
                            )
                        }
                    }
                }
            } ?: emptyList()
        } catch (e: Exception) {
            Log.w("audioapp_daw", "Could not list workspace folder $treeUri", e)
            emptyList()
        }
    }

    fun createWorkspaceFolder(context: Context, parentUri: Uri, requestedName: String): Uri {
        val name = requestedName.trim()
        if (name.isBlank() || name == "." || name == ".." || name.contains('/') || name.contains('\\')) {
            throw IOException("Enter a valid folder name")
        }
        val folder = File(workspaceDirectory(context, parentUri), name)
        if (!folder.exists() && !folder.mkdir()) throw IOException("Could not create folder $name")
        if (!folder.isDirectory) throw IOException("$name already exists as a file")
        return Uri.fromFile(folder)
    }

    @Throws(IOException::class)
    fun createProjectDocument(context: Context, folderUri: Uri, requestedName: String): Uri {
        val cleanName = requestedName.trim().ifBlank { "project" }
        val fileName = if (cleanName.endsWith(PROJECT_FILE_SUFFIX, ignoreCase = true)) {
            cleanName
        } else {
            "$cleanName$PROJECT_FILE_SUFFIX"
        }
        if (folderUri.scheme == "file") {
            return Uri.fromFile(File(workspaceDirectory(context, folderUri), fileName))
        }
        val existing = listWorkspaceEntries(context, folderUri)
            .firstOrNull { !it.isDirectory && it.displayName.equals(fileName, ignoreCase = true) }
        if (existing != null) return existing.documentUri
        val parentDocumentUri = try {
            DocumentsContract.getDocumentId(folderUri)
            folderUri
        } catch (_: Exception) {
            DocumentsContract.buildDocumentUriUsingTree(
                folderUri,
                DocumentsContract.getTreeDocumentId(folderUri),
            )
        }
        return DocumentsContract.createDocument(
            context.contentResolver,
            parentDocumentUri,
            PROJECT_MIME_TYPE,
            fileName,
        ) ?: throw IOException("Could not create $fileName")
    }

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
            DocumentsContract.buildChildDocumentsUriUsingTree(
                treeUri,
                DocumentsContract.getTreeDocumentId(treeUri),
            )
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
     * Takes persistable read/write grants on [treeUri]. Required so that the
     * folder URI survives process death and reboots (without persistable
     * permission, the grant is session-scoped and `getChildDocuments`
     * would throw SecurityException after the process is killed).
     *
     * Failures are silent: a session grant is sufficient for the
     * immediate folder operation. Mirrors the pattern in
     * [persistDocumentUri].
     */
    fun takeFolderUriPermission(context: Context, treeUri: Uri) {
        try {
            context.contentResolver.takePersistableUriPermission(
                treeUri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
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

                zip.putNextEntry(ZipEntry("assets/freeze/"))
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
    fun writeArchiveBytes(context: Context, documentUri: Uri, archiveBytes: ByteArray) {
        if (documentUri.scheme == "file") {
            val target = documentUri.path?.let(::File) ?: throw IOException("Archive path is missing")
            val root = workspaceRoot(context)
            val canonical = target.canonicalFile
            if (!canonical.path.startsWith(root.path + File.separator)) {
                throw IOException("Archive is outside the AudioApp workspace")
            }
            canonical.outputStream().use { it.write(archiveBytes) }
            return
        }
        persistDocumentUri(context, documentUri, writable = true)
        context.contentResolver.openOutputStream(documentUri)?.use { stream ->
            stream.write(archiveBytes)
        } ?: throw IOException("Could not open archive for writing")
    }

    @Throws(IOException::class)
    fun readArchiveBytes(context: Context, documentUri: Uri): ByteArray {
        if (documentUri.scheme == "file") {
            val source = documentUri.path?.let(::File) ?: throw IOException("Archive path is missing")
            val root = workspaceRoot(context)
            val canonical = source.canonicalFile
            if (!canonical.path.startsWith(root.path + File.separator) || !canonical.isFile) {
                throw IOException("Project is unavailable in the AudioApp workspace")
            }
            return canonical.readBytes().also {
                if (it.isEmpty()) throw IOException("Archive is empty")
            }
        }
        persistDocumentUri(context, documentUri, writable = false)
        val bytes = context.contentResolver.openInputStream(documentUri)?.use { stream ->
            stream.readBytes()
        } ?: throw IOException("Could not open archive for reading")
        if (bytes.isEmpty()) {
            throw IOException("Archive is empty")
        }
        return bytes
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
