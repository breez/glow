import 'dart:async';
import 'package:flutter/material.dart';
import 'package:glow/features/qr_scan/qr_scan_layout.dart';
import 'package:glow/features/qr_scan/services/qr_code_parser.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

final Logger log = AppLogger.getLogger('QRScanView');

/// QR Scan View - handles setup and business logic coordination
/// - QRScanView: setup, lifecycle, and business logic coordination
/// - QRScanLayout: pure presentation widget
/// - QRCodeParser: validation/parsing logic (testable service)
class QRScanView extends StatefulWidget {
  const QRScanView({super.key});

  @override
  State<StatefulWidget> createState() => _QRScanViewState();
}

class _QRScanViewState extends State<QRScanView> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final QRCodeParser _parser = const QRCodeParser();
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _hasPopped = false;
  late StreamSubscription<BarcodeCapture> _barcodeSubscription;

  @override
  void initState() {
    super.initState();
    _barcodeSubscription = _cameraController.barcodes.listen(_onDetect);
  }

  @override
  void dispose() {
    _barcodeSubscription.cancel();
    _cameraController.dispose();
    super.dispose();
  }

  /// Handles barcode detection from camera
  void _onDetect(BarcodeCapture capture) {
    if (_hasPopped || !mounted) {
      log.i('Skipping detection - already popped or not mounted');
      return;
    }

    // Use parser service to extract code
    final String? code = _parser.extractCode(capture);

    if (_parser.isValidCode(code)) {
      log.i('QR code detected: $code');
      _popWithResult(code);
    } else {
      log.w('No valid QR code found in capture');
    }
  }

  /// Handles image picker button tap
  Future<void> _onImagePickerTap() async {
    log.i('Image picker tapped');

    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        log.i('No image selected');
        return;
      }

      final String filePath = image.path;
      log.i('Analyzing image: $filePath');

      final BarcodeCapture? barcodes = await _cameraController.analyzeImage(filePath);

      if (barcodes == null) {
        log.i('No QR code found in image');
        _showSnackBar('No QR code found in image');
      } else {
        _onDetect(barcodes);
      }
    } catch (error) {
      log.w('Error analyzing image', error: error);
      _showSnackBar('Failed to analyze image');
    }
  }

  /// Handles cancel button tap
  void _onCancel() {
    log.i('Scan cancelled by user');
    _popWithResult(null);
  }

  /// Pops navigation with result
  void _popWithResult(String? code) {
    if (_hasPopped || !mounted) {
      return;
    }

    _hasPopped = true;
    Navigator.of(context).pop(code);
  }

  /// Shows snackbar message
  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // Pure presentation widget - just UI
    return QRScanLayout(
      qrKey: qrKey,
      cameraController: _cameraController,
      onImagePickerTap: _onImagePickerTap,
      onCancel: _onCancel,
    );
  }
}
