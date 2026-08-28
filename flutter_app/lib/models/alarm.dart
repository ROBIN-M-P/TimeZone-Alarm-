import 'dart:convert';

class Alarm {
  final String id;
  final String title;
  final String sourceTimeZone;
  final String sourceTime; // "HH:mm" (24-hour format)
  final List<int> days; // 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun (or 0=Sun..6=Sat)
  final bool enabled;
  final String sound; // 'chime', 'marimba', 'digital', 'cosmic', 'gentle'
  final double volume;
  final bool vibrate;
  final int createdAt;
  final DateTime? snoozeUntil;

  Alarm({
    required this.id,
    required this.title,
    required this.sourceTimeZone,
    required this.sourceTime,
    required this.days,
    this.enabled = true,
    this.sound = 'chime',
    this.volume = 0.85,
    this.vibrate = true,
    required this.createdAt,
    this.snoozeUntil,
  });

  int get sourceHour {
    final parts = sourceTime.split(':');
    return int.tryParse(parts[0]) ?? 0;
  }

  int get sourceMinute {
    final parts = sourceTime.split(':');
    if (parts.length > 1) {
      return int.tryParse(parts[1]) ?? 0;
    }
    return 0;
  }

  Alarm copyWith({
    String? id,
    String? title,
    String? sourceTimeZone,
    String? sourceTime,
    List<int>? days,
    bool? enabled,
    String? sound,
    double? volume,
    bool? vibrate,
    int? createdAt,
    DateTime? snoozeUntil,
    bool clearSnooze = false,
  }) {
    return Alarm(
      id: id ?? this.id,
      title: title ?? this.title,
      sourceTimeZone: sourceTimeZone ?? this.sourceTimeZone,
      sourceTime: sourceTime ?? this.sourceTime,
      days: days ?? this.days,
      enabled: enabled ?? this.enabled,
      sound: sound ?? this.sound,
      volume: volume ?? this.volume,
      vibrate: vibrate ?? this.vibrate,
      createdAt: createdAt ?? this.createdAt,
      snoozeUntil: clearSnooze ? null : (snoozeUntil ?? this.snoozeUntil),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'sourceTimeZone': sourceTimeZone,
      'sourceTime': sourceTime,
      'days': days,
      'enabled': enabled,
      'sound': sound,
      'volume': volume,
      'vibrate': vibrate,
      'createdAt': createdAt,
      'snoozeUntil': snoozeUntil?.toIso8601String(),
    };
  }

  factory Alarm.fromMap(Map<String, dynamic> map) {
    return Alarm(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Alarm',
      sourceTimeZone: map['sourceTimeZone'] ?? 'America/Los_Angeles',
      sourceTime: map['sourceTime'] ?? '09:00',
      days: List<int>.from(map['days'] ?? [1, 2, 3, 4, 5]),
      enabled: map['enabled'] ?? true,
      sound: map['sound'] ?? 'chime',
      volume: (map['volume'] as num?)?.toDouble() ?? 0.85,
      vibrate: map['vibrate'] ?? true,
      createdAt: map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      snoozeUntil: map['snoozeUntil'] != null ? DateTime.tryParse(map['snoozeUntil']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Alarm.fromJson(String source) => Alarm.fromMap(json.decode(source));
}
