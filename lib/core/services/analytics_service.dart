import 'package:amplitude_flutter/amplitude.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final Amplitude _amplitude = Amplitude.getInstance();
  static bool _isInitialized = false;

  static Future<void> init(String apiKey) async {
    if (_isInitialized) return;

    try {
      await _amplitude.init(apiKey);
      await _amplitude.enableCoppaControl();
      await _amplitude.setUserId(null);
      await _amplitude.trackingSessionEvents(true);
      _isInitialized = true;
      debugPrint('Amplitude initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Amplitude: $e');
    }
  }

  static Future<void> setUserId(String userId) async {
    try {
      await _amplitude.setUserId(userId);
      debugPrint('Amplitude user ID set: $userId');
    } catch (e) {
      debugPrint('Error setting Amplitude user ID: $e');
    }
  }

  static Future<void> logEvent(String eventName,
      {Map<String, dynamic>? properties}) async {
    try {
      await _amplitude.logEvent(
        eventName,
        eventProperties: properties,
      );
      debugPrint(
          'Amplitude event logged: $eventName with properties: $properties');
    } catch (e) {
      debugPrint('Error logging Amplitude event: $e');
    }
  }

  static Future<void> setUserProperties(Map<String, dynamic> properties) async {
    try {
      await _amplitude.setUserProperties(properties);
      debugPrint('Amplitude user properties set: $properties');
    } catch (e) {
      debugPrint('Error setting Amplitude user properties: $e');
    }
  }
}
