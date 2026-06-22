package com.example.moonguard.services

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.example.moonguard.MainActivity
import com.example.moonguard.R

/**
 * Continuous fused location in a **foreground** notification.
 * For Supabase upload, add WorkManager, HTTP from Kotlin, or call Flutter via
 * a background isolate; this class logs fixes for the demo.
 */
class LocationForegroundService : Service() {
    private val fused by lazy { LocationServices.getFusedLocationProviderClient(this) }
    private var callback: LocationCallback? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Moon Guard location",
                    NotificationManager.IMPORTANCE_LOW
                )
            )
        }
        startForeground(
            NOTIF_ID,
            buildNotification("Tracking location in background (demo)…")
        )
        startGps()
        return START_STICKY
    }

    private fun startGps() {
        val req = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 10_000L)
            .setMinUpdateIntervalMillis(5_000L)
            .build()
        val cb = object : LocationCallback() {
            override fun onLocationResult(r: LocationResult) {
                val l = r.lastLocation ?: return
                Log.d(TAG, "location ${l.latitude},${l.longitude} acc=${l.accuracy}")
            }
        }
        callback = cb
        try {
            fused.requestLocationUpdates(req, cb, Looper.getMainLooper())
        } catch (e: SecurityException) {
            Log.e(TAG, "Location permission: $e")
        }
    }

    private fun buildNotification(text: String): Notification {
        val open = Intent(this, MainActivity::class.java)
        val pi = PendingIntent.getActivity(
            this,
            0,
            open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Moon Guard")
            .setContentText(text)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pi)
            .setOngoing(true)
            .build()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        callback?.let { fused.removeLocationUpdates(it) }
        super.onDestroy()
    }

    companion object {
        private const val TAG = "MoonGuardLoc"
        private const val CHANNEL_ID = "moon_guard_location"
        private const val NOTIF_ID = 2001
    }
}
