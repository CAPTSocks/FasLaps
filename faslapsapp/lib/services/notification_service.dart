import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._privateConstructor();

  static final NotificationService instance =
      NotificationService._privateConstructor();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings, // Must use 'android:' named argument
      iOS: initializationSettingsDarwin, // Must use 'iOS:' named argument
    );

    await _notifications.initialize(settings: settings);

    // Request notification permission on Android 13+.
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Create the notification channel.
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'race_notifications',
      'Race Notifications',
      description: 'Notifications about upcoming races and race events.',
      importance: Importance.high,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<void> showNotification({
    required String title,
    required String message,
    int notificationId = 0,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'race_notifications',
          'Race Notifications',
          channelDescription:
              'Notifications about upcoming races and race events.',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      id: notificationId,
      title: title,
      body: message,
      notificationDetails: details,
    );
  }

  Future<void> showServerNotification(Map<String, dynamic> jsonData) async {
  final title = jsonData['title'];
  final message = jsonData['message'];
  final notificationId = jsonData['notificationId'];

  if (title is! String ||
      message is! String ||
      title.isEmpty ||
      message.isEmpty) {
    print('Invalid server notification received.');
    return;
  }

  await showNotification(
    title: title,
    message: message,
    notificationId: notificationId is int
        ? notificationId
        : 0,
  );
}

  Future<void> showTestNotification() async {
    await showNotification(
      title: 'FasLaps Test',
      message: 'Notifications are working!',
      notificationId: 999,
    );
  }
}
