import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_fitness/app.dart';
import 'package:my_fitness/core/services/storage_service.dart';
import 'package:my_fitness/features/hydration/hydration_provider.dart';
import 'package:my_fitness/features/posture/posture_provider.dart';
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
        ],
        child: const MyFitnessApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('myFitness'), findsOneWidget);
    expect(find.text('Hydration'), findsWidgets);
    expect(find.text('Workout'), findsWidgets);
    expect(find.text('Posture'), findsWidgets);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Reports'));
    await tester.pumpAndSettle();

    expect(find.text('Reports'), findsWidgets);
    expect(find.text('Last week'), findsOneWidget);
    expect(find.text('Last month'), findsOneWidget);
  });
}
