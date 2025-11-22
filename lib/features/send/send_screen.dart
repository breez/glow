import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/services/clipboard_service.dart';
import 'package:glow/features/qr_scan/services/qr_scan_service.dart';
import 'package:glow/features/send/send_layout.dart';
import 'package:glow/routing/input_handlers.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/features/send/providers/send_input_validator.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('SendScreen');

/// A page that allows users to enter payment information via text input, paste, or QR scan.
class SendScreen extends ConsumerStatefulWidget {
  const SendScreen({super.key});

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController paymentInfoController = TextEditingController();
  final AutoSizeGroup textGroup = AutoSizeGroup();
  final FocusNode focusNode = FocusNode();
  bool isValidating = false;
  String errorMessage = '';

  @override
  void dispose() {
    paymentInfoController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SendLayout(
      formKey: formKey,
      controller: paymentInfoController,
      textGroup: textGroup,
      focusNode: focusNode,
      isValidating: isValidating,
      errorMessage: errorMessage,
      onPaste: _onPaste,
      onScan: _onScan,
      onSubmit: _onSubmit,
      onApprove: _onApprove,
    );
  }

  Future<void> _onPaste() async {
    final ClipboardService clipboardService = ref.read(clipboardServiceProvider);
    final String? clipboardText = await clipboardService.getClipboardText();
    if (clipboardText != null && clipboardText.isNotEmpty) {
      setState(() {
        paymentInfoController.text = clipboardText;
      });
      await _validateInput();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clipboard is empty')));
      }
    }
  }

  Future<void> _onScan() async {
    // Unfocus text field
    focusNode.unfocus();

    final QrScanService qrScanService = ref.read(qrScanServiceProvider);
    final String? barcode = await qrScanService.scanQrCode(context);
    if (barcode == null) {
      return;
    }

    if (barcode.isEmpty && mounted) {
      final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('No QR code found in image')));
      return;
    }

    setState(() {
      paymentInfoController.text = barcode;
    });

    await _validateInput();
  }

  void _onSubmit(String value) {
    _log.i('Field submitted with value');
    if (value.isNotEmpty) {
      _onApprove();
    }
  }

  Future<void> _validateInput() async {
    if (!mounted || paymentInfoController.text.isEmpty) {
      return;
    }

    setState(() {
      isValidating = true;
      errorMessage = '';
    });

    final SendInputValidator validator = ref.read(sendInputValidatorProvider);
    final String? error = await validator.validate(paymentInfoController.text);

    if (!mounted) {
      return;
    }

    setState(() {
      errorMessage = error ?? '';
      isValidating = false;
    });
    formKey.currentState?.validate();
  }

  Future<void> _onApprove() async {
    _log.i('Approve button pressed');

    if (!mounted) {
      return;
    }

    // Validate input first
    await _validateInput();

    if (!mounted) {
      return;
    }

    // Check if validation passed
    if (!formKey.currentState!.validate()) {
      _log.w('Form validation failed');
      return;
    }

    if (errorMessage.isNotEmpty) {
      _log.w('Cannot proceed with error: $errorMessage');
      return;
    }

    setState(() {
      isValidating = true;
    });

    try {
      final InputHandler inputHandler = ref.read(inputHandlerProvider);
      final String input = paymentInfoController.text.trim();

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
          errorMessage = 'Failed to process payment';
        });
        formKey.currentState?.validate();
      }
    } finally {
      if (mounted) {
        setState(() {
          isValidating = false;
        });
      }
    }
  }
}
