package com.timezonealarm.app

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.os.Vibrator
import android.os.VibrationEffect
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.timezonealarm.app/native_alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleNativeAlarm" -> {
                    val alarmId = call.argument<String>("alarmId") ?: ""
                    val title = call.argument<String>("title") ?: "Alarm"
                    val triggerAtMillis = call.argument<Long>("triggerAtMillis") ?: 0L
                    val timeString = call.argument<String>("timeString") ?: ""
                    val timeZone = call.argument<String>("timeZone") ?: ""
                    
                    if (triggerAtMillis > System.currentTimeMillis()) {
                        AlarmScheduler.scheduleExactAlarm(
                            context = applicationContext,
                            alarmId = alarmId,
                            title = title,
                            timeString = timeString,
                            timeZone = timeZone,
                            triggerAtMillis = triggerAtMillis
                        )
                    }
                    result.success(true)
                }
                "cancelNativeAlarm" -> {
                    val alarmId = call.argument<String>("alarmId") ?: ""
                    AlarmScheduler.cancelAlarm(applicationContext, alarmId)
                    result.success(true)
                }
                "syncAllAlarms" -> {
                    val alarmsJson = call.argument<String>("alarmsJson") ?: "[]"
                    AlarmScheduler.syncAlarms(applicationContext, alarmsJson)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}

object AlarmScheduler {
    private const val PREFS_NAME = "tz_native_alarms_prefs"
    private const val KEY_ALARMS = "stored_native_alarms"

    fun scheduleExactAlarm(
        context: Context,
        alarmId: String,
        title: String,
        timeString: String,
        timeZone: String,
        triggerAtMillis: Long
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = "com.timezonealarm.app.ACTION_TRIGGER_ALARM"
            putExtra("alarmId", alarmId)
            putExtra("title", title)
            putExtra("timeString", timeString)
            putExtra("timeZone", timeZone)
        }

        val requestCode = alarmId.hashCode()
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent
                )
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun cancelAlarm(context: Context, alarmId: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = "com.timezonealarm.app.ACTION_TRIGGER_ALARM"
        }
        val requestCode = alarmId.hashCode()
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )
        if (pendingIntent != null) {
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }
    }

    fun syncAlarms(context: Context, alarmsJson: String) {
        // Save to persistent Android SharedPreferences for BootReceiver recovery
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_ALARMS, alarmsJson).apply()

        try {
            val array = JSONArray(alarmsJson)
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                val enabled = obj.optBoolean("enabled", false)
                val alarmId = obj.optString("id", "")
                val title = obj.optString("title", "Alarm")
                val timeString = obj.optString("sourceTime", "")
                val timeZone = obj.optString("sourceTimeZone", "")
                val nextLocalMillis = obj.optLong("nextTriggerMillis", 0L)

                if (enabled && nextLocalMillis > System.currentTimeMillis()) {
                    scheduleExactAlarm(context, alarmId, title, timeString, timeZone, nextLocalMillis)
                } else {
                    cancelAlarm(context, alarmId)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun rescheduleAllOnBoot(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val json = prefs.getString(KEY_ALARMS, null) ?: return
        syncAlarms(context, json)
    }
}

class AlarmReceiver : BroadcastReceiver() {
    companion object {
        const val CHANNEL_ID = "timezone_alarm_channel_high"
        const val CHANNEL_NAME = "Timezone Alarm Critical Alerts"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        val wakeLock = powerManager?.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
            "TimezoneAlarm:WakeLockTag"
        )
        wakeLock?.acquire(30000L) // Hold wake lock for 30s to sound alarm and show full screen

        val alarmId = intent.getStringExtra("alarmId") ?: ""
        val title = intent.getStringExtra("title") ?: "Alarm Ringing"
        val timeString = intent.getStringExtra("timeString") ?: ""
        val timeZone = intent.getStringExtra("timeZone") ?: ""

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Create high priority notification channel with alarm sound & vibration
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val alarmSound: Uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_ALARM)
                .build()

            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Urgent alarm notifications that ring when app is closed or phone is locked"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 800, 400, 800, 400, 800)
                setSound(alarmSound, audioAttributes)
                setBypassDnd(true)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            }
            notificationManager.createNotificationChannel(channel)
        }

        // Full-screen intent launching MainActivity directly when alarm triggers
        val fullScreenIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("alarmId", alarmId)
            putExtra("isAlarmTriggered", true)
        }
        val fullScreenPendingIntent = PendingIntent.getActivity(
            context,
            alarmId.hashCode(),
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val alarmSound: Uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("⏰ $title")
            .setContentText("Target: $timeString ($timeZone)")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setOngoing(true)
            .setSound(alarmSound)
            .setVibrate(longArrayOf(0, 800, 400, 800, 400, 800))
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .setContentIntent(fullScreenPendingIntent)
            .build()

        val notificationId = (System.currentTimeMillis() % 100000).toInt()
        notificationManager.notify(notificationId, notification)

        // Trigger hardware vibration immediately
        try {
            val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            if (vibrator != null && vibrator.hasVibrator()) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 800, 400, 800, 400, 800), -1))
                } else {
                    vibrator.vibrate(longArrayOf(0, 800, 400, 800, 400, 800), -1)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // Release wake lock safely after a short delay
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            try {
                if (wakeLock != null && wakeLock.isHeld) {
                    wakeLock.release()
                }
            } catch (e: Exception) {}
        }, 5000L)
    }
}

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || 
            intent.action == "android.intent.action.QUICKBOOT_POWERON" ||
            intent.action == "com.htc.intent.action.QUICKBOOT_POWERON") {
            AlarmScheduler.rescheduleAllOnBoot(context)
        }
    }
}
