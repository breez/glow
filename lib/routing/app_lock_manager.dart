import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/settings/providers/pin_provider.dart';
import 'package:glow/features/settings/widgets/pin_lock_screen.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:logger/logger.dart';

final Logger log = AppLogger.getLogger('AppLockManager');

/// Manages app-level PIN lock on resume
/// Shows PIN lock screen if user paused app longer than configured interval
class AppLockManager extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockManager({required this.child, super.key});

  @override
  ConsumerState<AppLockManager> createState() => _AppLockManagerState();
}

class _AppLockManagerState extends ConsumerState<AppLockManager> {
  late final AppLifecycleListener _listener;
  DateTime? _pauseTime;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onStateChange: _onAppLifecycleStateChanged);
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  void _onAppLifecycleStateChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _onAppPaused();
      case AppLifecycleState.resumed:
        _onAppResumed();
      default:
        break;
    }
  }

  void _onAppPaused() {
    log.d('App paused - recording time');
    _pauseTime = DateTime.now();
  }

  void _onAppResumed() {
    log.d('App resumed - checking if PIN lock needed');

    // Don't show lock if this is the first resume
    if (_pauseTime == null) {
      _pauseTime = DateTime.now();
      return;
    }

    final DateTime now = DateTime.now();
    final int secondsPaused = now.difference(_pauseTime!).inSeconds;

    // Get PIN status and lock interval
    final bool isPinEnabled = ref.read(pinStatusProvider).value ?? false;
    final int lockInterval = ref.read(pinLockIntervalProvider).value ?? 5;

    // Convert interval to seconds based on dropdown values
    // 0 = immediate, 1 = 30 seconds, 2 = 2 minutes, 5 = 5 minutes, etc.
    final int lockSeconds = _convertIntervalToSeconds(lockInterval);

    log.d('Paused for $secondsPaused seconds, lock interval is $lockSeconds seconds');

    // Show lock if PIN is enabled and interval exceeded
    if (isPinEnabled && secondsPaused >= lockSeconds) {
      log.d('Showing PIN lock screen');
      _showPinLock();
    } else {
      log.d('No PIN lock needed');
      _pauseTime = now;
    }
  }

  int _convertIntervalToSeconds(int interval) {
    switch (interval) {
      case 0:
        return 0; // Immediate
      case 1:
        return 30; // 30 seconds
      case 2:
        return 120; // 2 minutes
      case 5:
        return 300; // 5 minutes
      case 10:
        return 600; // 10 minutes
      case 30:
        return 1800; // 30 minutes
      case 60:
        return 3600; // 1 hour
      default:
        return 300; // Default to 5 minutes
    }
  }

  void _showPinLock() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PinLockScreen(
          onUnlocked: () {
            _pauseTime = DateTime.now();
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
