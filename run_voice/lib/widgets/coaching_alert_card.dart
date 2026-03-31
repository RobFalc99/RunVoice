import 'package:flutter/material.dart';
import '../models/alert_config.dart';
import '../utils/constants.dart';

class CoachingAlertCard extends StatelessWidget {
  final CoachingAlert alert;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggle;

  const CoachingAlertCard({
    super.key,
    required this.alert,
    this.onEdit,
    this.onDelete,
    this.onToggle,
  });

  IconData _getAlertIcon() {
    switch (alert.metric) {
      case AlertMetric.hrZone:
      case AlertMetric.bpm:
        return Icons.favorite;
      case AlertMetric.distance:
        return Icons.straighten;
      case AlertMetric.pace:
        return Icons.speed;
      case AlertMetric.speed:
        return Icons.flight_takeoff;
      case AlertMetric.time:
        return Icons.timer;
    }
  }

  Color _getAlertColor() {
    return AppColors.primary; // Coaching is primary colored
  }

  @override
  Widget build(BuildContext context) {
    final color = _getAlertColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alert.enabled
              ? color.withValues(alpha: 0.3)
              : AppColors.surfaceHighlight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: alert.enabled ? 0.15 : 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getAlertIcon(),
                    color: alert.enabled ? color : AppColors.textMuted,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.name,
                        style: TextStyle(
                          color: alert.enabled
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.track_changes,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${alert.minValue.toStringAsFixed(1)} - ${alert.maxValue.toStringAsFixed(1)}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                alert.metric.displayName,
                                style: TextStyle(
                                  color: color.withValues(alpha: 0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Toggle
                if (onToggle != null)
                  Switch(value: alert.enabled, onChanged: onToggle),
                // Delete
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: AppColors.textMuted,
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
