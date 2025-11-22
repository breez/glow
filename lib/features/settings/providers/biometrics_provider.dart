import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Provider to check if device supports biometrics
final FutureProvider<bool> biometricsAvailableProvider = FutureProvider<bool>((Ref ref) async {
  try {
    final LocalAuthentication localAuth = LocalAuthentication();
    final bool canCheckBiometrics = await localAuth.canCheckBiometrics;
    final bool isDeviceSupported = await localAuth.isDeviceSupported();
    return canCheckBiometrics && isDeviceSupported;
  } catch (_) {
    return false;
  }
});

/// Provider to get the available biometric type label
final FutureProvider<String> biometricTypeProvider = FutureProvider<String>((Ref ref) async {
  try {
    final LocalAuthentication localAuth = LocalAuthentication();
    final List<BiometricType> availableBiometrics = await localAuth.getAvailableBiometrics();

    if (availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Touch ID';
    } else if (availableBiometrics.contains(BiometricType.iris)) {
      return 'Iris';
    } else if (availableBiometrics.contains(BiometricType.strong) ||
        availableBiometrics.contains(BiometricType.weak)) {
      return 'Biometrics';
    }
    return 'Biometrics';
  } catch (_) {
    return 'Biometrics';
  }
});
