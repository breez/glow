import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/settings/services/pin_service.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:logger/logger.dart';

final Logger log = AppLogger.getLogger('PinProvider');

/// Provider for PIN service
final Provider<PinService> pinServiceProvider = Provider<PinService>((Ref ref) => PinService());

/// Provider to check if PIN is set
final FutureProvider<bool> pinStatusProvider = FutureProvider<bool>((Ref ref) async {
  final PinService pinService = ref.read(pinServiceProvider);
  return pinService.hasPin();
});

/// Provider to check if biometrics is enabled
final FutureProvider<bool> biometricsEnabledProvider = FutureProvider<bool>((Ref ref) async {
  final PinService pinService = ref.read(pinServiceProvider);
  return pinService.isBiometricsEnabled();
});

final FutureProvider<int> pinLockIntervalProvider = FutureProvider<int>((Ref ref) async {
  final PinService pinService = ref.read(pinServiceProvider);
  return pinService.getLockInterval();
});
