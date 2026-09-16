import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../hydration/hydration_provider.dart';
import '../hydration/hydration_screen.dart';
import '../posture/posture_provider.dart';
import '../posture/posture_screen.dart';
import '../reports/reports_screen.dart';
import '../workout/workout_provider.dart';
import '../workout/workout_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  late final List<Widget> _screens = [
    _DashboardScreen(onViewReports: () => setState(() => _index = 4)),
    const HydrationScreen(),
    const WorkoutScreen(),
    const PostureScreen(),
    const ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: 'Hydration',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Workout',
          ),
          NavigationDestination(
            icon: Icon(Icons.accessibility_new_outlined),
            selectedIcon: Icon(Icons.accessibility_new),
            label: 'Posture',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}

class _DashboardScreen extends StatelessWidget {
  const _DashboardScreen({required this.onViewReports});

  final VoidCallback onViewReports;

  @override
  Widget build(BuildContext context) {
    final hydration = context.watch<HydrationProvider>();
    final workout = context.watch<WorkoutProvider>();
    final posture = context.watch<PostureProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('myFitness')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Today at a glance',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _SummaryCard(
            icon: Icons.water_drop,
            color: Colors.blue,
            title: 'Hydration',
            value: hydration.loaded
                ? '${hydration.todayTotalMl} / ${hydration.goalMl} ml'
                : '—',
            subtitle: hydration.loaded
                ? '${(hydration.progress * 100).round()}% of daily goal'
                : '',
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            icon: Icons.fitness_center,
            color: Colors.deepOrange,
            title: 'Workout',
            value: workout.loaded ? '${workout.todayTotalReps} reps' : '—',
            subtitle: workout.loaded
                ? '${workout.todaySets.length} sets completed today'
                : '',
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            icon: Icons.accessibility_new,
            color: Colors.teal,
            title: 'Posture',
            value: posture.loaded
                ? '${posture.todayGoodCount} good checks'
                : '—',
            subtitle: posture.loaded
                ? '${posture.todayAdjustedCount} adjustments today'
                : '',
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onViewReports,
            icon: const Icon(Icons.insights_outlined),
            label: const Text('View weekly / monthly report'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
