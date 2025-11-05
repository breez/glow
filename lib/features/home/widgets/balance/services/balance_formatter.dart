/// Service for formatting balance-related values
class BalanceFormatter {
  const BalanceFormatter();

  /// Formats sats with thousand separators
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

  /// Formats sats to BTC with proper decimal places
  String formatBtc(BigInt sats) {
    final btc = sats.toDouble() / 100000000;
    return btc.toStringAsFixed(8);
  }

  /// Formats balance with currency suffix
  String formatBalanceWithUnit(BigInt sats, {BalanceUnit unit = BalanceUnit.sats}) {
    return switch (unit) {
      BalanceUnit.sats => '${formatSats(sats)} sats',
      BalanceUnit.btc => '${formatBtc(sats)} BTC',
    };
  }

  /// Converts sats to fiat using exchange rate
  String formatFiat(BigInt sats, double exchangeRate, String currencySymbol) {
    final btc = sats.toDouble() / 100000000;
    final fiatValue = btc * exchangeRate;
    return '$currencySymbol${fiatValue.toStringAsFixed(2)}';
  }
}

enum BalanceUnit { sats, btc }
