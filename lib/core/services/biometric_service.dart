import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _pinKey = 'app_pin';
  static const String _shouldCheckBiometricsKey = 'should_check_biometrics';
  static const _storage = FlutterSecureStorage();

  static Future<bool> isBiometricsAvailable() async {
    try {
      final isAvailable = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();

      if (isAvailable && isDeviceSupported) {
        final availableBiometrics = await _auth.getAvailableBiometrics();
        return availableBiometrics.isNotEmpty;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final biometrics = await _auth.getAvailableBiometrics();
      return biometrics;
    } catch (e) {
      return [];
    }
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Используйте Face ID для входа в приложение',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  static Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  static Future<String?> getPin() async {
    final pin = await _storage.read(key: _pinKey);
    return pin;
  }

  static Future<bool> isAppLocked() async {
    final prefs = await SharedPreferences.getInstance();
    final biometricsEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
    final shouldCheckBiometrics =
        prefs.getBool(_shouldCheckBiometricsKey) ?? false;
    final pin = await getPin();

    return pin != null && biometricsEnabled && shouldCheckBiometrics;
  }

  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
    final shouldCheck = prefs.getBool(_shouldCheckBiometricsKey) ?? false;

    return isEnabled && shouldCheck;
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  static Future<void> setShouldCheckBiometrics(bool shouldCheck) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shouldCheckBiometricsKey, shouldCheck);
  }

  static Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_biometricEnabledKey);
    await prefs.remove(_shouldCheckBiometricsKey);
    await _storage.delete(key: _pinKey);
  }
}
