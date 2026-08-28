import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class TimeZoneInfo {
  final String iana;
  final String label;
  final String city;
  final String country;
  final String flag;
  final String region;

  const TimeZoneInfo({
    required this.iana,
    required this.label,
    required this.city,
    required this.country,
    required this.flag,
    required this.region,
  });

  String get displayName => '$flag $city, $country ($iana)';
}

class ConvertedTimeResult {
  final String sourceFormatted;
  final String localFormatted;
  final int hourDiff;
  final String dayDifference; // e.g. "Same day", "+1 day", "-1 day"
  final bool isSourceDaytime;
  final bool isLocalDaytime;
  final String sourceAbbreviation;
  final String localAbbreviation;

  ConvertedTimeResult({
    required this.sourceFormatted,
    required this.localFormatted,
    required this.hourDiff,
    required this.dayDifference,
    required this.isSourceDaytime,
    required this.isLocalDaytime,
    required this.sourceAbbreviation,
    required this.localAbbreviation,
  });
}

class TimeZoneHelper {
  static bool _initialized = false;

  static const List<TimeZoneInfo> featuredZones = [
    TimeZoneInfo(iana: 'America/Los_Angeles', label: 'Los Angeles (PST/PDT)', city: 'Los Angeles', country: 'USA', flag: '🇺🇸', region: 'Americas'),
    TimeZoneInfo(iana: 'America/New_York', label: 'New York (EST/EDT)', city: 'New York', country: 'USA', flag: '🇺🇸', region: 'Americas'),
    TimeZoneInfo(iana: 'Europe/London', label: 'London (GMT/BST)', city: 'London', country: 'UK', flag: '🇬🇧', region: 'Europe'),
    TimeZoneInfo(iana: 'Europe/Paris', label: 'Paris (CET/CEST)', city: 'Paris', country: 'France', flag: '🇫🇷', region: 'Europe'),
    TimeZoneInfo(iana: 'Europe/Berlin', label: 'Berlin (CET/CEST)', city: 'Berlin', country: 'Germany', flag: '🇩🇪', region: 'Europe'),
    TimeZoneInfo(iana: 'Asia/Dubai', label: 'Dubai (GST)', city: 'Dubai', country: 'UAE', flag: '🇦🇪', region: 'Middle East'),
    TimeZoneInfo(iana: 'Asia/Kolkata', label: 'India / Mumbai (IST)', city: 'Mumbai', country: 'India', flag: '🇮🇳', region: 'Asia'),
    TimeZoneInfo(iana: 'Asia/Singapore', label: 'Singapore (SGT)', city: 'Singapore', country: 'Singapore', flag: '🇸🇬', region: 'Asia'),
    TimeZoneInfo(iana: 'Asia/Tokyo', label: 'Tokyo (JST)', city: 'Tokyo', country: 'Japan', flag: '🇯🇵', region: 'Asia'),
    TimeZoneInfo(iana: 'Australia/Sydney', label: 'Sydney (AEST/AEDT)', city: 'Sydney', country: 'Australia', flag: '🇦🇺', region: 'Oceania'),
  ];

  static const List<TimeZoneInfo> allTimeZones = [
    TimeZoneInfo(iana: 'America/Los_Angeles', label: 'US Pacific (PST/PDT)', city: 'Los Angeles', country: 'United States', flag: '🇺🇸', region: 'Americas'),
    TimeZoneInfo(iana: 'America/Denver', label: 'US Mountain (MST/MDT)', city: 'Denver', country: 'United States', flag: '🇺🇸', region: 'Americas'),
    TimeZoneInfo(iana: 'America/Chicago', label: 'US Central (CST/CDT)', city: 'Chicago', country: 'United States', flag: '🇺🇸', region: 'Americas'),
    TimeZoneInfo(iana: 'America/New_York', label: 'US Eastern (EST/EDT)', city: 'New York', country: 'United States', flag: '🇺🇸', region: 'Americas'),
    TimeZoneInfo(iana: 'America/Toronto', label: 'Toronto', city: 'Toronto', country: 'Canada', flag: '🇨🇦', region: 'Americas'),
    TimeZoneInfo(iana: 'America/Vancouver', label: 'Vancouver', city: 'Vancouver', country: 'Canada', flag: '🇨🇦', region: 'Americas'),
    TimeZoneInfo(iana: 'America/Sao_Paulo', label: 'São Paulo (BRT)', city: 'São Paulo', country: 'Brazil', flag: '🇧🇷', region: 'Americas'),
    TimeZoneInfo(iana: 'America/Buenos_Aires', label: 'Buenos Aires (ART)', city: 'Buenos Aires', country: 'Argentina', flag: '🇦🇷', region: 'Americas'),
    TimeZoneInfo(iana: 'Europe/London', label: 'London (GMT/BST)', city: 'London', country: 'United Kingdom', flag: '🇬🇧', region: 'Europe'),
    TimeZoneInfo(iana: 'Europe/Dublin', label: 'Dublin (GMT/IST)', city: 'Dublin', country: 'Ireland', flag: '🇮🇪', region: 'Europe'),
    TimeZoneInfo(iana: 'Europe/Paris', label: 'Paris (CET/CEST)', city: 'Paris', country: 'France', flag: '🇫🇷', region: 'Europe'),
    TimeZoneInfo(iana: 'Europe/Berlin', label: 'Berlin (CET/CEST)', city: 'Berlin', country: 'Germany', flag: '🇩🇪', region: 'Europe'),
    TimeZoneInfo(iana: 'Europe/Rome', label: 'Rome (CET/CEST)', city: 'Rome', country: 'Italy', flag: '🇮🇹', region: 'Europe'),
    TimeZoneInfo(iana: 'Europe/Madrid', label: 'Madrid (CET/CEST)', city: 'Madrid', country: 'Spain', flag: '🇪🇸', region: 'Europe'),
    TimeZoneInfo(iana: 'Europe/Amsterdam', label: 'Amsterdam', city: 'Amsterdam', country: 'Netherlands', flag: '🇳🇱', region: 'Europe'),
    TimeZoneInfo(iana: 'Europe/Zurich', label: 'Zurich', city: 'Zurich', country: 'Switzerland', flag: '🇨🇭', region: 'Europe'),
    TimeZoneInfo(iana: 'Europe/Athens', label: 'Athens (EET/EEST)', city: 'Athens', country: 'Greece', flag: '🇬🇷', region: 'Europe'),
    TimeZoneInfo(iana: 'Asia/Dubai', label: 'Dubai (GST)', city: 'Dubai', country: 'United Arab Emirates', flag: '🇦🇪', region: 'Middle East'),
    TimeZoneInfo(iana: 'Asia/Riyadh', label: 'Riyadh (AST)', city: 'Riyadh', country: 'Saudi Arabia', flag: '🇸🇦', region: 'Middle East'),
    TimeZoneInfo(iana: 'Asia/Kolkata', label: 'India (IST)', city: 'Mumbai / Delhi', country: 'India', flag: '🇮🇳', region: 'Asia'),
    TimeZoneInfo(iana: 'Asia/Bangkok', label: 'Bangkok (ICT)', city: 'Bangkok', country: 'Thailand', flag: '🇹🇭', region: 'Asia'),
    TimeZoneInfo(iana: 'Asia/Singapore', label: 'Singapore (SGT)', city: 'Singapore', country: 'Singapore', flag: '🇸🇬', region: 'Asia'),
    TimeZoneInfo(iana: 'Asia/Hong_Kong', label: 'Hong Kong (HKT)', city: 'Hong Kong', country: 'Hong Kong', flag: '🇭🇰', region: 'Asia'),
    TimeZoneInfo(iana: 'Asia/Shanghai', label: 'Beijing / Shanghai (CST)', city: 'Beijing', country: 'China', flag: '🇨🇳', region: 'Asia'),
    TimeZoneInfo(iana: 'Asia/Tokyo', label: 'Tokyo (JST)', city: 'Tokyo', country: 'Japan', flag: '🇯🇵', region: 'Asia'),
    TimeZoneInfo(iana: 'Asia/Seoul', label: 'Seoul (KST)', city: 'Seoul', country: 'South Korea', flag: '🇰🇷', region: 'Asia'),
    TimeZoneInfo(iana: 'Australia/Sydney', label: 'Sydney (AEST/AEDT)', city: 'Sydney', country: 'Australia', flag: '🇦🇺', region: 'Oceania'),
    TimeZoneInfo(iana: 'Australia/Melbourne', label: 'Melbourne (AEST/AEDT)', city: 'Melbourne', country: 'Australia', flag: '🇦🇺', region: 'Oceania'),
    TimeZoneInfo(iana: 'Pacific/Auckland', label: 'Auckland (NZST/NZDT)', city: 'Auckland', country: 'New Zealand', flag: '🇳🇿', region: 'Oceania'),
    TimeZoneInfo(iana: 'Pacific/Honolulu', label: 'Hawaii (HST)', city: 'Honolulu', country: 'United States', flag: '🇺🇸', region: 'Oceania'),
  ];

  static void initialize() {
    if (!_initialized) {
      tz_data.initializeTimeZones();
      _initialized = true;
    }
  }

  static tz.Location getLocation(String iana) {
    initialize();
    try {
      return tz.getLocation(iana);
    } catch (_) {
      return tz.getLocation('UTC');
    }
  }

  static String getLocalTimeZoneName() {
    return DateTime.now().timeZoneName;
  }

  static int getUtcOffsetMinutes(String iana, [DateTime? date]) {
    final loc = getLocation(iana);
    final d = date ?? DateTime.now();
    final tzDate = tz.TZDateTime.from(d, loc);
    return tzDate.timeZoneOffset.inMinutes;
  }

  static String getOffsetFormatted(String iana, [DateTime? date]) {
    final mins = getUtcOffsetMinutes(iana, date);
    final hours = mins ~/ 60;
    final remainingMins = (mins % 60).abs();
    final sign = hours >= 0 ? '+' : '-';
    final hStr = hours.abs().toString().padLeft(2, '0');
    final mStr = remainingMins.toString().padLeft(2, '0');
    return 'UTC$sign$hStr:$mStr';
  }

  /// Calculates the next local occurrence for a source timezone and target time
  static DateTime calculateNextLocalOccurrence({
    required String sourceTimeZone,
    required int sourceHour,
    required int sourceMinute,
    required List<int> repeatDays, // 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun (or 0=Sun)
  }) {
    initialize();
    final now = DateTime.now();
    final sourceLoc = getLocation(sourceTimeZone);
    final nowInSource = tz.TZDateTime.from(now, sourceLoc);

    var candidateSourceTime = tz.TZDateTime(
      sourceLoc,
      nowInSource.year,
      nowInSource.month,
      nowInSource.day,
      sourceHour,
      sourceMinute,
    );

    // Standardize repeat days to Dart's DateTime.weekday (1=Mon ... 7=Sun)
    final Set<int> normalizedDays = {};
    for (final d in repeatDays) {
      if (d == 0) {
        normalizedDays.add(7); // Sunday
      } else {
        normalizedDays.add(d);
      }
    }

    if (normalizedDays.isEmpty) {
      // One-off alarm: if time has passed in source timezone today, schedule for tomorrow
      if (candidateSourceTime.isBefore(nowInSource)) {
        candidateSourceTime = candidateSourceTime.add(const Duration(days: 1));
      }
      return candidateSourceTime.toLocal();
    }

    // Check next 7 days for matching recurring day
    for (int i = 0; i < 7; i++) {
      final checkTime = candidateSourceTime.add(Duration(days: i));
      if (normalizedDays.contains(checkTime.weekday)) {
        if (i > 0 || checkTime.isAfter(nowInSource)) {
          return checkTime.toLocal();
        }
      }
    }

    return candidateSourceTime.add(const Duration(days: 1)).toLocal();
  }

  /// Convert source time "HH:mm" in source timezone to local time representation
  static ConvertedTimeResult convertSourceToLocal({
    required String sourceTime, // "HH:mm"
    required String sourceTimeZone,
    bool use24Hour = false,
  }) {
    initialize();
    final parts = sourceTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    final now = DateTime.now();
    final sourceLoc = getLocation(sourceTimeZone);
    final nowInSource = tz.TZDateTime.from(now, sourceLoc);

    final sourceTzDate = tz.TZDateTime(
      sourceLoc,
      nowInSource.year,
      nowInSource.month,
      nowInSource.day,
      hour,
      minute,
    );

    final localEquivalent = sourceTzDate.toLocal();

    final sourceFormat = DateFormat(use24Hour ? 'HH:mm' : 'h:mm a');
    final localFormat = DateFormat(use24Hour ? 'HH:mm' : 'h:mm a');

    final hourDiff = (localEquivalent.difference(sourceTzDate).inHours);
    
    String dayDiff = 'Same day';
    if (localEquivalent.day > sourceTzDate.day) {
      dayDiff = '+1 day';
    } else if (localEquivalent.day < sourceTzDate.day) {
      dayDiff = '-1 day';
    }

    return ConvertedTimeResult(
      sourceFormatted: sourceFormat.format(sourceTzDate),
      localFormatted: localFormat.format(localEquivalent),
      hourDiff: hourDiff,
      dayDifference: dayDiff,
      isSourceDaytime: sourceTzDate.hour >= 6 && sourceTzDate.hour < 18,
      isLocalDaytime: localEquivalent.hour >= 6 && localEquivalent.hour < 18,
      sourceAbbreviation: sourceTzDate.timeZoneName,
      localAbbreviation: localEquivalent.timeZoneName,
    );
  }

  static String formatDurationUntil(DateTime target) {
    final diff = target.difference(DateTime.now());
    if (diff.isNegative) return 'due now';

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    if (days > 0) {
      return 'in ${days}d ${hours}h';
    } else if (hours > 0) {
      return 'in ${hours}h ${minutes}m';
    }
    return 'in ${minutes}m';
  }
}
