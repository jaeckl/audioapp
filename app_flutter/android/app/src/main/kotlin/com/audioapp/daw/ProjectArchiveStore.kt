package com.audioapp.daw

import android.content.Context
import android.content.Intent
import android.net.Uri
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

    val openArchiveMimeFilter: Array<String> = arrayOf(
        ARCHIVE_MIME_TYPE,
        "application/octet-stream",
    )

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
        context.contentResolver.openOutputStream(documentUri, "wt")?.use { stream ->
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
