package com.example.mute_zones

import android.app.*
import android.content.Intent
import android.location.Location
import android.os.IBinder
import android.media.AudioManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel

class LocationService : Service() {
    private lateinit var audioManager: AudioManager
    private val CHANNEL_ID = "mute_zones_location"
    private val NOTIFICATION_ID = 1

    override fun onCreate() {
        super.onCreate()
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, createNotification())
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Mute Zones Location Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Background location tracking for mute zones"
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Mute Zones Active")
            .setContentText("Monitoring your location for mute zones")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    fun checkMuteZone(currentLocation: Location, muteZones: List<MuteZone>) {
        for (zone in muteZones) {
            val zoneLocation = Location("zone").apply {
                latitude = zone.latitude
                longitude = zone.longitude
            }
            
            val distance = currentLocation.distanceTo(zoneLocation)
            
            if (distance <= 50) { // 50 meters radius
                setRingerMode(AudioManager.RINGER_MODE_SILENT)
                return
            }
        }
        // If not in any mute zone, restore normal mode
        setRingerMode(AudioManager.RINGER_MODE_NORMAL)
    }

    private fun setRingerMode(mode: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (checkSelfPermission(android.Manifest.permission.ACCESS_NOTIFICATION_POLICY) == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                audioManager.ringerMode = mode
            }
        } else {
            audioManager.ringerMode = mode
        }
    }

    data class MuteZone(
        val latitude: Double,
        val longitude: Double,
        val name: String
    )
} 