import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

void setupNotificationListeners() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Get the device token after permissions are granted
  await getDeviceToken();

  // Listen for token refresh
  messaging.onTokenRefresh.listen((newToken) {
    debugPrint("Token refreshed: $newToken");
  });

  // Handle foreground notifications
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
  });

  // Handle notifications that open the app
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('Opened from notification: ${message.notification?.title}');
  });
}

Future<void> getDeviceToken() async {
  try {
    // Get the FCM token
    String? fcmToken = await FirebaseMessaging.instance.getToken();

    // For iOS, explicitly request APNS token first
    if (Platform.isIOS) {
      String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      debugPrint('APNS Token: $apnsToken');
    }

    debugPrint('FCM Token: $fcmToken');
  } catch (e) {
    debugPrint('Error getting device token: $e');
  }
}
