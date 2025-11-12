/// Utility functions for formatting values
library;

/// Formats a BigInt satoshi amount with thousand separators
///
/// Example: 1234567 -> "1,234,567"
String formatSats(BigInt sats) {
  final String str = sats.toString();
  final StringBuffer buffer = StringBuffer();
  final int length = str.length;

  for (int i = 0; i < length; i++) {
    buffer.write(str[i]);
    final int position = length - i - 1;
    if (position > 0 && position % 3 == 0) {
      buffer.write(',');
    }
  }

  return buffer.toString();
}

/// Format sats to BTC (8 decimal places)
String formatSatsToBtc(BigInt sats) {
  final double btc = sats.toDouble() / 100000000;
  return btc.toStringAsFixed(8);
}

/// Parse sats string with commas removed
BigInt? parseSats(String input) {
  return BigInt.tryParse(input.replaceAll(',', ''));
}

/// Formats a Unix timestamp into a human-readable relative time string
///
/// Returns:
/// - "Today" if the date is today
/// - "Yesterday" if the date was yesterday
/// - "N days ago" if within the last week
/// - "Mon DD" for older dates
String formatTimestamp(BigInt timestamp) {
  final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000);
  final DateTime now = DateTime.now();
  final Duration diff = now.difference(date);

  if (diff.inDays == 0) {
    return 'Today';
  } else if (diff.inDays == 1) {
    return 'Yesterday';
  } else if (diff.inDays < 7) {
    return '${diff.inDays} days ago';
  } else {
    return _formatShortDate(date);
  }
}

/// Formats a date as "Mon DD" (e.g., "Jan 15")
String _formatShortDate(DateTime date) {
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}
