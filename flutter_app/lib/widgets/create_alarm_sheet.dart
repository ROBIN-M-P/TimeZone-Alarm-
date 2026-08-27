import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm.dart';
import '../services/timezone_helper.dart';

class CreateAlarmSheet extends StatefulWidget {
  final Function(Alarm) onSave;

  const CreateAlarmSheet({super.key, required this.onSave});

  @override
  State<CreateAlarmSheet> createState() => _CreateAlarmSheetState();
}

class _CreateAlarmSheetState extends State<CreateAlarmSheet> {
  final TextEditingController _labelController = TextEditingController(text: 'Team Standup');
  TimeOfDay _sourceTime = const TimeOfDay(hour: 9, minute: 30);
  String _selectedZone = 'America/New_York';
  final List<int> _repeatDays = [1, 2, 3, 4, 5];
  final String _alertMode = 'sound_and_vibrate';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Timezone Alarm', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _labelController,
            decoration: InputDecoration(
              labelText: 'Alarm Label',
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedZone,
            decoration: InputDecoration(
              labelText: 'Source Timezone',
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: TimeZoneHelper.majorTimeZones.map((tz) {
              return DropdownMenuItem(
                value: tz.id,
                child: Text('${tz.city} (${tz.label.split('(').last.replaceAll(')', '')})'),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedZone = val!),
          ),
          const SizedBox(height: 16),
          ListTile(
            tileColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Source Time'),
            trailing: Text(
              _sourceTime.format(context),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF818CF8)),
            ),
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: _sourceTime);
              if (picked != null) setState(() => _sourceTime = picked);
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final newAlarm = Alarm(
                  id: const Uuid().v4(),
                  label: _labelController.text.trim().isEmpty ? 'Alarm' : _labelController.text.trim(),
                  sourceTimeZone: _selectedZone,
                  sourceHour: _sourceTime.hour,
                  sourceMinute: _sourceTime.minute,
                  repeatDays: _repeatDays,
                  alertMode: _alertMode,
                );
                widget.onSave(newAlarm);
                Navigator.pop(context);
              },
              child: const Text('Save Alarm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
