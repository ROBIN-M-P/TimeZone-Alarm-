import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alarm.dart';
import '../services/alarm_manager_service.dart';
import '../services/timezone_helper.dart';
import '../widgets/world_clock_bar.dart';
import '../widgets/alarm_card.dart';
import '../widgets/create_alarm_sheet.dart';
import '../widgets/timezone_converter_sheet.dart';
import '../widgets/season_info_dialog.dart';

class HomeScreen extends StatelessWidget {
  final AlarmManagerService alarmService;

  const HomeScreen({super.key, required this.alarmService});

  void _openCreateAlarm(BuildContext context, {String? preselectedZone, String? preselectedTime, Alarm? editingAlarm}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateAlarmSheet(
        editingAlarm: editingAlarm,
        preselectedZone: preselectedZone,
        preselectedTime: preselectedTime,
        use24Hour: alarmService.use24Hour,
        onPreviewSound: alarmService.previewSound,
        onSave: (newAlarm) {
          if (editingAlarm != null) {
            alarmService.updateAlarm(newAlarm);
          } else {
            alarmService.addAlarm(newAlarm);
          }
        },
      ),
    );
  }

  void _openConverter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TimezoneConverterSheet(
        use24Hour: alarmService.use24Hour,
        onSetAlarmForTime: (sourceTz, time24) {
          _openCreateAlarm(context, preselectedZone: sourceTz, preselectedTime: time24);
        },
      ),
    );
  }

  void _openDstGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const SeasonInfoDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final localTimeStr = DateFormat(alarmService.use24Hour ? 'HH:mm' : 'h:mm a').format(now);
    final localDateStr = DateFormat('EEE, MMM d').format(now);
    final localTzName = TimeZoneHelper.getLocalTimeZoneName();

    // Find next upcoming alarm among enabled
    Alarm? nextUpcoming;
    DateTime? nextTriggerTime;

    for (final a in alarmService.alarms) {
      if (!a.enabled) continue;
      final trigger = a.snoozeUntil ??
          TimeZoneHelper.calculateNextLocalOccurrence(
            sourceTimeZone: a.sourceTimeZone,
            sourceHour: a.sourceHour,
            sourceMinute: a.sourceMinute,
            repeatDays: a.days,
          );

      if (nextTriggerTime == null || trigger.isBefore(nextTriggerTime)) {
        nextTriggerTime = trigger;
        nextUpcoming = a;
      }
    }

    final filteredList = alarmService.filteredAlarms;

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.alarm, color: Color(0xFF818CF8), size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Timezone Alarm',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Local: $localTimeStr ($localTzName)',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // 24H Toggle button
          InkWell(
            onTap: alarmService.toggleTimeFormat,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              alignment: Alignment.center,
              child: Text(
                alarmService.use24Hour ? '24H' : '12H',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF818CF8)),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // DST Info Guide Button
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF94A3B8), size: 20),
            tooltip: 'Daylight Saving Info',
            onPressed: () => _openDstGuide(context),
          ),

          // Time Converter Button
          IconButton(
            icon: const Icon(Icons.explore_outlined, color: Color(0xFF38BDF8), size: 22),
            tooltip: 'Time Explorer & Converter',
            onPressed: () => _openConverter(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // World Clock Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: WorldClockBar(
                use24Hour: alarmService.use24Hour,
                onSelectZone: (iana) {
                  _openCreateAlarm(context, preselectedZone: iana);
                },
              ),
            ),
          ),

          // Next Upcoming Alarm Banner
          if (nextUpcoming != null && nextTriggerTime != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active, color: Color(0xFF818CF8), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('NEXT ALARM: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF818CF8), letterSpacing: 0.8)),
                              Text(
                                TimeZoneHelper.formatDurationUntil(nextTriggerTime),
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF4ADE80)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            nextUpcoming.title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'At ${DateFormat(alarmService.use24Hour ? 'HH:mm' : 'h:mm a').format(nextTriggerTime)} local time',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Search & Filter Tabs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  // Search TextField
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      onChanged: alarmService.setSearchQuery,
                      decoration: const InputDecoration(
                        hintText: 'Search alarms or timezones...',
                        hintStyle: TextStyle(color: Color(0xFF475569), fontSize: 12.5),
                        prefixIcon: Icon(Icons.search, color: Color(0xFF64748B), size: 18),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Filter Chips (All, Active, Inactive)
                  Row(
                    children: [
                      _buildFilterChip('All (${alarmService.alarms.length})', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Active (${alarmService.alarms.where((a) => a.enabled).length})', 'active'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Inactive (${alarmService.alarms.where((a) => !a.enabled).length})', 'inactive'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Alarms List
          if (filteredList.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.alarm_off, size: 56, color: const Color(0xFF6366F1).withOpacity(0.3)),
                      const SizedBox(height: 16),
                      const Text(
                        'No Alarms Found',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tap the + button below or click any global clock to create a timezone alarm.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final alarm = filteredList[index];
                    return AlarmCard(
                      alarm: alarm,
                      use24Hour: alarmService.use24Hour,
                      onToggle: () => alarmService.toggleAlarm(alarm.id),
                      onDuplicate: () => alarmService.duplicateAlarm(alarm.id),
                      onEdit: () => _openCreateAlarm(context, editingAlarm: alarm),
                      onDelete: () => alarmService.deleteAlarm(alarm.id),
                      onPreviewSound: alarmService.previewSound,
                    );
                  },
                  childCount: filteredList.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => _openCreateAlarm(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add Alarm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = alarmService.filterTab == value;
    return InkWell(
      onTap: () => alarmService.setFilterTab(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1).withOpacity(0.25) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: isSelected ? const Color(0xFF818CF8) : const Color(0xFF94A3B8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
