import 'package:flutter/material.dart';
import 'package:faslapsapp/Pages/startup_page.dart';
import 'Services/tts_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterForegroundTask.initCommunicationPort();

  await TtsService.instance.initializeTTS();

  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'race_service',
      channelName: 'Race Service',
      channelDescription:
          'Keeps FasLaps connected during an active race.',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(
        5000,
      ),
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 7, 104, 222),
        ),
        useMaterial3: true,
      ),
      home: const StartupPage(),
    );
  }
}