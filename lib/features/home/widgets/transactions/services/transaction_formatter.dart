import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';

/// Service for formatting transaction/payment-related values
/// Following Inversion of Control principle
class TransactionFormatter {
  const TransactionFormatter();

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

  /// Formats payment status for display
  String formatStatus(PaymentStatus status) {
    return switch (status) {
      PaymentStatus.completed => 'Completed',
      PaymentStatus.pending => 'Pending',
      PaymentStatus.failed => 'Failed',
    };
  }

  /// Formats payment type for display
  String formatType(PaymentType type) {
    return switch (type) {
      PaymentType.send => 'Send',
      PaymentType.receive => 'Receive',
    };
  }

  /// Formats payment method for display
  String formatMethod(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.lightning => 'Lightning',
      PaymentMethod.spark => 'Spark',
      PaymentMethod.token => 'Token',
      PaymentMethod.deposit => 'Deposit',
      PaymentMethod.withdraw => 'Withdraw',
      PaymentMethod.unknown => 'Unknown',
    };
  }

  /// Formats timestamp to relative time (e.g., "2 hours ago")
  String formatRelativeTime(BigInt timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Formats full timestamp
  String formatDateTime(BigInt timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000);
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Gets a short description for payment details
  String getShortDescription(PaymentDetails? details) {
    if (details == null) return '';

    return switch (details) {
      PaymentDetails_Lightning(:final description) => description ?? '',
      PaymentDetails_Token(:final metadata) => metadata.name,
      PaymentDetails_Withdraw() => 'On-chain withdrawal',
      PaymentDetails_Deposit() => 'On-chain deposit',
      PaymentDetails_Spark() => 'Spark payment',
    };
  }

  /// Formats amount with sign based on payment type
  String formatAmountWithSign(BigInt amount, PaymentType type) {
    final formattedAmount = formatSats(amount);
    return switch (type) {
      PaymentType.send => '-$formattedAmount',
      PaymentType.receive => '+$formattedAmount',
    };
  }
}
