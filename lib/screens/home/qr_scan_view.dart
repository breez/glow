import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/widgets/home/scan_overlay.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

final log = AppLogger.getLogger('QRScanView');

class QRScanView extends StatefulWidget {
  const QRScanView({super.key});

  @override
  State<StatefulWidget> createState() => QRScanViewState();
}

class QRScanViewState extends State<QRScanView> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool popped = false;
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  late StreamSubscription<BarcodeCapture> _barcodeSubscription;

  @override
  void initState() {
    super.initState();
    _barcodeSubscription = cameraController.barcodes.listen(onDetect);
  }

  void onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final Barcode barcode in barcodes) {
      log.i('Barcode detected. ${barcode.displayValue}');
      if (popped || !mounted) {
        log.i('Skipping, already popped or not mounted');
        return;
      }
      final String? code = barcode.rawValue;
      if (code == null) {
        log.w('Failed to scan QR code.');
      } else {
        popped = true;
        log.i('Popping read QR code: $code');
        Navigator.of(context).pop(code);
      }
    }
  }

  @override
  void dispose() {
    _barcodeSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Column(
              children: <Widget>[
                Expanded(
                  flex: 5,
                  child: MobileScanner(key: qrKey, controller: cameraController),
                ),
              ],
            ),
          ),
          const ScanOverlay(),
          SafeArea(
            child: Stack(
              children: <Widget>[
                Positioned(
                  right: 10,
                  top: 5,
                  child: ImagePickerButton(cameraController: cameraController, onDetect: onDetect),
                ),
                if (defaultTargetPlatform == TargetPlatform.iOS) ...<Widget>[
                  const Positioned(bottom: 30.0, right: 0, left: 0, child: QRScanCancelButton()),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ImagePickerButton extends StatelessWidget {
  final MobileScannerController cameraController;
  final void Function(BarcodeCapture capture) onDetect;

  const ImagePickerButton({required this.cameraController, required this.onDetect, super.key});

  @override
  Widget build(BuildContext context) {
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);

    return IconButton(
      padding: const EdgeInsets.fromLTRB(0, 32, 24, 0),
      icon: const Icon(Icons.photo_outlined),
      onPressed: () async {
        final ImagePicker picker = ImagePicker();

        final XFile? image = await picker.pickImage(source: ImageSource.gallery).catchError((Object err) {
          log.w('Failed to pick image', error: err);
          return null;
        });

        if (image == null) {
          return;
        }

        final String filePath = image.path;
        log.i('Picked image: $filePath');

        final BarcodeCapture? barcodes = await cameraController.analyzeImage(filePath).catchError((
          Object err,
        ) {
          log.w('Failed to analyze image', error: err);
          return null;
        });

        if (barcodes == null) {
          log.i('No QR code found in image');
          scaffoldMessenger.showSnackBar(SnackBar(content: Text('No QR code found in image')));
        } else {
          onDetect(barcodes);
        }
      },
    );
  }
}

class QRScanCancelButton extends StatelessWidget {
  const QRScanCancelButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(12.0)),
          border: Border.all(color: Colors.white.withValues(alpha: .8)),
        ),
        child: TextButton(
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 35)),
          onPressed: () => Navigator.of(context).pop(),
          child: Text('CANCEL', style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
