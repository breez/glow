import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow_breez/providers/sdk_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  bool _showInvoiceInput = false;
  final _amountController = TextEditingController();
  BigInt? _amountSats;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _generateInvoice() {
    final amount = BigInt.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount != null && amount > BigInt.zero) {
      setState(() {
        _amountSats = amount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If generating invoice with amount
    if (_amountSats != null) {
      return _buildInvoiceScreen(context);
    }

    // If showing invoice input
    if (_showInvoiceInput) {
      return _buildAmountInput(context);
    }

    // Default: Show Lightning Address
    return _buildLightningAddressScreen(context);
  }

  Widget _buildLightningAddressScreen(BuildContext context) {
    final lightningAddress = ref.watch(lightningAddressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Receive')),
      body: lightningAddress.when(
        data: (address) {
          if (address == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.alternate_email,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Lightning Address',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Register a Lightning Address to receive payments',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _showInvoiceInput = true;
                        });
                      },
                      icon: const Icon(Icons.bolt),
                      label: const Text('Generate Invoice Instead'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Or register a Lightning Address in settings',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // QR Code
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: PrettyQrView.data(
                    data: address.lightningAddress,
                    decoration: const PrettyQrDecoration(shape: PrettyQrSmoothSymbol(color: Colors.black)),
                  ),
                ),
                const SizedBox(height: 32),

                // Lightning Address
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Lightning Address',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: address.lightningAddress));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        address.lightningAddress,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Generate Invoice Button
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showInvoiceInput = true;
                    });
                  },
                  icon: const Icon(Icons.bolt),
                  label: const Text('Generate Invoice'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to load Lightning Address',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _showInvoiceInput = true;
                    });
                  },
                  icon: const Icon(Icons.bolt),
                  label: const Text('Generate Invoice'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Invoice'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _showInvoiceInput = false;
              _amountSats = null;
            });
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text(
              'Amount',
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
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
              onSubmitted: (_) => _generateInvoice(),
            ),
            const Spacer(),
            FilledButton(onPressed: _generateInvoice, child: const Text('Generate Invoice')),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceScreen(BuildContext context) {
    final receiveResponse = ref.watch(
      receivePaymentProvider(
        ReceivePaymentRequest(
          paymentMethod: ReceivePaymentMethod.bolt11Invoice(description: 'Payment', amountSats: _amountSats),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _showInvoiceInput = false;
              _amountSats = null;
            });
          },
        ),
      ),
      body: receiveResponse.when(
        data: (response) => _buildInvoiceContent(context, response),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to generate invoice',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _amountSats = null;
                    });
                  },
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceContent(BuildContext context, ReceivePaymentResponse response) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Amount display
          Text(
            _formatSats(_amountSats!),
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w300, letterSpacing: -2),
          ),
          const Text('sats', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 32),

          // QR Code
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: PrettyQrView.data(
              data: response.paymentRequest,
              decoration: const PrettyQrDecoration(shape: PrettyQrSmoothSymbol(color: Colors.black)),
            ),
          ),
          const SizedBox(height: 32),

          // Invoice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Lightning Invoice',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: response.paymentRequest));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  response.paymentRequest,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          if (response.feeSats > BigInt.zero) ...[
            const SizedBox(height: 16),
            Text(
              'Fee: ${_formatSats(response.feeSats)} sats',
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  String _formatSats(BigInt sats) {
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
}
