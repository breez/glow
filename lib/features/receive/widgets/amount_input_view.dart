import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/receive/models/receive_method.dart';
import 'package:glow/features/receive/models/receive_state.dart';
import 'package:glow/features/receive/providers/receive_form_controllers.dart';
import 'package:glow/features/receive/providers/receive_provider.dart';
import 'package:glow/features/receive/providers/bitcoin_address_provider.dart';
import 'package:glow/utils/formatters.dart';
import 'package:glow/features/receive/widgets/copy_and_share_actions.dart';
import 'package:glow/widgets/qr_code_card.dart';
import 'package:glow/widgets/copyable_card.dart';
import 'package:glow/features/receive/widgets/error_view.dart';
import 'package:glow/widgets/card_wrapper.dart';

class AmountInputView extends ConsumerStatefulWidget {
  final ReceiveMethod method;
  final ReceiveFormControllers formControllers;

  const AmountInputView({required this.method, required this.formControllers, super.key});

  @override
  ConsumerState<AmountInputView> createState() => _AmountInputViewState();
}

class _AmountInputViewState extends ConsumerState<AmountInputView> {
  late final TextEditingController _amountController;
  final FocusNode _amountFocusNode = FocusNode();
  late final TextEditingController _descriptionController;
  final FocusNode _descriptionFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _amountController = widget.formControllers.amount;
    _descriptionController = widget.formControllers.description;
    _amountFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CardWrapper(
              child: Form(
                key: widget.formControllers.formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      focusNode: _descriptionFocusNode,
                      controller: _descriptionController,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.done,
                      maxLines: null,
                      maxLength: 90,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      decoration: InputDecoration(
                        prefixIconConstraints: BoxConstraints.tight(const Size(16, 56)),
                        prefixIcon: const SizedBox.shrink(),
                        contentPadding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
                        border: const OutlineInputBorder(),
                        labelText: 'Description (optional)',
                        counterStyle: _descriptionFocusNode.hasFocus
                            ? const TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                                height: 1.182,
                                fontWeight: FontWeight.w400,
                              )
                            : const TextStyle(
                                color: Colors.white54,
                                fontSize: 14.0,
                                height: 1.182,
                                fontWeight: FontWeight.w400,
                              ),
                      ),
                      style: const TextStyle(
                        fontSize: 18.0,
                        color: Colors.white,
                        letterSpacing: 0.15,
                        height: 1.234,
                      ),
                    ),
                    const Divider(
                      height: 32.0,
                      color: Color.fromRGBO(40, 59, 74, 0.5),
                      indent: 0.0,
                      endIndent: 0.0,
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                      textInputAction: TextInputAction.done,
                      autofocus: true,
                      style: const TextStyle(fontSize: 18.0, letterSpacing: 0.15, height: 1.234),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        prefixIconConstraints: BoxConstraints.tight(const Size(16, 56)),
                        prefixIcon: const SizedBox.shrink(),
                        label: const Text('Amount in sats'),
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount in sats';
                        }
                        if (BigInt.tryParse(value) == null) {
                          return 'Invalid amount';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Payment display view - second step showing generated payment request
class PaymentDisplayView extends ConsumerWidget {
  final ReceiveState state;

  const PaymentDisplayView({required this.state, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.method == ReceiveMethod.lightning) {
      return _LightningPaymentDisplay(amountSats: state.amountSats!, response: state.receivePaymentResponse);
    } else {
      return _BitcoinPaymentDisplay(amountSats: state.amountSats!);
    }
  }
}

/// Lightning payment display
class _LightningPaymentDisplay extends ConsumerWidget {
  final BigInt amountSats;
  final ReceivePaymentResponse? response;

  const _LightningPaymentDisplay({required this.amountSats, this.response});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: CardWrapper(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            QRCodeCard(data: response!.paymentRequest),
            const SizedBox(height: 24),
            CopyAndShareActions(copyData: response!.paymentRequest, shareData: response!.paymentRequest),
            if (response!.fee > BigInt.zero) ...<Widget>[
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                padding: EdgeInsets.zero,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  width: MediaQuery.of(context).size.width,
                  child: Text(
                    'A fee of ${formatSats(response!.fee)} sats is applied to this invoice.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.4,
                      height: 1.182,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bitcoin payment display - handles fetching address with amount
class _BitcoinPaymentDisplay extends ConsumerWidget {
  final BigInt amountSats;

  const _BitcoinPaymentDisplay({required this.amountSats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<BitcoinBip21Data?> bip21DataAsync = ref.watch(
      bitcoinAddressWithAmountProvider(amountSats),
    );

    return bip21DataAsync.when(
      data: (BitcoinBip21Data? bip21Data) {
        if (bip21Data == null) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorView(
              message: 'No Bitcoin address available',
              error: 'Please generate a Bitcoin address first',
              onRetry: () {
                ref.read(receiveProvider.notifier).goBackInFlow();
              },
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: Text('Bitcoin Address', style: Theme.of(context).textTheme.headlineSmall)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      ref.read(receiveProvider.notifier).resetAmountFlow();
                    },
                  ),
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
              QRCodeCard(data: bip21Data.bip21Uri),
              const SizedBox(height: 32),
              CopyableCard(title: 'Bitcoin Address', content: bip21Data.address),
              const SizedBox(height: 16),
              // Show network warning if not mainnet
              if (bip21Data.network != BitcoinNetwork.bitcoin) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.warning_amber_rounded, size: 20, color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This is a ${_getNetworkName(bip21Data.network)} address',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              OutlinedButton.icon(
                onPressed: () => _copyBip21Uri(context, bip21Data.bip21Uri),
                icon: const Icon(Icons.copy),
                label: const Text('Copy Payment URI'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Generating address...', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
      error: (Object err, StackTrace _) => Padding(
        padding: const EdgeInsets.all(24),
        child: ErrorView(
          message: 'Failed to load Bitcoin address',
          error: err.toString(),
          onRetry: () {
            ref.read(receiveProvider.notifier).goBackInFlow();
          },
        ),
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
