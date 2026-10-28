import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';

class NeumorphicSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final double width;
  final double height;

  const NeumorphicSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.width = 54,
    this.height = 30,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(height / 2);
    final thumbSize = height - 8;
    final horizontalPadding = 4.0;

    return Semantics(
      button: true,
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onChanged(!value);
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          width: width,
          height: height,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: value ? AppColors.surfaceHighlight : AppColors.surface,
            border: Border.all(
              color: value
                  ? AppColors.primary.withValues(alpha: 0.22)
                  : AppColors.neuBorder.withValues(alpha: 0.65),
              width: 1,
            ),
            boxShadow: value
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      blurRadius: 8,
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: AppColors.neuDarkShadow.withValues(alpha: 0.65),
                      offset: const Offset(2, 2),
                      blurRadius: 5,
                    ),
                    BoxShadow(
                      color: AppColors.neuLightShadow.withValues(alpha: 0.40),
                      offset: const Offset(-1.5, -1.5),
                      blurRadius: 3,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.neuDarkShadow.withValues(alpha: 0.85),
                      offset: const Offset(2, 2),
                      blurRadius: 5,
                    ),
                    BoxShadow(
                      color: AppColors.neuLightShadow.withValues(alpha: 0.35),
                      offset: const Offset(-1.5, -1.5),
                      blurRadius: 3,
                    ),
                  ],
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: thumbSize,
                  height: thumbSize,
                  margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value ? AppColors.primary : AppColors.textMuted,
                    boxShadow: [
                      BoxShadow(
                        color: (value ? AppColors.primary : AppColors.textMuted)
                            .withValues(alpha: 0.28),
                        blurRadius: value ? 10 : 6,
                        spreadRadius: -1,
                      ),
                      BoxShadow(
                        color: AppColors.neuDarkShadow.withValues(alpha: 0.45),
                        offset: const Offset(1.5, 1.5),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      gradient: value
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.08),
                                Colors.transparent,
                              ],
                            )
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.03),
                                Colors.transparent,
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NeumorphicSwitchListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final EdgeInsetsGeometry padding;
  final bool enabled;

  const NeumorphicSwitchListTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onChanged(!value);
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IgnorePointer(
                child: NeumorphicSwitch(
                  value: value,
                  onChanged: onChanged,
                  enabled: enabled,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
