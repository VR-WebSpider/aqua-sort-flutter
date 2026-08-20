import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class PushNotificationService {
  PushNotificationService._();

  static const String oneSignalAppId = 'b2c918e6-1234-5678-abcd-ef1234567890'; // Placeholder to be configured

  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.warn);
      OneSignal.initialize(oneSignalAppId);
      
      // Request push notification permissions automatically
      OneSignal.Notifications.requestPermission(true);
    } catch (e) {
      debugPrint("OneSignal initialization failed: $e");
    }
  }

  /// Map Supabase user ID to OneSignal for targeted push notifications
  static void setUserId(String userId) {
    if (kIsWeb) return;
    try {
      OneSignal.login(userId);
      debugPrint("OneSignal external ID linked: $userId");
    } catch (e) {
      debugPrint("OneSignal login failed: $e");
    }
  }

  /// Clear mapping on logout
  static void removeUserId() {
    if (kIsWeb) return;
    try {
      OneSignal.logout();
      debugPrint("OneSignal external ID cleared");
    } catch (e) {
      debugPrint("OneSignal logout failed: $e");
    }
  }
}
