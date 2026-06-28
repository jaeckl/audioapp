package com.audioapp.daw

import android.content.Context
import android.net.Uri
import org.json.JSONArray
import org.json.JSONObject

/** Last SAF document URI (save/open project file). */
object ProjectUriStore {
    private const val PREFS_NAME = "audioapp_project_store"
    private const val KEY_LAST_DOCUMENT_URI = "last_document_uri"
    private const val KEY_LAST_FOLDER_URI = "last_folder_uri"
    private const val KEY_RECENT_PROJECTS = "recent_projects"

    data class RecentProject(
        val uri: String,
        val name: String,
        val openedAtMillis: Long,
    )

    fun saveLastDocumentUri(context: Context, documentUri: Uri) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_LAST_DOCUMENT_URI, documentUri.toString())
            .apply()
    }

    fun loadLastDocumentUri(context: Context): Uri? {
        val raw = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_LAST_DOCUMENT_URI, null)
        return raw?.let { Uri.parse(it) }
    }

    fun saveLastFolderUri(context: Context, folderUri: Uri) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_LAST_FOLDER_URI, folderUri.toString())
            .apply()
    }

    fun loadLastFolderUri(context: Context): Uri? {
        val raw = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_LAST_FOLDER_URI, null)
        return raw?.let { Uri.parse(it) }
    }

    fun recordRecentProject(context: Context, documentUri: Uri, displayName: String) {
        val updated = loadRecentProjects(context)
            .filterNot { it.uri == documentUri.toString() }
            .toMutableList()
        updated.add(0, RecentProject(documentUri.toString(), displayName, System.currentTimeMillis()))
        val array = JSONArray()
        updated.take(8).forEach { entry ->
            array.put(JSONObject().apply {
                put("uri", entry.uri)
                put("name", entry.name)
                put("openedAtMillis", entry.openedAtMillis)
            })
        }
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit().putString(KEY_RECENT_PROJECTS, array.toString()).apply()
    }

    fun loadRecentProjects(context: Context): List<RecentProject> {
        val raw = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_RECENT_PROJECTS, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            buildList {
                for (index in 0 until array.length()) {
                    val item = array.getJSONObject(index)
                    add(RecentProject(
                        item.getString("uri"),
                        item.optString("name", "Project"),
                        item.optLong("openedAtMillis", 0L),
                    ))
                }
            }
        } catch (_: Exception) {
            emptyList()
        }
    }
}
