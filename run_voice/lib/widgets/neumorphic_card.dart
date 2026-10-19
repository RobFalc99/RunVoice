import 'package:flutter/material.dart';
import '../utils/constants.dart';

enum NeumorphicStyle { flat, extruded, inset }

class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final NeumorphicStyle style;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? accentBorderColor;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 16,
    this.style = NeumorphicStyle.extruded,
    this.onTap,
    this.backgroundColor,
    this.accentBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    BoxDecoration decoration;
    switch (style) {
      case NeumorphicStyle.extruded:
        decoration = NeumorphicDecorations.extruded(
          radius: borderRadius,
          color: backgroundColor ?? AppColors.surface,
          borderColor: accentBorderColor ?? AppColors.accent.withValues(alpha: 0.10),
        );
        break;
      case NeumorphicStyle.inset:
        decoration = NeumorphicDecorations.inset(
          radius: borderRadius,
          color: backgroundColor ?? AppColors.background,
          borderColor: accentBorderColor ?? AppColors.accent.withValues(alpha: 0.08),
        );
        break;
      case NeumorphicStyle.flat:
        decoration = BoxDecoration(
          color: backgroundColor ?? AppColors.surface,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: accentBorderColor ?? AppColors.accent.withValues(alpha: 0.10),
            width: 1,
          ),
        );
        break;
    }

    final card = Container(
      margin: margin,
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: card,
        ),
      );
    }

    return card;
  }
}
