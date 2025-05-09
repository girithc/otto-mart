import 'dart:io';

import 'package:delivery/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // request permission from user (prompt)

    if (Platform.isIOS) {
      String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      print("APNS Token: $apnsToken");
    } else {
      await _firebaseMessaging.requestPermission();
      final FCMToken = await _firebaseMessaging.getToken();
      print('Token $FCMToken');
    }

    initPushNotifications();
  }

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    print('message not null');
    navigatorKey.currentState?.pushNamed('/order', arguments: message);
  }

  // initialize background settings
  Future initPushNotifications() async {
    // handle notification if app was terminated and now opened
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

    // atach even listeners for when a notification opens the app
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  }
}
