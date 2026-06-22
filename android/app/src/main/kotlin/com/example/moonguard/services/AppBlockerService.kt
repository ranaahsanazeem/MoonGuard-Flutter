package com.example.moonguard.services

import android.accessibilityservice.AccessibilityService
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import com.example.moonguard.Prefs

/**
 * System-wide app blocking: when a foreground app matches a package in
 * [Prefs.KEY_BLOCKED] (set from Flutter via [com.example.moonguard.MainActivity] MethodChannel
 * and synced from Supabase [blocked_apps]), the user is sent to the home screen.
 * User must enable this service in **Settings > Accessibility** for your app.
 */
class AppBlockerService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return
        if (packageName == pkg) return

        val blocked = getSharedPreferences("moon_guard", MODE_PRIVATE)
            .getStringSet(Prefs.KEY_BLOCKED, emptySet())
            ?: emptySet()
        if (blocked.isEmpty() || !blocked.contains(pkg)) {
            return
        }
        Log.d(TAG, "Block redirect: $pkg")
        performGlobalAction(GLOBAL_ACTION_HOME)
    }

    override fun onInterrupt() {}

    companion object {
        private const val TAG = "AppBlocker"
    }
}
