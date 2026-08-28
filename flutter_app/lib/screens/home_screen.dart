import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/alarm_manager_service.dart';
import '../widgets/alarm_card.dart';
import '../widgets/create_alarm_sheet.dart';
import '../widgets/offline_status_banner.dart';

class HomeScreen extends StatelessWidget {
  final AlarmManagerService alarmService;

  const HomeScreen({super.key, required this.alarmService});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.alarm, color: Color(0xFF818CF8)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Timezone Alarm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  'Local: ${DateFormat('hh:mm a').format(now)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const OfflineStatusBanner(),
          Expanded(
            child: alarmService.alarms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.public, size: 64, color: Colors.indigo.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        const Text('No Global Alarms Set', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        const Text('Set an alarm in New York, London, or Tokyo', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: alarmService.alarms.length,
                    itemBuilder: (context, index) {
                      final alarm = alarmService.alarms[index];
                      return AlarmCard(
                        alarm: alarm,
                        onToggle: () => alarmService.toggleAlarm(alarm.id),
                        onDelete: () => alarmService.deleteAlarm(alarm.id),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6366F1),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: const Color(0xFF0F172A),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (ctx) => CreateAlarmSheet(onSave: alarmService.addAlarm),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Alarm'),
      ),
    );
  }
}
