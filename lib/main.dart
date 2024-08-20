// ignore_for_file: depend_on_referenced_packages
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import 'package:sound_mode/permission_handler.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Configure local notifications
Future<void> _configureNotifications() async {
  const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('launch_background'),
      iOS: DarwinInitializationSettings());
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

// Show notification with custom sound
Future<void> showNotification(String title, String body) async {
  AndroidNotificationDetails androidPlatformSpecificDetails =
      AndroidNotificationDetails(
    'important_notifications',
    'Important Notifications',
    importance: Importance.max,
    priority: Priority.high,
    enableVibration: true,
    playSound: true,
    sound: const RawResourceAndroidNotificationSound("yourmp3files"),
    additionalFlags: Int32List.fromList([4]),
  ); // Replace with your sound file

  NotificationDetails platformSpecificDetails = NotificationDetails(
      android: androidPlatformSpecificDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ));

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformSpecificDetails,
  );

  // Optionally, revert to the previous sound mode after a short delay
  Future.delayed(const Duration(seconds: 5), () async {
    RingerModeStatus currentMode = await SoundMode.ringerModeStatus;
    if (currentMode != RingerModeStatus.silent) {
      await SoundMode.setSoundMode(RingerModeStatus.silent);
    }
  });
}

void handleNotificationTap() async {
  // Handle notification tap action (optional)
}

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  // Handle FCM messages received in the background
  // ...
  await Firebase.initializeApp();
  await showNotification(message.notification?.title ?? 'No Title',
      message.notification?.body ?? 'No Body');

  // Schedule notification based on message content and platform-specific settings
}

void showTestNotification() async {
  if (Platform.isAndroid) {
    try {
      // Change the sound mode to normal before showing the notification
      await SoundMode.setSoundMode(RingerModeStatus.normal);
    } catch (e) {
      print('Error changing sound mode to normal: $e');
    }
  }

  const String notificationChannelId = 'important_notifications';
  AndroidNotificationDetails androidPlatformSpecificDetails =
      const AndroidNotificationDetails(
          notificationChannelId, 'Important Notifications',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          enableLights: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          playSound: true,
          sound: RawResourceAndroidNotificationSound("yourmp3files"));

  NotificationDetails platformSpecificDetails = NotificationDetails(
      android: androidPlatformSpecificDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ));

  if (kDebugMode) {
    print('showTestNotification');
  }
  // Schedule notification
  await flutterLocalNotificationsPlugin.show(
      0, // Unique notification ID
      'Test Notification Title',
      'This is a test notification with sound.',
      platformSpecificDetails);

  if (Platform.isAndroid) {
    // Optionally, revert to the previous sound mode after a short delay
    Future.delayed(const Duration(seconds: 5), () async {
      try {
        await SoundMode.setSoundMode(RingerModeStatus.silent);
      } catch (e) {
        print('Error changing sound mode to silent: $e');
      }
    });
  }
}

// Request notification permissions
Future<void> requestNotificationPermissions() async {
  final PermissionStatus notificationStatus =
      await Permission.notification.request();
  final PermissionStatus dndStatus =
      await Permission.accessNotificationPolicy.request();
  if (notificationStatus.isGranted && dndStatus.isGranted) {
    // Notification permissions granted
  } else if (notificationStatus.isDenied || dndStatus.isDenied) {
    // Notification permissions denied
  } else if (notificationStatus.isPermanentlyDenied ||
      dndStatus.isPermanentlyDenied) {
    // Notification permissions permanently denied, open app settings
    await openAppSettings();
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await handleBackgroundMessage(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  await requestNotificationPermissions();
  await _configureNotifications();

  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
  //   if (message != null) {
  //     handleNotificationTap();
  //   }
  // });

  // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //   showNotification(message.notification?.title ?? 'No Title',
  //       message.notification?.body ?? 'No Body');
  // });

  // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  //   handleNotificationTap();
  // });

  Future.delayed(const Duration(seconds: 5), showTestNotification);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  RingerModeStatus _soundMode = RingerModeStatus.unknown;
  String? _permissionStatus;

  @override
  void initState() {
    super.initState();
    _getCurrentSoundMode();
    _getPermissionStatus();
  }

  Future<void> _getCurrentSoundMode() async {
    RingerModeStatus ringerStatus = RingerModeStatus.unknown;

    Future.delayed(const Duration(seconds: 1), () async {
      try {
        ringerStatus = await SoundMode.ringerModeStatus;
      } catch (err) {
        ringerStatus = RingerModeStatus.unknown;
      }

      setState(() {
        _soundMode = ringerStatus;
      });
    });
  }

  Future<void> _getPermissionStatus() async {
    bool? permissionStatus = false;
    try {
      permissionStatus = await PermissionHandler.permissionsGranted;
      print(permissionStatus);
    } catch (err) {
      print(err);
    }

    setState(() {
      _permissionStatus =
          permissionStatus! ? "Permissions Enabled" : "Permissions not granted";
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Hello World'),
                Text('Current Sound Mode: $_soundMode'),
                Text('Permission Status: $_permissionStatus'),
              ],
            ),
          ),
        ));
  }
}
