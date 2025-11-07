import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/qr_scan/widgets/scan_overlay.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Pure presentation widget for QR scan view
class QRScanLayout extends StatelessWidget {
  const QRScanLayout({
    super.key,
    required this.qrKey,
    required this.cameraController,
    required this.onImagePickerTap,
    required this.onCancel,
  });

  final GlobalKey qrKey;
  final MobileScannerController cameraController;
  final VoidCallback onImagePickerTap;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: MobileScanner(key: qrKey, controller: cameraController),
          ),
          const ScanOverlay(),
          SafeArea(
            child: Stack(
              children: <Widget>[
                Positioned(right: 10, top: 5, child: _ImagePickerIcon(onImagePickerTap: onImagePickerTap)),
                if (defaultTargetPlatform == TargetPlatform.iOS)
                  Positioned(bottom: 30.0, right: 0, left: 0, child: _CancelButton(onCancel: onCancel)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePickerIcon extends StatelessWidget {
  const _ImagePickerIcon({required this.onImagePickerTap});

  final VoidCallback onImagePickerTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: const EdgeInsets.fromLTRB(0, 32, 24, 0),
      icon: const Icon(Icons.photo_outlined),
      onPressed: onImagePickerTap,
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onCancel});

  final VoidCallback onCancel;

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
          onPressed: onCancel,
          child: const Text('CANCEL', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
