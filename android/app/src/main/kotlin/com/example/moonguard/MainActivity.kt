package com.example.moonguard

import android.content.Intent
import android.util.Log
import com.example.moonguard.services.LocationForegroundService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "com.example.moonguard/natives"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setBlockedPackages" -> {
                    @Suppress("UNCHECKED_CAST")
                    val list = (call.arguments as? List<*>)
                        ?.mapNotNull { it as? String }
                        ?: emptyList()
                    Prefs.setBlockedPackages(this, list)
                    result.success(null)
                }
                "setForegroundLocation" -> {
                    val arg = call.arguments as? Map<*, *>
                    val enabled = (arg?.get("enabled") as? Boolean) ?: false
                    val i = Intent(this, LocationForegroundService::class.java)
                    if (enabled) {
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                            startForegroundService(i)
                        } else {
                            startService(i)
                        }
                    } else {
                        stopService(i)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}

object Prefs {
    private const val NAME = "moon_guard"
    const val KEY_BLOCKED = "blocked_packages"

    fun setBlockedPackages(ctx: android.content.Context, packages: List<String>) {
        val s = ctx.getSharedPreferences(NAME, android.content.Context.MODE_PRIVATE).edit()
        s.putStringSet(KEY_BLOCKED, packages.toSet())
        s.apply()
        Log.d("MoonGuard", "Blocked list updated: $packages")
    }
}
