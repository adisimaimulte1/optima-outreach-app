import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

class PushNotificationService {
  static Future<bool> initialize({required Function onHardDenied}) async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.getNotificationSettings();

    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      settings = await messaging.requestPermission();
    }

    if (settings.authorizationStatus == AuthorizationStatus.denied ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      onHardDenied();
      return false;
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await messaging.getToken();

      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({'fcmToken': token});
      }

      return true;
    }

    return false;
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }

  static Future<void> disableNotifications() async {
    await FirebaseMessaging.instance.deleteToken();
  }
}
