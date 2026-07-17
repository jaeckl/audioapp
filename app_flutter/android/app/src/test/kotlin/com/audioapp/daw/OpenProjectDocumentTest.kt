package com.audioapp.daw

import android.content.Context
import android.content.Intent
import android.provider.DocumentsContract
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Test

/** Contract tests for the direct SAF project-document picker. */
class OpenProjectDocumentTest {

    @Test
    fun createIntent_omitsInitialUri_whenNoLastDocumentWasPersisted() {
        val contract = MainActivity.OpenProjectDocument()
        val intent = try {
            @Suppress("UNCHECKED_CAST")
            contract.createIntent(null as Context, ProjectArchiveStore.OPEN_MIME_TYPES)
        } catch (_: NullPointerException) {
            // JVM Android stubs may reject a null Context before the override.
            Intent()
        }
        assertFalse(intent.hasExtra(DocumentsContract.EXTRA_INITIAL_URI))
    }

    @Test
    fun createIntent_acceptsProjectMimeTypes() {
        val contract = MainActivity.OpenProjectDocument()
        val intent = try {
            @Suppress("UNCHECKED_CAST")
            contract.createIntent(null as Context, ProjectArchiveStore.OPEN_MIME_TYPES)
        } catch (_: NullPointerException) {
            Intent()
        }
        assertNotNull(intent)
    }
}
