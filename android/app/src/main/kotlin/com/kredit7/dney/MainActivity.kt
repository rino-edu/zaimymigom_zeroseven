package com.kredit7.dney

import android.content.Context
import android.content.Intent
import android.os.Bundle
import io.appmetrica.analytics.push.AppMetricaPush
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        PendingPushOpenStorage.save(this, intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        PendingPushOpenStorage.save(this, intent)
        super.onNewIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PENDING_PUSH_OPEN_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "consumePendingPushOpen" -> result.success(PendingPushOpenStorage.consume(this))
                "clearPendingPushOpen" -> {
                    PendingPushOpenStorage.clear(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private object PendingPushOpenStorage {
        private const val PREFS = "pending_push_open"
        private const val KEY_PENDING = "pending"
        private const val KEY_PAYLOAD = "payload"

        fun save(context: Context, intent: Intent?) {
            if (intent == null || !hasPushOpenIntent(intent)) return
            val payload = intent.getStringExtra(AppMetricaPush.EXTRA_PAYLOAD).orEmpty()
            context.getSharedPreferences(PREFS, MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_PENDING, true)
                .putString(KEY_PAYLOAD, payload)
                .apply()
        }

        fun consume(context: Context): Map<String, Any>? {
            val prefs = context.getSharedPreferences(PREFS, MODE_PRIVATE)
            if (!prefs.getBoolean(KEY_PENDING, false)) return null
            val payload = prefs.getString(KEY_PAYLOAD, "").orEmpty()
            clear(context)
            return mapOf(
                "opened" to true,
                "payload" to payload,
            )
        }

        fun clear(context: Context) {
            context.getSharedPreferences(PREFS, MODE_PRIVATE)
                .edit()
                .clear()
                .apply()
        }

        private fun hasPushOpenIntent(intent: Intent): Boolean {
            if (intent.hasExtra(AppMetricaPush.EXTRA_PAYLOAD)) return true
            val action = intent.action.orEmpty()
            return action.contains("notification", ignoreCase = true) ||
                action.contains("push", ignoreCase = true)
        }
    }

    companion object {
        private const val PENDING_PUSH_OPEN_CHANNEL = "com.kredit7.dney/pending_push_open"
    }
}
