import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alarm.dart';
import '../services/timezone_helper.dart';

class ActiveAlarmScreen extends StatefulWidget {
  final Alarm alarm;
  final VoidCallback onDismiss;
  final Function(int minutes) onSnooze;

  const ActiveAlarmScreen({
    super.key,
    required this.alarm,
    required this.onDismiss,
    required this.onSnooze,
  });

  @override
  State<ActiveAlarmScreen> createState() => _ActiveAlarmScreenState();
}

class _ActiveAlarmScreenState extends State<ActiveAlarmScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final localTimeStr = DateFormat('h:mm:ss a').format(now);

    final zoneInfo = TimeZoneHelper.allTimeZones.firstWhere(
      (z) => z.iana == widget.alarm.sourceTimeZone,
      orElse: () => TimeZoneInfo(
        iana: widget.alarm.sourceTimeZone,
        label: widget.alarm.sourceTimeZone,
        city: widget.alarm.sourceTimeZone.split('/').last,
        country: '',
        flag: '🌐',
        region: '',
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_active, color: Color(0xFFEF4444), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'ALARM RINGING',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEF4444), letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),

              // Animated Pulsing Bell Icon
              Column(
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.15),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF6366F1).withOpacity(0.2),
                            border: Border.all(
                              color: const Color(0xFF818CF8).withOpacity(0.5 + (_pulseController.value * 0.5)),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.4),
                                blurRadius: 30 * _pulseController.value,
                                spreadRadius: 10 * _pulseController.value,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.alarm,
                            size: 64,
                            color: Color(0xFF818CF8),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Title & Time info
                  Text(
                    widget.alarm.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Target: ${widget.alarm.sourceTime} in ${zoneInfo.flag} ${zoneInfo.city}',
                    style: const TextStyle(fontSize: 15, color: Color(0xFF38BDF8), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localTimeStr,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),

              // Snooze & Dismiss Controls
              Column(
                children: [
                  const Text('Snooze options:', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSnoozeButton(5),
                      const SizedBox(width: 12),
                      _buildSnoozeButton(10),
                      const SizedBox(width: 12),
                      _buildSnoozeButton(15),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Dismiss Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      onPressed: widget.onDismiss,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close, size: 24),
                          SizedBox(width: 8),
                          Text('DISMISS ALARM', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ],
                      ),
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

  Widget _buildSnoozeButton(int mins) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFF1E293B)),
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      onPressed: () => widget.onSnooze(mins),
      child: Text('+${mins}m', style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
