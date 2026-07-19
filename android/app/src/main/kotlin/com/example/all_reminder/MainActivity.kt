package com.example.all_reminder

import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val CHANNEL = "in.inhomex.all_reminder/settings"
    private val RINGTONE_PICKER_REQUEST_CODE = 999
    private var pendingResult: MethodChannel.Result? = null
    private var pendingChannelId: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        cleanOrphanedChannels()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openRingtonePicker" -> {
                    val channelId = call.argument<String>("channelId")
                    pendingResult = result
                    openRingtonePicker(channelId)
                }
                "openNotificationSettings" -> {
                    val channelId = call.argument<String>("channelId")
                    openNotificationSettings(channelId)
                    result.success(true)
                }
                "openBatteryOptimizationSettings" -> {
                    openBatteryOptimizationSettings()
                    result.success(true)
                }
                "isMiui" -> {
                    result.success(isMiuiDevice())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun openRingtonePicker(channelId: String?) {
        pendingChannelId = channelId
        try {
            val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER)
            intent.putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_NOTIFICATION or RingtoneManager.TYPE_ALARM)
            intent.putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Select Notification Sound")
            intent.putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
            intent.putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, true)

            val savedUri = getSavedChannelSoundUri(channelId)
            if (!savedUri.isNullOrEmpty()) {
                intent.putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, Uri.parse(savedUri))
            }

            startActivityForResult(intent, RINGTONE_PICKER_REQUEST_CODE)
        } catch (e: Exception) {
            openNotificationSettings(channelId)
            pendingResult?.success(false)
            pendingResult = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == RINGTONE_PICKER_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                val uri: Uri? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI, Uri::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
                }

                val channelId = pendingChannelId
                if (!channelId.isNullOrEmpty() && uri != null) {
                    updateChannelSound(channelId, uri)
                    pendingResult?.success(true)
                } else {
                    pendingResult?.success(false)
                }
            } else {
                pendingResult?.success(false)
            }
            pendingResult = null
        }
    }

    private fun updateChannelSound(baseChannelId: String, uri: Uri) {
        try {
            contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        } catch (e: Exception) {
            // Ignore if URI does not support persistable permissions
        }

        val soundHash = Math.abs(uri.toString().hashCode())
        val dynamicChannelId = "${baseChannelId}_snd_$soundHash"

        saveChannelSoundUri(baseChannelId, uri.toString())
        saveDynamicChannelId(baseChannelId, dynamicChannelId)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            if (notificationManager != null) {
                val channelName = getChannelName(baseChannelId)
                val channelDesc = getChannelDesc(baseChannelId)

                try {
                    val existingChannels = notificationManager.notificationChannels
                    for (ch in existingChannels) {
                        if (ch.id == baseChannelId || ch.id.startsWith("${baseChannelId}_")) {
                            notificationManager.deleteNotificationChannel(ch.id)
                        }
                    }
                } catch (e: Exception) {
                    // Ignore
                }

                val audioAttributes = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                    .setFlags(AudioAttributes.FLAG_AUDIBILITY_ENFORCED)
                    .build()

                val newChannel = NotificationChannel(dynamicChannelId, channelName, NotificationManager.IMPORTANCE_HIGH).apply {
                    description = channelDesc
                    setSound(uri, audioAttributes)
                    enableVibration(true)
                    enableLights(true)
                }

                notificationManager.createNotificationChannel(newChannel)
            }
        }
    }

    private fun saveDynamicChannelId(channelId: String?, dynamicChannelId: String) {
        if (channelId.isNullOrEmpty()) return
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit().putString("flutter.sound_channel_id_$channelId", dynamicChannelId).apply()
    }

    private fun saveChannelSoundUri(channelId: String?, uriString: String) {
        if (channelId.isNullOrEmpty()) return
        val prefs = getSharedPreferences("app_settings", Context.MODE_PRIVATE)
        prefs.edit().putString("sound_uri_$channelId", uriString).apply()

        val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        flutterPrefs.edit().putString("flutter.sound_uri_$channelId", uriString).apply()
    }

    private fun getSavedChannelSoundUri(channelId: String?): String? {
        if (channelId.isNullOrEmpty()) return null
        val prefs = getSharedPreferences("app_settings", Context.MODE_PRIVATE)
        return prefs.getString("sound_uri_$channelId", null)
    }

    private fun getChannelName(channelId: String): String {
        return when {
            channelId.startsWith("channel_workout") -> "Workout Reminders"
            channelId.startsWith("channel_meal") -> "Meal Reminders"
            channelId.startsWith("channel_medicine") -> "Medicine Reminders"
            channelId.startsWith("channel_study") -> "Study Reminders"
            channelId.startsWith("channel_sleep") -> "Sleeping Reminders"
            channelId.startsWith("channel_prayer") -> "Prayer Reminders"
            else -> "Reminders"
        }
    }

    private fun getChannelDesc(channelId: String): String {
        return when {
            channelId.startsWith("channel_workout") -> "Notifications for workout & exercise schedules"
            channelId.startsWith("channel_meal") -> "Notifications for meal & diet schedules"
            channelId.startsWith("channel_medicine") -> "Notifications for pill & medicine schedules"
            channelId.startsWith("channel_study") -> "Notifications for study & exam schedules"
            channelId.startsWith("channel_sleep") -> "Notifications for bedtime & sleep cycle schedules"
            channelId.startsWith("channel_prayer") -> "Notifications for daily prayer times & Azan"
            else -> "App notifications"
        }
    }

    private fun cleanOrphanedChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                if (notificationManager != null) {
                    val existingChannels = notificationManager.notificationChannels
                    val mainChannelIds = setOf(
                        "channel_workout",
                        "channel_meal",
                        "channel_medicine",
                        "channel_study",
                        "channel_sleep",
                        "channel_prayer"
                    )
                    for (ch in existingChannels) {
                        if (ch.id.contains("_v") || (ch.id.startsWith("channel_") && !mainChannelIds.contains(ch.id) && !ch.id.startsWith("prayer_"))) {
                            notificationManager.deleteNotificationChannel(ch.id)
                        }
                    }
                }
            } catch (e: Exception) {
                // Ignore
            }
        }
    }

    private fun isMiuiDevice(): Boolean {
        val manufacturer = Build.MANUFACTURER.lowercase(Locale.ROOT)
        val brand = Build.BRAND.lowercase(Locale.ROOT)
        
        if (manufacturer.contains("xiaomi") || brand.contains("xiaomi") || 
            brand.contains("redmi") || brand.contains("poco") ||
            manufacturer.contains("redmi") || manufacturer.contains("poco")) {
            return true
        }

        try {
            val systemProperties = Class.forName("android.os.SystemProperties")
            val getMethod = systemProperties.getMethod("get", String::class.java)
            val miuiVersion = getMethod.invoke(null, "ro.miui.ui.version.name") as String?
            if (!miuiVersion.isNullOrEmpty()) {
                return true
            }
        } catch (e: Exception) {
            // Ignore
        }
        return false
    }

    private fun openBatteryOptimizationSettings() {
        if (isMiuiDevice()) {
            openMiuiBatterySettings()
        } else {
            openStandardBatterySettings()
        }
    }

    private fun openMiuiBatterySettings() {
        try {
            val intent = Intent()
            intent.component = ComponentName("com.miui.powerkeeper", "com.miui.powerkeeper.ui.HiddenAppsConfigActivity")
            intent.putExtra("package_name", packageName)
            intent.putExtra("package_label", applicationInfo.loadLabel(packageManager))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            return
        } catch (e: Exception) {
            // Ignore
        }

        try {
            val intent = Intent("miui.intent.action.HIDDEN_APPS_CONFIG_ACTIVITY")
            intent.putExtra("package_name", packageName)
            intent.putExtra("package_label", applicationInfo.loadLabel(packageManager))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            return
        } catch (e: Exception) {
            // Ignore
        }

        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            intent.data = Uri.parse("package:$packageName")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (e: Exception) {
            openStandardBatterySettings()
        }
    }

    private fun openStandardBatterySettings() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val intent = Intent()
                intent.action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                intent.data = Uri.parse("package:$packageName")
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            } else {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                intent.data = Uri.parse("package:$packageName")
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            }
        } catch (e: Exception) {
            try {
                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            } catch (ex: Exception) {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                intent.data = Uri.parse("package:$packageName")
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            }
        }
    }

    private fun openNotificationSettings(channelId: String? = null) {
        try {
            val intent = Intent()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !channelId.isNullOrEmpty()) {
                intent.action = Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS
                intent.putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                intent.putExtra(Settings.EXTRA_CHANNEL_ID, channelId)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                intent.action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
                intent.putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            } else {
                intent.action = "android.settings.APP_NOTIFICATION_SETTINGS"
                intent.putExtra("app_package", packageName)
                intent.putExtra("app_uid", applicationInfo.uid)
            }
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (e: Exception) {
            try {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                intent.data = Uri.parse("package:$packageName")
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            } catch (ex: Exception) {
                // Ignore
            }
        }
    }
}
