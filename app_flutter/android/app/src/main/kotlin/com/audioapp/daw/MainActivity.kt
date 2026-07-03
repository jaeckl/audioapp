package com.audioapp.daw

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.DocumentsContract
import android.util.Log
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
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
    private var pendingRecordPermissionResult: MethodChannel.Result? = null
    private var pendingRecordStartResult: MethodChannel.Result? = null
    private var pendingRecordSampleId: String = ""
    private var pendingRecordClipId: String = ""
    @Volatile private var activeRecordSampleId: String = ""
    @Volatile private var activeRecordClipId: String = ""
    private val audioRecorder = AudioSampleRecorder()

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

    private val requestRecordAudio = registerForActivityResult(
        ActivityResultContracts.RequestPermission(),
    ) { granted ->
        val permissionOnlyResult = pendingRecordPermissionResult
        val result = pendingRecordStartResult
        val sampleId = pendingRecordSampleId
        val clipId = pendingRecordClipId
        pendingRecordPermissionResult = null
        pendingRecordStartResult = null
        pendingRecordSampleId = ""
        pendingRecordClipId = ""
        if (permissionOnlyResult != null) {
            if (granted) {
                permissionOnlyResult.success(mapOf("ok" to true))
            } else {
                permissionOnlyResult.error("mic_permission_denied", "Microphone permission denied", null)
            }
            return@registerForActivityResult
        }
        if (result == null) return@registerForActivityResult
        if (granted) {
            startTrackAudioRecording(result, sampleId, clipId)
        } else {
            result.error("mic_permission_denied", "Microphone permission denied", null)
        }
    }

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

    private fun requestOrStartTrackAudioRecording(args: Map<*, *>?, result: MethodChannel.Result) {
        val sampleId = args?.get("sampleId") as? String ?: ""
        val clipId = args?.get("clipId") as? String ?: ""
        if (sampleId.isBlank() || clipId.isBlank()) {
            result.error("invalid_recording_session", "Recording session ids are missing", null)
            return
        }
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED) {
            startTrackAudioRecording(result, sampleId, clipId)
            return
        }
        if (pendingRecordStartResult != null) {
            result.error("busy", "Recording permission request already active", null)
            return
        }
        pendingRecordStartResult = result
        pendingRecordSampleId = sampleId
        pendingRecordClipId = clipId
        requestRecordAudio.launch(Manifest.permission.RECORD_AUDIO)
    }

    private fun ensureRecordAudioPermission(result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED) {
            result.success(mapOf("ok" to true))
            return
        }
        if (pendingRecordPermissionResult != null || pendingRecordStartResult != null) {
            result.error("busy", "Recording permission request already active", null)
            return
        }
        pendingRecordPermissionResult = result
        requestRecordAudio.launch(Manifest.permission.RECORD_AUDIO)
    }

    private fun startTrackAudioRecording(result: MethodChannel.Result, sampleId: String, clipId: String) {
        activeRecordSampleId = sampleId
        activeRecordClipId = clipId
        audioRecorder.start { chunk ->
            val targetSampleId = activeRecordSampleId
            val targetClipId = activeRecordClipId
            if (targetSampleId.isNotBlank() && targetClipId.isNotBlank()) {
                nativeAppendAudioRecordingPcm(targetSampleId, targetClipId, chunk)
            }
        }
        result.success(mapOf("ok" to true))
    }

    private fun retargetTrackAudioRecording(args: Map<*, *>?, result: MethodChannel.Result) {
        val sampleId = args?.get("sampleId") as? String ?: ""
        val clipId = args?.get("clipId") as? String ?: ""
        if (sampleId.isBlank() || clipId.isBlank()) {
            result.error("invalid_recording_session", "Recording session ids are missing", null)
            return
        }
        activeRecordSampleId = sampleId
        activeRecordClipId = clipId
        result.success(mapOf("ok" to true))
    }

    private fun stopTrackAudioRecording(result: MethodChannel.Result) {
        val pcm = audioRecorder.stop()
        activeRecordSampleId = ""
        activeRecordClipId = ""
        result.success(
            mapOf(
                "ok" to true,
                "durationSeconds" to pcm.size.toDouble() / AudioSampleRecorder.SAMPLE_RATE.toDouble(),
            ),
        )
    }

    private fun cancelTrackAudioRecording(result: MethodChannel.Result) {
        audioRecorder.cancel()
        activeRecordSampleId = ""
        activeRecordClipId = ""
        result.success(mapOf("ok" to true))
    }

    private fun findSampleIdByName(map: Map<String, Any?>, displayName: String): String {
        val snapshot = (map["snapshot"] as? Map<*, *>)
            ?: ((map["delta"] as? Map<*, *>)?.get("fullSnapshot") as? Map<*, *>)
            ?: return ""
        val samples = snapshot["samples"] as? List<*> ?: return ""
        for (sample in samples.asReversed()) {
            val sampleMap = sample as? Map<*, *> ?: continue
            if (sampleMap["name"] == displayName) {
                return sampleMap["id"] as? String ?: ""
            }
        }
        return ""
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
            val archiveBytes = nativeBuildProjectArchiveBytes()
            ProjectArchiveStore.writeArchiveBytes(this, documentUri, archiveBytes)
            ProjectUriStore.saveLastDocumentUri(this, documentUri)
            ProjectUriStore.recordRecentProject(this, documentUri, projectDisplayName(documentUri))
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
            Log.i(logTag, "Saved project archive (${archiveBytes.size} bytes) to $documentUri")
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
        loadArchive(documentUri, result)
    }

    private fun loadArchive(documentUri: Uri, result: MethodChannel.Result) {
        try {
            val archiveBytes = ProjectArchiveStore.readArchiveBytes(this, documentUri)
            Log.i(logTag, "Loading project archive (${archiveBytes.size} bytes) from $documentUri")
            val response = nativeLoadProjectArchiveBytes(archiveBytes)
            val map = jsonToMap(response).toMutableMap()
            if (map["ok"] == true) {
                ProjectUriStore.saveLastDocumentUri(this, documentUri)
                ProjectUriStore.recordRecentProject(this, documentUri, projectDisplayName(documentUri))
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

    /// Loads a bundled example project shipped as a Flutter asset. Unlike
    /// [loadArchive], this has no document URI: it never touches SAF or the
    /// native "recent projects" store, since it isn't a user file.
    private fun loadExampleProject(projectJson: String, result: MethodChannel.Result) {
        try {
            val response = nativeLoadProjectFileJson(projectJson)
            val map = jsonToMap(response).toMutableMap()
            if (map["ok"] == true) {
                map["cancelled"] = false
                result.success(map)
            } else {
                val error = map["error"]?.toString() ?: "load_failed"
                result.error(error, "Failed to load example project", null)
            }
        } catch (e: Exception) {
            Log.e(logTag, "Load example project failed", e)
            result.error("engine_error", e.message, null)
        }
    }

    private fun projectDisplayName(documentUri: Uri): String =
        contentResolver.query(documentUri, null, null, null, null)?.use { cursor ->
            val index = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
            if (index >= 0 && cursor.moveToFirst()) cursor.getString(index) else null
        } ?: documentUri.lastPathSegment?.substringAfterLast('/') ?: "Project"

    private fun recentProjectsResult(): Map<String, Any> {
        var projects = ProjectUriStore.loadRecentProjects(this)
        if (projects.isEmpty()) {
            ProjectUriStore.loadLastDocumentUri(this)?.let { legacyUri ->
                ProjectUriStore.recordRecentProject(
                    this, legacyUri, projectDisplayName(legacyUri),
                )
                projects = ProjectUriStore.loadRecentProjects(this)
            }
        }
        return mapOf(
            "ok" to true,
            "projects" to projects.map { entry ->
            mapOf(
                "uri" to entry.uri,
                "name" to entry.name,
                "openedAtMillis" to entry.openedAtMillis,
            )
        },
        )
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
                        "getRecentProjects" -> result.success(recentProjectsResult())
                        "loadRecentProject" -> {
                            val rawUri = (call.arguments as? Map<*, *>)?.get("uri") as? String
                            if (rawUri.isNullOrBlank()) {
                                result.error("invalid_uri", "Recent project URI is missing", null)
                            } else {
                                loadArchive(Uri.parse(rawUri), result)
                            }
                        }
                        "loadExampleProject" -> {
                            val projectJson = (call.arguments as? Map<*, *>)?.get("projectJson") as? String
                            if (projectJson.isNullOrBlank()) {
                                result.error("invalid_project_json", "Example project JSON is missing", null)
                            } else {
                                loadExampleProject(projectJson, result)
                            }
                        }
                        "importSample" -> launchImportSamplePicker(result)
                        "ensureRecordAudioPermission" -> ensureRecordAudioPermission(result)
                        "startTrackAudioRecording" -> requestOrStartTrackAudioRecording(call.arguments as? Map<*, *>, result)
                        "retargetTrackAudioRecording" -> retargetTrackAudioRecording(call.arguments as? Map<*, *>, result)
                        "stopTrackAudioRecording" -> stopTrackAudioRecording(result)
                        "cancelTrackAudioRecording" -> cancelTrackAudioRecording(result)
                        "getTrackAudioRecordingLevel" -> result.success(
                            mapOf("ok" to true, "level" to audioRecorder.inputLevel()),
                        )
                        "registerDemoSample" -> {
                            val args = call.arguments as? Map<*, *>
                            val id = args?.get("id") as? String
                            val name = args?.get("name") as? String
                            val bytes = args?.get("bytes") as? ByteArray
                            if (id.isNullOrBlank() || name.isNullOrBlank() || bytes == null || bytes.isEmpty()) {
                                result.error("invalid_demo_sample", "Demo sample data is incomplete", null)
                            } else {
                                result.success(jsonToMap(nativeRegisterDemoWavSample(id, name, bytes)))
                            }
                        }
                        "exportMix" -> {
                            val lengthBeats = when (val args = call.arguments) {
                                is Map<*, *> -> (args["lengthBeats"] as? Number)?.toDouble() ?: 16.0
                                else -> 16.0
                            }
                            launchExportMixPicker(result, lengthBeats)
                        }
                        // All engine commands route through native_bridge C++ command registry.
                        // Play/stop need wakelock; file ops need SAF pickers; everything else
                        // is handled by the C++ CommandRegistry.
                        else -> {
                            val argsJson = when (val args = call.arguments) {
                                null -> "{}"
                                is Map<*, *> -> mapToJson(args).toString()
                                is String -> args
                                else -> "{}"
                            }
                            val response = nativeInvoke(call.method, argsJson)
                            result.success(jsonToMap(response))
                        }
                    }
                } catch (e: Exception) {
                    Log.e(logTag, "Engine command failed: ${call.method}", e)
                    result.error("engine_error", e.message, null)
                }
            }

        // ── Meters EventChannel ──────────────────────────────────────────
        val metersChannelName = "com.audioapp.daw/meters"
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, metersChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                private val mainHandler = Handler(Looper.getMainLooper())
                private var meterTimer: java.util.Timer? = null
                @Volatile private var listening = false

                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    meterTimer?.cancel()
                    listening = true
                    meterTimer = java.util.Timer("audioapp-meter-poll", true)
                    meterTimer!!.schedule(object : java.util.TimerTask() {
                        override fun run() {
                            try {
                                val json = nativeInvoke("getDeviceMeters", "{}")
                                val map = jsonToMap(json)
                                if (map["ok"] == true) {
                                    mainHandler.post {
                                        if (listening) {
                                            events.success(map)
                                        }
                                    }
                                }
                            } catch (e: Exception) {
                                Log.w(logTag, "Meter poll failed: ${e.message}")
                            }
                        }
                    }, 0L, 16L) // ~60 Hz UI meter refresh
                }

                override fun onCancel(arguments: Any?) {
                    listening = false
                    meterTimer?.cancel()
                    meterTimer = null
                }
            })

        loadBundledWavetables()
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
    private external fun nativeBuildProjectArchiveBytes(): ByteArray
    private external fun nativeLoadProjectArchiveBytes(archiveBytes: ByteArray): String
    private external fun nativeLoadProjectFileJson(projectJson: String): String
    private external fun nativeImportWavSample(displayName: String, wavBytes: ByteArray): String
    private external fun nativeAppendAudioRecordingPcm(sampleId: String, clipId: String, pcm: FloatArray): Boolean
    private external fun nativeRegisterDemoWavSample(sampleId: String, displayName: String, wavBytes: ByteArray): String
    private external fun nativeLoadWavetableAsset(name: String, wavBytes: ByteArray): Boolean
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

    private fun loadBundledWavetables() {
        try {
            val assetManager = resources.assets
            val prefix = "flutter_assets/assets/wavetables"
            val names = listOf("sine_64", "bass_64", "strings_64", "digital_64", "fm_bells_64")
            for (name in names) {
                val path = "$prefix/${name}.wav"
                try {
                    val bytes = assetManager.open(path)?.use { it.readBytes() }
                    if (bytes != null && bytes.isNotEmpty()) {
                        nativeLoadWavetableAsset(name, bytes)
                    }
                } catch (e: Exception) {
                    Log.w(logTag, "Failed to load wavetable $name: ${e.message}")
                }
            }
        } catch (e: Exception) {
            Log.w(logTag, "Failed to load bundled wavetables: ${e.message}")
        }
    }

    companion object {
        init {
            System.loadLibrary("audioapp_native")
        }
    }
}
