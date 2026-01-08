import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/developers/providers/network_provider.dart';
import 'package:glow/features/transaction_filter/models/transaction_filter_state.dart';
import 'package:glow/features/transaction_filter/providers/transaction_filter_provider.dart';
import 'package:glow/features/transactions/providers/transaction_providers.dart';
import 'package:glow/features/transactions/services/csv_export_service.dart';
import 'package:glow/theme/dark_theme.dart';

class PaymentFilterExporter extends ConsumerWidget {
  const PaymentFilterExporter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData themeData = Theme.of(context);

    return PopupMenuButton<VoidCallback>(
      icon: Icon(Icons.more_vert, color: themeData.appBarTheme.iconTheme?.color),
      iconSize: 24.0,
      padding: EdgeInsets.zero,
      offset: const Offset(12, 24),
      onSelected: (VoidCallback action) => action(),
      itemBuilder: (BuildContext context) => <PopupMenuItem<VoidCallback>>[
        PopupMenuItem<VoidCallback>(
          height: 36,
          value: () async => await _exportPayments(context, ref),
          child: Text('Export payments', style: themeData.textTheme.labelLarge),
        ),
      ],
    );
  }

  Future<void> _exportPayments(BuildContext context, WidgetRef ref) async {
    try {
      final AsyncValue<List<Payment>> filteredPaymentsAsync = ref.read(filteredPaymentsProvider);
      final Network network = ref.read(networkProvider);

      if (!filteredPaymentsAsync.hasValue) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment data not available'),
              padding: kHomeScreenSnackBarPadding,
            ),
          );
        }
        return;
      }

      final List<Payment> filteredPayments = filteredPaymentsAsync.value!;

      // Check if filtered payment list is empty
      if (filteredPayments.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No payments match the current filter'),
              padding: kHomeScreenSnackBarPadding,
            ),
          );
        }
        return;
      }

      // GetInfoResponse doesn't expose pubkey/nodeId directly, use a placeholder
      final String nodeId = 'Node-${DateTime.now().millisecondsSinceEpoch}';
      final String networkName = network.toString().split('.').last;

      // Get current filter state
      final TransactionFilterState filterState = ref.read(transactionFilterProvider);

      const CsvExportService exportService = CsvExportService();
      await exportService.exportCsv(
        payments: filteredPayments,
        nodeId: nodeId,
        network: networkName,
        paymentTypeFilters: filterState.paymentTypes.isNotEmpty ? filterState.paymentTypes : null,
        startDate: filterState.startDate,
        endDate: filterState.endDate,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), padding: kHomeScreenSnackBarPadding),
        );
      }
    }
  }
}
