package com.drawcrypt.subguard

import android.content.Context
import android.os.Build
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Lets the app ask Android whether SubGuard is already free of battery
        // limits, so Reminder setup only asks for what is really missing.
        // Reading this needs no extra permission.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "subguard/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isIgnoringBatteryOptimizations" -> {
                        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                            result.success(true)
                        } else {
                            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                            result.success(pm.isIgnoringBatteryOptimizations(packageName))
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
