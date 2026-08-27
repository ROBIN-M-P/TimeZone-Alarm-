import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class TimeZoneOption {
  final String id;
  final String label;
  final String city;
  final String country;
  final String region;

  const TimeZoneOption({
    required this.id,
    required this.label,
    required this.city,
    required this.country,
    required this.region,
  });
}

class TimeZoneHelper {
  static const List<TimeZoneOption> majorTimeZones = [
    TimeZoneOption(id: 'America/New_York', label: 'New York (EDT/EST)', city: 'New York', country: 'United States', region: 'Americas'),
    TimeZoneOption(id: 'America/Los_Angeles', label: 'San Francisco / LA (PDT/PST)', city: 'Los Angeles', country: 'United States', region: 'Americas'),
    TimeZoneOption(id: 'America/Chicago', label: 'Chicago (CDT/CST)', city: 'Chicago', country: 'United States', region: 'Americas'),
    TimeZoneOption(id: 'Europe/London', label: 'London (BST/GMT)', city: 'London', country: 'United Kingdom', region: 'Europe'),
    TimeZoneOption(id: 'Europe/Paris', label: 'Paris (CEST/CET)', city: 'Paris', country: 'France', region: 'Europe'),
    TimeZoneOption(id: 'Europe/Berlin', label: 'Berlin (CEST/CET)', city: 'Berlin', country: 'Germany', region: 'Europe'),
    TimeZoneOption(id: 'Asia/Tokyo', label: 'Tokyo (JST)', city: 'Tokyo', country: 'Japan', region: 'Asia-Pacific'),
    TimeZoneOption(id: 'Asia/Singapore', label: 'Singapore (SGT)', city: 'Singapore', country: 'Singapore', region: 'Asia-Pacific'),
    TimeZoneOption(id: 'Asia/Kolkata', label: 'India / Mumbai (IST)', city: 'Mumbai', country: 'India', region: 'Asia-Pacific'),
    TimeZoneOption(id: 'Asia/Dubai', label: 'Dubai (GST)', city: 'Dubai', country: 'UAE', region: 'Middle East'),
    TimeZoneOption(id: 'Australia/Sydney', label: 'Sydney (AEST/AEDT)', city: 'Sydney', country: 'Australia', region: 'Asia-Pacific'),
  ];

  static void initialize() {
    tz_data.initializeTimeZones();
  }

  static DateTime calculateNextLocalOccurrence({
    required String sourceTimeZone,
    required int sourceHour,
    required int sourceMinute,
    required List<int> repeatDays,
  }) {
    final now = DateTime.now();
    tz.Location sourceLocation;
    try {
      sourceLocation = tz.getLocation(sourceTimeZone);
    } catch (_) {
      sourceLocation = tz.getLocation('UTC');
    }

    final nowInSource = tz.TZDateTime.from(now, sourceLocation);

    var candidateSourceTime = tz.TZDateTime(
      sourceLocation,
      nowInSource.year,
      nowInSource.month,
      nowInSource.day,
      sourceHour,
      sourceMinute,
    );

    if (repeatDays.isEmpty) {
      if (candidateSourceTime.isBefore(nowInSource)) {
        candidateSourceTime = candidateSourceTime.add(const Duration(days: 1));
      }
      return candidateSourceTime.toLocal();
    }

    for (int i = 0; i < 7; i++) {
      final checkTime = candidateSourceTime.add(Duration(days: i));
      final dayOfWeek = checkTime.weekday % 7; // 0=Sun, 1=Mon ... 6=Sat
      if (repeatDays.contains(dayOfWeek)) {
        if (i > 0 || checkTime.isAfter(nowInSource)) {
          return checkTime.toLocal();
        }
      }
    }

    return candidateSourceTime.add(const Duration(days: 1)).toLocal();
  }

  static String formatDurationUntil(DateTime target) {
    final diff = target.difference(DateTime.now());
    if (diff.isNegative) return 'due now';

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    if (hours > 0) {
      return 'in ${hours}h ${minutes}m';
    }
    return 'in ${minutes}m';
  }
}
