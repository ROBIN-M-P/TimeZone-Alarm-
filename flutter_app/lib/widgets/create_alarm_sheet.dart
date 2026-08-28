import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm.dart';
import '../services/timezone_helper.dart';

class CreateAlarmSheet extends StatefulWidget {
  final Alarm? editingAlarm;
  final String? preselectedZone;
  final String? preselectedTime;
  final Function(Alarm alarm) onSave;
  final bool use24Hour;
  final Function(String sound, double volume)? onPreviewSound;

  const CreateAlarmSheet({
    super.key,
    this.editingAlarm,
    this.preselectedZone,
    this.preselectedTime,
    required this.onSave,
    required this.use24Hour,
    this.onPreviewSound,
  });

  @override
  State<CreateAlarmSheet> createState() => _CreateAlarmSheetState();
}

class _CreateAlarmSheetState extends State<CreateAlarmSheet> {
  late TextEditingController _titleController;
  late String _selectedZone;
  late int _selectedHour;
  late int _selectedMinute;
  late List<int> _selectedDays;
  late String _selectedSound;
  late double _volume;
  late bool _vibrate;

  String _searchFilter = '';

  final List<Map<String, String>> _soundOptions = [
    {'id': 'chime', 'name': 'Melodic Chime'},
    {'id': 'marimba', 'name': 'Marimba Rise'},
    {'id': 'digital', 'name': 'Digital Bip'},
    {'id': 'cosmic', 'name': 'Cosmic Pulse'},
    {'id': 'gentle', 'name': 'Gentle Horizon'},
  ];

  @override
  void initState() {
    super.initState();
    final edit = widget.editingAlarm;

    if (edit != null) {
      _titleController = TextEditingController(text: edit.title);
      _selectedZone = edit.sourceTimeZone;
      _selectedHour = edit.sourceHour;
      _selectedMinute = edit.sourceMinute;
      _selectedDays = List.from(edit.days);
      _selectedSound = edit.sound;
      _volume = edit.volume;
      _vibrate = edit.vibrate;
    } else {
      _titleController = TextEditingController(text: '');
      _selectedZone = widget.preselectedZone ?? 'America/Los_Angeles';

      if (widget.preselectedTime != null) {
        final parts = widget.preselectedTime!.split(':');
        _selectedHour = int.tryParse(parts[0]) ?? 6;
        _selectedMinute = int.tryParse(parts.length > 1 ? parts[1] : '30') ?? 30;
      } else {
        _selectedHour = 6;
        _selectedMinute = 30;
      }

      _selectedDays = [1, 2, 3, 4, 5]; // Mon-Fri default
      _selectedSound = 'chime';
      _volume = 0.85;
      _vibrate = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1),
              surface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedHour = picked.hour;
        _selectedMinute = picked.minute;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final time24Str = '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}';
    final conversion = TimeZoneHelper.convertSourceToLocal(
      sourceTime: time24Str,
      sourceTimeZone: _selectedZone,
      use24Hour: widget.use24Hour,
    );

    final selectedZoneInfo = TimeZoneHelper.allTimeZones.firstWhere(
      (z) => z.iana == _selectedZone,
      orElse: () => TimeZoneHelper.allTimeZones.first,
    );

    final filteredZones = TimeZoneHelper.allTimeZones.where((z) {
      if (_searchFilter.isEmpty) return true;
      final q = _searchFilter.toLowerCase();
      return z.city.toLowerCase().contains(q) ||
          z.country.toLowerCase().contains(q) ||
          z.label.toLowerCase().contains(q) ||
          z.iana.toLowerCase().contains(q);
    }).toList();

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.alarm_add, color: Color(0xFF818CF8), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.editingAlarm != null ? 'Edit Global Alarm' : 'New Global Alarm',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Alarm Title
            const Text(
              'ALARM LABEL / MEETING TITLE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 1),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. US Pacific Standup, London Market Open',
                hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF020617),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1))),
              ),
            ),
            const SizedBox(height: 16),

            // Timezone Selection
            const Text(
              '1. TARGET / REMOTE TIMEZONE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 1),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedZone,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0F172A),
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF818CF8)),
                  items: filteredZones.map((tz) {
                    return DropdownMenuItem(
                      value: tz.iana,
                      child: Text(
                        '${tz.flag} ${tz.city} (${tz.label.split('(').last}',
                        style: const TextStyle(fontSize: 13.5, color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedZone = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dual Time Preview & Picker Card
            const Text(
              '2. TIME IN REMOTE TIMEZONE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 1),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF020617),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${selectedZoneInfo.flag} In ${selectedZoneInfo.city}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              conversion.sourceFormatted,
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.schedule, color: Color(0xFF818CF8), size: 14),
                              SizedBox(width: 4),
                              Text('Change', style: TextStyle(fontSize: 12, color: Color(0xFF818CF8), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFF1E293B), height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notifications_active, color: Color(0xFF4ADE80), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Equivalent Local Alarm:',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white70),
                            ),
                          ],
                        ),
                        Text(
                          '${conversion.localFormatted} (${conversion.dayDifference})',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF4ADE80)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Repeat Days
            const Text(
              '3. REPEAT DAYS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDayChip('M', 1),
                _buildDayChip('T', 2),
                _buildDayChip('W', 3),
                _buildDayChip('T', 4),
                _buildDayChip('F', 5),
                _buildDayChip('S', 6),
                _buildDayChip('S', 7),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _selectedDays = [1, 2, 3, 4, 5]),
                  child: const Text('Weekdays (Mon-Fri)', style: TextStyle(fontSize: 11, color: Color(0xFF818CF8))),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedDays = [1, 2, 3, 4, 5, 6, 7]),
                  child: const Text('Every Day', style: TextStyle(fontSize: 11, color: Color(0xFF818CF8))),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedDays = []),
                  child: const Text('Once', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Sound Options
            const Text(
              '4. ALARM TONE & SOUND',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 1),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _soundOptions.map((opt) {
                final isSelected = _selectedSound == opt['id'];
                return InkWell(
                  onTap: () {
                    setState(() => _selectedSound = opt['id']!);
                    widget.onPreviewSound?.call(opt['id']!, _volume);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF6366F1).withOpacity(0.25) : const Color(0xFF020617),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? Icons.volume_up : Icons.music_note,
                          size: 14,
                          color: isSelected ? const Color(0xFF818CF8) : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          opt['name']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Vibration & Volume
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Vibration Alert', style: TextStyle(fontSize: 13, color: Colors.white)),
                Switch(
                  value: _vibrate,
                  activeColor: const Color(0xFF6366F1),
                  onChanged: (val) => setState(() => _vibrate = val),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Save Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final title = _titleController.text.trim().isNotEmpty
                      ? _titleController.text.trim()
                      : '${selectedZoneInfo.city} Alarm';

                  final alarm = Alarm(
                    id: widget.editingAlarm?.id ?? const Uuid().v4(),
                    title: title,
                    sourceTimeZone: _selectedZone,
                    sourceTime: time24Str,
                    days: _selectedDays,
                    enabled: true,
                    sound: _selectedSound,
                    volume: _volume,
                    vibrate: _vibrate,
                    createdAt: widget.editingAlarm?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
                  );

                  widget.onSave(alarm);
                  Navigator.pop(context);
                },
                child: Text(
                  widget.editingAlarm != null ? 'Save Alarm Changes' : 'Create Global Alarm',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayChip(String label, int dayNum) {
    final isSelected = _selectedDays.contains(dayNum);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedDays.remove(dayNum);
          } else {
            _selectedDays.add(dayNum);
          }
        });
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF020617),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF818CF8) : const Color(0xFF1E293B),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
