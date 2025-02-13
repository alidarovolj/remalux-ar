import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _pinKey = 'app_pin';
  static const String _shouldCheckBiometricsKey = 'should_check_biometrics';
  static const _storage = FlutterSecureStorage();

  static Future<bool> isBiometricsAvailable() async {
    try {
      debugPrint('Checking biometrics availability...');
      final isAvailable = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      debugPrint(
          'Biometrics available: $isAvailable, Device supported: $isDeviceSupported');

      if (isAvailable && isDeviceSupported) {
        final availableBiometrics = await _auth.getAvailableBiometrics();
        debugPrint('Available biometrics: $availableBiometrics');
        return availableBiometrics.isNotEmpty;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking biometrics availability: $e');
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final biometrics = await _auth.getAvailableBiometrics();
      debugPrint('Available biometrics: $biometrics');
      return biometrics;
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  static Future<bool> authenticate() async {
    try {
      debugPrint('Starting biometric authentication...');
      return await _auth.authenticate(
        localizedReason: 'Используйте Face ID для входа в приложение',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      debugPrint('Authentication error: $e');
      return false;
    }
  }

  static Future<void> savePin(String pin) async {
    debugPrint('Saving PIN...');
    await _storage.write(key: _pinKey, value: pin);
    debugPrint('PIN saved successfully');
  }

  static Future<String?> getPin() async {
    debugPrint('Retrieving PIN...');
    final pin = await _storage.read(key: _pinKey);
    debugPrint('PIN retrieved: ${pin != null ? '[PIN EXISTS]' : 'null'}');
    return pin;
  }

  static Future<bool> isAppLocked() async {
    debugPrint('Checking if app is locked...');
    final prefs = await SharedPreferences.getInstance();
    final biometricsEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
    final shouldCheckBiometrics =
        prefs.getBool(_shouldCheckBiometricsKey) ?? false;
    final pin = await getPin();

    debugPrint(
        'App lock check - Biometrics enabled: $biometricsEnabled, Should check biometrics: $shouldCheckBiometrics, Has PIN: ${pin != null}');

    return pin != null && biometricsEnabled && shouldCheckBiometrics;
  }

  static Future<bool> isBiometricEnabled() async {
    debugPrint('Checking if biometrics is enabled in settings...');
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
    final shouldCheck = prefs.getBool(_shouldCheckBiometricsKey) ?? false;
    debugPrint('Biometrics enabled: $isEnabled, Should check: $shouldCheck');
    return isEnabled && shouldCheck;
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    debugPrint('Setting biometric enabled: $enabled');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  static Future<void> setShouldCheckBiometrics(bool shouldCheck) async {
    debugPrint('Setting should check biometrics: $shouldCheck');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shouldCheckBiometricsKey, shouldCheck);
  }

  static Future<void> clearSettings() async {
    debugPrint('Clearing all biometric and PIN settings...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_biometricEnabledKey);
    await prefs.remove(_shouldCheckBiometricsKey);
    await _storage.delete(key: _pinKey);
    debugPrint('All settings cleared');
  }
}
