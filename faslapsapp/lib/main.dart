import 'package:flutter/material.dart';
import 'package:faslapsapp/Pages/startup_page.dart';
import 'Services/tts_service.dart';
import 'services/notification_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';


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
      theme: ThemeData.dark().copyWith(
        appBarTheme: AppBarTheme(
          centerTitle: true,

          iconTheme: const IconThemeData(
            color: Color.fromARGB(255, 225, 115, 6),
          ),

          actionsIconTheme: const IconThemeData(color: Colors.white),
        ),

        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey.shade800,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
          ),
        ),

        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color.fromRGBO(23, 43, 61, 1),
            foregroundColor: Colors.white,

            elevation: 3,

            shadowColor: const Color.fromARGB(255, 225, 115, 6),

            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color.fromARGB(255, 234, 102, 30), width: 2),
            ),

            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
      home: const StartupPage(),
    );
  }
}
