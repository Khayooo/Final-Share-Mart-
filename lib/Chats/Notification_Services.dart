import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationServices {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<String?> getDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      return token;
    } catch (e) {
      print("Error getting device token: $e");
      return null;
    }
  }

  void requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }
}
