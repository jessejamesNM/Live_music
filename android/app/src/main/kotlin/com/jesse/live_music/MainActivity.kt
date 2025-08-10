package com.jesse.live_music

import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    private val CHANNEL = "app.channel/deeplink"
    private val EVENT_CHANNEL = "app.channel/deeplink/events"
    private var initialLink: String? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        Log.d("DeepLink", "Configuring Flutter Engine")

        // Configurar MethodChannel para el enlace inicial
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialLink" -> {
                    Log.d("DeepLink", "getInitialLink method called. Returning: $initialLink")
                    result.success(initialLink)
                    initialLink = null // Limpiar después de usar
                }
                else -> result.notImplemented()
            }
        }

        // Configurar EventChannel para enlaces posteriores
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    Log.d("DeepLink", "EventChannel: Listener added")
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    Log.d("DeepLink", "EventChannel: Listener removed")
                    eventSink = null
                }
            }
        )

        // Manejar intent inicial
        Log.d("DeepLink", "Handling initial intent: ${intent?.data}")
        handleIntent(intent, true)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d("DeepLink", "New Intent received: ${intent.data}")
        handleIntent(intent, false)
    }

    private fun handleIntent(intent: Intent?, isInitial: Boolean) {
        if (intent == null) {
            Log.d("DeepLink", "handleIntent: intent is null")
            return
        }

        val uri = intent.data
        if (uri != null) {
            val link = uri.toString()
            Log.d("DeepLink", "handleIntent: Received link: $link (isInitial: $isInitial)")
            if (isInitial) {
                initialLink = link
            } else {
                Log.d("DeepLink", "handleIntent: Sending link to EventChannel: $link")
                eventSink?.success(link)
            }
        } else {
            Log.d("DeepLink", "handleIntent: No data found in intent")
        }
    }
}
