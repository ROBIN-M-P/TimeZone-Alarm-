import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/timezone_helper.dart';

class TimezoneConverterSheet extends StatefulWidget {
  final Function(String sourceTz, String time24) onSetAlarmForTime;
  final bool use24Hour;

  const TimezoneConverterSheet({
    super.key,
    required this.onSetAlarmForTime,
    required this.use24Hour,
  });

  @override
  State<TimezoneConverterSheet> createState() => _TimezoneConverterSheetState();
}

class _TimezoneConverterSheetState extends State<TimezoneConverterSheet> {
  String _sourceTz = 'America/Los_Angeles';
  double _hourSlider = 6.5; // 6:30 AM default

  @override
  Widget build(BuildContext context) {
    final hourInt = _hourSlider.floor();
    final minInt = ((_hourSlider - hourInt) * 60).round();
    final time24Str = '${hourInt.toString().padLeft(2, '0')}:${minInt.toString().padLeft(2, '0')}';

    final conversion = TimeZoneHelper.convertSourceToLocal(
      sourceTime: time24Str,
      sourceTimeZone: _sourceTz,
      use24Hour: widget.use24Hour,
    );

    final selectedZoneInfo = TimeZoneHelper.allTimeZones.firstWhere(
      (z) => z.iana == _sourceTz,
      orElse: () => TimeZoneHelper.allTimeZones.first,
    );

    return Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.explore, color: Color(0xFF22D3EE), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time Explorer & Converter',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'Scrub time to see instant local conversion',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Timezone Dropdown
            const Text(
              'SOURCE TIMEZONE',
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
                  value: _sourceTz,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0F172A),
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF818CF8)),
                  items: TimeZoneHelper.allTimeZones.map((tz) {
                    return DropdownMenuItem(
                      value: tz.iana,
                      child: Text(
                        '${tz.flag} ${tz.city}, ${tz.country} (${tz.label.split('(').last}',
                        style: const TextStyle(fontSize: 13.5, color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _sourceTz = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Slider & Time Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E293B)),
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
                          Row(
                            children: [
                              Text(
                                conversion.sourceFormatted,
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                conversion.isSourceDaytime ? Icons.wb_sunny : Icons.nightlight_round,
                                size: 16,
                                color: conversion.isSourceDaytime ? Colors.amber : const Color(0xFFA5B4FC),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_rounded, color: Color(0xFF6366F1)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Your Local Alarm Time',
                            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                conversion.localFormatted,
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4ADE80)),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                conversion.isLocalDaytime ? Icons.wb_sunny : Icons.nightlight_round,
                                size: 16,
                                color: conversion.isLocalDaytime ? Colors.amber : const Color(0xFFA5B4FC),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF6366F1),
                      inactiveTrackColor: const Color(0xFF1E293B),
                      thumbColor: const Color(0xFF818CF8),
                      overlayColor: const Color(0xFF6366F1).withOpacity(0.2),
                    ),
                    child: Slider(
                      value: _hourSlider,
                      min: 0,
                      max: 23.75,
                      divisions: 95, // 15-minute increments
                      onChanged: (val) => setState(() => _hourSlider = val),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('12:00 AM', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      Text(
                        'Day diff: ${conversion.dayDifference}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B)),
                      ),
                      const Text('11:45 PM', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Preset Times (e.g. 6:30 AM PST Standup, 9:00 AM Market Open)
            const Text(
              'POPULAR GLOBAL TIMES',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickPreset('6:30 AM Standup', 6.5),
                _buildQuickPreset('8:00 AM Market Open', 8.0),
                _buildQuickPreset('9:00 AM Morning Start', 9.0),
                _buildQuickPreset('2:00 PM Afternoon Sync', 14.0),
                _buildQuickPreset('5:00 PM End of Day', 17.0),
              ],
            ),
            const SizedBox(height: 24),

            // Set Alarm Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onSetAlarmForTime(_sourceTz, time24Str);
                },
                icon: const Icon(Icons.alarm_add, size: 18),
                label: Text(
                  'Set Alarm for $time24Str in ${selectedZoneInfo.city}',
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPreset(String label, double hourVal) {
    final isSelected = (_hourSlider - hourVal).abs() < 0.1;
    return InkWell(
      onTap: () => setState(() => _hourSlider = hourVal),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1).withOpacity(0.2) : const Color(0xFF020617),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: isSelected ? const Color(0xFF818CF8) : const Color(0xFFCBD5E1),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
