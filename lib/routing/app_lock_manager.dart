import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/settings/providers/pin_provider.dart';
import 'package:glow/features/settings/services/pin_service.dart';
import 'package:glow/features/settings/widgets/pin_lock_screen.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:logger/logger.dart';

final Logger log = AppLogger.getLogger('AppLockManager');

/// Global navigator key for accessing Navigator from AppLockManager
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

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

  Future<void> _onAppResumed() async {
    log.d('App resumed - checking if PIN lock needed');

    final DateTime now = DateTime.now();

    // Get PIN service to read current values from storage
    final PinService pinService = ref.read(pinServiceProvider);

    // Read PIN status and lock interval directly from storage to ensure we get persisted values
    final bool isPinEnabled = await pinService.hasPin();
    final int lockIntervalSeconds = await pinService.getLockInterval();

    log.d('PIN enabled: $isPinEnabled, lock interval: $lockIntervalSeconds seconds');

    // If this is the first resume, initialize pause time and check if we should show lock
    if (_pauseTime == null) {
      _pauseTime = now;
      // On first app open/resume, show lock immediately if PIN is enabled
      if (isPinEnabled) {
        log.d('First app open with PIN enabled - will show PIN lock screen');
        _showPinLock();
      } else {
        log.d('First app open, no PIN enabled');
      }
      return;
    }

    final int secondsPaused = now.difference(_pauseTime!).inSeconds;

    log.d('Paused for $secondsPaused seconds, lock interval is $lockIntervalSeconds seconds');

    // Show lock if PIN is enabled and interval exceeded
    if (isPinEnabled && secondsPaused >= lockIntervalSeconds) {
      log.d('Lock interval exceeded - will show PIN lock screen');
      _showPinLock();
    } else {
      log.d('No PIN lock needed (interval not exceeded or PIN disabled)');
      _pauseTime = now;
    }
  }

  void _showPinLock() {
    // Ensure the widget is still mounted
    if (!mounted) {
      log.w('Widget not mounted, cannot show PIN lock');
      return;
    }

    // Use addPostFrameCallback to ensure Navigator is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        log.w('Widget not mounted after frame callback, cannot show PIN lock');
        return;
      }

      final NavigatorState? navigator = appNavigatorKey.currentState;
      if (navigator == null) {
        log.e('Navigator not available, cannot show PIN lock');
        return;
      }

      try {
        log.d('Pushing PIN lock screen to Navigator');
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => PinLockScreen(
              onUnlocked: () {
                _pauseTime = DateTime.now();
                log.d('PIN lock unlocked successfully');
              },
            ),
            fullscreenDialog: true,
          ),
        );
      } catch (e, stack) {
        log.e('Failed to show PIN lock screen', error: e, stackTrace: stack);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
