import 'dart:convert';

class Alarm {
  final String id;
  final String label;
  final String sourceTimeZone;
  final int sourceHour;
  final int sourceMinute;
  final bool isEnabled;
  final List<int> repeatDays; // 0 = Sun, 1 = Mon ... 6 = Sat
  final String sound; // 'classic', 'gentle', 'radar', 'digital', 'silent'
  final bool vibrate;
  final String alertMode; // 'sound_and_vibrate', 'sound_only', 'vibrate_only'
  final int snoozeMinutes;
  final String? originalAlarmId;
  final DateTime? snoozeUntil;

  Alarm({
    required this.id,
    required this.label,
    required this.sourceTimeZone,
    required this.sourceHour,
    required this.sourceMinute,
    this.isEnabled = true,
    this.repeatDays = const [],
    this.sound = 'classic',
    this.vibrate = true,
    this.alertMode = 'sound_and_vibrate',
    this.snoozeMinutes = 5,
    this.originalAlarmId,
    this.snoozeUntil,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'sourceTimeZone': sourceTimeZone,
      'sourceHour': sourceHour,
      'sourceMinute': sourceMinute,
      'isEnabled': isEnabled,
      'repeatDays': repeatDays,
      'sound': sound,
      'vibrate': vibrate,
      'alertMode': alertMode,
      'snoozeMinutes': snoozeMinutes,
      'originalAlarmId': originalAlarmId,
      'snoozeUntil': snoozeUntil?.toIso8601String(),
    };
  }

  factory Alarm.fromMap(Map<String, dynamic> map) {
    return Alarm(
      id: map['id'] ?? '',
      label: map['label'] ?? 'Alarm',
      sourceTimeZone: map['sourceTimeZone'] ?? 'America/New_York',
      sourceHour: map['sourceHour'] ?? 9,
      sourceMinute: map['sourceMinute'] ?? 0,
      isEnabled: map['isEnabled'] ?? true,
      repeatDays: List<int>.from(map['repeatDays'] ?? []),
      sound: map['sound'] ?? 'classic',
      vibrate: map['vibrate'] ?? true,
      alertMode: map['alertMode'] ?? 'sound_and_vibrate',
      snoozeMinutes: map['snoozeMinutes'] ?? 5,
      originalAlarmId: map['originalAlarmId'],
      snoozeUntil: map['snoozeUntil'] != null ? DateTime.tryParse(map['snoozeUntil']) : null,
    );
  }

  String toJson() => json.encode(toMap());
  factory Alarm.fromJson(String source) => Alarm.fromMap(json.decode(source));

  Alarm copyWith({
    String? id,
    String? label,
    String? sourceTimeZone,
    int? sourceHour,
    int? sourceMinute,
    bool? isEnabled,
    List<int>? repeatDays,
    String? sound,
    bool? vibrate,
    String? alertMode,
    int? snoozeMinutes,
    String? originalAlarmId,
    DateTime? snoozeUntil,
  }) {
    return Alarm(
      id: id ?? this.id,
      label: label ?? this.label,
      sourceTimeZone: sourceTimeZone ?? this.sourceTimeZone,
      sourceHour: sourceHour ?? this.sourceHour,
      sourceMinute: sourceMinute ?? this.sourceMinute,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDays: repeatDays ?? this.repeatDays,
      sound: sound ?? this.sound,
      vibrate: vibrate ?? this.vibrate,
      alertMode: alertMode ?? this.alertMode,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      originalAlarmId: originalAlarmId ?? this.originalAlarmId,
      snoozeUntil: snoozeUntil ?? this.snoozeUntil,
    );
  }
}
