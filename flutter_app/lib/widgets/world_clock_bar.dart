import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/timezone_helper.dart';

class WorldClockBar extends StatefulWidget {
  final Function(String iana) onSelectZone;
  final bool use24Hour;

  const WorldClockBar({
    super.key,
    required this.onSelectZone,
    required this.use24Hour,
  });

  @override
  State<WorldClockBar> createState() => _WorldClockBarState();
}

class _WorldClockBarState extends State<WorldClockBar> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localOffsetMinutes = _now.timeZoneOffset.inMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.public, color: Color(0xFF818CF8), size: 14),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'LIVE GLOBAL CLOCKS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              const Text(
                'Tap clock to set alarm',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: TimeZoneHelper.featuredZones.length,
            itemBuilder: (context, index) {
              final zone = TimeZoneHelper.featuredZones[index];
              final loc = TimeZoneHelper.getLocation(zone.iana);
              final tzNow = tz.TZDateTime.from(_now, loc);
              final isDaytime = tzNow.hour >= 6 && tzNow.hour < 18;

              final zoneOffsetMinutes = tzNow.timeZoneOffset.inMinutes;
              final diffMinutes = zoneOffsetMinutes - localOffsetMinutes;
              final diffHours = diffMinutes ~/ 60;
              final diffRemMins = diffMinutes % 60;

              String diffLabel = 'Same time';
              if (diffMinutes != 0) {
                final sign = diffMinutes > 0 ? '+' : '-';
                if (diffRemMins == 0) {
                  diffLabel = '$sign${diffHours.abs()}h';
                } else {
                  diffLabel = '$sign${diffHours.abs()}h ${diffRemMins.abs()}m';
                }
              }

              final timeStr = DateFormat(widget.use24Hour ? 'HH:mm' : 'h:mm a').format(tzNow);

              return GestureDetector(
                onTap: () => widget.onSelectZone(zone.iana),
                child: Container(
                  width: 146,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF1E293B)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(zone.flag, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              Text(
                                zone.city,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE2E8F0),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          Icon(
                            isDaytime ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                            size: 13,
                            color: isDaytime ? const Color(0xFFFBBF24) : const Color(0xFFA5B4FC),
                          ),
                        ],
                      ),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              diffLabel,
                              style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            tzNow.timeZoneName,
                            style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
