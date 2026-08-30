import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(
    RaceTaskHandler(),
  );
}

class RaceTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(
    DateTime timestamp,
    TaskStarter starter,
  ) async {
    print("FasLaps background service started");
  }



static Future<void> requestPermissions() async {
  final permission =
      await FlutterForegroundTask.checkNotificationPermission();

  if (permission != NotificationPermission.granted) {
    await FlutterForegroundTask.requestNotificationPermission();
  }
}

  @override
  void onRepeatEvent(DateTime timestamp) {
    print("FasLaps background service is running");
  }

  @override
  Future<void> onDestroy(
    DateTime timestamp,
    bool isTimeout,
  ) async {
    print("FasLaps background service stopped");
  }

  @override
  void onNotificationButtonPressed(String id) {
    print("Notification button pressed: $id");

    if (id == 'stop') {
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onReceiveData(Object data) {
    print("Received data from app: $data");
  }
}

class BackgroundRaceService {
  static Future<void> requestPermissions() async {
    final permission =
        await FlutterForegroundTask.checkNotificationPermission();

    if (permission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  static Future<void> start() async {
    if (await FlutterForegroundTask.isRunningService) {
      print("FasLaps background service is already running.");
      return;
    }

    final result =
        await FlutterForegroundTask.startService(
      serviceId: 100,
      notificationTitle: 'FasLaps Race',
      notificationText: 'Race monitoring is active.',
      callback: startCallback,
    );

    print("Foreground service result: $result");
  }

  static Future<void> stop() async {
    final result =
        await FlutterForegroundTask.stopService();

    print("Foreground service stop result: $result");
  }
}