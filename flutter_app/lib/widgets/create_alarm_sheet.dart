import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  bool _setByLocalTime = false; // Toggle to set via user's local time

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
        // Initialize with real-time current clock in the chosen timezone
        final nowInTz = TimeZoneHelper.getNowInZone(_selectedZone);
        _selectedHour = nowInTz['hour'] ?? DateTime.now().hour;
        _selectedMinute = nowInTz['minute'] ?? DateTime.now().minute;
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

  void _adjustTime({int deltaMinutes = 0, int deltaHours = 0}) {
    setState(() {
      int totalMinutes = (_selectedHour * 60 + _selectedMinute) + (deltaHours * 60) + deltaMinutes;
      // Handle wrap-around across 24 hours (1440 minutes)
      totalMinutes = (totalMinutes % 1440 + 1440) % 1440;
      _selectedHour = totalMinutes ~/ 60;
      _selectedMinute = totalMinutes % 60;
    });
  }

  void _setCurrentTime() {
    if (_setByLocalTime) {
      final now = DateTime.now();
      final converted = TimeZoneHelper.convertLocalToSource(
        localHour: now.hour,
        localMinute: now.minute,
        sourceTimeZone: _selectedZone,
      );
      setState(() {
        _selectedHour = converted['hour'] ?? now.hour;
        _selectedMinute = converted['minute'] ?? now.minute;
      });
    } else {
      final nowInTz = TimeZoneHelper.getNowInZone(_selectedZone);
      setState(() {
        _selectedHour = nowInTz['hour'] ?? DateTime.now().hour;
        _selectedMinute = nowInTz['minute'] ?? DateTime.now().minute;
      });
    }
  }

  void _pickTime() async {
    final initialHour = _setByLocalTime
        ? _getLocalHourMinute()['hour']!
        : _selectedHour;
    final initialMin = _setByLocalTime
        ? _getLocalHourMinute()['minute']!
        : _selectedMinute;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMin),
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
      if (_setByLocalTime) {
        final converted = TimeZoneHelper.convertLocalToSource(
          localHour: picked.hour,
          localMinute: picked.minute,
          sourceTimeZone: _selectedZone,
        );
        setState(() {
          _selectedHour = converted['hour'] ?? picked.hour;
          _selectedMinute = converted['minute'] ?? picked.minute;
        });
      } else {
        setState(() {
          _selectedHour = picked.hour;
          _selectedMinute = picked.minute;
        });
      }
    }
  }

  Map<String, int> _getLocalHourMinute() {
    final time24Str = '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}';
    final conv = TimeZoneHelper.convertSourceToLocal(
      sourceTime: time24Str,
      sourceTimeZone: _selectedZone,
      use24Hour: true,
    );
    final parts = conv.localFormatted.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return {'hour': h, 'minute': m};
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

    final filteredZones = TimeZoneHelper.allTimeZones;

    final nextOccurrence = TimeZoneHelper.calculateNextLocalOccurrence(
      sourceTimeZone: _selectedZone,
      sourceHour: _selectedHour,
      sourceMinute: _selectedMinute,
      repeatDays: _selectedDays,
    );
    final relativeCountdown = TimeZoneHelper.formatDurationUntil(nextOccurrence);
    final nextOccurrenceFormatted = DateFormat(widget.use24Hour ? 'EEE, HH:mm' : 'EEE, h:mm a').format(nextOccurrence);

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '2. SET ALARM TIME',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 1),
                ),
                // Toggle between setting by Remote Time vs Local Time
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _setByLocalTime = false),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: !_setByLocalTime ? const Color(0xFF6366F1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Remote (${selectedZoneInfo.city})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: !_setByLocalTime ? FontWeight.bold : FontWeight.normal,
                              color: !_setByLocalTime ? Colors.white : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _setByLocalTime = true),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _setByLocalTime ? const Color(0xFF10B981) : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'My Local Time',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: _setByLocalTime ? FontWeight.bold : FontWeight.normal,
                              color: _setByLocalTime ? Colors.white : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _setByLocalTime
                      ? const Color(0xFF10B981).withOpacity(0.5)
                      : const Color(0xFF6366F1).withOpacity(0.5),
                ),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${selectedZoneInfo.flag} In ${selectedZoneInfo.city}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                  ),
                                  if (!_setByLocalTime) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Primary Target',
                                        style: TextStyle(fontSize: 9.5, color: Color(0xFF818CF8), fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
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
                                Text('Pick Time', style: TextStyle(fontSize: 12, color: Color(0xFF818CF8), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(color: Color(0xFF1E293B), height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active, color: Color(0xFF4ADE80), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Local Alarm (${conversion.localAbbreviation.isNotEmpty ? conversion.localAbbreviation : TimeZoneHelper.getLocalTimeZoneName()}):',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white70),
                          ),
                        ],
                      ),
                      Text(
                        '${conversion.localFormatted} (${conversion.dayDifference})',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF4ADE80)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Quick Stepper Buttons: go back and front as user required
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildStepperBtn(
                        label: '⚡ Now',
                        onTap: _setCurrentTime,
                        isHighlight: true,
                      ),
                      _buildStepperBtn(
                        label: '-1h',
                        onTap: () => _adjustTime(deltaHours: -1),
                      ),
                      _buildStepperBtn(
                        label: '+1h',
                        onTap: () => _adjustTime(deltaHours: 1),
                      ),
                      _buildStepperBtn(
                        label: '-15m',
                        onTap: () => _adjustTime(deltaMinutes: -15),
                      ),
                      _buildStepperBtn(
                        label: '+15m',
                        onTap: () => _adjustTime(deltaMinutes: 15),
                      ),
                      _buildStepperBtn(
                        label: '-5m',
                        onTap: () => _adjustTime(deltaMinutes: -5),
                      ),
                      _buildStepperBtn(
                        label: '+5m',
                        onTap: () => _adjustTime(deltaMinutes: 5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Color(0xFF818CF8), size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Rings $relativeCountdown • Next: $nextOccurrenceFormatted',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFFA5B4FC), fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

  Widget _buildStepperBtn({
    required String label,
    required VoidCallback onTap,
    bool isHighlight = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isHighlight
              ? const Color(0xFF6366F1).withOpacity(0.25)
              : const Color(0xFF1E293B).withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHighlight ? const Color(0xFF818CF8) : const Color(0xFF334155),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isHighlight ? const Color(0xFFA5B4FC) : const Color(0xFFCBD5E1),
          ),
        ),
      ),
    );
  }
}
