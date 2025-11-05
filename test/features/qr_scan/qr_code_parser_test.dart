// test/features/qr_scan/qr_code_parser_test.dart

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:glow/features/qr_scan/services/qr_code_parser.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  group('QRCodeParser', () {
    const parser = QRCodeParser();

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
      final barcode = Barcode(rawValue: 'test-code', format: BarcodeFormat.qrCode);
      final capture = BarcodeCapture(barcodes: [barcode], image: null, size: Size.zero);

      final code = parser.extractCode(capture);

      expect(code, 'test-code');
    });

    test('returns null from empty barcode capture', () {
      final capture = BarcodeCapture(barcodes: [], image: null, size: Size.zero);

      final code = parser.extractCode(capture);

      expect(code, null);
    });

    test('returns null from barcode capture with null values', () {
      final barcode = Barcode(rawValue: null, format: BarcodeFormat.qrCode);
      final capture = BarcodeCapture(barcodes: [barcode], image: null, size: Size.zero);

      final code = parser.extractCode(capture);

      expect(code, null);
    });

    test('returns first valid code from multiple barcodes', () {
      final barcode1 = Barcode(rawValue: null, format: BarcodeFormat.qrCode);
      final barcode2 = Barcode(rawValue: 'valid-code', format: BarcodeFormat.qrCode);
      final barcode3 = Barcode(rawValue: 'another-code', format: BarcodeFormat.qrCode);
      final capture = BarcodeCapture(barcodes: [barcode1, barcode2, barcode3], image: null, size: Size.zero);

      final code = parser.extractCode(capture);

      expect(code, 'valid-code');
    });

    test('extracts display value when available', () {
      final barcode = Barcode(
        rawValue: 'raw-value',
        displayValue: 'display-value',
        format: BarcodeFormat.qrCode,
      );

      final displayValue = parser.extractDisplayValue(barcode);

      expect(displayValue, 'display-value');
    });

    test('falls back to raw value when display value is null', () {
      final barcode = Barcode(rawValue: 'raw-value', displayValue: null, format: BarcodeFormat.qrCode);

      final displayValue = parser.extractDisplayValue(barcode);

      expect(displayValue, 'raw-value');
    });
  });
}
