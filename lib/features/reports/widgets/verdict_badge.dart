import 'package:flutter/material.dart';

import '../report_engine.dart';

class VerdictBadge extends StatelessWidget {
  const VerdictBadge({super.key, required this.verdict});

  final ReportVerdict verdict;

  static const _statusGreenLight = Color(0xFF2E7D32);
  static const _statusAmberLight = Color(0xFFB26A00);
  static const _statusRedLight = Color(0xFFC62828);

  static const _statusGreenDark = Color(0xFF81C784);
  static const _statusAmberDark = Color(0xFFFFB74D);
  static const _statusRedDark = Color(0xFFE57373);

  (Color, IconData, String) _statusFor(ReportVerdict verdict, bool isDark) {
    final green = isDark ? _statusGreenDark : _statusGreenLight;
    final amber = isDark ? _statusAmberDark : _statusAmberLight;
    final red = isDark ? _statusRedDark : _statusRedLight;
    return switch (verdict) {
      ReportVerdict.great => (green, Icons.check_circle, 'Great'),
      ReportVerdict.good => (amber, Icons.trending_up, 'Good'),
      ReportVerdict.needsImprovement => (red, Icons.priority_high, 'Needs work'),
      ReportVerdict.noData => (Colors.grey, Icons.help_outline, 'No data'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (color, icon, label) = _statusFor(verdict, isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
