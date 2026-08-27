# Timezone Alarm App (Flutter & Native Android)

A smart world timezone alarm clock that converts source timezone times to your exact local time with automatic seasonal and daylight saving adjustments.

## Features
- **Global Multi-Zone Support**: Set alarms anchored to New York, London, Tokyo, Paris, Singapore, Sydney, and more.
- **Auto Local Translation**: Automatically converts target timezone to local trigger time with real-time countdown.
- **Full Hardware Vibration & Loop Sound**: Continuous vibration pulsing and loop alarm audio until dismissed.
- **Snooze & Repeat Rules**: Custom repeat days (Mon–Fri, Weekends, Daily) and configurable snooze timers.
- **Offline Persistence**: Local storage with `SharedPreferences` without external database dependencies.

## How to Build the APK
1. Install Flutter (3.x+) on your computer.
2. Open terminal in the `flutter_app/` directory.
3. Run:
   ```bash
   flutter pub get
   flutter build apk --release
   ```
4. Find the generated APK at:
   `build/app/outputs/flutter-apk/app-release.apk`
