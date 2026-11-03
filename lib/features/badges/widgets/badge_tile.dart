import 'package:flutter/material.dart';

import '../badge_engine.dart';

class BadgeTile extends StatelessWidget {
  const BadgeTile({super.key, required this.badge});

  final BadgeDefinition badge;

  Color _moduleColor(BadgeModule module) {
    return switch (module) {
      BadgeModule.hydration => Colors.blue,
      BadgeModule.workout => Colors.deepOrange,
      BadgeModule.posture => Colors.teal,
      BadgeModule.overall => Colors.purple,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _moduleColor(badge.module);
    final unlocked = badge.unlocked;

    return Opacity(
      opacity: unlocked ? 1 : 0.55,
      child: Card(
        color: scheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor:
                    unlocked ? color.withValues(alpha: 0.15) : scheme.surfaceContainerHighest,
                child: Icon(
                  unlocked ? badge.icon : Icons.lock_outline,
                  color: unlocked ? color : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                badge.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                unlocked ? badge.description : (badge.progress ?? badge.description),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
