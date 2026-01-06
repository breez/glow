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

    final DateTime now = DateTime.now();

    // Get PIN status and lock interval (in seconds)
    final bool isPinEnabled = ref.read(pinStatusProvider).value ?? false;
    final int lockIntervalSeconds = ref.read(pinLockIntervalProvider).value ?? 300;

    // If this is the first resume, initialize pause time and check if we should show lock
    if (_pauseTime == null) {
      _pauseTime = now;
      // On first app open/resume, show lock immediately if PIN is enabled
      if (isPinEnabled) {
        log.d('First app open with PIN enabled - showing PIN lock screen');
        _showPinLock();
      }
      return;
    }

    final int secondsPaused = now.difference(_pauseTime!).inSeconds;

    log.d('Paused for $secondsPaused seconds, lock interval is $lockIntervalSeconds seconds');

    // Show lock if PIN is enabled and interval exceeded
    if (isPinEnabled && secondsPaused >= lockIntervalSeconds) {
      log.d('Showing PIN lock screen');
      _showPinLock();
    } else {
      log.d('No PIN lock needed');
      _pauseTime = now;
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
