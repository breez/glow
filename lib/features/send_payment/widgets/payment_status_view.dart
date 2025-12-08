import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/routing/app_routes.dart';
import 'package:logger/logger.dart';
import 'package:lottie/lottie.dart';

/// Widget that displays payment status (loading, success, error)
class PaymentStatusView extends StatelessWidget {
  final PaymentStatus status;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onDone;

  const PaymentStatusView({required this.status, this.errorMessage, this.onRetry, this.onDone, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final TextTheme textTheme = themeData.textTheme;

    return Stack(
      children: <Widget>[
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    _getTitle(),
                    style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 0.25),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Message
                if (status != PaymentStatus.success)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                    child: SizedBox(
                      height: 64.0,
                      child: Text(
                        _getMessage(),
                        style: textTheme.bodyLarge?.copyWith(
                          color: themeData.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // Icon
                _buildIcon(themeData),

                // Action button (for error retry or success done)
                if (status == PaymentStatus.error && onRetry != null) ...<Widget>[
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ] else if (status == PaymentStatus.success && onDone != null) ...<Widget>[
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: onDone,
                    icon: const Icon(Icons.check),
                    label: const Text('Done'),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (kDebugMode)
          Positioned(
            top: MediaQuery.of(context).viewInsets.top + 40.0,
            right: 16.0,
            child: CloseButton(
              color: Colors.white,
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.homeScreen, (Route<dynamic> route) => false);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildIcon(ThemeData themeData) {
    final Color iconContainerColor = themeData.canvasColor;
    switch (status) {
      case PaymentStatus.sending:
        return const PaymentProcessingAnimation();

      case PaymentStatus.success:
        return Lottie.asset(
          'assets/animations/lottie/payment_sent_dark.json',
          width: 128.0,
          height: 128.0,
          repeat: false,
          fit: BoxFit.fill,
        );

      case PaymentStatus.error:
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(color: iconContainerColor, shape: BoxShape.circle),
          child: Icon(Icons.error_outline, size: 48, color: iconContainerColor),
        );
    }
  }

  String _getTitle() {
    switch (status) {
      case PaymentStatus.sending:
        return 'Processing Payment';
      case PaymentStatus.success:
        return 'Payment Sent';
      case PaymentStatus.error:
        return 'Payment Failed';
    }
  }

  String _getMessage() {
    switch (status) {
      case PaymentStatus.sending:
        return 'Please wait while your payment is being processed...';
      case PaymentStatus.success:
        return '';
      case PaymentStatus.error:
        return errorMessage ?? 'An error occurred while sending the payment';
    }
  }
}

enum PaymentStatus { sending, success, error }

/// Displays the Lottie animation for payment processing.
class PaymentProcessingAnimation extends StatefulWidget {
  /// Creates a payment processing animation widget.
  const PaymentProcessingAnimation({super.key});

  @override
  State<PaymentProcessingAnimation> createState() => _PaymentProcessingAnimationState();
}

class _PaymentProcessingAnimationState extends State<PaymentProcessingAnimation> {
  static final Logger _logger = AppLogger.getLogger('PaymentProcessingAnimation');

  /// Maximum number of retry attempts for loading animation.
  static const int _maxRetryAttempts = 3;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Lottie.asset(
        'assets/animations/lottie/breez_loader.lottie',
        decoder: (List<int> bytes) => _decodeLottieFileWithRetry(bytes, _maxRetryAttempts),
        repeat: true,
        reverse: false,
        filterQuality: FilterQuality.high,
        fit: BoxFit.fill,
        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
          _logger.e('Failed to load Lottie animation', error: error, stackTrace: stackTrace);
          // Fallback to a simple CircularProgressIndicator if Lottie fails
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  /// Custom decoder for Lottie files with retry mechanism.
  ///
  /// Attempts to decode the Lottie file multiple times before giving up.
  Future<LottieComposition?> _decodeLottieFileWithRetry(List<int> bytes, int remainingAttempts) async {
    try {
      return await LottieComposition.decodeZip(bytes, filePicker: _selectLottieFileFromArchive);
    } catch (e, stackTrace) {
      if (remainingAttempts > 0) {
        _logger.w(
          'Error decoding Lottie ZIP file, retrying (${_maxRetryAttempts - remainingAttempts + 1}/$_maxRetryAttempts)',
          error: e,
          stackTrace: stackTrace,
        );
        // Add a small delay before retrying
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return _decodeLottieFileWithRetry(bytes, remainingAttempts - 1);
      }

      _logger.f(
        'Failed to decode Lottie ZIP file after $_maxRetryAttempts attempts',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow; // Let Lottie's error builder handle this after all retries are exhausted
    }
  }

  /// Selects the appropriate Lottie JSON file from the archive.
  ///
  /// Searches for JSON files in the 'animations/' directory.
  ArchiveFile _selectLottieFileFromArchive(List<ArchiveFile> files) {
    try {
      // Cache file list for diagnostics
      final List<String> fileNames = files.map((ArchiveFile f) => f.name).toList();
      _logger.f('Archive contains ${files.length} files: ${fileNames.join(", ")}');

      return files.firstWhere(
        (ArchiveFile f) => f.name.startsWith('animations/') && f.name.endsWith('.json'),
        orElse: () {
          final String availableFiles = fileNames.join(', ');
          throw Exception('No Lottie animation file found in the archive. Available files: $availableFiles');
        },
      );
    } catch (e, stackTrace) {
      _logger.w('Failed to select Lottie file from archive', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
