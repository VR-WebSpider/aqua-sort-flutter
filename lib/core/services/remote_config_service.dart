import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_update/in_app_update.dart';

class RemoteConfigService {
  RemoteConfigService._();

  static const String currentVersionName = '1.2.1';
  static const int currentVersionCode = 9;

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<String, dynamic> _config = {};

  /// Initialize remote config and check for Google Play updates
  static Future<void> init() async {
    await fetchConfig();
    if (!kIsWeb) {
      // Run update check in background so it doesn't block app launch
      checkGooglePlayUpdate();
    }
  }

  /// Fetch remote configuration flags from Cloud Firestore
  static Future<void> fetchConfig() async {
    try {
      final snapshot = await _firestore.collection('app_config').get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('value')) {
          _config[doc.id] = data['value'];
        } else {
          _config.addAll(data);
        }
      }
      debugPrint("Remote Config loaded from Firestore: $_config");
    } catch (e) {
      debugPrint("Failed to fetch remote config: $e");
    }
  }

  /// Get boolean value from remote config
  static bool getBool(String key, bool defaultValue) {
    if (_config.containsKey(key)) {
      final val = _config[key];
      if (val is bool) return val;
      if (val is String) return val.toLowerCase() == 'true';
    }
    return defaultValue;
  }

  /// Get integer value from remote config
  static int getInt(String key, int defaultValue) {
    if (_config.containsKey(key)) {
      final val = _config[key];
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? defaultValue;
    }
    return defaultValue;
  }

  /// Get string value from remote config
  static String getString(String key, String defaultValue) {
    if (_config.containsKey(key)) {
      return _config[key]?.toString() ?? defaultValue;
    }
    return defaultValue;
  }

  /// Perform in-app update checks using Google Play Store APIs
  static Future<void> checkGooglePlayUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        final bool forceImmediate = getBool('force_immediate_update', false);

        if (forceImmediate && info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      debugPrint("Google Play in-app update check failed: $e");
    }
  }
}
