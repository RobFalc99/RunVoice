import 'package:flutter/material.dart';
import '../models/heart_rate_zone.dart';
import '../utils/constants.dart';

class ZoneEditor extends StatelessWidget {
  final HeartRateZone zone;
  final ValueChanged<int>? onMinChanged;
  final ValueChanged<int>? onMaxChanged;

  const ZoneEditor({
    super.key,
    required this.zone,
    this.onMinChanged,
    this.onMaxChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getZoneColor(zone.zoneNumber);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${zone.zoneNumber}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  zone.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${zone.minPercent}% - ${zone.maxPercent}%',
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BpmInput(
                  label: 'Min BPM',
                  value: zone.minBpm,
                  color: color,
                  onChanged: onMinChanged,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward, color: AppColors.textMuted, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: _BpmInput(
                  label: 'Max BPM',
                  value: zone.maxBpm,
                  color: color,
                  onChanged: onMaxChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BpmInput extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final ValueChanged<int>? onChanged;

  const _BpmInput({
    required this.label,
    required this.value,
    required this.color,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$value',
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            children: [
              _SmallButton(
                icon: Icons.add,
                onPressed: onChanged != null
                    ? () => onChanged!(value + 1)
                    : null,
              ),
              const SizedBox(height: 2),
              _SmallButton(
                icon: Icons.remove,
                onPressed: onChanged != null
                    ? () => onChanged!(value - 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _SmallButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 14, color: AppColors.textSecondary),
        onPressed: onPressed,
      ),
    );
  }
}
