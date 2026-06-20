package com.audioapp.daw

import android.content.Context
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Bundle
import android.os.PowerManager
import android.provider.DocumentsContract
import android.util.Log
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.view.WindowCompat
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "com.audioapp.daw/engine"
    private val logTag = "audioapp_daw"

    private var pendingSaveResult: MethodChannel.Result? = null
    private var pendingLoadResult: MethodChannel.Result? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var pendingImportResult: MethodChannel.Result? = null
    private var pendingExportResult: MethodChannel.Result? = null

    private val createWavExport = registerForActivityResult(
        ActivityResultContracts.CreateDocument(WavEncoder.MIME_TYPE),
    ) { documentUri -> onExportWavPicked(documentUri) }

    private val createProjectArchive = registerForActivityResult(
        ActivityResultContracts.CreateDocument(ProjectArchiveStore.ARCHIVE_MIME_TYPE),
    ) { documentUri -> onSaveArchivePicked(documentUri) }

    private val openProjectFolder = registerForActivityResult(
        OpenProjectFolder(),
    ) { folderUri -> onFolderPicked(folderUri) }

    private val openAudioSample = registerForActivityResult(
        ActivityResultContracts.OpenDocument(),
    ) { documentUri -> onImportSamplePicked(documentUri) }

    private fun launchSaveArchivePicker(result: MethodChannel.Result) {
        if (pendingSaveResult != null || pendingLoadResult != null || pendingImportResult != null || pendingExportResult != null) {
            result.error("busy", "File picker already open", null)
            return
        }
        pendingSaveResult = result
        createProjectArchive.launch(ProjectArchiveStore.DEFAULT_ARCHIVE_NAME)
    }

    private fun launchLoadArchivePicker(result: MethodChannel.Result) {
        if (pendingSaveResult != null || pendingLoadResult != null || pendingImportResult != null) {
            result.error("busy", "File picker already open", null)
            return
        }
        pendingLoadResult = result
        openProjectFolder.launch(ProjectUriStore.loadLastFolderUri(this))
    }

    private fun launchImportSamplePicker(result: MethodChannel.Result) {
        if (pendingSaveResult != null || pendingLoadResult != null || pendingImportResult != null || pendingExportResult != null) {
            result.error("busy", "File picker already open", null)
            return
        }
        pendingImportResult = result
        openAudioSample.launch(arrayOf("audio/*"))
    }

    private fun onImportSamplePicked(documentUri: Uri?) {
        val result = pendingImportResult
        pendingImportResult = null
        if (result == null) {
            return
        }
        if (documentUri == null) {
            result.success(mapOf("ok" to false, "cancelled" to true))
            return
        }
        try {
            val displayName = contentResolver.query(documentUri, null, null, null, null)?.use { cursor ->
                val nameIndex = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                if (nameIndex >= 0 && cursor.moveToFirst()) cursor.getString(nameIndex) else null
            } ?: "Imported sample"
            val bytes = contentResolver.openInputStream(documentUri)?.use { input ->
                input.readBytes()
            } ?: ByteArray(0)
            if (bytes.isEmpty()) {
                result.error("import_failed", "Empty audio file", null)
                return
            }
            val response = nativeImportWavSample(displayName, bytes)
            val map = jsonToMap(response).toMutableMap()
            if (map["ok"] == true) {
                map["cancelled"] = false
                result.success(map)
            } else {
                val error = map["error"]?.toString() ?: "import_failed"
                result.error(error, "Failed to import sample", null)
            }
        } catch (e: IOException) {
            Log.e(logTag, "Import sample failed", e)
            result.error("import_failed", e.message, null)
        } catch (e: Exception) {
            Log.e(logTag, "Import sample failed", e)
            result.error("engine_error", e.message, null)
        }
    }

    private fun onSaveArchivePicked(documentUri: Uri?) {
        val result = pendingSaveResult
        pendingSaveResult = null
        if (result == null) {
            return
        }
        if (documentUri == null) {
            Log.d(logTag, "Save archive picker cancelled")
            result.success(mapOf("ok" to false, "cancelled" to true))
            return
        }
        try {
            val projectJson = nativeGetProjectFileJson()
            ProjectArchiveStore.writeProjectArchive(this, documentUri, projectJson)
            ProjectUriStore.saveLastDocumentUri(this, documentUri)
            // Trigger MediaScanner so the file gets a proper application/zip MIME
            // in MediaStore. Without this, the SAF picker on Android 11+
            // (MediaProvider storage backbone) shows an empty list because the
            // file was written via SAF ContentResolver and never indexed, so
            // its MediaStore row has mime_type=NULL and the MIME-filtered
            // picker hides it. Pre-existing saves (before this fix) have
            // mime_type=NULL and need a one-time manual rescan, e.g.:
            //   adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE \
            //       -d file:///sdcard/Projects/nice.audioapp.zip
            val scanPath = queryDisplayPathFromUri(this, documentUri)
            if (scanPath != null) {
                MediaScannerConnection.scanFile(
                    this,
                    arrayOf(scanPath),
                    arrayOf(ProjectArchiveStore.ARCHIVE_MIME_TYPE),
                    null,
                )
            }
            Log.i(logTag, "Saved project archive (${projectJson.length} bytes json) to $documentUri")
            result.success(
                mapOf(
                    "ok" to true,
                    "uri" to documentUri.toString(),
                    "cancelled" to false,
                ),
            )
        } catch (e: IOException) {
            Log.e(logTag, "Save project archive failed", e)
            result.error("save_failed", e.message, null)
        } catch (e: Exception) {
            Log.e(logTag, "Save project failed", e)
            result.error("engine_error", e.message, null)
        }
    }

    private fun onLoadArchivePicked(documentUri: Uri?) {
        val result = pendingLoadResult
        pendingLoadResult = null
        if (result == null) {
            return
        }
        if (documentUri == null) {
            Log.d(logTag, "Open archive picker cancelled")
            result.success(mapOf("ok" to false, "cancelled" to true))
            return
        }
        try {
            val projectJson = ProjectArchiveStore.readProjectArchive(this, documentUri)
            Log.i(logTag, "Loading project archive (${projectJson.length} bytes json) from $documentUri")
            val response = nativeLoadProjectFileJson(projectJson)
            val map = jsonToMap(response).toMutableMap()
            if (map["ok"] == true) {
                ProjectUriStore.saveLastDocumentUri(this, documentUri)
                map["uri"] = documentUri.toString()
                map["cancelled"] = false
                result.success(map)
            } else {
                val error = map["error"]?.toString() ?: "load_failed"
                result.error(error, "Failed to load project", null)
            }
        } catch (e: IOException) {
            Log.e(logTag, "Load project archive failed", e)
            result.error("load_failed", e.message, null)
        } catch (e: Exception) {
            Log.e(logTag, "Load project failed", e)
            result.error("engine_error", e.message, null)
        }
    }

    private fun launchExportMixPicker(result: MethodChannel.Result, lengthBeats: Double) {
        if (pendingSaveResult != null || pendingLoadResult != null || pendingImportResult != null || pendingExportResult != null) {
            result.error("busy", "File picker already open", null)
            return
        }
        pendingExportLengthBeats = lengthBeats
        pendingExportResult = result
        createWavExport.launch(WavEncoder.DEFAULT_NAME)
    }

    private var pendingExportLengthBeats: Double = 16.0

    private fun onExportWavPicked(documentUri: Uri?) {
        val result = pendingExportResult
        pendingExportResult = null
        if (result == null) {
            return
        }
        if (documentUri == null) {
            result.success(mapOf("ok" to false, "cancelled" to true))
            return
        }
        try {
            val pcm = nativeRenderOffline(pendingExportLengthBeats)
            if (pcm.isEmpty()) {
                result.error("export_failed", "Render produced no audio", null)
                return
            }
            contentResolver.openOutputStream(documentUri)?.use { output ->
                WavEncoder.writeMonoFloat32Wav(output, pcm)
            } ?: run {
                result.error("export_failed", "Could not open output stream", null)
                return
            }
            result.success(mapOf("ok" to true, "uri" to documentUri.toString(), "cancelled" to false))
        } catch (e: Exception) {
            Log.e(logTag, "Export WAV failed", e)
            result.error("export_failed", e.message, null)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "ping" -> result.success("pong")
                        "play" -> {
                            acquirePlaybackWakeLock()
                            nativePlay()
                            result.success(null)
                        }
                        "stop" -> {
                            releasePlaybackWakeLock()
                            nativeStop()
                            result.success(null)
                        }
                        "saveProject" -> launchSaveArchivePicker(result)
                        "loadProject" -> launchLoadArchivePicker(result)
                        "importSample" -> launchImportSamplePicker(result)
                        "exportMix" -> {
                            val lengthBeats = when (val args = call.arguments) {
                                is Map<*, *> -> (args["lengthBeats"] as? Number)?.toDouble() ?: 16.0
                                else -> 16.0
                            }
                            launchExportMixPicker(result, lengthBeats)
                        }
                        "createProject",
                        "getProjectSnapshot",
                        "getTransportState",
                        "addTrack",
                        "selectTrack",
                        "addDeviceToTrack",
                        "removeDeviceFromTrack",
                        "setDeviceParameter",
                        "setDeviceStringParameter",
                        "setMasterGain",
                        "setPlayheadBeats",
                        "createMidiClip",
                        "setMidiClipNotes",
                        "createAutomationClip",
                        "assignAutomationTarget",
                        "setAutomationPoints",
                        "createSampleClip",
                        "moveClip",
                        "setClipLength",
                        "setBpm",
                        "deleteTrack",
                        "deleteClip",
                        "duplicateClip",
                        "setLoopEnabled",
                        "setLoopLengthBeats",
                        "setLoopRegion",
                        "setRecordArmed",
                        "noteOn",
                        "noteOff",
                        "allNotesOff",
                        "clearCapture",
                        "commitCapture",
                        "enterPlayMode",
                        "setPitchBend",
                        "setModulation",
                        "previewSample",
                        "createLfo",
                        "removeLfo",
                        "updateLfoParam",
                        "assignModulation",
                        "removeModulation",
                        "applySubtractiveSynthPreset" -> {
                            val argsJson = when (val args = call.arguments) {
                                null -> "{}"
                                is Map<*, *> -> mapToJson(args).toString()
                                is String -> args
                                else -> "{}"
                            }
                            val response = nativeInvoke(call.method, argsJson)
                            result.success(jsonToMap(response))
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    Log.e(logTag, "Engine command failed: ${call.method}", e)
                    result.error("engine_error", e.message, null)
                }
            }
    }

    private fun mapToJson(map: Map<*, *>): JSONObject {
        val json = JSONObject()
        for ((key, value) in map) {
            json.put(key.toString(), mapValueToJson(value))
        }
        return json
    }

    private fun mapValueToJson(value: Any?): Any = when (value) {
        null -> JSONObject.NULL
        is Boolean -> value
        is Int -> value
        is Long -> value
        is Double -> value
        is Float -> value.toDouble()
        is String -> value
        is Map<*, *> -> mapToJson(value)
        is List<*> -> {
            val array = JSONArray()
            for (item in value) {
                array.put(mapValueToJson(item))
            }
            array
        }
        else -> value.toString()
    }

    private fun jsonToMap(json: String): Map<String, Any?> {
        val root = JSONObject(json)
        val map = mutableMapOf<String, Any?>()
        val keys = root.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            map[key] = jsonValue(root.opt(key))
        }
        return map
    }

    private fun jsonValue(value: Any?): Any? {
        if (value == null || value === JSONObject.NULL) {
            return null
        }
        return when (value) {
            is JSONObject -> {
                val nested = mutableMapOf<String, Any?>()
                val keys = value.keys()
                while (keys.hasNext()) {
                    val key = keys.next()
                    nested[key] = jsonValue(value.opt(key))
                }
                nested
            }
            is JSONArray -> {
                List(value.length()) { index -> jsonValue(value.opt(index)) }
            }
            is Boolean -> value
            is Int -> value
            is Long -> value
            is Double -> value
            is String -> value
            else -> value.toString()
        }
    }

    private external fun nativeInvoke(method: String, argsJson: String): String
    private external fun nativeGetProjectFileJson(): String
    private external fun nativeLoadProjectFileJson(projectJson: String): String
    private external fun nativeImportWavSample(displayName: String, wavBytes: ByteArray): String
    private external fun nativeRenderOffline(lengthBeats: Double): FloatArray
    private external fun nativePlay()
    private external fun nativeStop()

    private fun acquirePlaybackWakeLock() {
        try {
            if (wakeLock == null || wakeLock?.isHeld == false) {
                val pm = getSystemService(POWER_SERVICE) as PowerManager
                wakeLock = pm.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK,
                    "audioapp:audio_playback"
                )
                wakeLock?.acquire()
                Log.i(logTag, "Acquired PARTIAL_WAKE_LOCK")
            }
        } catch (e: Exception) {
            Log.w(logTag, "Failed to acquire wake lock: ${e.message}")
        }
    }

    private fun releasePlaybackWakeLock() {
        try {
            wakeLock?.let {
                if (it.isHeld) {
                    it.release()
                    Log.i(logTag, "Released wake lock")
                }
            }
            wakeLock = null
        } catch (e: Exception) {
            Log.w(logTag, "Failed to release wake lock: ${e.message}")
        }
    }

    /**
     * Resolves a SAF document [uri] to a filesystem-style path that
     * [MediaScannerConnection.scanFile] can use.
     *
     * Strategy (API 29+): prefer
     * [android.provider.DocumentsContract.findDocumentPath], which
     * returns the full user-visible path
     * (`/storage/emulated/0/Projects/project.audioapp.zip` etc.) as
     * a list of segments joined with `/`.
     *
     * Fallback: query `_display_name` (the bare filename) from
     * [android.provider.DocumentsContract.Document.COLUMN_DISPLAY_NAME].
     * MediaScanner will scan by name on most devices.
     *
     * Returns null if the URI cannot be resolved (ephemeral grant,
     * provider doesn't expose the path, or the query throws).
     * Callers must handle null gracefully.
     */
    private fun queryDisplayPathFromUri(context: Context, uri: Uri): String? {
        return try {
            val resolver = context.contentResolver
            val docPath = DocumentsContract.findDocumentPath(resolver, uri)
            if (docPath != null) {
                val path = docPath.path.joinToString(separator = "/")
                if (path.isNotEmpty()) return path
            }
            resolver.query(
                uri,
                arrayOf(android.provider.DocumentsContract.Document.COLUMN_DISPLAY_NAME),
                null, null, null,
            )?.use { cursor ->
                if (cursor.moveToFirst()) cursor.getString(0) else null
            }
        } catch (e: Exception) {
            Log.w(logTag, "Could not resolve display path for $uri: ${e.message}")
            null
        }
    }

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

    private fun showLoadFolderDialog(entries: List<ProjectArchiveStore.LoadFolderEntry>) {
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

    companion object {
        init {
            System.loadLibrary("audioapp_native")
        }
    }
}
