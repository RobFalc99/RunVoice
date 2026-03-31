import 'package:flutter/material.dart';
import '../models/alert_config.dart';
import '../utils/constants.dart';

class AlertCard extends StatelessWidget {
  final AlertConfig alert;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggle;

  const AlertCard({
    super.key,
    required this.alert,
    this.onEdit,
    this.onDelete,
    this.onToggle,
  });

  IconData _getAlertIcon() {
    switch (alert.type) {
      case AlertType.heartRateZone:
        return Icons.favorite;
      case AlertType.distance:
        return Icons.straighten;
      case AlertType.pace:
        return Icons.speed;
      case AlertType.time:
        return Icons.timer;
    }
  }

  Color _getAlertColor() {
    switch (alert.type) {
      case AlertType.heartRateZone:
        return AppColors.error;
      case AlertType.distance:
        return AppColors.success;
      case AlertType.pace:
        return AppColors.accent;
      case AlertType.time:
        return AppColors.warning;
    }
  }

  String _formatInterval() {
    final seconds = alert.intervalSeconds;
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) return '${minutes}m';
    return '${minutes}m ${remainingSeconds}s';
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
                            Icons.replay,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ogni ${_formatInterval()}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              alert.type.displayName,
                              style: TextStyle(
                                color: color.withValues(alpha: 0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
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
