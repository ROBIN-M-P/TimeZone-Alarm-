import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alarm.dart';
import '../services/timezone_helper.dart';

class AlarmCard extends StatelessWidget {
  final Alarm alarm;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final nextOccurrence = TimeZoneHelper.calculateNextLocalOccurrence(
      sourceTimeZone: alarm.sourceTimeZone,
      sourceHour: alarm.sourceHour,
      sourceMinute: alarm.sourceMinute,
      repeatDays: alarm.repeatDays,
    );

    final localFormatted = DateFormat('hh:mm a').format(nextOccurrence);
    final relativeTime = TimeZoneHelper.formatDurationUntil(nextOccurrence);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: alarm.isEnabled ? const Color(0xFF6366F1).withOpacity(0.4) : Colors.white10,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        localFormatted,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: alarm.isEnabled ? Colors.white : Colors.white38,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($relativeTime)',
                        style: TextStyle(fontSize: 12, color: alarm.isEnabled ? const Color(0xFF818CF8) : Colors.white24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${alarm.label} • Source: ${alarm.sourceHour.toString().padLeft(2, '0')}:${alarm.sourceMinute.toString().padLeft(2, '0')} (${alarm.sourceTimeZone.split('/').last})',
                    style: TextStyle(fontSize: 13, color: alarm.isEnabled ? Colors.white70 : Colors.white24),
                  ),
                ],
              ),
            ),
            Switch(
              value: alarm.isEnabled,
              activeColor: const Color(0xFF6366F1),
              onChanged: (_) => onToggle(),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
