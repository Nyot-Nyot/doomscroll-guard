package com.example.doomscrolling_guard

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			CHANNEL
		).setMethodCallHandler { call, result ->
			when (call.method) {
				"startService" -> result.success(false)
				"stopService" -> result.success(false)
				"getMonitoringState" -> result.success(mapOf("isRunning" to false))
				"getUsageStats" -> result.success(emptyList<Any>())
				else -> result.notImplemented()
			}
		}
	}

	private companion object {
		const val CHANNEL = "doomscroll_guard/channel"
	}
}
