import 'package:flutter/material.dart';
import 'package:yafintech/core/theme/app_theme.dart';

class YafiBrand extends StatelessWidget {
  const YafiBrand({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final markSize = compact ? 32.0 : 48.0;
    final textStyle = compact
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.titleLarge;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: markSize,
          height: markSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(compact ? 10 : 15),
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: compact ? 18 : 25,
          ),
        ),
        const SizedBox(width: 10),
        Text('YAFINTECH', style: textStyle),
      ],
    );
  }
}

class AuthPageHeading extends StatelessWidget {
  const AuthPageHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.step,
    this.totalSteps,
  });

  final String title;
  final String subtitle;
  final int? step;
  final int? totalSteps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasProgress = step != null && totalSteps != null && totalSteps! > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 7),
        Text(subtitle, style: theme.textTheme.bodyMedium),
        if (hasProgress) ...[
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: step! / totalSteps!,
              minHeight: 5,
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.12,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text('Étape $step sur $totalSteps', style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}

class AuthProgressIndicator extends StatelessWidget {
  const AuthProgressIndicator({
    super.key,
    required this.step,
    this.totalSteps = 6,
  });

  final int step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final safeTotal = totalSteps < 1 ? 1 : totalSteps;
    final value = (step / safeTotal).clamp(0.0, 1.0).toDouble();
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          'Étape $step sur $safeTotal',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 5,
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
