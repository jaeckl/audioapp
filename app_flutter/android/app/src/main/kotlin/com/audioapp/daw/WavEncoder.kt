package com.audioapp.daw

import java.io.OutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder

object WavEncoder {
    const val MIME_TYPE = "audio/wav"
    const val DEFAULT_NAME = "mix.wav"
    private const val SAMPLE_RATE = 48000

    fun writeMonoFloat32Wav(output: OutputStream, samples: FloatArray, sampleRate: Int = SAMPLE_RATE) {
        val dataSize = samples.size * 2
        val byteRate = sampleRate * 2
        val header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN)
        header.put("RIFF".toByteArray())
        header.putInt(36 + dataSize)
        header.put("WAVE".toByteArray())
        header.put("fmt ".toByteArray())
        header.putInt(16)
        header.putShort(1) // PCM
        header.putShort(1) // mono
        header.putInt(sampleRate)
        header.putInt(byteRate)
        header.putShort(2) // block align
        header.putShort(16) // bits
        header.put("data".toByteArray())
        header.putInt(dataSize)
        output.write(header.array())

        val pcm = ByteBuffer.allocate(samples.size * 2).order(ByteOrder.LITTLE_ENDIAN)
        for (sample in samples) {
            val clamped = sample.coerceIn(-1f, 1f)
            pcm.putShort((clamped * 32767f).toInt().toShort())
        }
        output.write(pcm.array())
    }
}
