import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_fitness/app.dart';
import 'package:my_fitness/core/services/storage_service.dart';
import 'package:my_fitness/features/hydration/hydration_provider.dart';
import 'package:my_fitness/features/posture/posture_provider.dart';
import 'package:my_fitness/features/profile/profile_provider.dart';
import 'package:my_fitness/features/workout/workout_provider.dart';

void main() {
  setUp(() {
    // In-memory shared_preferences.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App loads with the home dashboard and bottom nav',
      (WidgetTester tester) async {
    final storage = await StorageService.getInstance();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => HydrationProvider(storage)),
          ChangeNotifierProvider(create: (_) => WorkoutProvider(storage)),
          ChangeNotifierProvider(create: (_) => PostureProvider(storage)),
          ChangeNotifierProvider(create: (_) => ProfileProvider(storage)),
        ],
        child: const MyFitnessApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fit Myself'), findsOneWidget);
    expect(find.text('Hydration'), findsWidgets);
    expect(find.text('Workout'), findsWidgets);
    expect(find.text('Posture'), findsWidgets);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Reports'));
    await tester.pumpAndSettle();

    expect(find.text('Reports'), findsWidgets);
    expect(find.text('Last week'), findsOneWidget);
    expect(find.text('Last month'), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Workout'));
    await tester.pumpAndSettle();

    // Default seeded exercises show up as checklist items.
    expect(find.text('Push-ups'), findsOneWidget);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add exercise'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ActionChip, 'Plank'));
    await tester.pumpAndSettle();

    expect(find.text('Plank'), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Home'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Badges'));
    await tester.pumpAndSettle();
    expect(find.text('Badges'), findsWidgets);
    expect(find.textContaining('unlocked'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsWidgets);
    expect(find.text('Log weight'), findsOneWidget);
  });
}
