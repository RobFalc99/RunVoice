import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                child: _BpmField(
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
                child: _BpmField(
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

class _BpmField extends StatefulWidget {
  final String label;
  final int value;
  final Color color;
  final ValueChanged<int>? onChanged;

  const _BpmField({
    required this.label,
    required this.value,
    required this.color,
    this.onChanged,
  });

  @override
  State<_BpmField> createState() => _BpmFieldState();
}

class _BpmFieldState extends State<_BpmField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
  }

  @override
  void didUpdateWidget(covariant _BpmField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 32,
            child: TextField(
              controller: _controller,
              style: TextStyle(
                color: widget.color,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (v) {
                final val = int.tryParse(v);
                if (val != null && val > 0 && val < 250) {
                  widget.onChanged?.call(val);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
