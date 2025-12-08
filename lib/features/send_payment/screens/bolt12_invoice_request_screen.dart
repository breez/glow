import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/send_payment/models/bolt12_invoice_request_state.dart';
import 'package:glow/features/send_payment/providers/bolt12_invoice_request_provider.dart';
import 'package:glow/features/send_payment/screens/bolt12_invoice_request_layout.dart';

/// Screen for BOLT12 Invoice Request payment (wiring layer)
///
/// This widget handles the business logic and state management,
/// delegating rendering to Bolt12InvoiceRequestLayout.
///
/// Note: This feature is not fully supported as Bolt12InvoiceRequestDetails
/// is an empty class in the SDK.
class Bolt12InvoiceRequestScreen extends ConsumerWidget {
  final Bolt12InvoiceRequestDetails requestDetails;

  const Bolt12InvoiceRequestScreen({required this.requestDetails, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Bolt12InvoiceRequestState state = ref.watch(bolt12InvoiceRequestProvider(requestDetails));

    return Bolt12InvoiceRequestLayout(
      requestDetails: requestDetails,
      state: state,
      onCancel: () {
        Navigator.of(context).pop();
      },
    );
  }
}
