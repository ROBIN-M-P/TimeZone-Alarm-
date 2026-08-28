import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alarm.dart';
import '../services/timezone_helper.dart';

class AlarmCard extends StatelessWidget {
  final Alarm alarm;
  final bool use24Hour;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final Function(String sound, double volume)? onPreviewSound;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.use24Hour,
    required this.onToggle,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
    this.onPreviewSound,
  });

  @override
  Widget build(BuildContext context) {
    final nextOccurrence = TimeZoneHelper.calculateNextLocalOccurrence(
      sourceTimeZone: alarm.sourceTimeZone,
      sourceHour: alarm.sourceHour,
      sourceMinute: alarm.sourceMinute,
      repeatDays: alarm.days,
    );

    final localTimeFormatted = DateFormat(use24Hour ? 'HH:mm' : 'h:mm a').format(nextOccurrence);
    final relativeCountdown = TimeZoneHelper.formatDurationUntil(nextOccurrence);

    final zoneInfo = TimeZoneHelper.allTimeZones.firstWhere(
      (z) => z.iana == alarm.sourceTimeZone,
      orElse: () => TimeZoneInfo(
        iana: alarm.sourceTimeZone,
        label: alarm.sourceTimeZone,
        city: alarm.sourceTimeZone.split('/').last.replaceAll('_', ' '),
        country: 'Global',
        flag: '🌐',
        region: 'Global',
      ),
    );

    final sourceTimeFormatted = DateFormat(use24Hour ? 'HH:mm' : 'h:mm a').format(
      DateTime(2026, 1, 1, alarm.sourceHour, alarm.sourceMinute),
    );

    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: alarm.enabled ? const Color(0xFF6366F1).withOpacity(0.4) : const Color(0xFF1E293B),
          width: alarm.enabled ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Title and Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        alarm.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: alarm.enabled ? Colors.white : const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Switch(
                      value: alarm.enabled,
                      activeColor: const Color(0xFF6366F1),
                      activeTrackColor: const Color(0xFF6366F1).withOpacity(0.4),
                      inactiveThumbColor: const Color(0xFF475569),
                      inactiveTrackColor: const Color(0xFF1E293B),
                      onChanged: (_) => onToggle(),
                    ),
                  ],
                ),

                // Source Timezone Badge & Remote Time
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF020617),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(zoneInfo.flag, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            '${zoneInfo.city} • $sourceTimeFormatted',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF38BDF8), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    if (alarm.enabled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Rings $relativeCountdown',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFFA5B4FC), fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Local Converted Time Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR LOCAL TIME',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          localTimeFormatted,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            color: alarm.enabled ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),

                    // Repeat Days Badges
                    Row(
                      children: List.generate(7, (i) {
                        final dayNum = i + 1; // 1=Mon..7=Sun
                        final isDayActive = alarm.days.contains(dayNum) || (dayNum == 7 && alarm.days.contains(0));
                        return Container(
                          width: 22,
                          height: 22,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDayActive
                                ? (alarm.enabled ? const Color(0xFF6366F1) : const Color(0xFF334155))
                                : const Color(0xFF020617),
                            border: Border.all(
                              color: isDayActive ? const Color(0xFF818CF8) : const Color(0xFF1E293B),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            dayLabels[i],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDayActive ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Bar Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF020617),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(17)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Sound Tag & Preview
                InkWell(
                  onTap: () => onPreviewSound?.call(alarm.sound, alarm.volume),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.volume_up, size: 14, color: Color(0xFF818CF8)),
                        const SizedBox(width: 4),
                        Text(
                          alarm.sound.toUpperCase(),
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF818CF8), fontWeight: FontWeight.bold),
                        ),
                        if (alarm.vibrate) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.vibration, size: 13, color: Color(0xFF94A3B8)),
                        ],
                      ],
                    ),
                  ),
                ),

                // Card Actions (Duplicate, Edit, Delete)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16, color: Color(0xFF94A3B8)),
                      tooltip: 'Duplicate',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      onPressed: onDuplicate,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF94A3B8)),
                      tooltip: 'Edit',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      onPressed: onEdit,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
                      tooltip: 'Delete',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
