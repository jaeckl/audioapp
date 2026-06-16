package com.audioapp.daw

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.audioapp.daw/engine"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "ping" -> result.success("pong")
                    "play" -> {
                        // Milestone 01: wire to JUCE audio engine
                        result.success(null)
                    }
                    "stop" -> {
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
