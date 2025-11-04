import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';

/// Service responsible for formatting payment data for display
class PaymentFormatter {
  const PaymentFormatter();

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

  String formatStatus(PaymentStatus status) {
    return switch (status) {
      PaymentStatus.completed => 'Completed',
      PaymentStatus.pending => 'Pending',
      PaymentStatus.failed => 'Failed',
    };
  }

  String formatType(PaymentType type) {
    return switch (type) {
      PaymentType.send => 'Send',
      PaymentType.receive => 'Receive',
    };
  }

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

  String formatDate(BigInt timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000);
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
