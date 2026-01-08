// test/features/qr_scan/qr_code_parser_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:glow/features/qr_scan/services/qr_code_parser.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  group('QRCodeParser', () {
    const QRCodeParser parser = QRCodeParser();

    test('validates non-empty codes as valid', () {
      expect(parser.isValidCode('lnbc123'), true);
      expect(parser.isValidCode('bitcoin:address'), true);
      expect(parser.isValidCode('any-string'), true);
    });

    test('validates empty or null codes as invalid', () {
      expect(parser.isValidCode(''), false);
      expect(parser.isValidCode(null), false);
    });

    test('extracts code from barcode capture with valid code', () {
      final Barcode barcode = const Barcode(rawValue: 'test-code', format: BarcodeFormat.qrCode);
      final BarcodeCapture capture = BarcodeCapture(barcodes: <Barcode>[barcode]);

      final String? code = parser.extractCode(capture);

      expect(code, 'test-code');
    });

    test('returns null from empty barcode capture', () {
      final BarcodeCapture capture = const BarcodeCapture();

      final String? code = parser.extractCode(capture);

      expect(code, null);
    });

    test('returns null from barcode capture with null values', () {
      final Barcode barcode = const Barcode(format: BarcodeFormat.qrCode);
      final BarcodeCapture capture = BarcodeCapture(barcodes: <Barcode>[barcode]);

      final String? code = parser.extractCode(capture);

      expect(code, null);
    });

    test('returns first valid code from multiple barcodes', () {
      final Barcode barcode1 = const Barcode(format: BarcodeFormat.qrCode);
      final Barcode barcode2 = const Barcode(rawValue: 'valid-code', format: BarcodeFormat.qrCode);
      final Barcode barcode3 = const Barcode(
        rawValue: 'another-code',
        format: BarcodeFormat.qrCode,
      );
      final BarcodeCapture capture = BarcodeCapture(
        barcodes: <Barcode>[barcode1, barcode2, barcode3],
      );

      final String? code = parser.extractCode(capture);

      expect(code, 'valid-code');
    });

    test('extracts display value when available', () {
      final Barcode barcode = const Barcode(
        rawValue: 'raw-value',
        displayValue: 'display-value',
        format: BarcodeFormat.qrCode,
      );

      final String? displayValue = parser.extractDisplayValue(barcode);

      expect(displayValue, 'display-value');
    });

    test('falls back to raw value when display value is null', () {
      final Barcode barcode = const Barcode(rawValue: 'raw-value', format: BarcodeFormat.qrCode);

      final String? displayValue = parser.extractDisplayValue(barcode);

      expect(displayValue, 'raw-value');
    });
  });
}
