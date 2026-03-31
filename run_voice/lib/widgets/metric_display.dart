import 'package:flutter/material.dart';
import '../utils/constants.dart';

class MetricDisplay extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color? color;
  final bool large;

  const MetricDisplay({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    required this.icon,
    this.color,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? AppColors.textPrimary;

    return Container(
      padding: EdgeInsets.all(large ? 20 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: displayColor.withValues(alpha: 0.7), size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: large ? 14 : 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: displayColor,
                  fontSize: large ? 36 : 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit!,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: large ? 16 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
