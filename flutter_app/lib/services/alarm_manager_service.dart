import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../models/alarm.dart';
import 'timezone_helper.dart';

class AlarmManagerService extends ChangeNotifier {
  List<Alarm> _alarms = [];
  Alarm? _ringingAlarm;
  Timer? _ticker;
  Timer? _vibrationTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Set<String> _triggeredSet = {};

  List<Alarm> get alarms => _alarms;
  Alarm? get ringingAlarm => _ringingAlarm;

  AlarmManagerService() {
    _loadAlarms();
    _startTicker();
  }

  Future<void> _loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList('saved_alarms');
    if (stored != null) {
      _alarms = stored.map((s) => Alarm.fromJson(s)).toList();
      notifyListeners();
    } else {
      // Seed default sample alarm
      _alarms = [
        Alarm(
          id: 'default-team-sync',
          label: 'US East Standup',
          sourceTimeZone: 'America/New_York',
          sourceHour: 9,
          sourceMinute: 30,
          repeatDays: [1, 2, 3, 4, 5],
          alertMode: 'sound_and_vibrate',
        ),
      ];
      _saveAlarms();
    }
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encoded = _alarms.map((a) => a.toJson()).toList();
    await prefs.setStringList('saved_alarms', encoded);
    notifyListeners();
  }

  void addAlarm(Alarm alarm) {
    _alarms.insert(0, alarm);
    _saveAlarms();
  }

  void updateAlarm(Alarm alarm) {
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      _alarms[index] = alarm;
      _saveAlarms();
    }
  }

  void deleteAlarm(String id) {
    _alarms.removeWhere((a) => a.id == id);
    _saveAlarms();
  }

  void toggleAlarm(String id) {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      _alarms[index] = _alarms[index].copyWith(isEnabled: !_alarms[index].isEnabled);
      _saveAlarms();
    }
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkAlarms();
    });
  }

  void _checkAlarms() {
    if (_ringingAlarm != null) return;
    final now = DateTime.now();

    for (final alarm in _alarms) {
      if (!alarm.isEnabled) continue;

      DateTime nextTrigger;
      if (alarm.snoozeUntil != null) {
        nextTrigger = alarm.snoozeUntil!;
      } else {
        nextTrigger = TimeZoneHelper.calculateNextLocalOccurrence(
          sourceTimeZone: alarm.sourceTimeZone,
          sourceHour: alarm.sourceHour,
          sourceMinute: alarm.sourceMinute,
          repeatDays: alarm.repeatDays,
        );
      }

      final diff = (now.millisecondsSinceEpoch - nextTrigger.millisecondsSinceEpoch).abs();
      final triggerKey = '${alarm.id}_${now.hour}_${now.minute}';

      if (diff < 1500 && !_triggeredSet.contains(triggerKey)) {
        _triggeredSet.add(triggerKey);
        _triggerAlarm(alarm);
        break;
      }
    }
  }

  void _triggerAlarm(Alarm alarm) async {
    _ringingAlarm = alarm;
    notifyListeners();

    if (alarm.alertMode != 'vibrate_only' && alarm.sound != 'silent') {
      try {
        _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.play(AssetSource('sounds/alarm_classic.mp3'));
      } catch (_) {}
    }

    if (alarm.alertMode != 'sound_only' && alarm.vibrate) {
      _startVibrationLoop();
    }
  }

  void _startVibrationLoop() {
    _vibrationTimer?.cancel();
    Vibration.hasVibrator().then((hasVibe) {
      if (hasVibe == true) {
        Vibration.vibrate(pattern: [0, 800, 200, 800]);
        _vibrationTimer = Timer.periodic(const Duration(milliseconds: 2000), (_) {
          Vibration.vibrate(pattern: [0, 800, 200, 800]);
        });
      }
    });
  }

  void dismissAlarm() {
    _vibrationTimer?.cancel();
    Vibration.cancel();
    _audioPlayer.stop();

    if (_ringingAlarm != null && _ringingAlarm!.repeatDays.isEmpty) {
      toggleAlarm(_ringingAlarm!.id);
    }

    _ringingAlarm = null;
    notifyListeners();
  }

  void snoozeAlarm() {
    if (_ringingAlarm == null) return;
    _vibrationTimer?.cancel();
    Vibration.cancel();
    _audioPlayer.stop();

    final snoozedAlarm = _ringingAlarm!.copyWith(
      snoozeUntil: DateTime.now().add(Duration(minutes: _ringingAlarm!.snoozeMinutes)),
    );
    updateAlarm(snoozedAlarm);

    _ringingAlarm = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _vibrationTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
