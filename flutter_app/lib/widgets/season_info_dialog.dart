import 'package:flutter/material.dart';

class SeasonInfoDialog extends StatelessWidget {
  const SeasonInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF1E293B)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
                          color: const Color(0xFFF59E0B).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.wb_sunny_outlined, color: Color(0xFFFBBF24), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Daylight Saving (DST)',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'How Seasonal Timezones Work in This App',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF38BDF8)),
              ),
              const SizedBox(height: 8),
              const Text(
                'When you set an alarm for 6:30 AM in Los Angeles (PST/PDT), the app automatically references the IANA timezone database. When US clocks "Spring Forward" or "Fall Back", your alarm dynamically adjusts so it ALWAYS fires at exactly 6:30 AM California time, no matter what your local clock says!',
                style: TextStyle(fontSize: 12.5, color: Color(0xFFCBD5E1), height: 1.45),
              ),
              const SizedBox(height: 16),
              _buildFeatureRow(
                Icons.check_circle_outline,
                'Always On Time for Overseas Standups',
                'Never calculate whether London, New York or Tokyo changed clocks this weekend.',
              ),
              const SizedBox(height: 10),
              _buildFeatureRow(
                Icons.schedule,
                'Exact Local Calculation',
                'Dual time display clearly shows both target city time and your resulting alarm time.',
              ),
              const SizedBox(height: 10),
              _buildFeatureRow(
                Icons.offline_pin_outlined,
                '100% Offline & Private',
                'Embedded IANA timezone tables calculate everything locally without needing an internet connection.',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it!'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF4ADE80), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}
