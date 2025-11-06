import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/developers/developers_layout.dart';
import 'package:glow/features/developers/providers/max_deposit_fee_provider.dart';
import 'package:glow/features/developers/providers/network_provider.dart';
import 'package:glow/features/developers/widgets/max_fee_bottom_sheet.dart';
import 'package:glow/core/logging/app_logger.dart';
import 'package:glow/core/providers/sdk_provider.dart';
import 'package:share_plus/share_plus.dart';

class DevelopersScreen extends ConsumerWidget {
  const DevelopersScreen({super.key});

  void _showMaxFeeBottomSheet(BuildContext context, WidgetRef ref, Fee currentFee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => MaxFeeBottomSheet(
        currentFee: currentFee,
        onSave: (fee) async {
          try {
            await ref.read(maxDepositClaimFeeProvider.notifier).setFee(fee);

            // Invalidate SDK to reconnect with new fee
            ref.invalidate(sdkProvider);

            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Fee updated.'), duration: Duration(seconds: 2)));
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update: $e'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        },
        onReset: () async {
          await ref.read(maxDepositClaimFeeProvider.notifier).reset();
          ref.invalidate(sdkProvider);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reset to default.'), duration: Duration(seconds: 2)),
            );
          }
        },
      ),
    );
  }

  Future<void> _shareCurrentSession(BuildContext context) async {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preparing logs...')));
      }

      final zipFile = await AppLogger.createCurrentSessionZip();

      if (zipFile == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No logs to share')));
        }
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          subject: 'Glow - Current Session Logs',
          text: 'Debug logs from current session',
          files: [XFile(zipFile.path)],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share logs: $e')));
      }
    }
  }

  Future<void> _shareAllLogs(BuildContext context) async {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preparing logs...')));
      }

      final zipFile = await AppLogger.createAllLogsZip();

      if (zipFile == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No logs to share')));
        }
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          subject: 'Glow - All Session Logs',
          text: 'Debug logs from all sessions',
          files: [XFile(zipFile.path)],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share logs: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final network = ref.watch(networkProvider);
    final maxDepositClaimFee = ref.watch(maxDepositClaimFeeProvider);

    return DevelopersLayout(
      network: network,
      maxDepositClaimFee: maxDepositClaimFee,
      onTapMaxFeeCard: () => _showMaxFeeBottomSheet(context, ref, maxDepositClaimFee),
      onChangeNetwork: (Network network) => ref.read(networkProvider.notifier).setNetwork(network),
      onShareCurrentSession: () => _shareCurrentSession(context),
      onShareAllLogs: () => _shareAllLogs(context),
    );
  }
}
