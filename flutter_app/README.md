# Timezone Alarm App (Standalone Native Flutter APK)

A 100% offline, zero-network-dependent World Timezone Alarm Clock built in Flutter. Converts source timezone meeting times (e.g., 9:30 AM New York, 2:00 PM London, 6:00 PM Tokyo) into exact local alarms with automatic Daylight Saving Time (DST) handling.

---

## 🚀 How to Build & Download the Android APK

### Step 1: Export/Download Code
Click the **Export to GitHub** or **Export as ZIP** button in the top menu of Google AI Studio.

### Step 2: Build the Release APK in One Command
Open your terminal inside the `flutter_app/` folder and run:
```bash
# 1. Fetch Flutter packages
flutter pub get

# 2. Compile standalone release APK
flutter build apk --release
```

### Step 3: Locate Your APK
Your standalone APK file is generated at:
```
flutter_app/build/app/outputs/flutter-apk/app-release.apk
```
Transfer this file to any Android device to install and use immediately.

### Mobile-Friendly Option: Build APK on GitHub
If you cannot run Flutter locally (for example, when using mobile), use the included GitHub Actions workflow:

1. Open the repository on GitHub.
2. Go to **Actions** → **Build Android APK**.
3. Tap **Run workflow**.
4. After it completes, open the run and download the **app-release-apk** artifact.

---

## 📦 What is Bundled Inside (Zero Post-Install Downloads Needed)

The app is **100% self-contained at compile time**. It **never** downloads additional assets or database files after installation:

1. **Complete IANA Timezone Database (`timezone: ^0.9.4`)**:
   - Pre-compiled historical and future timezone shift tables, leap seconds, and DST definitions are bundled directly into the binary (`timezone/data/latest.dart`).
2. **Native System Alarms (`android_alarm_manager_plus: ^3.0.4`)**:
   - Registers directly with Android OS kernel `AlarmManager` (`SCHEDULE_EXACT_ALARM`, `WAKE_LOCK`).
   - Wakes up the CPU even from deep Doze mode, locked screens, or when the app is completely terminated (killed state).
3. **High-Priority Notification Channel (`flutter_local_notifications: ^17.2.2`)**:
   - Full-screen lockscreen alert and ongoing alarm notification.
4. **Offline Hardware Haptics & Audio (`vibration`, `audioplayers`)**:
   - Direct hardware vibrator pulsing and standalone looped alarm tones.
5. **Local Flash Persistence (`shared_preferences: ^2.2.2`)**:
   - Stores all alarms securely on the device filesystem with zero cloud database dependency.
