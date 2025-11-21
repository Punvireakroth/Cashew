import 'package:flutter/material.dart';

class BudgetProgressBar extends StatelessWidget {

  final double percentage;

  final double? height;

  final Color? backgroundColor;

  final Color? progressColor;

  final bool showPercentage;

  final bool showStatus;

  final double? borderRadius;

  final Duration? animationDuration;

  const BudgetProgressBar({
    super.key,
    required this.percentage,
    this.height,
    this.backgroundColor,
    this.progressColor,
    this.showPercentage = true,
    this.showStatus = true,
    this.borderRadius,
    this.animationDuration,
  }) : assert(
          percentage >= 0.0,
          'Percentage must be >= 0.0',
        );
  Color _getProgressColor(BuildContext context) {
    if (progressColor != null) {
      return progressColor!;
    }

    if (percentage < 0.8) {
      return Colors.green;
    } else if (percentage <= 1.0) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }

  String _getStatusText() {
    if (percentage < 0.8) {
      return 'Under Budget';
    } else if (percentage <= 1.0) {
      return 'Warning';
    } else {
      return 'Over Budget';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clampedPercentage = percentage.clamp(0.0, 1.0);
    final barHeight = height ?? 8.0;
    final bgColor = backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    final progColor = _getProgressColor(context);
    final radius = borderRadius ?? 4.0;
    final animDuration = animationDuration ?? const Duration(milliseconds: 500);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: TweenAnimationBuilder<double>(
            duration: animDuration,
            tween: Tween<double>(begin: 0.0, end: clampedPercentage),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Container(
                height: barHeight,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: progColor,
                      borderRadius: BorderRadius.circular(radius),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (showPercentage || showStatus) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showPercentage)
                Text(
                  '${(percentage * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (showStatus)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: progColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: progColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: progColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getStatusText(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: progColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

