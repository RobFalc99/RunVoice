import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';

class NeumorphicSegmentedControl<T> extends StatefulWidget {
  final T value;
  final ValueChanged<T> onChanged;
  final List<NeumorphicSegment<T>> segments;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double minHeight;
  final double borderRadius;
  final bool enabled;

  const NeumorphicSegmentedControl({
    super.key,
    required this.value,
    required this.onChanged,
    required this.segments,
    this.padding = const EdgeInsets.all(4),
    this.margin,
    this.minHeight = 48,
    this.borderRadius = 18,
    this.enabled = true,
  }) : assert(segments.length > 1, 'NeumorphicSegmentedControl needs at least two segments.');

  @override
  State<NeumorphicSegmentedControl<T>> createState() => _NeumorphicSegmentedControlState<T>();
}

class _NeumorphicSegmentedControlState<T> extends State<NeumorphicSegmentedControl<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  T? _pressedValue;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      reverseDuration: const Duration(milliseconds: 120),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setPressed(T? value) {
    if (!widget.enabled) return;
    if (_pressedValue == value) return;
    setState(() => _pressedValue = value);
    if (value == null) {
      _controller.reverse();
    } else {
      HapticFeedback.lightImpact();
      _controller.forward();
    }
  }

  void _handleTap(T value) {
    if (!widget.enabled || value == widget.value) return;
    HapticFeedback.selectionClick();
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.segments;
    final selectedIndex = entries.indexWhere((e) => e.value == widget.value);

    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: widget.minHeight),
          child: DecoratedBox(
            decoration: NeumorphicDecorations.inset(
              radius: widget.borderRadius,
              color: AppColors.surface,
            ),
            child: Padding(
              padding: widget.padding,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final segmentWidth = constraints.maxWidth / entries.length;
                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        left: selectedIndex < 0 ? 0 : selectedIndex * segmentWidth,
                        top: 0,
                        bottom: 0,
                        width: segmentWidth,
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (_, child) {
                            final isPressed = _pressedValue != null;
                            return Transform.scale(
                              scale: 1.0 - (isPressed ? 0.02 : 0.0) + (_controller.value * 0.01),
                              child: child,
                            );
                          },
                          child: Container(
                            key: ValueKey<String>(widget.value.toString()),
                            width: segmentWidth,
                            decoration: NeumorphicDecorations.extruded(
                              radius: widget.borderRadius - 4,
                              color: AppColors.surfaceHighlight,
                              borderColor: AppColors.accent.withValues(alpha: 0.35),
                              depth: 3,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (final segment in entries)
                            Expanded(
                              child: _Segment<T>(
                                segment: segment,
                                selected: segment.value == widget.value,
                                enabled: widget.enabled,
                                minHeight: widget.minHeight,
                                onTap: () => _handleTap(segment.value),
                                onPressedChanged: _setPressed,
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NeumorphicSegment<T> {
  final T value;
  final String label;
  final IconData? icon;

  const NeumorphicSegment({
    required this.value,
    required this.label,
    this.icon,
  });
}

class _Segment<T> extends StatefulWidget {
  final NeumorphicSegment<T> segment;
  final bool selected;
  final bool enabled;
  final double minHeight;
  final VoidCallback onTap;
  final ValueChanged<T?> onPressedChanged;

  const _Segment({
    required this.segment,
    required this.selected,
    required this.enabled,
    required this.minHeight,
    required this.onTap,
    required this.onPressedChanged,
  });

  @override
  State<_Segment<T>> createState() => _SegmentState<T>();
}

class _SegmentState<T> extends State<_Segment<T>> {
  bool _pressed = false;

  void _handleHighlight(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
    widget.onPressedChanged(value ? widget.segment.value : null);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        key: ValueKey<String>(widget.segment.value.toString()),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        constraints: BoxConstraints(minHeight: widget.minHeight),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.95)
                : AppColors.neuBorder.withValues(alpha: 0.35),
            width: selected ? 1.2 : 1,
          ),
          color: selected ? AppColors.surfaceHighlight.withValues(alpha: 0.55) : Colors.transparent,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.neuDarkShadow.withValues(alpha: 0.55),
                    offset: const Offset(1, 1),
                    blurRadius: 3,
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: widget.enabled ? widget.onTap : null,
          onHighlightChanged: widget.enabled ? _handleHighlight : null,
          borderRadius: BorderRadius.circular(14),
          splashColor: AppColors.accent.withValues(alpha: 0.12),
          highlightColor: AppColors.accent.withValues(alpha: 0.08),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 140),
            scale: _pressed ? 0.98 : 1.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                if (widget.segment.icon != null) ...[
                  Icon(widget.segment.icon, size: 18, color: selected ? AppColors.accentLight : AppColors.textMuted),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.segment.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
