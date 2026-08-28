import 'package:flutter/material.dart';
import 'services/timezone_helper.dart';
import 'services/alarm_manager_service.dart';
import 'screens/home_screen.dart';
import 'screens/active_alarm_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  TimeZoneHelper.initialize();
  runApp(const TimezoneAlarmApp());
}

class TimezoneAlarmApp extends StatefulWidget {
  const TimezoneAlarmApp({super.key});

  @override
  State<TimezoneAlarmApp> createState() => _TimezoneAlarmAppState();
}

class _TimezoneAlarmAppState extends State<TimezoneAlarmApp> {
  final AlarmManagerService _alarmService = AlarmManagerService();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _alarmService,
      builder: (context, _) {
        return MaterialApp(
          title: 'Timezone Alarm',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF020617),
            primaryColor: const Color(0xFF6366F1),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1),
              surface: Color(0xFF0F172A),
            ),
          ),
          home: Stack(
            children: [
              HomeScreen(alarmService: _alarmService),
              if (_alarmService.ringingAlarm != null)
                ActiveAlarmScreen(
                  alarm: _alarmService.ringingAlarm!,
                  onDismiss: _alarmService.dismissAlarm,
                  onSnooze: _alarmService.snoozeAlarm,
                ),
            ],
          ),
        );
      },
    );
  }
}
