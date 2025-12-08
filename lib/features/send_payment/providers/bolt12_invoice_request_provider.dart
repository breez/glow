import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:glow/features/send_payment/models/bolt12_invoice_request_state.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('Bolt12InvoiceRequestNotifier');

/// Provider for BOLT12 invoice request payment state
///
/// This provider manages the state for sending a BOLT12 invoice request payment
final NotifierProviderFamily<
  Bolt12InvoiceRequestNotifier,
  Bolt12InvoiceRequestState,
  Bolt12InvoiceRequestDetails
>
bolt12InvoiceRequestProvider = NotifierProvider.autoDispose
    .family<Bolt12InvoiceRequestNotifier, Bolt12InvoiceRequestState, Bolt12InvoiceRequestDetails>(
      Bolt12InvoiceRequestNotifier.new,
    );

/// Notifier for BOLT12 invoice request payment flow
///
/// Note: This feature is not yet fully supported because Bolt12InvoiceRequestDetails
/// is an empty class in the SDK with no fields to work with.
class Bolt12InvoiceRequestNotifier extends Notifier<Bolt12InvoiceRequestState> {
  Bolt12InvoiceRequestNotifier(this.arg);
  final Bolt12InvoiceRequestDetails arg;

  @override
  Bolt12InvoiceRequestState build() {
    // Bolt12InvoiceRequestDetails is an empty class in the SDK
    // This feature is not yet fully supported
    _log.w('BOLT12 Invoice Request is not yet supported - SDK type has no fields');
    return const Bolt12InvoiceRequestError(
      message: 'BOLT12 Invoice Request is not yet fully supported',
      technicalDetails: 'The SDK Bolt12InvoiceRequestDetails type has no fields to work with',
    );
  }
}
