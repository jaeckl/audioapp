package com.audioapp.daw

import android.content.Context
import android.net.Uri

/** Last SAF document URI (save/open project file). */
object ProjectUriStore {
    private const val PREFS_NAME = "audioapp_project_store"
    private const val KEY_LAST_DOCUMENT_URI = "last_document_uri"

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
}
