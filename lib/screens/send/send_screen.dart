import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/app_routes.dart';
import 'package:glow/handlers/input_handlers.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/providers/input_parser_provider.dart';

final _log = AppLogger.getLogger('SendScreen');
final _textGroup = AutoSizeGroup();

/// A page that allows users to enter payment information via text input, paste, or QR scan.
class SendScreen extends ConsumerStatefulWidget {
  const SendScreen({super.key});

  @override
  ConsumerState<SendScreen> createState() => _SendPageState();
}

class _SendPageState extends ConsumerState<SendScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _paymentInfoController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String _errorMessage = '';
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _paymentInfoController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _paymentInfoController.removeListener(_onTextChanged);
    _paymentInfoController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {
        // Clear error when user starts typing
        if (_errorMessage.isNotEmpty) {
          _errorMessage = '';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Send Payment')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: SingleChildScrollView(child: _buildContentContainer(themeData)),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildContentContainer(ThemeData themeData) {
    return Container(
      decoration: ShapeDecoration(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        color: themeData.colorScheme.surface,
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(children: [_buildForm(themeData), _buildActionButtons()]),
    );
  }

  Widget _buildForm(ThemeData themeData) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _paymentInfoController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintText: 'Invoice | Lightning Address | BTC Address | LNURL',
              hintStyle: themeData.textTheme.bodyMedium?.copyWith(
                color: themeData.colorScheme.onSurface.withValues(alpha: .5),
              ),
              helperText: 'Paste or scan payee information',
              helperStyle: themeData.textTheme.bodySmall,
              errorMaxLines: 3,
            ),
            style: themeData.textTheme.bodyLarge,
            maxLines: 3,
            minLines: 1,
            textInputAction: TextInputAction.done,
            validator: (value) => _errorMessage.isNotEmpty ? _errorMessage : null,
            onFieldSubmitted: _onFieldSubmitted,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 36.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: PaymentInfoPasteButton(onPressed: _onPastePressed, textGroup: _textGroup),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: PaymentInfoScanButton(onPressed: _scanBarcode, textGroup: _textGroup),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final hasText = _paymentInfoController.text.isNotEmpty;
    final isProcessing = _isValidating;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: Theme.of(context).primaryColorLight,
          ),
          onPressed: hasText && !isProcessing ? _onApprovePressed : null,
          child: SizedBox(
            height: 48,
            child: Center(
              child: isProcessing
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('NEXT', style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onPastePressed(String? value) async {
    _log.i('Paste button pressed');
    if (value != null && value.isNotEmpty) {
      _log.i('Pasted value length: ${value.length}');
      setState(() {
        _paymentInfoController.text = value;
      });
      await _validateInput();
    } else {
      _log.w('No clipboard data available');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clipboard is empty')));
      }
    }
  }

  Future<void> _scanBarcode() async {
    _log.i('Opening QR scanner');

    // Unfocus text field
    _focusNode.unfocus();

    if (!mounted) return;

    final String? barcode = await Navigator.pushNamed<String>(context, AppRoutes.qrScan);

    if (!mounted) return;

    if (barcode == null) {
      _log.i('QR scan cancelled');
      return;
    }

    if (barcode.isEmpty) {
      _log.w('Empty QR code scanned');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('QR code could not be detected')));
      return;
    }

    _log.i('QR code scanned: ${barcode.substring(0, barcode.length > 50 ? 50 : barcode.length)}...');

    setState(() {
      _paymentInfoController.text = barcode;
    });

    await _validateInput();
  }

  void _onFieldSubmitted(String value) {
    _log.i('Field submitted with value');
    if (value.isNotEmpty) {
      _onApprovePressed();
    }
  }

  Future<void> _validateInput() async {
    if (!mounted || _paymentInfoController.text.isEmpty) {
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = '';
    });

    _log.i('Validating input...');

    try {
      final parser = ref.read(inputParserProvider);
      final result = await parser.parse(_paymentInfoController.text);

      if (!mounted) return;

      result.when(
        success: (inputType) {
          _log.i('Input validated successfully: ${inputType.runtimeType}');

          // Check for specific validation rules
          inputType.when(
            bolt11Invoice: (details) {
              if (details.amountMsat == null || details.amountMsat! == BigInt.zero) {
                setState(() {
                  _errorMessage = 'Zero amount invoices are not supported';
                });
                _log.w('Zero amount BOLT11 invoice rejected');
              }
            },
            // Add other specific validation rules as needed
            bitcoinAddress: (_) {},
            bolt12Invoice: (_) {},
            bolt12Offer: (_) {},
            lightningAddress: (_) {},
            lnurlPay: (_) {},
            silentPaymentAddress: (_) {},
            lnurlAuth: (_) {},
            url: (_) {},
            bip21: (_) {},
            bolt12InvoiceRequest: (_) {},
            lnurlWithdraw: (_) {},
            sparkAddress: (_) {},
          );
        },
        error: (message) {
          _log.w('Input validation failed: $message');
          setState(() {
            _errorMessage = message.contains('Unrecognized') ? 'Unsupported payment format' : message;
          });
        },
      );
    } catch (e) {
      _log.e('Unexpected error during validation: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to validate input';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
        _formKey.currentState?.validate();
      }
    }
  }

  Future<void> _onApprovePressed() async {
    _log.i('Approve button pressed');

    if (!mounted) return;

    // Validate input first
    await _validateInput();

    if (!mounted) return;

    // Check if validation passed
    if (!_formKey.currentState!.validate()) {
      _log.w('Form validation failed');
      return;
    }

    if (_errorMessage.isNotEmpty) {
      _log.w('Cannot proceed with error: $_errorMessage');
      return;
    }

    setState(() {
      _isValidating = true;
    });

    try {
      final inputHandler = ref.read(inputHandlerProvider);
      final input = _paymentInfoController.text.trim();

      _log.i('Processing payment input');

      // Handle the input (will navigate to appropriate payment screen)
      // This will replace the current send screen with the payment screen
      if (mounted) {
        await inputHandler.handleInput(context, input);
      }
    } catch (e) {
      _log.e('Error processing payment info: $e');

      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to process payment';
        });
        _formKey.currentState?.validate();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
      }
    }
  }
}

/// A button that allows pasting from clipboard
class PaymentInfoPasteButton extends StatelessWidget {
  final Function(String? value) onPressed;
  final AutoSizeGroup? textGroup;

  const PaymentInfoPasteButton({required this.onPressed, this.textGroup, super.key});

  @override
  Widget build(BuildContext context) {
    final log = AppLogger.getLogger('PaymentInfoPasteButton');

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48.0, minWidth: 138.0),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        icon: const Icon(Icons.content_paste, size: 20.0),
        label: AutoSizeText(
          'PASTE',
          style: Theme.of(context).textTheme.labelLarge,
          maxLines: 1,
          group: textGroup,
          minFontSize: 12,
          stepGranularity: 0.1,
        ),
        onPressed: () async {
          log.i('Attempting to fetch clipboard data');
          try {
            final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
            final text = clipboardData?.text;

            if (text != null && text.isNotEmpty) {
              log.i('Clipboard data fetched successfully: ${text.length} characters');
              onPressed(text);
            } else {
              log.w('Clipboard is empty');
              onPressed(null);
            }
          } catch (e) {
            log.e('Failed to fetch clipboard data: $e');
            onPressed(null);
          }
        },
      ),
    );
  }
}

/// A button that allows scanning QR codes
class PaymentInfoScanButton extends StatelessWidget {
  final VoidCallback onPressed;
  final AutoSizeGroup? textGroup;

  const PaymentInfoScanButton({required this.onPressed, this.textGroup, super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48.0, minWidth: 138.0),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: themeData.colorScheme.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        icon: Icon(Icons.qr_code_scanner, size: 20.0, color: themeData.colorScheme.primary),
        label: AutoSizeText(
          'SCAN',
          style: themeData.textTheme.labelLarge,
          maxLines: 1,
          group: textGroup,
          minFontSize: 12,
          stepGranularity: 0.1,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
