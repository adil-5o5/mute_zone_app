package com.example.mute_zones

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.media.AudioManager
import android.provider.Settings
import android.util.Log

class MuteZoneNotificationService : NotificationListenerService() {
    
    companion object {
        private const val TAG = "MuteZoneNotification"
        private var isServiceRunning = false
        
        fun isServiceActive(): Boolean {
            return isServiceRunning
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "NotificationListenerService created")
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "NotificationListenerService started")
        isServiceRunning = true
        return START_STICKY
    }
    
    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "NotificationListenerService connected")
        isServiceRunning = true
    }
    
    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.d(TAG, "NotificationListenerService disconnected")
        isServiceRunning = false
    }
    
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        super.onNotificationPosted(sbn)
        Log.d(TAG, "Notification posted: ${sbn.packageName}")
    }
    
    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        super.onNotificationRemoved(sbn)
        Log.d(TAG, "Notification removed: ${sbn.packageName}")
    }
    
    fun setDoNotDisturbMode(enable: Boolean) {
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (checkSelfPermission(android.Manifest.permission.ACCESS_NOTIFICATION_POLICY) == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                    val currentInterruptionFilter = notificationManager.currentInterruptionFilter
                    val targetFilter = if (enable) {
                        NotificationManager.INTERRUPTION_FILTER_NONE
                    } else {
                        NotificationManager.INTERRUPTION_FILTER_ALL
                    }
                    
                    if (currentInterruptionFilter != targetFilter) {
                        notificationManager.setInterruptionFilter(targetFilter)
                        Log.d(TAG, "Do Not Disturb ${if (enable) "enabled" else "disabled"}")
                    }
                } else {
                    Log.e(TAG, "ACCESS_NOTIFICATION_POLICY permission not granted")
                }
            } else {
                Log.e(TAG, "Do Not Disturb control not supported on this Android version")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error setting Do Not Disturb mode: ${e.message}")
        }
    }
    
    fun setRingerMode(mute: Boolean) {
        try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            
            // Check if we have WRITE_SETTINGS permission (required for OnePlus devices)
            val hasWriteSettingsPermission = Settings.System.canWrite(this)
            val hasNotificationPolicyPermission = checkSelfPermission(android.Manifest.permission.ACCESS_NOTIFICATION_POLICY) == android.content.pm.PackageManager.PERMISSION_GRANTED
            
            Log.d(TAG, "Permissions - WRITE_SETTINGS: $hasWriteSettingsPermission, ACCESS_NOTIFICATION_POLICY: $hasNotificationPolicyPermission")
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (hasNotificationPolicyPermission) {
                    val targetMode = if (mute) AudioManager.RINGER_MODE_SILENT else AudioManager.RINGER_MODE_NORMAL
                    audioManager.ringerMode = targetMode
                    Log.d(TAG, "Ringer mode set to: ${if (mute) "SILENT" else "NORMAL"} using ACCESS_NOTIFICATION_POLICY")
                } else if (hasWriteSettingsPermission) {
                    // Fallback for OnePlus devices that might need WRITE_SETTINGS
                    val targetMode = if (mute) AudioManager.RINGER_MODE_SILENT else AudioManager.RINGER_MODE_NORMAL
                    audioManager.ringerMode = targetMode
                    Log.d(TAG, "Ringer mode set to: ${if (mute) "SILENT" else "NORMAL"} using WRITE_SETTINGS")
                } else {
                    Log.e(TAG, "No permissions granted for ringer mode control")
                }
            } else {
                // For older Android versions, try with WRITE_SETTINGS
                if (hasWriteSettingsPermission) {
                    val targetMode = if (mute) AudioManager.RINGER_MODE_SILENT else AudioManager.RINGER_MODE_NORMAL
                    audioManager.ringerMode = targetMode
                    Log.d(TAG, "Ringer mode set to: ${if (mute) "SILENT" else "NORMAL"} using WRITE_SETTINGS (legacy)")
                } else {
                    Log.e(TAG, "WRITE_SETTINGS permission not granted for legacy Android")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error setting ringer mode: ${e.message}")
        }
    }
} 