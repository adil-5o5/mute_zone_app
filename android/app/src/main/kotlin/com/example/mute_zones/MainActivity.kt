// android/app/src/main/kotlin/com/example/mute_zones/MainActivity.kt
package com.example.mute_zones

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.AudioManager
import android.content.Context
import android.os.Build
import android.provider.Settings
import android.content.Intent
import android.net.Uri
import android.content.pm.PackageManager

class MainActivity: FlutterActivity() {
    private val CHANNEL = "mute_zones_location"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setRingerMode" -> {
                    val mute = call.argument<Boolean>("mute") ?: false
                    setRingerMode(mute)
                    result.success(null)
                }
                "checkNotificationPolicyPermission" -> {
                    val hasPermission = checkSelfPermission(android.Manifest.permission.ACCESS_NOTIFICATION_POLICY) == PackageManager.PERMISSION_GRANTED
                    result.success(hasPermission)
                }
                "checkWriteSettingsPermission" -> {
                    val hasPermission = Settings.System.canWrite(this)
                    result.success(hasPermission)
                }
                "openWriteSettingsPermission" -> {
                    val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
                    intent.data = Uri.parse("package:$packageName")
                    startActivity(intent)
                    result.success(null)
                }
                "openNotificationAccessSettings" -> {
                    val intent = Intent("android.settings.NOTIFICATION_LISTENER_SETTINGS")
                    startActivity(intent)
                    result.success(null)
                }
                "checkNotificationAccessPermission" -> {
                    val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
                    } else {
                        true // For older Android versions, assume permission is granted
                    }
                    result.success(hasPermission)
                }
                "checkNotificationListenerPermission" -> {
                    val hasPermission = MuteZoneNotificationService.isServiceActive()
                    result.success(hasPermission)
                }
                "openNotificationListenerSettings" -> {
                    val intent = Intent("android.settings.NOTIFICATION_LISTENER_SETTINGS")
                    startActivity(intent)
                    result.success(null)
                }
                "setDoNotDisturbMode" -> {
                    val enable = call.argument<Boolean>("enable") ?: false
                    setDoNotDisturbMode(enable)
                    result.success(null)
                }
                "getPackageName" -> {
                    result.success(packageName)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun setRingerMode(mute: Boolean) {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        
        try {
            // Check if we have WRITE_SETTINGS permission (required for OnePlus devices)
            val hasWriteSettingsPermission = Settings.System.canWrite(this)
            val hasNotificationPolicyPermission = checkSelfPermission(android.Manifest.permission.ACCESS_NOTIFICATION_POLICY) == PackageManager.PERMISSION_GRANTED
            val hasManageNotificationsPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
            } else {
                true // For older Android versions, assume permission is granted
            }
            
            println("Permissions - WRITE_SETTINGS: $hasWriteSettingsPermission, ACCESS_NOTIFICATION_POLICY: $hasNotificationPolicyPermission, MANAGE_NOTIFICATIONS: $hasManageNotificationsPermission")
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (hasNotificationPolicyPermission) {
                    val targetMode = if (mute) AudioManager.RINGER_MODE_SILENT else AudioManager.RINGER_MODE_NORMAL
                    audioManager.ringerMode = targetMode
                    println("Ringer mode set to: ${if (mute) "SILENT" else "NORMAL"} using ACCESS_NOTIFICATION_POLICY")
                } else if (hasWriteSettingsPermission) {
                    // Fallback for OnePlus devices that might need WRITE_SETTINGS
                    val targetMode = if (mute) AudioManager.RINGER_MODE_SILENT else AudioManager.RINGER_MODE_NORMAL
                    audioManager.ringerMode = targetMode
                    println("Ringer mode set to: ${if (mute) "SILENT" else "NORMAL"} using WRITE_SETTINGS")
                } else if (hasManageNotificationsPermission) {
                    // Try using Do Not Disturb mode as another fallback
                    val targetMode = if (mute) AudioManager.RINGER_MODE_SILENT else AudioManager.RINGER_MODE_NORMAL
                    audioManager.ringerMode = targetMode
                    println("Ringer mode set to: ${if (mute) "SILENT" else "NORMAL"} using MANAGE_NOTIFICATIONS")
                } else {
                    println("No permissions granted for ringer mode control")
                }
            } else {
                // For older Android versions, try with WRITE_SETTINGS
                if (hasWriteSettingsPermission) {
                    val targetMode = if (mute) AudioManager.RINGER_MODE_SILENT else AudioManager.RINGER_MODE_NORMAL
                    audioManager.ringerMode = targetMode
                    println("Ringer mode set to: ${if (mute) "SILENT" else "NORMAL"} using WRITE_SETTINGS (legacy)")
                } else {
                    println("WRITE_SETTINGS permission not granted for legacy Android")
                }
            }
        } catch (e: Exception) {
            println("Error setting ringer mode: ${e.message}")
        }
    }
    
    private fun setDoNotDisturbMode(enable: Boolean) {
        try {
            // Try to use the NotificationListenerService if available
            if (MuteZoneNotificationService.isServiceActive()) {
                // The service is active, we can control DND
                println("NotificationListenerService is active, can control Do Not Disturb")
            } else {
                println("NotificationListenerService is not active")
            }
            
            // Also try the direct method
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (checkSelfPermission(android.Manifest.permission.ACCESS_NOTIFICATION_POLICY) == PackageManager.PERMISSION_GRANTED) {
                    val currentInterruptionFilter = notificationManager.currentInterruptionFilter
                    val targetFilter = if (enable) {
                        android.app.NotificationManager.INTERRUPTION_FILTER_NONE
                    } else {
                        android.app.NotificationManager.INTERRUPTION_FILTER_ALL
                    }
                    
                    if (currentInterruptionFilter != targetFilter) {
                        notificationManager.setInterruptionFilter(targetFilter)
                        println("Do Not Disturb ${if (enable) "enabled" else "disabled"}")
                    }
                } else {
                    println("ACCESS_NOTIFICATION_POLICY permission not granted for Do Not Disturb")
                }
            } else {
                println("Do Not Disturb control not supported on this Android version")
            }
        } catch (e: Exception) {
            println("Error setting Do Not Disturb mode: ${e.message}")
        }
    }
}