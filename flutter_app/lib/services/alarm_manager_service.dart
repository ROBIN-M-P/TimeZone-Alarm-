import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../models/alarm.dart';
import 'timezone_helper.dart';

class AlarmManagerService extends ChangeNotifier {
  static const MethodChannel _nativeChannel = MethodChannel('com.timezonealarm.app/native_alarm');

  List<Alarm> _alarms = [];
  Alarm? _ringingAlarm;
  Timer? _ticker;
  Timer? _vibrationTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Set<String> _triggeredMinuteKeys = {};
  bool _use24Hour = false;
  String _searchQuery = '';
  String _filterTab = 'all'; // 'all', 'active', 'inactive'

  List<Alarm> get alarms => _alarms;
  Alarm? get ringingAlarm => _ringingAlarm;
  bool get use24Hour => _use24Hour;
  String get searchQuery => _searchQuery;
  String get filterTab => _filterTab;

  List<Alarm> get filteredAlarms {
    return _alarms.where((alarm) {
      if (_filterTab == 'active' && !alarm.enabled) return false;
      if (_filterTab == 'inactive' && alarm.enabled) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = alarm.title.toLowerCase().contains(query);
        final matchTz = alarm.sourceTimeZone.toLowerCase().contains(query);
        if (!matchTitle && !matchTz) return false;
      }
      return true;
    }).toList();
  }

  AlarmManagerService() {
    TimeZoneHelper.initialize();
    _loadData();
    _startTicker();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _use24Hour = prefs.getBool('tz_use_24h') ?? false;

    final List<String>? stored = prefs.getStringList('tz_saved_alarms_v2');
    if (stored != null && stored.isNotEmpty) {
      _alarms = stored.map((s) => Alarm.fromJson(s)).toList();
    } else {
      // Seed preset alarms matching the web app
      _alarms = [
        Alarm(
          id: 'alarm-sample-pst',
          title: 'US Pacific Sync (e.g. 6:30 AM PST/PDT)',
          sourceTimeZone: 'America/Los_Angeles',
          sourceTime: '06:30',
          days: [1, 2, 3, 4, 5], // Mon-Fri
          enabled: true,
          sound: 'chime',
          volume: 0.85,
          vibrate: true,
          createdAt: DateTime.now().millisecondsSinceEpoch - 3600000,
        ),
        Alarm(
          id: 'alarm-sample-london',
          title: 'London Market Opening',
          sourceTimeZone: 'Europe/London',
          sourceTime: '08:00',
          days: [1, 2, 3, 4, 5],
          enabled: true,
          sound: 'marimba',
          volume: 0.80,
          vibrate: true,
          createdAt: DateTime.now().millisecondsSinceEpoch - 7200000,
        ),
        Alarm(
          id: 'alarm-sample-tokyo',
          title: 'Tokyo Morning Standup',
          sourceTimeZone: 'Asia/Tokyo',
          sourceTime: '09:30',
          days: [1, 2, 3, 4, 5],
          enabled: false,
          sound: 'digital',
          volume: 0.75,
          vibrate: true,
          createdAt: DateTime.now().millisecondsSinceEpoch - 10800000,
        ),
      ];
      _saveAlarms();
    }
    _syncNativeAlarms();
    notifyListeners();
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encoded = _alarms.map((a) => a.toJson()).toList();
    await prefs.setStringList('tz_saved_alarms_v2', encoded);
    _syncNativeAlarms();
    notifyListeners();
  }

  /// Synchronize all alarms with Android system AlarmManager so alarms ring even when app is killed
  void _syncNativeAlarms() {
    try {
      final List<Map<String, dynamic>> payload = _alarms.map((alarm) {
        DateTime nextTrigger;
        if (alarm.snoozeUntil != null) {
          nextTrigger = alarm.snoozeUntil!;
        } else {
          nextTrigger = TimeZoneHelper.calculateNextLocalOccurrence(
            sourceTimeZone: alarm.sourceTimeZone,
            sourceHour: alarm.sourceHour,
            sourceMinute: alarm.sourceMinute,
            repeatDays: alarm.days,
          );
        }

        return {
          'id': alarm.id,
          'title': alarm.title,
          'sourceTimeZone': alarm.sourceTimeZone,
          'sourceTime': alarm.sourceTime,
          'enabled': alarm.enabled,
          'nextTriggerMillis': nextTrigger.millisecondsSinceEpoch,
        };
      }).toList();

      _nativeChannel.invokeMethod('syncAllAlarms', {
        'alarmsJson': jsonEncode(payload),
      });
    } catch (_) {}
  }

  void toggleTimeFormat() async {
    _use24Hour = !_use24Hour;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tz_use_24h', _use24Hour);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterTab(String tab) {
    _filterTab = tab;
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
      final current = _alarms[index];
      _alarms[index] = current.copyWith(
        enabled: !current.enabled,
        clearSnooze: true,
      );
      _saveAlarms();
    }
  }

  void duplicateAlarm(String id) {
    final original = _alarms.firstWhere((a) => a.id == id, orElse: () => _alarms.first);
    final copy = original.copyWith(
      id: 'alarm-${DateTime.now().millisecondsSinceEpoch}',
      title: '${original.title} (Copy)',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    addAlarm(copy);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkAlarms();
      notifyListeners(); // Keep relative countdowns fresh
    });
  }

  void _checkAlarms() {
    if (_ringingAlarm != null) return;
    final now = DateTime.now();

    for (final alarm in _alarms) {
      if (!alarm.enabled) continue;

      DateTime nextTrigger;
      if (alarm.snoozeUntil != null) {
        nextTrigger = alarm.snoozeUntil!;
      } else {
        nextTrigger = TimeZoneHelper.calculateNextLocalOccurrence(
          sourceTimeZone: alarm.sourceTimeZone,
          sourceHour: alarm.sourceHour,
          sourceMinute: alarm.sourceMinute,
          repeatDays: alarm.days,
        );
      }

      final diff = nextTrigger.difference(now);
      final triggerKey = '${alarm.id}_${nextTrigger.year}-${nextTrigger.month}-${nextTrigger.day}_${nextTrigger.hour}:${nextTrigger.minute}';

      if (diff.inSeconds.abs() <= 2 && !_triggeredMinuteKeys.contains(triggerKey)) {
        _triggeredMinuteKeys.add(triggerKey);
        _triggerAlarm(alarm);
        break;
      }
    }
  }

  void _triggerAlarm(Alarm alarm) {
    _ringingAlarm = alarm;
    notifyListeners();

    _startAlarmAudioAndVibration(alarm);
  }

  Future<void> _startAlarmAudioAndVibration(Alarm alarm) async {
    // Sound playback
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(alarm.volume);
      // Play system or tone stream
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
    } catch (_) {
      // Fallback
    }

    // Vibration loop
    if (alarm.vibrate) {
      try {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          _vibrationTimer?.cancel();
          _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
            Vibration.vibrate(duration: 800);
          });
          Vibration.vibrate(duration: 800);
        }
      } catch (_) {}
    }
  }

  void previewSound(String soundName, double volume) async {
    try {
      final player = AudioPlayer();
      await player.setVolume(volume);
      await player.play(AssetSource('sounds/alarm.mp3'));
      Timer(const Duration(seconds: 3), () => player.stop());
    } catch (_) {}
  }

  void snoozeAlarm(int minutes) {
    if (_ringingAlarm == null) return;
    _stopAudioAndVibration();

    final alarmId = _ringingAlarm!.id;
    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));

    final index = _alarms.indexWhere((a) => a.id == alarmId);
    if (index != -1) {
      _alarms[index] = _alarms[index].copyWith(snoozeUntil: snoozeTime);
      _saveAlarms();
    }

    _ringingAlarm = null;
    notifyListeners();
  }

  void dismissAlarm() {
    if (_ringingAlarm == null) return;
    _stopAudioAndVibration();

    final alarmId = _ringingAlarm!.id;
    final index = _alarms.indexWhere((a) => a.id == alarmId);
    if (index != -1) {
      // If one-off alarm (no repeat days), disable it
      if (_alarms[index].days.isEmpty) {
        _alarms[index] = _alarms[index].copyWith(enabled: false, clearSnooze: true);
      } else {
        _alarms[index] = _alarms[index].copyWith(clearSnooze: true);
      }
      _saveAlarms();
    }

    _ringingAlarm = null;
    notifyListeners();
  }

  void _stopAudioAndVibration() {
    try {
      _audioPlayer.stop();
    } catch (_) {}
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    try {
      Vibration.cancel();
    } catch (_) {}
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopAudioAndVibration();
    _audioPlayer.dispose();
    super.dispose();
  }
}
