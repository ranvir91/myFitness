import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';
import 'features/hydration/hydration_provider.dart';
import 'features/posture/posture_provider.dart';
import 'features/profile/profile_provider.dart';
import 'features/workout/workout_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.instance.init();
  await NotificationService.instance.requestPermissions();
  final storage = await StorageService.getInstance();

  runApp(
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
}
