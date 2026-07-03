package com.audioapp.daw

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import kotlin.concurrent.thread

class AudioSampleRecorder {
    companion object {
        const val SAMPLE_RATE = 48000
        private const val MAX_SECONDS = 120
    }

    private val running = AtomicBoolean(false)
    private var recorder: AudioRecord? = null
    private var worker: Thread? = null
    private val samples = ArrayList<Float>(SAMPLE_RATE * 4)
    private val peakMilli = AtomicInteger(0)

    @Synchronized
    fun start(onChunk: (FloatArray) -> Unit) {
        if (running.get()) return
        samples.clear()
        peakMilli.set(0)
        val minBuffer = AudioRecord.getMinBufferSize(
            SAMPLE_RATE,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        val bufferSize = maxOf(minBuffer, 4096)
        val next = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            SAMPLE_RATE,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            bufferSize,
        )
        next.startRecording()
        recorder = next
        running.set(true)
        worker = thread(name = "audioapp-sample-recorder", isDaemon = true) {
            val buffer = ShortArray(bufferSize / 2)
            val maxFrames = SAMPLE_RATE * MAX_SECONDS
            while (running.get() && samples.size < maxFrames) {
                val read = next.read(buffer, 0, buffer.size)
                if (read > 0) {
                    val remaining = maxFrames - samples.size
                    val count = minOf(read, remaining)
                    val chunk = FloatArray(count)
                    var peak = peakMilli.get() / 1000f * 0.85f
                    for (i in 0 until count) {
                        val sample = (buffer[i] / 32768f).coerceIn(-1f, 1f)
                        samples.add(sample)
                        chunk[i] = sample
                        peak = maxOf(peak, kotlin.math.abs(sample))
                    }
                    peakMilli.set((peak * 1000f).toInt().coerceIn(0, 1000))
                    if (chunk.isNotEmpty()) {
                        onChunk(chunk)
                    }
                }
            }
            running.set(false)
        }
    }

    @Synchronized
    fun stop(): FloatArray {
        running.set(false)
        try {
            recorder?.stop()
        } catch (_: Exception) {
        }
        recorder?.release()
        recorder = null
        worker?.join(500)
        worker = null
        return samples.toFloatArray()
    }

    fun inputLevel(): Float = peakMilli.get() / 1000f

    @Synchronized
    fun cancel() {
        stop()
        samples.clear()
    }
}
