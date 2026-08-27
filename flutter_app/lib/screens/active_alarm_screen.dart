import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alarm.dart';

class ActiveAlarmScreen extends StatelessWidget {
  final Alarm alarm;
  final VoidCallback onDismiss;
  final VoidCallback onSnooze;

  const ActiveAlarmScreen({
    super.key,
    required this.alarm,
    required this.onDismiss,
    required this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Material(
      color: Colors.black.withOpacity(0.95),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.indigo.withOpacity(0.2),
                  border: Border.all(color: Colors.indigoAccent, width: 2),
                ),
                child: const Icon(Icons.alarm_on, size: 72, color: Colors.indigoAccent),
              ),
              const SizedBox(height: 32),
              Text(
                alarm.label,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('hh:mm:ss a').format(now),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.indigoAccent),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Source: ${alarm.sourceHour.toString().padLeft(2, '0')}:${alarm.sourceMinute.toString().padLeft(2, '0')} (${alarm.sourceTimeZone.split('/').last})',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              const SizedBox(height: 48),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: const BorderSide(color: Colors.white30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: onSnooze,
                      icon: const Icon(Icons.snooze, color: Colors.white),
                      label: Text('Snooze (${alarm.snoozeMinutes}m)', style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: onDismiss,
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Dismiss', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
