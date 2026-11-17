import 'package:flutter/material.dart';
import 'package:faslapsapp/Pages/startup_page.dart';
import 'Services/tts_service.dart';
import 'services/notification_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'Theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.instance.initialize();

  FlutterForegroundTask.initCommunicationPort();

  await TtsService.instance.initializeTTS();

  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'race_service',
      channelName: 'Race Service',
      channelDescription: 'Keeps FasLaps connected during an active race.',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(5000),
    ),
  );

  runApp(const FasLapsQRApp());
}

class FasLapsQRApp extends StatelessWidget {
  const FasLapsQRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FasLaps QR Reader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const StartupPage(),
    );
  }
}
