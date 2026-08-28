package com.timezonealarm.app

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
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

        // Stop ringing sound service if user enters/opens the app
        if (intent?.getBooleanExtra("isAlarmTriggered", false) == true) {
            AlarmSoundService.stopService(applicationContext)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleNativeAlarm" -> {
                    val alarmId = call.argument<String>("alarmId") ?: ""
                    val title = call.argument<String>("title") ?: "Alarm"
                    val triggerAtMillis = call.argument<Long>("triggerAtMillis") ?: 0L
                    val timeString = call.argument<String>("timeString") ?: ""
                    val timeZone = call.argument<String>("timeZone") ?: ""
                    val sound = call.argument<String>("sound") ?: "chime"
                    val volume = call.argument<Double>("volume") ?: 0.8
                    val vibrate = call.argument<Boolean>("vibrate") ?: true

                    if (triggerAtMillis > System.currentTimeMillis()) {
                        AlarmScheduler.scheduleExactAlarm(
                            context = applicationContext,
                            alarmId = alarmId,
                            title = title,
                            timeString = timeString,
                            timeZone = timeZone,
                            sound = sound,
                            volume = volume,
                            vibrate = vibrate,
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
                "stopAlarmSound" -> {
                    AlarmSoundService.stopService(applicationContext)
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
        sound: String = "chime",
        volume: Double = 0.8,
        vibrate: Boolean = true,
        triggerAtMillis: Long
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = "com.timezonealarm.app.ACTION_TRIGGER_ALARM"
            putExtra("alarmId", alarmId)
            putExtra("title", title)
            putExtra("timeString", timeString)
            putExtra("timeZone", timeZone)
            putExtra("sound", sound)
            putExtra("volume", volume)
            putExtra("vibrate", vibrate)
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
                val sound = obj.optString("sound", "chime")
                val volume = obj.optDouble("volume", 0.8)
                val vibrate = obj.optBoolean("vibrate", true)
                val nextLocalMillis = obj.optLong("nextTriggerMillis", 0L)

                if (enabled && nextLocalMillis > System.currentTimeMillis()) {
                    scheduleExactAlarm(
                        context, alarmId, title, timeString, timeZone,
                        sound, volume, vibrate, nextLocalMillis
                    )
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

/**
 * Dedicated Foreground Service for Continuous Alarm Sound & Vibration
 * Runs in background or when app process is killed.
 */
class AlarmSoundService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null

    companion object {
        const val CHANNEL_ID = "timezone_alarm_channel_high_v2"
        const val NOTIFICATION_ID = 99991

        fun startService(context: Context, intent: Intent) {
            val serviceIntent = Intent(context, AlarmSoundService::class.java).apply {
                putExtras(intent)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        }

        fun stopService(context: Context) {
            val serviceIntent = Intent(context, AlarmSoundService::class.java)
            context.stopService(serviceIntent)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
        wakeLock = powerManager?.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
            "TimezoneAlarm:SoundServiceWakeLock"
        )
        wakeLock?.acquire(60000L) // 1 minute max ringing loop

        val alarmId = intent?.getStringExtra("alarmId") ?: ""
        val title = intent?.getStringExtra("title") ?: "Alarm Ringing"
        val timeString = intent?.getStringExtra("timeString") ?: ""
        val timeZone = intent?.getStringExtra("timeZone") ?: ""
        val volume = intent?.getDoubleExtra("volume", 0.8) ?: 0.8
        val vibrate = intent?.getBooleanExtra("vibrate", true) ?: true

        createNotificationChannel()

        val fullScreenIntent = Intent(this, MainActivity::class.java).apply {
            this.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("alarmId", alarmId)
            putExtra("isAlarmTriggered", true)
        }
        val fullScreenPendingIntent = PendingIntent.getActivity(
            this,
            alarmId.hashCode(),
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val dismissIntent = Intent(this, AlarmDismissReceiver::class.java)
        val dismissPendingIntent = PendingIntent.getBroadcast(
            this,
            alarmId.hashCode() + 1,
            dismissIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("⏰ $title")
            .setContentText("Target: $timeString ($timeZone)")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .setContentIntent(fullScreenPendingIntent)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Dismiss Alarm", dismissPendingIntent)
            .build()

        startForeground(NOTIFICATION_ID, notification)

        // Play loud audible sound through the ALARM audio stream
        playAlarmSound(volume.toFloat())

        // Hardware vibration
        if (vibrate) {
            startVibration()
        }

        return START_NOT_STICKY
    }

    private fun playAlarmSound(volume: Float) {
        try {
            var alarmUri: Uri? = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            if (alarmUri == null) {
                alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            }
            if (alarmUri == null) {
                alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            }

            mediaPlayer?.release()
            mediaPlayer = MediaPlayer().apply {
                setDataSource(applicationContext, alarmUri!!)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .build()
                )
                setVolume(volume, volume)
                isLooping = true
                prepare()
                start()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun startVibration() {
        try {
            vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            if (vibrator != null && vibrator!!.hasVibrator()) {
                val pattern = longArrayOf(0, 800, 400, 800, 400, 800)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0)) // repeat index 0
                } else {
                    @Suppress("DEPRECATION")
                    vibrator?.vibrate(pattern, 0)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Timezone Alarm Ringing Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Critical alerts when alarm rings even if app is closed"
                setBypassDnd(true)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
                enableVibration(false) // handled via Vibrator directly
                setSound(null, null)   // handled via MediaPlayer directly on ALARM stream
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
            mediaPlayer = null
        } catch (e: Exception) {}

        try {
            vibrator?.cancel()
            vibrator = null
        } catch (e: Exception) {}

        try {
            if (wakeLock != null && wakeLock!!.isHeld) {
                wakeLock?.release()
                wakeLock = null
            }
        } catch (e: Exception) {}
    }
}

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        AlarmSoundService.startService(context, intent)
    }
}

class AlarmDismissReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        AlarmSoundService.stopService(context)
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
