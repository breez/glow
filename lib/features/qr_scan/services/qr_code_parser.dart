import 'package:mobile_scanner/mobile_scanner.dart';

/// Service for parsing and validating QR codes
/// Following Inversion of Control principle
class QRCodeParser {
  const QRCodeParser();

  /// Extracts the first valid code from barcode capture
  String? extractCode(BarcodeCapture capture) {
    for (final Barcode barcode in capture.barcodes) {
      final String? code = barcode.rawValue;
      if (isValidCode(code)) {
        return code;
      }
    }
    return null;
  }

  /// Validates if a scanned code is valid
  bool isValidCode(String? code) {
    return code != null && code.isNotEmpty;
  }

  /// Extracts display value (fallback to raw value)
  String? extractDisplayValue(Barcode barcode) {
    return barcode.displayValue ?? barcode.rawValue;
  }
}
