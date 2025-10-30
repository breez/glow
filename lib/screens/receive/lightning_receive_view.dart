import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:glow/widgets/receive/error_view.dart';
import 'package:glow/widgets/receive/info_card.dart';
import 'package:glow/widgets/receive/lightning_address_card.dart';
import 'package:glow/widgets/receive/no_lightning_address_view.dart';
import 'package:glow/widgets/receive/qr_code_card.dart';
import 'package:glow/widgets/receive/edit_lightning_address_sheet.dart';
import 'package:glow/widgets/receive/register_lightning_address_sheet.dart';

/// Lightning receive view - displays Lightning Address with QR code
class LightningReceiveView extends ConsumerWidget {
  const LightningReceiveView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lightningAddress = ref.watch(lightningAddressProvider(true));
    final sdkAsync = ref.watch(sdkProvider);

    return lightningAddress.when(
      data: (address) => address != null
          ? _LightningAddressContent(address: address.lightningAddress, sdk: sdkAsync.value!)
          : NoLightningAddressView(
              onRegister: () async {
                final sdk = sdkAsync.value;
                if (sdk != null) {
                  await showRegisterLightningAddressSheet(context, ref, sdk);
                }
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorView(message: 'Failed to load Lightning Address', error: err.toString()),
    );
  }
}

/// Content displayed when Lightning Address exists
class _LightningAddressContent extends ConsumerWidget {
  final String address;
  final BreezSdk sdk;

  const _LightningAddressContent({required this.address, required this.sdk});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          QRCodeCard(data: address),
          const SizedBox(height: 32),
          LightningAddressCard(
            address: address,
            onEdit: () => showEditLightningAddressSheet(context, ref, sdk, address),
          ),
          const SizedBox(height: 16),
          const InfoCard(
            icon: Icons.info_outline,
            text: 'Anyone can send you sats using this Lightning Address',
          ),
        ],
      ),
    );
  }
}
