import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/providers/bitcoin_address_provider.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:glow/screens/receive/receive_screen.dart';
import 'package:glow/utils/formatters.dart';
import 'package:glow/widgets/receive/qr_code_card.dart';
import 'package:glow/widgets/receive/copyable_card.dart';
import 'package:glow/widgets/receive/error_view.dart';

/// Bottom sheet for inputting amount and generating invoice/address
class AmountInputSheet extends ConsumerStatefulWidget {
  final ReceiveMethod receiveMethod;

  const AmountInputSheet({super.key, required this.receiveMethod});

  @override
  ConsumerState<AmountInputSheet> createState() => _AmountInputSheetState();
}

class _AmountInputSheetState extends ConsumerState<AmountInputSheet> {
  final _amountController = TextEditingController();
  BigInt? _generatedAmountSats;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _generatePaymentRequest() {
    final amount = parseSats(_amountController.text);
    if (amount != null && amount > BigInt.zero) {
      setState(() => _generatedAmountSats = amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show generated invoice/address
    if (_generatedAmountSats != null) {
      return _GeneratedPaymentRequest(
        amountSats: _generatedAmountSats!,
        receiveMethod: widget.receiveMethod,
        onBack: () => Navigator.of(context).pop(),
      );
    }

    // Show amount input
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Request Payment', style: Theme.of(context).textTheme.headlineSmall)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enter amount for ${widget.receiveMethod.label}',
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300, letterSpacing: -2),
            decoration: InputDecoration(
              hintText: '0',
              suffix: Text(
                'sats',
                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              border: InputBorder.none,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _generatePaymentRequest(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _generatePaymentRequest,
            child: Text(
              widget.receiveMethod == ReceiveMethod.lightning ? 'Generate Invoice' : 'Generate Address',
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Display generated payment request (Lightning invoice or Bitcoin address)
class _GeneratedPaymentRequest extends ConsumerWidget {
  final BigInt amountSats;
  final ReceiveMethod receiveMethod;
  final VoidCallback onBack;

  const _GeneratedPaymentRequest({
    required this.amountSats,
    required this.receiveMethod,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (receiveMethod == ReceiveMethod.lightning) {
      return _LightningInvoiceDisplay(amountSats: amountSats, onBack: onBack);
    } else {
      // Bitcoin address with amount encoded
      return _BitcoinAddressDisplay(amountSats: amountSats, onBack: onBack);
    }
  }
}

/// Display Lightning invoice
class _LightningInvoiceDisplay extends ConsumerWidget {
  final BigInt amountSats;
  final VoidCallback onBack;

  const _LightningInvoiceDisplay({required this.amountSats, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiveResponse = ref.watch(
      receivePaymentProvider(
        ReceivePaymentRequest(
          paymentMethod: ReceivePaymentMethod.bolt11Invoice(description: 'Payment', amountSats: amountSats),
        ),
      ),
    );

    return receiveResponse.when(
      data: (response) => _InvoiceContent(amountSats: amountSats, response: response, onBack: onBack),
      loading: () => const Center(
        child: Padding(padding: EdgeInsets.all(48.0), child: CircularProgressIndicator()),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: ErrorView(message: 'Failed to generate invoice', error: err.toString(), onRetry: onBack),
      ),
    );
  }
}

/// Invoice content display
class _InvoiceContent extends StatelessWidget {
  final BigInt amountSats;
  final ReceivePaymentResponse response;
  final VoidCallback onBack;

  const _InvoiceContent({required this.amountSats, required this.response, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text('Invoice', style: Theme.of(context).textTheme.headlineSmall)),
              IconButton(icon: const Icon(Icons.close), onPressed: onBack),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            formatSats(amountSats),
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w300, letterSpacing: -2),
          ),
          const Text('sats', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 32),
          QRCodeCard(data: response.paymentRequest),
          const SizedBox(height: 32),
          CopyableCard(title: 'Lightning Invoice', content: response.paymentRequest),
          if (response.feeSats > BigInt.zero) ...[
            const SizedBox(height: 16),
            Text(
              'Fee: ${formatSats(response.feeSats)} sats',
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Display Bitcoin address with amount
class _BitcoinAddressDisplay extends ConsumerWidget {
  final BigInt amountSats;
  final VoidCallback onBack;

  const _BitcoinAddressDisplay({required this.amountSats, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bip21DataAsync = ref.watch(bitcoinAddressWithAmountProvider(amountSats));

    return bip21DataAsync.when(
      data: (bip21Data) {
        if (bip21Data == null) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorView(
              message: 'No Bitcoin address available',
              error: 'Please generate a Bitcoin address first',
              onRetry: onBack,
            ),
          );
        }

        return _BitcoinAddressWithAmountContent(
          address: bip21Data.address,
          amountSats: bip21Data.amountSats,
          bip21Uri: bip21Data.bip21Uri,
          network: bip21Data.network,
          onBack: onBack,
        );
      },
      loading: () => const Center(
        child: Padding(padding: EdgeInsets.all(48.0), child: CircularProgressIndicator()),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: ErrorView(message: 'Failed to load Bitcoin address', error: err.toString(), onRetry: onBack),
      ),
    );
  }
}

/// Content for Bitcoin address with amount
class _BitcoinAddressWithAmountContent extends StatelessWidget {
  final String address;
  final BigInt amountSats;
  final String bip21Uri;
  final BitcoinNetwork network;
  final VoidCallback onBack;

  const _BitcoinAddressWithAmountContent({
    required this.address,
    required this.amountSats,
    required this.bip21Uri,
    required this.network,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text('Bitcoin Address', style: Theme.of(context).textTheme.headlineSmall)),
              IconButton(icon: const Icon(Icons.close), onPressed: onBack),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            formatSats(amountSats),
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w300, letterSpacing: -2),
          ),
          const Text('sats', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            '≈ ${formatSatsToBtc(amountSats)} BTC',
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          // QR code with BIP21 URI (includes amount)
          QRCodeCard(data: bip21Uri),
          const SizedBox(height: 32),
          CopyableCard(title: 'Bitcoin Address', content: address),
          const SizedBox(height: 16),
          // Show network warning if not mainnet
          if (network != BitcoinNetwork.bitcoin) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 20, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This is a ${_getNetworkName(network)} address',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          OutlinedButton.icon(
            onPressed: () => _copyBip21Uri(context, bip21Uri),
            icon: const Icon(Icons.copy),
            label: const Text('Copy Payment URI'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _copyBip21Uri(BuildContext context, String uri) {
    Clipboard.setData(ClipboardData(text: uri));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment URI copied to clipboard'), duration: Duration(seconds: 2)),
    );
  }

  String _getNetworkName(BitcoinNetwork network) {
    switch (network) {
      case BitcoinNetwork.bitcoin:
        return 'Mainnet';
      case BitcoinNetwork.testnet3:
        return 'Testnet3';
      case BitcoinNetwork.testnet4:
        return 'Testnet4';
      case BitcoinNetwork.signet:
        return 'Signet';
      case BitcoinNetwork.regtest:
        return 'Regtest';
    }
  }
}
