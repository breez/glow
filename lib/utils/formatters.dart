/// Utility functions for formatting values
library;

/// Format sats with thousand separators
String formatSats(BigInt sats) {
  final str = sats.toString();
  final buffer = StringBuffer();
  final length = str.length;

  for (int i = 0; i < length; i++) {
    buffer.write(str[i]);
    final position = length - i - 1;
    if (position > 0 && position % 3 == 0) {
      buffer.write(',');
    }
  }

  return buffer.toString();
}

/// Format sats to BTC (8 decimal places)
String formatSatsToBtc(BigInt sats) {
  final btc = sats.toDouble() / 100000000;
  return btc.toStringAsFixed(8);
}

/// Parse sats string with commas removed
BigInt? parseSats(String input) {
  return BigInt.tryParse(input.replaceAll(',', ''));
}
